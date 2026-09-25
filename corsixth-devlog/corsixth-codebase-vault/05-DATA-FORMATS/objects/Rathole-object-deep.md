# Rathole Object Deep — thob 64

## 1. CorsixTH definition — Documented fact
- `Lua/objects/rathole.lua:22`: `id="rathole"`, `:23` `thob=64`; `:25` `class="Rathole"`; `:27` `ticks=false`.
- `:29-32` `idle_animations` north=1904 (single, no copy/mirror).
- `:34-43` orientations: all 4 explicit — footprint `{}` (empty) each. Empty footprint means "build any other object on top".
- `:45-53` class `Rathole` extends `Object`: ctor calls `Object`; `getDrawingLayer` = `RatHole`; no custom logic.
- Anim comments: 1904 hole in north wall; 1908-1928 rat movement/enter/leave anims (8 directions + enter/leave).
- No `use_position`, `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke, `usage_animations`.

## 2. Original TH data — Documented fact unless noted
- thob 64 assigned by CorsixTH (not in original TH thob table 1-61).
- `base_config.lua` objects table 1-61 only — thob 64 not in table.
- Original TH ratholes likely used different internal representation.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 64 | `rathole.lua:23` | **not in original TH** | **divergence** — CorsixTH assigned |
| Empty footprint | `rathole.lua:37-42` | TH had ratholes | Inference (likely faithful) |
| Anim 1904 + 1908-1928 | `rathole.lua:45-51` comments | TH had rat animations | Inference |
| No gameplay logic | `rathole.lua:45-53` | TH ratholes decorative | Inference |

## 4. Footprint-compare [Inference]
- Empty footprint on all 4 orients — allows building over rathole.
- Single idle anim 1904; rat movement anims 1908-1928 for visual effect.
- No `use_position` — purely decorative.
- No orientations logic needed (all same empty).

## 5. strict/minimal + next
- PASS(strict): N/A — not a footprint parity target.
- Overall: **NO VANILLA PARITY** — thob 64 is CorsixTH assignment; original TH used different system.
- Next: verify rat anim indices 1908-1928 vs TH original; confirm empty footprint allows building; no footprint parity needed.