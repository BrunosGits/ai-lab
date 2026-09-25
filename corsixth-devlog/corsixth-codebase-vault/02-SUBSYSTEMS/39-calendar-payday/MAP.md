# 39 — Calendar + Payday Cycle — Map

Paths below are `CorsixTH/Lua/...`. Ranges verified by `ssh vps cat/grep`.

| # | Claim | File:lines |
|---|---|---|
| 1 | Month lengths, no leap year, 50 hrs/day | date.lua:34-49 |
| 2 | `hoursPerDay`, `daysPerMonth`, ctor, `lastDayOfMonth` | date.lua:59-106 |
| 3 | `plusHours/plusDays/plusMonths/plusYears` return new Date | date.lua:116-159 |
| 4 | `isLastDayOfMonth`, `isLastDayOfYear` | date.lua:217-231 |
| 5 | `monthOfGame`, `clone`, `isSameDay`, `getProgressInMonths` | date.lua:240-271 |
| 6 | Overflow normalize month→day→hour | date.lua:310-358 |
| 7 | `hours_per_tick/tick_rate`, `game_date=Date()` init | world.lua:72-75 |
| 8 | Speed table (Pause..Speed Up), `setSpeed` | world.lua:726-803 |
| 9 | `onTick` cascade day→month→year, annual-report-before-`onEndYear` | world.lua:913-959 |
| 10 | `setEndMonth/setEndYear`, `wasEmergencySkipped` | world.lua:1024-1054 |
| 11 | `World:onEndDay`: tickDay, VIP, quake, emergency, spawns, autosave | world.lua:1056-1146 |
| 12 | `World:onEndMonth`: population, spawn rate, staff pool | world.lua:1160-1190 |
| 13 | `World:onEndYear`: hospital reset then lose-check | world.lua:1474-1490 |
| 14 | Win-fax `salary_offer = salary + bonus%` | world.lua:1349-1350 |
| 15 | `World:date()` returns clone | world.lua:3021-3023 |
| 16 | Old-save rebuild `Date(year,month,day,hour)` | world.lua:2751-2755 |
| 17 | Salary/interest init: 10000, rate/10000, ScoreMaxInc 300/50 | hospital.lua:59-86 |
| 18 | `statistics[1]`, `money_in/out`, yearly counters init | hospital.lua:140-168 |
| 19 | Insurance pick + `insurance_balance={{0,0,0}x3}`, 2-month comment | hospital.lua:202-222 |
| 20 | Daily: loan/365, researchCost, overdraft/365, heating/day | hospital.lua:899-940 |
| 21 | Monthly spend order: wages, heating, loan, overdraft, research | hospital.lua:949-976 |
| 22 | Salary-score bump, clamp, `player_salary+=ceil` | hospital.lua:981-991 |
| 23 | Insurance payout slot[3], shift-left, autodiscovery, stats push | hospital.lua:994-1022 |
| 24 | `Hospital:onEndYear` resets + L3/Y3 salary bonus | hospital.lua:1063-1082 |
| 25 | `spendMoney/receiveMoney`, `money_in/out`, free-build guard | hospital.lua:1369-1399 |
| 26 | Treatment→insurance vs cash, `addInsuranceMoney[1]+=amount` | hospital.lua:1402-1455 |
| 27 | `logTransaction`: balance+day+month, cap 20, newest-first | hospital.lua:1476-1484 |
| 28 | `researchCost`: `ceil(3*doctors*frac/100)` | research_department.lua:625-647 |
| 29 | Bottom-panel date `monthOfYear/dayOfMonth` draw | dialogs/bottom_panel.lua:265-267 |
| 30 | Graphs read `statistics`, `display_month=monthOfGame` | dialogs/fullscreen/graphs.lua:82-150 |
| 31 | Annual report init, salary/balance sorts | dialogs/fullscreen/annual_report.lua:43-166 |
| 32 | Trophy/award rules, `won/award_won/rep_amount` | dialogs/fullscreen/annual_report.lua:172-300 |
| 33 | `updateAwards`: eoy money + year-end rep | dialogs/fullscreen/annual_report.lua:301-311 |
| 34 | `months_played=getProgressInMonths`, `checkEndGame` | endconditions.lua:35-111 |
| 35 | Transaction string keys (wages/heating/insurance/eoy) | languages/original_strings.lua:355-405 |
| 36 | Fair wage + rise amount; payday sums `profile.wage` | staff_profile.lua:246-263; entities/humanoids/staff.lua:561-613 |
| 37 | Bank page: balance/loan/monthly interest, insurance sums | dialogs/fullscreen/bank_manager.lua:289-312 |
