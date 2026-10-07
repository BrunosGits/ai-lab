# Loo — thob 51 (Toilets) — vanilla-parity deep note

Scope: loo (thob 51, display "Toilet"). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="loo"` :22, `thob=51` :23; `ticks=false` :26; preview `5098` :27; `dynamic_info=true` :28
- `copy_north_to_south`; idle north `1760`; `usage` north (+south copy): 5 phases × 12 types (begin/begin_2/in/finish/finish_2), incl. bugged anim note
- Patient markers across phases :110-118
- `orientations` north+east only: north `{0,0 complete},{0,1 only_passable}` + `use="passable"` + animate-from-use; east `{0,0 complete},{1,0 only_passable}`
- Room `rooms/toilets.lua:22-37`: id toilets, level 29, `objects_needed={loo=1,sink=1}`, preview 5098, facilities 3, min 4; `:49-60` counts loos→maximum_patients; `:74` `findFreeObjectNearToUse(loo)` with random use + `toilet_need` drain + sink follow-up (Standard only)

THOB + cost: `base_config.lua:271`: `{StartCost=300, StartAvail=1, StartStrength=10}, -- 51 Toilet`. Room `[29] Cost=1170`.

## 2. Original TH data

- Base + room rows match (proxy). Strings `original_strings.lua:175,1821`.
- `patient.lua:129-133` thirst/toilet_need init. No thob-51 disassembly; no overlay.

## 3. Footprint-compare

- N `{0,0},{0,1p}`, E `{0,0},{1,0p}`; `use="passable"` → first passable; nearest solid d=1 → single-dir; no recenter.
- N+E only; S=copy, W/E-S via mirror + flip. East footprint distinct (side vs front) — orientation semantics unverified.
- Strict/minimal unfiled.

## 4. Behavior checklist

- Passable-use per orient, animate-from-use, markers present. No secondary/finish/slave/smoke; no `default_strength` → no repair.
- Room capacity = loo count; single-loo private. Soak/save pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 51 | match (proxy) | `loo.lua:23` vs `base_config.lua:271` |
| cost 300 / avail 1 | match (proxy) | `base_config.lua:271` |
| room needs loo+sink | match (proxy) | `toilets.lua:29-31` |
| 2-tile N/E | unverified | `loo.lua:122,127` |
| 5-phase 12-type anims + markers | unverified | `:33-118` |
| toilet_need + sink chain | unverified parity | `toilets.lua:74+` |

## 6. Fact vs Inference vs Hypothesis

- Fact: thob/cost/room/anims/footprints as cited.
- Inference: no-shift, mirror derivation.
- Hypothesis: front-vs-side matches vanilla cubicle side.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: overlay; `original_cells` vs SAM; disassemble thob-51; soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
