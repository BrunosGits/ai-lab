# 36 — Win/Lose + Insurance/Competitors — Map

| Claim | Path | Lines |
|---|---|---|
| 9 criteria + icons/formats | `CorsixTH/Lua/endconditions.lua` | 25-35 |
| custom getters (happiness, months) | `CorsixTH/Lua/endconditions.lua` | 40-44 |
| ctor: towns/campaign vs town, freebuild skip | `CorsixTH/Lua/endconditions.lua` | 54-74 |
| `_loadGoals`: group bucketing, win/lose_value | `CorsixTH/Lua/endconditions.lua` | 80-104 |
| `checkEndGame`: win needs score 1 + loan 0 | `CorsixTH/Lua/endconditions.lua` | 111-130 |
| `generateReportTable`: 5-max lose-then-win | `CorsixTH/Lua/endconditions.lua` | 135-179 |
| `_checkLoseGroup` incl. report/progress mode | `CorsixTH/Lua/endconditions.lua` | 183-211 |
| `_checkWinGroup` fractional score | `CorsixTH/Lua/endconditions.lua` | 213-229 |
| `_findBestWinGroup` / `getAttribute` | `CorsixTH/Lua/endconditions.lua` | 231-251 |
| init win/lose test point | `CorsixTH/Lua/world.lua` | 281-285 |
| hospitals: Player + AI from `level_config.computer` | `CorsixTH/Lua/world.lua` | 111-123 |
| AI spawn TODO (not simulated) | `CorsixTH/Lua/world.lua` | 1193-1194 |
| `checkIfGameWon` → `winGame(i)` | `CorsixTH/Lua/world.lua` | 1150-1156 |
| `winGame` fax + salary bonus + game_won | `CorsixTH/Lua/world.lua` | 1344-1383 |
| campaign win text / repeated offer | `CorsixTH/Lua/world.lua` | 1391-1456 |
| `loseGame` movie + `level_lost` menu | `CorsixTH/Lua/world.lua` | 1459-1471 |
| `onEndYear`: awards first, then lose check | `CorsixTH/Lua/world.lua` | 1474-1491 |
| tick: month→annual report→onEndYear | `CorsixTH/Lua/world.lua` | 943-956 |
| `AIHospital` ctor, names-only | `CorsixTH/Lua/hospitals/ai_hospital.lua` | 26-37 |
| AI `spawnPatient` stub | `CorsixTH/Lua/hospitals/ai_hospital.lua` | 39-41 |
| AI `logTransaction` no-op | `CorsixTH/Lua/hospitals/ai_hospital.lua` | 43-45 |
| win check months 3/6/9 + win_declined | `CorsixTH/Lua/hospitals/player_hospital.lua` | 543-562 |
| money advice + bankruptcy_imminent | `CorsixTH/Lua/hospitals/player_hospital.lua` | 131-149 |
| win_declined init / afterLoad | `CorsixTH/Lua/hospitals/player_hospital.lua` | 48, 873 |
| insurance: pick 3 companies | `CorsixTH/Lua/hospital.lua` | 202-215 |
| insurance_balance 3x3 delay queue | `CorsixTH/Lua/hospital.lua` | 217-222 |
| monthly payout slot 3 + shift | `CorsixTH/Lua/hospital.lua` | 994-1004 |
| treatment split insured/immediate | `CorsixTH/Lua/hospital.lua` | 1402-1430 |
| `addInsuranceMoney` slot-1 accrue | `CorsixTH/Lua/hospital.lua` | 1452-1454 |
| `spendMoney` / `receiveMoney` ledger | `CorsixTH/Lua/hospital.lua` | 1369-1399 |
| impress-rep trophy flag upkeep | `CorsixTH/Lua/hospital.lua` | 1817-1825 |
| 25% patients get insurer 1-3 | `CorsixTH/Lua/entities/humanoids/patient.lua` | 126-129 |
| report consumer | `CorsixTH/Lua/dialogs/fullscreen/progress_report.lua` | 69-95 |
| bank: insurer graphs + owed tooltips | `CorsixTH/Lua/dialogs/fullscreen/bank_manager.lua` | 75-77, 94-104 |
| fax: accept/return/stay_on_level | `CorsixTH/Lua/dialogs/fullscreen/fax.lua` | 211-243 |
| trophies/awards money+rep | `CorsixTH/Lua/dialogs/fullscreen/annual_report.lua` | 171-245 |
