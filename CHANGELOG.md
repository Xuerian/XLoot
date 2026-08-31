# Changelog

XLoot is a revival fork of Xuerian's original addon, continued for retail World of
Warcraft **12.1.0 ("Midnight")**. This changelog starts at the revival; earlier
history lives in the original project's git tags.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [12.17.0] - 2026-08-30

### Features
- **Color quest items in the loot feed.** The loot feed now colors quest items the same way the loot window
  does, finishing what 12.16.0 started. The item name, the row border and the icon border all take the color,
  and you can pick any color you like or tick "Use my class color". It covers both quest-type items and the
  ordinary drops your active quests ask you to collect. Quest items are shown even when they fall below your
  quality thresholds, so the setting works without having to lower them. Only your own loot is colored, and
  only items that come from a loot window - a quest reward handed straight to your bags is not. Off by
  default, under Loot Monitor > Colors. Suggested by Kharris.

### Bug Fixes
- The Loot Toast anchor no longer un-hides itself. Hiding it and then changing any setting brought it straight
  back, because opening the options panel put the anchor into a preview mode that outranked the anchor's own
  hide button on every later change. The saved setting is now the only thing that decides, matching the Loot
  Monitor and roll anchors. One consequence worth knowing: opening the options panel no longer reveals a
  hidden Toast anchor, so use Loot Toast > Anchor > "Anchor visible" to bring it back.
- Roll results no longer stop at the first finished roll. When a roll finished while an earlier roll's bar was
  still on screen, the second one never got a winner, because the search gave up as soon as it met a bar it
  had already filled in. Classic flavors only.
- A roll no longer errors when somebody never chooses. A player still deciding when the roll completed
  reported no roll type, which the winner comparison could not handle. Classic flavors only.
- The winning type icon now actually appears. The dice, coin and disenchant icons shown next to the winner's
  name were compared against the wrong kind of value and could never match, so "Show winning type icon" had no
  effect at all. Classic flavors only.
- The roll test command no longer hides your real loot history. After running /xlgd, its practice entries sat
  in front of the real ones for the rest of the session, so genuine roll results stopped appearing entirely
  until you reloaded. Classic flavors only.

## [12.16.0] - 2026-08-20

### Features
- **Color quest items in the loot window.** Quest items can now take a color of their own on both the
  item name and the row border, so they stand out the moment the window opens. Pick any color you like,
  or tick "Use my class color" to use your class color instead. It covers both quest-type items and the
  ordinary drops your active quests ask you to collect - the game's own quest flag only marks the first
  kind, so XLoot also reads your quest log's item objectives. Off by default, under Loot Frame > Colors.
  The loot feed will get the same treatment in a following update. Suggested by Kharris.

## [12.15.0] - 2026-08-16

### Features
- **Leave fishing catches alone.** A new switch under Speedy auto-loot stops XLoot taking your fishing
  loot, so the normal loot window opens for it instead. Speedy empties the bobber faster than some
  fishing tracker addons can read the catch, which left them quietly missing fish. Everything that is
  not a fishing catch still auto-loots exactly as before. Off by default, under Loot Frame >
  Auto-looting. Reported by Addonman.

## [12.14.4] - 2026-08-15

### Bug Fixes
- Roll rows no longer leave a hole in the list. When a roll ended from the middle of the stack, the rows below
  it stayed where they were instead of closing up, and a row reused for a later roll could reappear in the gap
  it left behind rather than in its place in the list.
- A roll waiting on its result no longer lingers after the game clears its loot history. The result it was
  waiting for could never arrive, but the bar sat there for a full six minutes before giving up on its own.
  Retail only, and only with "Show roll results" turned on.
- A roll row that fails to finish building can no longer act on the wrong item. The roll's identity and timer
  are now set the moment the row appears rather than most of the way through, so an error while filling in the
  rest of the row can no longer leave it carrying the previous roll's id, counting down against a finished
  roll, or closing itself moments after opening. Nothing between those two points could throw on a healthy
  client, but two of the calls that sat in the gap reach outside XLoot, one of them into Pawn.

## [12.14.3] - 2026-08-12

### Bug Fixes
- Loot rolls work again on retail patch 12.1.0. The patch removed a game function XLoot used to grey out
  the roll buttons you are not eligible for, and every roll then failed partway through setting itself up.
  The item icon stayed blank, the timer bar never started, and the roll either closed itself moments later
  or did nothing when you clicked it. Reported by Addonman.
- The options window no longer errors on its first checkbox on 12.1.0. The bundled Ace3 checkbox widget
  used that same removed function, and has been updated to the current version.
- Fixed errors on 12.1.0 when holding a modifier key over the loot window, a roll bar, the loot monitor, or
  a toast, and when the same item was looted twice in quick succession. Those used a second function the
  patch removed.

## [12.14.2] - 2026-08-11

### Bug Fixes
- A master-loot raid roll that never finished no longer lingers. If the loot window closed part way
  through, or the result never arrived, XLoot kept waiting indefinitely, and the next loot window you
  opened could have an item handed out from the old roll. XLoot now stops waiting when the loot window
  closes, gives up on its own after fifteen seconds, and tells you when a roll was discarded.

### Improvements
- Master loot now sends its announcements through the same chat path as the rest of XLoot, the one
  hardened against the "secret value" errors that 12.0 introduced in instanced encounters.

## [12.14.1] - 2026-08-06

