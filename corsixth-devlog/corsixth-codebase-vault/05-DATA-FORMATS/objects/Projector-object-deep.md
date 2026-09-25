# Projector Object Deep — thob 37

## 1. CorsixTH definition — Documented fact
- `Lua/objects/projector.lua:22`: `id="projector"`, `:23` `thob=37`; no research fields.
- `:27` `ticks=false`; `:28` `build_preview_animation=5086`; `:30` `show_in_town_map=true`.
- `:32-35` `idle_animations` north=2586, south=2586 (explicit, not copy).
- `:37-49` `usage_animations` Doctor-only: `begin_use=2594`, `begin_use_2=2590`, `begin_use_3=2598`, `in_use=2602`, `finish_use=2606`, `finish_use_2=2610`, `finish_use_3=2684`; south copied.
- `:51-55` Staff markers on `begin_use_2/3/in_use/finish_use/2` at kf2 `{ -0.4, 0.5 }`; finish_use_2 also at frames 11,16 with kf1 `{0,0}`.
- `:57-67` orientations: north footprint 4 tiles `{0,0 only_passable},{0,1},{-1,0},{-1,1}`, `use_position="passable"`; east footprint `{0,0 only_passable},{0,-1},{1,0},{1,-1}`, `use_position="passable"`.
- No `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke — Object not Machine.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:257`: thob 37 row: `StartCost=100, StartAvail=0, StartStrength=10, AvailableForLevel=0` comment `37 Projector`.
- `training.lua:30`: `objects_needed={lecture_chair=1, projector=1}` — required.
- `training.lua:42`: `categories.facilities=4`; `:43` `minimum_size=4`; green wall, floor 17; `:46` `required_staff=none` (no staff req).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 37 | `projector.lua:23` | `base_config.lua:257` | match (proxy; EXE pending) |
| cost 100 / strength 10 | `base_config.lua:257` | `base_config.lua:257` | match (proxy) |
| footprint 4 tiles | `projector.lua:59-66` | no EXE mask / overlay | unverified |
| `use_position="passable"` | keyword → first `only_passable` | unknown | unverified |
| Doctor anims 2594-2684 | `projector.lua:37-49` | DAT/ANI not decoded | unverified |
| Staff markers kf2 | `projector.lua:51-55` | CorsixTH tuning | Inference (no vanilla equiv) |
| required in training | `training.lua:30` | no TH room table extracted | unverified |

## 4. Footprint-compare [Inference]
- 2x2 block with only `(0,0)` passable; `use_position="passable"` resolves to `(0,0)` in both orients (`object.lua:945-954`).
- Mirror derives east from north; south copied from north (explicit).
- No `need_*_side`, no `early_list`, no slave, no crash/smoke.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay training room both orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-37; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.