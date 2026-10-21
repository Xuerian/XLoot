-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		anchor = "Loot Toast",
		received = "You received",
		legendary = "Legendary!",
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

locales.ruRU["anchor"] = "Уведомления о добыче"
locales.ruRU["received"] = "Вы получили"
locales.ruRU["legendary"] = "Легендарный предмет!"

XLoot:Localize("Toast", locales)
