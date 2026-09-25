# Radiation Shield Slave Object Deep — radiation_shield_b (no thob)

## 1. CorsixTH definition — Documented fact
- No separate file for `radiation_shield_b` — slave is implicit via `RadiationShield:slaveMixinClass()` in `radiation_shield.lua:67`.
- Master `radiation_shield.lua:22`: `slave_id="radiation_shield_b"`, `class="RadiationShield"`, thob=28.
- Slave class same `RadiationShield` (via `slaveMixinClass`); no separate thob — uses master's thob 28 or implicit.
- `radiation_shield.lua:47-65` master orientations (9-tile footprints, `use_position={0,0}` on `only_passable`, `render_attach={0,-1}`).
- Slave orientations not defined — `slaveMixinClass` uses `Object.slaveMixinClass` which:
  - Creates slave via `newObject(slave_id)` at `master_position + slave_position` (none defined for radiation_shield).
  - `slave.master = self`; `slave.initOrientation` sets anim 2310 / mirror fallback (`object.lua:64-73`).
  - Slave `footprint` not explicitly set — likely empty (cf. `operating_table_b`, `op_sink2`).
- `slaveMixinClass` chain: `RadiationShield:slaveMixinClass()` → `Machine.slaveMixinClass` → `Object.slaveMixinClass`.
- Event redirect: slave→master click/info/repair; master→slave create/move/destroy/orient-sync.
- Slave hidden from lists (`world.lua:2455`).

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:248`: thob 28 row only — no separate slave row.
- Original TH radiation shield was a single console object (no separate slave).
- Slave concept appears to be CorsixTH implementation for dual-surgeon workflow.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| Slave file | **none** (implicit) | no TH slave | **divergence** — CorsixTH added |
| Slave thob | implicit (uses master 28?) | N/A | unverified |
| Slave footprint | likely empty (cf. other slaves) | N/A | unverified |
| Slave anim | 2310 / mirror fallback | N/A | unverified |
| Event redirect / hidden | `object.lua:145-147,161-166,118-131` | N/A | Documented fact (code) |

## 4. Footprint-compare [Inference]
- Slave likely empty footprint (cf. `operating_table_b.lua:55-64`, `op_sink2.lua:46-52`).
- No `slave_position` defined on master — offset may be (0,0) or default.
- `RadiationShield` uses console anims (794/798/806/810/814/802) for master; slave gets 2310 idle / mirror.

## 4. strict/minimal + next
- PASS(strict): N/A — no separate vanilla object.
- Overall: **PARTIAL VANILLA PARITY** — master has proxy; slave is CorsixTH addition.
- Next: verify slave creation at runtime (offset, anim 2310); confirm empty footprint allows building; verify event redirect works; no footprint parity for slave itself.