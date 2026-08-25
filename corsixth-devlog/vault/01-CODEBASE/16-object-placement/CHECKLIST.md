# Pre-Fix Checklist: Object Placement Changes

## Before Making Any Changes to Object Placement System

### 1. Understand the Impact Scope
- [ ] Identify all object types affected (machines, furniture, corridors, side objects)
- [ ] Check if change affects `Object` base class or specific subclasses
- [ ] Verify impact on `processTypeDefinition` (load-time normalization)
- [ ] Consider save/load compatibility (`afterLoad` version handling)

### 2. Footprint Modifications
- [ ] **Tile Flags**: Verify `only_passable`, `complete_cell`, `optional`, `invisible`, `only_side` usage
- [ ] **Side Requirements**: Check `need_north_side`, `need_south_side`, `need_east_side`, `need_west_side`
- [ ] **Adjacent Tiles**: Ensure `adjacent_to_solid_footprint` is recalculated
- [ ] **Origin Shift**: Confirm footprint re-centering in `processTypeDefinition` still works
- [ ] **Optional Tiles**: Test room boundary and reachability conditions

### 3. Orientation System
- [ ] All 4 directions defined in `orientations` table
- [ ] Mirror fallback works via `orient_mirror` table
- [ ] `idle_animations` exist for each direction (or mirror)
- [ ] `early_list` flag set correctly for render ordering
- [ ] `animation_offset` and `render_attach_position` defined per direction

### 4. Use Positions
- [ ] `use_position` - primary interaction tile
- [ ] `use_position_secondary` - secondary interaction
- [ ] `slave_position` - for master-slave objects
- [ ] `finish_use_position` / `finish_use_position_secondary` - exit tiles
- [ ] `handyman_position` - single or multiple repair tiles
- [ ] `walk_in_tile` - for machines with `walk_in_to_use = true`
- [ ] All positions adjusted correctly during `processTypeDefinition` origin shift

### 5. Direction Parameter Mapping
- [ ] `directionParameters()` returns correct x/y offsets for all 4 directions
- [ ] Buildable flags (`buildableNorth`, etc.) match direction
- [ ] Passable flags (`travelNorth`, etc.) match direction
- [ ] Needed side flags (`need_north_side`, etc.) match direction
- [ ] Complementary flags work via `getComplementaryPassableFlag()`

### 6. Occupation/Deoccupation Logic
- [ ] `occupyTilesByObjectFootprintAt` sets flags correctly:
  - [ ] `buildable = false` on all footprint tiles
  - [ ] `passable = true` only on `only_passable` tiles
  - [ ] Directional `buildable<Dir> = false` for adjacent/needed sides
  - [ ] `only_side` tiles: passable flags on both tiles
- [ ] `deoccupyTilesByObjectFootprintAt` restores flags:
  - [ ] Re-enables `buildable<Dir>` for blocked directions
  - [ ] Restores `buildable = true` / `passable = true` if unclaimed
  - [ ] Handles `only_side` passable flag restoration
  - [ ] Checks `isTilePartOfNearbyObject` for passable tiles (10-tile radius)
- [ ] Special case: Trash bin (thob 50) east→west handled

### 7. Master-Slave Objects
- [ ] `slave_id` defined in object type
- [ ] `slave_position` defined per orientation
- [ ] Class uses `slaveMixinClass()`
- [ ] Slave created at `master_pos + slave_position`
- [ ] Slave destroyed with master (`onDestroy`)
- [ ] Slave moves with master (`setTile`)
- [ ] Slave orientation syncs with master (`initOrientation`)
- [ ] Event redirection: `onClick`, `updateDynamicInfo`, `getDynamicInfo`

### 8. Split Animations
- [ ] `render_attach_position` as table of tables for multi-tile render
- [ ] Each entry has `column` for crop
- [ ] `split_anims` created and positioned correctly
- [ ] `setPosition` offsets non-primary animations
- [ ] `setTile` places split animations on map
- [ ] `tick` advances all split animations

