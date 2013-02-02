-- Create module
local addon, L = XLoot:NewModule("Monitor")
local XLootMonitor = CreateFrame("Frame", "XLootMonitor", UIParent)
XLootMonitor.addon = addon
-- Grab locals
local print, opt, eframe, anchor = print
local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
local CopperToString = XLoot.CopperToString
local table_insert, table_remove = table.insert, table.remove
local me = UnitName("player")

-------------------------------------------------------------------------------
-- Settings

local defaults = {
	profile = {
		anchor = {
			direction = "up",
			visible = true,
			scale = 1.0,
			x = UIParent:GetWidth() * .85,
			y = UIParent:GetHeight() * .2
		},
		name_width = 50,

		threshold_own = 1,
		threshold_other = 2,
		show_coin = true,

		show_totals = false,

		fade_own = 10,
		fade_other = 5,
	}
}

-------------------------------------------------------------------------------
-- Helpers
local white = { r = 1, g = 1, b = 1 }
local dimensions = {
	HEALER = '48:64',
	DAMAGER = '16:32',
	TANK = '32:48'
}
local function FancyPlayerName(name, class)
	local c = RAID_CLASS_COLORS[class] or white
	local role = UnitGroupRolesAssigned(name)
	if role ~= 'NONE' and opt.role_icon then
		name = string_format('\124TInterface\\LFGFRAME\\LFGROLE:12:12:-1:0:64:16:%s:0:16\124t%s', dimensions[role], name)
	end
	return name, c.r, c.g, c.b
end

-------------------------------------------------------------------------------
-- Module init

function addon:OnInitialize()
	eframe = CreateFrame("Frame")
	self:InitializeModule(defaults, eframe)
	XLoot:SetSlashCommand("xlm", self.SlashHandler)
	opt = self.db.profile
end

function addon:OnEnable()
	-- Register for loot events
	LibStub("LootEvents"):RegisterLootCallback(self.LOOT_EVENT)
	eframe:RegisterEvent("MODIFIER_STATE_CHANGED")
	-- Set up skins
	XLoot:MakeSkinner(self, {
		anchor = { r = .4, g = .4, b = .4, a = .6, gradient = false },
		anchor_pretty = { r = .6, g = .6, b = .6, a = .8 },
		item = { backdrop = false },
		item_highlight = { type = "highlight", layer = "overlay" },
		row_highlight = { type = "highlight" }
	})
	-- Set up anchor
	anchor = XLoot.Stack:CreateStaticStack(self.CreateRow, L.anchor, opt.anchor)
	self:Skin(anchor, XLoot.opt.skin_anchors and 'anchor_pretty' or 'anchor')
end

function addon:ApplyOptions()
	opt = self.opt
	anchor:UpdateSVData(opt.anchor)
	-- Apply all options
end

function addon.LOOT_EVENT(event, pattern, player, arg1, arg2)
	if event == 'item' then
		local link, num = arg1, arg2
		local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(link)
		if (player == me and opt.threshold_own or opt.threshold_other) > quality then
			return -- Doesn't meet threshold requirements
		end
		--print(event, pattern, player, name, num)
		local r, g, b = GetItemQualityColor(quality)
		local nr, ng, nb
		if player ~= me then
			player, nr, ng, nb = FancyPlayerName(player, select(2, UnitClass(player)))
		else
			player = nil
		end
		local row = addon:AddRow(icon, (player and opt.fade_other or opt.fade_own), r, g, b)
		local total = GetItemCount(link) + (tonumber(num) or 1)
		row:SetTexts(player, link, opt.show_totals and (total and total > 1) and total or '', nr, ng, nb)
		row.item = link
	elseif event == 'coin' and opt.show_coin then
		local copper, coin_string = arg1, arg2
		addon:AddRow(GetCoinIcon(copper), opt.fade_own, .5, .5, .5, .5, .5, .5):SetTexts(nil, CopperToString(copper))
	end
end

function addon:MODIFIER_STATE_CHANGED(self, modifier, state)
	if mouse_focus and MouseIsOver(mouse_focus) then
		mouse_focus:ShowTooltip()
	end
