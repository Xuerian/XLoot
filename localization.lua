---@class XLootAddon
local XLoot = select(2, ...)

local function CompileLocales(locales)
	local L = locales[GetLocale()] and locales[GetLocale()] or locales.enUS
	if L ~= locales.enUS then
		setmetatable(L, { __index = locales.enUS })
		for k, v in pairs(L) do
			if type(v) == 'table' then
				setmetatable(v, { __index = locales.enUS[k] })
			end
		end
	end
	return L
end

-- locales expects table: { enUS = {...}, ... }
function XLoot:Localize(name, locales)
	-- We need to extract the root namespace due to how Curse is currently doing localizations.
	for _,t in pairs(locales) do
		if t[name] then
			for k, v in pairs(t[name]) do
				t[k] = v
			end
			t[name] = nil
		end
	end
	self["L_"..name] = CompileLocales(locales)
end

local locales = {
	enUS = {
		skin_svelte = "XLoot: Svelte",
		skin_legacy = "XLoot: Legacy",
		skin_smooth = "XLoot: Smooth",
		anchor_hide = "hide",
		minimap_click_left = "Left-click: Open options",
		minimap_click_right = "Right-click: What's New",
		minimap_click_shift = "Shift-click: Toggle Speedy auto-loot",
		speedy_state = "Speedy auto-loot: %s",
		state_on = "ON",
		state_off = "OFF",
		speedy_unavailable = "Speedy auto-loot needs the XLoot Frame module enabled.",
		speedy_usage = "Usage: /xlspeedy toggles Speedy auto-loot. /xlspeedy on or /xlspeedy off sets it directly.",
		binding_toggle_speedy = "Toggle Speedy auto-loot",
		anchor_hide_desc = "Lock this module in position\nThis will hide the anchor,\nbut it can be shown again from the options",
		discord_popup = "Join the XLoot community for help, feedback, and updates.\n\nCopy the invite below (it's pre-selected — just press Ctrl+C):",
	},
	-- Possibly localized
	ptBR = {},
	frFR = {},
	deDE = {},
	koKR = {},
	esMX = {},
	ruRU = {},
	zhCN = {},
	esES = {},
	zhTW = {},
}

-- Automatically inserted translations
--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@

locales.ruRU["anchor_hide"] = "скрыть"
locales.ruRU["anchor_hide_desc"] = "Зафиксировать этот модуль на месте\nЭто скроет якорь,\nно его можно снова показать в настройках"
locales.ruRU["skin_legacy"] = "XLoot: Наследие"
locales.ruRU["skin_smooth"] = "XLoot: Плавный"
locales.ruRU["skin_svelte"] = "XLoot: Стройный"
locales.ruRU["minimap_click_left"] = "ЛКМ: открыть настройки"
locales.ruRU["minimap_click_right"] = "ПКМ: Что нового"
locales.ruRU["discord_popup"] = "Присоединяйтесь к сообществу XLoot, чтобы получить помощь, оставить отзыв и узнавать об обновлениях.\n\nСкопируйте приглашение ниже (оно уже выделено — просто нажмите Ctrl+C):"

XLoot.L = CompileLocales(locales)
