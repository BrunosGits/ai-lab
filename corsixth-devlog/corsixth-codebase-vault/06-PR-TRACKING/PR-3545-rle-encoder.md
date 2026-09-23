---
pr: 3545
title: "Run length encoder implementation is very expensive"
status: draft
branch:
base: master
repo: CorsixTH/CorsixTH
created: 2026-09-17
updated: 2026-09-19
labels: [Bug, perf, savegame, cpp]
reviewers: []
related_areas: [23-map-tile, 12-saveload-migrations]
---

# PR 3545: Run length encoder implementation is very expensive

## Summary
`integer_run_length_encoder::are_ranges_equal` costs ~25ms per save
(7800X3D, tracy). Autosave stutters. Author note: contained, easily
testable, fairly standard algorithm, tricky implementation.

## Status
Studying. Commented on the issue (studying + findings posted
2026-09-18/19). No PR yet, fork deleted after #3441. Patch held locally
as `/tmp/rle_bench/rle_sw128.cpp` on the VPS.

## Findings
- Encoder is <10% of total save time. Full save of a 2.7MB hospital is
  ~280ms, rest is Lua entity persist (outside this ticket).
- Harness (synthetic map-like data, 99k ints): 23.4ms to 2.7ms.
  Worst case random data: 67ms to 5.1ms.
- Real binary: save 280ms to 227ms on the developed hospital,
  fresh level maps ~91ms to ~57ms.
- Fix: `memcmp` compares, power of 2 buffer (128) with mask indexing,
  division free write path, self compare skip. One file,
  `CorsixTH/Src/run_length_encoder.cpp`. No format change,
  decoder untouched.
- Save sizes vary ±4% by map layout versus baseline, no systematic
  growth. Buffer 64 rejected (43% bigger output on mixed data).
- RLE expands random data ~2%. Relevant input for #3534
  (whole save compression may obsolete RLE for new saves).

## Test
- Reference decoder written from the format spec, round trip OK on
  all datasets and all buffer sizes.
- 36 fresh level maps (levels 1-12 x easy/full/hard): load, save,
  load back in the unpatched binary, all clean.
- Developed hospital: save, load back, 5 ticks, resave, clean.
- Old saves load unchanged (decoder untouched).

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3545
- Related #3534 (compress save games, open idea)
- Vault: [[02-SUBSYSTEMS/23-map-tile/RLE-encoder-perf]]

## Review (PR 3554, draft)
- lewri: no SAVEGAME_VERSION bump without Lua afterload code.
  TheCycoONE agrees. Bump reverted (commit ff1d8c19), PR is now
  th_map.cpp only. No api_version bump unless a maintainer asks.
- TheCycoONE holding further comments, invited to post. Staying
  in draft per ARGAMX process note until review finishes.

## Next
- Address held comments when they land, then undraft.
- Maintainer decision: drop RLE for new saves post #3534.


## Related Pages

- [[PR-3372-pickup-destroy]]
- [[PR-3441-vanilla-ultrascan]]
- [[PR-3504-entity-destruction]]
