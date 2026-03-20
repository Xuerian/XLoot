---@class XLootAddon
local XLoot = select(2, ...)
local buffer, print = {}, print

local table_insert, table_concat, string_format = table.insert, table.concat, string.format

-- [PATCH 12.0] math.floor/math.fmod explicitly; bare global aliases removed.
local floor, fmod = math.floor, math.fmod

local coin_table = {
	{ GOLD_AMOUNT, 0, "ffd700" },
	{ SILVER_AMOUNT, 0, "c7c7cf" },
	{ COPPER_AMOUNT, 0, "eda55f" }
}
for i,v in ipairs(coin_table) do
	v[4] = string_format("|cff%s%s|r", v[3], v[1])
end
function XLoot.CopperToString(copper)
	coin_table[1][2] = floor(copper / 10000)
	coin_table[2][2] = fmod(floor(copper / 100), 100)
	coin_table[3][2] = fmod(copper, 100)

	local buffer = wipe(buffer)
	for i,v in ipairs(coin_table) do
		local n = v[2]
		if n and n > 0 then
			table_insert(buffer, string_format(v[4], n))
		end
	end

	return table_concat(buffer, ", ")
end

XLootTooltip = CreateFrame('GameTooltip', 'XLootTooltip', UIParent, 'GameTooltipTemplate')
local tooltip = XLootTooltip
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

local bind_types = {
	[ITEM_BIND_ON_PICKUP] = 'pickup',
	[ITEM_BIND_ON_EQUIP] = 'equip',
	[ITEM_BIND_ON_USE] = 'use'
}

local tooltip_lines = {
	XLootTooltipTextLeft2,
	XLootTooltipTextLeft3,
	XLootTooltipTextLeft4,
	XLootTooltipTextLeft5
}

function XLoot.GetItemBindType(link)
	tooltip:ClearLines()
	tooltip:SetHyperlink(link)
	for i=1, #tooltip_lines do
		local value = bind_types[tooltip_lines[i]:GetText()]
		if value then
			return value
		end
	end
end

function XLoot.CanEquipItem(link)
	if not C_Item.IsEquippableItem(link) then
		return false
	end
	tooltip:ClearLines()
	tooltip:SetHyperlink(link)
	for i=2, 5 do
		local line = _G["XLootTooltipTextRight"..i]
		if line and line:GetText() then
			local r, g, b = line:GetTextColor()
			local lr, lg, lb = _G["XLootTooltipTextLeft"..i]:GetTextColor()
			return (r > .8 and b > .8 and g > .8 and lr > .8 and lg > .8 and lb > .8) and true or false
		end
	end
end

function XLoot.IsItemUpgrade(link)
	if not XLoot.CanEquipItem(link) then
		return false
	end
	local id = string.match(link, "item:(%d+)")
	if PawnIsItemIDAnUpgrade and id and PawnIsItemIDAnUpgrade(id) then
		return true
	end
	return false
end

-- Tack role icon on to player name and return class colors
local white = { r = 1, g = 1, b = 1 }
local dimensions = {
	HEALER = '48:64',
	DAMAGER = '16:32',
	TANK = '32:48'
}
function XLoot.FancyPlayerName(name, class, opt)
	local c
	if _G.CUSTOM_CLASS_COLORS then
		c = _G.CUSTOM_CLASS_COLORS[class]
	elseif _G.RAID_CLASS_COLORS[class] then
		c = _G.RAID_CLASS_COLORS[class]
	else
		c = white
	end
	-- !CLASSIC
	local role = 'NONE'
	if UnitGroupRolesAssigned then
		role = UnitGroupRolesAssigned(name)
	end
	local short, realm = UnitName(name)
	if short then
		name = short
	end
	if realm and realm ~= "" then
		name = name.."*"
	end
	if role ~= 'NONE' and opt and opt.role_icon then
		name = string_format('\124TInterface\\LFGFRAME\\LFGROLE:12:12:-1:0:64:16:%s:0:16\124t%s', dimensions[role], name)
	end
	return name, c.r, c.g, c.b
end


-- Return an inverted match string and the capture-return order for Deformat.
-- For simple patterns (%s/%d), captures are always m1..m5 in order.
-- For positional patterns (%1$s etc.), captures may be reordered; we record
-- the desired return order as a numeric array so we can reorder at call time
-- without needing loadstring/load.
local temp_list = {}
local match, gsub = string.match, string.gsub

local function invert(pattern)
	local inverted, order = pattern, nil
	-- Escape magic characters
	inverted = gsub(inverted, "%(", "%%(")
	inverted = gsub(inverted, "%)", "%%)")
	inverted = gsub(inverted, "%-", "%%-")
	inverted = gsub(inverted, "%+", "%%+")
	inverted = gsub(inverted, "%.", "%%.")
	-- Account for reordered replacements (%1$s style)
	local k = match(inverted, '%%(%d)%$')
	if k then
		local i, list = 1, wipe(temp_list)
		while k ~= nil do
			inverted = gsub(inverted, "(%%%d%$.)", "(.-)", 1)
			list[i] = tonumber(k)
			k, i = match(inverted, "%%(%d)%$"), i + 1
		end
		-- Store as a plain numeric array copy (temp_list is reused)
		order = { list[1], list[2], list[3], list[4], list[5] }
	-- Simple %s / %d patterns
	else
		inverted = gsub(inverted, "%%d", "(%%d+)")
		inverted = gsub(inverted, "%%s", "(.-)")
		-- order stays nil → return captures in natural order
	end
	return inverted, order
end

-- [PATCH 12.0] loadstring() and load() are both unavailable in the WoW 12.0
-- Lua sandbox. The previous implementation compiled match functions as strings;
-- this version builds a plain closure instead, storing the anchored inverted
-- pattern and (for positional formats) a capture-reorder table.
local invert_cache = {}
function XLoot.Deformat(str, pattern)
	local cached = invert_cache[pattern]
	if not cached then
		local inverted, order = invert(pattern)
		cached = { pat = "^" .. inverted .. "$", order = order }
		invert_cache[pattern] = cached
	end

	local ok, m1, m2, m3, m4, m5 = pcall(string.match, str, cached.pat)
	assert(ok, "Please report this on XLoot's curse page")

	local ord = cached.order
	if ord then
		-- Reorder captures to match positional format specifiers
		local c = { m1, m2, m3, m4, m5 }
		return c[ord[1]], c[ord[2]], c[ord[3]], c[ord[4]], c[ord[5]]
	end
	return m1, m2, m3, m4, m5
end

XLoot.InvertFormatString = invert
