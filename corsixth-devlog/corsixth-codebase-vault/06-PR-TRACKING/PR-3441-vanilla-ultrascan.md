---
pr: 3441
title: Ultrascan footprint does not match original game
status: spec-3441
branch: fix/3441-ultrascan-footprint
base: master
repo: CorsixTH/CorsixTH
created: 2026-08-29
updated: 2026-08-31
labels: [P4 Low, vanilla, footprint]
reviewers: []
related_areas: [16-object-placement, 23-map-tile, 03-room-lifecycle]
---

# PR 3441: Ultrascan footprint does not match original game

## Summary
Vault study for 3441, no code yet. Covers save dimensions, TH original masks, strict vs minimal.

## Status
Spec 3441 done 2026-08-31: busted spec/entities/ultrascanner_3441_spec.lua 2 tests 5000 ticks gate on/off PASS (65/65), gate self.footprint preserve luacheck 0/297, vault primary 16-object-placement/3441-TEST-RESULTS.md (08-QUERIES removed). Branch bf1bf575 hold.

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3441
- Comment https://github.com/CorsixTH/CorsixTH/issues/3441#issuecomment-5459638041
- TH_ORIGINAL_ULTRASCAN.md, VANILLA_FOOTPRINT_MATRIX.md, Ultrascan-footprint-research.md

## Next
Hold PR text and PR draft per instruction; keep only 16/3441-TEST-RESULTS.md primary, branch local bf1bf575.
