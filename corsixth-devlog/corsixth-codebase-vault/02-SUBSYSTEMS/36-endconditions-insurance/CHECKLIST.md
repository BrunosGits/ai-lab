# 36 — Pre-fix Safety Gate

Do not change win/lose/insurance without all boxes checked.

## Repro first

- [ ] Identified level file + Group ids for win_criteria/lose_criteria.
- [ ] Reproduced via `checkEndGame` return (`win`/`nothing`/reason+limit).
- [ ] Checked freebuild (`endconditions` empty → always `nothing`).
- [ ] Checked loan>0 blocks win but not lose.

## Boundaries

- [ ] `MaxMin` polarity verified for touched criterion (1=max, else min).
- [ ] `boundary` (warn) vs `win/lose_value` (fatal) not conflated.
- [ ] Custom attrs (happiness/months) read via `getAttribute`, not raw field.
- [ ] Report table still ≤5, lose-first, sorted by criterion.

## Money / insurance

- [ ] Insurer index 1-3 matches `insurance`/`insurance_balance` slots.
- [ ] Payout delay (current→slot1, pay slot3, shift) preserved.
- [ ] `free_build_mode` still bypasses `spend/receiveMoney`.
- [ ] Annual awards still applied before year-end lose check.

## Competitors / fax

- [ ] No new logic assumes AI economy (AI is stub/no ledger).
- [ ] `win_declined` months 3/9 gating preserved.
- [ ] Fax choices `accept_new_level`/`stay_on_level`/`return_to_main_menu` intact.
- [ ] `game_won` set/cleared; pause/resume callback intact.

## Regression

- [ ] Progress report, bank manager, annual report opened manually.
- [ ] Save/load: `win_declined`, `insurance_balance` persist.
- [ ] Linked notes [[07-financial-system/SUMMARY]], [[08-reputation-system/SUMMARY]] re-checked.
