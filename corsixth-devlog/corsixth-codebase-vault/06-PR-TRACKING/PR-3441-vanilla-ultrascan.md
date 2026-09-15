---
pr: 3441
title: Ultrascan footprint does not match original game
status: merged
branch: fix/3441-ultrascan-footprint
base: master
repo: CorsixTH/CorsixTH
created: 2026-08-29
updated: 2026-09-14
merged: 2026-09-14
pr_number: 3526
merge_commit: 06b70cd
labels: [P4 Low, vanilla, footprint, PR:Bugfix]
reviewers: [tobylane, TheCycoONE, ARGAMX]
approvals: [TheCycoONE, ARGAMX]
related_areas: [16-object-placement, 23-map-tile, 03-room-lifecycle]
---

# PR 3441: Ultrascan footprint does not match original game — Merged 3526

## Summary
Fix Ultrascan walk through gap (4 tiles) with footprint block. North {-1,1},{0,1} and east {1,-1},{1,0} now blocked (south copies north, west mirrors east), use_position {0,-1} kept passable. No 265 preserve — removed after review (did nothing, old saves keep old footprint via normal save data). Closes #3441.

## Status
Merged PR #3526 Sep 14 2026 by ARGAMX → master (06b70cd, branch fix/3441-ultrascan-footprint) — 5/6 checks passed. Reviewed tobylane (remove 3441 tags, local paths), Approved TheCycoONE 2026-09-11 + ARGAMX 2026-09-14. 4 pushes Sep 4 Sep 5 Sep 9 Sep 10 (ce32797 → e719ab4 → 63e0c2a → 06b70cd). Final fix: moved east block from {-1,1},{0,1} north edge to {1,-1},{1,0} eastern column to avoid shifted draw (east {0,-1} is use_position).

## Test
- busted spec/entities/ultrascanner_3441_spec.lua 2 tests north/east blocked + 5000 ticks — 65/65 PASS (was 63/63) — local paths ../Lua/... + CorsixTH/Lua/...
- save 3441 Ultrascan footprint.sav offscreen/xvfb 5000 ticks no crash, north correct east fixed after second image red crosses
- luacheck 0/297, changelog.txt removed per ARGAMX (conflict), whitespace clean

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3441
- PR https://github.com/CorsixTH/CorsixTH/pull/3526 (merged)
- Commits: ce32797 → e719ab4 → 63e0c2a → 06b70cd
- Vault: 16-object-placement/3441-TEST-RESULTS.md (primary), 16-object-placement/VANILLA_FOOTPRINT_MATRIX.md, TH_ORIGINAL_ULTRASCAN.md, Ultrascan-room-deep.md
- Images: east shifted (2026-09-04) + red crosses north {-1,1},{0,1} east {1,-1},{1,0}

## Next
Done — vault and roadmap updated, KANBAN moved to Done. Next: #3372 after #1467 machinery, then #2469.
