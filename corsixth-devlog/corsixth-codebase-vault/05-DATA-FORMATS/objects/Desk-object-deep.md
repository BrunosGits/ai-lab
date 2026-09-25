# Desk Object Deep — thob 1

## 1. CorsixTH definition — Documented fact
- `Lua/objects/desk.lua:22`: `id="desk"`, `:23` `thob=1`; `:27` `ticks=false`; `:28` `build_preview_animation=900`; `:30` `show_in_town_map=true`.
- `:32-35` `idle_animations` north=48, east=50 (no south/west — mirror fallback).
- `:37-81` `usage_animations`: Doctor + Nurse; `begin_use` (Doctor 56/58, Nurse 3240/3242); `in_use` Doctor list (72×11 + 718 head-scratch), Nurse 3256/3258; `finish_use` Doctor 64/66, Nurse 3248/3250; per-orient explicit north/east (no south/west copy — mirror).
- `:83-135` extensive staff markers on begin/in_use/finish for both Doctor/Nurse, both orients (kf1/kf2/kf3 keyframes).
- `:137-178` orientations: north footprint 5 tiles `{-2,-1 complete},{-1,-1 complete},{-1,0 complete},{0,-1 need_north_side},{0,0 only_passable}`, `render_attach_position={0,-1}`, `use_position="passable"`; east footprint 6 tiles `{0,-2 need_east_side},{-1,-1 complete},{0,-1 complete},{-1,0 only_passable},{0,0 complete},{-1,-2 only_passable}`, `render_attach={0,-1}`, `use_position={-1,0}`, `finish_use_position={-1,-2}`; south footprint 6 tiles `{0,-1 only_passable},{-2,0 need_south_side},{-1,-1 complete},{-1,0 complete},{0,0 complete},{-2,-1 only_passable}`, `render_attach={-2,0}`, `use_position={0,-1}`, `finish_use_position={-2,-1}`; west footprint 5 tiles `{-1,-2 complete},{0,0 only_passable},{-1,-1 complete},{0,-1 complete},{-1,0 need_west_side}`, `render_attach={-1,0}`, `use_position="passable"`.
- No `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke — Object not Machine.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:221`: thob 1 row: `StartCost=100, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `1 Desk`.
- `research.lua:38`: `objects_needed={desk=1,cabinet=1,autopsy=1}` — required in research.
- `research.lua:65`: `staff_usage_objects` includes `desk=true` — staff cycles desk (100 research pts).
- `research.lua:87`: after-use on desk `addResearchPoints(100)`.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 1 | `desk.lua:23` | `base_config.lua:221` | match (proxy; EXE pending) |
| cost 100 / strength 10 | `base_config.lua:221` | `base_config.lua:221` | match (proxy) |
| footprint 5+6 tiles (4 orients) | `desk.lua:137-178` | no EXE mask / overlay | unverified |
| `need_*_side` flags | all 4 orients | unknown | unverified |
| Doctor/Nurse anims + markers | `desk.lua:37-135` | DAT/ANI not decoded | unverified |
| required in research | `research.lua:38` | no TH room table extracted | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:221` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- All 4 orients defined explicitly (north/east/south/west) — no copy/mirror fallbacks.
- `need_north_side` north `{0,-1}`, `need_east_side` east `{0,-2}`, `need_south_side` south `{-2,0}`, `need_west_side` west `{-1,0}` — directional buildable flags per `object.lua:513-528`.
- `finish_use_position` east/south/west explicit; north only `use_position`.
- No `copy_north_to_south` — all 4 hand-written.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay research room all 4 orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-1; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.