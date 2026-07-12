# Changelog

XLoot is a revival fork of Xuerian's original addon, continued for retail World of
Warcraft **12.0.7 ("Midnight")**. This changelog starts at the revival; earlier
history lives in the original project's git tags.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [12.12.2] - 2026-07-12

### Bug Fixes
- Loot toasts no longer show a duplicate next to Blizzard's own loot pop-up. When XLoot's Loot Toasts are
  enabled they now hide Blizzard's default loot toast so you see only one, controlled by a new "Hide
  Blizzard's duplicate loot toast" option that is on while toasts are enabled. Non-loot alerts such as
  achievements, recipes, pets, and mounts are left alone. Reported by HOPE.
- Loot toasts now sit above other interface widgets instead of being covered by them, by raising the toast
  display layer. Reported by HOPE.

## [12.12.1] - 2026-07-12

### Bug Fixes
- Fixed a crash while looting in a raid encounter with loot auto-announce enabled. XLoot prefixed the
  announcement with the target's name, which is a protected "secret value" during a boss encounter, and
  errored trying to read it. The announcement now drops any value it cannot read and posts the loot
  normally, and no longer carries a stale mob name onto a later announcement.
- Fixed a blocked-action error when a loot toast was built during combat, which is exactly when most raid
  loot arrives. The toast's click-through mouse setup uses a function Blizzard protects in combat, so it is
  now skipped under combat lockdown; only the click-through-until-Shift mode is briefly affected, and it
  self-corrects once combat ends.
- Hardened several more loot, roll, and master-loot paths against the same secret-value protection so they
  cannot error during instanced encounters: the loot-window item name, the auto-announce quality and
  quantity checks, the Group Loot roll build, and the retail master-loot raid roll.
- Loot toasts now clear their hover highlight and tooltip if they are hidden while the mouse is over them,
  such as hiding the interface with Alt-Z. Suggested by RoadBlock.

## [12.12.0] - 2026-07-11

### Features
- **Loot toasts.** A new optional module pops a Blizzard-style toast when you receive notable loot, with
  the item icon, name, count, and quality border. Plenty to tune: quality threshold, quest items, item
  level, how many show at once, time on screen, sound and spawn animation, quality coloring, font, a
  movable anchor, and how toasts respond to the mouse (always clickable, click-through, or click-through
  until Shift is held). Off by default; `/xltd` previews it. Requested by HOPE.
- **Item values as coin icons.** The loot row sell price and the Classic tooltip sell line can show values
  as gold, silver, and copper coin icons instead of text. Off by default, under the Global settings.
  Requested by 1Holy-Z.

### Bug Fixes
- Fixed the retail Bonus Roll (coin-spin) frame being hidden by XLoot's roll-frame suppression. XLoot no
  longer touches the container that bonus rolls anchor into, so they appear again. Reported by Itamae;
  diagnosed and narrowed with RoadBlock and Itamae.
- Fixed auto-announce silently failing when set to a Raid Warning channel outside a raid, which tripped
  Blizzard's privilege guard. Channels you cannot currently post to are now downgraded or skipped. Thanks
  to Itamae.
- Hardened the default roll-frame suppression so its hide-hook cannot be skipped if Blizzard's roll frames
  had not been created yet the first time XLoot ran.

### Improvements
- Relaid out the "Announce Item Distribution" (Loot Master) and "Link button" (Loot Frame) channel and
  quality dropdowns so their labels no longer overlap, moving the detail into mouseover tooltips.

## [12.11.1] - 2026-07-10

### Bug Fixes
- Fixed Group Loot roll frames not appearing on Classic when the rolled item was not cached yet, such as
  zoning into a dungeon with rolls already in progress. The roll now waits for the item to finish loading
  and retries, instead of being dropped until a reload. Thanks to RoadBlock for the diagnosis, the
  item-load retry, and testing it in a live raid.
- Fixed the Group Loot test preview drawing no frames on Classic, where its sample items only existed on
  retail. It now uses items present on Classic clients. Thanks to RoadBlock for the replacement set.
- Fixed Blizzard's default loot roll frames showing alongside XLoot's after a reload or zone-in during an
  active roll. XLoot now hides the default container directly rather than only unregistering its event.

