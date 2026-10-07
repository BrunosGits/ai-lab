# Crash trolley — thob 20 — vanilla-parity deep note

Scope: crash_trolley (thob 20). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

Lua `~/CorsixTH/CorsixTH/Lua/objects/crash_trolley.lua` (150 lines):
- `id="crash_trolley"` :22, `thob=20` :23, `research_category="diagnosis"` :24; `ticks=false` :27; preview `916` :28; town-map true :29
- `copy_north_to_south`; idle north `3838` (+ comment: 1134/1132 back view missing)
- `multi_usage_animations`: 6 keys (Stripped M/F ×3), each north begin/in/finish triples; doctor secondary
- `orientations`: north 1 solid `(-1,0)` + 3 passable, explicit use + secondary; east 1 solid `(0,-1)` + 3 passable, explicit use + secondary; split `render_attach` lists
- Markers for staff+patient across variants :101-148
- Absent: slave, crash/strength/smoke/handyman, `early_list`.

Rooms:
- `rooms/general_diag.lua:30` — `objects_needed = {screen=1, crash_trolley=1}` (required); `:62` `findObjectNear`; `:65` `getSecondaryUsageTile`; `:92` `MultiUseObjectAction` with `setProlongedUsage(false)`

THOB + cost: `base_config.lua:240`: `{StartCost=250, StartAvail=1, StartStrength=10}, -- 20 Crash Trolley`. Room preview 916 matches.

## 2. Original TH data

- `base_config.lua:240` — cost 250, avail 1, strength 10.
- Strings `original_strings.lua:144` (`S[2][21]`); tooltip `:1790` (`S[40][21] -- no description`).
- No thob-20 disassembly; no overlay.

## 3. Footprint-compare

- north: solids→1, passables→3, use + secondary explicit; east mirrored arrangement. south=north; west via mirror.
- Recenter: nearest solid d=1 both orients → post-shift converges with swapped use/secondary (hand-derived, needs dump).
- Split `render_attach` shifts with footprint.
- Strict/minimal unfiled.

## 4. Behavior checklist

- Dual-humanoid (patient use + doctor secondary) via `MultiUseObjectAction`, not slave. Both tiles must stay reachable post-shift.
- 6 multi-use keys + markers present; alignment proof pending.
- Crash/repair N/A. Soak + save/load, `busted`/`luacheck`: not run. Dual-occupancy = higher regression risk.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| id / thob 20 | match (proxy) | `crash_trolley.lua:22-23` vs `base_config.lua:240` |
| cost 250 / avail 1 / strength 10 | match (proxy) | `base_config.lua:240` |
| required in general_diag + dual-use | match | `general_diag.lua:30,62,65,92` |
| 1+3 footprint N/E | unverified | `crash_trolley.lua:87-88,94-95` |
| idle/multi-use/markers | unverified | `crash_trolley.lua:35,40-50,102-148` |
| overlay/save/soak | pending | none exists |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua shape, dual-use wiring, base row, strings, missing-back-view comment, mirror rules.
- Inference: post-shift convergence, dual-occupancy risk.
- Hypothesis: 1+3 footprint + markers equal vanilla. Needs EXE + overlay + trace.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: (1) runtime dump; (2) overlay; (3) reachability both tiles; (4) marker trace; (5) soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
