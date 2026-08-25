# Pathfinding System (Area 21) - Technical Summary

## Overview

The CorsixTH pathfinding system implements the A* search algorithm with four specialized finder types, a min-heap open set, node caching, and a dirty node list for efficient memory reuse. It operates at the Lua/C++ boundary where path requests originate from Lua game logic and are executed in C++ for performance.

---

## 1. A* Algorithm Implementation

### Core Data Structures

**path_node** (th_pathfind.h:49-95)
- `prev`: Pointer to previous node in path (nullptr = start, self = not in path)
- `x, y`: Tile coordinates (constant after allocation)
- `cost`: Accumulated path cost from start (g-score)
- `distance`: Number of steps from start
- `guess`: Heuristic estimate to goal (h-score)
- `open_idx`: Index in min-heap (undefined if not in heap)
- `visited`: True if popped from open heap (closed set membership)
- `value()`: Returns `cost + guess` (f-score)

### Algorithm Flow

1. **Initialization** (`abstract_pathfinder::init`, th_pathfind.cpp:42-57)
   - Allocate/resize node cache to map dimensions
   - Reset start node: `prev=nullptr`, `cost=0`, `distance=0`, `guess=heuristic(start)`
   - Mark start as visited, add to dirty list, clear open heap

2. **Main Loop** (e.g., `basic_pathfinder::find_path`, th_pathfind.cpp:144-182)
   - Check if current node is target → success
   - Expand neighbours via `search_neighbours`
   - If open heap empty → no path
   - Pop lowest f-score node from heap, repeat

3. **Neighbour Expansion** (`abstract_pathfinder::search_neighbours`, th_pathfind.cpp:63-90)
   - Checks 4 directions (N/E/S/W) using `can_travel_*` flags
   - Calls virtual `try_node` for each passable direction

4. **Node Recording** (`abstract_pathfinder::record_neighbour_if_passable`, th_pathfind.cpp:92-127)
   - Refuses unpassable tiles unconditionally (fixes bug where entities on impassable tiles could walk through walls)
   - Avoid tiles cost 128 vs normal 1
   - First visit: set prev, cost, distance, guess, add to dirty list, push to heap
   - Better path found: update prev, cost, distance, promote in heap

### Heuristics by Finder Type

| Finder | Heuristic (guess_distance) | Admissible? |
|--------|---------------------------|-------------|
| Basic | Manhattan distance \|dx\|+\|dy\| | Yes |
| Hospital | 0 (Dijkstra-like) | Yes (trivial) |
| Idle Tile | 0 (Dijkstra-like) | Yes |
| Object Visitor | 0 (Dijkstra-like) | Yes |

---

## 2. Four Finder Types

### 2.1 Basic Pathfinder (`basic_pathfinder`)
**File**: th_pathfind.h:153-167, th_pathfind.cpp:129-182

**Purpose**: Point-to-point pathfinding between two tiles.

**Entry**: `find_path(map, startX, startY, endX, endY)`

**Target Check**: `pNode == pTarget` (exact coordinate match)

**Door Handling**: Crosses doors normally (no special logic)

**Use Cases**: Patient/staff movement, object transport, general navigation

### 2.2 Hospital Finder (`hospital_finder`)
**File**: th_pathfind.h:169-178, th_pathfind.cpp:184-232

**Purpose**: Find nearest hospital tile from a starting position.

**Entry**: `find_path_to_hospital(map, startX, startY)`

**Target Check**: `flags.hospital == true` (any tile marked as hospital)

**Door Handling**: Crosses doors normally

**Heuristic**: Always 0 → uniform-cost search (Dijkstra)

**Use Cases**: Ambulance routing, finding nearest hospital entrance

### 2.3 Idle Tile Finder (`idle_tile_finder`)
**File**: th_pathfind.h:180-210, th_pathfind.cpp:234-352

**Purpose**: Find suitable idle/waiting tiles for staff.

**Entry**: `find_idle_tile(map, startX, startY, N, parcelId)`

**Target Criteria** (th_pathfind.cpp:315-316):
- `!flags.do_not_idle` (not marked as no-idle)
- `!flags.avoid_tile` (not an avoid tile)
- `flags.passable` (walkable)
- `flags.hospital` (inside hospital)
- `parcelId match` (correct land parcel)

