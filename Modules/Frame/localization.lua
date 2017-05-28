-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		linkall_threshold_missed = "No loot meets your quality threshold",
		button_link = "Link",
		button_close = "Close",
		button_auto = "A",
		button_auto_tooltip = "Add this item to XLoot's autoloot list\nSee /xloot for more info",
		bind_on_use_short = "BoU",
		bind_on_equip_short = "BoE",
		bind_on_pickup_short = "BoP"
	},
	-- Possibly localized
	ptBR = {

	},
	frFR = {

	},
	deDE = {

	},
	koKR = {

	},
	esMX = {

	},
	ruRU = {

	},
	zhCN = {

	},
	esES = {

	},
	zhTW = {

	},
}

-- Automatically inserted translations
--@localization(locale="ptBR", format="lua_table", table-name="locales.ptBR", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="frFR", format="lua_table", table-name="locales.frFR", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="deDE", format="lua_table", table-name="locales.deDE", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="koKR", format="lua_table", table-name="locales.koKR", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="esMX", format="lua_table", table-name="locales.esMX", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="ruRU", format="lua_table", table-name="locales.ruRU", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="zhCN", format="lua_table", table-name="locales.zhCN", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="esES", format="lua_table", table-name="locales.esES", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="zhTW", format="lua_table", table-name="locales.zhTW", handle-unlocalized="ignore", namespace="Frame")@

XLoot:Localize("Frame", locales)
