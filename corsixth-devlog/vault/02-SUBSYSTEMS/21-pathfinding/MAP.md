# Pathfinding System (Area 21) - File:Line Index

Cross-reference map across C++ and Lua files for the pathfinding system.

---

## C++ Core Files

### th_pathfind.h - Pathfinding Class Declarations
**Path**: `/tmp/CorsixTH/CorsixTH/Src/th_pathfind.h`

| Line | Symbol | Type | Description |
|------|--------|------|-------------|
| 41-46 | `travel_direction` | enum | N/E/S/W movement directions |
| 49-95 | `path_node` | struct | A* search node with cost, guess, heap index |
| 98-151 | `abstract_pathfinder` | class | Base class for all finders |
| 99 | `abstract_pathfinder(pathfinder*)` | ctor | Constructor |
| 110 | `init(map, x, y)` | method | Initialize search, returns start node |
| 119 | `search_neighbours(node, flags, width)` | method | Expand to 4 neighbours |
| 127 | `record_neighbour_if_passable(node, flags, neighbour)` | method | Add neighbour to heap if passable |
| 135 | `guess_distance(node)` | virtual | Heuristic (pure virtual) |
| 145 | `try_node(node, flags, neighbour, dir)` | virtual | Finder-specific neighbour logic |
| 153-167 | `basic_pathfinder` | class | Point-to-point A* |
| 158 | `guess_distance` | method | Manhattan distance |
| 159 | `try_node` | method | Standard passable check |
| 162 | `find_path(map, sx, sy, ex, ey)` | method | Main entry point |
| 169-178 | `hospital_finder` | class | Find nearest hospital tile |
| 173 | `guess_distance` | method | Returns 0 (Dijkstra) |
| 174 | `try_node` | method | Standard passable check |
| 177 | `find_path_to_hospital(map, sx, sy)` | method | Main entry |
| 180-210 | `idle_tile_finder` | class | Find idle/waiting tiles |
| 189 | `guess_distance` | method | Returns 0 |
| 190 | `try_node` | method | Door avoidance + best neighbour tracking |
| 203 | `find_idle_tile(map, sx, sy, n, parcel)` | method | Main entry |
| 212-235 | `object_visitor` | class | Search for objects, call Lua |
| 222 | `guess_distance` | method | Returns 0 |
| 223 | `try_node` | method | Object check + Lua callback + door avoidance |
| 226 | `visit_objects(map, sx, sy, type, max, L, func, any)` | method | Main entry |
| 252-332 | `pathfinder` | class | Facade + shared state |
| 259 | `find_path` | inline | Delegates to basic_pathfinder |
| 264 | `find_idle_tile` | inline | Delegates to idle_tile_finder |
| 270 | `find_path_to_hospital` | inline | Delegates to hospital_finder |
| 275 | `visit_objects` | inline | Delegates to object_visitor |
| 283 | `get_path_length` | method | Returns destination distance |
| 284 | `get_path_end` | method | Returns destination coordinates |
| 285 | `push_result(L)` | method | Pushes path to Lua stack |
| 295 | `allocate_node_cache(w, h)` | method | Allocates/resizes node cache |
| 297 | `pop_from_open_heap` | method | Extracts min f-score node |
| 298 | `push_to_open_heap` | method | Inserts node into heap |
| 299 | `open_heap_promote` | method | Decrease-key (bubble up) |
| 304-305 | `nodes` | vector | Node cache (width*height) |
| 311 | `dirty_node_list` | array | Modified nodes for reset |
| 320 | `open_heap` | vector | Min-heap of open nodes |

---

### th_pathfind.cpp - Pathfinding Implementation
**Path**: `/tmp/CorsixTH/CorsixTH/Src/th_pathfind.cpp`

