-- Create module
local addon, L = XLoot:NewModule("Monitor")
local XLootMonitor = CreateFrame("Frame", "XLootMonitor", UIParent)
XLootMonitor.addon = addon
-- Grab locals
local print, opt, eframe = print
-- Libraries
local LootEvents

-------------------------------------------------------------------------------
-- Settings

local defaults = {
	profile = {

	}
}

-------------------------------------------------------------------------------
-- Module init

function addon:OnInitialize()
	eframe = CreateFrame("Frame")
	self:InitializeModule(defaults, eframe)
	opt = self.db.profile
	LootEvents = LibStub("LootEvents")
end

function addon:OnEnable()
	LootEvents:RegisterLootCallback(function(...) self:LOOT(...) end)

end

function addon:LOOT(event, pattern, player, arg1, arg2)
	-- print(event, pattern, player, arg1, arg2)
	if event == 'item' then
		local link, num = arg1, arg2
	elseif event == 'coin' then
		local copper, coin_string = arg1, arg2
	end
end

--@do-not-package@
local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
