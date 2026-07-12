local addon, L = XLoot:NewModule("Toast")

XLootToast = CreateFrame("Frame", "XLootToast", UIParent)
XLootToast.addon = addon

local opt, eframe, anchor
local me = UnitName("player")
local issecret = issecretvalue
local table_insert, table_remove = table.insert, table.remove
local floor, ceil, random = math.floor, math.ceil, math.random
local GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local GetItemQualityColor = C_Item.GetItemQualityColor

local TOAST_W, TOAST_H, ICON = 224, 48, 42
local GLOW = [[Interface\AchievementFrame\UI-Achievement-Alert-Glow]]
-- UI_EPICLOOT_TOAST / UI_LEGENDARY_LOOT_TOAST. Numeric fallbacks for flavors lacking the named keys.
local SOUND_LOOT = (SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST) or 31578
local SOUND_LEGENDARY = (SOUNDKIT and SOUNDKIT.UI_LEGENDARY_LOOT_TOAST) or 63971

-------------------------------------------------------------------------------
-- Settings

local defaults = {
	profile = {
		enabled = false,
		anchor = {
			direction = "down",
			alignment = "left",
			visible = false,
			scale = 1.0,
			draggable = true,
			offset = 0,
			spacing = 14,
			x = UIParent:GetWidth() * .5 - TOAST_W * .5,
			y = UIParent:GetHeight() * .72,
		},
		threshold = 3,
		quest = false,
		ilvl = false,
		max_active = 6,
		fadeout_delay = 2.8,
		vfx = true,
		sfx = true,
		mouse_hover = true,
		mouse_click_mode = "always",
		color_name = false,
		color_border = true,
		color_icon_border = true,
		color_threshold = 1,
		font = STANDARD_TEXT_FONT,
		font_size = 12,
		font_flag = "OUTLINE",
	}
}

-------------------------------------------------------------------------------
-- Animated counter (lerps a displayed number toward its target)

local animating, count_ticker = {}
local function count_tick()
	for fs, target in pairs(animating) do
		fs._elapsed = fs._elapsed + 0.05
		local v = fs._value
		local nv = v >= target and floor(v + (target - v) * (fs._elapsed / 0.6))
			or ceil(v + (target - v) * (fs._elapsed / 0.6))
		fs._value = nv
		fs:SetText(nv > 1 and nv or "")
		if nv == target then animating[fs] = nil end
	end
	if not next(animating) and count_ticker then
		count_ticker:Cancel()
		count_ticker = nil
	end
end

local function set_count(fs, target, skip)
	if skip then
		fs._value, fs._elapsed = target, 0
		fs:SetText(target > 1 and target or "")
	else
		fs._value, fs._elapsed = fs._value or 1, 0
		animating[fs] = target
		if not count_ticker then count_ticker = C_Timer.NewTicker(0.05, count_tick) end
	end
end

-------------------------------------------------------------------------------
-- Module init

function addon:OnInitialize()
	eframe = CreateFrame("Frame")
	self:InitializeModule(defaults, eframe)
	opt = self.db.profile
end

local pool, active, queued, byitem = {}, {}, {}, {}
local registered

function addon:OnEnable()
	XLoot:MakeSkinner(self, {
		default = { gradient = true },
		anchor = { r = .4, g = .4, b = .4, a = .6, gradient = false },
		anchor_pretty = { r = .6, g = .6, b = .6, a = .8 },
		icon = { backdrop = false, gradient = false },
		icon_highlight = { type = "highlight", layer = "OVERLAY" },
	})
	anchor = XLoot.Stack:CreateStaticStack(self.CreateToast, L.anchor, opt.anchor)
	anchor:SetFrameLevel(6)
	self:Skin(anchor, XLoot.opt.skin_anchors and 'anchor_pretty' or 'anchor')
	addon.anchor = anchor
	self:ApplyState()
end

function addon:ApplyState()
	if opt.enabled and not registered then
		-- Loot feed comes from Monitor's shared LootEvents lib, stay inert (never error) if that module was removed.
		local LootEvents = LibStub("LootEvents", true)
		if LootEvents then
			registered = true
			LootEvents:RegisterLootCallback(self.LOOT_EVENT)
			eframe:RegisterEvent("MODIFIER_STATE_CHANGED")
		end
	end
	self:UpdateAnchors()
