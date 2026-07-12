-- Retail master loot: removed in 8.0.1, back in 12.0.5 (CN-realm-only).
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local addon, L = XLoot:NewModule("Master")
XLootMaster = addon

local LOOT_SLOT_ITEM = LOOT_SLOT_ITEM or Enum.LootSlotType.Item
local MASTER_LOOTER_METHOD = Enum.LootMethod.Masterlooter

-- Keys mirror Master.lua so Options.lua builds the same panel on retail.
local defaults = {
	profile = {
		menu_roll = true,
		menu_disenchant = true,
		menu_disenchanters = "",
		menu_bank = true,
		menu_bankers = "",
		menu_self = true,
		confirm_qualitythreshold = MASTER_LOOT_THREHOLD or 2,
		award_qualitythreshold = 2,
		award_channel = 'AUTO',
		award_channel_secondary = 'NONE',
		award_guildannounce = false,
		award_special = true,
	}
}

local opt
local eframe = CreateFrame("Frame")
local me
local issecret = issecretvalue -- 12.0 secret values; nil pre-12.0

function addon:OnInitialize()
	self:InitializeModule(defaults, eframe)
	opt = self.db.profile
	XLootMaster.opt = opt
	XLoot:SetSlashCommand("xlml", addon.SlashHandler)
	XLoot:SetSlashCommand("xlmltest", addon.ToggleTest)
	XLoot:SetSlashCommand("xlmldebug", addon.ToggleDebug)
end

function addon.OnEnable()
	me = UnitName("player")
	-- Drop the native master-loot trigger; under XLoot's suppressed LootFrame it anchors to nil and errors.
	if EventRegistry and EventRegistry.UnregisterFrameEventAndCallback then
		local n = 0
		for i = 1, 4 do
			local frame = _G["GroupLootFrame"..i]
			if frame then
				EventRegistry:UnregisterFrameEventAndCallback("OPEN_MASTER_LOOT_LIST", frame)
				n = n + 1
			end
		end
		addon.dprint(("unregistered native OPEN_MASTER_LOOT_LIST on %d GroupLootFrame(s)."):format(n))
	end
end

function addon.SlashHandler()
	addon.ShowOptions()
end

