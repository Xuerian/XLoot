﻿-- See: http://wow.curseforge.com/addons/xloot/localization/ to create or fix translations
local locales = {
	enUS = {
		Core = {
			panel_title = "Global options",
			details = "Skin is applied to all XLoot modules. Most other settings currently require a /reload to be applied. Please open a ticket with any issues.\nTo turn off a single module, disable it like any normal addon.",
			skin = "Skin",
			skin_desc = "Select skin to use. Includes Masque skins",
			skin_anchors = "Apply to anchors",
			skin_anchors_desc = "Apply skin to anchors that XLoot uses",
			module_header = "Module options",
		},
		Frame = {
			panel_title = "Loot Frame",
			panel_desc = "Provides a adjustable loot frame",
			-- Group labels
			frame_options = "Frame settings",
			slot_options = "Loot slots",
			link_button = "Link all button",
			autolooting = "Auto-looting",
			colors = "Colors",

			-- Option labels
			autoloot_currency = "Auto loot currency",
			autoloot_currency_desc = "When to automatically loot currency",
			autoloot_quest = "Auto loot quest items",
			autoloot_quest_desc = "When to automatically loot quest items",
			autoloot_tradegoods = "Auto loot trade goods",
			autoloot_tradegoods_desc = "When to automatically loot any item of Trade Goods type",
			autoloot_all = "Auto loot everything",
			autoloot_list = "Auto loot listed items",
			autoloot_list_desc = "When to automatically loot listed items",
			autoloot_item_list = "Items to loot",
			-- frame_scale = "Frame scale",
			-- frame_alpha = "Frame alpha",
			frame_color_border = "Frame border color",
			frame_color_backdrop = "Frame backdrop color",
			frame_color_gradient = "Frame gradient color",
			frame_width_automatic = "Automatically expand frame",
			frame_width = "Frame width",
			old_close_button = "Use old close button",
			loot_highlight = "Highlight slots on mouseover",
			-- loot_alpha = "Slot alpha",
			loot_color_border = "Loot border color",
			loot_color_backdrop = "Loot backdrop color",
			loot_color_gradient = "Loot gradient color",
			loot_color_info = "Information text color",
			loot_collapse = "Collapse looted slots",
			loot_icon_size = "Loot icon size",
			loot_row_height = "Loot row height",
			quality_color_frame = "Color frame border by top quality",
			quality_color_slot = "Color loot border by quality",
			loot_texts_info = "Show detailed information",
			loot_texts_bind = "Show loot bind type",
			loot_texts_lock = "Show locked status",
			loot_buttons_auto = "Autoloot shortcut",
			loot_buttons_auto_desc = "A button to add any item to your auto-looting list (See below)\nOnly shown when the item would be autolooted",
			font_size_info = "Loot information",
			font_size_bottombuttons = "Linkall/Close",
			frame_snap = "Snap frame to mouse",
			frame_snap_offset_x = "Horizontal snap offset",
			frame_snap_offset_y = "Vertical snap offset",
			frame_grow_upwards = "Expand frame upwards",
			frame_draggable = "Loot frame draggable",
			linkall_threshold = "Minimum chat link quality",
			linkall_channel = "Default chat link channel",
			linkall_channel_secondary = "Secondary chat link channel",
			linkall_show = "Link button visibility",
			linkall_first_only = "Only link top item",

			autolooting_text = "XLoot's autolooting features act separately from the default UI. As such, if both are enabled, you may recieve warnings like 'that object is busy'. They are safe to ignore, but can be resolved by picking one autoloot method to use exclusively.",

			autolooting_list = "To automatically loot specific items, list them below.\n  Example: Linen Cloth,Ashbringer,Copper Ore",

			autolooting_details = "XLoot will choose the highest setting when deciding to loot a slot. This allows, for example, auto looting everything while solo yet only quest items and money while in a group.",

			show_slot_errors = "Looting errors in chat",
			show_slot_errors_details = "Print a chat message when a loot item cannot be shown for some reason. Most of these should be able to be safely ignored.",
		},
		Group = {
			panel_title = "Group Loot",
			-- Group labels
			anchors = "Anchors",
			rolls = "Roll frames",
			other_frames = "Other frames",
			roll_tracking = "What rolls to show",
			alerts = "Loot alerts",
			extra_info = "Details",

			-- Header labels
			expiration = "Expiration (in seconds)",

			-- Option labels
			text_outline = "Outline text",
			text_outline_desc = "Draws a dark outline around text on roll frames",
			text_time = "Show time remaining",
			text_time_desc = "Displays seconds remaining to roll over item icon",
			text_ilvl = "Show item level",
			role_icon = "Show role icons",
			win_icon = "Show winning type icon",
			show_decided = "Show decided",
			show_undecided = "List waiting players",
			show_undecided_desc = "List players who have not chosen how to roll",
			hook_alert = "Modify loot alerts",
			hook_alert_desc = "('You won..' popups)\nAttach loot alerts to a movable anchor.\n\nDisabling this can improve compatibility with other loot addons. \n\n(Requires ReloadUI)",
			alert_skin = "Skin loot alert frames",
			alert_offset = "Vertical spacing",
			alert_background = "Show background",
			alert_icon_frame = "Show icon frame",
			hook_bonus = "Modify bonus rolls",
			hook_bonus_desc = "Attach bonus loot rolls to a movable anchor.\n\nDisabling this can improve compatibility with other loot addons. \n\n(Requires ReloadUI)",
			bonus_skin = "Skin bonus roll frame",
			roll_width = "Roll frame width",
			roll_button_size = "Roll button size",
			roll_anchor_visible = "Roll anchor visible",
			alert_anchor_visible = "Loot alerts anchor visible",
			alert_anchor_visible_desc = "Refers to 'You won..' popups",
			track_all = "Track all rolls",
			track_player_roll = "Track items you roll on",
			track_by_threshold = "Track items by minimum quality",
			expire_won = "Won rolls",
			expire_lost = "Lost/Passed rolls",
			preview_show = "Show Preview",
			equip_prefix = "Show equippable prefix",
			equip_prefix_desc = "Prefixes item names to indicate if a item can be equipped or is a upgrade. (Upgrade prefix requires the Pawn addon)",
			prefix_equippable = "Equippable prefix",
			prefix_upgrade = "Upgrade prefix",

			hook_warning_text = "Hooking the loot alert and bonus roll frames has rarely been reported to cause issues such as not seeing bonus rolls.\n\nBy enabling these options you acknowledge that you understand and accept that risk.\n",
		},
		Monitor = {
			panel_title = "Loot Monitor",
			-- Group labels
			testing = "Testing",
			anchor = "Anchor",
			thresholds = "Quality thresholds",
			fading = "Row fade times (in seconds)",
			details = "Details",
			-- Option labels
			test_settings = "Click to test settings",
			visible = "Anchor visible",
			show_crafted = "Crafted",
			show_totals = "Show total items in inventory",
			totals_delay = "Totals delay",
			totals_delay_desc = "Time to wait before asking the game how many items you have, as the item events do not reliably match up to inventory counts",
			use_altoholic = "Include bank (Altoholic)",
			show_ilvl = "Show item level",
			font_size_ilvl = "Item level",
			name_width = "Player name width",
			gradients = "Gradients",
		},
		Master = {
			panel_title = "Loot Master",
			-- Group labels
			specialrecipients = "Special Recipients Menu",
			raidroll = "Special Rolls Menu",
			awardannounce = "Announce Item Distribution",
			-- Option labels
			confirm_qualitythreshold = "Minimum confirm quality",
			menu_roll = "Show raid roll",
			menu_disenchant = "Show disenchanter",
 			menu_disenchanters = "Disenchant character names",
			menu_bank = "Show banker",
			menu_bankers = "Banker character names",
			menu_self = "Show self",
			award_qualitythreshold = "Minimum announce quality",
			award_channel = "Default chat announce channel",
			award_channel_secondary = "Secondary chat announce channel",
			award_guildannounce = "Echo in guild chat",
			award_special = "Announce special recipients",
		},
		font = "Font",
		font_sizes = "Sizes",
		font_size_loot = "Loot",
		font_size_quantity = "Quantity",
		font_flag = "Flag",
		desc_channel_auto = "Highest available",
		growth_direction = "Growth direction",
		alignment = "Alignment",
		scale = "Scale",
		width = "Width",
		alpha = "Opacity",
		spacing = "Spacing",
		offset = "Offset",
		visible = "Visible",
		padding = "Padding",
		items_others = "Others' items",
		items_own = "Own items",
		up = "Up",
		down = "Down",
		left = "Left",
		right = "Right",
		top = "Top",
		bottom = "Bottom",
		minimum_quality = "Minimum quality",
		when_never = "Never",
		when_solo = "Solo",
		when_always = "Always",
		when_auto = "Automatic",
		when_group = "In groups",
		when_party = "In parties",
		when_raid = "In raids",
		confirm_reset_profile = "This will reset all options for this profile. Are you sure?",
		profile = "Profile",
		message_reloadui_warning = "|c2244dd22%s|r: Changing |c2244dd22%s|r requires you to reload your UI before continuing to play: |c2244dd22/reload ui|r",
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

-- Manually express subtables because apparently I'm the only one who thought to use namespaces the simple way

--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Core")@

--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Frame")@

--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Group")@

--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Monitor")@

--@localization(locale="ptBR", format="lua_additive_table", table-name="locales.ptBR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="frFR", format="lua_additive_table", table-name="locales.frFR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="deDE", format="lua_additive_table", table-name="locales.deDE", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="koKR", format="lua_additive_table", table-name="locales.koKR", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="esMX", format="lua_additive_table", table-name="locales.esMX", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="ruRU", format="lua_additive_table", table-name="locales.ruRU", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="zhCN", format="lua_additive_table", table-name="locales.zhCN", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="esES", format="lua_additive_table", table-name="locales.esES", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@
--@localization(locale="zhTW", format="lua_additive_table", table-name="locales.zhTW", handle-subnamespaces="subtable", handle-unlocalized="ignore", namespace="Master")@

XLoot:Localize("Options", locales)