end

function addon:ApplyOptions()
	opt = self.opt
	anchor:UpdateSVData(opt.anchor)
	self:ApplyState()
	for _, t in ipairs(active) do
		t:ApplyOptions()
	end
	self:Reflow()
end

function addon:UpdateAnchors()
	-- Raw _Show/_Hide keeps the config preview from flipping the saved visible flag that Show would set.
	if opt.anchor.visible or addon.config_preview then
		anchor:SetClampedToScreen(true)
		anchor:Position()
		anchor:_Show()
	else
		anchor:_Hide()
	end
end

function addon:OnOptionsShow()
	addon.config_preview = true
	self:UpdateAnchors()
end

function addon:OnOptionsHide()
	addon.config_preview = nil
	self:UpdateAnchors()
end

-------------------------------------------------------------------------------
-- Loot intake

function addon.LOOT_EVENT(event, _, ...)
	if opt.enabled and event == "item" then
		addon:OnItem(...)
	end
end

function addon:OnItem(player, link, num)
	if player ~= me or not link or not link:match("|Hitem:") then return end
	if issecret and issecret(link) then return end
	-- Delay a moment so the item is cached and rapid same-item loot coalesces onto one toast
	C_Timer.After(0.3, function() addon:BuildToast(link, tonumber(num) or 1) end)
end

function addon:BuildToast(link, num)
	if not opt.enabled then return end
	local itemID = GetItemInfoInstant(link)
	if not itemID then return end

	local existing = byitem[itemID]
	if existing then
		existing.count_value = existing.count_value + num
		if existing.active then
			set_count(existing.count, existing.count_value)
			existing.blinktext:SetText("+" .. num)
			existing.Blink:Stop()
			existing.Blink:Play()
			-- Skip while hovered so a coalesced loot cannot fade the toast out from under the cursor.
			if not MouseIsOver(existing) then existing:RestartFade() end
		else
			set_count(existing.count, existing.count_value, true)
		end
		return
	end

	local name, _, quality, _, _, _, _, _, _, icon, _, classID, subClassID, bindType = GetItemInfo(link)
	if not name or type(quality) ~= "number" then return end
	local isQuest = bindType == 4 or (classID == 12 and subClassID == 0)
	if quality < opt.threshold and not (isQuest and opt.quest) then return end

	local toast = table_remove(pool) or self.CreateToast()
	toast.item = link
	toast.itemID = itemID
	toast.count_value = num
	toast.icon:SetTexture(icon)

	local title, tr, tg, tb, sound = L.received, 1, .82, 0, SOUND_LOOT
	if quality == 5 then
		title, sound = L.legendary, SOUND_LEGENDARY
	end

	local dname = name
	if opt.ilvl then
		local ilvl = GetDetailedItemLevelInfo(link)
		if ilvl and ilvl > 0 then dname = "[" .. ilvl .. "] " .. name end
	end

	local r, g, b, hex = GetItemQualityColor(quality)
	if quality >= opt.color_threshold then
		if opt.color_name and hex then dname = "|c" .. hex .. dname .. "|r" end
		if opt.color_border then toast:SetBorderColor(r, g, b) end
		if opt.color_icon_border then toast.icon_frame:SetBorderColor(r, g, b) end
		if toast.SetGradientColor then toast:SetGradientColor(r, g, b, .35) end
	end

	toast.title:SetText(title)
	toast.title:SetTextColor(tr, tg, tb)
	toast.name:SetText(dname)
	set_count(toast.count, num, true)
	toast.sound = opt.sfx and sound
	toast.isQuest = isQuest
	toast:ApplyOptions()

	byitem[itemID] = toast
	self:Spawn(toast)
end

-------------------------------------------------------------------------------
-- Queue / stacking

function addon:Reflow()
	for i, t in ipairs(active) do
		anchor:AnchorChild(t, i > 1 and active[i - 1] or nil)
	end
end

