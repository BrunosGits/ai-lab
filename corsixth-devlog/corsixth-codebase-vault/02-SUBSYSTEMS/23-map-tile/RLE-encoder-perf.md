# RLE Save Encoder Performance (#3545)

> Investigation notes for `integer_run_length_encoder`
> (`CorsixTH/Src/run_length_encoder.{h,cpp}`), used only by
> `th_map.cpp` persist: `encoder(6)` live cells, `encoder(5)`
> original cells. Decoder: `integer_run_length_decoder`, untouched.

## Related Pages

- [[SUMMARY]] — Map persist/depersist layout
- [[CHECKLIST]]
- [[MAP]]
- [[PR-3545-rle-encoder]] — Tracking, measurements, PR status

## How the encoder works

- Circular fixed buffer (`record_size * 8 * 4` ints: 192 for map
  records of 6, 160 for original records of 5). Neither is a power
  of 2, so every `% buffer.size()` is a real division.
- `flush()` searches object sizes 1-8 records x offsets for the
  most repeats (ties go to smallest size), emits header word
  `(records-1) + 8*(count-1)` plus literals. Decoder reads whatever
  valid encoding results, so match decisions affect bytes but never
  validity.
- Contract (established 2026-09-19): total input length must be a
  multiple of `record_size`. Map data always satisfies this
  (width x height x 6 and x 5). A non multiple tail makes the final
  blob header under-claim its literals. Not hit by real callers.

## Hotspot breakdown (measured, VPS harness, -O2)

| Dataset | Baseline | Final (128 buf) | Speedup |
|---------|----------|-----------------|---------|
| Map-like 99k ints | 23.4ms | 2.7ms | 8.7x |
| Random (worst) | 67ms | 5.1ms | 13x |
| Zeros | 7.9ms | 2.7ms | 2.9x |

Call stats (map-like): 52k `are_ranges_equal` calls for 180k input
ints, avg 23 ints per call. 180k `write()` divisions.

## Variants tried (all in `/tmp/rle_bench`, repo untouched)

1. Wrap branch instead of modulo in compare loop: 3.3x.
2. `memcmp` over contiguous runs: 4.3x.
3. Division free `write()` (single subtract, documented invariant):
   5.8x combined.
4. Skip trivial self compare `are_equal(0,0,...)` in `flush()`
   search: identical decisions, worst case 3.9x to 5.5x.
5. Power of 2 buffer + mask (ticket's explicit suggestion).
   Sweep 64/128/256/512/1024, all round trip OK:
   128 wins (fastest, same output size as baseline everywhere).
   64 rejected (43% bigger output, window too narrow).

## Verification matrix

- Reference decoder from the format spec: round trip OK on every
  dataset x every buffer size.
- Real binaries (Release, full CD data): baseline vs patched on
  36 fresh level maps and one developed hospital. Saves load back
  in the unpatched binary, ticks run, resaves clean.
- Save sizes ±4% by layout versus baseline, no systematic growth.

## Open points

- Remaining save time (~227ms of ~280ms) is Lua entity persist,
  outside #3545.
- Whether RLE survives post #3534 is a maintainer decision.
  Data point: RLE expands random data ~2%.
