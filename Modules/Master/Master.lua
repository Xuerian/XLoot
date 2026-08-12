-- Master loot returned to retail in 12.0.5 (CN-realm-only) on a new ScrollBox/MenuUtil flow this module doesn't handle. It targets the pre-8.0 flow, so keep it Classic-only.
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

local addon, L = XLoot:NewModule("Master")
XLootMaster = addon
local print, wipe, match = print, table.wipe, string.match
local SendChatMessage = XLoot.SendChatMessage
local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
local hexColors = {}
local classesInRaid, class_players, classes_english = {}, {}, {}
local player_indices, index_name = {}, {}
local randoms = {}
local me = UnitName('player')
local my_index, banker_index, disenchanter_index
local candidate, color, lclass, className, slot, info, opt
local roll_pending
local LD

local defaults = {
	profile = {
		menu_roll = true,
		menu_disenchant = true,
		menu_disenchanters = "",
		menu_bank = true,
		menu_bankers = "",
		menu_self = true,
		confirm_qualitythreshold = MASTER_LOOT_THREHOLD,
		award_qualitythreshold = 2,
		award_channel = 'AUTO',
		award_channel_secondary = 'NONE',
		award_guildannounce = false,
		award_special = true,
	}
}

local eframe = CreateFrame("Frame")
function addon:OnInitialize()
	self:InitializeModule(defaults, eframe)
	opt = self.db.profile
	XLootMaster.opt = opt
	XLoot:SetSlashCommand("xlml", self.SlashHandler)
end

-- AceDB strips defaults out of the old profile table on a switch, so re-read it or opt goes nil-valued
function addon:ApplyOptions()
	opt = self.opt
end

function addon:OnEnable()
	for i,class in ipairs(CLASS_SORT_ORDER) do
		classes_english[class] = true
	end
	
	for k, v in pairs(RAID_CLASS_COLORS) do
		hexColors[k] = "|c" .. v.colorStr
	end
	hexColors["UNKNOWN"] = string.format("|cff%02x%02x%02x", 0.6*255, 0.6*255, 0.6*255)
	
	if CUSTOM_CLASS_COLORS then
		local function update()
			for k, v in pairs(CUSTOM_CLASS_COLORS) do
				hexColors[k] = "|c" .. v.colorStr
			end
		end
		CUSTOM_CLASS_COLORS:RegisterCallback(update)
		update()
	end
end

local function printall(...)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(string.join(", ",tostringall(...)))
	end
end
addon.printall = printall

local function dump(val)
	UIParentLoadAddOn("Blizzard_DebugTools")
	_G['xlminfostruct'] = val
	DevTools_DumpCommand('xlminfostruct')
	_G['xlminfostruct'] = nil
end
addon.dump = dump

local function OutChannel(channel)
	if channel == "NONE" then return end
	local out = channel
	if channel == "AUTO" then
		if IsInRaid() then
		  if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant() then
		    out = "RAID_WARNING"
		  elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		    out = "INSTANCE_CHAT"
		  else
		    out = "RAID"
		  end
		elseif IsInGroup() then
		  if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		    out = "INSTANCE_CHAT"
		  else
		    out = "PARTY"
		  end
		else
			out = "SAY"
		end
	end
	return out
end

function addon.AnnounceAward(data)
	if data.quality >= opt.award_qualitythreshold then
		if data.special and not opt.award_special then return end
		local out = OutChannel(opt.award_channel)
		local text = (L.ITEM_AWARDED):format(data.pname,data.link)
		if data.special then
			text = text .. " ("..data.special..")"
		end
		if out then
			pcall(SendChatMessage, text, out)
		end
		local secondary = OutChannel(opt.award_channel_secondary)
		if secondary then
			pcall(SendChatMessage, text, secondary)
		end
		if opt.award_guildannounce and IsInGuild() then
			pcall(SendChatMessage, text, "GUILD")
		end
	end
end

