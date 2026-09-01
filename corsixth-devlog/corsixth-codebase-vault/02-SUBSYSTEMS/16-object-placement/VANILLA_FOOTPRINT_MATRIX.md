# Vanilla Footprint Matrix — Ultrascan (3441) — Sprint 6 symmetric minimal (4 tiles)

| Orientation | Tile | Current (CorsixTH) | Strict vanilla | Minimal | Impact |
|-------------|------|--------------------|----------------|---------|--------|
| north | -1,-1 | need_west_side | complete_cell+need_west_side | need_west_side | Strict blocks corner wall adjacency, fixes build where original blocks |
| north | 1,-1 | only_passable+complete_cell | complete_cell | only_passable+complete_cell | Strict makes top-right solid |
| north | -1,0 | only_passable+need_west_side | need_west_side | need_west_side | Minimal flips contested gap where doctor stands |
| north | 1,0 | only_passable | blocked | only_passable | Strict blocks walk through table |
| north | -1,1 | only_passable+need_west_side → **blocked** (need_west_side) | need_west_side | **blocked** | **FIXED Sprint6 north: passable=false** |
| north | 0,1 | only_passable → **blocked** | blocked or only_passable | **blocked** | **FIXED Sprint6 north: passable=false** |
| east | -1,-1 | complete_cell | complete_cell | complete_cell | No change |
| east | 0,-1 | only_passable+need_north_side → **blocked** (need_north_side) | need_north_side | **blocked** | **FIXED Sprint6 east symmetric** |
| east | 1,-1 | only_passable+need_north_side → **blocked** (need_north_side) | need_north_side | **blocked** | **FIXED Sprint6 east symmetric** |
| east | 1,0 | only_passable | blocked | only_passable | Strict blocks walk through |

South copies north, west mirrored via orient_mirror:object.lua:29. Origin shift via processTypeDefinition:926 nearest solid to use_position. 4 tiles blocked (north {-1,1},{0,1} east {0,-1},{1,-1}) in 3441 minimal; remaining strict rows ( -1,-1, 1,-1, 1,0 ) marked **out-of-scope** for this P4 fix.

World:occupyTilesByObjectFootprintAt:465 enforces passable=false. Old saves preserved via SAVEGAME_VERSION 265 gate Object:afterLoad:892 (no re-occupation) to avoid periodic crash noted in 5482117933. Strict out-of-scope rows remain P4 backlog.
