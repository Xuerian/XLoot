-- Create module
local addon, L = XLoot:NewModule("Group")
-- Prepare global
XLootGroup = addon
-- Grab locals
local opt, anchor, alert_anchor, mouse_focus, Skinner
local rolls = {}
local auto_rolled = {}
local pending_rolls = {}
local drop_to_roll = {}
local FakeHistory
local fake_seq = 0
local GetLootRollItemInfo, GetLootRollItemLink, GetLootRollTimeLeft, RollOnLoot, UnitGroupRolesAssigned, print, string_format
	= GetLootRollItemInfo, GetLootRollItemLink, GetLootRollTimeLeft, RollOnLoot, UnitGroupRolesAssigned, print, string.format
-- C_LootHistory is nil on some Classic builds, so indexing it at file load would crash the module.
local HistoryGetItem = C_LootHistory and C_LootHistory.GetItem
local HistoryGetPlayerInfo = C_LootHistory and C_LootHistory.GetPlayerInfo
local HistoryGetNumItems = C_LootHistory and C_LootHistory.GetNumItems
-- Retail only, added in 10.1.0. Nil on Classic.
local HistoryGetSortedInfoForDrop = C_LootHistory and C_LootHistory.GetSortedInfoForDrop
local CanEquipItem, IsItemUpgrade, FancyPlayerName = XLoot.CanEquipItem, XLoot.IsItemUpgrade, XLoot.FancyPlayerName
local IsIlvlUpgrade, IsNewAppearance, TimeFractionColor = XLoot.IsIlvlUpgrade, XLoot.IsNewAppearance, XLoot.TimeFractionColor
local RollFramePrototype
-- Defined in the retail roll-status block, used above it.
local HoldForResult
local AWAIT_TIMEOUT = 360 -- seconds, past the longest retail roll window

local BUILD_NUMBER = select(4, GetBuildInfo())
local IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local BUILD_HAS_DISENCHANT = not IS_RETAIL and BUILD_NUMBER >= 30300
local HAS_TRANSMOG = IS_RETAIL

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetDetailedItemLevelInfo = C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local issecret = issecretvalue -- 12.0 secret values, nil pre-12.0

local ENUM_LOOT_GROUP = Enum and Enum.LootMethod and Enum.LootMethod.Group
local ENUM_LOOT_NEEDBEFOREGREED = Enum and Enum.LootMethod and Enum.LootMethod.Needbeforegreed

-- The string GetLootMethod() global is gone on modern Classic/retail builds. Prefer the C_PartyInfo enum, fall back to the global.
local function RollBasedLootMethod()
	if ENUM_LOOT_GROUP and C_PartyInfo and C_PartyInfo.GetLootMethod then
		local method = C_PartyInfo.GetLootMethod()
		return method == ENUM_LOOT_GROUP or method == ENUM_LOOT_NEEDBEFOREGREED
	end
	if GetLootMethod then
		local method = GetLootMethod()
		return method == 'group' or method == 'needbeforegreed'
	end
	return false
end

-------------------------------------------------------------------------------
-- Settings

local defaults = {
	profile = {
		role_icon = true,
		win_icon = false,
		show_decided = true,
		show_undecided = false,
		show_time_remaining = false,
		text_ilvl = false,
		roll_urgency = false,

		roll_highlight = false,
		roll_highlight_upgrade = true,
		roll_highlight_newlook = true,

		auto_roll = false,
		auto_roll_need = false,
		auto_roll_rules = {},

		equip_prefix = true,
		prefix_equippable = "*",
		prefix_upgrade = "+",

		hook_alert = false,
		alert_skin = true,
		alert_alpha = 1,
		alert_scale = 1,
		alert_offset = 4,
		alert_background = false,
		alert_icon_frame = false,

		hook_bonus = false,
		bonus_skin = true,

		roll_button_size = 28,
		roll_width = 325,

		font = STANDARD_TEXT_FONT,
		font_flag = "OUTLINE",

		roll_anchor = {
			direction = 'up',
			spacing = 2,
			offset = 0,
			visible = true,
			draggable = true,
			scale = 1.0,
			x = UIParent:GetWidth() * .75,
			y = UIParent:GetHeight() * .4
		},

		alert_anchor = {
			visible = true,
			direction = 'up',
			draggable = true,
			scale = 1.0,
			x = AlertFrame:GetLeft(),
			y = AlertFrame:GetTop()
		},

		roll_status = false,
		track_all = false,
		track_player_roll = false,
		track_by_threshold = true,
		track_threshold = 3,

		expire_won = 20,
		expire_lost = 10,
		shown_hook_warning = false
	}
}

opt = defaults.profile

-------------------------------------------------------------------------------
-- Module init

local eframe = CreateFrame("Frame")
function addon:OnInitialize()
	self:InitializeModule(defaults, eframe)
	opt = self.db.profile
	XLootGroup.opt = opt
	-- Extra slash command
	XLoot:SetSlashCommand("xlg", self.SlashHandler)
end

-- GroupLootFrame1..N are UIParent frames only anchored into GroupLootContainer, so hiding the container never suppressed them and only collided with bonus rolls, which anchor into that same container. Hide the roll frames directly and catch any re-show. A reload or zone-in during a roll rebuilds them via frame:Show outside START_LOOT_ROLL, which the frame hook catches.
local function HideRollFrame(frame)
	frame:Hide()
	-- Route through RemoveFrame so the invisible layout container self-collapses, without ever hooking its Show.
	if GroupLootContainer and GroupLootContainer_RemoveFrame then
		GroupLootContainer_RemoveFrame(GroupLootContainer, frame)
	end
end

local roll_ui_hooked = false
local function SuppressDefaultRollUI()
	for i = 1, (NUM_GROUP_LOOT_FRAMES or 4) do
		local f = _G["GroupLootFrame"..i]
		if f then
			f:UnregisterAllEvents()
			HideRollFrame(f)
			if not roll_ui_hooked then
				hooksecurefunc(f, "Show", HideRollFrame)
			end
		end
	end
	-- Only mark hooked once the frames exist, or a call before Blizzard creates them would skip hooking for good.
	if _G["GroupLootFrame1"] then roll_ui_hooked = true end
end

