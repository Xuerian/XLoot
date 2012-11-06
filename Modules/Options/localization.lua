-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		Core = {
			panel_title = "Global options",
			skin = "Skin",
			skin_desc = "Select skin to apply to all modules. Includes Masque skins"
		},
		Frame = {
			panel_title = "Loot Frame",
			-- Group labels
			frame_options = "Frame settings",
			slot_options = "Loot slots",
			link_button = "Link all button",
			autolooting = "Auto-looting",
			colors = "Colors",

			-- Option labels
			autoloot_coin = "Auto loot coin",
			autoloot_coin_desc = "When to automatically loot coin",
			autoloot_quest = "Auto loot quest items",
			autoloot_quest_desc = "When to automatically loot quest items",
			frame_scale = "Frame scale",
			frame_alpha = "Frame alpha",
			frame_color_border = "Frame border color",
			frame_color_backdrop = "Frame backdrop color",
			frame_color_gradient = "Frame gradient color",
			frame_width_automatic = "Automatically expand frame",
			frame_width = "Frame width",
			loot_highlight = "Highlight slots on mouseover",
			loot_alpha = "Slot alpha",
			loot_color_border = "Loot border color",
			loot_color_backdrop = "Loot backdrop color",
			loot_color_gradient = "Loot gradient color",
			loot_color_info = "Information font color",
			loot_collapse = "Collapse looted slots",
			quality_color_frame = "Color frame border by top quality",
			quality_color_slot = "Color loot border by quality",
			loot_texts_info = "Show detailed information",
			loot_texts_bind = "Show loot bind type",
			font_size_loot = "Loot font size",
			font_size_info = "Information font size",
			frame_snap = "Snap frame to mouse",
			frame_snap_offset_x = "Horizontal snap offset",
			frame_snap_offset_y = "Vertical snap offset",
			frame_draggable = "Loot frame draggable",
			linkall_threshold = "Minimum chat link quality",
			linkall_channel = "Default chat link channel",
			linkall_show = "Link button visibility",
		},
		when_never = "Never",
		when_solo = "Solo",
		when_always = "Always",
		when_auto = "Automatic",
		confirm_reset_profile = "This will reset all XLoot options for this profile. Are you sure?",
		profile = "Profile"
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
--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Options")@

XLoot:Localize("Options", locales)
