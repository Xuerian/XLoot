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

locales.koKR["bind_on_equip_short"] = "착귀"
locales.koKR["bind_on_pickup_short"] = "획귀"
locales.koKR["bind_on_use_short"] = "사귀"
locales.koKR["button_close"] = "닫기"
locales.koKR["button_link"] = "링크"
locales.koKR["button_auto"] = "자동"
locales.koKR["button_auto_tooltip"] = "이 아이템을 XLoot 자동 획득 목록에 추가합니다.\n자세한 내용은 /xloot에서 확인하세요."
locales.koKR["new_look"] = "(미수집 외형)"
locales.koKR["upgrade"] = "(장비 향상)"
locales.koKR["slot_name_error"] = "전리품 칸 %s의 아이템 이름을 확인할 수 없습니다. 이미 획득했을 수 있습니다. /xloot에서 이 메시지를 끌 수 있습니다."
locales.koKR["slot_icon_error"] = "전리품 칸 %s의 아이콘을 확인할 수 없습니다. 이미 획득했을 수 있습니다. /xloot에서 이 메시지를 끌 수 있습니다."
locales.koKR["linkall_threshold_missed"] = "설정한 최소 품질 이상의 전리품이 없습니다."

XLoot:Localize("Frame", locales)