function addon:OnEnable()
	-- Register events
	eframe:RegisterEvent('START_LOOT_ROLL')
	eframe:RegisterEvent('MODIFIER_STATE_CHANGED')
	eframe:RegisterEvent('CONFIRM_LOOT_ROLL')

	if IS_RETAIL then
		eframe:RegisterEvent('CANCEL_LOOT_ROLL')
		eframe:RegisterEvent('CANCEL_ALL_LOOT_ROLLS')
		self:UpdateRetailStatusEvents()
	elseif C_LootHistory then
		eframe:RegisterEvent('LOOT_HISTORY_ROLL_CHANGED')
		eframe:RegisterEvent('LOOT_HISTORY_ROLL_COMPLETE')
		eframe:RegisterEvent('LOOT_ROLLS_COMPLETE')
	end

	-- Disable default frame
	UIParent:UnregisterEvent("START_LOOT_ROLL")
	UIParent:UnregisterEvent("CANCEL_LOOT_ROLL")
	SuppressDefaultRollUI()
	eframe:RegisterEvent('PLAYER_ENTERING_WORLD')

	-- Set up skins
	Skinner = {}
	XLoot:MakeSkinner(Skinner, {
		anchor = { r = .4, g = .4, b = .4, a = .6, gradient = false },
		anchor_pretty = { r = .6, g = .6, b = .6, a = .8 },
		row = { gradient = false },
		item = { backdrop = false },
		alert = { gradient = true },
		alert_item = { gradient = true, backdrop = false },
		bonus = { }
	}, 'row')

	-- Create Roll anchor
	anchor = XLoot.Stack:CreateStaticStack(function() return RollFramePrototype:New() end, L.anchor, opt.roll_anchor)
	anchor:SetFrameLevel(7)
	anchor:Scale(opt.roll_anchor.scale)
	addon.anchor = anchor

	-- Create alert anchor
	alert_anchor = XLoot.Stack:CreateAnchor(L.alert_anchor, opt.alert_anchor)
	alert_anchor:SetFrameLevel(7)
	addon.alert_anchor = alert_anchor
	--  DISABLED-PATCH: LEGION PRE-PATCH
	alert_anchor.Show = alert_anchor.Hide
	alert_anchor:Hide()

	-- Skin anchor
	Skinner:Skin(anchor, XLoot.opt.skin_anchors and 'anchor_pretty' or 'anchor')
	Skinner:Skin(alert_anchor, XLoot.opt.skin_anchors and 'anchor_pretty' or 'anchor')

	-- Row fader
	local fader = CreateFrame('Frame')
	local timer = 0
	fader:SetScript('OnUpdate', function(self, elapsed)
		if timer < 1 then
			timer = timer + elapsed
		else
			timer = 0
			local time = GetTime()
			-- Extend expiration for mouseovered frames
			if mouse_focus and mouse_focus.aexpire and (mouse_focus.aexpire - time) < 5 then
				mouse_focus.aexpire = time + 5
			end
			for i=#anchor.expiring,1,-1 do
				local frame = anchor.expiring[i]
				if frame.aexpire and time > frame.aexpire then
					anchor:Pop(frame)
					table.remove(anchor.expiring, i)
				end
			end
			if not next(anchor.expiring) then
				self:Hide()
			end
		end
	end)
	anchor.expiring = {}
	function anchor:Expire(frame, time)
		fader:Show()
		table.insert(self.expiring, frame)
		frame.aexpire = GetTime() + time
	end

	-- Find and show active rolls
	if IsInGroup() and (IS_RETAIL or RollBasedLootMethod()) then
		for i=1,300 do
			local time = GetLootRollTimeLeft(i)
			if time > 0 and time <  300000 then
				self:START_LOOT_ROLL(i, time, true)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Frame helpers

-------------------------------------------------------------------------------
-- Event handlers

addon.bars = {}
local type_strings = {
	need = NEED,
	greed = GREED,
	disenchant = ROLL_DISENCHANT,
	pass = PASS
}
local rtypes = { [0] = 'pass', 'need', 'greed', 'disenchant' } -- Tekkub. Writing smaller addons than me since ever.

-- Roll-border highlight colors, matched to the (upgrade)/(new look) loot-row tags
local HIGHLIGHT_UPGRADE, HIGHLIGHT_NEWLOOK = { 30/255, 1, 0 }, { 102/255, 204/255, 1 }

local function RollBorderColor(link, r, g, b)
	if opt.roll_highlight and link and not (issecret and issecret(link)) then
		if opt.roll_highlight_upgrade and IsIlvlUpgrade(link) then
			return unpack(HIGHLIGHT_UPGRADE)
		elseif opt.roll_highlight_newlook and IsNewAppearance(link) then
			return unpack(HIGHLIGHT_NEWLOOK)
		end
	end
	return r, g, b
end

function addon:START_LOOT_ROLL(id, length, ongoing)
	local icon, name, count, quality, bop, need, greed, de, reason_need, reason_greed, reason_de, de_skill, can_transmog = GetLootRollItemInfo(id)
	-- LootFrame.lua includes this sanity check (== nil is a blocked op on a secret name, not is allowed)
	if not name or (issecret and issecret(name)) then
		-- a secret value (tainted 12.0 roll) can't be built, so bail. A plain nil name just means the item is not cached yet, so wait for it and retry instead of dropping the roll until a reload
		local link = GetLootRollItemLink(id)
		local itemid = link and not (issecret and issecret(link)) and GetItemInfoInstant(link)
		if itemid and pending_rolls[id] ~= itemid and Item then
			pending_rolls[id] = itemid
			Item:CreateFromItemID(itemid):ContinueOnItemLoad(function()
				local remaining = GetLootRollTimeLeft(id)
				if remaining > 0 then addon:START_LOOT_ROLL(id, remaining, true) end
				pending_rolls[id] = nil
			end)
		end
		return
	end
	local link = GetLootRollItemLink(id)
	local r, g, b = C_Item.GetItemQualityColor(quality)

	-- Clear any stale marker so a recycled id can't auto-confirm a later manual roll.
	auto_rolled[id] = nil
	if opt.auto_roll and link and not (issecret and issecret(link)) and not XLoot.GroupUsesMasterLoot() then
		local itemid = GetItemInfoInstant(link)
		local rule = itemid and opt.auto_roll_rules[itemid]
		if rule and (rule == 0
			or (rule == 2 and greed)
			or (rule == 1 and need and opt.auto_roll_need)
			or (rule == 3 and de)) then
			RollOnLoot(id, rule)
			auto_rolled[id] = true
			return
		end
	end

	local start = length
	-- The retail START_LOOT_ROLL event passes a lootHandle third, so only a literal true means ongoing.
	if ongoing == true then
		if not (issecret and issecret(quality)) and quality == 2 then
			length = 60000
		else
			length = 180000
		end
		-- Reload only knows remaining time, so the assumed total cannot be less than it
		if start > length then length = start end
	end
	length, start = length/1000, start/1000

	local frame = anchor:Push()
	rolls[id] = frame

	frame.need:Show()
	frame.greed:Show()
	if frame.disenchant then
		frame.disenchant:Show()
	end
	if frame.transmog then
		frame.transmog:Show()
	end
	frame.pass:Show()
	frame.text_status:Hide()
	frame.text_status:SetText()
	frame.text_time:SetShown(opt.show_time_remaining)

	frame.need.texture_special:SetTexture()
	frame.greed.texture_special:SetTexture()

	if opt.equip_prefix then
		local canequip, isupgrade = CanEquipItem(link), IsItemUpgrade(link)
		if canequip or isupgrade then
			name = string_format("|cFF%s%s|r%s", isupgrade and "44FF22" or "BBBBBB", isupgrade and opt.prefix_upgrade or opt.prefix_equippable, name)
			if isupgrade then
				(need and frame.need or frame.greed).texture_special:SetTexture([[Interface\AddOns\Pawn\Textures\UpgradeArrow.tga]])
			end
		end
	end
	frame.need:Toggle(need)
	frame.greed:Toggle(greed and not can_transmog)
	if frame.disenchant then frame.disenchant:Toggle(de) end
	if frame.transmog then frame.transmog:Toggle(can_transmog) end

	frame.need:SetText()
	frame.greed:SetText()
	frame.pass:SetText()
	if frame.disenchant then frame.disenchant:SetText() end
	if frame.transmog then frame.transmog:SetText() end

	frame.need.reason = reason_need ~= 0 and reason_need or nil
	frame.greed.reason = reason_greed ~= 0 and reason_greed or nil
	if frame.disenchant then
		frame.disenchant.reason = reason_de ~= 0 and reason_de or nil
		frame.disenchant.skill = de_skill ~= 0 and de_skill or nil
	end

	local bar = frame.bar
	bar.length = length
	bar.expires = GetTime() + start

	frame.link = link
	frame.rollid = id
	frame.rollended = nil
	frame.quality = quality
	frame.expires = bar.expires
	frame.over = nil
	frame.have_rolled = false
	frame.lead_type = 'pass'
	frame.drop_key = nil
	frame.awaiting = nil
	frame.await_until = nil

	frame.text_bind:SetText(bop and '|cffff4422BoP' or '')
	frame.text_loot:SetText(name)
	local ilvl = not (issecret and issecret(link)) and GetDetailedItemLevelInfo(link)
	frame.text_ilvl:SetText(ilvl and ilvl > 1 and ilvl or nil)

	frame.text_loot:SetVertexColor(r, g, b)
	local br, bg, bb = RollBorderColor(link, r, g, b)
	frame.overlay:SetBorderColor(br, bg, bb)
	frame.icon_frame:SetBorderColor(br, bg, bb)
	bar:SetStatusBarColor(r, g, b, .7)
	bar.base_r, bar.base_g, bar.base_b = r, g, b
	bar.base_br, bar.base_bg, bar.base_bb = br, bg, bb
	frame.icon:SetTexture(icon)

	bar:SetMinMaxValues(0, length)
	bar:SetValue(start)


	return frame
