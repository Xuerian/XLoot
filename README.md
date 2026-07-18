# XLoot

[![Version](https://img.shields.io/github/v/release/Xuerian/XLoot?color=FF2222&label=Version)](https://github.com/Xuerian/XLoot/releases) [![Downloads](https://img.shields.io/curseforge/dt/14906?color=F16436&label=Downloads&style=flat-square)](https://www.curseforge.com/wow/addons/xloot) [![Discord](https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/vm8K2WfQUE) ![WoW Midnight](https://img.shields.io/badge/WoW-Midnight%2012.0.7-8B0000?style=flat-square) ![WoW BCC](https://img.shields.io/badge/WoW-BCC%202.5.5-8B0000?style=flat-square) ![WoW MoP Classic](https://img.shields.io/badge/WoW-MoP%20Classic%205.5-8B0000?style=flat-square) ![WoW Classic Era](https://img.shields.io/badge/WoW-Classic%20Era%201.15.8-8B0000?style=flat-square) [![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-333333?style=flat-square)](LICENSE.txt)

**XLoot is back.** After a long break, the addon has been revived and fully updated for
retail **World of Warcraft 12.0.7 ("Midnight")** — and now works across the Classic flavors
too. It's live and working again.

XLoot improves looting in WoW by replacing the default loot frames with cleaner, more
informative, and highly configurable ones. Every module is optional and can be toggled
like any other addon.

> _Live, stable, and in active use on Midnight (12.0.7) and all current Classic flavors.
> Please report anything broken._

## Modules

- **XLoot Frame** — replaces the loot window. Quality borders, item level, an optional
  per-item vendor sell price (as text or gold/silver/copper coin icons, and in item
  tooltips on the Classic flavors), **(new look)**
  and **(upgrade)** tags flagging uncollected appearances and item-level upgrades,
  one-click "link all" to chat (or automatic announce when the window opens), extensive
  appearance/skin options, and rule-based auto-looting: filter by category (currency,
  quest items, trade goods), by rarity (everything at or above a quality you choose), by
  gear (minimum quality and item level), by total vendor value, by a custom item list, or
  just grab everything — each rule applying solo, in groups, always, or never.
  **Speedy auto-loot** can instead vacuum a corpse instantly with no loot window (paced to
  avoid the fast-loot disconnect on big pulls), optionally limited to only your filtered
  items.
- **XLoot Monitor** — a "toaster" loot feed for items you and others loot, so you can
  watch drops at a glance or move loot spam out of your chat box entirely. Shows item
  level, stack counts, quality coloring, and how many of an item you already own; can
  surface gold the game only reports as a system message (world-quest rewards, gold
  purses), match your class colors, hide Blizzard's own loot pop-ups so they don't pile
  up, and lets you right-click a row to dismiss it, with adjustable fade times.
- **XLoot Toast** _(new)_ — a Blizzard-style pop-up toast for notable loot as you receive
  it: item icon, quality-colored name, and a counting-up quantity, with same-item
  pickups coalescing onto one "+N" toast. Configurable quality threshold, item level, max on
  screen, fade time, spawn animation, sound, coloring, font, a movable anchor, and how toasts
  respond to the mouse (fully clickable, click-through, or click-through until Shift is held). When enabled it
  also hides Blizzard's own duplicate loot toast so you see only one. Off by default;
  **/xltd** previews it. Uses the Monitor's loot detection, so keep Monitor enabled for toasts.
- **XLoot Group** — Need / Greed / Transmog / Pass roll frames with a timer. On retail the
  window now **shows who rolled and who won** again: roll counts build on the buttons, then it
  names the winner in their class color (or "Pass: All"), waiting for the result rather than
  vanishing the moment you choose (the Classic flavors always had this). Optional roll-frame
  **highlight** (green upgrade / blue uncollected appearance), **per-item auto-roll** rules set
  by Shift-clicking a roll button, and an **urgent timer** that reddens as the roll runs out.
- **XLoot Master** — a configurable master-looter interface: assign loot from a right-click
  menu, with class submenus, special recipients (banker, disenchanter, self), raid rolls, and
  award announcements. Fully supported on the **Classic flavors**, where master loot has always
  existed. Blizzard brought master loot back to **retail in 12.0.5 — but only on Chinese (CN)
  realms** — so XLoot now includes a retail path too. ⚠️ **The retail path is experimental and
  unverified:** none of us can log into a CN realm to test the live loot-assignment flow, so on
  retail it's unconfirmed. CN-realm feedback (works or doesn't) is very welcome. Open its options
  with **/xlml**.

## Using XLoot

- **/xloot** — open the options (also under Game Menu → Options → AddOns → XLoot).
- **/xlm** — toggle the Monitor anchor to drag the loot feed where you want it.
- **/xlg** — toggle the Group anchor to position the roll frames.
- **/xltd** — preview a few toasts to position the Toast anchor and try the settings.
- **/xlgd** — preview sample roll frames, including the roll-results display.
- **/xlml** — open the Master Loot options (Classic flavors; experimental on retail CN).

Every option has a mouseover tooltip explaining what it does. Don't want a module?
Disable XLoot Frame / Monitor / Toast / Group / Master individually in the AddOns list.

After an update, XLoot can show a short **What's New** summary — as a popup, a quiet
clickable chat link, or nothing at all (your choice under **/xloot → After an update**).
New features ship **off by default**, so an update never changes how your looting behaves
until you turn something on.

## Installing

XLoot lives on [CurseForge](https://www.curseforge.com/wow/addons/xloot). To run it from
source instead (for testing or contributing), the Ace3 libraries are bundled, so the repo
loads with no extra downloads — either copy this folder into
`World of Warcraft/_retail_/Interface/AddOns/` named `XLoot`, or point a directory
junction there (no admin needed):

```cmd
mklink /J "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\XLoot" "<path to this repo>"
```

## Reporting issues

Please check the [issue tracker](https://github.com/Xuerian/XLoot/issues) and open a new
issue if your problem isn't already reported. You can also join the
[community Discord](https://discord.gg/vm8K2WfQUE) for help, feedback, and updates.

## Credit & license

XLoot was created and maintained for years by **Xuerian** — all credit for the original
work is his. This revival continues the project **with his blessing**, and is now
maintained by [wheelbarrel00](https://github.com/wheelbarrel00). See
[LICENSE.txt](LICENSE.txt).

If you'd like to support the project, there's a
[Donate button on the WoWAce page](https://www.wowace.com/projects/xloot).
