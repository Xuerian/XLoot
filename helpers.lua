---@class XLootAddon
local XLoot = select(2, ...)
local buffer, print = {}, print

local table_insert, table_concat, string_format = table.insert, table.concat, string.format

local issecret = issecretvalue -- 12.0 secret values; nil pre-12.0

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
	coin_table[2][2] = mod(floor(copper / 100), 100)
	coin_table[3][2] = mod(copper, 100)

	local buffer = wipe(buffer)
	for i,v in ipairs(coin_table) do
		local n = v[2]
		if n and n > 0 then
			table_insert(buffer, string_format(v[4], n))
		end
	end

	return table_concat(buffer, ", ")
end

local GetCoinTextureString = GetCoinTextureString
function XLoot.MoneyString(copper, icons)
	if icons and GetCoinTextureString then
		return GetCoinTextureString(copper)
	end
	return XLoot.CopperToString(copper)
end

-- Scanning tooltip must live outside the UIParent tree, or the tooltip refresh cycle perpetually re-processes dynamic content (weapon imbues, temp buffs, tradeable timers).
XLootTooltip = CreateFrame('GameTooltip', 'XLootTooltip', nil, 'GameTooltipTemplate')
local tooltip = XLootTooltip
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

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
	if issecret and issecret(link) then return false end
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

-- No single "do I own this appearance" API (no help from blizzard here lol): PlayerHasTransmog* is per-source, so OR the collected state across every source.
local C_TC = _G.C_TransmogCollection
local TC_GetItemInfo = C_TC and C_TC.GetItemInfo
local TC_GetAllSources = C_TC and C_TC.GetAllAppearanceSources
local TC_PlayerHasSource = C_TC and C_TC.PlayerHasTransmogItemModifiedAppearance
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
if TC_GetItemInfo and TC_GetAllSources and TC_PlayerHasSource and GetItemInfoInstant then
	local CLASS_WEAPON, CLASS_ARMOR = 2, 4
	local CACHE_CAP = 256
	local appearance_cache, cache_count = {}, 0
	local invalidator
	local function ensure_invalidator()
		if invalidator then return end
		invalidator = CreateFrame('Frame')
		invalidator:RegisterEvent('TRANSMOG_COLLECTION_SOURCE_ADDED')
		invalidator:RegisterEvent('TRANSMOG_COLLECTION_SOURCE_REMOVED')
		invalidator:SetScript('OnEvent', function() wipe(appearance_cache); cache_count = 0 end)
	end
	function XLoot.IsNewAppearance(link)
		if not link then return false end
		local classID = select(6, GetItemInfoInstant(link))
		if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end
		local appearanceID, sourceID = TC_GetItemInfo(link)
		if not appearanceID or not sourceID or sourceID == 0 then return false end
		-- false is a real cached verdict, so test presence with ~= nil
		local cached = appearance_cache[sourceID]
		if cached ~= nil then return cached end
		local sources = TC_GetAllSources(appearanceID)
		if not sources then return false end -- transient nil: bail without caching a guess
		ensure_invalidator()
		local isNew = true
		for i = 1, #sources do
			if TC_PlayerHasSource(sources[i]) then
				isNew = false
				break
			end
		end
		if cache_count >= CACHE_CAP then wipe(appearance_cache); cache_count = 0 end
		appearance_cache[sourceID] = isNew
		cache_count = cache_count + 1
		return isNew
	end
else
	function XLoot.IsNewAppearance() return false end
end

