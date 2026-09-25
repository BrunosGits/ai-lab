# Bed Object Deep — thob 8

## 1. CorsixTH definition — Documented fact
- `Lua/objects/bed.lua:22`: `id="bed"`, `:23` `thob=8`; `:24` `research_category="diagnosis"`; `:27` `ticks=false`; `:28` `build_preview_animation=910`; `:30` `show_in_town_map=true`.
- `:32-35` `idle_animations` north=2644, east=2646 (no south/west — mirror).
- `:37-67` `usage_animations`: Standard M/F Patient only; `begin_use` (lie down), `in_use` (use), `finish_use` (stand up); per-orient explicit north/east. South/west not defined — mirror.
- `:69-88` patient markers on begin/in_use/finish (kf1/kf2/kf3).
- `:90-122` orientations: all 4 explicit — north footprint 5 tiles `{1,-1 only_passable},{-1,-1 complete},{0,-1 complete},{-1,0 complete},{0,0 complete}`, `use_position={1,-1}`, `early_list=true`; east footprint 5 tiles `{0,1 only_passable},{-1,-1 complete},{0,-1 complete},{-1,0 complete},{0,0 complete}`, `use_position={0,1}`, `early_list=true`; south footprint 5 tiles `{1,0 only_passable},{-1,-1 complete},{0,-1 complete},{-1,0 complete},{0,0 complete}`, `use_position={1,0}`, `render_attach_position={{-2,0},{-1,0},{0,0},{0,-1}}`; west footprint 5 tiles `{-1,1 only_passable},{-1,-1 complete},{0,-1 complete},{-1,0 complete},{0,0 complete}`, `use_position={-1,1}`.
- No `handyman_position`, `use_position_secondary`, slave, crashed/smoke — Object (despite `research_category` field, no `ticks` or Machine behaviour).

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:228`: thob 8 row: `StartCost=200, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `8 Bed`.
- Used in ward rooms (not explicitly required by a single room type).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 8 | `bed.lua:23` | `base_config.lua:228` | match (proxy; EXE pending) |
| cost 200 / strength 10 | `base_config.lua:228` | `base_config.lua:228` | match (proxy) |
| footprint 5 tiles (all 4 orients) | `bed.lua:90-122` | no EXE mask / overlay | unverified |
| `early_list=true` north/east | `bed.lua:105,115` | unknown | unverified |
| `render_attach_position` array (south) | `bed.lua:117` | unknown | unverified |
| Standard M/F only (no variants) | `bed.lua:37-67` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:228` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- All 4 orients explicit 5-tile (4 complete + 1 passable at corner).
- `early_list=true` on north/east affects build-order per `object.lua:513-528`; absent on south/west — asymmetry.
- `render_attach_position` array on south only (4 positions for bed ends).
- No `copy_north_to_south` — all 4 hand-written.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay ward room all 4 orients; `original_cells` dump vs SAM; disassemble thob-8; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.