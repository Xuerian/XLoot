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
	self["L_"..name] = CompileLocales(locales)
end

local locales = {
	enUS = {
		skin_svelte = "XLoot: Svelte",
		skin_legacy = "XLoot: Legacy",
		skin_smooth = "XLoot: Smooth",
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
-- See: http://wow.curseforge.com/addons/xloot-1-0/localization/ to create or fix translations
--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-unlocalized="ignore")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-unlocalized="ignore")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-unlocalized="ignore")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-unlocalized="ignore")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-unlocalized="ignore")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-unlocalized="ignore")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-unlocalized="ignore")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-unlocalized="ignore")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-unlocalized="ignore")@


XLoot.L = CompileLocales(locales)
