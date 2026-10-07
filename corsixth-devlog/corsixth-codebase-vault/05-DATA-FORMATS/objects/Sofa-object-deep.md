# Sofa — thob 19 — vanilla-parity deep note

Scope: sofa (thob 19; distinct from thob 18 Couch). Staff-room rest object. Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="sofa"` :22, `thob=19`; `ticks=false`; preview `5066`; town-map true
- idle north `2122`, east `2124`; full staff split usage N+E (Doctor/Nurse/Handyman begin/begin_2/in/finish); staff markers both dirs
- `orientations` all 4 explicit: 2 adjacent solids + 1 diagonal passable (corner access); per-orient `render_attach` (N single, S dual)
- Resolved use = single passable per orient. No slave/strength/crash.
- Room `rooms/staff_room.lua:29` additional; `:30` `objects_needed {sofa=1}` (required)

THOB + cost: `base_config.lua:239`: thob 19 Sofa, StartCost 150, avail 1, strength 10. Distinct from thob 18 Couch (cost 100).

## 2. Original TH data

- Base row match (proxy). EXE/ANIMS/SAM pending; LUT caveat as usual.

## 3. Footprint-compare

- 2 solids + 1 diagonal passable; N `{-1,-1}`, E `{1,-1}`, S `{-1,1}`, W `{-1,-1}` (W reuses N — asymmetric; S mirrors N). Strict = current; minimal = same (complete_cell on both solids closes walk-through).
- `render_attach` N single vs S dual — draw-origin differs; visual check pending.

## 4. Behavior checklist

- Single-candidate passable each orient, unambiguous. 4/4 explicit (no mirror). Full markers present. Diagonal approach must stay reachable in walled staff room. Soak/save pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 19 / cost 150 / avail 1 | match (proxy) | `:23`, `base_config.lua:239` |
| footprints N/E/S/W | unverified | `:99,104,109,113` |
| render_attach N/S | unverified | `:100,108` |
| idle/staff anims/markers | unverified (complete) | `:30-95` |
| staff_room required | match (internal) | `staff_room.lua:30` |

## 6. Fact vs Inference vs Hypothesis

- Fact: footprint + full anim/marker set + required wiring.
- Inference: 2-wide sprite; diagonal passable is sit-approach; cost tier matches.
- Hypothesis: W-duplicating-N is vanilla sprite constraint, not bug; needs overlay + draw test.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: keep verbatim. Next: overlay all 4; diagonal reachability; render S-vs-N check + soak.
- Verdict: PASS (minimal-candidate) / strict pending V.
