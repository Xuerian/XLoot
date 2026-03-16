# XLoot — Midnight (Patch 12.0) Compatibility Changes

## Summary

This PR updates XLoot and all sub-modules to load and function correctly under
World of Warcraft: Midnight (Patch 12.0.1, Interface version 120001).
XLoot is a loot-UI replacement addon and is **not** a combat API consumer, so it
is largely insulated from the "addon disarmament" restrictions; the changes here
are targeted API removals/renames rather than philosophical ones.

---

## Files Changed

### All modules — `.toc` Interface version bump

| File | Old value | New value |
|------|-----------|-----------|
| `XLoot/XLoot.toc` | `110000` | `120001` |
| `XLoot_Frame/XLoot_Frame.toc` | `110000` | `120001` |
| `XLoot_Monitor/XLoot_Monitor.toc` | `110000` | `120001` |
| `XLoot_Group/XLoot_Group.toc` | `100005` | `120001` |
| `XLoot_Master/XLoot_Master.toc` | `100005` | `120001` |
| `XLoot_Options/XLoot_Options.toc` | `110000` | `120001` |

**Why:** Addons with an out-of-date `## Interface` version are hard-blocked from
loading by the WoW client in Midnight. No exception, no limp-along mode.

---

### `XLoot/helpers.lua`

**1. `Deformat` rewritten — dynamic code compilation removed entirely**

The original implementation used `loadstring()` to compile match functions from
strings at runtime. An initial patch attempt replaced this with `load()`, but
**both `loadstring` and `load` are unavailable in WoW 12.0's Lua sandbox**.
Confirmed via in-game error: `attempt to call global 'load' (a nil value)`.

The fix eliminates dynamic code generation entirely. The cache now stores a plain
table `{ pat, order }` and matching is done with a direct `pcall(string.match)`
call. The positional-reorder case (`%1$s` format strings) is handled by storing a
numeric order table built at cache-fill time and applying it at call time:

```lua
-- Before (broken in 12.0 — loadstring/load both unavailable in sandbox)
local template = [[return function(message)
    local ok, m1, m2, m3, m4, m5 = pcall(string_match, message, ...)
    return %s
end]]
func = loadstring(template:format(...))()

-- After (pure closure, no sandbox-restricted APIs)
-- Cache entry: { pat = "^<inverted>$", order = nil | {n,n,n,n,n} }
local ok, m1, m2, m3, m4, m5 = pcall(string.match, str, cached.pat)
assert(ok, "Please report this on XLoot's curse page")
if cached.order then
    local c = { m1, m2, m3, m4, m5 }
    return c[ord[1]], c[ord[2]], c[ord[3]], c[ord[4]], c[ord[5]]
end
return m1, m2, m3, m4, m5
```

**2. `floor` / `mod` global aliases → `math.floor` / `math.fmod`**

```lua
-- Before
coin_table[2][2] = mod(floor(copper / 100), 100)
coin_table[3][2] = mod(copper, 100)

-- After
local floor, fmod = math.floor, math.fmod
coin_table[2][2] = fmod(floor(copper / 100), 100)
coin_table[3][2] = fmod(copper, 100)
```

The bare global aliases `floor` and `mod` were removed in Midnight. Explicit
`math.*` references are the safe, forward-compatible form.

---

### `XLoot/XLoot.lua`

**Dead `InterfaceOptions_AddCategory` fallback removed**

```lua
-- Before
if Settings then
    C_AddOns.EnableAddOn("XLoot_Options")
    C_AddOns.LoadAddOn("XLoot_Options")
else
    local stub = CreateFrame("Frame", "XLootConfigPanel", UIParent)
    stub.name = "XLoot"
    stub:Hide()
    InterfaceOptions_AddCategory(stub)   -- <-- removed API
    stub:SetScript("OnShow", ...)
end

-- After
-- Settings API is always present in retail 10.0+; the else-branch is dead
-- code in Midnight and calling InterfaceOptions_AddCategory would error.
C_AddOns.EnableAddOn("XLoot_Options")
C_AddOns.LoadAddOn("XLoot_Options")
```

`InterfaceOptions_AddCategory` was deprecated in 10.0 and removed in 12.0.
The `Settings` API has been the standard since Dragonflight; the fallback path
is unreachable on any supported retail client and can be removed entirely.

