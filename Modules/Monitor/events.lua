local lib = LibStub:NewLibrary("LootEvents", "1.2")
if not lib then return nil end
local print = print

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



-- Catch latent rolls
if IsInGroup() then
	for i=1,200 do
		local time = GetLootRollTimeLeft(i)
		if time > 0 then
			activerolls = activerolls + 1
		end
	end
end

local Deformat = XLoot.Deformat

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
			local m1, m2, m3, m4 = Deformat(text, v[1])
			-- Match was found, call the handler with all captured values
			if m1 then
				current_pattern = v[3]
				return v[2](m1, m2, m3, m4)
			end
		end
	end

	if need_loot then
		-- Match string against our patterns
		for i, v in ipairs(loot_patterns) do
			local m1, m2, m3, m4 = Deformat(text, v[1])
			-- Match found, add to counter and call pattern's handler
			if m1 then
				current_pattern = v[1]
				return v[2](m1, m2, m3, m4)
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
event("CHAT_MSG_CURRENCY", Handler)

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
		assert(_G[str], "String does not exist", str)
		table.insert(loot_patterns, { _G[str], func, str })
	end

	-- Loot triggers
	local function loot(who, what, num)
		trigger_loot('item', who, what, num or 1)
	end

	local function coin(who, str)
		trigger_loot('coin', who, ParseCoinString(str), str)
	end

	-- Add item patterns
	handler('LOOT_ITEM_PUSHED_SELF_MULTIPLE', function(what, num) loot(player, what, num) end)
	handler('LOOT_ITEM_PUSHED_SELF', function(what) loot(player, what) end)
	handler('LOOT_ITEM_SELF_MULTIPLE', function(what, num) loot(player, what, num) end)

	-- Account for Russian locale using the same string for LOOT_MONEY as LOOT_ITEM_SELF
	if GetLocale() == "ruRU" then
		handler('LOOT_ITEM_SELF', function(what)
			if not what:match("|H") then -- No link, match coins
				trigger_loot('coin', player, ParseCoinString(what), what)
			else
				loot(player, what)
			end
		end)
	else
		handler('LOOT_ITEM_SELF', function(what) loot(player, what) end)
		handler('YOU_LOOT_MONEY_GUILD', function(str) coin(player, str) end)
		handler('YOU_LOOT_MONEY', function(str) coin(player, str) end)
	end
	handler('LOOT_ITEM_MULTIPLE', loot)
	handler('LOOT_ITEM', loot)


	-- Add coin patterns
	handler('LOOT_MONEY', coin)
	handler('LOOT_MONEY_SPLIT_GUILD', function(str) coin(player, str) end)
	handler('LOOT_MONEY_SPLIT', function(str) coin(player, str) end)

	-- Currency patterns
	local function currency(link, num)
		trigger_loot('currency', link:match('currency:(%d+)'), num or 1)
	end
	handler('CURRENCY_GAINED_MULTIPLE', currency)
	handler('CURRENCY_GAINED', currency)

	-- Self crafting
	local function crafted(what, num)
		trigger_loot('crafted', what, num or 1)
	end
	handler('LOOT_ITEM_CREATED_SELF_MULTIPLE', crafted)
	handler('LOOT_ITEM_CREATED_SELF', crafted)
	handler('LOOT_ITEM_REFUND_MULTIPLE', function (what, num) loot(player, what) end)
	handler('LOOT_ITEM_REFUND', function (what, num) loot(player, what, num) end)
	handler('LOOT_MONEY_REFUND', coin)
	handler('LOOT_ITEM_WHILE_PLAYER_INELIGIBLE', loot)

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

--@do-not-package@
local test = false
local test_verbose = false
local AC = LibStub('AceConsole-2.0', true)

if AC then print = function(...) AC:PrintLiteral(...) end end

local items = {
	-- { 52722 },
	-- { 31304 },
	-- { 37254 },
	-- { 13262 },
	-- { 15487 },
	{ 72120 },
	{ 76137 },
	-- { 2589 }
}

for i,v in ipairs(items) do
	GetItemInfo(v[1])
end