local function xprint(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99XLootMaster|r: "..msg)
	end
end

local function CandidateValid(slot, id, pname)
	return slot and id and GetMasterLootCandidate(slot, id) == pname
end

local function Award(data)
	if data.quality >= opt.confirm_qualitythreshold then
		local qcolor = ITEM_QUALITY_COLORS[data.quality]
		local dialog = StaticPopup_Show("CONFIRM_XLOOT_DISTRIBUTION",
			(qcolor and qcolor.hex or "")..(data.itemname or "")..FONT_COLOR_CODE_CLOSE, data.pname)
		if dialog then
			dialog.data = data
		end
	elseif CandidateValid(data.slot, data.id, data.pname) then
		addon.AnnounceAward(data)
		GiveMasterLoot(data.slot, data.id)
	else
		xprint(L.CANDIDATE_UNAVAILABLE)
	end
end

function addon.GiveLoot(frame, special)
	local slot = LootFrame.selectedSlot
	local id = frame.value
	Award({
		slot = slot,
		id = id,
		link = GetLootSlotLink(slot),
		itemname = LootFrame.selectedItemName,
		quality = LootFrame.selectedQuality or 0,
		pname = index_name[id],
		special = special,
	})
	CloseDropDownMenus()
end

-- DoMasterLootRoll was removed from every client flavor in 12.x with no replacement, so guard the call.
function addon.SpawnRoll(frame)
	if DoMasterLootRoll then DoMasterLootRoll(frame.value) end
end

local roll_serial = 0
local ROLL_TIMEOUT = 15

-- A pending roll left registered lets a later unrelated /roll 1-N award a slot from a closed loot window. The id keeps a stale timeout from clearing a newer roll.
local function ClearPendingRoll(id, discarded)
	if not roll_pending then return end
	if id and roll_pending.id ~= id then return end
	roll_pending = nil
	eframe:UnregisterEvent("CHAT_MSG_SYSTEM")
	eframe:UnregisterEvent("LOOT_CLOSED")
	-- The raid has already seen the candidate list and the roll, so dying quietly reads as a bug.
	if discarded then xprint(L.ROLL_DISCARDED) end
end

function addon.RaidRoll(frame, source)
	local slot = LootFrame.selectedSlot
	local link = slot and GetLootSlotLink(slot)
	if not link then return end

	-- `source` is the shared `randoms` table, which the next menu build wipes, so snapshot it.
	local players, count = {}, 0
	for i = 1, #source do
		local index = source[i]
		local name = index_name[index]
		if name then
			count = count + 1
			players[count] = { index = index, name = name }
		end
	end
	if count < 1 then return end

	local out = OutChannel("AUTO")
	if out then
		pcall(SendChatMessage, L.ML_RANDOM..": "..link, out)
		local line = ""
		for k = 1, count do
			line = (line == "") and (k..": "..players[k].name) or (line..", "..k..": "..players[k].name)
			if k == count or k % 3 == 0 then
				pcall(SendChatMessage, line, out)
				line = ""
			end
		end
	end

	roll_serial = roll_serial + 1
	roll_pending = {
		id = roll_serial,
		slot = slot,
		players = players,
		count = count,
		link = link,
		itemname = LootFrame.selectedItemName,
		quality = LootFrame.selectedQuality or 0,
	}
	eframe:RegisterEvent("CHAT_MSG_SYSTEM")
	eframe:RegisterEvent("LOOT_CLOSED")
	if C_Timer and C_Timer.After then
		local id = roll_serial
		C_Timer.After(ROLL_TIMEOUT, function() ClearPendingRoll(id, true) end)
	end
	RandomRoll(1, count)
	CloseDropDownMenus()
end

-- RandomRoll(1, count) returns a position into `players`, not a loot-slot candidate index.
function addon:CHAT_MSG_SYSTEM(...)
	if not roll_pending then return end
	local who, roll, low, high = XLoot.Deformat(..., RANDOM_ROLL_RESULT)
	roll = tonumber(roll)
	if who ~= me or not roll or tonumber(low) ~= 1 or tonumber(high) ~= roll_pending.count then return end

	local pending = roll_pending
	ClearPendingRoll()

	local winner = pending.players[roll]
	if not winner then return end
	Award({
		slot = pending.slot,
		id = winner.index,
		link = pending.link,
		itemname = pending.itemname,
		quality = pending.quality,
		pname = winner.name,
	})
end

-- Slot indices are meaningless once the window closes, so a pending roll must not outlive it.
function addon.LOOT_CLOSED()
	ClearPendingRoll(nil, true)
end

function addon.AddMenuTitle(title)
	info.isTitle = nil
	info.text = title
	info.textHeight = 12
	info.notCheckable = 1
	info.disabled = 1
	info.disablecolor = YELLOW_FONT_COLOR_CODE
	info.notClickable = 1
	UIDropDownMenu_AddButton(info)
	info.notClickable = nil
	info.disablecolor = nil
end

function addon.AddMenuSeparator()
	info.disabled = 1
  info.text = ""
  info.hasArrow = nil
  UIDropDownMenu_AddButton(info, level)
end

function addon.BuildPartyMenu(level)
	if level == 1 then
		for i=1, MAX_PARTY_MEMBERS+1, 1 do
			candidate,lclass,className = GetMasterLootCandidate(slot,i)
			index_name[i] = candidate
			if candidate then
				info.text = candidate
				info.colorCode = hexColors[className] or hexColors["UNKNOWN"]
				info.textHeight = 12
				info.value = i
				info.notCheckable = 1
				info.hasArrow = nil
				info.isTitle = nil
				info.disabled = nil
				info.func = addon.GiveLoot
				UIDropDownMenu_AddButton(info)
			end
		end
	end
end

function addon.BuildRaidMenuRecipients(level)
	if level == 1 then
		if (my_index and opt.menu_self) or (banker_index and opt.menu_bank) or (disenchanter_index and opt.menu_disenchant) then
			-- XLootMaster.AddMenuSeparator()
	    info.disabled = nil
			info.isTitle = nil
			info.text = L.RECIPIENTS
			info.colorCode = YELLOW_FONT_COLOR_CODE
			info.textHeight = 12
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = "RECIPIENTS"
			info.func = nil
			info.disabled = nil
			UIDropDownMenu_AddButton(info)
		end
	elseif level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == "RECIPIENTS" then
			if my_index then
				candidate,lclass,className = GetMasterLootCandidate(slot,my_index)
				if candidate and candidate == me then
					info.colorCode = hexColors[className] or hexColors["UNKNOWN"]
					info.isTitle = nil
					info.textHeight = 12
					info.value = my_index
					info.notCheckable = 1
					info.text = L.ML_SELF
					info.func = addon.GiveLoot
					info.arg1 = L.ML_SELF
					info.icon = "Interface\\GossipFrame\\VendorGossipIcon"
					UIDropDownMenu_AddButton(info,level)
				end
			end
			if banker_index and opt.menu_bank then
				candidate,lclass,className = GetMasterLootCandidate(slot,banker_index)
				if candidate and addon.listPriority(candidate, opt.menu_bankers) then
					info.colorCode = "|cffffffff"
					info.isTitle = nil
					info.textHeight = 12
					info.value = banker_index
					info.notCheckable = 1
					info.text = L.ML_BANKER.." ("..candidate..")"
					info.func = addon.GiveLoot
					info.arg1 = L.ML_BANKER
					info.icon = "Interface\\Minimap\\Tracking\\Banker"
					UIDropDownMenu_AddButton(info,level)
				end
			end
			if disenchanter_index and opt.menu_disenchant then
				candidate,lclass,className = GetMasterLootCandidate(slot,disenchanter_index)
				if candidate and addon.listPriority(candidate, opt.menu_disenchanters) then
					info.colorCode = "|cffffffff"
					info.isTitle = nil
					info.textHeight = 12
					info.value = disenchanter_index
					info.notCheckable = 1
					info.text = L.ML_DISENCHANTER.." ("..candidate..")"
					info.func = addon.GiveLoot
					info.arg1 = L.ML_DISENCHANTER
					info.icon = "Interface\\Buttons\\UI-GroupLoot-DE-Up"
					UIDropDownMenu_AddButton(info,level)
				end
			end
		end
	end
end

function addon.BuildMenuSpecialRolls(level)
	if level == 1 then
		info.isTitle = nil
		info.text = L.SPECIALROLLS
		info.colorCode = YELLOW_FONT_COLOR_CODE
		info.textHeight = 12
		info.hasArrow = 1
		info.notCheckable = 1
		info.value = "SPECIALROLLS"
		info.func = nil
		info.disabled = nil
		UIDropDownMenu_AddButton(info)		
	elseif level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == "SPECIALROLLS" then
			info.colorCode = "|cffffffff"
			info.isTitle = nil
			info.textHeight = 12
			info.value = slot
			info.notCheckable = 1
			info.hasArrow = nil
			if DoMasterLootRoll then
				info.text = REQUEST_ROLL
				info.func = addon.SpawnRoll
				info.icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
				UIDropDownMenu_AddButton(info,level)
			end
			
			if IsInRaid() and next(randoms) and opt.menu_roll then
				info.colorCode = "|cffffffff"
				info.isTitle = nil
				info.textHeight = 12
				info.value = randoms[math.random(1, #randoms)]
				info.notCheckable = 1
				info.text = L.ML_RANDOM
				info.func = addon.RaidRoll
 				info.arg1 = randoms
				info.icon = "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
				UIDropDownMenu_AddButton(info,level)
			end
		end		
	end
end

function addon.normalize_toon_list(str)
	str = str:gsub("%s+",",")
	str = str:gsub("%p+",",")
	str = str:lower()
	return ","..str..","
end

function addon.listPriority(name, list)
	list = addon.normalize_toon_list(list)
	return select(1,list:find(addon.normalize_toon_list(name)))
end

function addon.BuildRaidMenu(level)
	if level == 1 then
		wipe(player_indices)
		wipe(index_name)
		wipe(classesInRaid)
		wipe(class_players)
		wipe(randoms)
		local disenchant_rank, bank_rank = 10000, 10000
		my_index, banker_index, disenchanter_index = nil,nil,nil
		for i = 1, MAX_RAID_MEMBERS do
			candidate,lclass,className = GetMasterLootCandidate(slot,i)
			if candidate then
				classesInRaid[className] = lclass
				table.insert(randoms, i)
				if candidate == me then
					my_index = i
				end
				local br = addon.listPriority(candidate, opt.menu_bankers)
				if br and br < bank_rank then
					banker_index = i
					bank_rank = br
				end
				local dr = addon.listPriority(candidate, opt.menu_disenchanters)
				if dr and dr < disenchant_rank then
					disenchanter_index = i
					disenchant_rank = dr
				end
				player_indices[candidate] = i
				index_name[i] = candidate
				if not class_players[className] then class_players[className] = {} end
				table.insert(class_players[className],candidate)
			end
		end
		for i, class in ipairs(CLASS_SORT_ORDER) do
			local cname = classesInRaid[class]
			if cname then
				info.isTitle = nil
				info.text = cname
				info.colorCode = hexColors[class] or hexColors["UNKNOWN"]
				info.textHeight = 12
				info.hasArrow = 1
				info.notCheckable = 1
				info.value = class
				info.func = nil
				info.disabled = nil
				UIDropDownMenu_AddButton(info)
			end
		end
		
		addon.BuildRaidMenuRecipients(level)
	
	elseif level == 2 then
		if classes_english[UIDROPDOWNMENU_MENU_VALUE] then
			if next(class_players[UIDROPDOWNMENU_MENU_VALUE]) then
				table.sort(class_players[UIDROPDOWNMENU_MENU_VALUE])
				for _,cand in ipairs(class_players[UIDROPDOWNMENU_MENU_VALUE]) do
					info.text = cand
					info.colorCode = hexColors[UIDROPDOWNMENU_MENU_VALUE] or hexColors["UNKNOWN"]
					info.textHeight = 12
					info.value = player_indices[cand]
					info.notCheckable = 1
					info.disabled = nil
					info.func = addon.GiveLoot
					UIDropDownMenu_AddButton(info,level)
				end
			end
		end
		
		addon.BuildRaidMenuRecipients(level)
		addon.BuildMenuSpecialRolls(level)
		
	end
end

function addon.DropdownInit()
	slot = LootFrame.selectedSlot or 0
	info = UIDropDownMenu_CreateInfo()
	
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		
		addon.AddMenuTitle(GIVE_LOOT)
		if ( IsInRaid() ) then
			addon.BuildRaidMenu(UIDROPDOWNMENU_MENU_LEVEL)
		else
			addon.BuildPartyMenu(UIDROPDOWNMENU_MENU_LEVEL)
		end
		-- XLootMaster.AddMenuSeparator()
		addon.BuildMenuSpecialRolls(UIDROPDOWNMENU_MENU_LEVEL)
		
 	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then

		addon.BuildRaidMenu(UIDROPDOWNMENU_MENU_LEVEL)

 	end	
end

local GroupLootDropDown = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_Initialize(GroupLootDropDown, addon.DropdownInit, "MENU")
hooksecurefunc("MasterLooterFrame_Show", function(frame)
	if frame == LootFrame.selectedLootButton then
		ToggleDropDownMenu(1, nil, GroupLootDropDown, LootFrame.selectedLootButton, 0, 0);
		MasterLooterFrame:Hide()
	end
end)

BINDING_HEADER_XLOOTMASTER = "XLootMaster"

StaticPopupDialogs["CONFIRM_XLOOT_DISTRIBUTION"] = {
	text = CONFIRM_LOOT_DISTRIBUTION,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self,data)
		if not (data and CandidateValid(data.slot, data.id, data.pname)) then
			return xprint(L.CANDIDATE_UNAVAILABLE)
		end
		addon.AnnounceAward(data)
		GiveMasterLoot(data.slot, data.id)
	end,
	timeout = 0,
	hideOnEscape = 1,
	preferredIndex = 3,
}

function addon.SlashHandler(msg)
	addon.ShowOptions()
end



