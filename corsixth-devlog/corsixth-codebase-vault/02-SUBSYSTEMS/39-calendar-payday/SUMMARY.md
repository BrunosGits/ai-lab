# 39 — Calendar + Payday Cycle — Summary

See [[39-calendar-payday/MAP]] for every file:line. Siblings:
[[31-staff-management/SUMMARY]] (31), [[36-endconditions-insurance/SUMMARY]] (36),
[[07-financial-system/SUMMARY]] (07), annual awards also (36).

## Overview
- **[Documented fact]** `Date` is an immutable value object: year/month/day/hour
  with real month lengths (Feb 28, no leap years) and 50 hrs/day.
- **[Documented fact]** `World:onTick` advances `game_date` by `hours_per_tick`
  and fires a strict cascade: day → month → year.
- **[Documented fact]** Payday = `Hospital:onEndMonth`: wages + heating +
  loan interest + overdraft + research, then insurance payout, salary-score
  bump, statistics snapshot. Year end = annual report + `onEndYear` resets.
- **[Inference]** There is no separate "monthly report fax"; the monthly
  observers are bank-statement transactions, finance graphs, and the progress
  report. Only year end opens a modal report.
- **[Hypothesis]** `setEndMonth/setEndYear` debug jumps are the most likely
  source of skipped-emergency / skipped-payday edge cases.

## Lifecycle / Flow
1. **[Documented fact]** Speed table sets `hours_per_tick/tick_rate`;
   Normal = 1 hr per tick. `game_date` starts as `Date()` (1-01-01T00).
2. **[Documented fact]** Each tick: `new = game_date:plusHours(hours_per_tick)`.
   If day-of-month changed → end-of-day path; only then test
   `isLastDayOfMonth`, then `isLastDayOfYear`.
3. **[Documented fact]** Day path: every hospital `onEndDay` first, then
   `World:onEndDay` (VIP, earthquake, emergency, spawn-hours, autosave flag).
4. **[Documented fact]** Month path: every hospital `onEndMonth` (money moves),
   then `World:onEndMonth` (population, spawn rate, staff pool). Return
   `true` would abort the rest (game already ended).
5. **[Documented fact]** Year path: `UIAnnualReport` is constructed **before**
   `World:onEndYear`, so trophy/award money+rep lands before win/lose check
   and yearly counters reset.
6. **[Documented fact]** `World:date()` returns a clone; callers cannot mutate
   the clock.

## Key mechanics
- **Clock:** **[Documented fact]** overflow normalizes month→day→hour;
  `monthOfGame = (year-1)*12 + month`; `getProgressInMonths` looks one hour
  ahead for end-conditions. Save compat rebuilds `Date` from y/m/d/h.
- **Daily accrual, monthly charge:** **[Documented fact]** loan interest
  (`loan*rate/365`), overdraft (`|balance|*rate/365`), research
  (`ceil(3*doctors*fraction/100)`), heating (`radiator_heat*10*n*7.5/days`)
  accrue in `onEndDay`; all are `spendMoney` + zeroed in `onEndMonth`
  (rounded, only if `> 0`).
- **Wages:** **[Documented fact]** `sum(staff.profile.wage)` → single
  `transactions.wages` spend. Fair-wage/rise logic lives in (31); payday only
  reads the current `wage` field.
- **Insurance:** **[Documented fact]** treatment takes a 2-month-delayed path:
  `insurance_balance[co][1] += amount` at cure time; on month end, slot `[3]`
  is paid via `transactions.insurance_colon`, then shift left, insert `0`.
  See also (36).
- **Player salary (score, not cash):** **[Documented fact]** init 10000;
  monthly `+ceil(clamp(sal_inc + (rep-500)/(deaths+1), sal_min, salary_incr))`,
  bounds default 50–300 from `ScoreMaxInc`. Level 3 year 3 adds 8000–20000.
  Win fax offer = `salary + bonus_rate%` (0 if cheated).
- **Stats/graphs:** **[Documented fact]** `statistics[monthOfGame+1]` stores
  money_in/out, wages, balance, visitors, cures, deaths, rep; then
  `money_in/out` reset. Graphs plot exactly those four money series. See (07).
- **Annual report:** **[Documented fact]** stats page sorts hospitals by
  balance-loan, visitors, deaths, cures, value, salary; trophies/awards add
  `eoy_trophy_bonus` / `eoy_bonus_penalty` money and year-end rep. Yearly
  counters (`sodas_sold`, `num_*_ty`, deaths-this-year) reset in
  `Hospital:onEndYear`. See (36).
- **Win/lose timing:** **[Documented fact]** `World:onEndYear` checks
  `endconditions` after hospital resets; `months_played` criterion reads the
  live clock, so year-boundary order matters.

## Related subsystems
- (31) staff wages: profile `wage`, fair-wage formula, rise requests.
- (36) insurance + annual report: company pick, delayed payout, trophies.
- (07) finance: balance/loan/transactions log, bank manager, graphs.
