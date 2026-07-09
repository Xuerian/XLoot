-- XLoot is currently maintained by Wheelbarrel00.
-- Originally created by Xuerian.

local XLoot = select(2, ...)

-- Newest first. Array order is the display order, so we never sort version strings.
local updates = {
	{
		version = "12.11.0",
		date = "2026-07-08",
		changes = {
			{
				label = "Announce loot on open",
				type = "feature",
				option = "Loot Frame > Link all button",
				description = "Automatically link a loot window's contents to your chat channel when it opens, using the same quality threshold as the Link all button. Each loot source is announced only once, so reopening a corpse won't repeat it.",
			},
			{
				label = "Urgent roll timer",
				type = "feature",
				option = "Group Loot > Details",
				description = "The roll countdown can ramp to red as time runs out, reddening the whole row border so a roll about to expire is easy to catch at a glance.",
			},
			{
				label = "Clearer, more reliable What's New notices",
				type = "bugfix",
				description = "Version notices now compare numerically, so 12.10.0 no longer sorts below 12.9.0, and they never re-notify or forget notes after a downgrade.",
			},
			{
				label = "Scanning-tooltip refresh fix",
				type = "bugfix",
				description = "Stopped a tooltip refresh loop that could perpetually re-process items with dynamic tooltips like weapon enchants and temporary buffs. Thanks to RoadBlock.",
			},
			{
				label = "Clearer auto-loot help text",
				type = "improvement",
				option = "Loot Frame > Auto-looting",
				description = "The auto-loot section now makes clear it is XLoot's own auto-loot, separate from Blizzard's built-in Auto Loot, and that running both can cause \"that object is busy\" warnings.",
			},
		},
	},
	{
		version = "12.10.0",
		date = "2026-07-07",
		changes = {
			{
				label = "Highlight upgrades and new looks on roll frames",
				type = "feature",
				option = "Group Loot > Details",
				description = "The roll window border can turn green when a drop is an item-level upgrade for you, or blue when it's an appearance you haven't collected yet, so you can tell at a glance whether to roll.",
			},
			{
				label = "Per-item auto-roll",
				type = "feature",
				option = "Group Loot > Auto Roll",
				description = "Shift-click Need, Greed, or Pass on a roll window to set a rule for that item, and matching drops then roll for you automatically, bind-on-pickup prompts included. Auto-Need is behind its own opt-in.",
			},
			{
				label = "Loot window no longer vanishes with double auto-loot",
				type = "bugfix",
				description = "When Blizzard auto loot and XLoot's own auto-loot were both on, the loot window could fail to appear for items that still needed it, like bind-on-pickup confirmations. Thanks to Kai for the report and repro.",
			},
		},
	},
	{
		version = "12.9.0",
		date = "2026-07-05",
		changes = {
			{
				label = "New-appearance \"(new look)\" tag",
				type = "feature",
				option = "Loot Frame > Loot slots",
				description = "Marks looted weapons and armor whose transmog appearance you haven't collected yet, so you never vendor or disenchant a fresh look by mistake.",
			},
			{
				label = "Upgrade \"(upgrade)\" tag",
				type = "feature",
				option = "Loot Frame > Loot slots",
				description = "Marks looted gear with a higher item level than what you already have equipped in that slot.",
			},
			{
				label = "Vendor sell price in tooltips",
				type = "feature",
				option = "Global options",
				description = "On the Classic flavors, item tooltips can show the vendor sell price, including a stack's full value.",
			},
			{
				label = "Test button for Group Loot",
				type = "feature",
				option = "Group Loot > Testing",
				description = "Preview roll frames while you adjust their look, like the Loot Monitor's test button.",
			},
		},
	},
	{
		version = "12.8.1",
		date = "2026-07-03",
		notes = "|cffffd100Sorry for the popup!|r\nI wanted to make sure everyone sees this: you can now get these update notes as a quiet, clickable link in chat instead of a popup. Switch it under |cffffffff/xloot|r > |cffffffffAfter an update|r (choose |cffffffffChat link|r), or tick \"Don't show these again\" below to turn them off.",
		changes = {
			{
				label = "Fixed a group-join error on Classic",
				type = "bugfix",
				description = "XLoot Group no longer throws a Lua error when you join a group on Burning Crusade and other Classic clients. Thanks to Kai for the report.",
			},
		},
	},
	{
		version = "12.8.0",
		date = "2026-07-02",
		changes = {
			{
				label = "Auto-loot by rarity",
				type = "feature",
				option = "Loot Frame > Auto-looting",
				description = "Auto-loot everything at or above a quality you choose, like greens and better.",
			},
			{
				label = 'Show "system message" gold',
				type = "feature",
				option = "Loot Monitor > Filters",
				description = "Adds gold that only shows as a system message, such as world-quest rewards and gold purses (Sky Racer's Purse).",
			},
			{
				label = "Hide Blizzard's loot pop-ups",
				type = "feature",
				option = "Loot Monitor > Blizzard loot alerts",
				description = "Silence the default loot toasts that pile up when you open lots of chests, and let XLoot's Monitor handle it.",
			},
			{
				label = "Right-click to dismiss, longer display",
				type = "feature",
				option = "Loot Monitor > Details / Row fade times",
				description = "Right-click a Monitor row to clear it early, and keep loot on screen far longer if you like.",
			},
			{
				label = "Loot-frame font outline",
				type = "feature",
				option = "Loot Frame > Font",
				description = "A new outline option for the item-name text.",
			},
		},
	},
}

