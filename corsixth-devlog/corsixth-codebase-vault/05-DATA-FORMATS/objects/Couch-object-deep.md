# Couch — thob 18 — vanilla-parity deep note

Scope: couch (thob 18). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

Lua `~/CorsixTH/CorsixTH/Lua/objects/couch.lua` (65 lines):
- `id="couch"` :22, `thob=18` :23, `research_category="diagnosis"` :24; `ticks=false` :27; preview `5064` :28; no `show_in_town_map`
- `copy_north_to_south`; idle north `2540`
- `usage_animations` north only: `begin_use` (Elvis 1014, Male 2528, Female 3180), `in_use` (942, 2536, 3330), `finish_use` (938, 2532, 3326)
- `orientations`: north footprint `{(-1,-1),(-1,0) complete; (0,-1),(0,0) passable}`, `render_attach={-1,0}`, NO `use_position`; east transposed, NO `use_position`
- Absent: slave, crash/strength/smoke/handyman, `early_list`.

Rooms:
- `rooms/psych.lua:30` — `objects_needed` includes `couch=1` (required); `:84-86` `findObjectNear` + `UseObjectAction`; `:94` `user_of==couch` gates consult timer
- Save-compat: `entities/object.lua:913-919` — `if old<173` + `id=="couch"` then re-init ("Fix bug with couch not being fully passable")

THOB + cost: `base_config.lua:238`: `{StartCost=100, StartAvail=1, StartStrength=10}, -- 18 Couch`.

## 2. Original TH data

- `base_config.lua:238` — cost 100, avail 1, strength 10.
- Strings `original_strings.lua:142` (`S[2][19]`); tooltip `:1788` (`S[40][19] -- no description`).
- `research_category="diagnosis"` is CorsixTH bookkeeping; vanilla-req proof pending.
- No thob-18 disassembly; no overlay.

## 3. Footprint-compare

- north: solids west column, passables east column; east: transposed. south=north; west via mirror. Compare N/E only.
- No `use_position` → defaults `{0,0}` (passable both orients). Recenter on nearest solid: north `(-1,0)` d=1 → shift; east `(0,-1)` → shift. Post coords need runtime confirm (hand-derived).
- The `old<173` fix implies historic passability bug — current shape may already be fixed, vanilla-equality still unproven.
- Strict/minimal unfiled.

## 4. Behavior checklist

- Patient 3-variant anims north-only + mirror; no staff markers. Default use must stay reachable; `render_attach {-1,0}` shifts with footprint.
- Psych timer depends on `user_of==couch` — occupancy break would stall countdown silently.
- Soak + save/load (esp. `old<173` path), `busted`/`luacheck`: not run.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| id / thob 18 | match (proxy) | `couch.lua:22-23` vs `base_config.lua:238` |
| cost 100 / avail 1 / strength 10 | match (proxy) | `base_config.lua:238` |
| required in psych | match | `psych.lua:30,84-86,94` |
| 2x2 footprint N/E | unverified | `couch.lua:57,61` |
| idle/anims | unverified | `couch.lua:34,39-51` |
| save-migration fix | match (exists) | `object.lua:913-919` |
| overlay/save/soak | pending | none exists |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua shape, psych wiring, base row, strings, `old<173` fix, mirror rules.
- Inference: post-shift coords (hand-derived, needs dump).
- Hypothesis: 2x2 half-solid transposed equals vanilla; fix did not diverge. Needs EXE + overlay.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: (1) runtime pre/post dump; (2) overlay; (3) reachability; (4) soak incl. old-save path + `busted`/`luacheck`.
- Result: FAIL (pending).
