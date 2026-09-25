# Bench Object Deep — thob 4

## 1. CorsixTH definition — Documented fact
- `Lua/objects/bench.lua:22`: `id="bench"`, `:23` `class="Bench"`, `:24` `thob=4`; `:27` `ticks=false`; `:28` `corridor_object=2`; `:29` `build_preview_animation=902`; `:31` `dynamic_info=true`; `:33` `walk_in_to_use=true`.
- `:33-36` `idle_animations` north=112, east=114 (no south/west — mirror).
- `:38-119` `usage_animations`: 12 patient types × north/east × `begin_use`/`in_use`/`finish_use` (east anims distinct from north). No south/west — mirror.
- `:121-172` orientations: all 4 explicit — north footprint 2 tiles `{0,0 complete},{0,-1 only_passable+invisible+shareable}`, `render_attach_position={{0,0},{-1,0},{0,-1}}`, `use_position="passable"`; east `{0,0 complete},{1,0 only_passable+invisible+shareable}`; south `{0,0 complete},{0,1 only_passable+invisible+shareable}`; west `{0,0 complete},{-1,0 only_passable+invisible+shareable}`. All `use_position="passable"`.
- Class `Bench` with `walk_in_to_use=true`, `removeUser` (notifies patient to idle if action queue has idle), `resetUsageAndReservation` (handles issue #404), `afterLoad` compat for old saves (<119).
- `corridor_object=2` allows placement in corridors.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:224`: thob 4 row: `StartCost=2500, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `4 Bench`.
- Corridor placement allowed (`corridor_object=2`).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 4 | `bench.lua:24` | `base_config.lua:224` | match (proxy; EXE pending) |
| cost 2500 / strength 10 | `base_config.lua:224` | `base_config.lua:224` | match (proxy) |
| footprint 2 tiles (all 4 orients) | `bench.lua:121-172` | no EXE mask / overlay | unverified |
| `invisible+shareable` passable tile | `bench.lua:121-172` | unknown | unverified |
| 12 patient variants | `bench.lua:38-119` | DAT/ANI not decoded | unverified |
| `walk_in_to_use=true` + `corridor_object` | `bench.lua:31,33` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:224` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- All 4 orients explicit 2-tile (complete + passable with `invisible+shareable`).
- `shareable=true` allows multiple patients per `object.lua:386-392`.
- `render_attach_position` north has 3 positions for 3-seat bench.
- No `copy_north_to_south` — all 4 explicit.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay corridor + room both orients; `original_cells` dump vs SAM; disassemble thob-4; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.