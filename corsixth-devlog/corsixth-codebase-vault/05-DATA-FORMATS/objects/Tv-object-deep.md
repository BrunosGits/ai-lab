# TV set — thob 21 — vanilla-parity deep note

Scope: tv (thob 21). Passive decor, no active use. Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition — Documented fact

- `Lua/objects/tv.lua:22` `id="tv"`, `:23` `thob=21`; `:26` `ticks=false`; `:27` preview `5052`
- `:28-31` idle north `396`, east `398` (no south/west)
- `:32-45` all 4 orientations explicit, 2 tiles each: N `{0,0 complete},{0,-1 only_passable}`; E `{0,0},{1,0}`; S `{0,0},{0,1}`; W `{0,0},{-1,0}`
- No `use_position` (defaults `{0,0}`), no `usage_animations`, no secondary/finish, slave, crash/smoke, strength, `early_list`
- `rooms/staff_room.lua:29` additional includes tv (optional; needed = sofa only)
- Cost `base_config.lua:241`: StartCost 50, avail 1, strength 10 (`-- 21 TV set`)

## 2. Original TH data — Documented fact

- Base row match (proxy). Strings `original_strings.lua:145` (`S[2][22]` name); `:1791` (`S[40][22]` tooltip) — TH had buyable TV.
- Game data present; no decoded thob-21 mask; EXE not disassembled. LUT tiles-only.

## 3. Footprint-compare

- Pre-shift: 1 solid + 1 orthogonally-adjacent passable ×4. No `use_position` → defaults `{0,0}` (the solid itself).
- No `processTypeDefinition` shift issue (use at solid origin); passable tile stays `passable=true`.
- Strict/minimal unfiled; no walk-through gap known.

## 4. Behavior checklist

- Passive: no use logic, no WalkAction target. Idle N/E only; S/W via mirror. Markers N/A. Crash/repair N/A.
- Inference: passive decor; `staff.lua` proximity happiness only (`tv=0.0005`), never a `findFreeObjectNearToUse` target. Consistent with no `use_position`.
- Soak pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 21 / cost 50 / avail 1 | match (proxy) | `tv.lua:23`, `base_config.lua:241` |
| tooltip buyable | match (proxy) | `S[40][22]` |
| 4× 2-tile footprint | unverified | `tv.lua:33-43` |
| idle 396/398 | unverified | `:29-30` |
| passive (no use) | unverified parity | absent usage block |
| staff_room optional | match (internal) | `staff_room.lua:29` |

## 6. Fact vs Inference vs Hypothesis

- Fact: all §1-§2 rows. Passive decor per absent use block + proximity-only happiness.
- Hypothesis: 1+1 wall-adjacent matches vanilla; needs overlay.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: overlay 4 dirs; `original_cells` vs SAM; disassemble thob-21; runtime dump; soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