| Line | Function | Description |
|------|----------|-------------|
| 39-40 | `abstract_pathfinder::abstract_pathfinder` | Constructor |
| 42-57 | `abstract_pathfinder::init` | Initialize search state |
| 63-90 | `abstract_pathfinder::search_neighbours` | Try 4 directions via `try_node` |
| 92-127 | `abstract_pathfinder::record_neighbour_if_passable` | Core neighbour logic |
| 103-105 | | **Unpassable check** - refuses impassable neighbours |
| 109 | | **Avoid cost** - 128 for avoid_tile, 1 otherwise |
| 111-118 | | First visit: set prev, cost, distance, guess, push heap |
| 119-126 | | Better path: update prev, cost, distance, promote heap |
| 129-133 | `basic_pathfinder::guess_distance` | Manhattan: \|dx\|+\|dy\| |
| 135-142 | `basic_pathfinder::try_node` | Record if passable |
| 144-182 | `basic_pathfinder::find_path` | Main A* loop |
| 163-180 | | Loop: check target, expand, pop heap |
| 184 | `hospital_finder::guess_distance` | Returns 0 |
| 186-193 | `hospital_finder::try_node` | Record if passable |
| 195-232 | `hospital_finder::find_path_to_hospital` | Dijkstra to hospital flag |
| 215 | | Target check: `flags.hospital` |
| 234 | `idle_tile_finder::guess_distance` | Returns 0 |
| 236-283 | `idle_tile_finder::try_node` | **Door avoidance logic** |
| 246-270 | | Direction-specific door flag checks |
| 272-281 | | Best neighbour tracking (Euclidean to start) |
| 285-352 | `idle_tile_finder::find_idle_tile` | Main search loop |
| 315-316 | | Target criteria: !do_not_idle, !avoid, passable, hospital, parcel |
| 339-344 | | Best neighbour promotion: `guess = -distance` |
| 354 | `object_visitor::guess_distance` | Returns 0 |
| 356-422 | `object_visitor::try_node` | Object check + Lua callback |
| 364-371 | | Count matching objects on tile |
| 373-389 | | **Lua callback** - unprotected lua_call |
| 395-419 | | Door avoidance (same as idle finder) |
| 424-461 | `object_visitor::visit_objects` | Main search loop |
| 463-474 | `pathfinder::pathfinder` | Constructor, creates 4 finders |
| 476 | `pathfinder::~pathfinder` | Deletes dirty_node_list |
| 480-507 | `pathfinder::allocate_node_cache` | Cache allocation/reuse |
| 499-505 | | Reuse path: reset dirty nodes (prev=self, visited=false) |
| 509-515 | `get_path_length` | Returns distance or -1 |
| 517-534 | `get_path_end` | Returns coordinates or -1,-1 |
| 536-555 | `push_result` | Creates 2 Lua tables (x[], y[]) 1-based |
| 557-561 | `push_to_open_heap` | Append + promote |
| 563-582 | `open_heap_promote` | Bubble up (decrease-key) |
| 584-628 | `pop_from_open_heap` | Extract min + sink down |
| 630-642 | `persist` | Serialize path to writer |
| 644-677 | `depersist` | Deserialize path from reader |

---

### th_map.h - Map & Tile Definitions
**Path**: `/tmp/CorsixTH/CorsixTH/Src/th_map.h`

| Line | Symbol | Type | Description |
|------|--------|------|-------------|
| 46-113 | `object_type` | enum | 113 object types (desk, bed, toilet, etc.) |
| 118-179 | `map_tile_flags` | struct | 22 boolean flags + bitmask ops |
| 119-142 | `key` | enum class | Bit positions for each flag |
| 144 | `passable` | bool | Can walk on tile |
| 145-148 | `can_travel_n/e/s/w` | bool | Movement permissions |
| 149 | `hospital` | bool | Inside hospital |
| 156 | `door_north` | bool | Door on north wall |
| 157 | `door_west` | bool | Door on west wall |
| 158 | `do_not_idle` | bool | No idling allowed |
| 165 | `avoid_tile` | bool | High path cost (128) |
| 196-240 | `map_tile` | struct | Tile data (layers, objects, flags, parcel, room) |
| 234 | `objects` | list | Objects on this tile |
| 254-477 | `level_map` | class | Full map implementation |
| 291 | `get_width` | method | Map width |
| 294 | `get_height` | method | Map height |
| 297 | `get_parcel_count` | method | Number of parcels |
| 331 | `are_parcels_adjacent` | method | Parcel connectivity |
| 350 | `is_parcel_purchasable` | method | Can player buy parcel |
| 375-380 | `get_tile` / `get_tile_unchecked` | method | Tile access |
| 410 | `update_pathfinding` | method | Rebuilds can_travel_* from walls |
| 411 | `update_shadows` | method | Shadow calculations |