**Special Logic**:
- **Door Avoidance**: Does NOT traverse through doors (th_pathfind.cpp:246-270)
  - North: checks `!flags.door_north` (current tile's north door)
  - East: checks `!neighbour_flags.door_west` (neighbour's west door)
  - South: checks `!neighbour_flags.door_north` (neighbour's north door)
  - West: checks `!flags.door_west` (current tile's west door)
- **N-th Tile Selection**: Returns Nth valid tile for queueing/randomization
- **Best-Neighbour Promotion**: After expanding a node, promotes the neighbour closest to start (Euclidean distance) to front of heap (th_pathfind.cpp:339-344)

**Use Cases**: Staff finding waiting spots, doctors idling in offices

### 2.4 Object Visitor (`object_visitor`)
**File**: th_pathfind.h:212-235, th_pathfind.cpp:354-461

**Purpose**: Search for specific object types within max distance, calling Lua callback for each found.

**Entry**: `visit_objects(map, startX, startY, objectType, maxDistance, L, visitFunc, anyType)`

**Operation**:
- At each visited tile, iterates objects on that tile
- For matching objects, calls Lua function with: `(x+1, y+1, direction, distance)`
- If Lua returns true → search terminates successfully
- Continues search if `pNode->distance < max_distance`
- **Door Avoidance**: Same as idle_tile_finder (does not cross doors)

**Lua Callback Signature**: `function(x, y, direction, distance) -> bool`
- x, y: 1-based Lua tile coordinates
- direction: 0=N, 1=E, 2=S, 3=W (last travel direction)
- distance: Steps from start
- Return true to stop search

**Use Cases**: Patients finding nearest toilet, bin, drink machine; staff finding equipment

---

## 3. Min-Heap Implementation

**File**: th_pathfind.cpp:557-628

**Structure**: `std::vector<path_node*> open_heap` (0-based array)

**Heap Property**: `value(i) <= value(2*i+1)` and `value(i) <= value(2*i+2)`

**Operations**:
- `push_to_open_heap(node)`: Append, then promote (bubble up)
- `pop_from_open_heap()`: Remove root, move last to root, demote (sink down)
- `open_heap_promote(node)`: Bubble up from current position (used when cost decreases)

**Node Index Tracking**: Each node stores `open_idx` for O(1) position lookup during promotion.

**Validation**: Debug check throws if `open_heap[i] != node` during promote.

---

## 4. Node Cache & Dirty Node List

### Node Cache Allocation (`pathfinder::allocate_node_cache`, th_pathfind.cpp:480-507)

**Trigger**: Map size change or first use

**Process**:
1. Allocate `nodes` vector: `width * height` path_nodes
2. Initialize each node: `prev=self`, `x=iX`, `y=iY`, `visited=false`
3. Allocate `dirty_node_list`: array of `path_node*` size `width * height`
4. Reset `dirty_node_count = 0`

**Reuse** (same map size):
- Iterate `dirty_node_list[0..dirty_node_count-1]`
- Reset each: `prev=self`, `visited=false`
- Other fields (cost, distance, guess) left as-is (overwritten on next use)
- `dirty_node_count = 0`

**Memory Efficiency**: Avoids per-search allocation/deallocation. Single allocation per map size.

### Dirty Node List

**Purpose**: Track nodes modified during search for fast reset.

**Capacity**: Always `width * height` (worst case: all tiles visited)

**Population**: In `record_neighbour_if_passable` (th_pathfind.cpp:117):
```cpp
parent->dirty_node_list[parent->dirty_node_count++] = pNeighbour;
```

**Reset**: In `allocate_node_cache` reuse path (th_pathfind.cpp:499-505)

---

## 5. Lua/C++ Boundary

### C++ → Lua: Path Results

**Method**: `pathfinder::push_result(lua_State* L)` (th_pathfind.cpp:536-555)

**Returns**: Two parallel tables (x_coords, y_coords) indexed by distance+1 (1-based Lua)
```lua
-- Example result for path length 3:
x_coords = {start_x, ..., end_x}  -- indices 1, 2, 3, 4
y_coords = {start_y, ..., end_y}
```

**Failure**: Pushes `nil, "no path"`

### Lua → C++: Path Requests

**Lua Side** (map.lua): Calls `self.th:findPath(...)` etc. via TH binding

**C++ Binding** (th_lua.cpp - not provided but inferred):
- `th_pathfind::find_path` → `basic_pathfinder::find_path`
- `th_pathfind::find_idle_tile` → `idle_tile_finder::find_idle_tile`
- `th_pathfind::find_path_to_hospital` → `hospital_finder::find_path_to_hospital`
- `th_pathfind::visit_objects` → `object_visitor::visit_objects`

### Object Visitor Lua Callback

**Critical Path**: C++ calls Lua mid-search (th_pathfind.cpp:379-388)
```cpp
lua_pushvalue(L, visit_function_index);
lua_pushinteger(L, pNeighbour->x + 1);  -- 1-based
lua_pushinteger(L, pNeighbour->y + 1);
lua_pushinteger(L, static_cast<int>(direction));
lua_pushinteger(L, pNode->distance);
lua_call(L, 4, 1);
bool stop = lua_toboolean(L, -1) != 0;
lua_pop(L, 1);
```

**Risk**: Lua errors during search can corrupt pathfinder state. No pcall protection visible.

---

## 6. Door Crossing Logic

### Tile Flags (th_map.h:118-165)
- `door_north`: Door on north wall of THIS tile
- `door_west`: Door on west wall of THIS tile
- `can_travel_n/e/s/w`: Movement permission (blocked by walls/doors)

### Crossing Rules by Finder

| Finder | Crosses Doors? | Logic |
|--------|---------------|-------|
| Basic | Yes | Uses `can_travel_*` flags only |
| Hospital | Yes | Uses `can_travel_*` flags only |
| Idle Tile | **No** | Explicit door checks in `try_node` |
| Object Visitor | **No** | Explicit door checks in `try_node` |

### Idle/Object Door Check Details (th_pathfind.cpp:246-270, 395-419)

**Critical Asymmetry**: Checks different tile's door flag per direction:
- **North**: `!flags.door_north` (current tile's north door)
- **East**: `!neighbour_flags.door_west` (neighbour's west door)
- **South**: `!neighbour_flags.door_north` (neighbour's north door)
- **West**: `!flags.door_west` (current tile's west door)

**Rationale**: A door between tile (x,y) and (x,y-1) is represented as `door_north` on (x,y). When moving north from (x,y), check current tile's `door_north`. When moving south from (x,y-1), check neighbour's `door_north`.

**Bug Potential**: If door flags inconsistent between adjacent tiles, one direction may allow crossing while other blocks.

---

## 7. Avoid Tiles

**Flag**: `avoid_tile` (th_map.h:165, key: `avoid_tile_mask = 1<<21`)

**Cost Penalty**: 128 vs 1 for normal tiles (th_pathfind.cpp:109)

**Effect**: Strongly discouraged but not forbidden. Path will use avoid tiles if no alternative.

**Idle/Object Finders**: Explicitly reject avoid tiles as targets (th_pathfind.cpp:315, implicit in visitor)

**Setting**: Map loading sets based on tile type (th_map.cpp:478-498), `_fixTiles` in map.lua adjusts.

---

## 8. Common Bugs & Edge Cases

### 8.1 Stuck Entities
**Cause**: Entity on impassable tile (`passable=false`)
**Symptom**: Entity cannot move, pathfinding fails
**Root**: `record_neighbour_if_passable` refuses unpassable neighbours, but if start tile is impassable, `init` still proceeds
**Fix**: Validate start tile passability before search (done in `find_path` but not all finders)

### 8.2 Door Crossing Inconsistency
**Cause**: `door_north`/`door_west` flags not mirrored on adjacent tiles
**Symptom**: Can enter room but not exit (or vice versa)
**Location**: `update_pathfinding` (th_map.cpp:1410-1445) sets `can_travel_*` from wall layers, not door flags
**Note**: Door flags are decorative; `can_travel_*` is authoritative for movement

### 8.3 Heuristic Inadmissibility
**Basic**: Manhattan is admissible (4-connected grid)
**Others**: Zero heuristic is admissible but slow (Dijkstra)

### 8.4 Lua Callback Errors in Object Visitor
**Risk**: Unprotected `lua_call` can longjmp out, leaving pathfinder in inconsistent state
**Mitigation**: Should use `lua_pcall` with error handling

### 8.5 Node Cache Stale Data
**Scenario**: Map resized between searches
**Handling**: `allocate_node_cache` detects size mismatch, full reallocation
**Risk**: If map size same but topology changed (walls added/removed), node cache reused correctly because `prev=self` reset marks all as unvisited

### 8.6 Idle Tile Finder Infinite Loop Risk
**Code**: `best_next_node->guess = -best_next_node->distance` (th_pathfind.cpp:342)
**Issue**: Negative guess makes f-score potentially negative, but heap handles it
**Edge**: If `best_next_node` already popped (visited), promoting it does nothing harmful but wastes cycles

### 8.7 Parcel Boundary Pathfinding
**Issue**: `idle_tile_finder` restricts to parcel but `basic_pathfinder` does not
**Result**: Staff may path through unowned land to reach idle tile in owned parcel
**Fix**: Add parcel check to basic pathfinder or use room-based navigation

### 8.8 Persistence Edge Cases
**Methods**: `persist`/`depersist` (th_pathfind.cpp:630-677)
**Format**: Stores path as coordinate sequence + dimensions
**Risk**: Depersisting on different map size → `allocate_node_cache` reallocates, but node indices may not match if topology changed

---

## 9. Integration Points

### Map Updates Triggering Pathfinding Refresh
- `level_map::set_parcel_owner` → `update_pathfinding()` (th_map.cpp:718)
- `Map:setPlotOwner` (map.lua:370) → `th:updatePathfinding()`
- `Map:afterLoad` (map.lua:912) → `th:updatePathfinding()` for version < 120

### Staff Movement
- `CallsDispatcher` (calls_dispatcher.lua:296) assigns calls to staff
- Staff uses pathfinding to reach call targets
- `entity_map.lua` tracks entity positions for collision avoidance

### World Queries
- `World:getObject` (world.lua:2293) finds objects at tile
- `World:getRoom` (world.lua:2374) uses `map:getRoomId`

---

## 10. Performance Characteristics

| Aspect | Detail |
|--------|--------|
| Time Complexity | O((V+E) log V) with binary heap |
| Space Complexity | O(V) for node cache + heap |
| Cache Reuse | Full reuse when map size unchanged |
| Typical Search | < 1ms for 128x128 map |
| Worst Case | Full map exploration (no path) |

---

## 11. Key File References

| Component | File:Lines |
|-----------|------------|
| Abstract base | th_pathfind.h:98-151, th_pathfind.cpp:39-127 |
| Basic finder | th_pathfind.h:153-167, th_pathfind.cpp:129-182 |
| Hospital finder | th_pathfind.h:169-178, th_pathfind.cpp:184-232 |
| Idle tile finder | th_pathfind.h:180-210, th_pathfind.cpp:234-352 |
| Object visitor | th_pathfind.h:212-235, th_pathfind.cpp:354-461 |
| Pathfinder facade | th_pathfind.h:252-332, th_pathfind.cpp:463-677 |
| Min-heap | th_pathfind.cpp:557-628 |
| Node cache | th_pathfind.cpp:480-507 |
| Tile flags | th_map.h:118-179, th_map.cpp:52-261 |
| Door logic | th_map.cpp:1410-1445 (update_pathfinding) |
| Lua map binding | map.lua:1-965 |
| Entity tracking | entity_map.lua:1-218 |
| World queries | world.lua:2280-2379 |
| Call dispatch | calls_dispatcher.lua:290-389 |

---

## 12. Testing Considerations

### Unit Test Scenarios
1. Basic path: straight line, around wall, through door
2. Hospital find: from outside, from inside, multiple hospitals
3. Idle tile: N=0 (first), N>0 (nth), parcel restriction, door avoidance
4. Object visitor: found at distance 0, at max distance, not found, Lua callback true/false
5. Avoid tiles: path prefers normal, uses avoid when forced
6. Persistence: save/load path, different map size
7. Concurrency: multiple pathfinders same map (not thread-safe!)

### Integration Test Scenarios
1. Staff walks to patient, treats, returns to office (idle tile)
2. Patient arrives, finds toilet, returns to queue
3. Handyman called to repair, path crosses parcel boundary
4. Ambulance called, finds hospital entrance
5. Map edit (wall placed/removed) → pathfinding updates correctly



## Related Pages

- [[21-pathfinding/CHECKLIST]]
- [[21-pathfinding/MAP]]
- [[21-pathfinding/SCAFFOLD]]
