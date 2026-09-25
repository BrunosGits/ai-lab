# Litter Object Deep — thob 62

## 1. CorsixTH definition — Documented fact
- `Lua/objects/litter.lua:22`: `id="litter"`, `:23` `thob=62` (previously unused); `:25` `class="Litter"`; `:27` `ticks=false`.
- `:29-44` `litter_types` table: 11 types (pee=2248, dead_rat=2242, puke=2060, soda_can=1894, banana=1896, paper=1898, bottle=1900, soot_floor=3416, soot_wall=3408, soot_window=3412); random types 1-4 = cans/banana/paper/bottle.
- `:46-62` class `Litter` extends `Entity` (not `Object`): `Litter(hospital,x,y)` sets tile, adds to tile; `setLitterType(anim_type,mirrorFlag)` sets anim + cleaning task if cleanable; `remove()` removes from tile + cleaning task; `getWalkableTiles` returns own tile (hack for issue 918).
- `:82-96` `vomitInducing` (pee/dead_rat/puke), `isCleanable` (vomit or any litter), `anyLitter` (cans/banana/paper/bottle).
- `:98-134` `afterLoad` compat: <52 adds cleaning task; <54 removes non-cleanable tasks; <121 sets ticks; <150 re-finds hospital; <162 removes orphaned litter.
- No orientations, no `use_position`, no `handyman_position`, no slave, no `usage_animations` — `Entity` subclass, not `Object`. Handyman cleaning via `addHandymanTask("cleaning")`.

## 2. Original TH data — Documented fact unless noted
- thob 62 "previously unused" — CorsixTH assigned thob 62 for litter (not in original TH thob table).
- `base_config.lua` objects table (220-278) has 1-61 only — thob 62/64 not in table.
- Original TH litter likely used different internal representation (not thob-based).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 62 | `litter.lua:23` | **not in original TH** | **divergence** — CorsixTH assigned |
| anim types (11) | `litter.lua:29-44` | TH had similar litter | Inference (likely faithful) |
| `vomitInducing` types | `litter.lua:82-87` | TH had vomit-inducing litter | Inference |
| Cleaning task integration | `litter.lua:54-61,98-134` | TH had handyman cleaning | Inference |
| `afterLoad` compat layers | `litter.lua:98-134` | CorsixTH-specific | Documented fact |

## 4. Footprint-compare [Inference]
- No footprint — `Entity` not `Object`; `getWalkableTiles` returns own tile only.
- Placed on tile via `Entity.setTile`; handyman cleaning via `addHandymanTask("cleaning")`.
- No orientations, no `use_position`, no `handyman_position`, no slave.
- `vomitInducing` affects VIP rating (`vip.lua:326-338` litter scan).

## 5. strict/minimal + next
- PASS(strict): N/A — not an `Object` with footprint; no vanilla parity applicable.
- Overall: **NO VANILLA PARITY** — thob 62 is CorsixTH invention; original TH used different system.
- Next: verify litter anim indices vs TH original; confirm handyman cleaning behaviour matches; no footprint parity needed.