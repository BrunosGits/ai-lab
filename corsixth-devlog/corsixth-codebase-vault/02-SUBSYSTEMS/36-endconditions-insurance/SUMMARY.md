# 36 — Win/Lose + Insurance/Competitors — Summary

> Scope: `endconditions.lua`, `PlayerHospital` vs `AIHospital`,
> insurance payouts, bankruptcy warnings, win/lose fax + awards.
> Detail: [[36-endconditions-insurance/MAP]] · Gate: [[36-endconditions-insurance/CHECKLIST]] · Template: [[36-endconditions-insurance/SCAFFOLD]]
> Money: [[07-financial-system/SUMMARY]] · Rep: [[08-reputation-system/SUMMARY]]

## 1. Overview

- **[Documented fact]** `EndConditions` loads grouped win/lose goals
  from `level_config.win_criteria` / `lose_criteria` at world init.
- **[Documented fact]** Win needs ALL criteria of ANY one group met
  AND `hospital.loan == 0`. Lose needs ALL criteria of a lose group met.
- **[Documented fact]** `PlayerHospital` is the only fully simulated
  hospital; `AIHospital` is names-only (stub `spawnPatient`, no ledger).
- **[Documented fact]** Insurance = 3 named companies per hospital,
  25% of patients flagged, 2-month delayed payout via 3-slot queue.
- **[Documented fact]** No hard `goBankrupt()`; "bankruptcy" is a lose
  goal on `balance` + adviser warning text. Lose movies/menus via `World`.
- **[Inference]** Competitors exist for progress-report flavour, not for
  win/lose simulation. No AI economy ticks observed.
- **[Hypothesis]** `boundary` vs `win_value`/`lose_value` split lets the
  progress report warn early before the fatal limit — needs level-file check.

## 2. Lifecycle / Flow

1. `World:determineWinningConditions()` builds `EndConditions` (skip if freebuild).
2. `_loadGoals()` buckets criteria by `Group`, records `highest_group`.
3. Monthly: `PlayerHospital:onEndMonth()` calls `checkIfGameWon()` at months 3/6/9.
4. Yearly: `World:onEndYear()` shows `UIAnnualReport` (awards first), then
   `checkEndGame()` → `loseGame()` on `limit`.
5. Win: `winGame()` pauses, offers salary bonus, queues information fax
   (`accept_new_level` / `stay_on_level` / `return_to_main_menu`).
6. Lose: `loseGame()` plays lose movie, `loadMainMenu(level_lost)` with
   `reason:format(limit)`.
7. Treatment: 25% insured → `addInsuranceMoney()` (slot 1); else immediate
   `receiveMoney()` + price/rep impact. Insurer pays out slot 3 on `onEndMonth`.

## 3. Key mechanics

- **Criteria table (9):** reputation, balance, %cured, num_cured,
  %killed, value, staff/patient happiness (custom fn), months_played.
- **Custom getters:** happiness via averages; months via `game_date`.
- **Loan gate:** unpaid loan blocks `"win"` but not `"lose"`.
- **Report table:** max 5 entries — lose criteria over boundary first
  (by progress), then best win group fill, sorted by criterion id.
- **Insurance ledger:** `insurance_balance = {{0,0,0}x3}`; shift-left monthly.
- **Bank UI:** shows loan + 3 insurer owed amounts + graphs; tooltips only.
- **Awards:** `UIAnnualReport:checkTrophiesAndAwards()` grants money/rep
  BEFORE year-end lose check (explicit comment in `World:onEndYear`).

## 4. Related subsystems

- Finance ledger (`receiveMoney`/`spendMoney`, loans, overdraft): [[07-financial-system/SUMMARY]]
- Reputation thresholds + `has_impressive_reputation`: [[08-reputation-system/SUMMARY]]
- Progress report dialog (`generateReportTable` consumer)
- Bank manager dialog (loan + insurance display)
- Fax dialog (win/lose/emergency/VIP choices)
- Annual report (trophies/awards economy injection)
