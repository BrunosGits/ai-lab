# Reception desk — thob 11 — vanilla-parity deep note

Scope: reception_desk (thob 11). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="reception_desk"` :22, `thob=11`, `class="ReceptionDesk"`; `ticks=true` (queue tick); `corridor_object=1`; preview `5060`
- `idle_animations` north `2062`, east `2064`
- `orientations` all 4 explicit (no mirror/copy): north 1 solid + 4 neighbours with `need_north+need_south` sides, `use` + `secondary`; east transposed with `need_west+need_east`; south/west mirrored pairs
- `class "ReceptionDesk"`: `Queue()`, bench-threshold 3, max 20; `checkForNearbyStaff/getUsageScore/setTile/occupy` — receptionist uses secondary, patient uses primary
- No slave/strength/crash/smoke. Corridor object, no room `objects_needed`; tracked in `hospital.lua:1049,1065,1714` (build gate).

THOB + cost: `base_config.lua:231`: `thob 11 New Receptionists Station: StartCost=150 StartAvail=1 StartStrength=10`.

## 2. Original TH data

- Base row match (proxy). `HOSPITAL.EXE` present, not disassembled. `LEVELS/*.SAM` present, no overlay. LUT tiles-only; `original_cells` not dumped for thob 11.

## 3. Footprint-compare

- 1 solid + 4 neighbours per `occupyTilesByObjectFootprintAt` + `directionParameters` + `processTypeDefinition`. N/E canonical; S/W explicit (no mirror derivation needed).
- `use_position` explicit coords (not passable keyword). Primary=patient queue front, secondary=receptionist.
- Strict = current N+E as-is; minimal = same (no gap demonstrated). No overlay → candidates only.

## 4. Behavior checklist

- Explicit use/secondary; reachable if both sides open. 4/4 explicit orientations; idle N/E literal. No slave/crash. Soak + save/load pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 11 / cost 150 / avail 1 | match (proxy) | `:23`, `base_config.lua:231` |
| footprint + use/secondary | unverified | `:36-65` |
| idle/preview/queue class | unverified | `:29-32,71-79` |
| corridor + build gate | unverified parity | `:28`, `hospital.lua:1049,1714` |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua values + base row + engine lines.
- Inference: cost/avail vanilla-faithful (TH-derived table).
- Hypothesis: 5-tile cross with dual use is vanilla-intended. Needs overlay + mask.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: candidates only. Next: SAM overlay + screenshot; soak + `busted`/`luacheck`; `need_*_side` vs vanilla check.
- Verdict: FAIL (strict-pending) / PASS (minimal-candidate).
