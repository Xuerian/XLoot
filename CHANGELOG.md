# Changelog

XLoot is a revival fork of Xuerian's original addon, continued for retail World of
Warcraft **12.0.7 ("Midnight")**. This changelog starts at the revival; earlier
history lives in the original project's git tags.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

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
