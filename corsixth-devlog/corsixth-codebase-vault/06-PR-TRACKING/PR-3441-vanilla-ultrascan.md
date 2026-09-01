---
pr: 3441
title: Ultrascan footprint does not match original game
status: sprint4-east
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
Sprint 4/8 east done. ultrascanner.lua:83-84 {0,-1},{1,-1} only_passable removed keep need_north_side → blocked symmetric to north. 4 tiles total blocked (north 2 + east 2). Gate pending. Timebox 30m.

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3441
- Comment https://github.com/CorsixTH/CorsixTH/issues/3441#issuecomment-5459638041
- TH_ORIGINAL_ULTRASCAN.md, VANILLA_FOOTPRINT_MATRIX.md, Ultrascan-footprint-research.md

## Next
Sprint 5: SAVEGAME_VERSION 265 + Object:afterLoad gate.
