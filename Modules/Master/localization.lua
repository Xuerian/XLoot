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
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
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
locales.ruRU["BINDING_BANKER"] = "Назначить банкира"
locales.ruRU["BINDING_DISENCHANTER"] = "Назначить распылителя"
locales.ruRU["ITEM_AWARDED"] = "%s получает: %s"
locales.ruRU["CANDIDATE_UNAVAILABLE"] = "Этот игрок больше не может получить добычу."
locales.ruRU["ITEM_UNAVAILABLE"] = "Этого предмета больше нет в окне добычи."
locales.ruRU["ROLL_DISCARDED"] = "Рейдовый бросок отменён — победитель не назначен."

XLoot:Localize("Master", locales)