end

local pool, stack, active = {}, {}, false
stack[0] = anchor

local timer = 0
function addon.EframeUpdate(self, elapsed)
	timer = timer + elapsed
	for i,row in ipairs(stack) do
		local remaining = row.expires - timer
		if remaining < 0 then
			row:SetAlpha(0)
			addon:RemoveRow(row)
		elseif remaining <= .5 then
			row:SetAlpha(remaining * 2)
		else
			local since = timer - row.started
			if since <= .5 then
				row:SetAlpha(since * 2)
			end
		end
	end
end

function addon:RemoveRow(row)
	row:Hide()
	for i,v in ipairs(stack) do
		if v == row then
			table_remove(stack, i)
			table_insert(pool, row)
			if stack[i] then
				anchor:AnchorChild(stack[i], stack[i-1])
			end
			break
		end
	end

	-- Disable OnUpdate
	if #stack == 0 then
		active, timer = false, 0
		eframe:SetScript("OnUpdate", nil)
	end
end

function addon:AddRow(icon, fade_time, ir, ig, ib, rr, rg, rb)
	-- Acquire
	local row = table_remove(pool)
	if not row then
		row = self.CreateRow()
	end

	-- Set up row
	row.icon:SetTexture(icon)
	row.icon_frame:SetBorderColor(ir, ig, ib)
	row:SetBorderColor(rr or ir, rg or ig, rb or ib)
	row.expires = timer + fade_time
	row.started = timer
	row.item = nil

	-- Anchor
	anchor:AnchorChild(row)
	table_insert(stack, 1, row)
	if stack[2] then
		anchor:AnchorChild(stack[2], row)
	end
	row:Show()

	-- Enable OnUpdate
	if not active then
		active = true
		eframe:SetScript("OnUpdate", self.EframeUpdate)
	end
	return row
end

function addon:Restack()
	for i,v in ipairs(stack) do
		v:ClearAllPoints()
		anchor:AnchorChild(v, i == 1 and nil or stack[i-1])
	end
end
-------------------------------------------------------------------------------
-- Frame methods
do
	local function ShowTooltip(self)
		if self.item then
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT', 28, 0)
			GameTooltip:SetHyperlink(self.item)
			CursorUpdate(self)
		end
	end

	local function OnEnter(self)
		mouse_focus = self
		if self._highlights then
			self.icon_frame:ShowHighlight()
		end
		self:ShowTooltip()
	end

	local function OnLeave(self)
		mouse_focus = nil
		if self._highlights then
			self.icon_frame:HideHighlight()
		end
		GameTooltip:Hide()
		ResetCursor()
	end

	local function OnClick(self, button)
		if IsModifiedClick() and self.item then
			HandleModifiedItemClick(self.item)
		end
	end

	local function FitToText(self)
		self:SetWidth(self.name:GetWidth() + self.text:GetWidth() + 8 + self.icon_frame:GetWidth())
	end

	local function SetTexts(self, name, text, total, nr, ng, nb, tr, tg, tb)
		self.name:SetText(name and name.." " or nil)
		self.text:SetText(text)
		self.total:SetText(total)
		self.name:SetVertexColor(nr or 1, ng or 1, nb or 1)
		self.text:SetVertexColor(nr or 1, ng or 1, nb or 1)
		if name then
			self.name:SetWidth(opt.name_width)
		else
			self.name:SetWidth(0)
		end
		self:FitToText()
	end

	function addon.CreateRow()
		local frame = CreateFrame("Button", nil, UIParent)
		frame:SetFrameLevel(anchor:GetFrameLevel())
		frame:SetHeight(24)
		frame:SetWidth(250)

		addon:Skin(frame)
		addon:Highlight(frame, "row_highlight")
		frame:SetHighlightColor(.8, .8, .8)

		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		frame:SetScript("OnClick", OnClick)
		frame:SetScript("OnEnter", OnEnter)
		frame:SetScript("OnLeave", OnLeave)

		-- Item icon (For skin border)
		local icon_frame = CreateFrame("Frame", nil, frame)
		icon_frame:SetPoint("LEFT", 0, 0)
		icon_frame:SetWidth(28)
		icon_frame:SetHeight(28)
		addon:Skin(icon_frame, "item")
		addon:Highlight(icon_frame, "item_highlight")

		-- Item texture
		local icon = icon_frame:CreateTexture(nil, "BACKGROUND")
		icon:SetPoint("TOPLEFT", 3, -3)
		icon:SetPoint("BOTTOMRIGHT", -3, 3)
		icon:SetTexCoord(.07,.93,.07,.93)

		local name = frame:CreateFontString(nil, "OVERLAY")
		name:SetPoint("LEFT", icon_frame, "RIGHT", 2, 0)
		name:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		name:SetJustifyH("LEFT")

		local text = frame:CreateFontString(nil, "OVERLAY")
		text:SetPoint("LEFT", name, "RIGHT", 0, 0)
		text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		text:SetJustifyH("LEFT")

		local total = icon_frame:CreateFontString(nil, "OVERLAY")
		total:SetPoint("CENTER", icon_frame, "CENTER", 0, 0)
		total:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
		total:SetJustifyH("CENTER")

		frame.icon = icon
		frame.icon_frame = icon_frame
		frame.name = name
		frame.text = text
		frame.total = total
		frame.FitToText = FitToText
		frame.SetTexts = SetTexts
		frame.ShowTooltip = ShowTooltip

		return frame
	end
