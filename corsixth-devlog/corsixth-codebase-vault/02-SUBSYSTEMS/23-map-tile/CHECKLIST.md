# Map/Tile System - Pre-Fix Checklist (Area 23)

## Overview
This checklist must be completed before making any changes to the Map/Tile system (Lua/map.lua, Lua/entity_map.lua, Src/th_map.h, Src/th_map.cpp, Lua/world.lua map-related functions).

---

## 1. Code Understanding & Impact Analysis

### 1.1 Core Map Files
- [ ] Read and understand `Lua/map.lua` (965 lines) - Lua extensions to C++ THMap
- [ ] Read and understand `Src/th_map.h` (620 lines) - C++ level_map class definition
- [ ] Read and understand `Src/th_map.cpp` - C++ implementation (1500+ lines)
- [ ] Read and understand `Lua/entity_map.lua` (218 lines) - Entity tracking on map
- [ ] Read and understand `[[Lua/world.lua#L2293]]-2305` - getObject at coordinates

### 1.2 Key Data Structures
- [ ] `map_tile_flags` (th_map.h:118-179) - 22 boolean flags per tile
- [ ] `map_tile` (th_map.h:196-240) - Tile layers, parcel/room IDs, temperature, objects
- [ ] `level_map` (th_map.h:254-477) - Main map class with parcels, pathfinding, rendering
- [ ] `Map` Lua class (map.lua:22-965) - Game-level map management

### 1.3 Critical Algorithms
- [ ] Tile flag parsing/serialization (th_map.cpp:52-261)
- [ ] Map loading from TH format (th_map.cpp:390-537)
- [ ] Parcel ownership & divider walls (th_map.cpp:668-722)
- [ ] Adjacency/purchase matrices (th_map.cpp:742-823)
- [ ] Pathfinding update (th_map.cpp:1410-1445)
- [ ] Shadow calculation (th_map.cpp:1459-1487)
- [ ] Temperature diffusion (th_map.cpp:1298-1408)
- [ ] Rendering pipeline (th_map.cpp:964-1214)
- [ ] Save/load persistence (th_map.cpp:1489-1522+)

---

## 2. Test Coverage Verification

### 2.1 Existing Tests
- [ ] Check `Tests/` directory for existing map/tile tests
- [ ] Verify SCAFFOLD.lua covers: tile flags, room detection, parcel pricing, camera, temperature
- [ ] Run existing test suite: `busted Tests/`
- [ ] Document any failing tests before changes

### 2.2 Test Scenarios to Validate
- [ ] Tile flag get/set round-trip
- [ ] Room ID queries at boundaries
- [ ] Parcel price calculation (with/without config)
- [ ] Camera/heliport positioning for 1-4 players
- [ ] Temperature display methods (1, 2, 3)
- [ ] Debug overlays (heat, parcel, camera, heliport, flags)
- [ ] World↔Screen coordinate conversion (inverse property)
- [ ] Plot ownership changes & wall updates
- [ ] Map loading (original, custom, editor, blank)
- [ ] Save/load persistence (prepareForSave/afterSave)
- [ ] _fixTiles for original campaign & level 6
- [ ] afterLoad migrations (versions 5, 17, 43, 56, 119, 161, 164, 175, 187, 209, 217)
- [ ] EntityMap add/remove/query operations

---

## 3. Dependency Mapping

### 3.1 Lua → C++ Calls (map.lua → th_map.h)
| Lua Method | C++ Method | Line (map.lua) | Line (th_map.h) |
|------------|------------|----------------|-----------------|
| getCellFlag | getCellFlags | 55 | 375 |
| getRoomId | getRoomId | 63 | - |
| setPlayerCount | set_player_count | 67 | 301 |
| getPlayerCount | get_player_count | 71 | 299 |
| setCameraTile | set_player_camera_tile | 79 | 305 |
| setHeliportTile | set_player_heliport_tile | 87 | 306 |
| setTemperatureDisplayMethod | set_temperature_display | 99 | 293 |
| size | get_width/get_height | 252 | 291/294 |
| getPlotCount | get_parcel_count | 255 | 297 |
| getParcelTileCount | get_parcel_tile_count | 256 | 309 |
| setPlotOwner | set_parcel_owner | 258 | 321 |
| updatePathfinding | update_pathfinding | 370 | 281 |
| save | save | 378 | 265 |
| load/loadBlank | load_from_th_file/load_blank | 193/221 | 260/261 |
| setSheet | set_block_sheet | 649 | 272 |
| setCellFlags | (direct flag manipulation) | 653 | - |
| getCell | get_tile | 326 | 375 |
| getCellTemperature | get_tile_temperature | 532 | 382 |
| getCellRaw | (raw array access) | 623 | 239 |
| draw | draw | 729 | 360 |

