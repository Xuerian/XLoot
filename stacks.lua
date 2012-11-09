local XLoot = select(2, ...)
local lib = {}
XLoot.Stack = lib
local L = XLoot.L
local print = print

-- ANCHOR element
do
	local backdrop = { bgFile = [[Interface\Tooltips\UI-Tooltip-Background]] }

	local function OnDragStart(self)
		self:StartMoving()
	end
	
	local function OnDragStop(self)
		self:StopMovingOrSizing()
		self.data.x = self:GetLeft()
		self.data.y = self:GetTop()
	end
	
	local function Close_OnClick(self)
		self.parent:Hide()
	end
	
	local function OnClick(self, ...)
		if self.OnClick then
			self:OnClick(...)
		end
	end

	local function Show(self)
		self:SetClampedToScreen(true)
		self:Position()
		self.data.visible = true
		self:_Show()
	end
	
	local function Hide(self)
		self:SetClampedToScreen(false)
		if self.data.direction == 'up' then
			self:Position(self.data.x, self.data.y - 20)
		elseif self.data.direction then
			self:Position(self.data.x, self.data.y + 20)
		end
		self:GetTop() -- Force reflow
		self:GetBottom()
		self.data.visible = false
		self:_Hide()
	end

	local function Position(self, x, y)
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x or self.data.x, y or self.data.y)
	end

	local function AnchorChild(self, child, to)
		local d = self.data.direction
		if to then
			local a, b, x, y = 'BOTTOMLEFT', 'TOPLEFT', 0, 2
			if d == 'down' then
				a, b, x, y = 'TOPLEFT', 'BOTTOMLEFT', 0, -2
			elseif d == 'left' then
				a, b, x, y = 'RIGHT', 'LEFT', 2, 0
			elseif d == 'right' then
				a, b, x, y = 'LEFT', 'RIGHT', -2, 0
			end
			child:SetPoint(a, to, b, x, y)
		else
			local a, b = 'BOTTOMLEFT', 'TOPLEFT'
			if d == 'down' then
				a, b = 'TOPLEFT', 'BOTTOMLEFT'
			elseif d == 'left' then
				a, b = 'TOPRIGHT', 'BOTTOMRIGHT'
			end
			child:SetPoint(a, self, b)
		end
		if self.data and self.data.scale then
			child:SetScale(self.data.scale)
		end
	end

	function lib:CreateAnchor(text, svdata)
		local anchor = CreateFrame('Button', nil, UIParent)
		anchor:SetBackdrop(backdrop)
		anchor:SetBackdropColor(0, 0, 0, 0.7)
		anchor:SetMovable(true)
		anchor:SetClampedToScreen(true)
		anchor:RegisterForDrag('LeftButton')
		anchor:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		anchor:SetScript('OnDragStart', OnDragStart)
		anchor:SetScript('OnDragStop', OnDragStop)
		anchor:SetScript('OnClick', OnClick)
		anchor:SetAlpha(0.8)
		anchor.Show, anchor._Show = Show, anchor.Show
		anchor.Hide, anchor._Hide = Hide, anchor.Hide
		anchor.Position = Position
		anchor.OnMove = OnMove
		anchor.OnToggle = OnToggle
		anchor.AnchorChild = AnchorChild
		
		local close = CreateFrame('Button', nil, anchor, 'UIPanelCloseButton')
		close:SetScript('OnClick', Close_OnClick)
		close:SetPoint('RIGHT', 1, 0)
		close:SetHeight(20)
		close:SetWidth(20)
		close.parent = anchor
		anchor.close = close

		local label = anchor:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
		label:SetPoint('CENTER', -5, 0)
		label:SetJustifyH('MIDDLE')
		label:SetText(text)
		anchor.label = label
		
		anchor:SetHeight(20)
		anchor:SetWidth(label:GetStringWidth() + 100)

		if svdata then
			anchor.data = svdata
			anchor:Position()
			if not svdata.visible then
				anchor:Hide()
			end
		else
			anchor.data = svdata or {}
		end
		
		return anchor
	end
end
-- END ANCHOR element

local function AnchorScale(self, scale)
	self:SetScale(scale)
	if self.children then
		for _, child in pairs(self.children) do
			child:SetScale(scale)
		end
	end
end

local table_insert = table.insert
local function AcquireChild(self)
	for _, f in ipairs(self.children) do
		if not f.active then
			return f
		end
	end
	child = self:Factory()
	table_insert(self.children, child)
	return child, true
end