local WHATSNEW_VERSION = updates[1].version
local POPUP_TITLE = "What's New in XLoot"

local HEADING = "|cffffd100"
local VERSION_HEADING = "|cffffffff"
local WHERE = "|cff808080"
local STOP = "|r"

local POPUP_INTRO = HEADING.."Everything here is OFF by default"..STOP.."\n"
	.."XLoot looks and works exactly as before until you switch something on in |cffffffff/xloot|r. Nothing below changes unless you want it to."

local POPUP_FOOTER = HEADING.."Thanks for using XLoot!"..STOP.."\n"
	.."Found a bug or have an idea? Use the Discord button below. You can turn this popup off any time in /xloot."

local function unseen_releases()
	local seen = XLoot.db and XLoot.db.global and XLoot.db.global.whatsnew_seen
	-- The AceDB default is an empty string, so both nil and "" mean a fresh install: latest only, not the whole backlog.
	if not seen or seen == "" then
		return { updates[1] }
	end
	local out = {}
	-- Ordered compare, not an exact match: a downgrade or a pruned entry would otherwise dump the whole backlog.
	for _, release in ipairs(updates) do
		if XLoot.CompareVersions(release.version, seen) <= 0 then break end
		out[#out + 1] = release
	end
	if #out == 0 then
		out[1] = updates[1]  -- caught up but opened manually; never show an empty popup
	end
	return out
end

local function build_body(releases)
	local has_features = false
	for _, release in ipairs(releases) do
		for _, change in ipairs(release.changes) do
			if change.type ~= "bugfix" then
				has_features = true
				break
			end
		end
		if has_features then break end
	end
	local blocks = has_features and { POPUP_INTRO } or {}
	local show_versions = #releases > 1
	for _, release in ipairs(releases) do
		if show_versions then
			local header = VERSION_HEADING.."XLoot "..release.version..STOP
			if release.date then
				header = header.." "..WHERE.."("..release.date..")"..STOP
			end
			blocks[#blocks + 1] = header
		end
		if release.notes then
			blocks[#blocks + 1] = release.notes
		end
		for _, change in ipairs(release.changes) do
			local lines = { HEADING..change.label..STOP }
			if change.option then
				lines[#lines + 1] = WHERE..change.option..STOP
			end
			lines[#lines + 1] = change.description
			blocks[#blocks + 1] = table.concat(lines, "\n")
		end
	end
	blocks[#blocks + 1] = POPUP_FOOTER
	return table.concat(blocks, "\n\n")
end

-- Seen means seen this version OR NEWER, and marking never moves backward, so a downgrade neither re-notifies nor forgets the newer notes.
local function already_seen()
	local seen = XLoot.db and XLoot.db.global and XLoot.db.global.whatsnew_seen
	return seen ~= nil and XLoot.CompareVersions(seen, WHATSNEW_VERSION) >= 0
end

local function mark_seen()
	if XLoot.db and XLoot.db.global then
		local seen = XLoot.db.global.whatsnew_seen
		if not seen or XLoot.CompareVersions(WHATSNEW_VERSION, seen) > 0 then
			XLoot.db.global.whatsnew_seen = WHATSNEW_VERSION
		end
	end
end

local function already_announced()
	local announced = XLoot.db and XLoot.db.global and XLoot.db.global.whatsnew_announced
	return announced ~= nil and XLoot.CompareVersions(announced, WHATSNEW_VERSION) >= 0
end

local function mark_announced()
	if XLoot.db and XLoot.db.global then
		local announced = XLoot.db.global.whatsnew_announced
		if not announced or XLoot.CompareVersions(WHATSNEW_VERSION, announced) > 0 then
			XLoot.db.global.whatsnew_announced = WHATSNEW_VERSION
		end
	end
end

local function announce_chat()
	DEFAULT_CHAT_FRAME:AddMessage("|c2244dd22XLoot|r updated to "..WHATSNEW_VERSION.." — |Haddon:XLoot:whatsnew|h|cffffd100[See what's new]|r|h")
end

-- Custom chat hyperlink (|Haddon:XLoot:whatsnew|h); Blizzard ignores the unknown
-- type, so we open the popup ourselves when ours is clicked.
hooksecurefunc("SetItemRef", function(link)
	if link == "addon:XLoot:whatsnew" then
		XLoot:ShowWhatsNew()
	end
end)

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

	local releases = unseen_releases()

	local f = CreateFrame("Frame", "XLootWhatsNewFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	f:SetSize(520, 490)
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
	f:SetBackdropColor(0.03, 0.03, 0.03, 1)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.title:SetPoint("TOPLEFT", 16, -14)
	f.title:SetText(#releases > 1 and POPUP_TITLE or (POPUP_TITLE.." "..releases[1].version))

	f.byline = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.byline:SetPoint("BOTTOMRIGHT", -14, 74)
	f.byline:SetJustifyH("RIGHT")
	f.byline:SetText("|cff808080Maintained by Wheelbarrel00 · originally by Xuerian|r")

	local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 14, -44)
	scroll:SetPoint("BOTTOMRIGHT", -34, 94)
	local body = CreateFrame("Frame", nil, scroll)
	body:SetSize(scroll:GetWidth(), 1)
	scroll:SetScrollChild(body)
	f.body = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.body:SetPoint("TOPLEFT", 0, 0)
	f.body:SetPoint("TOPRIGHT", 0, 0)
	f.body:SetJustifyH("LEFT")
	f.body:SetJustifyV("TOP")
	f.body:SetSpacing(3)
	f.body:SetText(build_body(releases))
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
	f.dontShow:SetScript("OnShow", function(self) self:SetChecked(XLoot.opt.whatsnew_mode == "none") end)
	f.dontShow:SetScript("OnClick", function(self)
		XLoot.opt.whatsnew_mode = self:GetChecked() and "none" or "popup"
		local reg = LibStub("AceConfigRegistry-3.0", true)
		if reg then reg:NotifyChange("XLoot") end
	end)
	f.dontShow:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Stops What's New notices entirely. You can turn them back on in /xloot.", nil, nil, nil, nil, true)
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
	if not self.opt then return end
	if self.opt.whatsnew == false then          -- migrate the pre-mode opt-out to "None"
		self.opt.whatsnew_mode, self.opt.whatsnew = "none", nil
	end
	local mode = self.opt.whatsnew_mode
	if mode == "none" then return end
	local chat = mode == "chat"
	if (chat and already_announced()) or (not chat and already_seen()) then return end
	C_Timer.After(3, function()
		if not self.opt or self.opt.whatsnew_mode == "none" then return end
		if self.opt.whatsnew_mode == "chat" then
			if not already_announced() then
				announce_chat()
				mark_announced()
			end
		elseif not already_seen() then
			self:ShowWhatsNew()
		end
	end)
end

--@do-not-package@
-- Dev preview, stripped from packaged builds: /xlwhatsnew [lastSeenVersion|chat]
-- A version arg fakes whatsnew_seen so the digest is visible; "chat" prints the link.
local demo_seeded = false
local function seed_demo()
	if demo_seeded then return end
	demo_seeded = true
	updates[#updates + 1] = {
		version = "12.7.0", date = "2026-07-01", notes = "Bug-fix and polish pass.",
		changes = {
			{ label = "Vendor sell price", option = "Loot Monitor > Details",
			  description = "Show an item's vendor value in the loot feed." },
			{ label = "Loot Monitor colors", option = "Loot Monitor > Colors",
			  description = "Recolor rows by item quality." },
		},
	}
	updates[#updates + 1] = {
		version = "12.6.0", date = "2026-06-30",
		changes = {
			{ label = "Speedy auto-loot", option = "Loot Frame > Auto-looting",
			  description = "Empty lootable corpses and chests noticeably faster." },
		},
	}
end

SLASH_XLWHATSNEW1 = "/xlwhatsnew"
SlashCmdList["XLWHATSNEW"] = function(msg)
	seed_demo()
	local arg = (msg or ""):gsub("^%s*(.-)%s*$", "%1")
	if arg == "chat" then
		announce_chat()
		return
	end
	local has_arg = arg ~= ""
	if XLoot.db and XLoot.db.global then
		XLoot.db.global.whatsnew_seen = has_arg and arg or nil
	end
	if frame then frame:Hide() end
	frame = nil
	build():Show()
	print("|cffffd100XLoot|r what's-new preview — last seen: "..(has_arg and arg or "nil (fresh install)"))
end
--@end-do-not-package@
