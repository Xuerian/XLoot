# XLoot — in-progress community fork

> **This is an in-progress community fork of [Xuerian's XLoot](https://github.com/Xuerian/XLoot),**
> continued with the original author's blessing and updated for retail World of
> Warcraft **12.0.7 ("Midnight")**. It is a work in progress — expect rough edges.

XLoot enhances World of Warcraft's loot UI: a customizable, skinnable loot window, a
loot feed/monitor, and (work in progress) group need/greed roll frames.

## Status

Current state on retail **12.0.7**:

- ✅ Loads and runs on 12.0.7; the loot window, loot feed, and options panel work.
- 🔶 The group roll UI is being rebuilt (Blizzard removed the loot-history API it used).
- ❌ The master-loot module is retired on retail (Blizzard removed master loot in 8.0.1).

## Credit & license

Original addon, design, and copyright belong to **Xuerian** — see
[LICENSE.txt](LICENSE.txt). This fork continues the project **with Xuerian's
permission**; all credit for the original work and years of maintenance is his.

## Installing from source (for testing)

The Ace3 libraries are bundled, so the repo loads as an addon with no extra
downloads. Either copy this folder into
`World of Warcraft/_retail_/Interface/AddOns/` named `XLoot`, or point a directory
junction there (no admin needed):

```cmd
mklink /J "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\XLoot" "<path to this repo>"
```
