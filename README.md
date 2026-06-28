# XLoot

[![Version](https://img.shields.io/github/v/release/Xuerian/XLoot?color=FF2222&label=Version)](https://github.com/Xuerian/XLoot/releases) [![Downloads](https://img.shields.io/curseforge/dt/14906?color=F16436&label=Downloads&style=flat-square)](https://www.curseforge.com/wow/addons/xloot) [![Discord](https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/vm8K2WfQUE) ![WoW Midnight](https://img.shields.io/badge/WoW-Midnight%2012.0.7-8B0000?style=flat-square) ![WoW BCC](https://img.shields.io/badge/WoW-BCC%202.5.5-8B0000?style=flat-square) ![WoW MoP Classic](https://img.shields.io/badge/WoW-MoP%20Classic%205.5-8B0000?style=flat-square) ![WoW Classic Era](https://img.shields.io/badge/WoW-Classic%20Era%201.15.8-8B0000?style=flat-square) [![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-333333?style=flat-square)](LICENSE.txt)

**XLoot is back.** After a long break, the addon has been revived and fully updated for
retail **World of Warcraft 12.0.7 ("Midnight")** — and now works across the Classic flavors
too. It's live and working again.

XLoot improves looting in WoW by replacing the default loot frames with cleaner, more
informative, and highly configurable ones. Every module is optional and can be toggled
like any other addon.

> _Live and working on Midnight (12.0.7). A few finishing touches remain — notably the
> Group roll-tracking display (see Modules) — so please report anything broken._

## Modules

- **XLoot Frame** — replaces the loot window. Quality borders, item level, one-click
  "link all" to chat, extensive appearance/skin options, and rule-based auto-looting:
  filter by category (currency, quest items, trade goods), by gear (minimum quality and
  item level), by total vendor value, by a custom item list, or just grab everything —
  each rule applying solo, in groups, always, or never.
- **XLoot Monitor** — a "toaster" loot feed for items you and others loot, so you can
  watch drops at a glance or move loot spam out of your chat box entirely.
- **XLoot Group** — Need / Greed / Transmog / Pass roll frames with a timer, updated for
  retail. The live roll-tracking display (who rolled what, current winner) is being
  rebuilt against Blizzard's new loot-history API; the roll buttons themselves work today.
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
- **/xlml** — open the Master Loot options (Classic flavors; experimental on retail CN).

Every option has a mouseover tooltip explaining what it does. Don't want a module?
Disable XLoot Frame / Monitor / Group / Master individually in the AddOns list.

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
