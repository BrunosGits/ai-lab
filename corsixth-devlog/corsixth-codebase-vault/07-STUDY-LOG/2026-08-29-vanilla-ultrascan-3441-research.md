---
date: 2026-08-29
tags: [vanilla, th-original, footprint-parity, 3441, ultrascan]
areas: [16-object-placement, 23-map-tile, 03-room-lifecycle]
prs: [3441]
---

# Vanilla Ultrascan 3441 — Research

## Issue
#3441 — Ultrascan footprint does not match original game. Assigned to ARGAMX, P4 Low. Comment https://github.com/CorsixTH/CorsixTH/issues/3441#issuecomment-5459638041 confirms taken. Original TH screenshot 7f209963 and CorsixTH screenshot 1a8bf86e show room can be built in CorsixTH where vanilla blocks it. Doctor stands between table and wall where no space should exist. Save 3441 Ultrascan footprint.sav.zip attached.

## Save dimensions
- URL: https://github.com/user-attachments/files/29718656/3441.Ultrascan.footprint.sav.zip
- HEAD 302 to objects.githubusercontent.com, 907K zip, 2717590 bytes sav, single file 3441 Ultrascan footprint.sav (2026-07-06 17:28)
- Header: Lua persistence, TH.map.<mt>, Graphics.loadSpriteTable, VBLK
- Map: 128x128 per vault 23-map-tile, original_cells snapshot preserved
- Room ultrascan minimum_size 4, thob 22, build_preview_animation 5068

## Current footprint (CorsixTH)
File CorsixTH/CorsixTH/Lua/objects/machines/ultrascanner.lua:75-95, north 8 tiles, east 8 tiles, south copies north, west mirrored.
North: {-1,-1,need_west_side},{0,-1,complete_cell},{1,-1,only_passable,complete_cell},{-1,0,only_passable,need_west_side},{0,0},{1,0,only_passable},{-1,1,only_passable,need_west_side},{0,1,only_passable}
East: {-1,-1,complete_cell},{0,-1,only_passable,need_north_side},{1,-1,only_passable,need_north_side},{-1,0,complete_cell},{0,0},{1,0,only_passable},{-1,1,only_passable,complete_cell},{0,1,only_passable}
Flags: only_passable, complete_cell, need_west_side, need_north_side per 16-object-placement.

## Vanilla oracle (screenshot-measured)
Original TH image shows corner cells around ultrascanner table are impassable, not only_passable. Expected: {-1,0},{-1,1},{-1,-1} side column should be solid/complete, not passable. Exact mask pending grid overlay, but issue indicates at least 2-3 tiles differ.

## Approaches
- Strict 1:1 vanilla: flip all three side-column only_passable to blocked, add complete_cell where original shows wall. Breaks a few old saves where object sits in now blocked spot, but most correct. Note save compat in 12-saveload-migrations.
- Minimal corner: only flip the single contested corner where doctor stands ({-1,0} need_west_side). Preserves all old saves, less faithful.

Both will be documented in VANILLA_FOOTPRINT_MATRIX.md for decision before code sprint. Disassembly of TH.exe thob 22 placement routine is open question for next sprint.

## Open questions
- Exact vanilla mask per orientation (need grid overlay of 7f209963)
- TH disassembly address for footprint validation (Tools/TH disasm)
- LevelEdit handling of original block IDs
