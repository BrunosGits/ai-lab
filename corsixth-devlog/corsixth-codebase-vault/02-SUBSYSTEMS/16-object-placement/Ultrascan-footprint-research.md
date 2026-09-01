# Ultrascan Footprint Research — 3441 — Sprint 6

## Files
- CorsixTH/CorsixTH/Lua/objects/machines/ultrascanner.lua:42-95 thob 22, idle 1556, build_preview 5068 (Sprint 3-4: 4 tiles blocked)
- CorsixTH/CorsixTH/Lua/rooms/ultrascan.lua:14-18 id ultrascan, class UltrascanRoom, minimum_size 4
- Lua/entities/object.lua:61-107 initOrientation, 444-484 occupyTiles, 890-930 afterLoad gate 265
- Lua/app.lua:31 SAVEGAME_VERSION 265

## Flags
only_passable, complete_cell, need_west_side, need_north_side, render_attach_position. East has render_attach_position {0,0},{1,0},{-1,1}.

## Vanilla comparison
See TH_ORIGINAL_ULTRASCAN.md and VANILLA_FOOTPRINT_MATRIX.md. Sprint 6: minimal symmetric 4 tiles blocked (north {-1,1},{0,1} east {0,-1},{1,-1}); strict rows (-1,-1,1,-1,1,0) out-of-scope for P4. New saves use blocked; old saves preserved via 265 gate.

## Use positions
use_position north {-1,0,need_west_side}, secondary {1,-1}, handyman {2,0}. East {0,-1}, secondary {-1,1}, handyman {0,2}. Doctor walk bug at {-1,1}/{0,1} gap fixed via passable=false. Handyman {2,0}/{0,2} still reachable (south), north edge blocked does not affect.

## Save
3441.sav 2.7M (bd381b01) zip 907K (9b3ffe5f), map 128x128, thob 22 at contested position. Validated Sprint 2 inflated to build/saves/. Old-save crash hypothesis: object_type new vs self.footprint/map.th old mismatch → periodic Lua crash (5482117933). Mitigated via old<265 preserve (no re-occupation).

## Gate
Object:afterLoad:892 old<265 preserve comment, app.lua:31 265. Strict remain backlog.

## Links
VANILLA_FOOTPRINT_MATRIX.md, PR-3441, 03-room-lifecycle Ultrascan-room-deep.
