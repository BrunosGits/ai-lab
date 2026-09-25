# MAP — VIP & Inspector file:line references

> Base: `CorsixTH/Lua/`. All ranges read via `ssh vps` (read-only).

| # | Claim | Path:lines |
|---|-------|-------------|
| V1 | Rating header spec (0–15, 5 groups) | `entities/humanoids/vip.lua:26-57` |
| V2 | Constructor: seed `12-rand(0,5)`, counters, `room_visit_chance=1` | `entities/humanoids/vip.lua:65-90` |
| V3 | `tickDay`: `waiting` countdown + litter scan r=8 with `found_vomit` dedup | `entities/humanoids/vip.lua:94-134` |
| V4 | `getNextRoom`: first room always, `rand(0,chance)` skip, `vip_must_visit` forced, inactive skipped | `entities/humanoids/vip.lua:136-161` |
| V5 | `goHome`: guard, `setVIPRating`, `going_home`, `last_hospital` | `entities/humanoids/vip.lua:173-186` |
| V6 | `evaluateRoom`: +6 research-live-patient; extinguisher/bin/plants/machines | `entities/humanoids/vip.lua:188-226` |
| V7 | `onDestroy`: free-build +20; ≤7 cash+rep+pleased; else rep; end-fax; `nextVip` | `entities/humanoids/vip.lua:228-243` |
| V8 | `setVIPRating` preamble: non-crashed count + max queue | `entities/humanoids/vip.lua:245-257` |
| V9 | Litter factor ≤10 → −1 else +1 | `entities/humanoids/vip.lua:259-263` |
| V10 | Staff: ≤1 staff +4; very-tired +2; avg fatigue ≥0.5 +1 else −1 | `entities/humanoids/vip.lua:265-286` |
| V11 | Patients: health, warmth/warmth-map, happiness-map | `entities/humanoids/vip.lua:290-323` |
| V12 | Deaths ratio map, cures ratio map (+3 if none), sitting/standing, queue map | `entities/humanoids/vip.lua:326-377` |
| V13 | Doctors: 0 → +4; consultants >½ → −1; juniors >½ → +1 | `entities/humanoids/vip.lua:381-396` |
| V14 | Rooms: 0 → +4; <3 → +1; avg `room_eval` map | `entities/humanoids/vip.lua:401-417` |
| V15 | Clamp 1–15; `rewards` cash table; `rep_change` table | `entities/humanoids/vip.lua:420-455` |
| V16 | `afterLoad` legacy migrations (waiting, names, rating, visit chance) | `entities/humanoids/vip.lua:458-516` |
| W1 | `spawnVIP`: snapshots, `rooms_threshold=79`, `floor(n/40)`, spawn+reception | `world.lua:480-503` |
| W2 | Daily trigger: needs rooms + staffed desk, else reschedule | `world.lua:1070-1077` |
| W3 | `nextVip` / `_generateNextVipDate` (`MayorLaunch` mean ±30d) | `world.lua:1327-1340` |
| P1 | `createVip` invite/refuse fax, 20-day auto-accept | `hospitals/player_hospital.lua:735-747` |
| P2 | `makeVipEndFax` branches: free-build / ≤7 / 8–10 / ≥11 | `hospitals/player_hospital.lua:761-790` |
| P3 | `onSpawnVIP` + arrival announcement (`announce_vip`) | `hospitals/player_hospital.lua:493-530` |
| F1 | Fax `accept_vip` / `refuse_vip` / forced visit if `vip_declined>2` | `dialogs/fullscreen/fax.lua:190-201` |
| A1 | Tour action: `next_room_no==nil→goHome`; walk+`Idle(50)`+`evaluate()`; cancel cb | `humanoid_actions/vip_go_to_next_room.lua:32-73` |
| R1 | Reception: `handleVIP` (idle) vs `handleInspector` (verdict+goHome); dispatch | `objects/reception_desk.lua:115-160` |
| I1 | Inspector class, `goHome`, `tick→checkForReceptionDesk` (no-desk verdict) | `entities/humanoids/inspector.lua:26-87` |
| E1 | `startCoverUp` / `finishCoverUp→spawnInspector` / `handleInspectorArrival` | `epidemic.lua:396-431` |
| E2 | `determineFaxAndFines`: compensation 1000–5000; fine 2000/infected | `epidemic.lua:439-485` |
| E3 | `applyOutcome`: evac rep-hit `round(rep/3)` else `round(fine/100)`; clears epidemic | `epidemic.lua:489-508` |
| E4 | `spawnInspector` + `_inspectorSpawned` guard; `tryAnnounceInspector` | `epidemic.lua:551-562,723-733` |
| E5 | Thresholds `EpidemicRepLossMinimum=5`, `EpidemicEvacMinimum=10` | `epidemic.lua:83-88` |
| H1 | `unconditionalChangeReputation` clamp + trophy flag | `hospital.lua:1808-1826` |
| H2 | `getAveragePatient/StaffAttribute`, `countSittingStanding`, `countStaffOfCategory` | `hospital.lua:537-538,1615-1616,1921-1935` |
| H3 | Yearly reset `num_vips_ty/pleased_vips_ty`; init comments | `hospital.lua:162-163,1065-1066` |
| T1 | Annual "happy VIPs" trophy: all pleased → rep bonus | `dialogs/fullscreen/annual_report.lua:200-204` |
