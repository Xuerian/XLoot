local addon = XLootOptions
local L = XLoot.L_Options
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local Encoding = C_EncodingUtil

local FORMAT = 1
local GAME = WOW_PROJECT_ID
local RETAIL = XLoot.IS_RETAIL_ENGINE
local GAME_NAMES = { [1] = "game_retail", [2] = "game_classic_era", [5] = "game_tbc", [18] = "game_forever", [19] = "game_mop" }

local POSITIONS = {
	Frame = { x = "frame_position_x", y = "frame_position_y", scale = "frame_scale" },
	Group = { sub = "roll_anchor", x = "x", y = "y", scale = "scale" },
	Monitor = { sub = "anchor", x = "x", y = "y", scale = "scale" },
	Toast = { sub = "anchor", x = "x", y = "y", scale = "scale" },
}
local GAME_ONLY = { Group = { auto_roll_rules = true } }
-- Options.lua hides these on one engine, so the other engine's values for them are stale.
local ENGINE_ONLY = {
	Core = { tooltip_sell = true },
	Group = { roll_status = true, track_all = true, track_player_roll = true, track_by_threshold = true, track_threshold = true },
}
-- LibDBIcon saves fields the defaults lack, so its table is checked against the fields it uses.
local SHAPES = { minimap = { hide = true, minimapPos = 0, lock = false } }
local NEEDS_RELOAD = { Monitor = { gradients = true } }
-- The range of the scale sliders in Options.lua.
local SCALE_MIN, SCALE_MAX = 0.1, 2
local MAX_ITEM_ID = 2147483647

local function Print(text)
	print("|c2244dd22XLoot|r "..text)
end

local function Warn(text)
	return "|cffff4040"..text.."|r"
end

local function GameName(id)
	return GAME_NAMES[id] and L[GAME_NAMES[id]] or L.game_unknown
end

local function Databases()
	local list = { Core = XLoot.db }
	for name, module in pairs(XLoot.modules) do
		if module.db then
			list[name] = module.db
		end
	end
	return list
end

local function ProfileDefaults(db)
	return db.defaults and db.defaults.profile or {}
end

local function Container(profile, spec)
	if not spec.sub then
		return profile
	end
	local t = profile[spec.sub]
	return type(t) == "table" and t or nil
end

