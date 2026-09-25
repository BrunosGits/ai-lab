# Autopsy Object Deep — thob 55

## 1. CorsixTH definition — Documented fact
- `Lua/objects/autopsy.lua:22`: `id="autopsy"`, `:23` `thob=55`; `:24` `research_category="cure"`, no fallback field.
- `:27` `ticks=true`; `:28` `build_preview_animation=5102`; `:30` `crashed_animation=3304`; `:32` `show_in_town_map=true`.
- `:34-37` `idle_animations` north=2146, south copied via `copy_north_to_south`.
- `:39-47` `usage_animations` north Handyman `in_use=3566`, south copied.
- `:49-111` `multi_usage_animations`: 12 patient variants (Standard M/F, Alien M/F, Alternate M, Chewbacca, Elvis, Slack M/F, Transparent M/F, Invisible); each has `begin_use`, `begin_use_2`, `begin_use_3`, `in_use`, `finish_use`, `finish_use_2=4010`; secondary uses patient idle anim.
- `:113-130` orientations: north footprint 9 tiles (3x3 with `only_passable` on top row `y=1`), `use_position={0,1}`, `use_position_secondary={-2,1}`, `handyman_position={0,1}`, `early_list=true`; east footprint 8 tiles (2x3 + passable right col), `render_attach_position={-1,0}`, `use_position={1,0}`, `use_position_secondary={1,-2}`, `handyman_position={1,0}`.
- `:132` `anim_mgr:setPatientMarker(2146,{0,0})`; `:135-137` anim 4086 trimmed to length of 2166 (Chewbacca variant).
- No `default_strength`, no `smoke_animation` — Object, not Machine.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:275`: thob 55 row: `StartCost=4000, StartAvail=0, WhenAvail=0, StartStrength=10, AvailableForLevel=0` comment `55 Autopsy Research Machine`.
- `base_config.lua:216`: virtual treatment `I_X_RESEARCH` autopsy, `RschReqd=15000`.
- `research.lua:37`: `objects_needed={desk=1,cabinet=1,autopsy=1}` — autopsy required.
- `research.lua:65`: `staff_usage_objects` includes `analyser` but NOT autopsy (kept free for patients).
- `research.lua:97`: after-use on autopsy `addResearchPoints(800)` vs computer 500, desk 100.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 55 | `autopsy.lua:23` | `base_config.lua:275` | match (proxy; EXE mask pending) |
| cost 4000 / strength 10 | via `research_department` | `base_config.lua:275` | match (proxy) |
| footprint 9+8 tiles | `autopsy.lua:115-130` | no EXE mask / overlay | unverified |
| use positions `{0,1}`/`{1,0}` | explicit, not `passable` | unknown | unverified |
| 12 multi-use variants | `autopsy.lua:49-111` | original anim blocks unverified | unverified |
| anim 4086 trim | `autopsy.lua:135-137` | CorsixTH fix (repeat bug) | Inference (no vanilla equiv) |

## 4. Footprint-compare [Inference]
- Pre-shift: north 3x3 passable top row; east 3x2 passable right col. Nearest solid to north `{0,1}` is `{0,0}` (d=1) → post-shift use→`{0,2}`, passable row shifts to `y=2`. East similar.
- `early_list=true` north affects build order; `render_attach` east only.
- No contested gap demonstrated; minimal N/A.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay research room both orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-55; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.