# CorsixTH Map/Tile System - Comprehensive Technical Reference

## Overview

The CorsixTH map/tile system is a dual-layer architecture comprising a **C++ core** (`level_map` class in `th_map.h/.cpp`) and a **Lua wrapper** (`Map` class in `map.lua`). The C++ layer handles low-level tile data, rendering, pathfinding, serialization, temperature simulation, and parcel management. The Lua layer provides high-level map loading, configuration, camera control, and debug utilities.

---

## 1. C++ Core: `level_map` Class (`Src/th_map.h`, `Src/th_map.cpp`)

### 1.1 Data Structures

#### `map_tile` (th_map.h:196-240)
The fundamental unit of the map. Each tile contains:

| Field | Type | Description |
|-------|------|-------------|
| `entities` | `link_list` | Linked list of entities rendered at this tile (late pass) |
| `oEarlyEntities` | `link_list` | Linked list for early render pass (right-to-left) |
| `tile_layers[4]` | `uint16_t[4]` | Sprite indices + draw flags per layer: ground(0), north_wall(1), west_wall(2), ui(3) |
| `iParcelId` | `uint16_t` | Parcel/plot ownership ID (0 = outside) |
| `iRoomId` | `uint16_t` | Room ID (0 = corridor/outside) |
| `aiTemperature[2]` | `uint16_t[2]` | Double-buffered temperature (0=cold, 65535=hot), toggles each tick |
| `flags` | `map_tile_flags` | 22 boolean flags packed in uint32_t |
| `objects` | `std::list<object_type>` | Objects placed on this tile |
| `raw[8]` | `uint8_t[8]` | Raw map file data for debugging |

#### `map_tile_flags` (th_map.h:118-179)
22 boolean flags packed into a `uint32_t`:

**Pathfinding Flags (bits 0-4):**
- `passable` (1<<0): Can walk on this tile
- `can_travel_n` (1<<1): Can move north from this tile
- `can_travel_e` (1<<2): Can move east
- `can_travel_s` (1<<3): Can move south
- `can_travel_w` (1<<4): Can move west

**World Flags (bits 5-8):**
- `hospital` (1<<5): Tile is inside a hospital building
- `buildable` (1<<6): Player can build on this tile
- `passable_if_not_for_blueprint` (1<<7): Passable except during blueprint placement
- `room` (1<<8): Tile is inside a room (vs corridor)

**Rendering Flags (bits 9-11):**
- `shadow_half` (1<<9): Draw block 75 (half shadow) over floor
- `shadow_full` (1<<10): Draw block 74 (full shadow) over floor
- `shadow_wall` (1<<11): Draw block 156 over east wall

**Door/Object Flags (bits 12-16):**
- `door_north` (1<<12): Door on north wall
- `door_west` (1<<13): Door on west wall
- `do_not_idle` (1<<14): Humanoids should not idle here
- `tall_north` (1<<15): Wall-like object on north wall (casts shadow)
- `tall_west` (1<<16): Wall-like object on west wall

**Buildable Direction Flags (bits 17-20):**
- `buildable_n` (1<<17): Can build on north side
- `buildable_e` (1<<18): Can build on east side
- `buildable_s` (1<<19): Can build on south side
- `buildable_w` (1<<20): Can build on west side

**AI Flag (bit 21):**
- `avoid_tile` (1<<21): Humanoids try hard to avoid this tile

#### `temperature_theme` (th_map.h:181-185)
Three display modes for temperature visualization:
- `red` (0): Red gradients (default)
- `multi_colour` (1): Blue/green/red color shifts
- `yellow_red` (2): Yellow/orange/red gradients

#### `tile_layer` (th_map.h:187-194)
Four rendering layers per tile:
- `ground` (0): Floor tile
- `north_wall` (1): North-facing wall
- `west_wall` (2): West-facing wall
- `ui` (3): UI overlays (room highlights, etc.)

### 1.2 `level_map` Member Variables (th_map.h:453-476)

