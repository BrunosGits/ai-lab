# Map/Tile System - File:Line Index (Area 23)

Cross-reference of map-related methods across Lua and C++ codebases.

---

## Lua/map.lua → C++ th_map.h/.cpp Method Mapping

### Map Class Construction & Initialization

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:Map(app)` | 31-45 | `level_map()` | 256 | 263 |
| `Map:load()` | 173-264 | `load_from_th_file()` | 261 | 390 |
| `Map:load()` | 173-264 | `load_blank()` | 260 | 355 |
| `Map:_loadOriginalCampaignLevel()` | 275-304 | (Lua only) | - | - |
| `Map:loadMapConfig()` | 393-465 | (Lua only) | - | - |

### Tile Flag Queries

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:getCellFlag(x,y,flag)` | 54-56 | `get_tile() → flags` | 375 | 905 |
| `Map:getCellFlags(x,y)` | 652-654 | `get_tile() → flags` | 375 | 905 |
| `Map:setCellFlags(...)` | 652-654 | `get_tile_unchecked() → flags` | 379 | 929 |

### Room & Parcel Queries

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:getRoomId(x,y)` | 62-64 | `get_tile() → iRoomId` | 375 | 905 |
| `Map:getParcelPrice(parcel)` | 782-787 | `get_parcel_tile_count()` | 309 | 885 |
| `Map:getParcelTileCount(parcel)` | 792-794 | `get_parcel_tile_count()` | 309 | 885 |
| `Map:setPlotOwner(plot,owner)` | 320-372 | `set_parcel_owner()` | 321 | 668 |
| `Map.th:getPlotCount()` | 255 | `get_parcel_count()` | 297 | - |
| `Map.th:getParcelTileCount()` | 256 | `get_parcel_tile_count()` | 309 | 885 |
| `Map.th:setPlotOwner()` | 258 | `set_parcel_owner()` | 321 | 668 |

### Camera & Heliport

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:setCameraTile(x,y,player)` | 78-80 | `set_player_camera_tile()` | 305 | 871 |
| `Map:setHeliportTile(x,y,player)` | 86-88 | `set_player_heliport_tile()` | 306 | 878 |
| `Map.th:getCameraTile(player)` | 557 | `get_player_camera_tile()` | 303 | 833 |
| `Map.th:getHeliportTile(player)` | 573 | `get_player_heliport_tile()` | 304 | 852 |
| `Map:setPlayerCount()` | 66-68 | `set_player_count()` | 301 | 825 |
| `Map:getPlayerCount()` | 70-72 | `get_player_count()` | 299 | - |

### Temperature System

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:setTemperatureDisplayMethod()` | 93-100 | `set_temperature_display()` | 283 | 1294 |
| `Map:registerTemperatureDisplayMethod()` | 103-108 | `set_temperature_display()` | 283 | 1294 |
| `Map.th:getCellTemperature(x,y)` | 532 | `get_tile_temperature()` | 382 | 1290 |
| `Map.th:update_temperatures()` | (called from World) | `update_temperatures()` | 287 | 1354 |

### Coordinate Conversion

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:WorldToScreen(x,y)` | 117-125 | `world_to_screen()` | 387 | - |
| `Map:ScreenToWorld(x,y)` | 127-142 | `screen_to_world()` | 394 | - |

### Map Loading & Saving

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:save(filename)` | 377-379 | `save()` | 265 | 539 |
| `Map.th:load(data)` | 193,225,241 | `load_from_th_file()` | 261 | 390 |
| `Map.th:loadBlank()` | 221 | `load_blank()` | 260 | 355 |
| `Map:prepareForSave()` | 473-482 | `persist()` | 401 | 1489 |
| `Map:afterSave()` | 485-494 | `depersist()` | 402 | (later) |

### Debug & Visualization

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:loadDebugText()` | 582-632 | (Lua only) | - | - |
| `Map:updateDebugOverlayFlags()` | 519-526 | `get_tile() → flags` | 375 | 905 |
| `Map:updateDebugOverlayHeat()` | 528-535 | `get_tile_temperature()` | 382 | 1290 |
| `Map:updateDebugOverlayParcels()` | 537-547 | `get_tile() → iParcelId` | 375 | 905 |
| `Map:updateDebugOverlayCamera()` | 549-563 | `get_player_camera_tile()` | 303 | 833 |
| `Map:updateDebugOverlayHeliport()` | 565-579 | `get_player_heliport_tile()` | 304 | 852 |
| `Map:setBlocks(blocks)` | 647-650 | `set_block_sheet()` | 272 | 941 |
| `Map:draw(canvas,...)` | 727-777 | `draw()` | 360 | 1030 |
| `Map:_drawDebugTiles()` | 678-716 | (Lua only) | - | - |

