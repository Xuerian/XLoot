-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		ML_RANDOM = "Raid Roll",
		ML_SELF = "Self Loot",
		ML_BANKER = "Banker",
		ML_DISENCHANTER = "Disenchanter",
		RECIPIENTS = "Special Recipients",
		SPECIALROLLS = "Special Rolls",
		BINDING_BANKER = "Set Banker",
		BINDING_DISENCHANTER = "Set Disenchanter",
		ITEM_AWARDED = "%s awarded: %s",
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
--@localization(locale="ptBR", format="lua_table", table-name="locales.ptBR", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="frFR", format="lua_table", table-name="locales.frFR", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="deDE", format="lua_table", table-name="locales.deDE", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="koKR", format="lua_table", table-name="locales.koKR", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="esMX", format="lua_table", table-name="locales.esMX", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="ruRU", format="lua_table", table-name="locales.ruRU", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="zhCN", format="lua_table", table-name="locales.zhCN", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="esES", format="lua_table", table-name="locales.esES", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="zhTW", format="lua_table", table-name="locales.zhTW", handle-unlocalized="ignore", namespace="Master")@

XLoot:Localize("Master", locales)
