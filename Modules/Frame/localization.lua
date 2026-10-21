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
		bind_on_pickup_short = "BoP",
		new_look = "(new look)",
		upgrade = "(upgrade)",

		slot_name_error = "Could not get item name for loot slot %s , it may have already been looted. You can turn this message off in /xloot",
		slot_icon_error = "Could not get item icon for loot slot %s , it may have already been looted. You can turn this message off in /xloot",

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
--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@

locales.ruRU["linkall_threshold_missed"] = "Нет добычи, соответствующей вашему порогу качества"
locales.ruRU["button_link"] = "Ссылка"
locales.ruRU["button_close"] = "Закрыть"
locales.ruRU["button_auto"] = "А"
locales.ruRU["button_auto_tooltip"] = "Добавить этот предмет в список автолута XLoot\nПодробнее: /xloot"
locales.ruRU["bind_on_use_short"] = "БоИ"
locales.ruRU["bind_on_equip_short"] = "БоЕ"
locales.ruRU["bind_on_pickup_short"] = "БоП"
locales.ruRU["new_look"] = "(новый вид)"
locales.ruRU["upgrade"] = "(улучшение)"
locales.ruRU["slot_name_error"] = "Не удалось получить название предмета для ячейки добычи %s, возможно, он уже взят. Это сообщение можно отключить в /xloot"
locales.ruRU["slot_icon_error"] = "Не удалось получить значок предмета для ячейки добычи %s, возможно, он уже взят. Это сообщение можно отключить в /xloot"

XLoot:Localize("Frame", locales)