---

### th_map.cpp - Map Implementation
**Path**: `/tmp/CorsixTH/CorsixTH/Src/th_map.cpp`

| Line | Function | Description |
|------|----------|-------------|
| 52-81 | `map_tile_flags::operator=` | Parse uint32_t to flags |
| 83-134 | `operator[]` (non-const) | Flag access by key |
| 136-187 | `operator[]` (const) | Const flag access |
| 189-261 | `operator uint32_t()` | Flags to uint32_t |
| 427-498 | `load_from_th_file` | Load map from TH format |
| 427-441 | | Initialize can_travel_* at edges |
| 454-460 | | North wall blocks can_travel_n |
| 462-470 | | West wall blocks can_travel_w |
| 478-498 | | Set passable, hospital, buildable from raw data |
| 509-519 | | Parse objects via callback |
| 718 | `set_parcel_owner` | Calls `update_pathfinding()` |
| 1410-1445 | `update_pathfinding` | **Rebuilds can_travel_* from wall layers** |
| 1414-1417 | | Reset all can_travel_* to true |
| 1419-1423 | | Edge boundaries |
| 1431-1435 | | North wall blocks north/south travel |
| 1437-1442 | | West wall blocks west/east travel |
| 1459-1487 | `update_shadows` | Shadow casting from walls |

---

## Lua Files

### map.lua - Lua Map Wrapper
**Path**: `/tmp/CorsixTH/CorsixTH/Lua/map.lua`

| Line | Function | Description |
|------|----------|-------------|
| 31-45 | `Map:Map(app)` | Constructor |
| 54-56 | `getCellFlag(x, y, flag)` | Query tile flag |
| 62-64 | `getRoomId(x, y)` | Query room ID |
| 93-100 | `setTemperatureDisplayMethod` | Temperature display |
| 117-125 | `WorldToScreen` | World → screen coords |
| 127-142 | `ScreenToWorld` | Screen → world coords |
| 173-264 | `load` | Load level (campaign/custom/editor) |
| 252 | | Gets width/height from C++ |
| 262 | `_fixTiles` | Fixes tile flags post-load |
| 320-372 | `setPlotOwner` | Change parcel owner |
| 370 | | Calls `th:updatePathfinding()` |
| 496-500 | `clearDebugText` | Clears debug overlays |
| 519-526 | `updateDebugOverlayFlags` | Updates flag debug view |
| 528-535 | `updateDebugOverlayHeat` | Updates temperature view |
| 537-547 | `updateDebugOverlayParcels` | Updates parcel view |
| 634-643 | `onTick` | Periodic debug update |
| 798-854 | `_fixTiles` | **Post-load tile corrections** |
| 804-837 | `fixOutdoorTiles` | Clears hospital/buildable on outdoor tiles |
| 825-828 | | Sets avoid_tile on non-pathable outdoor tiles |
| 839-848 | `fixLevel6Flags` | Level 6 specific fixes |
| 910-913 | `afterLoad` | Version migration |
| 912 | | Calls `th:updatePathfinding()` for v<120 |

---

### entity_map.lua - Entity Position Tracking
**Path**: `/tmp/CorsixTH/CorsixTH/Lua/entity_map.lua`

| Line | Function | Description |
|------|----------|-------------|
| 32-41 | `EntityMap:EntityMap(map)` | Constructor, creates 2D grid |
| 51-61 | `addEntity(x, y, entity)` | Add humanoid/object to tile |
| 84-94 | `removeEntity(x, y, entity)` | Remove from tile |
| 101-114 | `getEntitiesAtCoordinate` | All entities at tile |
| 127-131 | `getHumanoidsAtCoordinate` | Humanoids at tile |
| 137-141 | `getObjectsAtCoordinate` | Objects at tile |
| 149-166 | `getAdjacentSquares` | 4-connected neighbours |
| 172-181 | `getHumanoidsInSquareAndInAdjacentSquares` | Humanoids in 3x3 area |
| 187-197 | `getPatientsInAdjacentSquares` | Patients in adjacent tiles |
| 205-217 | `getAdjacentFreeTiles` | Empty adjacent tiles |

---

### world.lua - World Queries
**Path**: `/tmp/CorsixTH/CorsixTH/Lua/world.lua`