### 9. Type Definition Processing (`processTypeDefinition`)
- [ ] Defaults applied: `animation_offset`, `render_attach_position`
- [ ] `"passable"` use_position resolved to first `only_passable` tile
- [ ] `handyman_position` defaults to `use_position` if `default_strength`
- [ ] `pathfind_allowed_dirs` calculated from nearest solid tile
- [ ] Footprint re-centered on nearest solid tile to use_position
- [ ] All positions adjusted: use, secondary, finish, slave, render, smoke
- [ ] `render_attach_position` converted to screen coords for `animation_offset`
- [ ] `adjacent_to_solid_footprint` built for placement validation

### 10. Side Objects
- [ ] Class extends `SideObject`
- [ ] `getDrawingLayer()` returns correct layer per direction
- [ ] Footprint uses `only_side` tiles
- [ ] Passable flags set on both sides of tile edge
- [ ] `rebuildPassableCellFlags()` called on destroy
- [ ] Trash bin (thob 50) special case for east/west layers

### 11. Corridor Objects
- [ ] `corridor_object = 1` flag set
- [ ] Can be placed in corridors (not just rooms)
- [ ] `onClick` allows pickup in corridors

### 12. Save/Load Compatibility
- [ ] `afterLoad` handles version migrations
- [ ] Footprint re-initialized on load (version < 57)
- [ ] Couch fix for version < 173
- [ ] SideObject buildable flag reset on load

### 13. Testing Requirements
- [ ] Test all 4 orientations
- [ ] Test placement at map edges
- [ ] Test placement adjacent to other objects
- [ ] Test placement in rooms vs corridors
- [ ] Test master-slave pair placement/movement/destruction
- [ ] Test handyman pathfinding to `handyman_position`
- [ ] Test patient/staff pathfinding to `use_position`
- [ ] Test save/load cycle
- [ ] Test object rotation (pickup + re-place)
- [ ] Test optional tile conditions (room match, reachability)

### 14. Performance Considerations
- [ ] `isTilePartOfNearbyObject` radius (10 tiles) assumption valid
- [ ] Footprint iteration not excessive for large objects
- [ ] Split animation tick overhead minimal
- [ ] `clearCaches()` called appropriately on tile changes

### 15. Common Pitfalls to Avoid
- [ ] **Don't** forget to update `processTypeDefinition` when adding new position types
- [ ] **Don't** assume footprint origin is always (0,0) - it's normalized
- [ ] **Don't** mix world coordinates and tile offsets
- [ ] **Don't** forget `only_side` tiles need complementary passable flags
- [ ] **Don't** break mirror fallback for missing animations
- [ ] **Don't** place slave objects without `slaveMixinClass()`
- [ ] **Don't** forget `early_list` for objects that should render first
- [ ] **Don't** use `complete_cell` and `only_passable` on same tile

---

## Quick Reference: Critical Files

| File | Purpose |
|------|---------|
| `Lua/entities/object.lua:36-113` | Constructor, initOrientation |
| `Lua/entities/object.lua:113-187` | slaveMixinClass |
| `Lua/entities/object.lua:276-344` | Use position logic |
| `Lua/entities/object.lua:385-393` | directionParameters |
| `Lua/entities/object.lua:462-549` | occupyTilesByObjectFootprintAt |
| `Lua/entities/object.lua:551-607` | deoccupyTilesByObjectFootprintAt |
| `Lua/entities/object.lua:926-1047` | processTypeDefinition |
| `Lua/objects/bed.lua` | Simple 2-direction example |
| `Lua/objects/machines/operating_table.lua` | Master-slave example |
| `Lua/objects/machines/cast_remover.lua` | Complex footprint example |
| `Lua/objects/reception_desk.lua` | Corridor/side object example |

---

## Sign-Off

- [ ] Code review completed
- [ ] All tests pass (run `busted SCAFFOLD.lua`)
- [ ] Manual testing in-game for affected objects
- [ ] Save/load tested with existing savegames
- [ ] Performance profiled (no regressions)
- [ ] Documentation updated if API changed

**Reviewer:** _______________ **Date:** _______________