end

function addon:UpdateAnchors(...)
	if opt.anchor.visible then
		anchor:Show()
	else
		anchor:Hide()
	end
end

function addon.SlashHandler(msg)
	if anchor:IsShown() then
		anchor:Hide()
	else
		anchor:Show()
	end
end

--@do-not-package@
local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end

local items = {
	{ 52722 },
	{ 31304 },
	{ 37254 },
	{ 13262 },
	{ 15487 },
	{ 2589 }
}
for i,v in ipairs(items) do
	GetItemInfo(v[1])
end

local players = {
	{ UnitName("player"), select(2, UnitClass('player')) },
	{ 'Player1', 'MAGE' },
	{ 'Player2', 'PRIEST' },
	{ 'Player3', 'WARRIOR' },
	{ 'Player4', 'SHAMAN' }
}

local random = math.random
local function random_player(is_me)
	return is_me and players[1][1] or players[random(2, 5)][1]
end

local function test_item(event, is_me)
	addon.LOOT_EVENT('item', event, random_player(is_me), select(2, GetItemInfo(items[random(1, #items)][1])), random(1, 2) == 2 and random(1, 20) or 1)
end

local function test_coin(event, is_me)
	addon.LOOT_EVENT('coin', event, random_player(is_me), random(1, 500000), "TODO")
end

local tests = {
	{ test_item, "LOOT_ITEM" },
	{ test_item, "LOOT_ITEM_SELF", true },
	{ test_item, "LOOT_ITEM_MULTIPLE" },
	{ test_item, "LOOT_ITEM_SELF_MULTIPLE", true },
	{ test_item, "LOOT_ITEM_PUSHED_SELF", true },
	{ test_item, "LOOT_ITEM_PUSHED_SELF_MULTIPLE", true },
	{ test_coin, "LOOT_MONEY" },
	{ test_coin, "LOOT_MONEY_SPLIT", true },
	{ test_coin, "YOU_LOOT_MONEY", true },
}

local queue, queueframe, tick = {}, CreateFrame("Frame"), 0
queueframe:SetScript("OnUpdate", function(self, elapsed)
	tick = tick + elapsed
	if tick > 0.5 then
		tick = 0
		local time = GetTime()
		for k,v in pairs(queue) do
			if v[1] < time then
				v[2](select(3, unpack(v)))
				queue[k] = nil
			end
		end
	end
end)

XLoot:SetSlashCommand("xlmd", function(msg)
	local now = GetTime()
	for i=1,15 do
		table.insert(queue, { now + i, unpack(tests[random(1, #tests)]) })
	end
end)
--@end-do-not-package@
