---
pr: 3441
title: Ultrascan footprint does not match original game
status: tests-done
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
Tests done 2026-08-31: headless offscreen/xvfb 5000 ticks 0 crashes, placement north/east/south/west PASS, handyman REACHABLE, west/south anim PASS, busted 63/63 luacheck 0. Results in 08-QUERIES/3441-test-results.md. Branch ef9705d2 hold per instruction.

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3441
- Comment https://github.com/CorsixTH/CorsixTH/issues/3441#issuecomment-5459638041
- TH_ORIGINAL_ULTRASCAN.md, VANILLA_FOOTPRINT_MATRIX.md, Ultrascan-footprint-research.md

## Next
Next: await push approval; branch local only, vault 13 pushes done.