| Variable | Type | Description |
|----------|------|-------------|
| `cells` | `map_tile*` | Current tile array [width × height] |
| `original_cells` | `map_tile*` | Tiles at load time (before modifications) |
| `wall_blocks` | `sprite_sheet*` | Sprite sheet for floor/wall/decor sprites |
| `overlay` | `map_overlay*` | Optional overlay (temperature, parcels, etc.) |
| `owns_overlay` | `bool` | Whether to delete overlay on destruction |
| `plot_owner` | `int*` | Owner per parcel [parcel_count], 0=unowned |
| `width`, `height` | `int` | Map dimensions in tiles (typically 128×128) |
| `player_count` | `int` | Number of players (1-4) |
| `initial_camera_x[4]`, `initial_camera_y[4]` | `int` | Starting camera position per player |
| `heliport_x[4]`, `heliport_y[4]` | `int` | Heliport position per player |
| `parcel_count` | `int` | Total parcels (including parcel 0 = outside) |
| `current_temperature_index` | `int` | 0 or 1 (double-buffer index) |
| `current_temperature_theme` | `temperature_theme` | Active temperature display mode |
| `parcel_tile_counts` | `int*` | Tile count per parcel |
| `parcel_adjacency_matrix` | `bool*` | Symmetric matrix [parcel_count²] |
| `purchasable_matrix` | `bool*` | Matrix [parcel_count × 4 players] |

### 1.3 Core Methods

#### Map Loading & Initialization

**`set_size(int width, int height)`** (th_map.cpp:281-310)
Allocates tile arrays. Returns false on failure.

**`load_blank()`** (th_map.cpp:355-382)
Creates empty 128×128 map with grass floor pattern. Sets parcel_count=1, player_count=1, camera at (63,63).

**`load_from_th_file(const uint8_t* pData, size_t iDataLength, callback, token)`** (th_map.cpp:390-537)
Loads original Theme Hospital .SAM format maps:
- Reads player count, camera/heliport positions from fixed offsets
- Parses 8 bytes per tile (128×128 = 131072 tiles)
- Uses `gs_iTHMapBlockLUT` (256-entry lookup) to map TH block IDs to sprite indices
- Sets initial flags from map data bytes 5 & 7
- Calls object callback for each placed object (pData[1] != 0)
- Builds parcel_tile_counts, updates shadows

#### Parcel & Ownership Management

**`get_parcel_count()`** (th_map.h:297) → `parcel_count - 1` (excludes parcel 0)

**`set_parcel_owner(int parcelId, int owner)`** (th_map.cpp:668-722)
- Updates `plot_owner[parcelId]`
- For each tile in parcel: restores original tiles if owned, converts to grass if unowned
- Calls `addRemoveDividerWalls()` to add/remove divider walls between parcels with different owners
- Returns vector of split tile coordinates where walls were removed
- Triggers `update_pathfinding()`, `update_shadows()`, `update_purchase_matrix()`

**`get_parcel_owner(int parcelId)`** (th_map.cpp:1282-1288) → owner (0=unowned)

**`are_parcels_adjacent(int p1, int p2)`** (th_map.cpp:807-814)
- Uses adjacency matrix (lazy-initialized via `make_adjacency_matrix()`)
- Two parcels are adjacent if they share a passable border

**`is_parcel_purchasable(int parcelId, int player)`** (th_map.cpp:816-823)
- Uses purchasability matrix (lazy-initialized via `make_purchase_matrix()`)
- Purchasable if unowned AND adjacent to player-owned parcel OR parcel 0 (outside)

**`get_parcel_tile_count(int parcelId)`** (th_map.cpp:885-890) → tile count

**`count_parcel_tiles(int parcelId)`** (th_map.cpp:892-903) - iterates all tiles

#### Camera & Heliport