local function Count(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

local function Copy(t)
	local out = {}
	if type(t) == "table" then
		for k, v in pairs(t) do
			out[k] = v
		end
	end
	return out
end

local function Finite(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function Whole(n)
	return Finite(n) and n % 1 == 0
end

local function Shorten(text, limit)
	local out = ""
	for char in text:gmatch("[%z\1-\127\192-\255][\128-\191]*") do
		if #out + #char > limit then
			break
		end
		out = out..char
	end
	return out
end

local function Diff(value, default)
	local kind = type(value)
	if kind == "table" then
		local out
		for k, v in pairs(value) do
			local key_kind = type(k)
			if key_kind == "string" or key_kind == "number" then
				local sub_default
				if type(default) == "table" then
					sub_default = default[k]
				end
				local changed = Diff(v, sub_default)
				if changed ~= nil then
					out = out or {}
					out[k] = changed
				end
			end
		end
		return out
	elseif (kind == "string" or kind == "number" or kind == "boolean") and value ~= default then
		return value
	end
end

local function BuildExport()
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	local settings, positions, modules, changes = {}, {}, {}, 0
	for name, db in pairs(Databases()) do
		modules[name] = true
		local profile, defaults = db.profile, ProfileDefaults(db)
		local changed = {}
		for k, v in pairs(profile) do
			if defaults[k] ~= nil then
				changed[k] = Diff(v, defaults[k])
			end
		end
		local spec = POSITIONS[name]
		local moved = spec and Container(changed, spec)
		if moved then
			local live = Container(profile, spec)
			local x, y, scale = tonumber(live[spec.x]), tonumber(live[spec.y]), tonumber(live[spec.scale]) or 1
			if x and y and (moved[spec.x] ~= nil or moved[spec.y] ~= nil) then
				positions[name] = { x * scale, y * scale }
				changes = changes + 1
			end
			moved[spec.x], moved[spec.y] = nil, nil
			if spec.sub and next(moved) == nil then
				changed[spec.sub] = nil
			end
		end
		if next(changed) then
			settings[name] = changed
			changes = changes + Count(changed)
		end
	end
	local payload = {
		game = GAME, retail = RETAIL, profile = XLoot.db:GetCurrentProfile(), screen = { width, height },
		modules = modules, settings = settings, positions = positions,
	}
	local ok, encoded = pcall(function()
		return Encoding.EncodeBase64(Encoding.CompressString(Encoding.SerializeCBOR(payload)))
	end)
	if ok and type(encoded) == "string" then
		return ("XLoot%d:%s"):format(FORMAT, encoded), changes
	end
end

local function Decode(text)
	text = (text or ""):gsub("%s", "")
	if text == "" then
		return
	end
	local version, body = text:match("^XLoot(%d+):(.+)$")
	if not version then
		return nil, L.import_invalid
	elseif tonumber(version) > FORMAT then
		return nil, L.import_newer
	end
	local ok, payload = pcall(function()
		local packed = Encoding.DecodeBase64(body)
		local raw = packed and Encoding.DecompressString(packed)
		return raw and Encoding.DeserializeCBOR(raw)
	end)
	if not ok or type(payload) ~= "table" or type(payload.settings) ~= "table" then
		return nil, L.import_invalid
	end
	return payload
end

local function ValidNumber(n, key)
	if not Finite(n) then
		return false
	elseif type(key) ~= "string" then
		return true
	elseif key:find("scale$") then
		return n >= SCALE_MIN and n <= SCALE_MAX
	end
	return n > 0 or not key:find("size")
end

local function Clean(value, default, report, key)
	if type(default) == "table" then
		if type(value) ~= "table" then
			report.dropped = report.dropped + 1
			return nil
		end
		local out
		for k, v in pairs(value) do
			local cleaned = Clean(v, default[k], report, k)
			if cleaned ~= nil then
				out = out or {}
				out[k] = cleaned
			end
		end
		return out
	elseif default ~= nil and type(value) == type(default) and (type(value) ~= "number" or ValidNumber(value, key)) then
		return value
	end
	report.dropped = report.dropped + 1
end

local function CleanRules(value, report)
	if type(value) ~= "table" then
		report.dropped = report.dropped + 1
		return nil
	end
	local out
	for item, roll in pairs(value) do
		if Whole(item) and item > 0 and item <= MAX_ITEM_ID and Whole(roll) and roll >= 0 then
			out = out or {}
			out[item] = roll
		else
			report.dropped = report.dropped + 1
		end
	end
	return out
end

local function Unspoken(payload)
	local keys = {}
	local function add(list)
		for name, set in pairs(list) do
			keys[name] = keys[name] or {}
			for key in pairs(set) do
				keys[name][key] = true
			end
		end
	end
	if payload.game ~= GAME then
		add(GAME_ONLY)
	end
	if payload.retail ~= RETAIL then
		add(ENGINE_ONLY)
	end
	return keys
end

-- Keep the distance to a nearby edge and rescale the middle, so frames against an edge stay there and keep their order.
local function Refit(pos, from, to)
	if not (Finite(pos) and Finite(from) and from > 0) or pos < -0.01 * from or pos > 1.01 * from then
		return nil
	end
	local margin = math.min(from, to) / 3
	local out
	if pos < margin then
		out = pos
	elseif pos > from - margin then
		out = to - (from - pos)
	else
		out = margin + (pos - margin) * (to - 2 * margin) / (from - 2 * margin)
	end
	return math.min(math.max(out, 0), to)
end

local function Prepare(payload)
	local report = { dropped = 0, rules = 0, offscreen = 0, missing = {} }
	local plan, places, unspoken = {}, {}, Unspoken(payload)
	local dbs = Databases()
	for name, values in pairs(payload.settings) do
		local db = dbs[name]
		if not db then
			if type(name) == "string" then
				report.missing[name] = true
			end
		elseif type(values) == "table" then
			local defaults, skip, rules, out = ProfileDefaults(db), unspoken[name] or {}, GAME_ONLY[name] or {}, {}
			for k, v in pairs(values) do
				local default = defaults[k]
				if skip[k] and rules[k] then
					report.rules = report.rules + (type(v) == "table" and Count(v) or 0)
				elseif rules[k] then
					out[k] = CleanRules(v, report)
				elseif not skip[k] then
					out[k] = Clean(v, type(default) == "table" and SHAPES[k] or default, report, k)
				end
			end
			local spec = POSITIONS[name]
			local held = spec and Container(out, spec)
			if held then
				held[spec.x], held[spec.y] = nil, nil
			end
			plan[name] = out
		end
	end
	local screen = type(payload.screen) == "table" and payload.screen or {}
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	if type(payload.positions) == "table" then
		for name, place in pairs(payload.positions) do
			if not dbs[name] then
				if type(name) == "string" then
					report.missing[name] = true
				end
			elseif POSITIONS[name] and type(place) == "table" then
				local x, y = Refit(place[1], screen[1], width), Refit(place[2], screen[2], height)
				if x and y then
					places[name] = { x, y }
				else
					report.offscreen = report.offscreen + 1
				end
			end
		end
	end
	return plan, places, report, unspoken
end

-- Swap in fresh tables rather than editing in place: a stack anchor rescales x and y when its own table's scale changes (UpdateSVData in stacks.lua).
local function Merge(dest, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			local t = Copy(dest[k])
			Merge(t, v)
			dest[k] = t
		else
			dest[k] = v
		end
	end
end

local function Apply(plan, places)
	local dbs = Databases()
	local spots = {}
	for name, spec in pairs(POSITIONS) do
		local live = dbs[name] and Container(dbs[name].profile, spec)
		if live and (plan[name] or places[name]) then
			local x, y, scale = tonumber(live[spec.x]), tonumber(live[spec.y]), tonumber(live[spec.scale]) or 1
			-- Stack anchors hold their spot when the scale changes but the loot frame moves with it, so only anchors keep theirs.
			spots[name] = places[name] or (spec.sub and x and y and { x * scale, y * scale }) or nil
		end
	end
	for name, values in pairs(plan) do
		Merge(dbs[name].profile, values)
	end
	for name, spot in pairs(spots) do
		local spec, profile = POSITIONS[name], dbs[name].profile
		local target = profile
		if spec.sub then
			target = Copy(profile[spec.sub])
			profile[spec.sub] = target
		end
		local scale = tonumber(target[spec.scale])
		if not scale or scale <= 0 then
			scale = 1
		end
		target[spec.x] = spot[1] / scale
		target[spec.y] = spot[2] / scale
	end
end

local function ReloadState()
	local dbs, state = Databases(), {}
	for name, keys in pairs(NEEDS_RELOAD) do
		for key in pairs(keys) do
			state[#state + 1] = tostring(dbs[name] and dbs[name].profile[key])
		end
	end
	return table.concat(state, ",")
end

local function Finish(report, profile_name, reload_state)
	XLoot:ApplyOptions(true)
	AceConfigRegistry:NotifyChange("XLoot")
	AceConfigRegistry:NotifyChange("XLootProfile")
	Print(L.import_done:format(profile_name))
	local missing = {}
	for name in pairs(report.missing) do
		local titles = L[name]
		missing[#missing + 1] = type(titles) == "table" and titles.panel_title or name
	end
	if #missing > 0 then
		table.sort(missing)
		Print(L.import_missing:format(table.concat(missing, ", ")))
	end
	if report.dropped > 0 then
		Print(L.import_dropped:format(report.dropped))
	end
	if report.rules > 0 then
		Print(L.import_rules_skipped:format(report.rules))
	end
	if report.offscreen > 0 then
		Print(L.import_offscreen:format(report.offscreen))
	end
	if ReloadState() ~= reload_state then
		Print(L.import_reload)
	end
end

local function ImportAsNew(payload, name)
	local plan, places, report = Prepare(payload)
	local reload_state = ReloadState()
	XLoot.db:SetProfile(name)
	Apply(plan, places)
	Finish(report, name, reload_state)
end

local function ImportReplace(payload)
	local plan, places, report, unspoken = Prepare(payload)
	local reload_state = ReloadState()
	local covered = type(payload.modules) == "table" and payload.modules
	for name, db in pairs(Databases()) do
		if name == "Core" or not covered or covered[name] then
			local kept = {}
			for key in pairs(unspoken[name] or {}) do
				kept[key] = db.profile[key]
			end
			db:ResetProfile(true, true)
			for key, value in pairs(kept) do
				db.profile[key] = value
			end
		end
	end
	Apply(plan, places)
	Finish(report, XLoot.db:GetCurrentProfile(), reload_state)
end

local function ProfileExists(name)
	for _, existing in ipairs(XLoot.db:GetProfiles()) do
		if existing == name then
			return true
		end
	end
end

local function UniqueName(base)
	local name, n = base, 2
	while ProfileExists(name) do
		name, n = ("%s %d"):format(base, n), n + 1
	end
	return name
end

local function NewWindow(title, global_name, height)
	local window = AceGUI:Create("Frame")
	window:SetTitle(title)
	window:SetLayout("Flow")
	window:SetWidth(560)
	window:SetHeight(height)
	window:EnableResize(false)
	_G[global_name] = window.frame
	table.insert(UISpecialFrames, global_name)
	return window
end

local function NewLabel(window, relative_width)
	local label = AceGUI:Create("Label")
	label:SetFontObject(GameFontHighlight)
	if relative_width then
		label:SetRelativeWidth(relative_width)
	else
		label:SetFullWidth(true)
	end
	window:AddChild(label)
	return label
end

local function NewButton(window, text, on_click)
	local button = AceGUI:Create("Button")
	button:SetText(text)
	button:SetRelativeWidth(0.5)
	button:SetCallback("OnClick", on_click)
	window:AddChild(button)
	return button
end

local export_window, export_info, export_box, export_text

function addon.ShowExport()
	if not export_window then
		export_window = NewWindow(L.export_title, "XLootExportWindow", 340)
		export_info = NewLabel(export_window)
		export_box = AceGUI:Create("MultiLineEditBox")
		export_box:SetLabel("")
		export_box:SetNumLines(12)
		export_box:DisableButton(true)
		export_box:SetFullWidth(true)
		export_box:SetCallback("OnTextChanged", function(box)
			box:SetText(export_text)
			box:HighlightText()
		end)
		export_box:SetCallback("OnEditFocusGained", function(box)
			box:HighlightText()
		end)
		export_box.editBox:HookScript("OnMouseUp", function(edit)
			edit:HighlightText()
		end)
		export_window:AddChild(export_box)
	end
	local text, changes = BuildExport()
	local profile = XLoot.db:GetCurrentProfile()
	if text then
		export_text = text
		local count = changes > 0 and L.export_count:format(profile, changes) or L.export_empty:format(profile)
		export_info:SetText(count.."\n"..L.export_help)
	else
		export_text = ""
		export_info:SetText(Warn(L.export_failed))
	end
	export_box:SetText(export_text)
	export_window:Show()
	C_Timer.After(0, function()
		export_box:SetFocus()
		export_box:HighlightText()
	end)
end

local import_window, import_box, import_status, import_name, import_new, import_replace
local pending, suggested

local function OnImportText(_, _, text)
	local payload, problem = Decode(text)
	pending = payload
	import_new:SetDisabled(not payload)
	import_replace:SetDisabled(not payload)
	if not payload then
		import_status:SetText(problem and Warn(problem) or "")
		return
	end
	local source = type(payload.profile) == "string" and Shorten(payload.profile:gsub("[%c|]", ""), 40) or ""
	if source == "" then
		source = "XLoot"
	end
	local changes = type(payload.positions) == "table" and Count(payload.positions) or 0
	for _, values in pairs(payload.settings) do
		if type(values) == "table" then
			changes = changes + Count(values)
		end
	end
	import_status:SetText(L.import_summary:format(GameName(payload.game), source, changes))
	local typed = strtrim(import_name:GetText() or "")
	if typed == "" or typed == suggested then
		suggested = UniqueName(("%s (%s)"):format(source, GameName(payload.game)))
		import_name:SetText(suggested)
	end
end

StaticPopupDialogs["XLOOT_IMPORT_REPLACE"] = {
	text = L.import_replace_confirm,
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, target)
		if target ~= XLoot.db:GetCurrentProfile() then
			import_window:Show()
			import_status:SetText(Warn(L.import_profile_changed))
		elseif pending then
			ImportReplace(pending)
		end
	end,
	OnCancel = function()
		import_window:Show()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function addon.ShowImport()
	if not import_window then
		import_window = NewWindow(L.import_title, "XLootImportWindow", 390)
		NewLabel(import_window):SetText(L.import_help)
		import_box = AceGUI:Create("MultiLineEditBox")
		import_box:SetLabel("")
		import_box:SetNumLines(8)
		import_box:DisableButton(true)
		import_box:SetFullWidth(true)
		import_box:SetCallback("OnTextChanged", OnImportText)
		import_window:AddChild(import_box)
		import_status = NewLabel(import_window)
		import_name = AceGUI:Create("EditBox")
		import_name:SetLabel(L.import_name)
		import_name:DisableButton(true)
		import_name:SetRelativeWidth(0.5)
		import_window:AddChild(import_name)
		import_new = NewButton(import_window, L.import_new, function()
			local name = strtrim(import_name:GetText() or "")
			if name == "" then
				import_status:SetText(Warn(L.import_name_missing))
			elseif ProfileExists(name) then
				import_status:SetText(Warn(L.import_name_taken:format(name)))
			elseif pending then
				import_window:Hide()
				ImportAsNew(pending, name)
			end
		end)
		NewLabel(import_window, 0.5)
		-- StaticPopups sit in a lower strata than this window, so it steps aside while the confirm is up.
		import_replace = NewButton(import_window, L.import_replace, function()
			if pending then
				import_window:Hide()
				local profile = XLoot.db:GetCurrentProfile()
				if not StaticPopup_Show("XLOOT_IMPORT_REPLACE", profile, nil, profile) then
					import_window:Show()
				end
			end
		end)
	end
	pending, suggested = nil, nil
	import_box:SetText("")
	import_name:SetText("")
	import_status:SetText("")
	import_new:SetDisabled(true)
	import_replace:SetDisabled(true)
	import_window:Show()
	C_Timer.After(0, function()
		import_box:SetFocus()
	end)
end

-- AceDBOptions hands every addon the same args table, so copy it rather than adding to it.
function addon.ProfileOptions()
	local base = LibStub("AceDBOptions-3.0"):GetOptionsTable(XLoot.db)
	local args = Copy(base.args)
	local hidden = not Encoding
	args.transfer = { type = "header", name = L.profile_transfer, order = 90, hidden = hidden }
	args.export = { type = "execute", name = L.profile_export, desc = L.profile_export_desc, order = 91, hidden = hidden, func = addon.ShowExport }
	args.import = { type = "execute", name = L.profile_import, desc = L.profile_import_desc, order = 92, hidden = hidden, func = addon.ShowImport }
	return { type = "group", name = base.name, desc = base.desc, handler = base.handler, args = args }
end