---

### `XLoot_Frame/Frame.lua`

**1. `MasterLooterFrame` nil guard**

```lua
-- Before
MasterLooterFrame:SetScript('OnShow', function(self) ... end)

-- After
if MasterLooterFrame then
    MasterLooterFrame:SetScript('OnShow', function(self) ... end)
end
```

`MasterLooterFrame` was removed from the retail client when master loot was
retired from group content. Calling `:SetScript` on nil crashes at load time.

**2. `UIDropDownMenu` → `Menu.CreateContextMenu`**

The entire `XLootLinkDropdown` frame, `UIDropDownMenu_AddButton`, and
`ToggleDropDownMenu` block was replaced with the modern Menu API:

```lua
-- Before (removed in 12.0)
LinkDropdown = CreateFrame('Frame', 'XLootLinkDropdown')
LinkDropdown.initialize = function(self, level)
    for i, c in ipairs(channels) do
        wipe(info)
        info.text = c[2]
        info.arg1 = c[1]
        info.func = Click
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info, 1)
    end
end
ToggleDropDownMenu(1, nil, LinkDropdown, self)

-- After
local function OpenLinkDropdown(owner)
    Menu.CreateContextMenu(owner, function(owner, rootDescription)
        for i, c in ipairs(channels) do
            local channelKey = c[1]
            rootDescription:CreateButton(c[2], function()
                LinkLoot(channelKey)
            end)
        end
    end)
end
OpenLinkDropdown(self)
```

`UIDropDownMenu` and `ToggleDropDownMenu` were removed in Patch 12.0.
`Menu.CreateContextMenu` (introduced in 10.0) is the current standard.

**3. `LOOT_CLOSED` — nil-safe `UIDropDownMenu_GetCurrentDropDown` guard**

```lua
-- Before
if UIDropDownMenu_GetCurrentDropDown() == LinkDropdown then

-- After
if UIDropDownMenu_GetCurrentDropDown and UIDropDownMenu_GetCurrentDropDown() == LinkDropdown then
```

---

### `XLoot_Monitor/events.lua`

**Global chat-string existence guards**

The `handler()` helper now silently skips any pattern whose global string key
does not exist, rather than asserting and halting load:

```lua
-- Before
local function handler(str, func)
    assert(_G[str], "String does not exist", str)
    table.insert(loot_patterns, { _G[str], func, str })
end

-- After
local function handler(str, func)
    if not _G[str] then return end   -- [PATCH 12.0] guard removed strings
    table.insert(loot_patterns, { _G[str], func, str })
end
```

Specific strings at risk of removal in 12.0:
- `YOU_LOOT_MONEY_GUILD` / `LOOT_MONEY_SPLIT_GUILD` — guild gold-split removed
- `CURRENCY_GAINED` / `CURRENCY_GAINED_MULTIPLE` — currency system revamp

The same guard was applied to the `group_patterns` handler block.

---

## Known Remaining Issues / Follow-up Needed

- **`XLoot_Group` and `XLoot_Master`**: TOC versions bumped but Lua not reviewed
  in this PR. These modules were already flagged as broken/unmaintained. Any
  maintainer picking up Group/Master should audit the roll-frame and
  `GetLootRollItemInfo` API calls, as roll-related APIs were also touched in 12.0.
- **`GetLootSlotInfo` return values**: Blizzard noted loot event API instability
  for chest items. The existing `pcall` wrapper in `Frame.lua` provides a safety
  net, but the return-value order should be validated in-game.
- **`LootFrame_OnHide`**: Called via `pcall` in `FramePrototype:OnHide`. If
  Blizzard removed this function it will silently no-op, which is acceptable.

---

## Testing Checklist

- [ ] Addon loads without Lua errors on login
- [ ] Loot frame opens when killing a mob
- [ ] Items, currency, and money display correctly in the loot frame
- [ ] Autoloot functions (quest items, currency, list)
- [ ] "Link All" left-click sends to configured channel
- [ ] "Link All" right-click opens channel picker context menu
- [ ] Monitor toasts appear when looting
- [ ] `/xloot` opens options panel
- [ ] `/xlm` toggles Monitor anchor