end

function addon:CANCEL_LOOT_ROLL(id)
	auto_rolled[id] = nil
	pending_rolls[id] = nil
	local frame = rolls[id]
	-- An over frame is owned by the fader, and popping it here would strand a stale expiry on the recycled frame.
	if frame and not frame.over then
		-- Retail cancels the roll the moment you choose but names the winner much later.
		if opt.roll_status and frame.drop_key then
			if not frame.awaiting then HoldForResult(frame) end
		else
			anchor:Pop(frame)
		end
	end
end

function addon:CANCEL_ALL_LOOT_ROLLS()
	wipe(auto_rolled)
	wipe(pending_rolls)
	wipe(drop_to_roll)
	for _, frame in pairs(rolls) do
		if not frame.over then
			anchor:Pop(frame)
		end
	end
end

function addon:PLAYER_ENTERING_WORLD()
	SuppressDefaultRollUI()
end

-- Rules change from shift-clicks outside the options dialog, so nudge AceConfig to redraw the live list.
local function NotifyOptions()
	local reg = LibStub("AceConfigRegistry-3.0", true)
	if reg then reg:NotifyChange("XLoot") end
end

function addon:CONFIRM_LOOT_ROLL(rollid, rtypeid)
	if auto_rolled[rollid] then
		ConfirmLootRoll(rollid, rtypeid)
		StaticPopup_Hide("CONFIRM_LOOT_ROLL")
		auto_rolled[rollid] = nil
	end
end

function addon.ToggleAutoRollRule(link, rtypeid)
	if rtypes[rtypeid] == nil or (issecret and issecret(link)) then return end
	local itemid = GetItemInfoInstant(link)
	if not itemid then return end
	local name = GetItemInfo(itemid) or link
	if opt.auto_roll_rules[itemid] == rtypeid then
		opt.auto_roll_rules[itemid] = nil
		print(L.auto_roll_removed:format(name))
	else
		opt.auto_roll_rules[itemid] = rtypeid
		print(L.auto_roll_saved:format(rtypes[rtypeid], name))
	end
	NotifyOptions()
end

function addon.ClearAutoRollRules()
	wipe(opt.auto_roll_rules)
	NotifyOptions()
end

