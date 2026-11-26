---@class XLootAddon
local XLoot = select(2, ...)
local lib = {
	skins = {},
	masque_tweaks = {},
}
XLoot.Skin = lib
local L = XLoot.L
local print = print

-- Custom skins
-- To add your own, simply make XLoot a dependency then call XLoot:RegisterSkin(name, skin_table)
-- skin_table being a table with these keys:
-- [required] texture - Path to texture
-- [optional] name - Shown in UI, name provided to RegisterSkin used by default
-- [optional] size, size_highlight
-- [optional] row_spacing
-- [optional] frame_color_*, loot_color_* -- see the color keys in Frame.lua profile defaults
-- [optional] color_mod - Multiplier for border quality colors
-- [optional] padding, padding_highlight - Padding refers to how far outward (or inward) the border should be offset from the frame

-- Tweaking Masque skins
-- To keep from having to change this file, call XLoot:RegisterMasqueTweak(skin_name, skin_table)
-- following the same rules as custom skins
-- Quick or temporary tweaks can be added to SKIN_TWEAKS.lua

lib.base = {
	bar_texture = [[Interface\AddOns\XLoot\Textures\bar]],
	color_mod = .75,
	row_spacing = 2,
}

function XLoot:RegisterSkin(skin_name, skin_table)
	setmetatable(skin_table, { __index = lib.base })
	skin_table.key = skin_name
	lib.skins[skin_name] = skin_table
end

function XLoot:RegisterMasqueTweak(masque_name, tweak_table)
	lib.masque_tweaks[masque_name] = tweak_table
	if lib.skins[masque_name] then
		for k, v in pairs(tweak_table) do
			lib.skins[masque_name][k] = v
		end
	end
end

local function subtable_insert(t, k, v)
	if not t[k] then
		t[k] = {}
	end
	table.insert(t[k], v)
end