**`get_player_camera_tile(int player, int* x, int* y)`** (th_map.cpp:833-850)
**`set_player_camera_tile(int player, int x, int y)`** (th_map.cpp:871-876)
**`get_player_heliport_tile(int player, int* x, int* y)`** (th_map.cpp:852-869)
**`set_player_heliport_tile(int player, int x, int y)`** (th_map.cpp:878-883)

#### Pathfinding

**`update_pathfinding()`** (th_map.cpp:1410-1445)
Rebuilds all `can_travel_*` flags:
- Resets all to true (except map edges)
- Blocks travel where north_wall or west_wall sprite exists (non-zero)
- Propagates blocking to neighbor's opposite direction

#### Temperature Simulation

**`set_temperature_display(temperature_theme)`** (th_map.cpp:1294-1296)

**`update_temperatures(uint16_t airTemp, uint16_t radiatorTemp)`** (th_map.cpp:1354-1408)
Double-buffered simulation (toggles `current_temperature_index` each tick):
1. **Diffusion** (25% weight): Average of 4 neighbors weighted by connectivity
   - `can_travel_*` = true → weight 4 (air flow)
   - `can_travel_*` = false → weight 1 (through wall) or 4 (same room, no object)
2. **External merge**:
   - Hospital + radiator: merge 50% toward radiatorTemp (ratio=2)
   - Hospital no radiator: dissipate 0.1% toward 0 (ratio=1000)
   - Outside: merge 1% toward airTemp (ratio=100)

**`get_tile_temperature(const map_tile*)`** (th_map.cpp:1290-1292) → current buffer value

**`thermal_neighbour()`** (th_map.cpp:1298-1333) - computes neighbor contribution

#### Rendering

**`draw(render_target*, screenX, screenY, width, height, canvasX, canvasY)`** (th_map.cpp:1030-1214)
Two-pass isometric rendering:
- **Pass 1** (floor): Left-to-right per scanline - ground layer + floor shadows (blocks 74/75)
- **Pass 2** (walls/entities): Per scanline:
  - Right-to-left: north walls + early entities
  - Left-to-right: west walls + UI layer + late entities
- Handles animation redraw for multi-frame animations crossing tile boundaries
- Draws overlay last

**`draw_floor()`** (th_map.cpp:964-989) - draws ground + floor shadows

**`draw_north_wall()`** (th_map.cpp:991-1007) - draws north wall + wall shadow (block 156)

**`draw_layer()`** (th_map.cpp:1018-1028) - generic layer drawing with sprite lookup

**`hit_test(int x, int y)`** (th_map.cpp:1216-1256) - reverse draw order hit testing

**`set_block_sheet(sprite_sheet*)`** (th_map.cpp:941) - sets sprite sheet
**`set_all_wall_draw_flags(uint8_t)`** (th_map.cpp:943-952) - alpha for transparent walls

#### Shadows

**`update_shadows()`** (th_map.cpp:1459-1487)
- `shadow_half` (block 75): Set if west wall exists (tall or block 82-164)
- `shadow_full` (block 74): Set on tile north of west wall if no north wall there
- `shadow_wall` (block 156): Set if both west and north walls exist
- Corner wrapping optimization for shadow_full

**`is_wall(tile, layer, flag)`** (th_map.cpp:1452-1455) - wall detection for shadows

#### Serialization (Save/Load)

**`save(filename)`** (th_map.cpp:539-634)
Writes .map format:
- Header: player_count + 33 bytes padding
- Per tile (8 bytes): tall_west flag, object type, 3 block indices (via reverse LUT), 2 flag bytes, 1 padding
- Parcel IDs (2 bytes each)
- Camera/heliport positions (16 bytes)
- 56 bytes padding

**`persist(lua_persist_writer*)`** (th_map.cpp:1489-1560+)
Lua savegame serialization (version 5):
- Player count, camera/heliport per player
- Parcel owners, parcel tile counts
- Width, height, temperature index
- Run-length encoded tile layers, parcelId, roomId
- Flags as uint32_t (not RLE)
- Temperature buffers (both)

**`depersist(lua_persist_reader*)`** - inverse of persist

