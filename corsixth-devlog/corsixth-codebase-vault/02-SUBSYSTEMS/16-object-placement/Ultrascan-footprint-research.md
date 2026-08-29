# Ultrascan Footprint Research — 3441

## Files
- CorsixTH/CorsixTH/Lua/objects/machines/ultrascanner.lua:42-95 thob 22, idle 1556, build_preview 5068
- CorsixTH/CorsixTH/Lua/rooms/ultrascan.lua:14-18 id ultrascan, class UltrascanRoom, minimum_size 4
- Lua/entities/object.lua:61-107 initOrientation, 444-484 occupyTiles

## Flags
only_passable, complete_cell, need_west_side, need_north_side, render_attach_position. East has render_attach_position {0,0},{1,0},{-1,1}.

## Vanilla comparison
See TH_ORIGINAL_ULTRASCAN.md and VANILLA_FOOTPRINT_MATRIX.md. Current 8 tiles, strict would be 5-6 solid, minimal flips 1 tile.

## Use positions
use_position north {-1,0,need_west_side}, secondary {1,-1}, handyman {2,0}. East {0,-1}, secondary {-1,1}, handyman {0,2}. Doctor walk bug in 3441 is at {-1,0} gap.

## Save
3441.sav 2.7M, map 128x128, thob 22 at contested position.
