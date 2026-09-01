# 3441 Test Results — 2026-08-31

Branch fix/3441-ultrascan-footprint ef9705d2, 4 tiles blocked, SAVEGAME_VERSION 265 do end.

## Headless load 5000 ticks
- env SDL_VIDEODRIVER=offscreen timeout 20 run-corsixth-dev.sh --load=3441.sav (and with space name) both exit 0, no Lua crash, audio init fail expected (ALSA).
- xvfb-run -a timeout 20 same load exit 0, X connection broken after timeout (expected kill), no error window.
- Simple Lua 5000-tick loop gate on (preserve) 0 crashes, gate off (blocked) 0 crashes (tmp/test_3441_simple.lua).

## New game build + edit placement
- north/east/south/west blocked tiles southern/northern edge, not adjacent to solids per processTypeDefinition:926, origin unchanged, adjacent_to_solid not affected.
- Placement test: handyman {2,0} north {0,2} east outside blocked, south side reachable PASS (tmp/test_placement.lua).
- Build preview 5068 same as idle 1556, wouldNonSideObjectBreakPathfindingIfSpawnedAt:1992 correctly blocks wall-adjacent, new placements blocked, old saves isolated via 265 gate.

## Handyman walk
- Handyman {2,0}/{0,2} REACHABLE, north edge blocked does not affect repair (tmp/test_handyman.lua). Machine isMachine true, answerCall walks south.

## West/south tick anims
- Anim 1556 via copy_north_to_south and orient_mirror FlipHorizontal, patient/doctor multi anims 1560/3084 etc, west/south tick PASS.

## Busted/luacheck
- busted --directory=CorsixTH/Luatest 63/63
- luacheck 0/297 after gate style fix
- whitespace clean for changed files

## Vault
- Deep study 6 areas + matrix 4 tiles FIXED pushed d755c11, migration 265 row pushed.

## Conclusion
- No periodic crash on old save with gate preserve, new saves correctly block walk-through. Hold push per instruction.
