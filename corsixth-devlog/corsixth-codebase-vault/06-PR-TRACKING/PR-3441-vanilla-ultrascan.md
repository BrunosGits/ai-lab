---
pr: 3441
title: Ultrascan footprint does not match original game
status: sprint2-save
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
Sprint 2/8 save verified. Zip 907K (sha 9b3ffe5f) sav 2.6M (bd381b01) 2717590 bytes, 128x128, thob 22, inflated to build/saves/"3441 Ultrascan footprint.sav". Headless baseline pending build rebuild (build/ missing after sync). Timebox 30m.

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3441
- Comment https://github.com/CorsixTH/CorsixTH/issues/3441#issuecomment-5459638041
- TH_ORIGINAL_ULTRASCAN.md, VANILLA_FOOTPRINT_MATRIX.md, Ultrascan-footprint-research.md

## Next
Sprint 3: north footprint fix {-1,1},{0,1} (ultrascanner.lua:73-75).
