# tdInspect Project Guidelines

## Architecture

- **Namespace**: `ns` via `local ns = select(2, ...)` — all addon state lives here
- **OOP**: `ns.Addon:NewClass('UI.ClassName', BaseClass)` via LibClass-2.0
  - Create instances: `:New(...)` (new frame) or `:Bind(existingFrame, ...)` (wrap existing)
  - UI classes auto-register to `ns.UI.ClassName` via `OnClassCreated`
- **Modules**: `ns.Addon:NewModule('Name', ...)` → auto-assigned to `ns.Name`
- **Events**: `self:Event('EVENT_NAME')` / `self:UnAllEvents()` from `ns.Events` mixin — never use raw `self:RegisterEvent`

## File Conventions

- Header comment block at top of every file: `-- FileName`, `-- @Author`, `-- @Link`, `-- @Date`
- Use `local ns = select(2, ...)` (not `local ADDON, ns = ...`)
- Localize WoW globals at file top: `local tinsert, wipe = table.insert, wipe`
- Localization: `local L = ns.L` then `L['key']`
- Version gates: `ns.BUILD` = WoW major version (1=Vanilla, 2=TBC, 3=Wrath, 4=Cata, 5=MoP)

## UI Frame Patterns

- New frame class: `ns.Addon:NewClass('UI.Name', 'Frame')`
- Create instance: `MyClass:Create(parent)` → `self:Bind(CreateFrame('Frame', nil, parent, 'TemplateName'), ...)`
- Backdrop (match existing): `bgFile=UI-Tooltip-Background, edgeFile=UI-Tooltip-Border, tileSize=8, edgeSize=16`
- Positioning: `TapTo(frame, 'TOPRIGHT')` pattern — see `GearFrame:TapTo` in `UI/GearFrame.lua`
- Lifecycle: register events in `OnShow`, unregister all in `OnHide` with `self:UnAllEvents()`
- Lazy-load frames in `Addon.lua` with `GetXxxFrame()` pattern (see `GetCharacterGearFrame`)

## Data Access

- Item links (player): `GetInventoryItemLink(unit, slot)`
- Item links (inspect target): `ns.Inspect:GetItemLink(slot)`
- Gem IDs from link: `ns.GetItemGems(link)` → `{itemId, ...}`; single gem: `ns.GetItemGem(link, index)`
- Socket type per slot: `ns.GetItemSocket(link, index)` → socketType (1=meta, 2=red, 3=yellow, 4=blue, 5=prismatic)
- Socket count: `ns.GetNumItemSockets(link)`
- Enchant info: `ns.GetItemEnchantInfo(link)` → `{spellId, itemId, ...}` or nil
- Gem color/class: `select(6, GetItemInfoInstant(gemId))` → classId, subClassId
- Set ID from item: `select(16, GetItemInfo(link))` → setId
- Set data: `ns.ItemSets[setId].bouns` (thresholds array), `ns.ItemSets[setId].slots`
- Set equipped: `ns.Inspect:GetEquippedSetItems(setId)` → count, items table

## Build & Load Order

- New UI files go in `tdInspect.toc` after `UI\Template.xml`
- `[AllowLoadGameType Vanilla]` etc. for version-specific data files
- No automated test runner; testing is manual in-game

## Localization

- `Localization/enUS.lua`: new key → `L['key'] = true` (identity)
- `Localization/zhCN.lua`: new key → `L['key'] = '中文'`
- Use English display string as the key
