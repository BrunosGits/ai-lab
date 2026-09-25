# Analyser (thob 41) — deep note

## 1. CorsixTH definition [Documented fact]

- `CorsixTH/Lua/objects/analyser.lua:22` `object.id = "analyser"`
- `analyser.lua:23` `object.thob = 41`
- `analyser.lua:24` `research_category = "cure"`
- `analyser.lua:25` `research_fallback = 45`
- `analyser.lua:28` `ticks = true`
- `analyser.lua:29` `class = "AtomAnalyser"`
- `analyser.lua:30` `build_preview_animation = 5092`
- `analyser.lua:32-35` `idle_animations = { north = 2134, south = 2134 }`
- `analyser.lua:36-39` `copy_north_to_south` — `south = north`
- `analyser.lua:41-47` `usage_animations` north `in_use Doctor = {4878, object_visible=true}`; south copied
- `analyser.lua:48-57` orientations (pre-shift): north footprint `{ {-1,-1},{0,-1},{1,-1},{-1,0},{0,0 only_passable},{1,0} }`, use `{0,0}`; east footprint `{ {-1,-1},{0,-1},{-1,0},{0,0 only_passable},{-1,1},{0,1} }`, use `{0,0}`
- `analyser.lua:59` `class "AtomAnalyser" (Object)`; `:64-66` ctor delegates to `Object`; `:68-70` `getDrawingLayer() -> DrawingLayers.AtomAnalyser`
- No `default_strength`, no `crashed_animation`, no `smoke_animation`, no `handyman_position`, no slave fields (verified full 72-line read)
- Room: `CorsixTH/Lua/rooms/research.lua:29-37` `objects_additional` includes `"analyser"`; `:38` `objects_needed = {desk=1,cabinet=1,autopsy=1}` — analyser is optional
- Room use: `research.lua:61-66` `staff_usage_objects` includes `analyser = true`; `:96-98` after-use `addResearchPoints(800)` for analyser, vs computer 500, desk 100
- Room meta: `research.lua:43` `minimum_size = 5`, `:44` green wall, `:45` floor 21

## 2. Original TH data [Documented fact unless noted]

- `CorsixTH/Lua/base_config.lua:261` thob 41 row: `{StartCost=10000, StartAvail=0, StartStrength=10}` comment `41 Chemical Mixer`
- `base_config.lua:217` research virtual `I_X_MIXER virtual treatment, atom analyser`, `RschReqd=30000`
- TH label "Chemical Mixer" vs CorsixTH `atom_analyser` display name is a rename — [Inference]
- `HOSPITAL.EXE` thob mask ground truth — not disassembled, pending

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 41 | `analyser.lua:23` | `base_config.lua:261` | match (proxy; EXE unverified) |
| cost 10000 / strength 10 | via `research_department.lua:59-60` | `base_config.lua:261` | match (proxy) |
| footprint north/east | `analyser.lua:50,54` | no EXE mask, no overlay | unverified |
| use `{0,0}` both | explicit, kept | unknown | unverified |
| idle/usage anims 2134/4878, preview 5092 | `analyser.lua:30,33-34,44` | DAT/ANI not decoded | unverified |
| research optional, 800 pts | `research.lua:37,65,97` | no TH room-req table extracted | unverified |

## 4. Footprint-compare [Inference]

- Pre-shift: north 3+3 with centre `{0,0}` passable; east 2x3 with centre passable. Nearest solid to `{0,0}` is `{0,-1}` — post-shift use → `{0,1}`. Verify with in-game dump before claiming strict.
- No `need_*_side` flags — simpler than slicer. No contested gap demonstrated; do not file minimal.

## 5. strict/minimal + next

- PASS(strict): FAIL — no overlay, checklist incomplete, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-41 mask; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.
