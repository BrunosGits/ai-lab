# Pharmacy Cabinet Object Deep — thob 39

## 1. CorsixTH definition — Documented fact
- `Lua/objects/pharmacy_cabinet.lua:22`: `id="pharmacy_cabinet"`, `:23` `thob=39`; `:24` `research_category="cure"`, `:25` `research_fallback=13` (sleeping illness).
- `:28` `ticks=false`; `:29` `build_preview_animation=5088`; `:31` `show_in_town_map=true`; no crashed/smoke — Object.
- `:33-36` `idle_animations` north=1578, south copied.
- `:38-64` `multi_usage_animations`: 5 Nurse variants (Standard M, Standard F, Invisible, Transparent M, Transparent F); each has `begin_use=1590`, `begin_use_2=1594` (Nurse-only), `begin_use_3` (patient-specific), `in_use=1666` (Nurse-only), `finish_use` (patient-specific), `finish_use_2=1598` (Nurse-only); secondary uses patient idle anim.
- `:66-82` orientations: north footprint 4 tiles `{0,0 complete}`, `{0,1 only_passable}`, `{0,2 only_passable}`, `{-1,1 only_passable}`, `use_position={0,1}`, `use_position_secondary={-1,1}`, `use_animate_from_use_position=true`; east footprint 4 tiles `{0,0 complete}`, `{1,0 only_passable}`, `{2,0 only_passable}`, `{1,-1 only_passable}`, `use_position={1,0}`, `use_position_secondary={1,-1}`, `use_animate_from_use_position=true`.
- No `handyman_position`, no `early_list`, no slave, no crashed/smoke.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:259`: thob 39 row: `StartCost=1000, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `39 Pharmacy Cabinet`.
- `pharmacy.lua:30`: `objects_needed={pharmacy_cabinet=1}` — required.
- `pharmacy.lua:57-62`: nurse finds cabinet, computes patient secondary tile via `use_position + use_position_secondary` offset; nurse walks to cabinet, patient walks to secondary tile; `MultiUseObjectAction` with `layer3` flask colour logic (female patients no colour 2).
- Cure price `diseases/sleeping_illness.lua:29`: 600 (not checked here).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 39 | `pharmacy_cabinet.lua:23` | `base_config.lua:259` | match (proxy; EXE pending) |
| cost 1000 / strength 10 | `base_config.lua:259` | `base_config.lua:259` | match (proxy) |
| footprint 4 tiles L-shape | `pharmacy_cabinet.lua:68-82` | no EXE mask / overlay | unverified |
| `use_animate_from_use_position` | true both orients | unknown | unverified |
| Nurse-only anims / layer3 flask | `pharmacy_cabinet.lua:38-64` | original behaviour unverified | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:259` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- L-shape: 3 vertical + 1 side passable (north) / 3 horizontal + 1 side (east). Use on first passable, secondary on side passable.
- `use_animate_from_use_position=true` → patient animates at use tile; nurse at cabinet.
- Mirror derives east from north; no west definition needed.
- No `need_*_side`, no `early_list`, no crash/smoke.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay pharmacy room both orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-39; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.