| Line | Function | Description |
|------|----------|-------------|
| 2282-2288 | `World:getObjects(x, y)` | Objects at tile (flat array) |
| 2290-2319 | `World:getObject(x, y, id, usable)` | Find specific object |
| 2293 | | **Key line referenced** - object lookup by ID |
| 2337-2350 | `prepareFootprintTilesForBuild` | Clear tiles for building |
| 2352-2368 | `prepareRectangleTilesForBuild` | Clear rectangle for room |
| 2370-2376 | `World:getRoom(x, y)` | Room at tile via map.getRoomId |

---

### calls_dispatcher.lua - Staff Call Dispatching
**Path**: `/tmp/CorsixTH/CorsixTH/Lua/calls_dispatcher.lua`

| Line | Function | Description |
|------|----------|-------------|
| 296 | `for _, e in ipairs(self.world.entities)` | **Key line** - iterates staff |
| 297-305 | | Finds best staff for call (non-handyman) |
| 309-311 | | Executes call immediately if staff found |
| 322-363 | `CallsDispatcher:answerCall(staff)` | Staff requests work |
| 328-330 | | Handyman: `searchForHandymanTask()` |
| 334-350 | | Scores calls for other staff |
| 352-360 | | Executes best call |
| 365-374 | `dump` | Debug queue dump |

---

## Cross-Reference: Call Flow

```
Lua: Patient needs toilet
  → Patient AI calls map.th:visitObjects(x, y, "toilet", maxDist, callback)
  → C++: object_visitor::visit_objects()
  → C++: search_neighbours() → try_node()
  → C++: Lua callback for each toilet found
  → Lua: callback returns true → search stops
  → C++: returns path to toilet
  → Lua: Patient follows path

Lua: Doctor goes idle
  → Doctor AI calls map.th:findIdleTile(x, y, 0, parcel)
  → C++: idle_tile_finder::find_idle_tile()
  → C++: Search with door avoidance
  → C++: Returns idle tile coordinates
  → Lua: Doctor walks to idle tile

Lua: Ambulance called
  → CallsDispatcher assigns to ambulance
  → Ambulance calls map.th:findPathToHospital(x, y)
  → C++: hospital_finder::find_path_to_hospital()
  → C++: Dijkstra to hospital flag
  → Returns path to nearest hospital tile

Lua: Handyman repairs machine
  → CallsDispatcher calls Handyman:searchForHandymanTask()
  → Handyman finds machine, calls map.th:findPath(x, y, mx, my)
  → C++: basic_pathfinder::find_path()
  → Standard A* with Manhattan heuristic
```

---

## Key Data Flow Summary

| Data | C++ → Lua | Lua → C++ |
|------|-----------|-----------|
| Path request | - | findPath, findIdleTile, findPathToHospital, visitObjects |
| Path result | push_result (2 tables) | - |
| Tile flags | getCellFlag, getCellFlags | setCellFlags |
| Map changes | - | setPlotOwner → updatePathfinding |
| Object queries | visitObjects callback | getObject, getObjects |
| Persistence | persist (writer) | depersist (reader) |

---

## Search Tips

**Find all door-related code:**
```bash
grep -n "door_north\|door_west" /tmp/CorsixTH/CorsixTH/Src/th_pathfind.cpp
grep -n "door_north\|door_west" /tmp/CorsixTH/CorsixTH/Src/th_map.cpp
```

**Find all avoid_tile usage:**
```bash
grep -n "avoid_tile" /tmp/CorsixTH/CorsixTH/Src/th_pathfind.cpp
grep -n "avoid_tile" /tmp/CorsixTH/CorsixTH/Lua/map.lua
```

**Find Lua callback in object_visitor:**
```bash
grep -n "lua_call\|lua_pcall" /tmp/CorsixTH/CorsixTH/Src/th_pathfind.cpp
```

**Find heap operations:**
```bash
grep -n "open_heap\|push_to_open_heap\|pop_from_open_heap\|open_heap_promote" /tmp/CorsixTH/CorsixTH/Src/th_pathfind.cpp
```



## Related Pages

- [[21-pathfinding/SUMMARY]]
- [[21-pathfinding/CHECKLIST]]
- [[21-pathfinding/SCAFFOLD]]