XLoot:SetSlashCommand("xe", function(msg)
	for i=1,4 do
		Handler((LOOT_ITEM_SELF):format(select(2, GetItemInfo(items[random(1, #items)][1]))))
	end
	Handler((YOU_LOOT_MONEY):format("1 Gold, 2 Silver, 3 Copper"))
end)

local locales = {
	zhTW = {
		-- item = "[崑萊碎肉塊]",
		strings = {
			LOOT_ITEM = "%s獲得戰利品:%s。",
			LOOT_ITEM_CREATED_SELF = "你製造了:%s。",
			LOOT_ITEM_CREATED_SELF_MULTIPLE = "你製造了:%sx%d。",
			LOOT_ITEM_MULTIPLE = "%s獲得戰利品:%sx%d。",
			LOOT_ITEM_PUSHED_SELF = "你獲得了物品:%s。",
			LOOT_ITEM_PUSHED_SELF_MULTIPLE = "你獲得物品:%sx%d。",
			LOOT_ITEM_REFUND = "退回給你的費用為:%s。",
			LOOT_ITEM_REFUND_MULTIPLE = "退回給你的費用為:%sx%d。",
			LOOT_ITEM_SELF = "你拾取了物品:%s。",
			LOOT_ITEM_SELF_MULTIPLE = "你獲得戰利品:%sx%d。",
			LOOT_ITEM_WHILE_PLAYER_INELIGIBLE = "%s獲得戰利品:|TInterface\\Common\\Icon-NoLoot:13:13:0:0|t%s",
			LOOT_MONEY = "%s拾取了%s。",
			LOOT_MONEY_REFUND = "退回給你的費用為%s。",
			LOOT_MONEY_SPLIT = "你分到%s。",
			LOOT_MONEY_SPLIT_GUILD = "你分到%s。(%s存放在公會銀行)",
			YOU_LOOT_MONEY = "你拾取了%s",
			YOU_LOOT_MONEY_GUILD = "你拾取了%s(%s存放在公會銀行)",
		}
	}
}
local locale_mt = {
	__index = {
		item = "[Linen Cloth]",
		player = "Xuerian",
		money = "1 Gold",
		guild = "Some guild",
		number = 5
	}
}

local function test_table_from_locale(t)
	return {
		LOOT_ITEM_CREATED_SELF = {t.item},
		LOOT_ITEM_CREATED_SELF_MULTIPLE = {t.item, t.number},
		LOOT_ITEM = {t.player, t.item},
		LOOT_ITEM_MULTIPLE = {t.player, t.item, t.number},
		LOOT_ITEM_PUSHED_SELF = {t.item},
		LOOT_ITEM_PUSHED_SELF_MULTIPLE = {t.item, t.number},
		LOOT_ITEM_REFUND = {t.item},
		LOOT_ITEM_REFUND_MULTIPLE = {t.item, t.number},
		LOOT_ITEM_SELF = {t.item},
		LOOT_ITEM_SELF_MULTIPLE = {t.item, t.number},
		LOOT_ITEM_WHILE_PLAYER_INELIGIBLE = {t.player, t.item},
		LOOT_MONEY = {t.player, t.money},
		LOOT_MONEY_REFUND = {t.money},
		LOOT_MONEY_SPLIT = {t.money},
		LOOT_MONEY_SPLIT_GUILD = {t.money, t.guild},
		YOU_LOOT_MONEY = {t.money},
		YOU_LOOT_MONEY_GUILD = {t.money, t.guild}
	}
end

local function tprint(...)
	if test_verbose then
		print(...)
	end
end

-- Test each locale
local function inv(pat) return select(1, XLoot.InvertFormatString(pat)) end
local fmt = string.format
for locale, t in pairs(locales) do
	setmetatable(t, locale_mt)
	-- setmetatable(t.strings, string_mt)
	local test_table = test_table_from_locale(t)
	local pass, fail = 0, 0
	-- Test each string
	for k, p in pairs(t.strings) do
		-- Fake string
		local test = p:format(unpack(test_table[k]))
		-- Emulate Handle(text)
		local m1, m2, m3, m4, matched
		for i, v in ipairs(loot_patterns) do
			if t.strings[v[3]] then
				m1, m2, m3, m4 = Deformat(test, t.strings[v[3]])
				if m1 then
					matched = v[3]
					break
				end
			else
				-- cprint("[INCOMPLETE] string missing", v[3], locale)
			end
		end
		-- String results
		if matched == k then
			tprint(fmt("[PASS] matched %s (%s) against %s", matched, inv(t.strings[k]), test), m1, m2, m3, m4)
			pass = pass + 1
		else
			if matched then
				tprint(fmt("[FAIL] expected %s, matched %s (%s vs %s) against %s", k, matched, inv(t.strings[matched]), inv(t.strings[k]), test), m1, m2, m3)
			else
				tprint(fmt("[FAIL] no match for %s (%s) against %s", k, inv(t.strings[k]), test))
			end
			fail = fail + 1
		end
	end
	-- Locale results
	if pass == 0 then
		print("[FAIL ALL]", locale)
	elseif fail ~= 0 then
		print(("[FAIL %s/%s]"):format(fail, fail+pass), locale)
	else
		print("[PASS]", localse)
	end
end

--@end-do-not-package@