-- STATIC STACK
do
	local function Push(self)
		local child, new = AcquireChild(self)
		if new then
			children = self.children
			self:AnchorChild(child, #children > 1 and children[#children-1] or nil)
		end
		child:Show()
		child.active = true
		return child
	end

	local function Pop(self, child)
		child:Hide()
		child.active = false
		if child.Popped then
			child:Popped()
		end
	end

	local function Restack(self)
		for i,child in ipairs(self.children) do
			child:ClearAllPoints()
			self:AnchorChild(child, i == 1 and self or self.children[i-1])
		end
	end

	function lib:CreateStaticStack(factory, ...)
		local anchor = self:CreateAnchor(...)
		anchor.children = {}
		anchor.Factory = factory
		anchor.Push = Push
		anchor.Pop = Pop
		anchor.Scale = AnchorScale
		anchor.Restack = Restack
		return anchor
	end
end

--@do-not-package@
-- DYNAMIC STACK
-- do
-- 	local function Acquire(self)
-- 		local child = AcquireChild(self)

-- 		local fade_in = child:CreateAnimationGroup()
-- 		local anim = fade_in:CreateAnimation('Alpha')
-- 		anim:SetDuration(1)
-- 		anim:SetChange(0)
-- 		anim:SetSmoothing("OUT")
-- 		child.fade_in = fade_in

-- 		local fade_out = child:CreateAnimationGroup()
-- 		fade_out:SetScript('OnFinished', FadeFinish)
-- 		local anim = fade_out:CreateAnimation('Alpha')
-- 		anim:SetDuration(self.fade_time)
-- 		anim:SetChange(-1)
-- 		anim:SetSmoothing("OUT")
-- 		child.fade_out = fade_out

-- 		return child
-- 	end

-- 	local function FadeOutFinish(self)
-- 		print('finished')
-- 		local child = self:GetParent()
-- 		child.achor:Clear(self)
-- 		child:SetAlpha(1)
-- 	end

-- 	local function Init(self)
-- 		local child = Acquire(self)
-- 		child.anchor = self
-- 		return child
-- 	end

-- 	local function expire_sort(a, b)
-- 		local ae, be = a.bar.expires, b.bar.expires
-- 		if ae > be then
-- 			return b
-- 		end
-- 		return a
-- 	end

-- 	local table_insert = table.insert
-- 	local function Push(self, child)
-- 		child = child or Init(self)
-- 		child.active = true
-- 		table_insert(self.active, child)
-- 		child:Show()
-- 		child:SetAlpha(0)
-- 		child.fade_in:Play()
-- 		self.eframe:Show()
-- 		return child
-- 	end

-- 	local function Pop(self, child)
-- 		child.fade_out:Play()
-- 	end

-- 	local table_remove = table.remove
-- 	local function Clear(self, child)
-- 		child.active = false
-- 		child.fading = nil
-- 		for i,test in pairs(self.active) do
-- 			if child == test then
-- 				table_remove(self.active, i)
-- 			end
-- 		end
-- 		if #self.active == 0 then
-- 			self.eframe:Hide()
-- 		end
-- 	end

-- 	local timer = 0
-- 	local function OnUpdate(self, elapsed)
-- 		timer = timer + elapsed
-- 		if timer > .1 then
-- 			timer = 0
-- 			local anchor = self.anchor
-- 			local time, focus, fade_time = GetTime(), GetMouseFocus(), anchor.fade_time
-- 			for k,child in pairs(anchor.active) do
-- 				if child.bar.expires < time then
-- 					if child == focus or (child.parent and child.parent == focus) then
-- 						child.fade_out:Stop()
-- 						--child:SetAlpha(1)
-- 					else
-- 						if not child.fade_out:IsPlaying() then
-- 							child.fade_out:Play()
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	function lib:CreateDynamicStack(factory, ...)
-- 		local anchor = self:CreateAnchor(...)
-- 		anchor.active = {}
-- 		anchor.children = {}
-- 		anchor.Factory = factory
-- 		anchor.Push = Push
-- 		anchor.Pop = Pop
-- 		anchor.Scale = AnchorScale
-- 		anchor.fade_time = 5

-- 		local eframe = CreateFrame('Frame')
-- 		eframe:SetScript('OnUpdate', OnUpdate)
-- 		eframe:Hide()
-- 		eframe.anchor = anchor
-- 		anchor.eframe = eframe

-- 		return anchor
-- 	end
-- end
--[=[
	local function AnchorButton(anchor, up, down, highlight, click)
		local button = CreateFrame('Button', nil, anchor)
		button:SetHeight(20)
		button:SetWidth(20)
		button:SetNormalTexture(up)
		button:SetHighlightTexture(highlight)
		button:SetPushedTexture(down)
		button:SetScript('OnClick', click)
		return button
	end

	local function ExpandClick(self)

	end

	local function CollapseClick(self)

	end

	local function AppearanceClick(self)
		if not lib.ScaleFrame then
			local frame = CreateFrame('Frame', 'XStackScaleFrame', UIParent)
			frame:SetWidth(250)

			local scale = CreateFrame('Slider')

			lib.ScaleFrame = frame
		end
	end

	function lib:CreateStackAnchor(...)
		local anchor = self:CreateAnchor(...)

		local expand = AnchorButton(anchor, 
			[[Interface\BUTTONS\UI-Panel-ExpandButton-Up]],
			[[Interface\BUTTONS\UI-Panel-ExpandButton-Down]],
			[[Interface\BUTTONS\UI-Panel-MinimizeButton-Highlight]],
			ExpandClick)

		local collapse = AnchorButton(anchor, 
			[[Interface\BUTTONS\UI-Panel-CollapseButton-Up]],
			[[Interface\BUTTONS\UI-Panel-CollapseButton-Down]],
			[[Interface\BUTTONS\UI-Panel-MinimizeButton-Highlight]],
			CollapseClick)

		local appearance = AnchorButton(anchor, 
			[[Interface\BUTTONS\UI-Panel-ExpandButton-Up]],
			[[Interface\BUTTONS\UI-Panel-ExpandButton-Down]],
			[[Interface\BUTTONS\UI-Panel-MinimizeButton-Highlight]],
			AppearanceClick)

	end

	local function Attach(self, f, to)

	end

	local function Push(self, ...)

	end

	local function Pop(self, f)

	end

	function lib:NewStack(anchor)
		local stack = {
			anchor = anchor,
			Push = Push,
			Pop = Pop,
			Attach = Attach,

		}

		return stack
	end 
-- ]=]
-- END STACKS


-- Debug
local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
