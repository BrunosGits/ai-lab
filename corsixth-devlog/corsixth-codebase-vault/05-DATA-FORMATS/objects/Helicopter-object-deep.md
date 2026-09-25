# Helicopter Object Deep — thob 63

## 1. CorsixTH definition — Documented fact
- `Lua/objects/helicopter.lua:22`: `id="helicopter"`, `:23` `thob=63`; `:25` `class="Helicopter"`; `:27` `ticks=true`.
- `:29-31` `idle_animations` north=2456.
- `:33-36` orientations: north footprint `{}` (empty) — "Helicopter is outside the hospital, so does not need a footprint".
- `:38-80` class `Helicopter` extends `Object`:
  - Ctor: positions at hospital heliport +1 tile south, makes invisible, sets position (0,-600), phase=-120, `emergency_patients={}`.
  - `tick()` phase machine: 0=appear+descend+sound, 60=hover+adviser, 85=spawn patient loop, 87=ascend, 147=destroy.
  - `spawnPatient()`: creates Patient at heliport spawn, sets disease, `is_emergency` counter, `cure_rooms_visited = treatment_rooms-1`, price check → `goHome("over_priced")` or `SeekRoomAction`.
- No footprint (empty), no `use_position`, `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke, `usage_animations`.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua` objects table 1-61 only — thob 63 not in table.
- Original TH helicopter was an off-map event (emergency arrival), not a placeable object.
- `base_config.lua` objects table 1-61 only — thob 63 not in table.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 63 | `helicopter.lua:23` | **not in original TH** | **divergence** — CorsixTH assigned |
| Empty footprint | `helicopter.lua:35` | TH helicopter off-map | Inference (faithful to concept) |
| Phase machine (0→147) | `helicopter.lua:53-80` | TH had animated helicopter | Inference (likely faithful) |
| Emergency patient spawn | `helicopter.lua:82-110` | TH had emergency heli arrivals | Inference |
| `ticks=true` | `helicopter.lua:27` | TH helicopter animated | Inference |

## 4. Footprint-compare [Inference]
- Empty footprint — helicopter exists outside hospital map, lands at heliport.
- No `use_position`, `handyman_position`, slave, crashed/smoke.
- `ticks=true` drives phase machine; `tick()` advances phase each call.

## 5. strict/minimal + next
- PASS(strict): N/A — no footprint parity target.
- Overall: **NO VANILLA PARITY** — thob 63 is CorsixTH assignment; original TH helicopter was off-map event.
- Next: verify heliport position logic vs TH original; verify emergency patient spawn sequence; no footprint parity needed.