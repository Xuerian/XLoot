local XLoot = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), "XLoot")
_G.XLoot = XLoot
local L = XLoot.L
local print, wprint = print, print

-------------------------------------------------------------------------------
-- Settings
local defaults = {
	profile = {
		skin = "smooth"
	}
}


-------------------------------------------------------------------------------
-- Module helpers

-- Return module localization with new module
local _NewModule = XLoot.NewModule
function XLoot:NewModule(module_name, ...)
	local new = _NewModule(self, module_name, ...)
	return new, self["L_"..module_name]
end

local _GetModule = XLoot.GetModule
function XLoot:GetModule(module_name, ...)
	return module_name == "Core" and XLoot or _GetModule(self, module_name, ...)
end

-- Set up basic event handler
local function SetEventHandler(addon, frame)
	if not frame then
		frame = CreateFrame("Frame")
		addon.eframe = frame
	end
	frame:SetScript("OnEvent", function(self, event, ...)
		if addon[event] then
			addon[event](addon, ...)
		end
	end)
end

-- Load and call Options
-- local function StubInit(self)
-- 	if not XLootOptions then
-- 		EnableAddOn("XLoot_Options")
-- 		LoadAddOn("XLoot_Options")
-- 	end
-- 	XLootOptions:StubInit(self)
-- end

XLoot.slash_commands = {}
function XLoot:SetSlashCommand(slash, func)
	local key = "XLOOT_"..slash
	_G["SLASH_"..key.."1"] = "/"..slash
	_G.SlashCmdList[key] = func
end

function XLoot:ShowOptionPanel(module)
	if not XLootOptions then
		EnableAddOn("XLoot_Options")
		LoadAddOn("XLoot_Options")
	end
	XLootOptions:OpenPanel(module)
end

-- Add shortcuts for modules
XLoot:SetDefaultModulePrototype({
	InitializeModule = function(self, defaults, frame)
		local module_name = self:GetName()
		-- Set up DB namespace
		self.db = XLoot.db:RegisterNamespace(module_name, defaults)
		
		function self.ShowOptions()
			XLoot:ShowOptionPanel(self)
		end
		-- Default slash command
		XLoot:SetSlashCommand(("XLoot"..module_name):lower(), self.ShowOptions)
		-- Set event handler
		self:SetEventHandler(frame)
	end,
	ShowOptions = ShowOptions,
	SetEventHandler = SetEventHandler
})

-------------------------------------------------------------------------------
-- Addon init

function XLoot:OnInitialize()
	-- Init DB
	self.db = LibStub("AceDB-3.0"):New("XLootADB", defaults, true)
	-- Load skins, import Masque skins
	self:SkinsOnInitialize()
end

function XLoot:OnEnable()
	-- Check for old addons
	local old = { "XLoot1.0", "XLootGroup", "XLootMaster" }
	for _,name in ipairs(old) do
		if IsAddOnLoaded(name) then
			DisableAddOn("XLootGroup")
			wprint(("|c2244dd22XLoot|r now includes |c2244dd22%s|r - the old version will be disabled on next load, and no longer needs to be installed."):format(name))
		end
	end	

	-- Create option stub
	local stub = CreateFrame("Frame", "XLootConfigPanel", UIParent)
	stub.name = "XLoot"
	stub:Hide()
	InterfaceOptions_AddCategory(stub)
	stub:SetScript("OnShow", function() self:ShowOptionPanel(self) end)
	self:SetSlashCommand("xloot", function() self:ShowOptionPanel(self) end)
end

--@do-not-package@
local AC = LibStub("AceConsole-2.0", true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