function addon:Spawn(toast)
	toast.managed = true
	if #active < opt.max_active then
		toast.active = true
		table_insert(active, toast)
		self:Reflow()
		toast:Show()
		if toast.sound then PlaySound(toast.sound) end
		if opt.vfx then toast.AnimGlow:Play() end
		toast:RestartFade()
	else
		table_insert(queued, toast)
	end
end

function addon:ReleaseToast(toast)
	-- Idempotent so a double release cannot pool the frame twice and re-add it to active, which would self-anchor and error.
	if not toast.managed then return end
	toast.managed = nil
	toast.AnimOut:Stop()
	toast.AnimGlow:Stop()
	toast.Blink:Stop()
	toast:Hide()
	toast:ClearAllPoints()
	toast.active = nil
	if byitem[toast.itemID] == toast then byitem[toast.itemID] = nil end
	for i, t in ipairs(active) do
		if t == toast then table_remove(active, i); break end
	end
	for i, t in ipairs(queued) do
		if t == toast then table_remove(queued, i); break end
	end
	table_insert(pool, toast)
	if #active < opt.max_active and queued[1] then
		self:Spawn(table_remove(queued, 1))
	end
	self:Reflow()
end

-------------------------------------------------------------------------------
-- Toast frame

local mouse_focus

-- SetPassThroughButtons is protected under combat lockdown, so skip it in combat.
local function set_passthrough(toast, ...)
	if not toast.SetPassThroughButtons or InCombatLockdown() then return end
	toast:SetPassThroughButtons(...)
end

local function apply_mouse(toast)
	if not toast.SetMouseClickEnabled then
		toast:EnableMouse(opt.mouse_click_mode ~= "never" or opt.mouse_hover)
		return
	end
	local mode = opt.mouse_click_mode
	-- Modifier mode needs motion on to detect the hover even when the tooltip is off.
	toast:SetMouseMotionEnabled(opt.mouse_hover or mode == "modifier")
	toast:SetMouseClickEnabled(mode ~= "never")
	-- Modifier mode keeps right-click for dismiss and lets left pass through until Shift is held.
	if mode == "modifier" then
		set_passthrough(toast, "LeftButton")
	else
		set_passthrough(toast)
	end
end

local function update_modifier_click(toast)
	if toast and toast.SetPassThroughButtons and opt.mouse_click_mode == "modifier" then
		if IsShiftKeyDown() then
			set_passthrough(toast)
		else
			set_passthrough(toast, "LeftButton")
		end
	end
end

function addon:MODIFIER_STATE_CHANGED()
	if mouse_focus and MouseIsOver(mouse_focus) then
		update_modifier_click(mouse_focus)
		if opt.mouse_hover and mouse_focus.item then
			GameTooltip:SetHyperlink(mouse_focus.item)
		end
	end
end

