# Sink (bathroom) — thob 32 — vanilla-parity deep note

Scope: sink (thob 32; do not confuse with op_sink1/2 thob 33/34). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="sink"` :22, `thob=32`; `ticks=false`; preview `5082`
- `copy_north_to_south`; idle north `1748`; usage north M/F begin/in/finish splits
- Patient markers kf1/kf2
- `orientations` N+E only: north `{0,0 complete},{0,1 only_passable}`, `use="passable"`, animate-from-use; east `{0,0 complete},{1,0 only_passable}`, same
- Resolved use: first `only_passable` → N `{0,1}`, E `{1,0}`; re-centre shifts solid to origin. No slave/strength/crash/smoke.
- Room `rooms/toilets.lua:29` additional includes sink; `:30` `objects_needed {loo=1,sink=1}`; `:95` `findFreeObjectNearToUse sink`. Name `toilet_sink` vs base `Bathroom Sink` — label only.

THOB + cost: `base_config.lua:252`: thob 32 Bathroom Sink, StartCost 30, avail 1, strength 10.

## 2. Original TH data

- Base row match (proxy). EXE mask/SAM overlay pending; LUT tiles-only.

## 3. Footprint-compare

- 1 solid + 1 adjacent passable; N passable south, E passable east. N+E + S=N copy; W via fallback (needs placement test).
- Strict = current; minimal = same (2-tile wall-hugger plausible, no gap).

## 4. Behavior checklist

- Passable-use resolves correctly if footprint order kept; markers present. M/F splits Lua-verified. Soak/save pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 32 / cost 30 / avail 1 | match (proxy) | `:23`, `base_config.lua:252` |
| footprint N/E | unverified | `:59,64` |
| use passable | unverified (logic sound) | `:60,65` + engine |
| anims/markers | unverified | `:33-55` |
| toilets needed | match (internal) | `toilets.lua:30` |

## 6. Fact vs Inference vs Hypothesis

- Fact: lines above; toilets dependency; M/F split.
- Inference: wall-sink convention; cost tier.
- Hypothesis: wall-adjacent single-solid matches vanilla.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: keep current. Next: overlay; W-placement check; soak + save/load.
- Verdict: PASS (minimal-candidate) / strict pending V.
