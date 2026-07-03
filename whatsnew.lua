local XLoot = select(2, ...)

-- Bump this (and the body) whenever the popup should re-appear for a new release.
local WHATSNEW_VERSION = "12.8.0"
local POPUP_TITLE = "What's New in XLoot "..WHATSNEW_VERSION

local POPUP_BODY = [[
|cffffd100Everything here is OFF by default|r
XLoot looks and works exactly as before until you switch something on in |cffffffff/xloot|r. Nothing below changes unless you want it to.

|cffffd100Auto-loot by rarity|r
|cff808080Loot Frame > Auto-looting|r
Auto-loot everything at or above a quality you choose, like greens and better.

|cffffd100Show "system message" gold|r
|cff808080Loot Monitor > Filters|r
Adds gold that only shows as a system message, such as world-quest rewards and gold purses (Sky Racer's Purse).

|cffffd100Hide Blizzard's loot pop-ups|r
|cff808080Loot Monitor > Blizzard loot alerts|r
Silence the default loot toasts that pile up when you open lots of chests, and let XLoot's Monitor handle it.

|cffffd100Right-click to dismiss, longer display|r
|cff808080Loot Monitor > Details / Row fade times|r
Right-click a Monitor row to clear it early, and keep loot on screen far longer if you like.

|cffffd100Loot-frame font outline|r
|cff808080Loot Frame > Font|r
A new outline option for the item-name text.

|cffffd100Thanks for using XLoot!|r
Found a bug or have an idea? Use the Discord button below. You can turn this popup off any time in /xloot.
]]

local function already_seen()
	return XLoot.db and XLoot.db.global and XLoot.db.global.whatsnew_seen == WHATSNEW_VERSION
end

local function mark_seen()
	if XLoot.db and XLoot.db.global then
		XLoot.db.global.whatsnew_seen = WHATSNEW_VERSION
	end
end

local function make_button(parent, width, text, r, g, b)
	local btn = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	btn:SetSize(width, 26)
	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(r, g, b, 0.95)
	btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	btn.text:SetPoint("CENTER")
	btn.text:SetText(text)
	return btn
end

local frame
local function build()
	if frame then return frame end

	local f = CreateFrame("Frame", "XLootWhatsNewFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	f:SetSize(520, 470)
	f:SetPoint("CENTER")
	-- Above the options window's DIALOG strata so it isn't hidden behind it.
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	f:Hide()

	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	f:SetBackdropColor(0.03, 0.03, 0.03, 0.97)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.title:SetPoint("TOPLEFT", 16, -14)
	f.title:SetText(POPUP_TITLE)

	local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 14, -44)
	scroll:SetPoint("BOTTOMRIGHT", -34, 78)
	local body = CreateFrame("Frame", nil, scroll)
	body:SetSize(scroll:GetWidth(), 1)
	scroll:SetScrollChild(body)
	f.body = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.body:SetPoint("TOPLEFT", 0, 0)
	f.body:SetPoint("TOPRIGHT", 0, 0)
	f.body:SetJustifyH("LEFT")
	f.body:SetJustifyV("TOP")
	f.body:SetSpacing(3)
	f.body:SetText(POPUP_BODY)
	body:SetHeight(f.body:GetStringHeight() + 12)

	-- Mark seen on an explicit close (button, X, or Escape) but NOT when an ancestor
	-- hide (cinematic, Alt-Z) fires OnHide while our own shown flag is still set.
	-- OnHide is set after the initial Hide above so building never marks it prematurely.
	f:SetScript("OnHide", function(self) if not self:IsShown() then mark_seen() end end)
	table.insert(UISpecialFrames, "XLootWhatsNewFrame")

	local function dismiss()
		f:Hide()
	end

	f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.close:SetPoint("TOPRIGHT", -4, -4)
	f.close:SetScript("OnClick", dismiss)

	f.dontShow = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	f.dontShow:SetSize(22, 22)
	f.dontShow:SetPoint("BOTTOMLEFT", 14, 46)
	f.dontShow.text = f.dontShow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.dontShow.text:SetPoint("LEFT", f.dontShow, "RIGHT", 2, 0)
	f.dontShow.text:SetText("Don't show these again")
	f.dontShow:SetScript("OnShow", function(self) self:SetChecked(not XLoot.opt.whatsnew) end)
	f.dontShow:SetScript("OnClick", function(self)
		XLoot.opt.whatsnew = not self:GetChecked()
		local reg = LibStub("AceConfigRegistry-3.0", true)
		if reg then reg:NotifyChange("XLoot") end
	end)
	f.dontShow:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Permanently disables the What's New popup. You can turn it back on in /xloot.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	f.dontShow:SetScript("OnLeave", function() GameTooltip:Hide() end)

	f.optBtn = make_button(f, 150, "XLoot options", 0.10, 0.10, 0.10)
	f.optBtn:SetPoint("BOTTOMLEFT", 14, 14)
	f.optBtn:SetScript("OnClick", function()
		dismiss()
		XLoot:ShowOptionPanel(XLoot)
	end)

	f.gotBtn = make_button(f, 110, "Got it", 0.16, 0.34, 0.14)
	f.gotBtn:SetPoint("BOTTOMRIGHT", -14, 14)
	f.gotBtn:SetScript("OnClick", dismiss)

	f.discordBtn = make_button(f, 150, "Join our Discord!", 0.10, 0.10, 0.10)
	f.discordBtn:SetPoint("BOTTOM", 0, 14)
	f.discordBtn:SetScript("OnClick", function() XLoot:ShowDiscord() end)

	frame = f
	return f
end

function XLoot:ShowWhatsNew()
	build():Show()
end

function XLoot:CheckWhatsNew()
	if not (self.opt and self.opt.whatsnew) or already_seen() then return end
	C_Timer.After(3, function()
		if self.opt.whatsnew and not already_seen() then
			self:ShowWhatsNew()
		end
	end)
end
