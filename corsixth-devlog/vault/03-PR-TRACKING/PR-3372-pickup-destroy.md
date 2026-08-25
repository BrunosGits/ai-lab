---
pr: 3372
title: "Properly destroy entities on pickup again"
status: backlog
branch: 
base: master
repo: CorsixTH/CorsixTH
created: 
updated: 
labels: [entity-system, pickup]
reviewers: []
related_areas: [01-entity-iteration, 16-object-placement]
---

# PR #3372: Properly destroy entities on pickup again

## Summary
#3304 stopped destroying on pickup (object made invisible + kept in `world.entities`), which leaked duplicates → save corruption #3376, patched by band-aid #3370 (`table_contains` guards).

## Approach
Snapshot-and-destroy with tile reservation (reuses #1467 deferred-destruction machinery):
1. Capture move snapshot at pickup, then `destroyEntity`
2. Reserve source footprint tiles during place window
3. Recreate from snapshot on place or Esc-cancel; refund on sell
4. Unify corridor + room-edit paths
5. Remove both `table_contains` band-aids

## Implementation Plan
- [ ] Commit 1: object move snapshot/restore helpers
- [ ] Commit 2: destroy on pickup with tile reservation
- [ ] Commit 3: unify corridor and room-edit pickup paths
- [ ] Commit 4: remove `table_contains` duplicate band-aids
- [ ] Commit 5: pickup/place/cancel/sell/save tests + negative control

## Status
Design complete, implementation pending.
