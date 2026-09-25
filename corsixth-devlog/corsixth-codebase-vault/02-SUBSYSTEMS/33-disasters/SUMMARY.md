# 33 — Disasters: Earthquakes + Boiler Breakdown

> Scope: earthquake scheduling / damage / repair flow, plus other
> disaster events. Machine explosion internals excluded — see [[32-machine-maintenance/MAP]].

## 1. Overview

- Two independent disaster families exist (Documented fact):
  - **Earthquakes** — owned by `World.earthquake` (`Earthquake` class),
    level-scripted via `quake_control`. See [[33-disasters/MAP#earthquakes]].
  - **Boiler/heating breakdowns** — owned per-`Hospital` via
    `disasterless_days` countdown. See [[33-disasters/MAP#boiler-disasters]].
- Earthquakes damage **machines only** (each damage tick calls
  `Machine:earthquakeImpact`); boiler disasters force `radiator_heat`
  to 0 or 1 until handyman staffing repairs it.
- There is **no heating ⇄ earthquake coupling** in code (Documented fact):
  quake path never touches `hospital.heating`; boiler path never reads
  `world.earthquake`. Cross-link only: [[07-financial-system/MAP]].

## 2. Earthquake lifecycle / flow

1. **Plan** — `Earthquake:nextEarthquake()` reads
   `level_config.quake_control[current_map_earthquake]`; random
   `start_month` in `[StartMonth, EndMonth]`, random `start_day`,
   `size = Severity`, `remaining_damage = size`,
   `warning_timer = 600`, `damage_timer = 16` (Documented fact).
2. **Arm** — `World:onEndDay()` → `Earthquake:onEndDay()` sets
   `active = true` when game month/day matches (Documented fact).
3. **Warn** — `Earthquake:tick()` (called from `World:tick()` when not
   paused) fires `tickEarthquake("warning_start")` at 600h, shakes at
   0.2 intensity, then `"end"` when the 25h warning window closes.
4. **Damage** — once `warning_timer <= 0`, every 16h each machine in
   every room takes one `earthquakeImpact` (= one `machineUsed` wear
   step); `remaining_damage` decrements per wave (Documented fact).
   Corridor patients with `falling_anim` have a 50/50 fall roll each wave.
5. **Close** — at `remaining_damage == 0`: `active = false`,
   `tickEarthquake("end")`, adviser note if `size > 7`, then immediately
   plans the next quake (Documented fact).
6. **Cheats** — `createEarthquake()` (size 1–6 if no level quake left);
   `disabled` flag gates both `tick()` and `onEndDay()` (Documented fact).

## 3. Key mechanics

- **Size 1–9; waves == size.** Head/tail waves shake at 0.5, middle at
  1.0 (`remaining_damage <= 2 or size - remaining_damage <= 2`).
  (Documented fact; Inference: tuning intent is "ramps up then down".)
- **Quake wear == one use.** `earthquakeImpact` → `machineUsed(room, true)`
  increments `times_used` but *not* `total_usage`; may queue/escalate a
  handyman `repairing` task or explode the room via the shared
  machine path (Documented fact; explosion detail lives in [[32-machine-maintenance/MAP]]).
- **Sound spam guard.** `announceRepair` always plays `machwarn.wav` but
  skips the per-room call sound while `isActive() and warning_timer == 0`
  (Documented fact).
- **Pause stops shaking.** `World:setSpeed("Pause")` sends
  `tickEarthquake("pause")` → `endShakeScreen()` (Documented fact).
- **Boiler disaster roll.** Daily in `Hospital:tickDay`: decrement
  `disasterless_days`; at 0, reset to `daysUntilNextDisaster()` and roll
  1–3: 1 = nothing, 2 = `boilerBreakdown(1)`, 3 = `boilerBreakdown(0)`
  (Documented fact). Vomit wave (`== 4`) is an unimplemented TODO (fact).
- **Boiler gating/repair.** Breakdown is a no-op if hospital closed,
  already broken, zero radiators, or `radiators <= 8 × handymen`.
  `_fixBoiler()` ticks daily, faster with more handymen (−3/−2/−1);
  at 0 restores `saved_radiator_heat` (Documented fact).

## 4. Related subsystems

- [[32-machine-maintenance/MAP]] — `machineUsed`, repair queue, smoke, `crashRoom`.
- [[07-financial-system/MAP]] — heating accrual (`acc_heating`) → monthly
  `spendMoney(..., transactions.heating)`; quakes have **no** direct
  money hook (Hypothesis: quake cost is fully indirect via repairs).
- Heating UI/advice — `adviseBoilerBreakdown`, temperature comfort;
  no quake interplay found (Documented fact via grep).
- Emergencies / epidemics / VIPs share `World:onEndDay` scheduling but
  are separate subsystems, not disasters in the `disasterless_days` sense.

## 5. Open questions (Hypothesis)

- `next_planned` is set true/false but never gates damage; likely a
  leftover cheat-vs-script flag — verify before reusing.
- `quake_control` keys start at index 0 in level data; off-by-one risk
  if porting to 1-based Lua tables — check level parser, not seen here.