### 3.2 Cross-Module Dependencies
- [ ] `Lua/world.lua` → `Map:getRoomId`, `Map:getCellFlag`
- [ ] `Lua/entity_map.lua` → `Map.th:size()`
- [ ] `Lua/ui.lua` → Map drawing, coordinate conversion
- [ ] `Lua/room.lua` → Map parcel/room queries
- [ ] `Lua/object.lua` → Map tile queries
- [ ] `Lua/humanoid.lua` → Pathfinding, tile flags
- [ ] Save/load system → Map persistence

---

## 4. Risk Assessment

### 4.1 High Risk Changes
- [ ] Tile flag bit manipulation (th_map.cpp:52-261) - affects pathfinding, building, rendering
- [ ] Parcel ownership logic (th_map.cpp:668-722) - affects game economy, building placement
- [ ] Pathfinding update (th_map.cpp:1410-1445) - affects all humanoid movement
- [ ] Temperature diffusion (th_map.cpp:1298-1408) - affects comfort, radiators
- [ ] Map loading (th_map.cpp:390-537) - affects level compatibility
- [ ] Rendering pipeline (th_map.cpp:964-1214) - visual correctness

### 4.2 Medium Risk Changes
- [ ] Coordinate conversion (map.lua:117-142, th_map.h:386-399)
- [ ] Debug overlay system (map.lua:467-632)
- [ ] Parcel pricing (map.lua:779-794)
- [ ] Camera/heliport positioning (map.lua:74-88)
- [ ] _fixTiles corrections (map.lua:798-854)
- [ ] afterLoad migrations (map.lua:856-965)

### 4.3 Low Risk Changes
- [ ] Debug text/helpers (map.lua:661-676)
- [ ] Temperature display method validation (map.lua:93-100)
- [ ] Lua-only helper functions

---

## 5. Pre-Change Validation

### 5.1 Run Before Any Edit
- [ ] `make clean && make` - clean build
- [ ] `busted Tests/` - full test suite passes
- [ ] Launch game, load original level 1 - verify playable
- [ ] Launch game, load custom level - verify playable
- [ ] Test map editor mode - verify blank map loads
- [ ] Test save/load cycle - verify persistence

### 5.2 Specific Functionality Checks
- [ ] Build room on parcel 1 - verify walls, pathfinding
- [ ] Purchase parcel 2 - verify divider walls appear
- [ ] Place radiator - verify temperature diffusion
- [ ] Move camera - verify coordinate conversion
- [ ] Enable debug overlays (flags, heat, parcels) - verify display
- [ ] Multiplayer (2-4 players) - verify camera/heliport per player

---

## 6. Change Implementation Guidelines

### 6.1 C++ Changes (th_map.h/cpp)
- [ ] Maintain binary compatibility for save files (persist version)
- [ ] Update `persist()`/`depersist()` for new fields
- [ ] Run `make test` for C++ unit tests
- [ ] Check for memory leaks (valgrind/ASAN)
- [ ] Verify parcel_count/plot_owner array bounds

### 6.2 Lua Changes (map.lua, entity_map.lua)
- [ ] Maintain API compatibility for other Lua modules
- [ ] Update SCAFFOLD.lua with new test cases
- [ ] Document any new public methods with `---@` annotations
- [ ] Test with `strict.lua` if available

### 6.3 Cross-Language Changes
- [ ] Keep Lua/C++ flag definitions in sync (map_tile_flags::key enum)
- [ ] Verify coordinate systems match (0-based C++, 1-based Lua)
- [ ] Test Lua→C++→Lua round trips

---

## 7. Post-Change Validation

### 7.1 Automated Tests
- [ ] Run full test suite: `busted Tests/`
- [ ] Run SCAFFOLD.lua specific tests: `busted SCAFFOLD.lua`
- [ ] Run C++ tests: `./test_runner` (if available)

### 7.2 Manual Regression Tests
- [ ] Load each original campaign level (1-12)
- [ ] Test all difficulty modes (easy, full, hard)
- [ ] Test custom level loading
- [ ] Test map editor
- [ ] Test save/load at various game states
- [ ] Test multiplayer map sync

### 7.3 Performance Checks
- [ ] Map rendering FPS (large maps, many entities)
- [ ] Pathfinding calculation time
- [ ] Temperature update tick time
- [ ] Memory usage for map tiles (128x128 = 16384 tiles)

---

## 8. Rollback Plan

- [ ] Tag git commit before changes: `git tag pre-map-tile-changes`
- [ ] Document exact files modified
- [ ] Keep backup of working build
- [ ] Test rollback procedure: `git checkout pre-map-tile-changes`

---

## 9. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer | | | |
| Code Reviewer | | | |
| QA Lead | | | |

---

## 10. Related Areas (for cross-reference)
- Area 07: World/Room Systems (room.lua)
- Area 12: Pathfinding (humanoid movement)
- Area 15: Temperature/Comfort Systems
- Area 18: Save/Load System
- Area 21: UI/Map Rendering
- Area 25: Campaign/Level Loading


## Related Pages

- [[MAP]]
- [[SUMMARY]]