-- Equip location -> the inventory slot(s) it competes with; multi-slot types (rings/trinkets/1H weapons) win if they beat any one.
local UPGRADE_SLOTS = {
	INVTYPE_HEAD = { INVSLOT_HEAD },
	INVTYPE_NECK = { INVSLOT_NECK },
	INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
	INVTYPE_CHEST = { INVSLOT_CHEST },
	INVTYPE_ROBE = { INVSLOT_CHEST },
	INVTYPE_WAIST = { INVSLOT_WAIST },
	INVTYPE_LEGS = { INVSLOT_LEGS },
	INVTYPE_FEET = { INVSLOT_FEET },
	INVTYPE_WRIST = { INVSLOT_WRIST },
	INVTYPE_HAND = { INVSLOT_HAND },
	INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
	INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
	INVTYPE_CLOAK = { INVSLOT_BACK },
	INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
	INVTYPE_2HWEAPON = { INVSLOT_MAINHAND },
	INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
	INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND },
	INVTYPE_HOLDABLE = { INVSLOT_OFFHAND },
	INVTYPE_SHIELD = { INVSLOT_OFFHAND },
	INVTYPE_RANGED = { INVSLOT_MAINHAND },
	INVTYPE_RANGEDRIGHT = { INVSLOT_MAINHAND },
}
local GetDetailedItemLevelInfo = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
local GetInventoryItemLink = GetInventoryItemLink
local RequestLoadItemDataByID = C_Item and C_Item.RequestLoadItemDataByID
if GetDetailedItemLevelInfo and GetItemInfoInstant and GetInventoryItemLink then
	local CLASS_WEAPON, CLASS_ARMOR = 2, 4
	function XLoot.IsIlvlUpgrade(link)
		if not link then return false end
		local itemID, _, _, equipLoc, _, classID, subclassID = GetItemInfoInstant(link)
		if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return false end
		local slots = equipLoc and UPGRADE_SLOTS[equipLoc]
		if not slots then return false end
		local lootedIlvl = GetDetailedItemLevelInfo(link)
		if not lootedIlvl or lootedIlvl == 0 then
			-- ilvl not cached yet; warm it and skip this pass rather than risk a wrong tag
			if itemID and RequestLoadItemDataByID then RequestLoadItemDataByID(itemID) end
			return false
		end
		-- Only when an equipped slot holds the SAME weapon/armor subtype at lower ilvl: proves the player can use it, so no false tag on unusable gear.
		for i = 1, #slots do
			local equipped = GetInventoryItemLink('player', slots[i])
			if equipped and select(7, GetItemInfoInstant(equipped)) == subclassID then
				local equippedIlvl = GetDetailedItemLevelInfo(equipped)
				if equippedIlvl and lootedIlvl > equippedIlvl then return true end
			end
		end
		return false
	end
else
	function XLoot.IsIlvlUpgrade() return false end
end
local URGENCY_START, URGENCY_FULL = 0.3, 0.1
local URGENT_R, URGENT_G, URGENT_B = 1, 0.15, 0.15
function XLoot.TimeFractionColor(fraction, r, g, b)
	if fraction >= URGENCY_START then return r, g, b end
	local t = fraction <= URGENCY_FULL and 1
		or (URGENCY_START - fraction) / (URGENCY_START - URGENCY_FULL)
	return r + (URGENT_R - r) * t, g + (URGENT_G - g) * t, b + (URGENT_B - b) * t
end

-- Tack role icon on to player name and return class colors
local white = { r = 1, g = 1, b = 1 }
local dimensions = {
	HEALER = '48:64',
	DAMAGER = '16:32',
	TANK = '32:48'
}
function XLoot.FancyPlayerName(name, class, opt)
	local c = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class])
		or (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class])
		or white
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

-- Loot method: the string GetLootMethod() global is gone on modern Classic/retail and Enum.LootMethod is absent on some older flavors, so probe the C_PartyInfo enum first and fall back to the global. Both return method, masterlooterPartyID, masterlooterRaidID.
local MASTER_LOOT = Enum and Enum.LootMethod and Enum.LootMethod.Masterlooter
local C_GetLootMethod = C_PartyInfo and C_PartyInfo.GetLootMethod
local function MasterLootInfo()
	if MASTER_LOOT and C_GetLootMethod then
		local method, party_id, raid_id = C_GetLootMethod()
		return method == MASTER_LOOT, party_id, raid_id
	end
	if GetLootMethod then
		local method, party_id, raid_id = GetLootMethod()
		return method == 'master', party_id, raid_id
	end
	-- Last resort while a loot window is open: a candidate list only exists under master loot.
	return GetMasterLootCandidate and GetMasterLootCandidate(1, 1) ~= nil or false
