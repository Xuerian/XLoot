-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		ML_RANDOM = "Raid Roll",
		ML_SELF = "Self Loot",
		ML_BANKER = "Banker",
		ML_DISENCHANTER = "Disenchanter",
		RECIPIENTS = "Special Recipients",
		SPECIALROLLS = "Special Rolls",
		ITEM_AWARDED = "%s awarded: %s",
		CANDIDATE_UNAVAILABLE = "That player is no longer eligible to receive loot.",
		ITEM_UNAVAILABLE = "That item is no longer in the loot window.",
		ROLL_DISCARDED = "Raid roll discarded - no winner was assigned.",
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
--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@

locales.ruRU["ML_RANDOM"] = "Рейдовый бросок"
locales.ruRU["ML_SELF"] = "Своя добыча"
locales.ruRU["ML_BANKER"] = "Банкир"
locales.ruRU["ML_DISENCHANTER"] = "Распылитель"
locales.ruRU["RECIPIENTS"] = "Особые получатели"
locales.ruRU["SPECIALROLLS"] = "Особые броски"
locales.ruRU["ITEM_AWARDED"] = "%s получает: %s"
locales.ruRU["CANDIDATE_UNAVAILABLE"] = "Этот игрок больше не может получить добычу."
locales.ruRU["ITEM_UNAVAILABLE"] = "Этого предмета больше нет в окне добычи."
locales.ruRU["ROLL_DISCARDED"] = "Рейдовый бросок отменён — победитель не назначен."

locales.koKR["ML_RANDOM"] = "공격대 주사위"
locales.koKR["RECIPIENTS"] = "특별 수령인"
locales.koKR["SPECIALROLLS"] = "특별 주사위"
locales.koKR["ML_SELF"] = "내가 획득"
locales.koKR["ML_BANKER"] = "은행 보관 담당자"
locales.koKR["ML_DISENCHANTER"] = "마력 추출 담당자"
locales.koKR["ITEM_AWARDED"] = "%s에게 분배: %s"
locales.koKR["CANDIDATE_UNAVAILABLE"] = "해당 플레이어는 더 이상 전리품을 받을 수 없습니다."
locales.koKR["ITEM_UNAVAILABLE"] = "해당 아이템이 더 이상 전리품 창에 없습니다."
locales.koKR["ROLL_DISCARDED"] = "공격대 주사위 분배가 취소되었습니다. 수령인이 지정되지 않았습니다."

XLoot:Localize("Master", locales)
