# Diseases Catalog

> Source: `CorsixTH/Lua/diseases/` — 34 disease definitions

## Disease Table

| # | ID | Name | Cure Price | Contagious | Requires Machine | Diagnosis Rooms | Treatment Rooms | Expertise ID |
|---|-----|------|-----------|-----------|-----------------|-----------------|-----------------|-------------|
| 1 | [[alien_dna]] | Alien DNA | 2000 | No | Yes | *(none)* | [[rooms/dna_fixer]] | 8 |
| 2 | [[baldness]] | Baldness | 950 | No | Yes | [[rooms/x_ray]], [[rooms/blood_machine]], [[rooms/scanner]] | [[rooms/hair_restoration]] | 10 |
| 3 | [[bloaty_head]] | Bloaty Head | 850 | No | Yes | [[rooms/general_diag]], [[rooms/x_ray]], [[rooms/cardiogram]], [[rooms/scanner]] | [[rooms/inflation]] | 2 |
| 4 | [[broken_heart]] | Broken Heart | 1900 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 20 |
| 5 | [[broken_wind]] | Broken Wind | 1300 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 17 |
| 6 | [[chronic_nosehair]] | Chronic Nosehair | 800 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 25 |
| 7 | [[corrugated_ankles]] | Corrugated Ankles | 800 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 24 |
| 8 | [[discrete_itching]] | Discrete Itching | 700 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 11 |
| 9 | [[fake_blood]] | Fake Blood | 800 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/psych]] | 27 |
| 10 | [[fractured_bones]] | Fractured Bones | 450 | No | Yes | [[rooms/scanner]] | [[rooms/fracture_clinic]] | 9 |
| 11 | [[gastric_ejections]] | Gastric Ejections | 650 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 28 |
| 12 | [[golf_stones]] | Golf Stones | 1600 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 34 |
| 13 | [[gut_rot]] | Gut Rot | 350 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 33 |
| 14 | [[hairyitis]] | Hairyitis | 1150 | No | Yes | [[rooms/x_ray]], [[rooms/scanner]] | [[rooms/electrolysis]] | 3 |
| 15 | [[heaped_piles]] | Heaped Piles | 400 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 32 |
| 16 | [[infectious_laughter]] | Infectious Laughter | 1500 | Yes | No | [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/psych]] | 23 |
| 17 | [[invisibility]] | Invisibility | 1400 | No | No | [[rooms/x_ray]], [[rooms/scanner]] | [[rooms/pharmacy]] | 5 |
| 18 | [[iron_lungs]] | Iron Lungs | 1700 | Yes | No | [[rooms/x_ray]], [[rooms/cardiogram]], [[rooms/blood_machine]] | [[rooms/ward]], [[rooms/operating_theatre]] | 30 |
| 19 | [[jellyitis]] | Jellyitis | 1000 | No | Yes | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/jelly_vat]] | 12 |
| 20 | [[kidney_beans]] | Kidney Beans | 1050 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 19 |
| 21 | [[king_complex]] | King Complex (Elvis) | 1600 | No | No | [[rooms/x_ray]], [[rooms/scanner]] | [[rooms/psych]] | 4 |
| 22 | [[pregnant]] | Pregnancy | 200 | No | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 14 |
| 23 | [[ruptured_nodules]] | Ruptured Nodules | 1600 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 21 |
| 24 | [[serious_radiation]] | Serious Radiation | 1800 | No | Yes | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/decontamination]] | 6 |
| 25 | [[slack_tongue]] | Slack Tongue | 900 | No | Yes | [[rooms/x_ray]], [[rooms/scanner]] | [[rooms/slack_tongue]] | 7 |
| 26 | [[sleeping_illness]] | Sleeping Illness | 750 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 13 |
| 27 | [[spare_ribs]] | Spare Ribs | 1100 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 18 |
| 28 | [[sweaty_palms]] | Sweaty Palms | 600 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/psych]] | 31 |
| 29 | [[the_squits]] | The Squits | 400 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 29 |
| 30 | [[third_degree_sideburns]] | Third Degree Sideburns | 550 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/psych]] | 26 |
| 31 | [[transparency]] | Transparency | 800 | No | No | [[rooms/scanner]] | [[rooms/pharmacy]] | 15 |
| 32 | [[tv_personalities]] | TV Personalities | 800 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/psych]] | 22 |
| 33 | [[uncommon_cold]] | Uncommon Cold | 300 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/pharmacy]] | 16 |
| 34 | [[unexpected_swelling]] | Unexpected Swelling | 500 | Yes | No | [[rooms/general_diag]], [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]], [[rooms/psych]], [[rooms/ward]] | [[rooms/ward]], [[rooms/operating_theatre]] | 35 |

## Treatment Summary

| Treatment Room | Diseases Using It |
|---------------|-------------------|
| [[rooms/pharmacy]] | Broken Wind, Chronic Nosehair, Corrugated Ankles, Discrete Itching, Gastric Ejections, Gut Rot, Heaped Piles, Invisibility, Sleeping Illness, The Squits, Transparency, Uncommon Cold |
| [[rooms/psych]] | Fake Blood, Infectious Laughter, King Complex, Sweaty Palms, Third Degree Sideburns, TV Personalities |
| [[rooms/ward]] + [[rooms/operating_theatre]] | Broken Heart, Golf Stones, Iron Lungs, Kidney Beans, Pregnant, Ruptured Nodules, Spare Ribs, Unexpected Swelling |
| [[rooms/inflation]] | Bloaty Head |
| [[rooms/hair_restoration]] | Baldness |
| [[rooms/dna_fixer]] | Alien DNA |
| [[rooms/electrolysis]] | Hairyitis |
| [[rooms/fracture_clinic]] | Fractured Bones |
| [[rooms/jelly_vat]] | Jellyitis |
| [[rooms/slack_tongue]] | Slack Tongue |
| [[rooms/decontamination]] | Serious Radiation |

## Diagnosis Summary

| Diagnosis Room | Diseases Using It |
|---------------|-------------------|
| [[rooms/scanner]] | 29 diseases (nearly all) |
| [[rooms/x_ray]] | 17 diseases |
| [[rooms/cardiogram]] | 22 diseases |
| [[rooms/blood_machine]] | 17 diseases |
| [[rooms/general_diag]] | 22 diseases |
| [[rooms/ultrascan]] | 21 diseases |
| [[rooms/psych]] | 22 diseases |
| [[rooms/ward]] | 22 diseases |

## Cross-Reference Matrix

See [[MASTER_CROSSREF]] for the full disease-room-object matrix.

## Related Pages

- [[rooms/CATALOG]]
- [[objects/CATALOG]]
- [[walls/CATALOG]]
- [[level-config/CATALOG]]