end

function XLoot.GroupUsesMasterLoot()
	return (MasterLootInfo()) and true or false
end

function XLoot.IsMasterLooter()
	local isMaster, party_id, raid_id = MasterLootInfo()
	if not isMaster then return false end
	if raid_id then
		return UnitIsUnit('player', 'raid'..raid_id)
	elseif party_id then
		return party_id == 0
	end
	return false
end

XLoot.SendChatMessage = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

-- Numeric segment-by-segment compare, since a string compare sorts "12.10.0" below "12.9.0". Returns 1, -1, or 0.
function XLoot.CompareVersions(a, b)
	local ai, bi = tostring(a or ""):gmatch("%d+"), tostring(b or ""):gmatch("%d+")
	while true do
		local a_part, b_part = ai(), bi()
		if not a_part and not b_part then return 0 end
		local an, bn = tonumber(a_part) or 0, tonumber(b_part) or 0
		if an ~= bn then
			return an > bn and 1 or -1
		end
	end
end

-- Shared Blizzard loot-toast suppression, reference-counted so Monitor and Toast can each request it without
-- clobbering the other. The AddAlert wrapper is installed once and never restored, so toggling a source off can
-- not clobber another addon's later hook. LegendaryItemAlertSystem is retail-only; MoP routes legendaries through
-- LootAlertSystem.
do
	local requesters = {}
	local hooked = {}
	local systems = { "LootAlertSystem", "MoneyWonAlertSystem", "LootUpgradeAlertSystem", "LegendaryItemAlertSystem" }
	local function suppressing()
		return next(requesters) ~= nil
	end
	function XLoot.SuppressLootToasts(source, want)
		requesters[source] = want or nil
		if not suppressing() then return end
		for _, name in ipairs(systems) do
			local system = _G[name]
			if system and system.AddAlert and not hooked[name] then
				hooked[name] = true
				local original = system.AddAlert
				system.AddAlert = function(...)
					if suppressing() then return end
					return original(...)
				end
			end
		end
	end
end


local temp_list, template = {},
[[local string_match = string.match
return function(message)
	local pcall_status, m1, m2, m3, m4, m5 = pcall(string_match, message, [=[^%s$]=])
	assert(pcall_status, "Please report this on XLoot's GitHub issues page", message, [=[^%s$]=], m1)
	return %s
end]]

-- Return a inverted match string and corresponding list of ordered match slots (m1-m5)
local match, gsub, insert = string.match, string.gsub, table.insert
local function invert(pattern)
	local inverted, arglist = pattern, nil
	-- Escape magic characters
	inverted = gsub(inverted, "%(", "%%(")
	inverted = gsub(inverted, "%)", "%%)")
	inverted = gsub(inverted, "%-", "%%-")
	inverted = gsub(inverted, "%+", "%%+")
	inverted = gsub(inverted, "%.", "%%.")
	-- Account for reordered replacements
	local k = match(inverted, '%%(%d)%$')
	if k then
		local i, list = 1, wipe(temp_list)
		while k ~= nil do
			inverted = gsub(inverted, "(%%%d%$.)", "(.-)", 1)
			list[i] = 'm'..tostring(k)
			k, i = match(inverted, "%%(%d)%$"), i + 1
		end
		arglist = table.concat(list, ", ")
	-- Simple patterns
	else
		inverted = gsub(inverted, "%%d", "(%%d+)")
		inverted = gsub(inverted, "%%s", "(.-)")
		arglist = "m1, m2, m3, m4, m5"
	end
	return inverted, arglist
end

-- Match string against a pattern, caching the inverted pattern
local invert_cache = {}
function XLoot.Deformat(str, pattern)
	if issecret and issecret(str) then return end
	local func = invert_cache[pattern]
	if not func then
		local inverted, arglist = invert(pattern)
		func = loadstring(template:format(inverted, inverted, arglist))()
		invert_cache[pattern] = func
	end
	return func(str)
end
XLoot.InvertFormatString = invert

--@do-not-package@
-- Debug
local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