### Tile Fixing & Migration

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:_fixTiles()` | 798-854 | (Lua only) | - | - |
| `Map:afterLoad(old,new)` | 856-965 | (Lua only) | - | - |
| `Map.th:updatePathfinding()` | 370 | `update_pathfinding()` | 281 | 1410 |
| `Map.th:updateShadows()` | (after setPlotOwner) | `update_shadows()` | 282 | 1459 |

### Internal Helpers

| Lua Method | Line | C++ Method | Header Line | Impl Line |
|------------|------|------------|-------------|-----------|
| `Map:getRawData()` | 502-517 | (Lua only) | - | - |
| `Map:setDebugText()` | 661-676 | (Lua only) | - | - |
| `Map:setDebugFont()` | 656-659 | (Lua only) | - | - |
| `Map:clearDebugText()` | 496-500 | (Lua only) | - | - |
| `Map:onTick()` | 634-643 | (Lua only) | - | - |

---

## C++ th_map.h - level_map Class Methods

### Construction & Destruction
| Method | Header Line | Impl Line (th_map.cpp) |
|--------|-------------|------------------------|
| `level_map()` | 256 | 263 |
| `~level_map()` | 257 | 263 |
| `set_size()` | 259 | 281 |
| `load_blank()` | 260 | 355 |
| `load_from_th_file()` | 261 | 390 |
| `save()` | 265 | 539 |

### Sprite & Rendering
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `set_block_sheet()` | 272 | 941 |
| `set_all_wall_draw_flags()` | 279 | 943 |
| `draw()` | 360 | 1030 |
| `draw_floor()` | 407 | 964 |
| `draw_north_wall()` | 409 | 991 |
| `draw_layer()` | 412 | 1018 |
| `hit_test()` | 371 | 1216 |
| `hit_test_drawables()` | 258 | 1258 |

### Pathfinding & Shadows
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `update_pathfinding()` | 281 | 1410 |
| `update_shadows()` | 282 | 1459 |
| `make_adjacency_matrix()` | 443 | 742 |
| `make_purchase_matrix()` | 474 | 774 |
| `update_purchase_matrix()` | 449 | 783 |

### Temperature
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `set_temperature_display()` | 283 | 1294 |
| `get_temperature_display()` | 284 | - |
| `update_temperatures()` | 287 | 1354 |
| `thermal_neighbour()` | 438 | 1298 |
| `get_tile_temperature()` | 382 | 1290 |

### Parcel Management
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `get_parcel_count()` | 297 | - |
| `get_player_count()` | 299 | - |
| `set_player_count()` | 301 | 825 |
| `get_player_camera_tile()` | 303 | 833 |
| `get_player_heliport_tile()` | 304 | 852 |
| `set_player_camera_tile()` | 305 | 871 |
| `set_player_heliport_tile()` | 306 | 878 |
| `get_parcel_tile_count()` | 309 | 885 |
| `set_parcel_owner()` | 321 | 668 |
| `get_parcel_owner()` | 329 | 1282 |
| `are_parcels_adjacent()` | 338 | 807 |
| `is_parcel_purchasable()` | 350 | 816 |
| `count_parcel_tiles()` | 451 | 892 |

### Tile Access
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `get_tile()` | 375 | 905 |
| `get_tile_unchecked()` | 378 | 929 |
| `get_original_tile()` | 377 | 921 |
| `get_original_tile_unchecked()` | 380 | 937 |
| `get_tile_owner()` | 383 | 1277 |

### Coordinate Conversion (Static)
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `world_to_screen()` | 387 | - |
| `screen_to_world()` | 394 | - |

### Persistence
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `persist()` | 401 | 1489 |
| `depersist()` | 402 | (after 1522) |
| `set_overlay()` | 404 | 273 |

### Internal Helpers
| Method | Header Line | Impl Line |
|--------|-------------|-----------|
| `layer_exists()` | 421 | 954 |
| `read_tile_index()` | 425 | 342 |
| `write_tile_index()` | 426 | 349 |

---

## C++ th_map.cpp - Key Implementation Sections

### Flag Serialization (map_tile_flags)
| Function | Lines |
|----------|-------|
| `operator=(uint32_t)` | 52-81 |
| `operator[](key)` | 83-134 |
| `operator[](key) const` | 136-187 |
| `operator uint32_t()` | 189-261 |

### Map Loading from TH Format
| Section | Lines |
|---------|-------|
| Header parsing | 390-410 |
| Tile data loop | 422-520 |
| Parcel counting | 473-476 |
| Flag assignment | 478-498 |
| Object callback | 510-513 |
| Post-load setup | 522-536 |

### Parcel Ownership & Divider Walls
| Function | Lines |
|----------|-------|
| `addRemoveDividerWalls()` | 639-664 |
| `set_parcel_owner()` | 668-722 |

### Adjacency & Purchase Matrices
| Function | Lines |
|----------|-------|
| `test_adj()` | 726-738 |
| `make_adjacency_matrix()` | 742-772 |
| `make_purchase_matrix()` | 774-781 |
| `update_purchase_matrix()` | 783-805 |
| `are_parcels_adjacent()` | 807-814 |
| `is_parcel_purchasable()` | 816-823 |

### Player Camera/Heliport
| Function | Lines |
|----------|-------|
| `set_player_count()` | 825-831 |
| `get_player_camera_tile()` | 833-850 |
| `get_player_heliport_tile()` | 852-869 |
| `set_player_camera_tile()` | 871-875 |
| `set_player_heliport_tile()` | 878-883 |

### Parcel Tile Counting
| Function | Lines |
|----------|-------|
| `get_parcel_tile_count()` | 885-890 |
| `count_parcel_tiles()` | 892-903 |

### Tile Accessors
| Function | Lines |
|----------|-------|
| `get_tile()` | 905-919 |
| `get_tile_unchecked()` | 929-935 |
| `get_original_tile()` | 921-927 |
| `get_original_tile_unchecked()` | 937-939 |

### Wall & Shadow Rendering
| Function | Lines |
|----------|-------|
| `set_all_wall_draw_flags()` | 943-952 |
| `layer_exists()` | 954-962 |
| `draw_floor()` | 964-989 |
| `draw_north_wall()` | 991-1007 |
| `draw_layer()` | 1018-1028 |

### Main Draw Pipeline
| Function | Lines |
|----------|-------|
| `draw()` | 1030-1214 |
| `hit_test()` | 1216-1256 |
| `hit_test_drawables()` | 1258-1275 |

### Temperature System
| Function | Lines |
|----------|-------|
| `get_tile_owner()` | 1277-1280 |
| `get_parcel_owner()` | 1282-1288 |
| `get_tile_temperature()` | 1290-1292 |
| `set_temperature_display()` | 1294-1296 |
| `thermal_neighbour()` | 1298-1333 |
| `merge_temperatures()` | 1345-1350 |
| `update_temperatures()` | 1354-1408 |

### Pathfinding Update
| Function | Lines |
|----------|-------|
| `update_pathfinding()` | 1410-1445 |

### Shadow Calculation
| Function | Lines |
|----------|-------|
| `is_wall()` | 1452-1455 |
| `update_shadows()` | 1459-1487 |

### Persistence
| Function | Lines |
|----------|-------|
| `persist()` | 1489-1522+ |
| `depersist()` | (after 1522) |

---

## Lua/entity_map.lua - EntityMap Class

| Method | Line | Description |
|--------|------|-------------|
| `EntityMap:EntityMap(map)` | 32-41 | Constructor - creates 2D grid |
| `EntityMap:addEntity(x,y,entity)` | 51-61 | Add humanoid/object to tile |
| `EntityMap:removeEntity(x,y,entity)` | 84-94 | Remove entity from tile |
| `EntityMap:getEntitiesAtCoordinate(x,y)` | 101-114 | Get all entities at tile |
| `EntityMap:getHumanoidsAtCoordinate(x,y)` | 127-131 | Get humanoids at tile |
| `EntityMap:getObjectsAtCoordinate(x,y)` | 137-141 | Get objects at tile |
| `EntityMap:getAdjacentSquares(x,y)` | 149-166 | Get 4-connected neighbors |
| `EntityMap:getHumanoidsInSquareAndInAdjacentSquares(x,y)` | 172-181 | Humanoids in tile + neighbors |
| `EntityMap:getPatientsInAdjacentSquares(x,y)` | 187-197 | Patients in neighbor tiles |
| `EntityMap:getAdjacentFreeTiles(x,y)` | 205-217 | Empty adjacent tiles |

---

## Lua/world.lua - Map-Related Functions (lines 2293-2305)

| Method | Line | Description |
|--------|------|-------------|
| `World:getObject(x,y,id,only_usable)` | 2297-2312 | Find object at map coordinates |

---

## Data Structures Cross-Reference

### map_tile_flags (th_map.h:118-179)
| Flag | Bit | Lua Access | Description |
|------|-----|------------|-------------|
| passable | 0 | flags.passable | Can walk on tile |
| can_travel_n | 1 | flags.travelNorth | Can walk north |
| can_travel_e | 2 | flags.travelEast | Can walk east |
| can_travel_s | 3 | flags.travelSouth | Can walk south |
| can_travel_w | 4 | flags.travelWest | Can walk west |
| hospital | 5 | flags.hospital | Inside building |
| buildable | 6 | flags.buildable | Can build on tile |
| passable_if_not_for_blueprint | 7 | - | Passable unless blueprint |
| room | 8 | flags.room | Inside room |
| shadow_half | 9 | flags.shadowHalf | Half shadow |
| shadow_full | 10 | flags.shadowFull | Full shadow |
| shadow_wall | 11 | flags.shadowWall | Wall shadow |
| door_north | 12 | flags.doorNorth | Door on north wall |
| door_west | 13 | flags.doorWest | Door on west wall |
| do_not_idle | 14 | flags.doNotIdle | No idling |
| tall_north | 15 | flags.tallNorth | Tall object north |
| tall_west | 16 | flags.tallWest | Tall object west |
| buildable_n | 17 | flags.buildableNorth | Buildable north side |
| buildable_e | 18 | flags.buildableEast | Buildable east side |
| buildable_s | 19 | flags.buildableSouth | Buildable south side |
| buildable_w | 20 | flags.buildableWest | Buildable west side |
| avoid_tile | 21 | flags.avoidTile | Avoid for humanoids |

### map_tile (th_map.h:196-240)
| Field | Type | Description |
|-------|------|-------------|
| entities | link_list | Entities rendered at tile |
| oEarlyEntities | link_list | Early-pass entities |
| tile_layers[4] | uint16_t | Ground, N-wall, W-wall, UI |
| iParcelId | uint16_t | Parcel/plot ID (0=outside) |
| iRoomId | uint16_t | Room ID (0=corridor) |
| aiTemperature[2] | uint16_t | Current/prev temperature |
| flags | map_tile_flags | 22 boolean flags |
| objects | list<object_type> | Objects on tile |
| raw[8] | uint8_t | Raw map file data |

### level_map (th_map.h:254-477) - Key Fields
| Field | Type | Description |
|-------|------|-------------|
| cells | map_tile* | Current tile array |
| original_cells | map_tile* | Tiles at load time |
| wall_blocks | sprite_sheet* | Sprite sheet for walls |
| overlay | map_overlay* | Debug overlay |
| plot_owner | int* | Owner per parcel |
| width/height | int | Map dimensions |
| player_count | int | Number of players |
| initial_camera_x/y[4] | int | Camera positions |
| heliport_x/y[4] | int | Heliport positions |
| parcel_count | int | Total parcels |
| parcel_tile_counts | int* | Tiles per parcel |
| parcel_adjacency_matrix | bool* | Parcel connectivity |
| purchasable_matrix | bool* | Player→parcel purchasable |

---

## Temperature Themes (th_map.h:181-185)

| Enum Value | Lua Method | Description |
|------------|------------|-------------|
| `temperature_theme::red` (0) | Method 1 | Red gradients |
| `temperature_theme::multi_colour` (1) | Method 2 | Blue/Green/Red |
| `temperature_theme::yellow_red` (2) | Method 3 | Yellow/Orange/Red |

---

## Tile Layers (th_map.h:187-194)

| Layer | Index | Lua Layer | Description |
|-------|-------|-----------|-------------|
| ground | 0 | 1 | Floor tiles |
| north_wall | 1 | 2 | North-facing walls |
| west_wall | 2 | 3 | West-facing walls |
| ui | 3 | 4 | UI overlays |

---

## Object Types (th_map.h:46-113)

Key object types referenced in map loading:
- `desk` (1), `cabinet` (2), `door` (3), `bench` (4)
- `bed` (8), `reception_desk` (11), `radiator` (44)
- `plant` (45), `bin` (50), `loo` (51)
- `helicopter` (63), `rathole` (64)

---

## Coordinate Systems

| System | Origin | Range | Used By |
|--------|--------|-------|---------|
| World (tile) | (1,1) | [1, width] × [1, height] | Lua API, game logic |
| World (C++) | (0,0) | [0, width-1] × [0, height-1] | C++ internals |
| Screen (absolute) | Map origin | Pixels | Rendering, hit-test |
| Screen (relative) | Window corner | Pixels | UI input |

Conversion (Lua map.lua:117-142):
```
WorldToScreen:  sx = 32*(x-y),  sy = 16*(x+y-2)
ScreenToWorld:  tx = y/32 + 1 + x/64,  ty = y/32 + 1 - x/64
```

C++ equivalent (th_map.h:387-399):
```
world_to_screen:  x = 32*(x-y),  y = 16*(x+y)
screen_to_world:  x = y/32 + x/64,  y = y/32 - x/64
```

---

## Save File Version History (map.lua:856-965)

| Version | Change |
|---------|--------|
| < 6 | Parcel tile count migration |
| < 18 | Default difficulty "full" |
| < 44 | Expertise MaxDiagDiff values |
| < 57 | Set all buildable flags |
| < 120 | Update pathfinding |
| < 161 | Trophy bug fix (hotfix1, awards) |
| < 164 | Non-visual illnesses availability |
| < 175 | Max salary config |
| < 187 | Tiredness thresholds |
| < 209 | Soda price |
| < 217 | Re-run _fixTiles |

---

## Quick Navigation Index

### By Feature Area

**Tile Flags**: map.lua:54, th_map.h:118, th_map.cpp:52
**Room Detection**: map.lua:62, th_map.h:221
**Parcel System**: map.lua:254, th_map.h:297, th_map.cpp:668
**Camera**: map.lua:78, th_map.h:303, th_map.cpp:833
**Temperature**: map.lua:93, th_map.h:181, th_map.cpp:1354
**Coordinates**: map.lua:117, th_map.h:387
**Loading**: map.lua:173, th_map.cpp:390
**Saving**: map.lua:377, th_map.cpp:539
**Rendering**: map.lua:727, th_map.cpp:1030
**Pathfinding**: map.lua:370, th_map.cpp:1410
**Shadows**: th_map.cpp:1459
**Debug**: map.lua:467, map.lua:582
**EntityMap**: entity_map.lua:32
**Persistence**: map.lua:473, th_map.cpp:1489
**Migration**: map.lua:856
