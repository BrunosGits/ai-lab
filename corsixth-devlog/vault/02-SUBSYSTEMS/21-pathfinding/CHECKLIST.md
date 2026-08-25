# Pathfinding System (Area 21) - Pre-Fix Checklist

## Before Making Any Changes

Use this checklist to verify the current state and identify potential issues before modifying the pathfinding system.

---

## 1. Tile Flags Verification

### 1.1 Flag Definitions (th_map.h:118-179)
- [ ] `passable` - Can entities walk on this tile?
- [ ] `can_travel_n/e/s/w` - Movement permissions (blocked by walls/doors)
- [ ] `hospital` - Tile is inside hospital building
- [ ] `buildable` - Player can build on this tile
- [ ] `room` - Tile is inside a room
- [ ] `door_north` - Door on north wall of THIS tile
- [ ] `door_west` - Door on west wall of THIS tile
- [ ] `do_not_idle` - Humanoids should not idle here
- [ ] `avoid_tile` - Strongly discouraged for pathfinding (cost 128)
- [ ] `tall_north/tall_west` - Wall-like objects for shadows
- [ ] `buildable_n/e/s/w` - Buildable on each side

### 1.2 Flag Consistency Checks
- [ ] `can_travel_n` on tile (x,y) == `can_travel_s` on tile (x,y-1)
- [ ] `can_travel_e` on tile (x,y) == `can_travel_w` on tile (x+1,y)
- [ ] `door_north` on tile (x,y) implies `can_travel_n` and `can_travel_s` on (x,y-1)
- [ ] `door_west` on tile (x,y) implies `can_travel_w` and `can_travel_e` on (x-1,y)
- [ ] Wall tiles (`tile_layers[north_wall/west_wall] != 0`) have corresponding `can_travel_*` = false
- [ ] `update_pathfinding()` (th_map.cpp:1410) correctly rebuilds all `can_travel_*` from wall layers

### 1.3 Flag Initialization (th_map.cpp:427-498)
- [ ] Map loading sets all flags from raw data correctly
- [ ] Map edges have `can_travel_*` = false at boundaries
- [ ] `hospital` flag set from raw data bit 4 (pData[7] & 16)
- [ ] `buildable` flags set from pData[5] bits
- [ ] `avoid_tile` initially false (set later by `_fixTiles` in map.lua)

---

## 2. Door Directions Verification

### 2.1 Door Representation
- [ ] Doors are ONE-WAY flags: `door_north` on SOUTH tile of doorway
- [ ] `door_west` on EAST tile of doorway
- [ ] No `door_south` or `door_east` flags exist
- [ ] Adjacent tiles have symmetric `can_travel_*` but NOT symmetric `door_*` flags

### 2.2 Door Logic by Finder
| Finder | Crosses Doors? | Check Logic |
|--------|---------------|-------------|
| Basic | Yes | Uses `can_travel_*` only |
| Hospital | Yes | Uses `can_travel_*` only |
| Idle Tile | **No** | Explicit checks (see below) |
| Object Visitor | **No** | Explicit checks (see below) |