#### Tile Access

**`get_tile(x, y)`** / **`get_tile_unchecked(x, y)`** (th_map.cpp:905-939)
- Checked version returns nullptr for out-of-bounds
- Unchecked version direct pointer arithmetic: `cells + y*width + x`

**`get_original_tile(x, y)`** - accesses `original_cells` (pre-modification state)

#### Coordinate Conversion (static)

**`world_to_screen(T& x, T& y)`** (th_map.h:387-391)
```
x' = 32 * (x - y)
y' = 16 * (x + y)
```

**`screen_to_world(T& x, T& y)`** (th_map.h:393-399)
```
x' = y/32 + x/64
y' = y/32 - x/64
```

---

## 2. Lua Wrapper: `Map` Class (`Lua/map.lua`)

### 2.1 Constructor & State (map.lua:31-45)

```lua
function Map:Map(app)
  self.width = false
  self.height = false
  self.th = thMap()  -- C++ level_map instance
  self.app = app
  self.debug_text = false
  self.debug_flags = false
  self.debug_font = false
  self.debug_tick_timer = 1
  self:setTemperatureDisplayMethod(app.config.warmth_colors_display_default)
  self.difficulty = nil  -- "easy", "full", "hard"
end
```

### 2.2 Tile Query Methods

**`getCellFlag(x, y, flag)`** (map.lua:54-56)
```lua
return self.th:getCellFlags(math.floor(x), math.floor(y), flag_cache)[flag]
```
Uses cached flag table to avoid allocation.

**`getRoomId(x, y)`** (map.lua:62-64)
```lua
return self.th:getRoomId(math.floor(x), math.floor(y))
```

### 2.3 Camera & Heliport

**`setCameraTile(x, y, player)`** (map.lua:78-80) → `self.th:setCameraTile(x, y, player)`

**`setHeliportTile(x, y, player)`** (map.lua:86-88) → `self.th:setHeliportTile(x, y, player)`

### 2.4 Temperature Display

**`setTemperatureDisplayMethod(method)`** (map.lua:93-100)
Validates method ∈ {1,2,3}, maps to `temperature_theme` enum.

**`registerTemperatureDisplayMethod()`** (map.lua:103-108)
Restores saved method or uses default.

### 2.5 Coordinate Conversion (map.lua:117-142)

**`WorldToScreen(x, y)`** - Adjusts origin (1,1)→(0,0), applies matrix:
```
screenX = 32 * (x - y)
screenY = 16 * (x + y - 2)
```

**`ScreenToWorld(x, y)`** - Inverse matrix, clamps to map bounds:
```
y = y/32 + 1
x = x/64
tile_x = y + x
tile_y = y - x
```

### 2.6 Map Loading (map.lua:173-264)

**`load(level, difficulty, level_name, map_file, level_intro, map_editor)`**

Three loading paths:
1. **Original Campaign** (level = number): Loads .SAM file, applies difficulty config (easy/full/hard), loads base_config + difficulty config + level config + optional CorsixTH override
2. **Map Editor** (map_editor = true): Loads blank or custom .map file, uses base_config
3. **Custom Level** (level = string): Loads custom level config, applies base_config + level config

Post-load:
- Gets width/height from C++
- Builds `parcelTileCounts` from C++ `getParcelTileCount()`
- Sets initial plot owners: parcel i → player i (for i ≤ player_count), else 0
- Calls `_fixTiles()`

**`_loadOriginalCampaignLevel(difficulty, level_number, config)`** (map.lua:275-304)
Loads config files in order: `difficulty00.SAM` → `difficultyXX.SAM` → optional `originalXX.level`

**`loadMapConfig(filename, config, custom)`** (map.lua:393-465)
Parses `#` directive config files with nested key support (e.g., `#.Room.GPDoctorCost 5000`)

### 2.7 Difficulty

**`getDifficulty()`** (map.lua:308-312) → 1 (easy), 2 (full/medium), 3 (hard)

### 2.8 Parcel Pricing

