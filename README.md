# XLoot

**XLoot is back.** After a long break, the addon has been revived and fully updated for
retail **World of Warcraft 12.0.7 ("Midnight")**. It's live and working again.

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

> _XLoot Master has been retired — Blizzard removed master loot from retail in patch
> 8.0.1. Its source remains in git history for a possible future Classic build._

## Using XLoot

- **/xloot** — open the options (also under Game Menu → Options → AddOns → XLoot).
- **/xlm** — toggle the Monitor anchor to drag the loot feed where you want it.
- **/xlg** — toggle the Group anchor to position the roll frames.

Every option has a mouseover tooltip explaining what it does. Don't want a module?
Disable XLoot Frame / Monitor / Group individually in the AddOns list.

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