do
	local function RestartFade(self)
		self.AnimOut:Stop()
		self:SetAlpha(1)
		self.AnimOut.fade:SetStartDelay(opt.fadeout_delay)
		self.AnimOut:Play()
	end

	local function OnEnter(self)
		mouse_focus = self
		self.AnimOut:Stop()
		self:SetAlpha(1)
		update_modifier_click(self)
		if opt.mouse_hover then
			self.icon_frame:ShowHighlight()
			if self.item then
				GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT', 28, 0)
				GameTooltip:SetHyperlink(self.item)
			end
		end
	end

	local function OnLeave(self)
		mouse_focus = nil
		self.icon_frame:HideHighlight()
		GameTooltip:Hide()
		if opt.mouse_click_mode == "modifier" and self.SetPassThroughButtons then
			set_passthrough(self, "LeftButton")
		end
		if self.active then self:RestartFade() end
	end

	-- A parent hide (Alt-Z, cinematics) hides the toast without firing OnLeave, so clear the hover state it would otherwise strand.
	local function OnHide(self)
		if mouse_focus == self then
			mouse_focus = nil
			self.icon_frame:HideHighlight()
			GameTooltip:Hide()
		end
	end

	local function OnClick(self, button)
		if button == "RightButton" then
			addon:ReleaseToast(self)
		elseif self.item then
			HandleModifiedItemClick(self.item)
		end
	end

	local function ApplyOptions(self)
		local a, b, xmod = "LEFT", "RIGHT", 1
		if opt.anchor.alignment == "right" then a, b, xmod = b, a, -1 end
		self.icon_frame:ClearAllPoints()
		self.icon_frame:SetPoint(a, 3 * xmod, 0)
		self.title:ClearAllPoints()
		self.title:SetPoint("TOP" .. a, self.icon_frame, "TOP" .. b, 6 * xmod, -2)
		self.title:SetPoint("TOP" .. b, self, "TOPRIGHT", -4 * xmod, -2)
		self.title:SetJustifyH(a)
		self.title:SetFont(opt.font, opt.font_size, opt.font_flag)
		self.name:ClearAllPoints()
		self.name:SetPoint("BOTTOM" .. a, self.icon_frame, "BOTTOM" .. b, 6 * xmod, 2)
		self.name:SetPoint("TOP" .. b, self, "RIGHT", -4 * xmod, 0)
		self.name:SetJustifyH(a)
		self.name:SetFont(opt.font, opt.font_size + 1, opt.font_flag)
		self.count:SetFont(opt.font, opt.font_size, "THICKOUTLINE")
		apply_mouse(self)
	end

	function addon.CreateToast()
		local frame = CreateFrame("Button", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		frame:SetSize(TOAST_W, TOAST_H)
		frame:SetFrameLevel(anchor:GetFrameLevel() + 2)
		addon:Skin(frame)
		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		frame:SetScript("OnClick", OnClick)
		frame:SetScript("OnEnter", OnEnter)
		frame:SetScript("OnLeave", OnLeave)
		frame:SetScript("OnHide", OnHide)

		local icon_frame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
		icon_frame:SetSize(ICON, ICON)
		addon:Skin(icon_frame, "icon")
		addon:Highlight(icon_frame, "icon_highlight")
		frame.icon_frame = icon_frame

		local icon = icon_frame:CreateTexture(nil, "BACKGROUND")
		icon:SetPoint("TOPLEFT", 2, -2)
		icon:SetPoint("BOTTOMRIGHT", -2, 2)
		icon:SetTexCoord(.07, .93, .07, .93)
		frame.icon = icon

		local count = icon_frame:CreateFontString(nil, "OVERLAY")
		count:SetPoint("BOTTOMRIGHT", -1, 2)
		count:SetJustifyH("RIGHT")
		frame.count = count

		local blinktext = icon_frame:CreateFontString(nil, "OVERLAY")
		blinktext:SetPoint("CENTER", icon_frame, "TOP", 0, 0)
		blinktext:SetFont(STANDARD_TEXT_FONT, 14, "THICKOUTLINE")
		blinktext:SetTextColor(.2, 1, .2)
		blinktext:SetAlpha(0)
		frame.blinktext = blinktext

		frame.title = frame:CreateFontString(nil, "ARTWORK")
		frame.title:SetHeight(14)
		frame.name = frame:CreateFontString(nil, "ARTWORK")
		frame.name:SetHeight(28)
		frame.name:SetMaxLines(2)

		local glowparent = CreateFrame("Frame", nil, frame)
		glowparent:SetFrameLevel(frame:GetFrameLevel() + 3)
		glowparent:SetAllPoints()
		local glow = glowparent:CreateTexture(nil, "OVERLAY")
		glow:SetBlendMode("ADD")
		glow:SetTexture(GLOW)
		glow:SetTexCoord(5/512, 395/512, 5/256, 167/256)
		glow:SetPoint("CENTER")
		glow:SetSize(TOAST_W * 1.4, TOAST_H * 3)
		glow:SetAlpha(0)
		frame.glow = glow
		local shine = glowparent:CreateTexture(nil, "OVERLAY")
		shine:SetBlendMode("ADD")
		shine:SetTexture(GLOW)
		shine:SetTexCoord(403/512, 465/512, 14/256, 62/256)
		shine:SetSize(66, TOAST_H)
		shine:SetPoint("LEFT")
		shine:SetAlpha(0)
		frame.shine = shine

		-- Spawn flourish: glow pulses, shine sweeps across
		local glowag = frame:CreateAnimationGroup()
		glowag:SetToFinalAlpha(true)
		local a1 = glowag:CreateAnimation("Alpha"); a1:SetChildKey("glow"); a1:SetOrder(1)
		a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.2)
		local a2 = glowag:CreateAnimation("Alpha"); a2:SetChildKey("glow"); a2:SetOrder(2)
		a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetDuration(0.5)
		local s1 = glowag:CreateAnimation("Alpha"); s1:SetChildKey("shine"); s1:SetOrder(1)
		s1:SetFromAlpha(0); s1:SetToAlpha(1); s1:SetDuration(0.2)
		local s2 = glowag:CreateAnimation("Translation"); s2:SetChildKey("shine"); s2:SetOrder(2)
		s2:SetOffset(TOAST_W - 66, 0); s2:SetDuration(0.85)
		local s3 = glowag:CreateAnimation("Alpha"); s3:SetChildKey("shine"); s3:SetOrder(2)
		s3:SetFromAlpha(1); s3:SetToAlpha(0); s3:SetStartDelay(0.35); s3:SetDuration(0.5)
		frame.AnimGlow = glowag

		-- Coalesce blink: the "+N" pops above the icon
		local blinkag = frame:CreateAnimationGroup()
		blinkag:SetToFinalAlpha(true)
		local b1 = blinkag:CreateAnimation("Alpha"); b1:SetChildKey("blinktext"); b1:SetOrder(1)
		b1:SetFromAlpha(0); b1:SetToAlpha(1); b1:SetDuration(0.2)
		local b2 = blinkag:CreateAnimation("Alpha"); b2:SetChildKey("blinktext"); b2:SetOrder(2)
		b2:SetFromAlpha(1); b2:SetToAlpha(0); b2:SetStartDelay(0.4); b2:SetDuration(0.4)
		frame.Blink = blinkag

		local outag = frame:CreateAnimationGroup()
		local fade = outag:CreateAnimation("Alpha"); fade:SetOrder(1)
		fade:SetFromAlpha(1); fade:SetToAlpha(0); fade:SetDuration(1.2)
		outag.fade = fade
		outag:SetScript("OnFinished", function() addon:ReleaseToast(frame) end)
		frame.AnimOut = outag

		frame.ApplyOptions = ApplyOptions
		frame.RestartFade = RestartFade
		frame:ApplyOptions()
		frame:Hide()
		return frame
	end