### Improvements
- Added an AddOns list category and icon so XLoot and its modules group together in the game's addon list.
  Thanks to RoadBlock for the suggestion.

## [12.11.0] - 2026-07-08

### Features
- **Announce loot on open.** The Loot Frame can automatically link a loot window's contents to your chat
  channel the moment it opens, using the same quality threshold as the Link all button. Each loot source
  is announced only once, so reopening a partially-looted corpse never repeats it. Off by default, under
  **/xloot → Loot Frame → Link all button**.
- **Urgent roll timer.** The Group Loot roll countdown can ramp to red as time runs out, reddening the
  whole row border (not just the draining bar) so a roll about to expire is easy to catch at a glance.
  Off by default, under **/xloot → Group Loot → Details**.

### Bug Fixes
- Fixed What's New notices comparing versions as text, which sorted "12.10.0" below "12.9.0" and could
  show or skip the wrong release notes. Versions now compare numerically, and the seen state never moves
  backward, so a downgrade neither re-notifies you nor forgets newer notes.
- Fixed the item-scanning tooltip being parented into the main UI, which kept the game's tooltip refresh
  loop perpetually re-processing items with dynamic tooltips (weapon enchants, temporary buffs, tradeable
  timers). It now lives on the WorldFrame, off that refresh path. Thanks to RoadBlock for the report.

### Improvements
- Reworded the auto-loot options help text to make clear that section is XLoot's own auto-loot, separate
  from Blizzard's built-in Auto Loot, and that running both at once can cause "that object is busy"
  warnings. Thanks to RoadBlock for flagging the confusing wording.

## [12.10.0] - 2026-07-07

### Features
- **Roll-frame highlight.** The Group Loot roll window can recolor its border to show why a drop
  matters: green when the item is an item-level upgrade for you, blue when it's an appearance you
  haven't collected yet. Off by default, under **/xloot → Group Loot → Details**.
- **Per-item auto-roll.** Shift-click Need, Greed, or Pass on a roll window to set a rule for that
  item, and matching drops then roll for you automatically, including auto-confirming bind-on-pickup
  prompts. Auto-Need is behind its own opt-in so a rule can never Need for you without your say-so.
  Off by default, under **/xloot → Group Loot → Auto Roll**.

### Bug Fixes
- Fixed the loot window not appearing when Blizzard auto loot and XLoot's own auto-loot were both
  enabled, which stranded items that still needed the window (bind-on-pickup confirmations and
  read-only master-loot drops). Thanks to Kai for the detailed report and repro.
- Guarded the removed `DoMasterLootRoll` API so the master-loot "Request Roll" menu item no longer
  errors on the Classic flavors. Thanks to RoadBlock for spotting it.

### Improvements
- Consolidated the cross-flavor loot-method and chat API shims into a single place. Thanks to RoadBlock.

## [12.9.0] - 2026-07-05

### Features
- **"New look" tag for uncollected appearances.** Looted weapons and armor whose transmog
  appearance you haven't collected from any source yet get a cyan **(new look)** tag on the loot
  row, so you never vendor or disenchant a fresh appearance by mistake. Off by default (retail),
  under **/xloot → Loot Frame → Loot slots**.
- **"Upgrade" tag for higher item level.** Looted gear with a higher item level than what you
  already have equipped in that slot gets a green **(upgrade)** tag. Off by default, under
  **/xloot → Loot Frame → Loot slots**.