do
	local base = {
		padding = 2,
		size = 16,
		layer = 'ARTWORK',
		mode = 'BLEND',
		r = 1,
		g = 1,
		b = 1,
		a = 1
	}
	local types = {
		highlight = {
			mode = 'ADD',
			layer = 'HIGHLIGHT',
			texture = [[Interface\Buttons\ButtonHilight-Square]],
			size = 8,
			padding = 0,
			r = .8,
			g = .8,
			b = .8,
			a = .8
		}
	}

	local mt = {
		__index = function(t, k)
			local ttype = rawget(t, 'type')
			if ttype and types[ttype] and types[ttype][k] then
				return types[ttype][k]
			end
			return base[k] or nil
		end
	}

	local function meta(t)
		return setmetatable(t, mt)
	end

	local function update_borders(frame, options, borders, r, g, b, a)
		local padding = options.padding
		local size = options.size/2
		r = r or options.r
		g = g or options.g
		b = b or options.b
		a = a or options.a
		for pos, tex in ipairs(borders) do
			tex:SetDrawLayer(options.layer)
			tex:SetTexture(options.texture)
			tex:SetBlendMode(options.mode)
			tex:SetWidth(size)
			tex:SetHeight(size)
			tex:SetVertexColor(r, g, b, a)

			tex:ClearAllPoints()
			if pos == 1 then
				tex:SetTexCoord(0, 1/6, 0, 1/6)
				tex:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding)
			elseif pos == 2 then
				tex:SetTexCoord(5/6, 1, 0, 1/6)
				tex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", padding, padding)
			elseif pos == 3 then
				tex:SetTexCoord(0, 1/6, 5/6, 1)
				tex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -padding, -padding)
			elseif pos == 4 then
				tex:SetTexCoord(5/6, 1, 5/6, 1)
				tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding)
			elseif pos == 5 then
				tex:SetTexCoord(1/6, 5/6, 0, 1/6)
				tex:SetPoint("TOPLEFT", borders[1], "TOPRIGHT")
				tex:SetPoint("TOPRIGHT", borders[2], "TOPLEFT")
			elseif pos == 6 then
				tex:SetTexCoord(1/6, 5/6, 5/6, 1)
				tex:SetPoint("BOTTOMLEFT", borders[3], "BOTTOMRIGHT")
				tex:SetPoint("BOTTOMRIGHT", borders[4], "BOTTOMLEFT")
			elseif pos == 7 then
				tex:SetTexCoord(0, 1/6, 1/6, 5/6)
				tex:SetPoint("TOPLEFT", borders[1], "BOTTOMLEFT")
				tex:SetPoint("BOTTOMLEFT", borders[3], "TOPLEFT")
			elseif pos == 8 then
				tex:SetTexCoord(5/6, 1, 1/6, 5/6)
				tex:SetPoint("TOPRIGHT", borders[2], "BOTTOMRIGHT")
				tex:SetPoint("BOTTOMRIGHT", borders[4], "TOPRIGHT")
			end
		end
	end

	local function create_borders(frame, options)
		local borders = { }
		for i = 1, 8 do
			borders[i] = frame:CreateTexture()
		end
		update_borders(frame, options, borders)
		return borders
	end

	local backdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = true, tileSize = 16,
		insets = {left = 3, right = 3, top = 3, bottom = 3},
	}

	local backdrop_empty = {
		bgFile = ''
	}

	local bd_color = { 0, 0, 0, .9 }
	local g_color = { .5, .5, .5, .6 }
	local clear = { 0, 0, 0, 0 }

	local function SetBorderColor(self, r, g, b, a)
		for i, x in pairs(self._skin_borders) do
			x:SetVertexColor(r, g, b, a or 1)
		end
		if self._modern then
			lib.PaintEdge(self._modern, r, g, b)
		end
	end

	local function shown(list, show)
		if list then
			for _, tex in pairs(list) do
				tex:SetShown(show)
			end
		end
	end

	-- Only a box this hid is ever shown again, so another addon's hidden borders stay hidden.
	function lib.ShowBox(frame, show, keep_borders)
		if show and not frame._box_hidden then
			return
		end
		frame._box_hidden = not show or nil
		shown(frame._skin_borders, show or keep_borders)
		if frame.gradient then
			frame.gradient:SetShown(show)
		end
		if frame._highlights and frame._higlight_options.layer == 'HIGHLIGHT' then
			shown(frame._highlights, show)
		end
		if frame.GetBackdrop and frame:GetBackdrop() then
			frame:SetBackdropColor(unpack(show and bd_color or clear))
		end
	end

	local function GetBorderColor(self)
		return self._skin_borders[1]:GetVertexColor()
	end

	local function SetGradientColor(self, r, g, b, a)
		self.gradient:SetGradient('VERTICAL', CreateColor(0.1, 0.1, 0.1, 0), CreateColor(r, g, b, a))
	end

	function lib:Gradient(frame)
		local g = frame:CreateTexture(nil, 'BORDER')
		frame.gradient = g
		g:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		g:SetPoint('TOPLEFT', 3, -3)
		g:SetPoint('BOTTOMRIGHT', -3, 3)
		-- g:SetBlendMode'ADD'
		frame.SetGradientColor = SetGradientColor
		frame:SetGradientColor(unpack(g_color))
	end

	function lib:Backdrop(frame, opt_backdrop)
		frame:SetBackdrop(opt_backdrop or backdrop)
		frame:SetBackdropColor(unpack(bd_color))
	end

	function lib:Skin(frame, options)
		frame._skin_options = meta(options)

		if options.backdrop ~= false then
			self:Backdrop(frame, type(options.backdrop) == 'table' and options.backdrop or nil)
		end

		if options.gradient ~= false then
			self:Gradient(frame)
		end

		frame._skin_borders = create_borders(frame, options)
		frame.SetBorderColor = SetBorderColor
		frame.GetBorderColor = GetBorderColor
	end

	function lib:SkinRaw(frame, options)
		return create_borders(frame, meta(options)), SetBorderColor
	end

	function lib:UpdateSkin(frame, options, r, g, b, a)
		frame._skin_options = meta(options)
		update_borders(frame, options, frame._skin_borders, r, g, b, a)
	end

	local function ShowHighlight(self, status)
		for _, tex in ipairs(self._highlights) do
			tex:Show()
		end
	end

	local function HideHighlight(self)
		for _, tex in ipairs(self._highlights) do
			tex:Hide()
		end
	end

	local function SetHighlightColor(self, r, g, b, a)
		for _, tex in ipairs(self._highlights) do
			tex:SetVertexColor(r, g, b, a)
		end
	end

	local function GetHighlightColor(self)
		return self._highlights[1]:GetVertexColor()
	end

	local highlight = { type = 'highlight' }

	function lib:Highlight(frame, options)
		options = meta(options or highlight)

		frame._highlights = create_borders(frame, options)
		frame._higlight_options = options

		frame.ShowHighlight = ShowHighlight
		frame.HideHighlight = HideHighlight
		frame.SetHighlightColor = SetHighlightColor
		frame.GetHighlightColor = GetHighlightColor
		if options.layer ~= 'HIGHLIGHT' then
			frame:HideHighlight()
		end
	end

	function lib:UpdateHighlight(frame, options, r, g, b, a)
		frame._higlight_options = meta(options)
		update_borders(frame, options, frame._highlights, r, g, b, a)
	end
