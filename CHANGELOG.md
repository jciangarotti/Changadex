# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.4] - 2026-04-18

### Added
- Sidebar button: a Changadex icon is appended at the bottom of the
  left-side vertical icon column (the one hosting Inventory / Health /
  Crafting / ...). Clicking it toggles the collection window — same
  behaviour as pressing the bound key.

### Fixed
- Auto-discovery now actually triggers on regular inventory transfers.
  Previously the mod hooked `OnContainerUpdate`, but PZ only fires that
  event for a handful of paths (vehicles, foraging, moveables, BBQ) —
  not for the normal drag-and-drop / "grab" / "loot all" flow. Replaced
  with a throttled `OnPlayerUpdate` scan (500 ms) that catches every
  item that ends up in the player's inventory tree regardless of how it
  got there.

## [0.7.3] - 2026-04-18

### Changed
- Tooltip indicator redesigned: instead of a corner badge, the inventory
  hover tooltip now appends a row styled like the native fields —
  `Discovered: Yes` (green) or `Discovered: No` (red).

## [0.7.2] - 2026-04-18

### Added
- Inventory tooltip now shows a discovery badge in its top-right corner:
  green if the item has been discovered, gray otherwise. (Superseded in
  0.7.3.)

## [0.7.1] - 2026-04-18

### Added
- Auto-discovery restored for the inventory path: anything that lands in
  your inventory — including items inside nested bags, at any depth — is
  marked as discovered.
- Level-up-style halo text appears above the character with the item's
  name on every new discovery.

### Changed
- The initial inventory scan on game load now runs silently (no halo text
  spam for items you already owned before the mod was installed).

## [0.7.0] - 2026-04-18

Major rework of how discoveries happen. The old action-based model (eat /
read / wear / equip / watch / listen) is gone. Discovery now flows through
the context menu with a clickable option and opens an info card.

### Added
- Context menu option **Discover** on undiscovered items: marks them and
  opens the info window.
- Context menu option **View info** on already discovered items: reopens
  the info window.
- New `ChangadexInfoWindow` popup with the item icon, localized name,
  category label and a category-derived flavor description.
- Left-click on a discovered cell in the main window opens the same info
  card.
- Per-category flavor descriptions (localized EN / ES).

### Changed
- State schema bumped to v2. Existing `ModData` is migrated automatically
  on load: the per-title table (magazines / newspapers) and the
  per-discovery `how` / `name` fields are dropped, keeping only the
  discovery timestamp.
- Main grid no longer shows the verb ("Read", "Eaten", ...) under each
  item — it now just shows the item's name centered next to the icon.

### Removed
- `OnContainerUpdate` / `OnEquipPrimary` / `OnEquipSecondary` /
  `OnClothingUpdated` hooks (auto-discovery by pickup / equip / wear).
- `ISReadABook:perform` / `ISEatFoodAction:complete` /
  `ISDeviceMediaAction:complete` timed-action patches.
- Per-title tracking for magazines and newspapers.
- Halo text notification (temporarily — re-added in 0.7.1 with a new
  code path).
- The context menu no longer shows a greyed-out informational line — the
  options are all clickable now.

## [0.6.1] - initial release

Base Changadex. Items get discovered automatically based on how you
interact with them:

- Weapons / tools / clothing / materials → on pickup.
- Food / drink → when eaten or drunk (`ISEatFoodAction`).
- Books / magazines / newspapers / flyers → when read
  (`ISReadABook`).
- VHS / CDs → when inserted into a VCR, radio or TV
  (`ISDeviceMediaAction`).

Magazines and newspapers are tracked per title. Halo text pops up on
every new discovery. Right-click on an item surfaces an informational
(non-clickable) line describing what action is still needed to discover
it. Main window has a category sidebar with per-category progress bars,
filters (all / only discovered / only missing) and a text search.
