# Slicer (thob 26) — deep note

## 1. CorsixTH definition [Documented fact]

- `CorsixTH/Lua/objects/machines/slicer.lua:22-23`: `id = "slicer"`, `thob = 26`
- `slicer.lua:24-25`: `research_category = "cure"`, `research_fallback = 7`
- `slicer.lua:28-33`: `ticks = false`, preview 932, `default_strength = 8`, crashed 3400, town_map true, smoke 3464
- `slicer.lua:34-40`: `copy_north_to_south`; idle north 1386
- `slicer.lua:41-45`: Handyman `in_use 3490`; `:46-57` multi-use Slack M 1390 / Slack F 1394
- `:59-68` north: footprint `{ {-1,-1 passable},{-1,0},{-1,1},{0,-1 passable},{0,0 passable need_east_side},{0,1 passable} }`; use `{0,0}`; handyman `{1,-1}`; secondary `{-1,-1}`; smoke `{0,0}`
- `:71-79` east: footprint `{ {-1,-1 passable},{0,-1},{1,-1},{-1,0 passable},{0,0 passable need_south_side},{1,0 passable} }`; use `{0,0}`; handyman `{-1,1}`; secondary `{-1,-1}`; `early_list=true`; smoke `{0,0}`
- `:83,85`: patient marker; staff marker
- Room: `CorsixTH/Lua/rooms/slack_tongue.lua:30` `objects_needed = {slicer=1}`; `:31` preview 932; `:35-37` min 4, blue, floor 17
- Room logic: `slack_tongue.lua:56-57` `findObjectNear` + `getSecondaryUsageTile`; `:79` `MultiUseObjectAction`

## 2. Original TH data [Documented fact unless noted]

- `CorsixTH/Lua/base_config.lua:246` thob 26: `{StartCost=1500, StartAvail=0, StartStrength=10}` comment `26 Slicer for slack tongues`
- Disease: `diseases/slack_tongue.lua:29` cure_price 900; `:55-57` treatment rooms; `:60` `requires_machine=true`
- `HOSPITAL.EXE` thob-26 mask: not disassembled — pending

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 26 | `slicer.lua:23` | `base_config.lua:246` | match (proxy) |
| cost 1500 | via research | `base_config.lua:246` | match (proxy) |
| strength | `default_strength=8` BUT runtime `start_strength=10` | StartStrength 10 | divergence noted: Lua 8 vs base 10 — unverified intent |
| footprint (L-shaped solids) | north `{-1,0},{-1,1}`; east `{0,-1},{1,-1}` | no mask/overlay | unverified |
| `need_east_side`/`need_south_side`, east `early_list` | `slicer.lua:63,73,78` | unknown | unverified |
| anims/markers | `slicer.lua:29,31,33,39,43,49,54,83,85` | DAT/ANI not decoded | unverified |

## 4. Footprint-compare [Inference]

- Post-shift (computed): north use `{0,0}→{1,0}`, handyman `{1,-1}→{2,-1}`; east use `{0,0}→{0,1}`, handyman `{-1,1}→{-1,2}`. Handyman far offset suspect without overlay — confirm reachability after shift.

## 5. strict/minimal + next

- PASS(strict): FAIL. PASS(minimal): N/A — no demonstrated gap.
- Overall: UNVERIFIED (`[T+C]`, V pending). Strength 8-vs-10 stays open.
- Next: grid-overlay tongue clinic both orients; `original_cells` vs SAM; disassemble thob-26; runtime dump + crash/smoke test; soak + save/load + `busted`/`luacheck`.