### 2.3 Idle/Visitor Door Check Asymmetry (th_pathfind.cpp:246-270, 395-419)
- [ ] **North**: Check `!flags.door_north` (CURRENT tile's north door)
- [ ] **East**: Check `!neighbour_flags.door_west` (NEIGHBOUR's west door)
- [ ] **South**: Check `!neighbour_flags.door_north` (NEIGHBOUR's north door)
- [ ] **West**: Check `!flags.door_west` (CURRENT tile's west door)

### 2.4 Common Door Bugs
- [ ] Door flags not mirrored → can enter room but not exit
- [ ] `update_pathfinding()` doesn't update door flags (only `can_travel_*`)
- [ ] Parcel ownership change (`set_parcel_owner`) calls `update_pathfinding()` → OK
- [ ] Map editor wall placement updates door flags correctly

---

## 3. Heuristic Correctness

### 3.1 Basic Pathfinder (Manhattan Distance)
- [ ] `guess_distance = |dx| + |dy|` (th_pathfind.cpp:129-133)
- [ ] Admissible for 4-connected grid (no diagonals) ✓
- [ ] Consistent (monotonic) ✓

### 3.2 Hospital Finder (Zero Heuristic)
- [ ] `guess_distance = 0` (th_pathfind.cpp:184)
- [ ] Effectively Dijkstra's algorithm
- [ ] Admissible (0 ≤ actual cost) ✓
- [ ] Slower but finds nearest hospital correctly

### 3.3 Idle Tile Finder (Zero Heuristic)
- [ ] `guess_distance = 0` (th_pathfind.cpp:234)
- [ ] Best-neighbour promotion uses Euclidean distance to start (th_pathfind.cpp:342)
- [ ] Promotion: `guess = -distance` → negative f-score
- [ ] Heap handles negative values correctly

### 3.4 Object Visitor (Zero Heuristic)
- [ ] `guess_distance = 0` (th_pathfind.cpp:354)
- [ ] Search limited by `max_distance` parameter
- [ ] Door avoidance same as idle finder

### 3.5 Heuristic Validation
- [ ] No finder uses inadmissible heuristic (overestimates)
- [ ] Zero heuristic always safe but slower
- [ ] Basic finder's Manhattan optimal for grid

---

## 4. Avoid Tile Cost Verification

### 4.1 Cost Values (th_pathfind.cpp:109)
- [ ] Normal tile cost: **1**
- [ ] Avoid tile cost: **128**
- [ ] Ratio: 128:1 (strong penalty)

### 4.2 Avoid Tile Behavior
- [ ] Path prefers 127 normal tiles over 1 avoid tile
- [ ] Path uses avoid tile if no alternative (not forbidden)
- [ ] Idle finder rejects avoid tiles as TARGETS (th_pathfind.cpp:315)
- [ ] Object visitor doesn't explicitly reject avoid targets (check needed)

### 4.3 Avoid Tile Assignment
- [ ] Set in `Map:_fixTiles()` (map.lua:825-828) for outdoor/ineligible tiles
- [ ] Original campaign levels: outdoor tiles marked avoid
- [ ] Custom levels: verify `_fixTiles` runs appropriately

---

## 5. Staff Matching & Call Dispatch

### 5.1 CallsDispatcher Integration (calls_dispatcher.lua:296)
- [ ] `executeCall` triggers pathfinding for staff
- [ ] Staff uses `find_path` to reach call target
- [ ] Handyman uses `searchForHandymanTask` (different logic)

### 5.2 Path Request Patterns
- [ ] Patient → GP office: basic pathfinder
- [ ] Patient → Toilet: object_visitor (finds toilet object)
- [ ] Staff → Idle spot: idle_tile_finder
- [ ] Ambulance → Hospital: hospital_finder
- [ ] Handyman → Machine: basic pathfinder

### 5.3 EntityMap Coordination (entity_map.lua)
- [ ] `EntityMap:addEntity/removeEntity` tracks positions
- [ ] Pathfinding doesn't check EntityMap for collisions (dynamic avoidance separate)
- [ ] `getAdjacentFreeTiles` used for local navigation

---

## 6. Lua/C++ Boundary Safety

### 6.1 Path Request Flow
- [ ] Lua: `map.th:findPath(sx, sy, ex, ey)` → C++ `basic_pathfinder::find_path`
- [ ] Lua: `map.th:findIdleTile(sx, sy, n, parcel)` → C++ `idle_tile_finder::find_idle_tile`
- [ ] Lua: `map.th:findPathToHospital(sx, sy)` → C++ `hospital_finder::find_path_to_hospital`
- [ ] Lua: `map.th:visitObjects(sx, sy, type, maxDist, func, any)` → C++ `object_visitor::visit_objects`

### 6.2 Result Retrieval
- [ ] `pathfinder:push_result(L)` returns two tables (x[], y[]) 1-based
- [ ] Failure returns `nil, "no path"`
- [ ] `get_path_length()` returns -1 if no path

### 6.3 Object Visitor Callback Risk (th_pathfind.cpp:379-388)
- [ ] **CRITICAL**: Uses `lua_call` NOT `lua_pcall` - errors longjmp out
- [ ] No error handling in C++ - can corrupt pathfinder state
- [ ] Stack: pushes function + 4 args, calls, pops 1 result
- [ ] Arguments: x+1, y+1 (1-based), direction (0-3), distance

### 6.4 Persistence (th_pathfind.cpp:630-677)
- [ ] `persist`: writes path length, width, height, then coordinate pairs
- [ ] `depersist`: allocates cache, rebuilds node chain
- [ ] Risk: Depersisting on different map topology → invalid paths

---

## 7. Memory & Performance

### 7.1 Node Cache (th_pathfind.cpp:480-507)
- [ ] Allocates `width * height` nodes on size change
- [ ] Reuses cache on same size (resets only dirty nodes)
- [ ] `dirty_node_list` capacity = `width * height` (worst case)
- [ ] No per-search allocations after warmup

### 7.2 Min-Heap (th_pathfind.cpp:557-628)
- [ ] Binary heap with `open_idx` for O(1) promote
- [ ] `push_to_open_heap` → `promote` (bubble up)
- [ ] `pop_from_open_heap` → `demote` (sink down)
- [ ] Debug assertion validates `open_idx` consistency

### 7.3 Scalability
- [ ] 128x128 map = 16,384 nodes, ~64KB node cache
- [ ] Heap max size = visited nodes
- [ ] Typical search visits < 1000 nodes
- [ ] Worst case (no path) visits all reachable nodes

---

## 8. Common Bug Patterns to Verify

### 8.1 Stuck Entities
- [ ] Entity on impassable tile → pathfinding fails
- [ ] Start tile validation in `find_path` (th_pathfind.cpp:149) but NOT in `find_idle_tile` (th_pathfind.cpp:290) or `find_path_to_hospital` (th_pathfind.cpp:200)
- [ ] Fix: Validate start tile passability in ALL finders

### 8.2 Door Crossing Inconsistency
- [ ] `can_travel_*` authoritative, door flags decorative
- [ ] `update_pathfinding` sets `can_travel_*` from walls, NOT doors
- [ ] Door flags only used by idle/visitor finders for avoidance

### 8.3 Parcel Boundary Issues
- [ ] Idle finder respects parcel, basic finder does not
- [ ] Staff may path through unowned land
- [ ] Room-based navigation would be better

### 8.4 Negative Guess in Idle Finder
- [ ] `best_next_node->guess = -distance` (th_pathfind.cpp:342)
- [ ] Can create negative f-scores
- [ ] Heap handles correctly but unusual

### 8.5 Object Visitor Lua Errors
- [ ] Unprotected `lua_call` can crash game
- [ ] Should wrap in `lua_pcall` with error handling

### 8.6 Persistence on Map Change
- [ ] Saved path invalid if walls/doors changed
- [ ] No validation on depersist

---

## 9. Regression Test Scenarios

### 9.1 Must-Pass Scenarios
- [ ] Patient walks from reception to GP office
- [ ] Patient uses toilet and returns
- [ ] Doctor idles in office (finds idle tile)
- [ ] Handyman repairs machine across hospital
- [ ] Ambulance finds hospital entrance
- [ ] Map edit (add wall) updates pathfinding
- [ ] Parcel purchase updates pathfinding
- [ ] Save/load preserves paths

### 9.2 Edge Cases
- [ ] Start == End (zero-length path)
- [ ] Start on impassable tile
- [ ] End on impassable tile
- [ ] Completely walled-off area
- [ ] Maximum map size (128x128)
- [ ] All tiles avoid_tile
- [ ] Object visitor max_distance = 0
- [ ] Object visitor callback returns true immediately

---

## 10. Sign-Off

| Check | Verified | Notes |
|-------|----------|-------|
| Tile flags consistent | [ ] | |
| Door logic correct | [ ] | |
| Heuristics admissible | [ ] | |
| Avoid costs correct | [ ] | |
| Staff path requests work | [ ] | |
| Lua boundary safe | [ ] | |
| Memory no leaks | [ ] | |
| Known bugs documented | [ ] | |

**Reviewer**: _______________ **Date**: _______________

---

## Quick Reference: Key Files & Lines

| Component | File | Lines |
|-----------|------|-------|
| Tile flags | th_map.h | 118-179 |
| Flag parsing | th_map.cpp | 52-261 |
| Pathfinding update | th_map.cpp | 1410-1445 |
| Abstract finder | th_pathfind.h/cpp | 98-151 / 39-127 |
| Basic finder | th_pathfind.h/cpp | 153-167 / 129-182 |
| Hospital finder | th_pathfind.h/cpp | 169-178 / 184-232 |
| Idle finder | th_pathfind.h/cpp | 180-210 / 234-352 |
| Object visitor | th_pathfind.h/cpp | 212-235 / 354-461 |
| Pathfinder facade | th_pathfind.h/cpp | 252-332 / 463-677 |
| Min-heap | th_pathfind.cpp | 557-628 |
| Node cache | th_pathfind.cpp | 480-507 |
| Lua Map | map.lua | 1-965 |
| EntityMap | entity_map.lua | 1-218 |
| World queries | world.lua | 2280-2379 |
| Call dispatch | calls_dispatcher.lua | 290-389 |



## Related Pages

- [[21-pathfinding/SUMMARY]]
- [[21-pathfinding/MAP]]
- [[21-pathfinding/SCAFFOLD]]