### Bug Fixes
- Switching, copying, or resetting an XLoot profile now applies it everywhere. XLoot mistook the name of
  the profile event for a signal that its options window was open, so it tried to refresh the options
  preview before that preview existed and errored partway through, leaving part of the addon still running
  on the profile you switched away from until you reloaded.
- The loot window preview in the options no longer comes out the wrong height when one of its sample items
  has not finished loading. The currency rows were recorded at the wrong position, which left a gap in the
  list the preview measures itself from.

### Improvements
- Changing options is lighter on the game. Every skinned frame in the addon was being restyled twice for
  each change, which on a slider meant about ten times a second while you dragged it.
- The three "Track" options and the "Minimum quality" setting under Group Loot > What rolls to show are now
  hidden on retail, where they have no effect. Retail shows who rolled and who won through "Show roll
  results" instead. Nothing changed on Classic, and any values you had saved are kept.

## [12.14.0] - 2026-08-02

### Features
- **Minimap icon.** XLoot can now put a coin button on your minimap. Left-click opens XLoot's options,
  right-click brings up What's New, and you can drag it anywhere around the minimap edge. Turn it on with
  the new "Minimap icon" switch in Global options. Off by default.
- **Broker support.** XLoot now offers itself to broker displays such as Titan Panel, ChocolateBar, and
  ElvUI's datatexts, so you can put it on a bar instead of the minimap if you prefer. This works whether
  or not the minimap icon itself is switched on.

### Bug Fixes
- Auto-loot filters now work on items you are seeing for the first time. The gear, value, and trade goods
  filters need item details the game has not downloaded yet the first time an item drops, so until now
  they silently skipped every new item until you had already seen it once that session. XLoot now takes a
  second look once the details arrive.
- Items that would not fit in your bags are no longer left without a row in the loot window when Speedy
  auto-loot is filtering. If your bags filled up partway through looting, the leftovers stayed on the
  corpse with nothing shown for them.
- The loot window no longer opens in the wrong place after Speedy auto-loot leaves something behind. It
  could appear at an unset position instead of at your cursor.
- Crafting reagents are now auto-looted into your reagent bag on retail when your normal bags are full.
  The free space check never looked at the reagent bag, so a reagent that would have fitted was left behind.
- Auto-loot item lists now match names written with spaces around the commas. "Silk Cloth , Linen Cloth"
  kept the trailing space as part of the name, so that entry never matched anything.

### Improvements
- Two Global option labels were shortened so the panel fits them on one row: "Apply to anchors" is now
  "Skin anchors" and "Item values as coin icons" is now "Coin icons". Both still explain themselves in
  full when you mouse over them, and neither changed what it does.

## [12.13.2] - 2026-07-29

### Bug Fixes
- Fixed an error every time you moused over a roll window or its Need, Greed, or Pass buttons on Classic
  clients that do not have the loot history API. The roll tooltip asked that API who had rolled without
  first checking it existed, so the hover threw an error instead of showing the tooltip.
- Switching XLoot profiles no longer breaks master loot. The Master module kept reading the profile you
  switched away from, which is emptied out on a switch, so the next award failed with an error until you
  reloaded. It now picks up the new profile straight away, on both Classic and retail.
- Fixed the Classic raid roll handing the item to the wrong player. If anyone in the raid could not receive
  loot, such as being out of range, the announced list of names no longer lined up with the numbers being
  rolled on, so the winning number picked a different player than the one announced, and with enough
  ineligible members the roll could error out and never start at all. The roll now announces and awards from
  the same list, and only accepts a roll result that matches the raid roll it started.
- A raid roll can no longer be resolved by an unrelated `/roll`. The old code left itself listening for roll
  results after a failed raid roll, so a later manual roll could hand out the item.
- Master loot now tells you when the player you picked can no longer receive the item, such as leaving the
  group while the confirmation was open, instead of silently doing nothing.

## [12.13.1] - 2026-07-23

### Bug Fixes
- The `/xlgd` roll preview no longer shows its test items in place of real loot rolls. The preview handed its
  fake rolls low ids that could collide with real loot-roll ids, so after previewing, a real drop whose id
  matched could display a test item instead of the real drop and not roll. The preview now uses ids far
  outside the real range and clears each one when its frame closes. Reported by RoadBlock.

### Improvements
- The "What's New" popup now has a solid background instead of a see-through one.
- TOC bumps for Classic Era 1.15.9 and TBC 2.5.6.

## [12.13.0] - 2026-07-16

### Features
- **Roll results on retail.** The Group Loot roll window can show who rolled and who won again. Roll counts
  build up on the Need, Greed, and Transmog buttons as your group rolls, then the window names the winner in
  their class color with the winning roll type's icon, or shows "Pass: All" when nobody wanted it. Retail
  closes your roll the moment you choose but does not decide it until everyone has rolled, so the window now
  waits for the result instead of disappearing, showing the current leader while it waits. Off by default,
  under Group Loot > What rolls to show. Classic already had this and is unchanged. `/xlgd` previews it.

### Bug Fixes
- Fixed retail roll windows starting with a partly filled timer bar instead of a full one. XLoot was reading
  a value Blizzard passes with the roll event as its own "roll resumed after a reload" flag, which replaced
  the roll's real length with an assumed one. Rolls longer than three minutes happened to mask it.

### Improvements
- The Group Loot roll tracking options now describe themselves on mouseover: "Track all rolls", "Track items
  you roll on", "Track items by minimum quality", and the two expiration sliders. The "Track all rolls"
  tooltip also no longer appears far off to the side of the option.

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
