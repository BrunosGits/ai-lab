# Computer Object Deep — thob 40

## 1. CorsixTH definition — Documented fact
- `Lua/objects/computer.lua:22`: `id="computer"`, `:23` `thob=40`; `:24` `research_category="cure"`, `:25` `research_fallback=46`.
- `:28` `ticks=false`; `:29` `build_preview_animation=5090`; `:31` `show_in_town_map=true`; no crashed/smoke — Object, not Machine.
- `:33-36` `idle_animations` north=2094, south copied.
- `:38-44` `usage_animations` north Doctor `in_use=2098`, south copied.
- `:46-55` orientations: north footprint 2 tiles `{0,0 complete}`, `{0,1 only_passable}`, `use_position="passable"` (keyword), `use_animate_from_use_position=true`; east footprint `{0,0 complete}`, `{1,0 only_passable}`, `use_position="passable"`, `use_animate_from_use_position=true`.
- No `handyman_position`, no `use_position_secondary`, no `early_list`, no slave.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:260`: thob 40 row: `StartCost=5000, StartAvail=0, StartStrength=10, AvailableForLevel=0` comment `40 Research Computer`.
- `base_config.lua:218`: virtual treatment `I_X_COMPUTER`, `RschReqd=30000`.
- `research.lua:37`: `objects_additional` includes `"computer"` (optional); `:65` `staff_usage_objects` includes `computer=true`.
- `research.lua:95`: after-use on computer `addResearchPoints(500)` vs autopsy 800, desk 100.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 40 | `computer.lua:23` | `base_config.lua:260` | match (proxy; EXE pending) |
| cost 5000 / strength 10 | via `research_department` | `base_config.lua:260` | match (proxy) |
| footprint 2 tiles/orient | `computer.lua:48-55` | no EXE mask / overlay | unverified |
| `use_position="passable"` | keyword → first `only_passable` (`object.lua:945-954`) | unknown | unverified |
| idle/usage anims 2094/2098 | `computer.lua:34-44` | DAT/ANI not decoded | unverified |
| optional in research | `research.lua:37,65` | no TH room-req table | unverified |

## 4. Footprint-compare [Inference]
- 1-wide + passable use tile; `use_animate_from_use_position=true` means patient animates at use tile.
- Nearest solid to `{0,0}` is `{0,0}` (complete_cell) — `processTypeDefinition` may shift if `{0,0}` considered passable; needs runtime dump.
- No `need_*_side`, no `early_list`, simple case.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay research room both orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-40; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.