end

do
	local FLAT = [[Interface\Buttons\WHITE8X8]]
	local EDGE, HOVER_ALPHA, OUTLINE_ALPHA = 3, .06, .6
	local OUTLINE = { { 'TOPLEFT', 'TOPRIGHT' }, { 'BOTTOMLEFT', 'BOTTOMRIGHT' }, { 'TOPLEFT', 'BOTTOMLEFT' }, { 'TOPRIGHT', 'BOTTOMRIGHT' } }
	local fade_from, fade_to = CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0)
	lib.FLAT, lib.EDGE = FLAT, EDGE

	function lib.Modern(holder, region)
		local m = holder._modern
		if m then
			return m
		end
		region = region or holder
		m = { region = region }
		local function piece(layer, sublevel)
			local tex = holder:CreateTexture(nil, layer, nil, sublevel)
			tex:Hide()
			return tex
		end
		m.panel = piece('BACKGROUND', -8)
		m.panel:SetAllPoints(region)
		m.fade = piece('BACKGROUND', -7)
		m.fade:SetColorTexture(1, 1, 1, 1)
		m.fade:SetAllPoints(region)
		m.edge = piece('ARTWORK')
		m.hover = piece('BORDER')
		m.hover:SetColorTexture(1, 1, 1, HOVER_ALPHA)
		m.hover:SetAllPoints(region)
		m.outline = {}
		for i, points in ipairs(OUTLINE) do
			local line = piece('OVERLAY', 7)
			line:SetPoint(points[1], region, points[1])
			line:SetPoint(points[2], region, points[2])
			m.outline[i] = line
		end
		if holder._skin_borders then
			m.r0, m.g0, m.b0 = holder:GetBorderColor()
		end
		holder._modern = m
		return m
	end

	function lib.HideModern(m)
		if m then
			m.panel:Hide()
			m.fade:Hide()
			m.edge:Hide()
			lib.ShowHover(m, false)
		end
	end

	function lib.PaintFade(m, right, r, g, b, a)
		fade_from:SetRGBA(r, g, b, right and 0 or a)
		fade_to:SetRGBA(r, g, b, right and a or 0)
		m.fade:SetGradient('HORIZONTAL', fade_from, fade_to)
		m.fade:Show()
	end

	function lib.PlaceEdge(m, right)
		local side = right and 'RIGHT' or 'LEFT'
		m.edge:ClearAllPoints()
		m.edge:SetPoint('TOP'..side, m.region, 'TOP'..side)
		m.edge:SetPoint('BOTTOM'..side, m.region, 'BOTTOM'..side)
		m.edge:SetWidth(EDGE)
		m.edge:Show()
	end

	-- A white or gray edge reads as no color at all, so any near-neutral color takes the accent color instead.
	function lib.PaintEdge(m, r, g, b)
		if r then
			m.r0, m.g0, m.b0 = r, g, b
		end
		r, g, b = m.r0, m.g0, m.b0
		if not r then
			return
		end
		if math.max(r, g, b) - math.min(r, g, b) <= .1 then
			r, g, b = XLoot:AccentColor()
		end
		m.r, m.g, m.b = r, g, b
		m.edge:SetColorTexture(r, g, b, 1)
	end

	function lib.ShowHover(m, show)
		if not m then
			return
		end
		m.hover:SetShown(show)
		local mode = XLoot.opt.hover_outline
		local r, g, b = m.r, m.g, m.b
		if mode == 'accent' or not r then
			r, g, b = XLoot:AccentColor()
		end
		for i, line in ipairs(m.outline) do
			if show and mode ~= 'none' then
				if PixelUtil then
					if i <= 2 then PixelUtil.SetHeight(line, 1, 1) else PixelUtil.SetWidth(line, 1, 1) end
				elseif i <= 2 then
					line:SetHeight(1)
				else
					line:SetWidth(1)
				end
				line:SetColorTexture(r, g, b, OUTLINE_ALPHA)
				line:Show()
			else
				line:Hide()
			end
		end
	end

	function lib.SavePoints(region)
		local points = {}
		for i = 1, region:GetNumPoints() do
			points[i] = { region:GetPoint(i) }
		end
		return points
	end

	function lib.RestorePoints(region, points)
		region:ClearAllPoints()
		for _, point in ipairs(points) do
			region:SetPoint(unpack(point))
		end
	end

	-- Leaving Modern puts the icon back exactly where it was, which may be another addon's layout rather than XLoot's.
	function lib.ModernIcon(icon_frame, icon, on)
		on = on and true or false
		if (icon_frame._modern_icon or false) == on then
			return
		end
		icon_frame._modern_icon = on
		local edge = icon_frame._modern_edge
		if on and not edge then
			edge = icon_frame:CreateTexture(nil, 'BACKGROUND', nil, -8)
			edge:SetColorTexture(0, 0, 0, 1)
			edge:SetPoint('TOPLEFT', icon_frame, 'TOPLEFT', -1, 1)
			edge:SetPoint('BOTTOMRIGHT', icon_frame, 'BOTTOMRIGHT', 1, -1)
			icon_frame._modern_edge = edge
		end
		if edge then
			edge:SetShown(on)
		end
		if on then
			icon_frame._icon_points = lib.SavePoints(icon)
			icon:ClearAllPoints()
			icon:SetAllPoints(icon_frame)
		else
			lib.RestorePoints(icon, icon_frame._icon_points)
		end
	end
