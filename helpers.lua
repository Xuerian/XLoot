local XLoot = select(2, ...)
local buffer, print = {}, print

local table_insert, table_concat, string_format = table.insert, table.concat, string.format

local coin_table = {
	{ GOLD_AMOUNT, 0, "ffd700" },
	{ SILVER_AMOUNT, 0, "c7c7cf" },
	{ COPPER_AMOUNT, 0, "eda55f" }
}
for i,v in ipairs(coin_table) do
	v[4] = string_format("|cff%s%s|r", v[3], v[1])
end
function XLoot.CopperToString(copper)
	coin_table[1][2] = floor(copper / 10000)
	coin_table[2][2] = mod(floor(copper / 100), 100)
	coin_table[3][2] = mod(copper, 100)

	local buffer = wipe(buffer)
	for i,v in ipairs(coin_table) do
		local n = v[2]
		if n and n > 0 then
			table_insert(buffer, string_format(v[4], n))
		end
	end

	return table_concat(buffer, ", ")
end

local tooltip = CreateFrame('GameTooltip', 'XLootTooltip', UIParent, 'GameTooltipTemplate')
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

function XLoot.GetItemBindType(link)
	local value = (GetCVar('colorblindMode') == '1' and XLootTooltipTextLeft3 or XLootTooltipTextLeft2):GetText()
	if value == ITEM_BIND_ON_PICKUP then
		return 'pickup'
	elseif value == ITEM_BIND_ON_EQUIP then
		return 'equip'
	elseif value == ITEM_BIND_ON_USE then
		return 'use'
	end
end

--@do-not-package@
-- Debug
local AC = LibStub('AceConsole-2.0', true)
if AC then print = function(...) AC:PrintLiteral(...) end end
--@end-do-not-package@
