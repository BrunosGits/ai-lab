# Gates to Hell Object Deep — thob 48

## 1. CorsixTH definition — Documented fact
- `Lua/objects/gates_to_hell.lua:22`: `id="gates_to_hell"`, `:23` `thob=48`; `:25` `ticks=true`; `:26` `walk_in_to_use=true`.
- `:28-31` `idle_animations` south=1602, east=1602 (no north/west — mirror).
- `:33-45` `usage_animations`: Standard Male Patient `in_use=4560` for south+east (no north/west — mirror). Staff markers at `{0,0}`.
- `:47-63` orientations: south — `use_position={0,0}`, footprint 3 tiles `{1,0 only_passable},{0,0 complete},{-1,0 only_passable}`, `use_animate_from_use_position=false`; east — `use_position={0,0}`, footprint `{0,-1 only_passable},{0,0 complete},{0,1 only_passable}`, `use_animate_from_use_position=false`.
- No north/west orientations — mirror fallback via `object.lua:29-34` (south↔north, east↔west).
- `ticks=true`, `walk_in_to_use=true` — but no `tick()` method defined (inherits `Object`).
- No `use_position_secondary`, `handyman_position`, `early_list`, slave, crashed/smoke.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:267`: thob 48 row: `StartCost=0, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `48 Gates to Hell`.
- Cost 0 — not purchasable (spawned by death action).
- Used by `die.lua:174-188` (hell death branch) — spawned at death location with `lava_hole` + `GrimReaper`.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 48 | `gates_to_hell.lua:23` | `base_config.lua:267` | match (proxy; EXE pending) |
| cost 0 / strength 10 | `base_config.lua:267` | `base_config.lua:267` | match (proxy) |
| footprint 3 tiles (south/east) | `gates_to_hell.lua:51-63` | no EXE mask / overlay | unverified |
| `use_position={0,0}` on complete | `gates_to_hell.lua:50,58` | unknown | unverified |
| `use_animate_from_use_position=false` | explicit false both orients | unknown | unverified |
| Cost 0 (spawned by death) | `base_config.lua:267` + `die.lua:174` | TH had hell gate | Inference |

## 4. Footprint-compare [Inference]
- 3-tile horizontal (south) / vertical (east) with complete center + passable sides.
- `use_position={0,0}` on complete_cell; `use_animate_from_use_position=false` means anim at object origin.
- South/north mirror, east/west mirror — only 2 orients defined.
- Spawned by `die.lua:174-188` with `lava_hole` + `GrimReaper`; patient walks into hole via `UseObjectAction(destroy_user_after_use=true)`.

## 4. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay death hell branch both orients; `original_cells` dump vs SAM; verify spawn logic in `die.lua`; 5000-tick soak + save/load + `busted`/`luacheck`.