function addon.AutoRollRulesText()
	local lines = {}
	for itemid, rtypeid in pairs(opt.auto_roll_rules) do
		lines[#lines+1] = ("%s: %s"):format(GetItemInfo(itemid) or ('item:'..itemid), rtypes[rtypeid] or '?')
	end
	if #lines == 0 then
		return L.auto_roll_none
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end

local tidx = { [0] = 1, [3] = 2, [2] = 2, [1] = 3 }
function addon:LOOT_HISTORY_ROLL_COMPLETE()
	-- Locate history item
	local hid, frame, rollid, players, done, _ = 1, nil, nil, nil, nil, nil
	while true do
		rollid, _, players, done = HistoryGetItem(hid)
		if not rollid or (rolls[rollid] and rolls[rollid].over) then
			return
		elseif done and rolls[rollid] then
			frame = rolls[rollid]
			break
		end
		hid = hid+1
	end

	-- Active frame found
	frame.over = true
	local top_type, top_roll, top_pid, top_is_me = 0, 0, nil, nil
	for j=1, players do
		local name, class, rtype, roll, is_winner, is_me = HistoryGetPlayerInfo(hid, j)
		-- roll = roll and roll or true
		if is_winner then
			top_pid = j
			top_is_me = is_me
			break
		elseif rtype ~= 0 and tidx[rtype] >= tidx[top_type] and (not roll or roll > top_roll) then
			top_type = rtype
			top_roll = roll
			top_pid = j
		end
	end

	-- Winner or lead
	if top_pid then
		local name, class = HistoryGetPlayerInfo(hid, top_pid)
		local player, r, g, b = FancyPlayerName(name, class, opt)
		if opt.win_icon then
			if top_type == 'need' then
				player = [[|TInterface\Buttons\UI-GroupLoot-Dice-Up:16:16:-1:-1|t]]..player
			elseif top_type == 'greed' then
				player = [[|TInterface\Buttons\UI-GroupLoot-Coin-Up:16:16:-1:-2|t]]..player
			elseif top_type == 'disenchant' then
				player = [[|TInterface\Buttons\UI-GroupLoot-DE-Up:16:16:-1:-1|t]]..player
			end
		end
		frame.text_status:SetText(player)
		frame.text_status:SetTextColor(r, g, b)
		frame.bar.expires = GetTime()
		anchor:Expire(frame, top_is_me and opt.expire_won or opt.expire_lost)
	else
	-- No winner/lead
		frame.text_status:SetText(string_format('%s: %s', PASS, ALL))
		frame.text_status:SetTextColor(.7, .7, .7)
		frame.bar.expires = GetTime()
		anchor:Expire(frame, opt.expire_lost)
	end
	-- Refresh tooltip
	if frame and mouse_focus == frame then
		frame:OnEnter()
	end
end
addon.LOOT_ROLLS_COMPLETE = addon.LOOT_HISTORY_ROLL_COMPLETE

local rweights = { need = 3, greed = 2, disenchant = 2, pass = 1 }
function addon:LOOT_HISTORY_ROLL_CHANGED(hid, pid)
	-- Acquire roll information and frame
	local rollid, link, players, done = HistoryGetItem(hid)
	local frame = rolls[rollid]
	if not frame or frame.rollid ~= rollid or not frame:IsShown() then
		return nil
	end

	-- Acquire player information
	local name, class, rtypeid, roll, winner, is_me = HistoryGetPlayerInfo(hid, pid)
	local rtype = rtypes[rtypeid]

	-- Transition or expire frame on player roll
	if is_me then
		if 	opt.track_all
			or (opt.track_player_roll and rtype ~= 'pass')
			or (opt.track_by_threshold and frame.quality >= opt.track_threshold) then
			frame.need:Hide()
			frame.greed:Hide()
			if frame.disenchant then frame.disenchant:Hide() end
			frame.pass:Hide()
			frame.text_status:Show()
			frame.have_rolled = true
		else
			anchor:Pop(frame)
			return
		end
	end

	-- Update post-player-roll status text
	if frame.have_rolled then
		local rtype = rtype == 'disenchant' and 'greed' or rtype
		-- Roll of leading type or higher (rtype is nil until a player picks)
		if rtype and rweights[rtype] >= rweights[frame.lead_type] then
			frame.lead_type = rtype
			local bracket, mtype = 0, nil
			for i=1, players do
				local _, _, ptype, _, _, is_me = HistoryGetPlayerInfo(hid, i)
				local ptype = rtypes[ptype == 3 and 2 or ptype]
				if ptype == rtype then
					bracket = bracket + 1
				end
				if is_me then
					mtype = ptype
				end
			end

			local r, g, b = .7, .7, .7
			if mtype == rtype then
				r, g, b = .2, 1, .1
			elseif mtype and mtype ~= 0 then
				r, g, b = 1, .2, .1
			end
			frame.text_status:SetText(string_format('%s: %s', type_strings[rtype], bracket))
			frame.text_status:SetTextColor(r, g, b)
		end

	-- Update roll button counters
	else
		local bracket = 0
		for i=1, players do
			local _, _, thistype = HistoryGetPlayerInfo(hid, i)
			if thistype == rtypeid then
				bracket = bracket + 1
			end
		end
		local btn = frame[rtype]
		if btn then btn:SetText(bracket) end
	end

	-- Refresh tooltip
	if frame and mouse_focus == frame then
		frame:OnEnter()
	end
end

local retail_state_type
do
	local S = Enum and Enum.EncounterLootDropRollState
	if S then
		retail_state_type = {
			[S.NeedMainSpec] = 'need',
			[S.NeedOffSpec] = 'need',
			[S.Transmog] = 'transmog',
			[S.Greed] = 'greed',
			[S.Pass] = 'pass'
		}
	end
end

local function DropKey(encounterID, lootListID)
	return (encounterID or 0) * 100000 + (lootListID or 0)
end

local function DropItemID(link)
	if not link or (issecret and issecret(link)) then return nil end
	return GetItemInfoInstant(link)
end

-- rollID and lootListID are unrelated ID spaces with no bridge, so drops join by item link.
-- Without bind a completed drop is never bound fresh, so a late winner cannot attach to an unrelated new roll.
local function ResolveRetailFrame(encounterID, lootListID, link, bind)
	local key = DropKey(encounterID, lootListID)
	local cached = drop_to_roll[key]
	if cached and rolls[cached.rollid] == cached then
		return cached
	end
	if not bind then return nil end
	local want = DropItemID(link)
	if not want then return nil end
	-- Oldest match first so duplicate identical drops bind FIFO, and never rebind a completed frame.
	local best
	for id, frame in pairs(rolls) do
		if not frame.drop_key and not frame.over and DropItemID(frame.link) == want and (not best or id < best.rollid) then
			best = frame
		end
	end
	if best then
		best.drop_key = key
		drop_to_roll[key] = best
	end
	return best
end

local win_icons = {
	need = [[|TInterface\Buttons\UI-GroupLoot-Dice-Up:16:16:-1:-1|t]],
	greed = [[|TInterface\Buttons\UI-GroupLoot-Coin-Up:16:16:-1:-2|t]],
	transmog = [[|TInterface\MINIMAP\TRACKING\Transmogrifier:16:16:-1:-1|t]]
}

local function HideRollButtons(frame)
	frame.need:Hide()
	frame.greed:Hide()
	if frame.disenchant then frame.disenchant:Hide() end
	if frame.transmog then frame.transmog:Hide() end
	frame.pass:Hide()
	frame.text_status:Show()
end

function HoldForResult(frame)
	frame.awaiting = true
	frame.await_until = GetTime() + AWAIT_TIMEOUT
	HideRollButtons(frame)
	frame.text_status:SetText(L.awaiting)
	frame.text_status:SetTextColor(.7, .7, .7)
	frame.bar.spark:Hide()
	frame.bar:SetValue(0)
	frame.text_time:SetText()
end

local function CompleteRetailDrop(frame, drop)
	if frame.over then return end
	frame.over = true
	frame.awaiting = nil
	HideRollButtons(frame)
	frame.bar.expires = GetTime()

	local winner = drop.winner
	if not winner or drop.allPassed then
		frame.text_status:SetText(string_format('%s: %s', PASS, ALL))
		frame.text_status:SetTextColor(.7, .7, .7)
		anchor:Expire(frame, opt.expire_lost)
	elseif issecret and (issecret(winner.playerName) or issecret(winner.playerClass)) then
		frame.text_status:SetText(UNKNOWN or '?')
		frame.text_status:SetTextColor(.7, .7, .7)
		anchor:Expire(frame, opt.expire_lost)
	else
		local player, r, g, b = FancyPlayerName(winner.playerName, winner.playerClass, opt)
		if opt.win_icon then
			local icon = win_icons[retail_state_type and retail_state_type[winner.state]]
			if icon then player = icon..player end
		end
		frame.text_status:SetText(player)
		frame.text_status:SetTextColor(r, g, b)
		anchor:Expire(frame, winner.isSelf and opt.expire_won or opt.expire_lost)
	end
	if mouse_focus == frame then frame:OnEnter() end
end

-- Split out so the /xlgd harness can drive a preview without toggling the option on.
local function ProcessRetailDrop(encounterID, lootListID)
	if not HistoryGetSortedInfoForDrop then return end
	local drop = HistoryGetSortedInfoForDrop(encounterID, lootListID)
	if not drop then return end
	local completed = drop.winner or drop.allPassed
	local frame = ResolveRetailFrame(encounterID, lootListID, drop.itemHyperlink, not completed)
	if not frame or frame.over then return end

	if completed then
		CompleteRetailDrop(frame, drop)
		return
	end

	-- Held bars have no buttons left to count on, so track the current leader instead.
	if frame.awaiting then
		local leader = drop.currentLeader
		if leader and not (issecret and (issecret(leader.playerName) or issecret(leader.playerClass))) then
			local player, r, g, b = FancyPlayerName(leader.playerName, leader.playerClass, opt)
			if opt.win_icon then
				local icon = win_icons[retail_state_type and retail_state_type[leader.state]]
				if icon then player = icon..player end
			end
			frame.text_status:SetText(player)
			frame.text_status:SetTextColor(r, g, b)
		end
		if mouse_focus == frame then frame:OnEnter() end
		return
	end

	local need, greed, transmog, pass = 0, 0, 0, 0
	local infos = drop.rollInfos
	if infos and retail_state_type then
		for i = 1, #infos do
			local t = retail_state_type[infos[i].state]
			if t == 'need' then need = need + 1
			elseif t == 'greed' then greed = greed + 1
			elseif t == 'transmog' then transmog = transmog + 1
			elseif t == 'pass' then pass = pass + 1 end
		end
	end
	frame.need:SetText(need)
	frame.greed:SetText(greed)
	if frame.transmog then frame.transmog:SetText(transmog) end
	frame.pass:SetText(pass)
	if mouse_focus == frame then frame:OnEnter() end
end

function addon:LOOT_HISTORY_UPDATE_DROP(encounterID, lootListID)
	if opt.roll_status then
		ProcessRetailDrop(encounterID, lootListID)
	end
end

function addon:LOOT_HISTORY_CLEAR_HISTORY()
	wipe(drop_to_roll)
	for _, frame in pairs(rolls) do
		frame.drop_key = nil
	end
end

function addon:UpdateRetailStatusEvents()
	if not IS_RETAIL or not HistoryGetSortedInfoForDrop then return end
	if opt.roll_status then
		eframe:RegisterEvent('LOOT_HISTORY_UPDATE_DROP')
		eframe:RegisterEvent('LOOT_HISTORY_CLEAR_HISTORY')
	else
		eframe:UnregisterEvent('LOOT_HISTORY_UPDATE_DROP')
		eframe:UnregisterEvent('LOOT_HISTORY_CLEAR_HISTORY')
		-- No result can arrive once the events are gone, so held bars would sit until they time out.
		for _, frame in pairs(rolls) do
			if frame.awaiting then anchor:Pop(frame) end
		end
	end
end

function addon:MODIFIER_STATE_CHANGED()
	if mouse_focus and MouseIsOver(mouse_focus) and mouse_focus.OnEnter then
		mouse_focus:OnEnter()
	end
end

local alert_frames = {}
function addon.AlertFrameHook(alert)
	-- Reskin toast
	local elements = alert_frames[alert]
	if not elements then
		elements = {}
		if not (opt.alert_background and opt.alert_icon_frame) then
			local name
			if alert.ItemName then
				name = alert.ItemName
				alert.Label:ClearAllPoints()
				alert.Label:SetPoint('TOPLEFT', alert.Icon, 'TOPRIGHT', 15, -5)
			elseif alert.BaseQualityItemName then
				name = alert.BaseQualityItemName
				alert.TitleText:ClearAllPoints()
				alert.TitleText:SetPoint('TOPLEFT', alert.Icon, 'TOPRIGHT', 15, -2)
			elseif alert.Amount then
				name = alert.Amount
				alert.Label:ClearAllPoints()
				alert.Label:SetPoint('TOPLEFT', alert.Icon, 'TOPRIGHT', 15, -2)
			end
			name:ClearAllPoints()
			name:SetPoint('LEFT', alert.Icon, 'RIGHT', 10, -6)
		end
		if opt.alert_skin then
			local overlay = CreateFrame('Frame', nil, alert, BackdropTemplateMixin and "BackdropTemplate")
			overlay:SetPoint('TOPLEFT', 11, -11)
			overlay:SetPoint('BOTTOMRIGHT', -11, 11)
			overlay:SetFrameLevel(alert:GetFrameLevel())
			elements.overlay = overlay
			Skinner:Skin(overlay, 'alert')
			if opt.alert_background then
				local backdrop = CreateFrame('Frame', nil, alert, BackdropTemplateMixin and "BackdropTemplate")
				backdrop:SetAllPoints(overlay)
				backdrop:SetFrameLevel(alert:GetFrameLevel()-1)
				overlay.gradient:SetParent(backdrop)
			end

			local icon_frame = CreateFrame('Frame', nil, alert, BackdropTemplateMixin and "BackdropTemplate")
			icon_frame:SetPoint('CENTER', alert.Icon, 'CENTER', 0, 0)
			icon_frame:SetWidth(alert.Icon:GetWidth() + 4)
			icon_frame:SetHeight(alert.Icon:GetHeight() + 4)
			elements.icon_frame = icon_frame
			Skinner:Skin(icon_frame, 'alert_item')
		end

		alert_frames[alert] = elements
	end
	alert.Background:SetShown(opt.alert_background)
	alert.IconBorder:SetShown(opt.alert_icon_frame)
	alert.BaseQualityBorder:SetShown(opt.alert_icon_frame)
	alert.UpgradeQualityBorder:SetShown(opt.alert_icon_frame)
	alert:SetAlpha(opt.alert_alpha)
	alert:SetScale(opt.alert_scale)

	-- Update toast
	if opt.alert_skin then
		local c
		if alert.hyperlink then
			local _, _, rarity = GetItemInfo(alert.hyperlink)
			c = ITEM_QUALITY_COLORS[rarity]
		else
			c = {r = 1, g = .8, b = 0.1}
		end
		if type(c) == "table" then -- Sanity check due to 5.4.1 reported error
			elements.overlay:SetGradientColor(c.r, c.g, c.b, .2)
			elements.icon_frame:SetGradientColor(c.r, c.g, c.b, .2)
			elements.overlay:SetBorderColor(c.r, c.g, c.b)
			elements.icon_frame:SetBorderColor(c.r, c.g, c.b)
		end
	end
end

local AlertFrameTables = {
	'LOOT_WON_ALERT_FRAMES',
	'LOOT_UPGRADE_ALERT_FRAMES',
	'MONEY_WON_ALERT_FRAMES'
}

function addon.SlashHandler(msg)
	if msg == 'reset' then
		anchor:Position()
		alert_anchor:Position()
	elseif msg == 'opt' or msg == 'options' then
		addon.ShowOptions()
	else
		addon.ToggleAnchors()
	end
end

function addon:UpdateAnchors()
	anchor:SetShown(opt.roll_anchor.visible)
	alert_anchor:SetShown(opt.alert_anchor.visible)
end

function addon.ToggleAnchors()
	local state = anchor:IsShown()
	anchor:SetShown(not state)
	alert_anchor:SetShown(not state)
end

-------------------------------------------------------------------------------
-- Frame creation

do
	local sf = string.format
	-- Add a specific roll type to the tooltip
	local function RollLines(list, hid)
		for _,pid in pairs(list) do
			local name, class, rtype, roll, is_winner, is_me = HistoryGetPlayerInfo(hid, pid)
			-- TODO- ACCOUNT FOR MISSING PLAYERS BETTER
			if not name then return nil end
			local text, r, g, b, color = FancyPlayerName(name, class, opt)
			if roll ~= nil then
				if is_winner then
					color = '44ff22'
				elseif is_me then
					color = 'ff2244'
				else
					color = 'CCCCCC'
				end
				GameTooltip:AddLine(sf('   |cff%s%s|r  %s', color, roll, text), r, g, b)
			else
				GameTooltip:AddLine('   '..text, r, g, b)
			end
		end
	end

	-- Add roll status or summary to tooltip
	local tneed, tgreed, tpass, trolls, tnone, table_sort
		= {}, {}, {}, {}, {}, table.sort
	local function rsort(a, b)
		a, b = trolls[a] or 0, trolls[b] or 0
		return a > b and true or false
	end

	local function AddIneligibleReason(button, r, g, b)
		if button.reason and _G["LOOT_ROLL_INELIGIBLE_REASON"..button.reason] then
			GameTooltip:AddLine(string_format(_G["LOOT_ROLL_INELIGIBLE_REASON"..button.reason], button.skill), r or .6, g or .6, b or .6)
			GameTooltip:Show()
		end
	end

	local function AddTooltipLines(self, show_all, show)
		-- Locate history item
		local rollid, hid = self.rollid, 1
		local hrollid, link, players, done
		while true do
			hrollid, link, players, done = HistoryGetItem(hid)
			if not hrollid then
				return
			elseif hrollid == rollid then
				break
			end
			hid = hid+1
		end

		-- Generate player lists
		local tneed, tgreed, tpass, tnone, trolls
			= wipe(tneed), wipe(tgreed), wipe(tpass), wipe(tnone), wipe(trolls)
		for pid=1, players do
			local _, _, rtype, roll = HistoryGetPlayerInfo(hid, pid)
			local t
			if rtype then
				if rtype == 0 then
					t = tpass
				elseif rtype == 1 then
					t = tneed
				elseif rtype == 2 or rtype == 3 then
					t = tgreed
				end
				trolls[pid] = roll
			else
				t = tnone
			end
			if t then
				t[#t+1] = pid
			end
		end

		table_sort(tneed, rsort)
		table_sort(tgreed, rsort)
		table_sort(tpass, rsort)

		-- Generate tooltip
		if show_all then
			GameTooltip:AddLine('.', 0, 0, 0)
		end
		if #tneed ~= 0 and (show_all or show == 1) then
			GameTooltip:AddLine(NEED, .2, 1, .1)
			RollLines(tneed, hid)
		end
		if #tgreed ~= 0 and (show_all or (show == 2 or show == 3)) then
			GameTooltip:AddLine(GREED, .1, .2, 1)
			RollLines(tgreed, hid)
		end
		if #tpass ~= 0 and (show_all or show == 0) then
			GameTooltip:AddLine(PASS, .7, .7, .7)
			RollLines(tpass, hid)
		end
		if show_all and opt.show_undecided then
			GameTooltip:AddLine(L.undecided, .7, .3, .2)
			RollLines(tnone, hid)
		end

		-- Force tooltip to refresh
		GameTooltip:Show()
		return true
	end

	---------------------------------------------------------------------------
	-- Roll buttons
	---------------------------------------------------------------------------
	local RollButtonPrototype = XLoot.NewPrototype()
	do
		function RollButtonPrototype:OnClick()
			local parent = self.parent
			if IsShiftKeyDown() then
				-- Transmog (type 4) has no rtypes entry, so only rule-able buttons set a rule.
				if parent.link and rtypes[self.type] then
					addon.ToggleAutoRollRule(parent.link, self.type)
				end
				return
			end
			RollOnLoot(parent.rollid, self.type)
		end

		function RollButtonPrototype:Toggle(status)
			if status then
				self:Enable()
				self:SetAlpha(1)
			else
				self:Disable()
				self:SetAlpha(.6)
			end
			SetDesaturation(self:GetNormalTexture(), not status)
		end

		function RollButtonPrototype:OnEnter()
			mouse_focus = self
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			if not IS_RETAIL then
				AddTooltipLines(self.parent, false, self.type)
			end
			if GameTooltip:NumLines() == 0 then
				GameTooltip:SetText(self.label, unpack(self.label_colors))
				GameTooltip:Show()
			end
			-- This is for those people who think they should be able
			--  to roll on something, can't, and then come complain to me.
			if self.reason then
				AddIneligibleReason(self, 1, .2, 0)
			end
		end

		function RollButtonPrototype:OnLeave()
			mouse_focus = nil
			GameTooltip:Hide()
		end

		function RollButtonPrototype:SetText(text)
			if text and text > 0 then
				self.text:SetText(text)
			else
				self.text:SetText()
			end
		end

		local path = [[Interface\Buttons\UI-GroupLoot-%s-%s]]
		local transmog_texture = [[Interface\MINIMAP\TRACKING\Transmogrifier]]
		function RollButtonPrototype:New(parent, roll, label, tex, anchor_to, x, y, label_colors)
			local b = self:_New(CreateFrame('Button', nil, parent))
			b:SetPoint('LEFT', anchor_to, 'RIGHT', x, y)
			if tex == 'Transmog' then
				b:SetNormalTexture(transmog_texture)
				b:SetHighlightTexture(transmog_texture)
				b:SetPushedTexture(transmog_texture)
				b:GetHighlightTexture():SetAlpha(0.5)
			else
				b:SetNormalTexture(path:format(tex, 'Up'))
				if tex ~= 'Pass' then
					b:SetHighlightTexture(path:format(tex, 'Highlight'))
					b:SetPushedTexture(path:format(tex, 'Down'))
				else
					b:SetHighlightTexture(path:format(tex, 'Up'))
					b:GetNormalTexture():SetVertexColor(0.8, 0.7, 0.7)
					b:GetHighlightTexture():SetAlpha(0.5)
				end
			end
			b.parent = parent

			local texture_special = b:CreateTexture(nil, 'OVERLAY')
			texture_special:SetAllPoints(b)
			texture_special:SetAlpha(0.5)
			b.texture_special = texture_special

			local text = b:CreateFontString(nil, 'OVERLAY')
			text:SetPoint("CENTER", -x + 1, tex == 'DE' and -y +2 or -y)
			b.text = text

			b:SetScript('OnEnter', self.OnEnter)
			b:SetScript('OnLeave', self.OnLeave)
			b:SetScript('OnClick', self.OnClick)
			b:SetMotionScriptsWhileDisabled(true)
			b:Enable()
			b.type = roll
			b.label = label
			b.label_colors = label_colors

			b:ApplyOptions()

			return b
		end

		function RollButtonPrototype:ApplyOptions()
			self.text:SetFont(opt.font, 12, opt.font_flag)
			self:SetWidth(opt.roll_button_size)
			self:SetHeight(opt.roll_button_size)
		end
	end

	---------------------------------------------------------------------------
	-- Roll frames
	---------------------------------------------------------------------------
	RollFramePrototype = XLoot.NewPrototype()
	-- Events
	function RollFramePrototype:OnEnter()
		mouse_focus = self
		GameTooltip:SetOwner(self.icon_frame, 'ANCHOR_TOPLEFT', 28, 0)
		GameTooltip:SetHyperlink(self.link)
		if opt.show_decided or opt.show_undecided then
			if not IS_RETAIL then
				AddTooltipLines(self, true)
			end
			if self.need.reason then
				AddIneligibleReason(self.need, 1, .2, 0)
			end
			if self.greed.reason and self.greed.reason ~= self.need.reason then
				AddIneligibleReason(self.greed, .8, .1, 0)
			end
			if self.disenchant and self.disenchant.reason then
				AddIneligibleReason(self.disenchant, .6, .05, 0)
			end
		end
		if IsShiftKeyDown() then
			GameTooltip_ShowCompareItem()
		end
		if IsModifiedClick('DRESSUP') then
			ShowInspectCursor()
		else
			ResetCursor()
		end
	end

	function RollFramePrototype:OnLeave()
		mouse_focus = nil
		GameTooltip:Hide()
	end

	function RollFramePrototype:OnClick(button)
		if IsControlKeyDown() then
			DressUpItemLink(self.link)
		elseif IsShiftKeyDown() then
			ChatEdit_InsertLink(self.link)
		end
	end

	-- Status bar update
	local max, min = math.max, math.min
	function RollFramePrototype:OnBarUpdate()
		local parent = self.parent
		if parent.over then
			self.spark:Hide()
			self:SetValue(0)
			parent.text_time:SetText()
			return
		end
		local time = GetTime()
		-- The timeout is the only way out of a held bar if a result never lands.
		if parent.awaiting then
			self.spark:Hide()
			self:SetValue(0)
			parent.text_time:SetText()
			if time > (parent.await_until or 0) then
				anchor:Pop(parent)
			end
			return
		end
		-- TODO: Remove?
		local status, result = pcall(GetLootRollTimeLeft, parent.rollid)
		if not status or result == 0 then
			-- Rolling closes the local roll, so a Need with no cancel event lands here.
			if opt.roll_status and parent.drop_key then
				HoldForResult(parent)
				return
			end
			local ended = parent.rollended
			if ended then
				if time - ended > 10 then
					anchor:Pop(parent)
				end
			else
				parent.rollended = time
			end
		end
		-- /TODO
		local remaining = self.expires - time
		if remaining < -4 then
			anchor:Pop(parent)
		else
			local now, length = max(remaining, -1), self.length
			local fraction = max(0, min(now / length, 1))
			if opt.roll_urgency and self.base_r then
				local ur, ug, ub = TimeFractionColor(fraction, self.base_r, self.base_g, self.base_b)
				self:SetStatusBarColor(ur, ug, ub, .7)
				-- The fill shrinks as time runs out, so redden the always-full row border too, ramping from the highlight color it started at.
				local pr, pg, pb = TimeFractionColor(fraction, self.base_br, self.base_bg, self.base_bb)
				self.parent.overlay:SetBorderColor(pr, pg, pb)
				self.parent.icon_frame:SetBorderColor(pr, pg, pb)
			end
			self.spark:SetPoint('CENTER', self, 'LEFT', fraction * self:GetWidth(), 0)
			self:SetValue(now)
			self.spark:Show()
			if opt.show_time_remaining then
				if remaining >= 0 then
					parent.text_time:SetText(sf('%.0f', max(0, remaining)))
					parent.text_time:Show()
				else
					parent.text_time:Hide()
				end
			end
		end
	end

	function RollFramePrototype:Popped()
		rolls[self.rollid] = nil
		if FakeHistory then
			FakeHistory.rolls[self.rollid] = nil
			FakeHistory.links[self.rollid] = nil
		end
		if self.drop_key then
			drop_to_roll[self.drop_key] = nil
			if FakeHistory then FakeHistory.drops[self.drop_key] = nil end
			self.drop_key = nil
		end
	end

	-- Create roll frame
	function RollFramePrototype:New()
		-- Base frame
		local frame = self:_New(CreateFrame('Button', nil, UIParent))
		frame:SetFrameLevel(anchor:GetFrameLevel())
		frame:SetHeight(24)
		frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		frame:SetScript('OnEnter', self.OnEnter)
		frame:SetScript('OnLeave', self.OnLeave)
		frame:SetScript('OnClick', self.OnClick)

		-- Overlay (For skin border)
		local overlay = CreateFrame('frame', nil, frame, BackdropTemplateMixin and "BackdropTemplate")
		overlay:SetFrameLevel(frame:GetFrameLevel())
		overlay:SetAllPoints()
		frame.overlay = overlay
		local skin = Skinner:Skin(overlay, 'row')

		-- Item icon (For skin border)
		local icon_frame = CreateFrame('Frame', nil, frame)
		icon_frame:SetPoint('LEFT', 0, 0)
		icon_frame:SetWidth(28)
		icon_frame:SetHeight(28)
		frame.icon_frame = icon_frame
		Skinner:Skin(icon_frame, 'item')

		-- Item texture
		local icon = icon_frame:CreateTexture(nil, 'BACKGROUND')
		icon:SetPoint('TOPLEFT', 3, -3)
		icon:SetPoint('BOTTOMRIGHT', -3, 3)
		icon:SetTexCoord(.07,.93,.07,.93)
		frame.icon = icon

		-- Timer bar
		local bar = CreateFrame('StatusBar', nil, frame)
		bar:SetFrameLevel(frame:GetFrameLevel())
		local pad = skin.padding or 2
		bar:SetPoint('TOPRIGHT', -pad - 3, -pad - 3)
		bar:SetPoint('BOTTOMRIGHT', -pad - 3, pad + 3)
		bar:SetPoint('LEFT', icon_frame, 'RIGHT', -pad, 0)
		bar:SetStatusBarTexture(skin.bar_texture)
		bar:SetScript('OnUpdate', self.OnBarUpdate)
		bar.parent = frame
		frame.bar = bar
		-- Reference bar for quick re-skinning when XLoot skin changes
		table.insert(addon.bars, bar)

		local spark = bar:CreateTexture(nil, 'OVERLAY')
		spark:SetWidth(14)
		spark:SetHeight(38)
		spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
		spark:SetBlendMode('ADD')
		bar.spark = spark

		-- Bind text
		local bind = icon_frame:CreateFontString(nil, 'OVERLAY')
		bind:SetPoint('BOTTOM', 0, 1)
		frame.text_bind = bind

		-- Time text
		local time = icon_frame:CreateFontString(nil, 'OVERLAY')
		time:SetPoint('CENTER', 0, 2)
		frame.text_time = time

		-- Item level
		local ilvl = icon_frame:CreateFontString(nil, 'OVERLAY')
		ilvl:SetPoint('TOPLEFT', 3, -3)
		frame.text_ilvl = ilvl

		local n = RollButtonPrototype:New(frame, 1, NEED, 'Dice', icon_frame, 3, -1, {.2, 1, .1})
		local g = RollButtonPrototype:New(frame, 2, GREED, 'Coin', n, 0, -2, {.1, .2, 1})
		local d, t, third
		if HAS_TRANSMOG then
			t = RollButtonPrototype:New(frame, 4, (TRANSMOGRIFY or 'Transmog'), 'Transmog', g, 0, -2, {.9, .5, .9})
			third = t
		elseif BUILD_HAS_DISENCHANT then
			d = RollButtonPrototype:New(frame, 3, ROLL_DISENCHANT, 'DE', g, 0, 2, {.1, .2, 1})
			third = d
		else
			third = g
		end
		local p = RollButtonPrototype:New(frame, 0, PASS, 'Pass', third, 0, 2, {.7, .7, .7})
		frame.need, frame.greed, frame.disenchant, frame.transmog, frame.pass = n, g, d, t, p

		-- Roll status text
		local status = frame:CreateFontString(nil, 'OVERLAY')
		status:SetHeight(16)
		status:SetJustifyH('LEFT')
		status:SetPoint('LEFT', icon_frame, 'RIGHT', 1, 0)
		status:SetPoint('RIGHT', p, 'RIGHT', 2, 0)
		frame.text_status = status

		-- Loot name/link
		local loot = frame:CreateFontString(nil, 'OVERLAY')
		loot:SetHeight(16)
		loot:SetJustifyH('LEFT')
		loot:SetPoint('LEFT', p, 'RIGHT', 3, -1)
		loot:SetPoint('RIGHT', frame, 'RIGHT', -5, 0)
		frame.text_loot = loot

		frame:ApplyOptions()

		return frame
	end

	function RollFramePrototype:ApplyOptions()
		self:SetWidth(opt.roll_width)

		-- Status bar is reskinned with SkinUpdate

		-- Drop any urgency tint so turning the option off mid-roll restores the quality fill and highlight border.
		if self.bar.base_r then
			self.bar:SetStatusBarColor(self.bar.base_r, self.bar.base_g, self.bar.base_b, .7)
			self.overlay:SetBorderColor(self.bar.base_br, self.bar.base_bg, self.bar.base_bb)
			self.icon_frame:SetBorderColor(self.bar.base_br, self.bar.base_bg, self.bar.base_bb)
		end

		self.need:ApplyOptions()
		self.greed:ApplyOptions()
		if self.disenchant then self.disenchant:ApplyOptions() end
		if self.transmog then self.transmog:ApplyOptions() end
		self.pass:ApplyOptions()

		self.text_ilvl:SetFont(opt.font, 8, 'OUTLINE')
		self.text_bind:SetFont(opt.font, 8, 'THICKOUTLINE')
		self.text_time:SetFont(opt.font, 12, 'OUTLINE')
		self.text_status:SetFont(opt.font, 12, opt.font_flag)
		self.text_loot:SetFont(opt.font, 12, opt.font_flag)

		self.text_time:SetShown(opt.show_time_remaining)
		self.text_ilvl:SetShown(opt.text_ilvl)
	end
end

---------------------------------------------------------------------------
-- AddOn setup and events
---------------------------------------------------------------------------

-- Update skins when XLoot skin changes
function addon:SkinUpdate()
	local skin = Skinner:Reskin()
	local padding = skin.padding or 2
	local p, n = padding + 3, -padding - 3
	for _,bar in pairs(addon.bars) do
		bar:ClearAllPoints()
		bar:SetPoint('TOPRIGHT', n, n)
		bar:SetPoint('BOTTOMRIGHT', n, p)
		bar:SetPoint('LEFT', bar.parent.icon_frame, 'RIGHT', -padding, 0)
		bar:SetStatusBarTexture(skin.bar_texture)
		local link = bar.parent.link
		if link and not (issecret and issecret(link)) then
			local r, g, b = C_Item.GetItemQualityColor(select(3, GetItemInfo(link)))
			local br, bg, bb = RollBorderColor(link, r, g, b)
			bar.parent.overlay:SetBorderColor(br, bg, bb)
			bar.parent.icon_frame:SetBorderColor(br, bg, bb)
		end
	end

end

-- Move anchors when scale changes
function addon:ApplyOptions()
	opt = self.opt

	if not anchor then return end

	self:UpdateRetailStatusEvents()

	anchor:UpdateSVData(opt.roll_anchor)
	alert_anchor:UpdateSVData(opt.alert_anchor)

	self:SkinUpdate()

	anchor:Restack()

	for _,frame in pairs(anchor.children) do
		if frame.ApplyOptions then
			frame:ApplyOptions()
		end
	end
end


---------------------------------------------------------------------------
-- Test rolls
---------------------------------------------------------------------------
local preview_loot = IS_RETAIL and {
	{ 249288, true, true, true, true },
	{ 258412, true, true, true, true },
	{ 193701, false, true, true, true },
	{ 249805, true, true, true, true },
	{ 249339, true, false, true, true },
	{ 260188, true, true, true, true },
	{ 249659, true, true, true, false },
	{ 249626, false, true, true, true }
} or {
	-- Low classic-safe IDs with a spread of quality and item types
	{ 17204, true, true, true, true },
	{ 2244, false, true, true, true },
	{ 69818, false, false, true, false },
	{ 18332, false, true, false, true },
	{ 14256, false, false, true, true }
}
-- Activate items
for i, t in ipairs(preview_loot) do
	GetItemInfo(t[1])
end

local init, tests, links, StartFakeRoll = false, {}, {}, nil

local deframe = CreateFrame('Frame')

-- Currently only debugs one roll at a time.
function XLootGroup.TestSettings()
	local schedule = {}
	local type_index = { 'need', 'greed', 'disenchant', [0] = 'pass' }
	if not init then
		init = true
		local tick = 0
		deframe:SetScript('OnUpdate', function(self, elapsed)
			tick = tick + elapsed
			if tick > 1 then
				tick = 0
				local time = GetTime()
				for k,v in pairs(schedule) do
					if v[1] < time then
						local e = v
						schedule[k] = nil
						e[2]()
						e[3](unpack(e[4]))
					end
				end
			end
		end)

		FakeHistory = {
			rolls = {},
			links = {},
			items = {},
			drops = {}
		}

		local function after(seconds, func, target, ...)
			table.insert(schedule, { GetTime() + seconds, func, target, {...} } )
		end

		local function changed(...)
			addon:LOOT_HISTORY_ROLL_CHANGED(...)
		end

		-- An orphaned fake drop must never join a real roll of the same item and fake a winner onto it.
		local function updated(enc, list)
			local frame = drop_to_roll[DropKey(enc, list)]
			if frame and rolls[frame.rollid] == frame then
				ProcessRetailDrop(enc, list)
			end
		end

		-- Test overrides fall through to the real API for non-fake IDs, so /xlgd can't break live rolls
		local _GetLootRollItemInfo, _GetLootRollItemLink, _GetLootRollTimeLeft, _RollOnLoot,
			_UnitGroupRolesAssigned, _HistoryGetItem, _HistoryGetPlayerInfo, _HistoryGetSortedInfoForDrop
			= GetLootRollItemInfo, GetLootRollItemLink, GetLootRollTimeLeft, RollOnLoot,
			UnitGroupRolesAssigned, HistoryGetItem, HistoryGetPlayerInfo, HistoryGetSortedInfoForDrop

		function GetLootRollItemInfo(id)
			if FakeHistory.rolls[id] then return unpack(FakeHistory.rolls[id]) end
			return _GetLootRollItemInfo(id)
		end

		function GetLootRollItemLink(id)
			if FakeHistory.links[id] then return FakeHistory.links[id] end
			return _GetLootRollItemLink(id)
		end

		function GetLootRollTimeLeft(id)
			if FakeHistory.rolls[id] then return 1 end
			return _GetLootRollTimeLeft(id)
		end

		function RollOnLoot(rollid, rtypeid)
			if not FakeHistory.rolls[rollid] then
				return _RollOnLoot(rollid, rtypeid)
			end
			if IS_RETAIL then
				local frame = rolls[rollid]
				if frame then anchor:Pop(frame) end
				return
			end
			FakeHistory.items[1].players[1][3] = rtypeid
			changed(1, 1)
		end

		function UnitGroupRolesAssigned(player)
			local real = _UnitGroupRolesAssigned(player)
			if real and real ~= 'NONE' then return real end
			local s = math.random(1, 3)
			return s == 1 and "HEALER" or s == 2 and "DAMAGER" or "TANK"
		end

		function HistoryGetItem(hid)
			if FakeHistory.items[hid] then return unpack(FakeHistory.items[hid].item) end
			return _HistoryGetItem and _HistoryGetItem(hid)
		end

		function HistoryGetPlayerInfo(hid, pid)
			if FakeHistory.items[hid] then return unpack(FakeHistory.items[hid].players[pid]) end
			return _HistoryGetPlayerInfo and _HistoryGetPlayerInfo(hid, pid)
		end

		function HistoryGetSortedInfoForDrop(encounterID, lootListID)
			local drop = FakeHistory.drops[DropKey(encounterID, lootListID)]
			if drop then return drop end
			return _HistoryGetSortedInfoForDrop and _HistoryGetSortedInfoForDrop(encounterID, lootListID)
		end

		function StartFakeRoll(index)
			local fake = {}

			local item = preview_loot[index or random(1, #preview_loot)]
			local iname, ilink, iquality, _, _, _, _, _, _, itex = GetItemInfo(item[1])

			-- count up from a high base so fake ids never collide with real loot-roll ids
			fake_seq = fake_seq + 1
			local rollid = 1000000 + fake_seq

			fake.item = { rollid, ilink, 5, false, nil, false }
			fake.players = {
				{ UnitName("player"), select(2, UnitClass('player')), nil, nil, false, true },
				{ 'Player1', 'MAGE', nil, nil, false, false },
				{ 'Player2', 'PRIEST', nil, nil, false, false },
				{ 'Player3', 'WARRIOR', nil, nil, false, false },
				{ 'Player4', 'SHAMAN', nil, nil, false, false }
			}
			FakeHistory.rolls[rollid] = { itex, iname, 1, iquality, item[2], item[3], item[4], item[5], 0, 0, 0, 0, IS_RETAIL and random(1, 2) == 2 or nil }
			FakeHistory.links[rollid] = ilink

			table.insert(FakeHistory.items, 1, fake)

			local fake_frame = addon:START_LOOT_ROLL(rollid, random(20000, 40000), true)
			if not IS_RETAIL then
				after(5, function() fake.players[2][3] = 0 end, changed, 1, 2)
				after(7, function() fake.players[3][3] = 2 end, changed, 1, 3)
				after(9, function() fake.players[4][3] = 3 end, changed, 1, 4)
				after(11, function() fake.players[5][3] = 1 end, changed, 1, 5)
			else
				local S = Enum and Enum.EncounterLootDropRollState
				if S and fake_frame then
					local enc, list = 88888, rollid
					local key = DropKey(enc, list)
					local drop = { lootListID = list, itemHyperlink = ilink, rollInfos = {}, allPassed = false }
					FakeHistory.drops[key] = drop
					-- Bind up front so the fake drop resolves by cache and never scans real bars.
					fake_frame.drop_key = key
					drop_to_roll[key] = fake_frame
					local infos = drop.rollInfos
					local variant = index or 1
					if variant % 3 == 0 then
						after(3, function() infos[#infos+1] = { playerName = 'Player1', playerClass = 'MAGE', state = S.Pass } end, updated, enc, list)
						after(5, function() infos[#infos+1] = { playerName = 'Player2', playerClass = 'PRIEST', state = S.Pass } end, updated, enc, list)
						after(7, function() drop.allPassed = true end, updated, enc, list)
					else
						local me = { playerName = UnitName("player"), playerClass = select(2, UnitClass('player')), state = S.NeedMainSpec, roll = 71, isSelf = true }
						local rival = { playerName = 'Player2', playerClass = 'PRIEST', state = S.NeedMainSpec, roll = 88, isSelf = false }
						local winner = variant % 2 == 0 and me or rival
						winner.isWinner = true
						after(3, function() infos[#infos+1] = { playerName = 'Player1', playerClass = 'MAGE', state = S.Greed, roll = 42 } end, updated, enc, list)
						after(5, function() infos[#infos+1] = rival end, updated, enc, list)
						after(7, function() infos[#infos+1] = me end, updated, enc, list)
						after(9, function() drop.winner = winner end, updated, enc, list)
					end
				end
			end
		end

	end
	for i = 1, #preview_loot do
		StartFakeRoll(i)
	end
end

XLoot:SetSlashCommand('xlgd', XLootGroup.TestSettings)


--@do-not-package@
-- The pre-Legion *_ShowAlert globals are gone, so drive the modern alert-system objects directly.
local function alert()
	local _, link = GetItemInfo(preview_loot[random(1, #preview_loot)][1])
	local function try(name, ...)
		local sys = _G[name]
		if sys and sys.AddAlert then
			local ok, err = pcall(sys.AddAlert, sys, ...)
			if not ok then print('XLoot /xlga', name, err) end
		else
			print('XLoot /xlga: missing', name)
		end
	end
	try('LootAlertSystem', link, 1)
	try('LootUpgradeAlertSystem', link, 1, nil, 3, false, true)
	try('MoneyWonAlertSystem', random(1, 100000))
end

XLoot:SetSlashCommand('xlga', alert)

local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