end

-- AceDB copies defaults into the profile, so a color equal to its default counts as never changed and follows the skin.
function lib.Color(opt, defaults, skin, key)
	local raw, default = rawget(opt, key), defaults[key]
	if raw and (raw[1] ~= default[1] or raw[2] ~= default[2] or raw[3] ~= default[3] or raw[4] ~= default[4]) then
		return unpack(raw)
	end
	return unpack(skin and skin[key] or default)
end

do
	local function compile(data, name)
		assert(data.sets[name], "Bad set name given to XLoot.Skin")
		if not data.compiled[name] then
			data.compiled[name] = {}
		elseif next(data.compiled[name]) then
			return data.compiled[name]
		end
		local out = data.compiled[name]
		local skin = (data.SKIN and lib.skins[data.SKIN]) and lib.skins[data.SKIN] or lib.current
		local set = data.sets[name]
		for k,v in pairs(lib.base) do
			out[k] = v
		end
		for k,v in pairs(skin) do
			out[k] = v
		end
		if skin.highlight
			and set.type
			and set.type == 'highlight'
			and type(skin.highlight) == 'table' then
			for k,v in pairs(skin.highlight) do
				out[k] = v
			end
			-- Highlights shouldn't inherit default texture
			if not skin.highlight.texture then
				out.texture = nil
			end
		end
		for k,v in pairs(set) do
			out[k] = v
		end
		setmetatable(out, getmetatable(skin))
		return out
	end

	-- Reads the compiled skin without Reskin's frame walk, for callers that do not need to re-apply it. XLoot:ApplyOptions reskins every skinner before the module hooks run.
	local function CurrentSkin(self)
		local data = self._skin_data
		return compile(data, data.default or next(data.sets))
	end

	local function Reskin(self)
		local data = self._skin_data
		for k,v in pairs(data.compiled) do
			wipe(v)
		end
		for set_name,frames in pairs(data.skinned) do
			for i,frame in ipairs(frames) do
				lib:UpdateSkin(frame, compile(data, set_name), frame:GetBorderColor())
			end
		end
		for set_name,frames in pairs(data.highlighted) do
			for i,frame in ipairs(frames) do
				lib:UpdateHighlight(frame, compile(data, set_name), frame:GetHighlightColor())
			end
		end
		return CurrentSkin(self)
	end

	local function Skin(self, frame, set_name)
		local data = self._skin_data
		set_name = set_name or data.default
		local skin = compile(data, set_name)
		lib:Skin(frame, skin)
		subtable_insert(data.skinned, set_name, frame)
		return skin
	end

	local function Highlight(self, frame, set_name)
		local data = self._skin_data
		set_name = set_name or data.default
		lib:Highlight(frame, compile(data, set_name))
		subtable_insert(data.highlighted, set_name, frame)
	end

	XLoot.skinners = {}
	function XLoot:MakeSkinner(target, sets, default_set)
		if not default_set and not sets.default then
			sets.default = {}
		end
		target._skin_data = {
			skinned = {},
			highlighted = {},
			compiled = {},
			sets = sets,
			default = default_set or "default"
		}
		target.Reskin = Reskin
		target.CurrentSkin = CurrentSkin
		target.Skin = Skin
		target.Highlight = Highlight
		table.insert(XLoot.skinners, target)
		return target
	end