end

-------------------------------------------------------------------------------
-- preview / test

local test_samples = {
	{ "Worn Trinket", [[Interface\Icons\INV_Jewelry_Necklace_07]], 2 },
	{ "Gleaming Band", [[Interface\Icons\INV_Jewelry_Ring_03]], 3 },
	{ "Ravencrest's Legacy", [[Interface\Icons\INV_Sword_04]], 4 },
	{ "Heart of the Titan", [[Interface\Icons\INV_Misc_Gem_Pearl_06]], 5 },
}

function XLootToast.TestSettings()
	for _, s in ipairs(test_samples) do
		local toast = table_remove(pool) or addon.CreateToast()
		toast.item, toast.itemID, toast.count_value = nil, -random(1, 100000), random(1, 4)
		toast.icon:SetTexture(s[2])
		local r, g, b = GetItemQualityColor(s[3])
		toast:SetBorderColor(r, g, b)
		toast.icon_frame:SetBorderColor(r, g, b)
		if toast.SetGradientColor then toast:SetGradientColor(r, g, b, .35) end
		toast.title:SetText(s[3] == 5 and L.legendary or L.received)
		toast.title:SetTextColor(1, .82, 0)
		toast.name:SetText(s[1])
		set_count(toast.count, toast.count_value, true)
		toast.sound = opt.sfx and (s[3] == 5 and SOUND_LEGENDARY or SOUND_LOOT)
		toast:ApplyOptions()
		addon:Spawn(toast)
	end
end

XLoot:SetSlashCommand("xltd", XLootToast.TestSettings)
