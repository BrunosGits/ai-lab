# 3441 Test Results — 2026-08-31 — Sprint 13/14

Branch fix/3441-ultrascan-footprint bf1bf575, 4 tiles blocked north {-1,1},{0,1} east {0,-1},{1,-1}, SAVEGAME_VERSION 265 self.footprint preserve.

## Headless load 5000 ticks (real busted spec)
- Busted spec `CorsixTH/Luatest/spec/entities/ultrascanner_3441_spec.lua` 2 tests: north/east blocked (no only_passable) + Object:afterLoad old<265 preserve 5000 ticks — **65/65 successes** (was 63/63) via `busted --directory=CorsixTH/Luatest`
- Real persist.load mock: mock object with old footprint {{-1,1,only_passable},{0,1,only_passable}} afterLoad 264->265 preserves (no re-occupation), 5000 loop 0 crashes
- Offscreen/xvfb timeout 20 --load=3441.sav also exit 0 no Lua crash (audio ALSA fail expected)

## New game build + edit placement
- north/east/south/west blocked tiles southern/northern edge, not adjacent to solids per processTypeDefinition:926, origin unchanged, adjacent_to_solid not affected.
- Placement test: handyman {2,0} north {0,2} east outside blocked, south side reachable PASS (tmp/test_placement.lua).
- Build preview 5068 same as idle 1556, wouldNonSideObjectBreakPathfindingIfSpawnedAt:1992 correctly blocks wall-adjacent, new placements blocked, old saves isolated via 265 gate.

## Handyman walk
- Handyman {2,0}/{0,2} REACHABLE, north edge blocked does not affect repair (tmp/test_handyman.lua). Machine isMachine true, answerCall walks south.

## West/south tick anims
- Anim 1556 via copy_north_to_south and orient_mirror FlipHorizontal, patient/doctor multi anims 1560/3084 etc, west/south tick PASS.

## Busted/luacheck
- busted --directory=CorsixTH/Luatest 65/65
- luacheck CorsixTH/Lua/entities/object.lua OK (self.footprint preserve, 0/297)
- whitespace clean for changed files

## Vault
- Primary: `02-SUBSYSTEMS/16-object-placement/3441-TEST-RESULTS.md` (this file) — keep only this, `08-QUERIES/3441-test-results.md` removed as secondary alias
- Deep study 07-STUDY-LOG/2026-08-31-3441-deep-study.md 6 areas, matrix 4 tiles FIXED

## Conclusion
- No periodic crash on old save with gate self.footprint preserve, new saves correctly block walk-through. Hold PR per instruction.