**`getParcelPrice(parcel)`** (map.lua:782-787)
```
price = parcelTileCount * (level_config.gbv.LandCostPerTile or 25)
```

**`getParcelTileCount(parcel)`** (map.lua:792-794) → cached count

### 2.9 Tile Fixing (map.lua:798-854)

**`_fixTiles()`** - Called after load and after ownership changes.

**`fixOutdoorTiles()`** (map.lua:804-837) - Only for original campaign:
- Removes `hospital` flag from non-building tiles (only specific indoor tile IDs allowed)
- Removes `passable`/`buildable*` flags from ineligible outdoor tiles
- Allowed hospital tiles: {17,70,18,19,23,16,21,22,66,76,20}
- Allowed pathable tiles: hospital tiles + {4,15,5} (paths/helipad) + {41-58} (roads)

**`fixLevel6Flags()`** (map.lua:840-848) - Specific fixes for level 6

### 2.10 Save Preparation (map.lua:473-494)

**`prepareForSave()`** - Nulls debug fields, updateDebugOverlay, thData
**`afterSave()`** - Restores them

### 2.11 Debug Overlays (map.lua:519-632)

Multiple debug modes set via `loadDebugText()`:
- `"flags"` - Shows passable, hospital, buildable, travel dirs, thob, roomId
- `"positions"` - Shows "x,y" coordinates
- `"heat"` - Shows temperature ×50 as "XX.X"
- `"parcel"` - Shows parcelId
- `"camera"` - Shows "C1"-"C4" at camera positions
- `"heliport"` - Shows "H1"-"H4" at heliport positions
- Raw byte range: shows specific bytes from tile.raw[8]

**`onTick()`** (map.lua:634-643) - Updates debug overlay every 10 ticks

### 2.12 Drawing (map.lua:727-777)

**`draw(canvas, sx, sy, sw, sh, dx, dy)`**
- Delegates to `self.th:draw()` (C++)
- Renders debug overlays if active (font, text/flags)
- Iterates visible tiles using isometric scanline algorithm

### 2.13 Version Migration (map.lua:856-965)

**`afterLoad(old, new)`** - Handles savegame version upgrades:
- v6: Rebuild parcelTileCounts
- v18: Set difficulty="full"
- v44: Update expertise MaxDiagDiff values
- v57: Enable all buildable directions globally
- v120: Rebuild pathfinding (fix side object placement)
- v161: Fix trophy awards
- v164: Add non_visuals_available config
- v175: Add payroll.MaxSalary
- v187: Add tiredness thresholds
- v209: Set SodaPrice
- v217: Call `_fixTiles()`

---

## 3. Entity Map (`Lua/entity_map.lua`)

Separate Lua class tracking real-time entity positions (not tile data).

**`EntityMap:EntityMap(map)`** (entity_map.lua:32-41)
- Creates 2D array [width][height] of `{humanoids={}, objects={}}`

**`addEntity(x, y, entity)`** / **`removeEntity(x, y, entity)`** (entity_map.lua:51-94)
- Routes to humanoids or objects table based on class

**`getEntitiesAtCoordinate(x, y)`** (entity_map.lua:101-114)
**`getHumanoidsAtCoordinate(x, y)`** (entity_map.lua:127-131)
**`getObjectsAtCoordinate(x, y)`** (entity_map.lua:137-141)

**`getAdjacentSquares(x, y)`** (entity_map.lua:149-166) - 4-directional neighbors

**`getHumanoidsInSquareAndInAdjacentSquares(x, y)`** (entity_map.lua:172-181)

**`getPatientsInAdjacentSquares(x, y)`** (entity_map.lua:187-197)

**`getAdjacentFreeTiles(x, y)`** (entity_map.lua:205-217) - Empty tiles (no humanoids/objects)

---

## 4. World Integration (`Lua/world.lua:2293-2305`)

