--[=[ This addon provides options for all modules.
Options are preferrably defined as "BetterOptions" tables, which functionally resemble AceOptionsTables but are much more concise.

Start by defining your module options here in addon:OnEnable below other module options with the call addon:RegisterModuleBetterOptions("ModuleName", table), inside a if XLoot:GetModule(ModuleName, true) block.

The resulting BetterOptions -> AceOptionsTable is, just like passing a normal/partial AceOptionsTable, is "Finalized" (via Finalize(t)). This pass automatically inserts localizations based on key, handles .items -> .values, applies group {defaults = {k = v}} to group children, and implements requires*.

Please note that inline and non-inline groups do not mix well for AceConfigDialog.

Option localization entries should be added under Options/ModuleName namespace -]=] 

-- Create module
local addon, L = XLoot:NewModule("Options")

-- Global
_G.XLootOptions = addon

-- Locals
local print = print
local popup_panel -- Last panel to open profile reset popup

local function trigger(target, method, ...)
	local func = target[method]
	if type(func) == 'function' then
		func(target, ...)
	end
end

-------------------------------------------------------------------------------
-- Module init

function addon:OnEnable() -- Construct addon option tables here

	local option_metadata = {} -- Stores metadata for option entries outside of library-specific compiled option structure
	addon.option_metadata = option_metadata -- Until resulting AceOptionsTable can have .values upated, this is the only way to store a new .items table
	local module_index = {}

	-------------------------------------------------------------------------------
	-- General config methods

	-- Find module options and requested key from AceConfigDialog info table
	-- Also return meta table for option
	function path(info)
		local key = info[#info]
		local meta = option_metadata[info.appName][key]
		local db = module_index[info.appName].db.profile
		return meta.key and db[meta.key] or db, meta.subkey or key, meta
	end

	-- Generic option getter
	local function get(info)
		local db, k, meta = path(info)
		if info.option.type == "color" then
			return unpack(db[k])
		elseif info.option.type == "select" and meta.items then
			for i,v in ipairs(meta.items) do
				if db[k] == v[1] then
					return i
				end
			end
		else
			return db[k]
		end
	end

	-- Generic option setter
	local function set(info, v, v2, v3, v4)
		local db, k, meta = path(info)
		if info.option.type == "color" then
			db[k][1] = v
			db[k][2] = v2
			db[k][3] = v3
			db[k][4] = v4
		elseif info.option.type == "select" and meta.items then
			db[k] = meta.items[v][1]
		else
			db[k] = v
		end
	end

	-- Select value generator
	local function values_from_items(info)
		local db, k, meta = path(info)
		local values = meta.values
		wipe(values)
		for i,v in ipairs(meta.items) do
			values[i] = v[2]
		end
		return values
	end

	-- Sorted select getter
	local function sorted_get(map, info)
		local db, k = path(info)
		return map[db[k]]
	end

	-- Sorted select setter
	local function sorted_set(map, info, v)
		local db, k = path(info)
		db[k] = map[v]
	end

	-- Dependencies
	-- TODO: Recursive dependencies
	local function requires(info)
		local db, k, meta = path(info)
		return ((meta.requires and (not db[meta.requires]) or false)
				or (meta.requires_inverse and db[meta.requires_inverse] or false))
	end

	-------------------------------------------------------------------------------
	-- Streamlined options tables

	local BetterOptions = {}
	local table_remove = table.remove
	-- { "key", "type", [arg1[, ...]] [, key = value[, ...]] }
	-- Examples:
	-- { "key", "group", inline }
	-- { "key", "execute", func }
	-- { "key", "select", items }
	-- { "key", "color", hasAlpha }
	-- { "key", "range", min, max, step, softMin, softMax, bigStep }
	
	function BetterOptions:CompileToAceOptions(t)
		self:Iterate(t)
		return t
	end

	function BetterOptions:Iterate(set)
		for i,v in ipairs(set) do
			v.order = i
			local t, key = self:any(v)
			set[key] = t
			set[i] = nil
		end
		return set
	end

	function BetterOptions:any(t)
		-- Shift required elements
		local key = table_remove(t, 1)
		t.type = table_remove(t, 1)

		-- Handle specific option types
		if self[t.type] then
			self[t.type](self, t)
		end

		-- Cleanup
		for i,v in ipairs(t) do
			t[i] = nil
		end

		return t, key
	end

	function BetterOptions:group(t)
		t.args = t.args or t[1]
		t.inline = t.inline ~= nil and t.inline or (t[2] ~= nil and t[2] or true)

		self:Iterate(t.args)
	end

	function BetterOptions:select(t)
		t.items = t.items or t[1]
	end

	function BetterOptions:color(t)
		t.hasAlpha = t.hasAlpha or t[1]
	end

	function BetterOptions:range(t)
		t.min = t.max or t[1]
		t.max = t.max or t[2]
		t.step = t.step or t[3]
		t.softMin = t.softMin or t[4]
		t.softMax = t.softMax or t[5]
		t.bigStep = t.bigStep or t[6]
	end

	function BetterOptions:execute(t)
		t.func = t.func or t[1]
	end

	addon.BetterOptions = BetterOptions

	-------------------------------------------------------------------------------
	-- AceOptionsTable extension

	-- Flesh out AceOptionsTables for a given module
	-- Add features not directly supported
	function Finalize(module_name, key, opts)
		local meta_name = "XLoot"..module_name
		-- First call
		if not key then
			if not option_metadata[meta_name] then
				option_metadata[meta_name] = {}
			end
			for k,v in pairs(opts) do
				Finalize(module_name, k, v)
			end
		-- Recursion
		else
			local meta = {}
			-- Fill in localized name/description
			opts.name = opts.name or L[module_name][key] or key
			opts.desc = opts.desc or L[module_name][key.."_desc"]

			meta.key, meta.subkey = opts.key, opts.subkey
			opts.key, opts.subkey = nil, nil

			-- Dependencies
			if opts.requires or opts.requires_inverse then
				meta.requires, meta.requires_inverse = opts.requires, opts.requires_inverse
				opts.disabled = requires
				opts.requires, opts.requires_inverse = nil, nil
			end

			-- Sorted select
			-- TODO: Set metatable on option table to update meta.items?
			if opts.type == 'select' and opts.items then
				opts.values = values_from_items
				meta.values = {}
				meta.items = opts.items
				opts.items = nil
			end

			option_metadata[meta_name][key] = meta

			-- Traverse subgroup
			if opts.args then
				-- Apply subgroup defaults
				if opts.defaults then
					for argk, argv in pairs(opts.args) do
						for defk, defv in pairs(opts.defaults) do
							if argv[defk] == nil then
								argv[defk] = defv
							end
						end
					end
					opts.defaults = nil
				end
				-- Finalize subgroups
				for k,v in pairs(opts.args) do
					Finalize(module_name, k, v)
				end

			-- Default type "toggle"
			elseif not opts.type then
				opts.type = "toggle"
			end
		end
	end

	-------------------------------------------------------------------------------
	-- Module config registration

	self.configs = {} -- AceOptionTables for modules
	self.module_list = {} -- Maintains list of modules which need options generated

	-- Compose a module's option table
	function addon:RegisterModuleOptions(module_name, args)
		-- Initialize metadata
		option_metadata[module_name] = {}
		-- Compile nonstandard options
		Finalize(module_name, nil, args)
		self.configs[module_name] = {
			get = get,
			set = set,
			name = L[module_name].panel_title,
			desc = L[module_name].panel_desc,
			type = "group",
			args = args
		}
		module_index["XLoot"..module_name] = XLoot:GetModule(module_name)
		table.insert(self.module_list, module_name)
	end

	function addon:RegisterModuleBetterOptions(module_name, t)
		self:RegisterModuleOptions(module_name, BetterOptions:CompileToAceOptions(t))
	end

	-------------------------------------------------------------------------------
	-- Generic select values

	local item_qualities = {}
	do
		for k, v in ipairs(ITEM_QUALITY_COLORS) do
			local hex = select(4, GetItemQualityColor(k))
			item_qualities[k] = { k, ("|c%s%s"):format(hex, _G["ITEM_QUALITY"..tostring(k).."_DESC"]) }
		end
	end 

	local directions = {
		{ "up", L.up },
		{ "down", L.down }
	}

	-------------------------------------------------------------------------------
	-- Module configs

	-- XLoot Core
	local skins = {}
	addon:RegisterModuleBetterOptions("Core", {
		{ "skin", "select", values = function()
			wipe(skins)
			for k,v in pairs(XLoot.Skin.skins) do
				skins[k] = v.name
			end
			return skins
		end},
		{ "skin_anchors", "toggle" }
	})

	-- XLoot Frame
	if XLoot:GetModule("Frame", true) then
		local when_group = {
			{ "never", L.when_never },
			{ "solo", L.when_solo },
			{ "always", L.when_always },
			{ "grouped", L.when_grouped }
		}

 		addon:RegisterModuleBetterOptions("Frame", {
			{ "frame_options", "group", {
				{ "frame_width_automatic", "toggle", width = "double" },
				{ "frame_width", "range", 75, 300, 5, requires_inverse = "frame_width_automatic" },
				{ "frame_scale", "range", 0.1, 2.0, 0.1 },
				{ "frame_alpha", "range", 0.1, 1.0, 0.1 },
				{ "loot_alpha", "range", 0.1, 1.0, 0.1 },
				{ "frame_snap", "toggle" },
				{ "frame_snap_offset_x", "range", -2000, 2000, 1, -250, 250, 10, requires = "frame_snap" },
				{ "frame_snap_offset_y", "range", -2000, 2000, 1, -250, 250, 10, requires = "frame_snap" },
				{ "frame_draggable", "toggle" },
			}},
			{ "slot_options", "group", {
				{ "loot_texts_info", "toggle", width = "double" },
				{ "loot_texts_bind", "toggle" },
				{ "loot_highlight", "toggle", width = "double", },
				{ "loot_collapse", "toggle" },
				{ "font_size_loot", "range", 4, 26, 1 },
				{ "font_size_info", "range", 4, 26, 1 }
			}},
			{ "link_button", "group", {
				{ "linkall_show", "select", when_group },
				{ "linkall_threshold", "select", item_qualities },
				{ "linkall_channel", "select", {
					{ "SAY", CHAT_MSG_SAY },
					{ "PARTY", CHAT_MSG_PARTY },
					{ "GUILD", CHAT_MSG_GUILD },
					{ "OFFICER", CHAT_MSG_OFFICER },
					{ "RAID", CHAT_MSG_RAID },
					{ "RAID_WARNING", RAID_WARNING }
				}}
			}},
			{ "autolooting", "group", {
				{ "autoloot_coin", "select", when_group },
				{ "autoloot_quest", "select", when_group }
			}},
			{ "colors", "group", {
				{ "quality_color_frame", "toggle", width = "full" },
				{ "quality_color_slot", "toggle", width = "full" },
				{ "frame_color_border", "color", width = "double", requires_inverse = "quality_color_frame" },
				{ "loot_color_border", "color", requires_inverse = "quality_color_slot" },
				{ "frame_color_backdrop", "color", true, width = "double" },
				{ "loot_color_backdrop", "color", true },
				{ "frame_color_gradient", "color", true, width = "double" },
				{ "loot_color_gradient", "color", true },
				{ "loot_color_info", "color", width = "full", requires = "loot_texts_info" }
			}}
		})
	end

	-- XLoot Group
	if XLoot:GetModule("Group", true) then
		addon:RegisterModuleBetterOptions("Group", {
			{ "anchors", "group", {
				{ "anchor_toggle", "execute", function() XLootGroup:ToggleAnchors() end },
				{ "reload_ui", "execute", ReloadUI },
			}},
			{ "rolls", "group", {
				{ "roll_direction", "select", directions, name = L.growth_direction, key = "roll_anchor", subkey = "direction" },
				{ "text_outline", "toggle" },
				{ "text_time", "toggle" },
				{ "roll_scale", "range", 0.1, 2.0, 0.1, name = L.scale, key = "roll_anchor", subkey = "scale" },
				{ "roll_width", "range", 150, 700, 1, 150, 400, 10, name = L.width },
				{ "roll_button_size", "range", 16, 48, 1 },
				{ "expiration", "header" },
				{ "expire_won", "range", 5, 30, 1 },
				{ "expire_lost", "range", 5, 30, 1 },
			}},
			{ "bonus_roll", "group", {
				{ "bonus_skin", "toggle" },
			}},
			{ "roll_tracking", "group", {
				{ "track_all", "toggle", width = "double" },
				{ "track_player_roll", "toggle", requires_inverse = "track_all" },
				{ "track_by_threshold", "toggle", requires_inverse = "track_all", width = "double" },
				{ "track_threshold", "select", item_qualities, requires = "track_by_threshold", name = L.minimum_quality },
			}},
			{ "alerts", "group", {
				{ "alert_direction", "select", directions, key = "alert_anchor", subkey = "direction", name = L.growth_direction },
				{ "alert_skin", "toggle", width = "double" },
				{ "alert_scale", "range", 0.1, 2.0, 0.1, name = L.scale },
				{ "alert_offset", "range", 0.1, 2.0, 0.1 },
				{ "alert_alpha", "range", 0.1, 1.0, 0.1, name = L.alpha },
			}},
		})
	end

	-- XLoot Master
	if XLoot:GetModule("Master", true) then
		-- Item quality dropdown generator
		local item_qualities = {}
		do
			for i, v in ipairs(UnitPopupMenus["LOOT_THRESHOLD"]) do -- we only care for the qualities available as ML filters
				local quality = tonumber(strmatch(v,"%d+"))
				if quality then
					local hex = select(4, GetItemQualityColor(quality))
					item_qualities[i] = { quality, ('|c%s%s'):format(hex, _G[v]) }
				end
			end
		end
		local channels = {
				{ 'AUTO', L.desc_channel_auto },
				{ 'SAY', CHAT_MSG_SAY },
				{ 'PARTY', CHAT_MSG_PARTY },
				{ 'RAID', CHAT_MSG_RAID },
				{ 'RAID_WARNING', RAID_WARNING },
				{ 'OFFICER', CHAT_MSG_OFFICER },
				{ 'NONE', NONE },
		}
		addon:RegisterModuleBetterOptions("Master", {
			{ "specialrecipients", "group", {
				{ "menu_disenchant", "toggle" },
				{ "menu_bank", "toggle" },
				{ "menu_self", "toggle" },
			}},
			{ "raidroll", "group", {
				{ "menu_roll", "toggle" },
			}},
			{ "awardannounce", "group", {
				{ "award_qualitythreshold", "select", item_qualities },
				{ "award_channel", "select", channels },
				{ "award_guildannounce", "toggle" },
			}},
		})
	end
	
	-- Generate reset staticpopup
	if not StaticPopupDialogs['XLOOT_RESETPROFILE'] then
		StaticPopupDialogs['XLOOT_RESETPROFILE'] = {
			preferredIndex = 3,
			text = L.confirm_reset_profile,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function() addon:ResetProfile() end,
			exclusive = true,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	end
end

function addon:OnInitialize()
	
end

-------------------------------------------------------------------------------
-- Panel methods

local function PanelDefault(self)
	StaticPopup_Show("XLOOT_RESETPROFILE")
	trigger(self.owner, "ProfileChanged")
	popup_panel = self
end

local function PanelOkay(self)
	trigger(self.owner, "ConfigSave")
end

local function PanelCancel(self)
	trigger(self.owner, "ConfigCancel")
end

function addon:ResetProfile()
	XLoot.db:ResetProfile()
	LibStub("AceConfigRegistry-3.0"):NotifyChange(popup_panel.key)
end

local init
function addon:OpenPanel(module)
	-- One-time init
	if not init then
		init = true
		-- Create module subpanels
		for i,this_name in ipairs(self.module_list) do
			local module, key = XLoot:GetModule(this_name), "XLoot"..this_name
			LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(key, self.configs[this_name])
			local panel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(key, L[this_name].panel_title or "XLoot "..this_name, "XLoot")
			-- Supply panel methods
			panel.default = PanelDefault
			panel.okay = PanelOkay
			panel.cancel = PanelCancel
			panel.owner = module
			panel.key = key
			module.option_panel = panel
		end
		-- Create profile panel
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XLootProfile", LibStub("AceDBOptions-3.0"):GetOptionsTable(XLoot.db))
		XLoot.profile_panel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XLootProfile", L.profile, "XLoot")
		XLoot.profile_panel.default = PanelDefault
	end
	-- Open panel
	InterfaceOptionsFrame_OpenToCategory(module.option_panel)
end

--@do-not-package@
-- function print(...)
-- 	_G.UIParentLoadAddOn("Blizzard_DebugTools");
-- 	_G.DevTools_Dump((...));
-- 	_G.DevTools_Dump(select(2, ...));
-- end
local AC = LibStub('AceConsole-2.0', true)

if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
