# TH Original Ultrascan — thob 22

## Source
- Issue 3441 original screenshot 7f209963 (575x355) vs CorsixTH 1a8bf86e, save 3441.sav (907K zip, 2.7M sav, TH.map)
- CorsixTH definition CorsixTH/CorsixTH/Lua/objects/machines/ultrascanner.lua:42-95, thob 22, build_preview_animation 5068
- No disassembly yet, measured from screenshot grid. TODO verify via TH.exe thob 22.

## Current CorsixTH
North 8 tiles as in 07-STUDY-LOG 2026-08-29. East 8 tiles. South copies north, west mirrored.

## Vanilla masks (measured)
Strict 1:1 vanilla — all side column tiles solid, no only_passable on {-1,0},{-1,1},{-1,-1} where original shows wall adjacency. East side column {1,-1},{1,0},{1,1} also solid where original blocks passage.
- North strict: {-1,-1,complete_cell,need_west_side},{0,-1,complete_cell},{1,-1,complete_cell},{-1,0,need_west_side},{0,0},{1,0},{-1,1,need_west_side},{0,1}
- East strict: {-1,-1,complete_cell},{0,-1,need_north_side},{1,-1,need_north_side},{-1,0,complete_cell},{0,0},{1,0},{-1,1,complete_cell},{0,1}

Minimal — only the contested gap where doctor stands ({-1,0}):
- North minimal: change {-1,0,only_passable,need_west_side} to {-1,0,need_west_side} (remove only_passable)
- East minimal: change {-1,0,complete_cell} stays, but adjust {0,1} handling if needed

South and west derived via copy_north_to_south and orient_mirror, so fix north/east covers all.

## Save compat
Strict may invalidate a few old saves where ultrascanner sits in now blocked spot. Minimal preserves all saves. Note in 12-saveload-migrations if strict.

## Next
Grid overlay of 7f209963 pending, and Tools/th_original_dump for thob 22.
