# Skeleton — thob 60 — vanilla-parity deep note

Scope: skeleton (thob 60). Training/psych decor + doctor-use. Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="skeleton"` :22, `thob=60`; `ticks=false`; preview `5108`; town-map true
- `copy_north_to_south`; idle north `2402` aliased; usage north `in_use {Doctor=2614}` aliased
- `orientations` N+E only: north `{0,0 complete},{1,0 only_passable}`, `use="passable"`, animate-from-use; east `{0,0 complete},{0,1 only_passable}`, same
- Resolved use N `{1,0}`, E `{0,1}`. No slave/strength/crash/smoke.
- Rooms: `rooms/training.lua:30` additional (needed = chair+projector, skeleton optional; `:77,116,157-163` counts + doctor use); `rooms/psych.lua:29` additional (needed = screen+couch+chair, optional)

THOB + cost: `base_config.lua:280`: thob 60 Skeleton, StartCost 450, avail 1, strength 10. Cost high for decor (vs bookcase 350, sofa 150) — gameplay-relevant for training value.

## 2. Original TH data

- Base row match (proxy). EXE/ANIMS/SAM pending; LUT caveat as usual.

## 3. Footprint-compare

- 1 solid + 1 orthogonal passable, axis swapped vs sink (sink N `{0,1}`/E `{1,0}`; skeleton N `{1,0}`/E `{0,1}`). Both valid; intentional per Lua, not copy error. Strict = current; minimal = same.

## 4. Behavior checklist

- Passable resolution sound; no markers for single doctor anim — draw-offset check pending (V). N+E + S=N; W fallback needs placement test. Idle fallback for east pending. Soak/save pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 60 / cost 450 / avail 1 | match (proxy) | `:23`, `base_config.lua:280` |
| footprint N/E | unverified | `:44,49` |
| use passable | unverified (logic sound) | `:45,50` + engine |
| idle/use/preview | unverified | `:27,34-39` |
| training/psych optional | match (internal) | `training.lua:30-31`, `psych.lua:29-30` |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua + base + room lines.
- Inference: axis-swap deliberate (wall stance/sprite facing); landmark decor role.
- Hypothesis: orthogonal choice matches vanilla; confirm via overlay + facing.

## 7. Strict / minimal + next + pass/fail

- strict = keep; minimal = same. Next: overlay; east-idle fallback; reachability + soak.
- Verdict: PASS (minimal-candidate) / strict pending V.