end

local svelte = {
	name = ('|c2244dd22%s|r'):format(L.skin_svelte),
	texture = [[Interface\AddOns\XLoot\Textures\border_svelte]],
}
local legacy = {
	name = ('|c2244dd22%s|r'):format(L.skin_legacy),
	row_spacing = 3,
	texture = [[Interface\AddOns\XLoot\Textures\border_legacy]],
	size = 16,
	highlight = {
		size = 12
	},
	color_mod = .85,
}
local smooth = {
	name = ('|c2244dd22%s|r'):format(L.skin_smooth),
	row_spacing = 3,
	texture = [[Interface\AddOns\XLoot\Textures\border_smooth]],
	size = 14,
	padding = 1,
	highlight = {
		size = 6,
		padding = -1
	},
	color_mod = .9,
}

local modern = {
	name = ('|c2244dd22%s|r'):format(L.skin_modern),
	modern = true,
	texture = lib.FLAT,
	bar_texture = lib.FLAT,
	size = 2,
	padding = 0,
	row_spacing = 4,
	color_mod = 1,
	accent_color = { 1, .82, 0 },
	panel_color = { .05, .05, .06, .88 },
	lift_color = { 1, 1, 1, .07 },
	fade_color = { 0, 0, 0, .6 },
	frame_color_border = { .25, .25, .28, 1 },
	frame_color_backdrop = { .05, .05, .06, .88 },
	loot_color_backdrop = { 1, 1, 1, .07 },
	roll_color_backdrop = { .05, .05, .06, .88 },
}

XLoot:RegisterSkin('svelte', svelte)
XLoot:RegisterSkin('legacy', legacy)
XLoot:RegisterSkin('smooth', smooth)
XLoot:RegisterSkin('modern', modern)

-- Index Masque skins later so we definitely catch all of them

function XLoot:SkinsOnInitialize()
	local Masque = LibStub('Masque', true) or LibStub('LibButtonFacade', true)
	if Masque and Masque.GetSkins then
		local Masque_Skins = Masque:GetSkins()
		if type(Masque_Skins) == 'table' then
			for k, v in pairs(Masque_Skins) do
				if k ~= 'Blizzard' and v.Normal.Texture then
					local skin = { }
					-- Guess at dimensions
					if v.Icon.Height and v.Normal.Height then
						skin.padding = (v.Normal.Height - v.Icon.Height) / 4
						skin.row_spacing = v.Icon.Height / 16
						skin.size = v.Icon.Height / 2
					end
					skin.texture = v.Normal.Texture
					skin.name = ('|c22dddd22Masque:|r %s'):format(k)
					if lib.masque_tweaks[k] then
						for mk,mv in pairs(lib.masque_tweaks[k]) do
							skin[mk] = mv
						end
					end
					XLoot:RegisterSkin(k, skin)
				end
			end
		else
			print("XLoot: Use of masque skins requires the beta version of Masque.")
		end
	end

	XLoot:ApplySkinTweaks()

	self:SetSkin(self.db.profile.skin)
end

function XLoot:SetSkin(name)
	lib.current = lib.skins[lib.skins[name] and name or 'smooth']
end

--@do-not-package@
local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