- **Vendor sell price in item tooltips.** On the Classic flavors (where the game doesn't show it),
  item tooltips can display the vendor sell price, including a stack's full value. Off by default,
  under **/xloot → Global options**. Retail already shows sell price, so the option is hidden there.
- **Test button for Group Loot.** The Group Loot options now have a Test button that spawns sample
  roll frames so you can preview them while adjusting, matching the Loot Monitor's test button.

### Bug Fixes
- **What's New popup.** Fixed the footer so the "Don't show these again" checkbox no longer overlaps
  the maintainer byline, and made the background fully opaque so it is easier to read.

## [12.8.3] - 2026-07-04

### Bug Fixes
- Extended the 12.8.2 secret-value protection to the loot window and the need/greed roll UI. During
  instanced encounters on Midnight (12.0), item links and their details can be "secret," and reading
  them (to compare, measure, or list) would throw a Lua error. The loot list, auto-loot filters,
  "Link All," and roll windows now detect secret values and degrade gracefully — a secret item still
  shows and is lootable, just without the extra detail. No effect on normal loot or on Classic clients.

## [12.8.2] - 2026-07-04

### Bug Fixes
- Fixed a Lua error ("attempt to index a secret string value") that could appear during
  instanced encounters on Midnight (12.0), such as the Midsummer Fire Festival boss. The
  Loot Monitor's message parser now detects the game's new protected "secret" values and
  skips them instead of erroring. Thanks to 40P3 for the report.

## [12.8.1] - 2026-07-03

### Bug Fixes
- Fixed a Lua error in **XLoot Group** when joining a group on Burning Crusade and other
  Classic clients, where the removed global `GetLootMethod` was called without a guard.
  XLoot now reads the loot method through `C_PartyInfo.GetLootMethod` and falls back to the
  old global. Thanks to Kai for the report.

### Features
- **Chat-link update notices.** After an update you can now get the What's New summary as a
  quiet, clickable link in chat instead of a popup — or turn notices off entirely. Choose
  under **/xloot → After an update** (Popup window / Chat link / None).

## [12.8.0] - 2026-07-02

### Features
- **Auto-loot by rarity.** A new option auto-loots any item at or above a quality you
  choose, whatever its type ("greed all greens" and better). Off by default; set it
  under **/xloot → Loot Frame → Auto-looting**.
- **Show gold from system messages.** The Loot Monitor can now show gold that the game
  only reports as a system message, such as world-quest rewards and gold purses
  (Sky Racer's Purse). Off by default; enable **System gold** under
  **/xloot → Loot Monitor → Filters**.
- **Hide Blizzard's loot pop-ups.** A new option silences the default loot toast alerts
  (the ones that pile up when you open lots of chests) while leaving achievement,
  recipe, and other non-loot alerts alone. Off by default, under
  **/xloot → Loot Monitor → Blizzard loot alerts**.
- **Right-click to dismiss Loot Monitor rows.** Right-click a loot row to remove it
  early; the rows below shift up to close the gap. The row fade times can also be set
  much longer now. Off by default.
- **Loot Frame font outline.** A new outline option for the item-name text under
  **/xloot → Loot Frame → Font**.
- **What's New popup.** After an update, a short summary of the new features shows once.
  Turn it off any time under **/xloot → Global options**, or with the popup's own
  "Don't show these again" checkbox.

### Bug Fixes
- Fixed leftover loot being stranded, with a Lua error when bags were full, if Speedy
  auto-loot could not fit everything at once. The remaining items now show correctly.

## [12.7.0] - 2026-07-01

### Features
- **Vendor sell price on loot rows.** A new option shows each item's total vendor value
  right on its row in the loot window. Off by default; turn it on under
  **/xloot → Loot Frame → Loot slots**.
- **Loot Monitor color options.** The Monitor can now match your class colors like the
  Loot Frame. Turn off **Color rows by item quality** to use your own **Row border
  color**, and optionally enable **Color all rows** to extend that color to coin and
  currency rows too. Unchanged by default.

### Bug Fixes
- Fixed a Lua error on every normal loot click on Burning Crusade and other Classic
  clients, where the retail-only `EventRegistry` does not exist.
- Fixed **XLoot Group** erroring at load on Classic clients that lack `C_LootHistory`.
  Roll windows continue to work as before.
- Fixed the roll-timer spark sliding past the end of the bar after a `/reload` in the
  middle of a roll.
- Fixed a "compare number with nil" error when a roll update arrived for a player who
  had not yet chosen a roll type.

### Improvements
- Added a mouseover tooltip explaining the Loot Monitor **Gradients** option.

## [12.6.0] - 2026-06-30

### Features
- **Speedy auto-loot** — a new option that vacuums a corpse the instant its loot is
  available, one item per server tick, without ever opening the loot window. The steady
  pacing avoids the "looting too fast" disconnect on big AoE pulls. Off by default; turn
  it on under **/xloot → Loot Frame → Auto-looting**.
  - A **"Only speedy-loot filtered items"** sub-option keeps the same instant, no-window
    behavior but grabs only the items your auto-loot rules match, leaving everything else
    in the loot window.
  - Hold your auto-loot modifier (Shift by default) while looting to skip Speedy for a
    single corpse, and it never runs under master loot.

## [12.5.0] - 2026-06-28

### Features
- **Master Loot is now available on retail (experimental).** Blizzard quietly brought
  master loot back in patch 12.0.5, but only on Chinese (CN) realms — so XLoot now
  includes a retail master-looter interface: assign loot from a right-click menu with
  class submenus, special recipients (self, banker, disenchanter), Request and Raid
  rolls, and chat announcements. Open its options with **/xlml**.
  - **Unverified on CN.** Because master loot is enabled on CN realms only and we
    can't test there, the live loot-assignment flow is experimental and unconfirmed;
    off a CN realm it simply stays inactive. CN-realm feedback — works or doesn't — is
    a big help.

## [12.4.1] - 2026-06-28

### Bug Fixes
- The options window (`/xloot`) no longer fails to open on a clean install with no
  other addons. XLoot now bundles the standard Ace3 configuration libraries instead
  of a variant that relied on another addon already being loaded.

### Features
- Restored the **Master Loot** module for the Classic flavors (Classic Era, Burning
  Crusade Classic, Mists of Pandaria Classic), where master loot still exists. It is
  off on retail, where Blizzard removed master loot in patch 8.0.1.

### Improvements
- XLoot now loads as up-to-date on every supported game version — retail, Classic
  Era, Burning Crusade Classic, and Mists of Pandaria Classic — instead of only
  retail.

## [12.4.0] - 2026-06-28

First stable release of the Midnight revival.

### Features
- Added a **Join our Discord!** button to the options Global page — clicking it
  shows a copyable community invite link (the game can't open a browser, so just
  press Ctrl+C). Come say hi!

## [12-3-alpha] - 2026-06-27

First CurseForge release of the Midnight revival.

### Features
- Gear and value auto-loot filters: automatically loot equippable items by minimum
  quality and item level, or any item by minimum total vendor value. Both are off by
  default. Thanks to Lorolas for the original contribution.
- Options you type into (sliders and text boxes) now show a "Press Enter to save" hint
  in their tooltip.

## [12-2] - 2026-06-27

### Bug Fixes
- Fixed a crash when coloring a player name whose class was missing from
  `CUSTOM_CLASS_COLORS` (could fire from the loot feed and from group rolls).
- Quest items in the loot window show their orange border again.
- Currency now shows its stack-count badge on the icon.
- Uncached loot no longer aborts the loot window — the row appears immediately and
  fills in its details a moment later.
- Loot-feed row highlights use the correct draw layer (was erroring on every row).
- Removed a self-recursive highlight-color call that could overflow the stack.
- Anchor positions/visibility now persist correctly across `/reload`.
- The `/xlgd` roll preview no longer breaks real loot rolls afterwards.
- Group roll bars now get the correct duration for rolls already in progress when you
  log in.
- Corrected the options "reset to defaults" wiring.

### Features
- Added a **Reset to Defaults** button (with confirmation) to the options Global page,
  since retail's Settings window no longer shows a Defaults button for addon panels.
- The item-level badge in the loot feed now appears only on equippable gear, not on
  consumables.

### Improvements
- Removed the Master Loot module (master loot was removed from retail in patch 8.0.1).
  The source remains in git history for a possible future Classic build.
- Modernized a deprecated item-level API call.
- Removed dead code, tidied several messages, and pointed bug reports at GitHub.
- Packaging: bumped the Group module's TOC to the 12.0 interface versions, rewrote
  `.pkgmeta` (dropped dead `svn://` externals), and added `.gitattributes` for
  consistent line endings.

## Revival baseline - 2026-06-26

First working build of the fork on retail 12.0.7 (commit `c84b87a`; untagged).

### Bug Fixes
- Fixed load-time crashes caused by master-loot globals that no longer exist on retail.
- Fixed the options panel failing to open on the modern Settings API.
- Fixed an options-apply crash involving the disabled Group module.

### Features
- Revived the Group roll prompt for retail (Need / Greed / Transmog / Pass,
  transmog-aware).

### Improvements
- Vendored the Ace3 libraries locally (the original fetched them from dead SVN URLs).
- Bumped the TOC interface to `120001, 120005, 120007`.
- Retired the Master module from the retail load path.
