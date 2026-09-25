# VIP Visits & Health-Inspector Evaluation — Study

> Scope: VIP tour + rating/payout, and epidemic-cover-up Inspector verdict.
> Detail tables: [[30-vip-inspection/MAP]] · Gate: [[30-vip-inspection/CHECKLIST]]
> Scaffold: [[30-vip-inspection/SCAFFOLD]] · Reputation/awards: [[08-reputation-system/MAP]]

## 1. Overview

- **[Documented fact]** `Vip` is a `Humanoid` that tours rooms, accumulates
  a penalty score (`vip_rating`, lower = better), then converts it to a
  cash + reputation payout on despawn.
- **[Documented fact]** `Inspector` is a separate `Humanoid` with no rating.
  It only terminates an epidemic cover-up: reaching reception (or detecting
  no desk) calls `Epidemic:handleInspectorArrival()`, which counts remaining
  infected and applies fine / rep-hit / evacuation / compensation.
- **[Inference]** Design intent: VIP = continuous quality audit; Inspector =
  one-shot cover-up verdict. They share only the reception-queue pattern,
  not scoring code.

## 2. Lifecycle / Flow

### VIP
1. **[Documented fact]** `World` date matches `next_vip_date` → if rooms exist
   and a staffed reception desk exists → `PlayerHospital:createVip()` sends an
   invite/refuse fax. Else the date is regenerated.
2. **[Documented fact]** Fax `accept_vip` → `World:spawnVIP(name)` snapshots
   `num_deaths/num_visitors/num_cured/#patients`, sets `room_visit_chance`,
   queues `SpawnAction` + `SeekReceptionAction`. `refuse_vip` → `nextVip()`;
   refusing >2 times can still force a visit (coin flip).
3. **[Documented fact]** Reception desk front-of-queue `Vip` → short `Idle`,
   `waiting=1`. `Vip:tickDay` decrements `waiting`, then `getNextRoom()`.
4. **[Documented fact]** `VipGoToNextRoomAction`: walk to entrance → `Idle(50)`
   → `evaluateRoom()` → `getNextRoom()`; `next_room_no==nil` → `goHome()`.
   Room deleted en-route → cancel callback re-queues `Idle`, `waiting=1`.
5. **[Documented fact]** `goHome()` calls `setVIPRating()`, sets
   `going_home`, saves `last_hospital`, despawns. `onDestroy()` pays out,
   sends end-fax, calls `world:nextVip()` to schedule the next date
   (`MayorLaunch` mean ± 30 days).

### Inspector
1. **[Documented fact]** Cover-up chosen → timer runs → `finishCoverUp()` →
   `spawnInspector()` (adviser line + `SeekReceptionAction`).
2. **[Documented fact]** Reception front-of-queue `Inspector` →
   `handleInspectorArrival()` + `goHome()`. No desk / desk gone while
   meandering → verdict delivered anyway + `goHome()`.
3. **[Documented fact]** `handleInspectorArrival()` → `determineFaxAndFines()`
   → `clearAllInfectedPatients()` → `applyOutcome()` (money/rep/evacuation +
   result fax, clears `hospital.epidemic`).

## 3. Key mechanics

- **[Documented fact]** VIP seed rating: `12 - rand(0,5)` (i.e. 7–12); clamped
  to 1–15 at the end. Lower is better.
- **[Documented fact]** Five additive groups: (1) litter/vomit seen (scan r=8,
  de-duplicated), threshold ≤10; (2) staff fatigue + headcount; (3) patient
  health/warmth/happiness/deaths/cures/seating/max-queue; (4) doctor
  mix; (5) room count + per-room decor score.
- **[Documented fact]** Room score per visit: +1 extinguisher (once), +1 bin
  (once), ±1 per plant (net), ±1 per machine (breaking or not), +6 penalty if
  research room holds a live patient. Averaged over visited rooms.
- **[Documented fact]** Payout tables: rating 1–7 pays cash (4000→200) + rep
  (+50→+20) and counts `pleased_vips_ty`; 8–10 pays rep only (+15→+5, no fax
  rep line); 11–15 pays negative rep (−5→−25). Free-build always +20 rep.
- **[Documented fact]** Inspector verdict bands: 0 infected → compensation
  (default 1000–5000); <rep-loss-minimum (default 5) → fine only (default
  2000/infected, min 2000); ≥rep-minimum but <evac-minimum (default 10) →
  fine + rep-hit (≈fine/100); ≥evac-minimum → fine + rep-hit (≈rep/3) +
  evacuation of post-reception patients.
- **[Hypothesis]** Header comments in `vip.lua` disagree with code on two
  doctor values (−2/+2 vs −1/+1) and imply early-skips that do not exist —
  treat comments as stale, code as truth.

## 4. Related subsystems

- Reputation core (`unconditionalChangeReputation`, clamps, trophy flag) and
  annual "happy VIPs" trophy (all `num_vips_ty == pleased_vips_ty` → rep
  bonus): see [[08-reputation-system/MAP]].
- Reception queue (`reception_desk.lua`), fax choices (`fax.lua`),
  annual report (`annual_report.lua`), epidemic state machine
  (`epidemic.lua`), level tuning (`MayorLaunch`, `Epidemic*` GBV keys).