**`World:getObject(x, y, id, only_usable)`**
- Gets objects at tile via `self:getObjects(x, y)`
- Returns first matching object (by id or first available)
- Respects `only_usable` filter (excludes picked_up objects)

---

## 5. Key Algorithms & Formulas

### 5.1 Isometric Coordinates
```
World (tile) → Screen (pixels):
  sx = 32 * (tx - ty)
  sy = 16 * (tx + ty)    [C++: no -2 offset]
  sy = 16 * (tx + ty - 2) [Lua: adjusts for 1-based origin]

Screen → World:
  tx = (sy/32) + (sx/64)
  ty = (sy/32) - (sx/64)
  [Lua adds +1 to both for 1-based]
```

### 5.2 Parcel Pricing
```
price = tile_count × LandCostPerTile
Default LandCostPerTile = 25
```

### 5.3 Temperature Diffusion
```
new_temp = old_temp                                    (start)
new_temp = merge(new_temp, neighbor_avg, 4)            (25% diffusion)
new_temp = merge(new_temp, external_temp, ratio)       (external influence)

merge(old, new, ratio) = (old*(ratio-1) + new) / ratio

Ratios:
  Hospital + radiator:     ratio=2   (50% toward radiator)
  Hospital no radiator:    ratio=1000 (0.1% toward 0)
  Outside:                 ratio=100  (1% toward air_temp)
```

### 5.4 Pathfinding Flag Propagation
```
For each tile:
  can_travel_n = (north_wall == 0)
  can_travel_w = (west_wall == 0)
  If blocked, also set neighbor's opposite flag = false
```

### 5.5 Shadow Casting
```
if west_wall_exists:
  shadow_half = true
  if north_wall_exists:
    shadow_wall = true
  else:
    north_tile.shadow_full = true
    if northwest_tile has no west_wall:
      northwest_tile.shadow_full = true
```

---

## 6. File References

| File | Lines | Purpose |
|------|-------|---------|
| `Src/th_map.h` | 1-620 | C++ class declarations |
| `Src/th_map.cpp` | 1-1560+ | C++ implementation |
| `Lua/map.lua` | 1-965 | Lua Map class |
| `Lua/entity_map.lua` | 1-218 | Real-time entity tracking |
| `Lua/world.lua` | 2293-2305 | Object lookup at tile |

---

## 7. Critical Invariants

1. **Parcel 0** = outside, never owned, never purchasable
2. **Room 0** = corridor/outside
3. **Temperature** double-buffered: `current_temperature_index` toggles 0↔1 each tick
4. **Map size** fixed at 128×128 for original campaigns; custom maps can vary
5. **Original cells** preserved for divider wall logic and save/load comparison
6. **Adjacency matrix** symmetric: `matrix[i][j] == matrix[j][i]`
6. **Purchasability** requires: unowned + adjacent to player parcel OR parcel 0
7. **Camera/heliport** stored per player (max 4), 0-indexed in C++, 1-indexed in Lua API
8. **Tile layers**: C++ 0-3, Lua API uses 1-4
9. **Block LUT** (`gs_iTHMapBlockLUT`) maps 256 TH block IDs → sprite indices
10. **Save version** 5 for persist; map file format separate

---

## 8. Extension Points

### Adding New Tile Flags
1. Add to `map_tile_flags::key` enum (th_map.h:119-142)
2. Implement in `operator=` (th_map.cpp:52-81)
3. Implement in `operator[]` (th_map.cpp:83-187)
4. Implement in `operator uint32_t()` (th_map.cpp:189-261)
5. Add Lua binding in THMap bindings (not shown in provided files)

### Adding New Temperature Theme
1. Add to `temperature_theme` enum (th_map.h:181-185)
2. Handle in rendering/shader code (not in provided files)
3. Add Lua constant mapping in `setTemperatureDisplayMethod` (map.lua:93-100)

### Custom Map Formats
- Implement new `load_from_*` in C++
- Add loading path in `Map:load()` (map.lua:173-264)

---

*Generated from source analysis of CorsixTH Map/Tile System*
