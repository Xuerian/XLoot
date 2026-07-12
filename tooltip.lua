local XLoot = select(2, ...)

-- Retail already shows a vendor sell-price line in item tooltips; this only fills the gap on the Classic flavors, which don't.
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

local issecret = issecretvalue -- 12.0 secret values; nil pre-12.0
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
local MoneyString = XLoot.MoneyString
local SELL_LABEL = _G.SELL_PRICE or "Sell"

local function tip_link(tooltip)
	if tooltip.GetItem then
		local _, link = tooltip:GetItem()
		if link then return link end
	end
	if TooltipUtil and TooltipUtil.GetDisplayedItem then
		return select(2, TooltipUtil.GetDisplayedItem(tooltip))
	end
end

-- Stack count is only known when SetBagItem is called, and the post-call fires before a hooksecurefunc would; stash it pre-render, and clear on every read so a later non-bag tooltip can't inherit a stale count.
local pending_count
if GameTooltip.SetBagItem and GetContainerItemInfo then
	local orig = GameTooltip.SetBagItem
	GameTooltip.SetBagItem = function(self, bag, slot, ...)
		local info = GetContainerItemInfo(bag, slot)
		pending_count = info and info.stackCount
		return orig(self, bag, slot, ...)
	end
end

local function add_sell(tooltip)
	local count = pending_count
	pending_count = nil
	if not (XLoot.opt and XLoot.opt.tooltip_sell) then return end
	local link = tip_link(tooltip)
	if not link or (issecret and issecret(link)) then return end
	local sell = select(11, GetItemInfo(link))
	if not sell or sell == 0 then return end
	local icons = XLoot.opt.value_coin_icons
	if count and count > 1 then
		tooltip:AddDoubleLine(SELL_LABEL, ('%s |cff808080(%d x %s)|r'):format(MoneyString(sell * count, icons), count, MoneyString(sell, icons)))
	else
		tooltip:AddDoubleLine(SELL_LABEL, MoneyString(sell, icons))
	end
end

-- Retail routes item tooltips through TooltipDataProcessor; older clients use the OnTooltipSetItem script.
local TDP = TooltipDataProcessor
if TDP and TDP.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
	TDP.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
		if tooltip == GameTooltip or tooltip == ItemRefTooltip then
			add_sell(tooltip)
		end
	end)
elseif GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript('OnTooltipSetItem', add_sell)
	if ItemRefTooltip and ItemRefTooltip.HookScript then
		ItemRefTooltip:HookScript('OnTooltipSetItem', add_sell)
	end
end
