local lib = LibStub:NewLibrary("LootEvents", "1.2")
if not lib then return nil end

--[[// Usage
	Callbacks recieve (event, chat_event, ...)
	LootEvents:RegisterLootCallback(func)
		event: 'item'
			player_name, item_link, num_items
		event: 'coin'
			player_name, total_copper, coin_string
		event: 'currency'
			currency, num_currency
		event: 'crafted'
			item_link, num_items

	LootEvents:RegisterGroupCallback(func)
		Triggers func when "Group" loot mode events are recieved
		event: 'selected'
			item_link, player_name, roll_type
		event: 'rolled'
			item_link, player_name, roll_type, roll_number
		event: 'won'
			item_link, player_name
		event: 'allpass'
			item_link
--]]

-- Callback handling
lib.callbacks = lib.callbacks or { loot = {}, group = {} }
local lootcb, groupcb = lib.callbacks.loot, lib.callbacks.group

local need_loot = next(lootcb) and true or false
local need_group = next(groupcb) and true or false

function lib:RegisterLootCallback(func)
	table.insert(lootcb, func)
	need_loot = true
end

function lib:RegisterGroupCallback(func)
	table.insert(groupcb, func)
	need_group = true
end

local current_pattern = nil
local function trigger_loot(event, ...)
	for _, func in ipairs(lootcb) do
		func(event, current_pattern, ...)
	end
end

local activerolls = 0
local function trigger_group(event, ...)
	for _, func in ipairs(groupcb) do
		func(event, current_pattern, ...)
	end
	if event == 'won' or event == 'allpass' then
		activerolls = max(0, activerolls - 1)
	end
end


local temp_list, template = {}, 
[[local string_match = string.match
local emsg = "Please report this on XLootGroup's addon page"
return function(message)
	local inverted = [=[^%s$]=]
	local pcall_status, m1, m2, m3, m4, m5 = pcall(string_match, message, inverted)
	assert(pcall_status, emsg, message, inverted, m1)
	return %s
end]]

local invert_cache, match, gsub, insert = {}, string.match, string.gsub, table.insert
local function extract(str, pattern)
	local func = invert_cache[pattern]
	if not func then
		local inverted, args = pattern
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
			args = table.concat(list, ", ")
		-- Simple patterns
		else
			inverted = gsub(inverted, "%%d", "(%d+)")
			inverted = gsub(inverted, "%%s", "(.-)")
			args = "m1, m2, m3, m4, m5"
		end

		func = loadstring(template:format(inverted, args))()
		invert_cache[pattern] = func
	end
	return func(str)
end

-- Catch latent rolls
if IsInGroup() then
	for i=1,200 do
		local time = GetLootRollTimeLeft(i)
		if time > 0 then
			activerolls = activerolls + 1
		end
	end
end


local loot_patterns, group_patterns, unsortedloot, currentsort

-- Chatmsg handler
local sort, group = table.sort
local function sort_func(a, b)
	return a[group] < b[group]
end

local function Handler(text)
	if need_group and activerolls > 0 then
		-- Move through the patterns one by one, match against the message
		for k, v in ipairs(group_patterns) do
			local m1, m2, m3, m4 = extract(text, v[1])
			-- Match was found, call the handler with all captured values
			if m1 then
				current_pattern = v[3]
				return v[2](m1, m2, m3, m4)
			end
		end
	end

	if need_loot then
		-- Optimize by grouped/not and weight patterns by usage
		-- Check group mode (1 corresponds to ungrouped, 2 to grouped)
		group = IsInGroup() and 2 or 1
		-- If we're not currently sorting for our current mode, or it's been too long since last sort, sort ourpatterns for efficiency
		if not currentsort or currentsort ~= group or unsortedloot > 100 then
			unsortedloot, currentsort = 0, group
			sort(loot_patterns, sort_func)
		else
			unsortedloot = unsortedloot + 1
		end

		-- Match string against our patterns
		for i, v in ipairs(loot_patterns) do
			local m1, m2, m3, m4 = extract(text, v[3])
			-- Match found, add to counter and call pattern's handler
			if m1 then
				v[group] = v[group] + 1
				current_pattern = v[3]
				return v[4](m1, m2, m3, m4)
			end
		end
	end
end

-- Invert gold patterns
local function invert(pstr)
	return pstr:gsub("%%d", "(%1+)")
end
local cg = invert(GOLD_AMOUNT)
local cs = invert(SILVER_AMOUNT)
local cc = invert(COPPER_AMOUNT)

-- Parse coin strings (Really?)
local function ParseCoinString(tstr)
	local g = tstr:match(cg) or 0
	local s = tstr:match(cs) or 0
	local c = tstr:match(cc) or 0
	return g*10000+s*100+c
end

-- Event handling
if lib.frame then
	lib.frame:SetScript("OnEvent", function() return nil end)
end
lib.frame = CreateFrame("Frame")
local f = lib.frame
local events = {}
f:SetScript("OnEvent", function(_, e, ...) if events[e] then events[e](...) end end)
local function event(e, func)
	f:RegisterEvent(e)
	events[e] = func
