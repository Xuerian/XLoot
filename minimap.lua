---@class XLootAddon
local XLoot = select(2, ...)
local L = XLoot.L

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local BUTTON = "XLoot"
local ICON = [[Interface\Icons\INV_Misc_Coin_01]]

local function OnClick(_, button)
	if button == "RightButton" then
		XLoot:ShowWhatsNew()
	else
		XLoot:ShowOptionPanel(XLoot)
	end
end

local function OnTooltipShow(tooltip)
	tooltip:AddLine(BUTTON)
	tooltip:AddLine(L.minimap_click_left, 1, 1, 1)
	tooltip:AddLine(L.minimap_click_right, 1, 1, 1)
end

-- minimap_icon is the only source of truth: minimap.hide is derived from it, and the lib owns minimapPos.
function XLoot:UpdateMinimapIcon()
	if not (LDBIcon and LDBIcon:IsRegistered(BUTTON)) then return end
	local db = self.db.profile.minimap
	db.hide = not self.db.profile.minimap_icon
	-- Refresh, not Show/Hide: AceDB hands out a new profile table on a profile switch, and this re-points the button at it.
	LDBIcon:Refresh(BUTTON, db)
end

function XLoot:SetupMinimapIcon()
	if not (LDB and LDBIcon) or LDBIcon:IsRegistered(BUTTON) then return end
	local object = LDB:NewDataObject(BUTTON, {
		type = "launcher",
		label = BUTTON,
		text = BUTTON,
		icon = ICON,
		OnClick = OnClick,
		OnTooltipShow = OnTooltipShow,
	})
	if not object then return end
	local db = self.db.profile.minimap
	db.hide = not self.db.profile.minimap_icon
	LDBIcon:Register(BUTTON, object, db)
end
