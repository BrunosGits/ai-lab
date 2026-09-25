# 39 — Calendar + Payday — Pre-fix Safety Gate

Do not change payday/clock code until each box is checked.

- [ ] Re-read [[39-calendar-payday/MAP]] rows 9, 21–23; confirm spend order
      and zero-after-spend for all five accumulators.
- [ ] Confirm trigger predicate: day-change first, then `isLastDayOfMonth`,
      then `isLastDayOfYear`. No month-end without day-end.
- [ ] Confirm `World:date()` clone semantics; fix must not mutate `game_date`.
- [ ] Daily/monthly pair check: every `acc_*` written in `onEndDay` has a
      matching rounded `spendMoney` + reset in `onEndMonth`.
- [ ] Insurance shift check: payout reads `[3]`, `remove(3)+insert(1,0)`;
      cure-time write targets `[1]`. Off-by-one = 1-month pay error.
- [ ] Salary-score bounds: `sal_min..salary_incr`, `ceil`, deaths+1 divisor.
      Salary is score, never cash; win offer handles `cheated`.
- [ ] Year order: `UIAnnualReport` constructed before `onEndYear`; resets in
      `Hospital:onEndYear` run before `checkEndGame` lose-check.
- [ ] Graphs/stats index: `statistics[monthOfGame+1]`; `money_in/out` reset
      after push. Bank statement cap (20) is display-only.
- [ ] Speed/jump paths: `setEndMonth/setEndYear` + `Speed Up (8h)` still hit
      the day-change branch exactly once per crossing.
- [ ] Free-build guard: `spendMoney/receiveMoney` no-op on balance; payday
      must stay a no-op there too.
- [ ] Regression: month with 28/30/31 days, Dec→Jan rollover, L3/Y3 bonus,
      negative balance overdraft, zero-staff month.