end

event("CHAT_MSG_LOOT", Handler)
event("CHAT_MSG_MONEY", Handler)

-- Incriment and deincement rolls to only match while there is a roll happening
event("START_LOOT_ROLL", function()
	activerolls = activerolls + 1
	end)
-- 2 second delay needed?
local max = math.max
event("CANCEL_LOOT_ROLL", function()
	--activerolls = max(0, activerolls - 1)
end)

local player = UnitName('player')


--// LOOT PATTERNS
loot_patterns = { }
do
	local function handler(str, func)
		table.insert(loot_patterns, { 0, 0, _G[str], func, str })
	end

	-- Loot triggers
	local function loot(who, what, num)
		trigger_loot('item', who, what, num or 1)
	end

	local function coin(who, str)
		trigger_loot('coin', who, ParseCoinString(str), str)
	end

	-- Add item patterns
	handler('LOOT_ITEM', loot)
	handler('LOOT_ITEM_MULTIPLE', loot)
	handler('LOOT_ITEM_PUSHED_SELF', function(what) loot(player, what) end)
	handler('LOOT_ITEM_PUSHED_SELF_MULTIPLE', function(what, num) loot(player, what, num) end)

	-- Account for Russian locale using the same string for LOOT_MONEY as LOOT_ITEM_SELF
	if GetLocale() == "ruRU" then
		handler('LOOT_ITEM_SELF', function(what)
			local c = ParseCoinString(what)
			if c > 0 then
				trigger_loot('coin', player, c, what)
			else
				loot(player, what)
			end
		end)
	else
		handler('LOOT_ITEM_SELF', function(what) loot(player, what) end)
	end

	handler('LOOT_ITEM_SELF_MULTIPLE', function(what, num) loot(player, what, num) end)

	-- Add coin patterns
	handler('LOOT_MONEY', coin)
	handler('LOOT_MONEY_SPLIT', function(str) coin(player, str) end)
	handler('YOU_LOOT_MONEY', function(str) coin(player, str) end)

	-- Currency patterns
	function currency(link, num)
		trigger_loot('currency', link:match('currency:(%d+)'), num or 1)
	end
	handler('CURRENCY_GAINED', currency)
	handler('CURRENCY_GAINED_MULTIPLE', currency)

	-- Self crafting
	function crafted(what, num)
		trigger_loot('crafted', what, num or 1)
	end
	handler('LOOT_ITEM_CREATED_SELF', crafted)
	handler('LOOT_ITEM_CREATED_SELF_MULTIPLE', crafted)
end


--// GROUP PATTERNS
group_patterns = { }
do
	-- Base handler function. Checks argument types, adds to handler table (Presorted)
	--    The pattern is stored as the first key, and the function to be called in the second
	local function handler(str, func)
		table.insert(group_patterns, { _G[str], func, str })
	end

	-- Roll selected handler (You select Greed for XXXX, etc)
	local function selected(str, rtype, own)
		handler(str, function(who, item)
			if own then
				item, who = who, player
			end
			trigger_group('selected', item, who, rtype)
		end)
	end

	-- Rolled handler (XXXX roll - # by xxxxx, etc)
	local function rolled(str, rtype, own)
		handler(str, function(roll, item, who)
			trigger_group('rolled', item, (own or who == YOU) and player or who, rtype, tonumber(roll)) 
		end)
	end

	-- Add handlers using construct functions, ordered specifically
	selected('LOOT_ROLL_DISENCHANT', 'disenchant')
	selected('LOOT_ROLL_GREED', 'greed')
	selected('LOOT_ROLL_NEED', 'need')
	selected('LOOT_ROLL_DISENCHANT_SELF', 'disenchant', true)
	selected('LOOT_ROLL_GREED_SELF', 'greed', true)
	selected('LOOT_ROLL_NEED_SELF', 'need', true)
	selected('LOOT_ROLL_PASSED_AUTO', 'pass')
	selected('LOOT_ROLL_PASSED_AUTO_FEMALE', 'pass')
	selected('LOOT_ROLL_PASSED_SELF_AUTO', 'pass', true)
	handler('LOOT_ROLL_ALL_PASSED', function(item) trigger_group('allpass', item) end)
	selected('LOOT_ROLL_PASSED_SELF', 'pass', true)
	selected('LOOT_ROLL_PASSED', 'pass')
	rolled('LOOT_ROLL_ROLLED_DE', 'disenchant')
	rolled('LOOT_ROLL_ROLLED_GREED', 'greed')
	rolled('LOOT_ROLL_ROLLED_NEED', 'need') 
	rolled('LOOT_ROLL_ROLLED_NEED_ROLE_BONUS', 'need')
	handler('LOOT_ROLL_YOU_WON', function(item) trigger_group('won', item, player) end)
	handler('LOOT_ROLL_WON', function(who, item) trigger_group('won', item, who == YOU and player or who) end)
end