local function xprint(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99XLootMaster|r: "..msg)
	end
end

function addon.dprint(msg)
	if addon.debug then xprint("|cffff8800[debug]|r "..msg) end
end

function addon.ToggleDebug()
	addon.debug = not addon.debug
	xprint(addon.debug and "verbose debug ON — award/announce/detection steps will print." or "verbose debug OFF.")
end

local function ClassColor(class)
	if class and C_ClassColor and C_ClassColor.GetClassColor then
		return C_ClassColor.GetClassColor(class)
	end
	return class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or nil
end

local function ColorName(name, class)
	local color = ClassColor(class)
	if color and color.WrapTextInColorCode then
		return color:WrapTextInColorCode(name)
	end
	return name
end

local function LocalizedClassName(class)
	return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
end

local function MasterLootActive()
	if not (C_PartyInfo and C_PartyInfo.GetLootMethod) then return false end
	return (C_PartyInfo.GetLootMethod()) == MASTER_LOOTER_METHOD
end

local function OutChannel(channel)
	if channel == "NONE" then return end
	if channel ~= "AUTO" then return channel end
	if IsInRaid() then
		if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant() then
			return "RAID_WARNING"
		end
		return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
	elseif IsInGroup() then
		return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
	end
	return "SAY"
end

local function AnnounceAward(quality, link, pname, special)
	if not (quality and link and pname) then return end
	if quality < (opt.award_qualitythreshold or 2) then return end
	if special and not opt.award_special then return end
	local text = (L.ITEM_AWARDED or "%s awarded: %s"):format(pname, link)
	if special then text = text.." ("..special..")" end
	local primary = OutChannel(opt.award_channel)
	if primary then
		addon.dprint(("announce [%s]: %s"):format(primary, text))
		pcall(SendChatMessage, text, primary)
	end
	local secondary = OutChannel(opt.award_channel_secondary)
	if secondary then pcall(SendChatMessage, text, secondary) end
	if opt.award_guildannounce and IsInGuild() then
		pcall(SendChatMessage, text, "GUILD")
	end
end

local function normalize_toon_list(str)
	str = (str or ""):gsub("%s+", ",")
	str = str:gsub("%p+", ",")
	str = str:lower()
	return ","..str..","
end

local function listPriority(name, list)
	return (normalize_toon_list(list):find(normalize_toon_list(name), 1, true))
end

-- Real master loot is CN-server-only; fake candidates let /xlmltest preview the menu anywhere.
addon.test_candidates = {
	{ name = "Banker", class = "WARRIOR" },
	{ name = "Disenchanter", class = "MAGE" },
	{ name = "Sylvanas", class = "HUNTER" },
	{ name = "Thrall", class = "SHAMAN" },
	{ name = "Uther", class = "PALADIN" },
}

function addon.ToggleTest()
	addon.testing = not addon.testing
	xprint(addon.testing and "candidate-menu test mode ON — right-click a loot row." or "test mode OFF.")
end

local function CollectCandidates(slot)
	local list = {}
	if addon.testing then
		local lc, ec = UnitClass("player")
		list[1] = { index = 1, name = me, class = ec, classLocalized = lc }
		for i, c in ipairs(addon.test_candidates) do
			list[i + 1] = { index = i + 1, name = c.name, class = c.class, classLocalized = LocalizedClassName(c.class) }
		end
		return list
	end
	for i = 1, MAX_RAID_MEMBERS do
		local name, classLocalized, class = GetMasterLootCandidate(slot, i)
		if name then
			list[#list + 1] = { index = i, name = name, class = class, classLocalized = classLocalized }
		end
	end
	return list
end

-- self / banker / disenchanter shortcuts; test mode keys off the fixed names above so they preview off-CN.
local function ResolveSpecial(candidates)
	local result = {}
	if addon.testing then
		for _, c in ipairs(candidates) do
			if opt.menu_self and c.name == me then result.self = c end
			if opt.menu_bank and c.name == "Banker" then result.banker = c end
			if opt.menu_disenchant and c.name == "Disenchanter" then result.disenchanter = c end
		end
		return result
	end
	local bank_rank, de_rank = math.huge, math.huge
	for _, c in ipairs(candidates) do
		if opt.menu_self and c.name == me then
			result.self = c
		end
		if opt.menu_bank then
			local r = listPriority(c.name, opt.menu_bankers)
			if r and r < bank_rank then result.banker = c; bank_rank = r end
		end
		if opt.menu_disenchant then
			local r = listPriority(c.name, opt.menu_disenchanters)
			if r and r < de_rank then result.disenchanter = c; de_rank = r end
		end
	end
	return result
end

local function GroupByClass(candidates)
	local groups = {}
	for _, c in ipairs(candidates) do
		local key = c.class or "UNKNOWN"
		if not groups[key] then
			groups[key] = { class = c.class, classLocalized = c.classLocalized or LocalizedClassName(c.class), players = {} }
		end
		table.insert(groups[key].players, c)
	end
	return groups
end

local function InRaidMode()
	return addon.testing or IsInRaid()
end

-- The index is captured when the menu opens; re-check it still maps to the same player at award time.
local function CandidateValid(slot, index, name)
	return GetMasterLootCandidate(slot, index) == name
end

StaticPopupDialogs["XLOOT_MASTER_DISTRIBUTE"] = {
	text = CONFIRM_LOOT_DISTRIBUTION or "Assign %s to %s?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, data)
		if data and CandidateValid(data.slot, data.index, data.name) then
			AnnounceAward(data.quality, data.link, data.name, data.special)
			addon.dprint(("GiveMasterLoot(slot=%d, index=%d) -> %s"):format(data.slot, data.index, data.name))
			GiveMasterLoot(data.slot, data.index)
		elseif data then
			xprint(L.CANDIDATE_UNAVAILABLE or "That player is no longer eligible to receive loot.")
		end
	end,
	timeout = 0,
	hideOnEscape = 1,
	preferredIndex = 3,
}

local roll_pending

local function Award(slot, candidate, link, quality, special)
	-- Test mode must never reach GiveMasterLoot with a fake index.
	if addon.testing then
		xprint(("[test] would assign %s to %s%s (slot %d, candidate %d)."):format(
			tostring(link), candidate.name, special and (" ["..special.."]") or "", slot, candidate.index))
		return
	end
	if quality and quality >= (opt.confirm_qualitythreshold or 2) then
		local dialog = StaticPopup_Show("XLOOT_MASTER_DISTRIBUTE", link or candidate.name, candidate.name)
		if dialog then
			dialog.data = { slot = slot, index = candidate.index, name = candidate.name, link = link, quality = quality, special = special }
		end
	elseif CandidateValid(slot, candidate.index, candidate.name) then
		AnnounceAward(quality, link, candidate.name, special)
		addon.dprint(("GiveMasterLoot(slot=%d, index=%d) -> %s"):format(slot, candidate.index, candidate.name))
		GiveMasterLoot(slot, candidate.index)
	else
		xprint(L.CANDIDATE_UNAVAILABLE or "That player is no longer eligible to receive loot.")
	end
end

local function RaidRoll(slot, candidates, link, quality)
	local count = #candidates
	if count < 1 then return end
	if addon.testing then
		xprint(("[test] would raid-roll %s among %d candidate(s)."):format(tostring(link), count))
		return
	end
	local out = OutChannel("AUTO")
	if out then
		pcall(SendChatMessage, (L.ML_RANDOM or "Raid Roll")..": "..(link or ""), out)
		local line = ""
		for k, c in ipairs(candidates) do
			line = (line == "") and (k..": "..c.name) or (line..", "..k..": "..c.name)
			if k == count or k % 3 == 0 then
				pcall(SendChatMessage, line, out)
				line = ""
			end
		end
	end
	roll_pending = { slot = slot, candidates = candidates, link = link, quality = quality, count = count }
	eframe:RegisterEvent("CHAT_MSG_SYSTEM")
	RandomRoll(1, count)
end

-- RandomRoll(1, count) returns a position into `candidates`, not a loot-slot index.
function addon.CHAT_MSG_SYSTEM(_, ...)
	if not roll_pending then return end
	local who, roll, low, high = XLoot.Deformat(..., RANDOM_ROLL_RESULT)
	roll = tonumber(roll)
	if who ~= me or not roll or tonumber(low) ~= 1 or tonumber(high) ~= roll_pending.count then return end
	local pending = roll_pending
	roll_pending = nil
	eframe:UnregisterEvent("CHAT_MSG_SYSTEM")
	local winner = pending.candidates[roll]
	if winner then
		Award(pending.slot, winner, pending.link, pending.quality)
	end
end

function addon.ShowAssignMenu(row)
	local slot = row.slot
	local candidates = CollectCandidates(slot)
	if #candidates == 0 then return end
	local link = addon.testing and "[Test Item]" or GetLootSlotLink(slot)
	if issecret and issecret(link) then link = nil end
	local quality = row.quality or 0
	local raid = InRaidMode()
	local special = raid and ResolveSpecial(candidates) or nil

	MenuUtil.CreateContextMenu(row, function(_, root)
		root:SetTag("MENU_XLOOT_MASTER")
		root:CreateTitle(GIVE_LOOT or "Give Loot")

		if raid then
			local groups = GroupByClass(candidates)
			for _, class in ipairs(CLASS_SORT_ORDER) do
				local group = groups[class]
				if group then
					table.sort(group.players, function(a, b) return a.name < b.name end)
					local submenu = root:CreateButton(ColorName(group.classLocalized, class))
					for _, c in ipairs(group.players) do
						submenu:CreateButton(ColorName(c.name, c.class), function()
							Award(slot, c, link, quality)
						end)
					end
				end
			end
		else
			for _, c in ipairs(candidates) do
				root:CreateButton(ColorName(c.name, c.class), function()
					Award(slot, c, link, quality)
				end)
			end
		end

		if special and (special.self or special.banker or special.disenchanter) then
			local sub = root:CreateButton(L.RECIPIENTS or "Special Recipients")
			if special.self then
				sub:CreateButton(ColorName(L.ML_SELF or "Self Loot", special.self.class), function()
					Award(slot, special.self, link, quality, L.ML_SELF)
				end)
			end
			if special.banker then
				sub:CreateButton((L.ML_BANKER or "Banker").." ("..special.banker.name..")", function()
					Award(slot, special.banker, link, quality, L.ML_BANKER)
				end)
			end
			if special.disenchanter then
				sub:CreateButton((L.ML_DISENCHANTER or "Disenchanter").." ("..special.disenchanter.name..")", function()
					Award(slot, special.disenchanter, link, quality, L.ML_DISENCHANTER)
				end)
			end
		end

		local rolls = root:CreateButton(L.SPECIALROLLS or "Special Rolls")
		-- DoMasterLootRoll was removed from every client flavor in 12.x with no replacement, so drop the item when it is gone.
		if DoMasterLootRoll then
			rolls:CreateButton(REQUEST_ROLL or "Request Roll", function()
				if addon.testing then
					xprint(("[test] would request roll on slot %d."):format(slot))
				else
					DoMasterLootRoll(slot)
				end
			end)
		end
		if raid and opt.menu_roll then
			rolls:CreateButton(L.ML_RANDOM or "Raid Roll", function()
				RaidRoll(slot, candidates, link, quality)
			end)
		end
	end)
end

function addon.ShouldHandle(row, button)
	if not row or not row.slot then return false end
	if button ~= "LeftButton" and button ~= "RightButton" then return false end
	if GetLootSlotType(row.slot) ~= LOOT_SLOT_ITEM then return false end
	if addon.testing then return button == "RightButton" end
	if not MasterLootActive() then return false end
	-- Take both clicks here so XLoot never LootSlots a master-lootable item and trips the native flow.
	local handle = GetMasterLootCandidate(row.slot, 1) ~= nil
	if handle then addon.dprint(("master-loot row clicked (slot %d, %s)."):format(row.slot, button)) end
	return handle
end

local XLootButtonOnClick_Orig = XLootButtonOnClick
function XLootButtonOnClick(row, button, handled)
	if not handled and addon.ShouldHandle(row, button) then
		handled = true
		addon.ShowAssignMenu(row)
	end
	return XLootButtonOnClick_Orig(row, button, handled)
end

BINDING_HEADER_XLOOTMASTER = "XLootMaster"
