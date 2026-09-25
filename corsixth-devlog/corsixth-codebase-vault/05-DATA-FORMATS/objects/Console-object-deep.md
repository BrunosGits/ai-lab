# Console Object Deep — thob 15

## 1. CorsixTH definition — Documented fact
- `Lua/objects/console.lua:22`: `id="console"`, `:23` `thob=15`; no research fields (paired with machines).
- `:27` `ticks=true`; `:28` `build_preview_animation=922`; `:30` `show_in_town_map=true`; no crashed/smoke — Object.
- `:32-35` `idle_animations` north=794, south copied.
- `:37-49` `usage_animations`: north Doctor `begin_use=798` (sits), `begin_use_2=806` (pulls handle), `in_use={810 idle, 814 buttons}`, `finish_use=802` (stands); south copied.
- `:51-71` orientations: north footprint 4 tiles `{-1,-1 complete},{-1,0 complete},{0,-1 complete},{0,0 complete+only_passable}`, `render_attach_position={0,-1}`, `use_position="passable"`; east footprint identical 4 tiles, `render_attach_position={-1,0}`, `use_position="passable"`.
- No `handyman_position`, no `use_position_secondary`, no `early_list`, no slave.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:235`: thob 15 row: `StartCost=3000, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `15 Scanner Console`.
- Paired with: scanner (thob 14, `scanner.lua:30` needs `console=1`), dna_fixer (thob 23, `dna_fixer.lua:30` needs `console=1`), electrolyser (thob 46, `electrolysis.lua:30` needs `console=1`).
- Console is purchasable (StartAvail=1) unlike machines; no research_gate.
- `scanner_room.lua:56-85`: staff→console, patient→screen→scanner, synced `UseObjectAction`.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 15 | `console.lua:23` | `base_config.lua:235` | match (proxy; EXE pending) |
| cost 3000 / strength 10 | `base_config.lua:235` | `base_config.lua:235` | match (proxy) |
| footprint 4 tiles | `console.lua:54-70` | no EXE mask / overlay | unverified |
| `use_position="passable"` | keyword → first `only_passable` | unknown | unverified |
| Doctor anims 794/798/806/810/814/802 | `console.lua:34-49` | DAT/ANI not decoded | unverified |
| Pairing with 3 machines | `scanner/dna/electrolysis` rooms | no TH room table extracted | unverified |

## 4. Footprint-compare [Inference]
- 2x2 block with 3 solid + 1 passable (use); `render_attach` offsets by 1 tile.
- `use_position="passable"` → resolves to the single `only_passable` tile (`object.lua:945-954`).
- South copied, west/east mirrored; no west definition needed.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay scanner/dna/electrolysis rooms both orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-15; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.