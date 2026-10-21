-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		anchor = "Group Rolls",
		alert_anchor = "Loot Popups",
		undecided = "Undecided",
		awaiting = "Rolling...",
		auto_roll_saved = "XLoot: auto-%s set for %s",
		auto_roll_removed = "XLoot: auto-roll cleared for %s",
		auto_roll_none = "No rules yet. Shift-click Need, Greed, or Pass on a roll to add one.",
		roll_type_pass = "pass",
		roll_type_need = "need",
		roll_type_greed = "greed",
		roll_type_disenchant = "disenchant",
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
--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@

locales.ruRU["anchor"] = "Броски группы"
locales.ruRU["alert_anchor"] = "Всплывающие окна с добычей"
locales.ruRU["undecided"] = "Не определились"
locales.ruRU["awaiting"] = "Идёт бросок..."
locales.ruRU["auto_roll_saved"] = "XLoot: автовыбор «%s» задан для %s"
locales.ruRU["auto_roll_removed"] = "XLoot: автобросок для %s отменён"
locales.ruRU["auto_roll_none"] = "Правил пока нет. Shift+клик по «Нужно», «Не откажусь» или «Пас» в окне броска добавит правило."
locales.ruRU["roll_type_pass"] = "Пас"
locales.ruRU["roll_type_need"] = "Нужно"
locales.ruRU["roll_type_greed"] = "Не откажусь"
locales.ruRU["roll_type_disenchant"] = "Распылить"

XLoot:Localize("Group", locales)
