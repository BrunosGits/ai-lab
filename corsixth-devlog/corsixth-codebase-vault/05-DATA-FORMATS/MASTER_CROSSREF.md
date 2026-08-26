# Master Cross-Reference Matrix

> Complete cross-reference linking all CorsixTH data catalogs

## 1. Disease → Room → Object Matrix

| Disease | Treatment Rooms | Required Machines/Objects |
|---------|----------------|--------------------------|
| [[diseases/alien_dna]] → | [[rooms/dna_fixer]] | [[objects/dna_fixer]], [[objects/console]] |
| [[diseases/baldness]] → | [[rooms/hair_restoration]] | [[objects/hair_restorer]], [[objects/console]] |
| [[diseases/bloaty_head]] → | [[rooms/inflation]] | [[objects/inflator]] |
| [[diseases/broken_heart]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/broken_wind]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/chronic_nosehair]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/corrugated_ankles]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/discrete_itching]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/fake_blood]] → | [[rooms/psych]] | [[objects/couch]], [[objects/comfortable_chair]], [[objects/screen]] |
| [[diseases/fractured_bones]] → | [[rooms/fracture_clinic]] | [[objects/cast_remover]] |
| [[diseases/gastric_ejections]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/golf_stones]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/gut_rot]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/hairyitis]] → | [[rooms/electrolysis]] | [[objects/electrolyser]], [[objects/console]] |
| [[diseases/heaped_piles]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/infectious_laughter]] → | [[rooms/psych]] | [[objects/couch]], [[objects/comfortable_chair]], [[objects/screen]] |
| [[diseases/invisibility]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/iron_lungs]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/jellyitis]] → | [[rooms/jelly_vat]] | [[objects/jelly_moulder]] |
| [[diseases/kidney_beans]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/king_complex]] → | [[rooms/psych]] | [[objects/couch]], [[objects/comfortable_chair]], [[objects/screen]] |
| [[diseases/pregnant]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/ruptured_nodules]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/serious_radiation]] → | [[rooms/decontamination]] | [[objects/shower]], [[objects/console]] |
| [[diseases/slack_tongue]] → | [[rooms/slack_tongue]] | [[objects/slicer]] |
| [[diseases/sleeping_illness]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/spare_ribs]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |
| [[diseases/sweaty_palms]] → | [[rooms/psych]] | [[objects/couch]], [[objects/comfortable_chair]], [[objects/screen]] |
| [[diseases/the_squits]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/third_degree_sideburns]] → | [[rooms/psych]] | [[objects/couch]], [[objects/comfortable_chair]], [[objects/screen]] |
| [[diseases/transparency]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/tv_personalities]] → | [[rooms/psych]] | [[objects/couch]], [[objects/comfortable_chair]], [[objects/screen]] |
| [[diseases/uncommon_cold]] → | [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] |
| [[diseases/unexpected_swelling]] → | [[rooms/ward]], [[rooms/operating_theatre]] | [[objects/bed]], [[objects/desk]], [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] |

## 2. Room → Object → Disease Matrix

| Room | Required Objects | Diseases Served |
|------|-----------------|-----------------|
| [[rooms/gp]] | [[objects/desk]], [[objects/cabinet]], [[objects/chair]] | All 34 diseases (initial diagnosis) |
| [[rooms/general_diag]] | [[objects/screen]], [[objects/crash_trolley]] | 22 diseases |
| [[rooms/cardiogram]] | [[objects/cardio]], [[objects/screen]] | 22 diseases |
| [[rooms/scanner]] | [[objects/scanner]], [[objects/console]], [[objects/screen]] | 29 diseases |
| [[rooms/ultrascan]] | [[objects/ultrascanner]] | 21 diseases |
| [[rooms/blood_machine]] | [[objects/blood_machine]] | 17 diseases |
| [[rooms/x_ray]] | [[objects/x_ray]], [[objects/radiation_shield]] | 17 diseases |
| [[rooms/psych]] | [[objects/screen]], [[objects/couch]], [[objects/comfortable_chair]] | 22 diseases (diag) + 6 diseases (treatment) |
| [[rooms/ward]] | [[objects/desk]], [[objects/bed]] | 22 diseases (diag) + 8 diseases (treatment) |
| [[rooms/operating_theatre]] | [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]], [[objects/x_ray_viewer]] | 8 diseases |
| [[rooms/pharmacy]] | [[objects/pharmacy_cabinet]] | 12 diseases |
| [[rooms/inflation]] | [[objects/inflator]] | 1 disease (Bloaty Head) |
| [[rooms/slack_tongue]] | [[objects/slicer]] | 1 disease (Slack Tongue) |
| [[rooms/fracture_clinic]] | [[objects/cast_remover]] | 1 disease (Fractured Bones) |
| [[rooms/hair_restoration]] | [[objects/hair_restorer]], [[objects/console]] | 1 disease (Baldness) |
| [[rooms/electrolysis]] | [[objects/electrolyser]], [[objects/console]] | 1 disease (Hairyitis) |
| [[rooms/dna_fixer]] | [[objects/dna_fixer]], [[objects/console]] | 1 disease (Alien DNA) |
| [[rooms/jelly_vat]] | [[objects/jelly_moulder]] | 1 disease (Jellyitis) |
| [[rooms/decontamination]] | [[objects/shower]], [[objects/console]] | 1 disease (Serious Radiation) |
| [[rooms/research]] | [[objects/desk]], [[objects/cabinet]], [[objects/autopsy]] | All diseases (research) |
| [[rooms/staff_room]] | [[objects/sofa]] | None (staff rest) |
| [[rooms/training]] | [[objects/lecture_chair]], [[objects/projector]] | None (staff training) |
| [[rooms/toilets]] | [[objects/loo]], [[objects/sink]] | None (facilities) |

## 3. Object → Room → Disease Matrix

### Machines (Treatment)

| Machine Object | Room | Disease(s) |
|---------------|------|-----------|
| [[objects/inflator]] | [[rooms/inflation]] | [[diseases/bloaty_head]] |
| [[objects/slicer]] | [[rooms/slack_tongue]] | [[diseases/slack_tongue]] |
| [[objects/cast_remover]] | [[rooms/fracture_clinic]] | [[diseases/fractured_bones]] |
| [[objects/hair_restorer]] | [[rooms/hair_restoration]] | [[diseases/baldness]] |
| [[objects/electrolyser]] | [[rooms/electrolysis]] | [[diseases/hairyitis]] |
| [[objects/dna_fixer]] | [[rooms/dna_fixer]] | [[diseases/alien_dna]] |
| [[objects/jelly_moulder]] | [[rooms/jelly_vat]] | [[diseases/jellyitis]] |
| [[objects/shower]] | [[rooms/decontamination]] | [[diseases/serious_radiation]] |
| [[objects/pharmacy_cabinet]] | [[rooms/pharmacy]] | 12 diseases (Broken Wind, Chronic Nosehair, Corrugated Ankles, Discrete Itching, Gastric Ejections, Gut Rot, Heaped Piles, Invisibility, Sleeping Illness, The Squits, Transparency, Uncommon Cold) |
| [[objects/couch]] | [[rooms/psych]] | 6 diseases (Fake Blood, Infectious Laughter, King Complex, Sweaty Palms, Third Degree Sideburns, TV Personalities) |
| [[objects/bed]] | [[rooms/ward]] | 8 diseases (pre-op/post-op) |
| [[objects/operating_table]] | [[rooms/operating_theatre]] | 8 diseases (Broken Heart, Golf Stones, Iron Lungs, Kidney Beans, Pregnant, Ruptured Nodules, Spare Ribs, Unexpected Swelling) |

### Machines (Diagnosis)

| Machine Object | Room | Diseases Using It |
|---------------|------|-------------------|
| [[objects/cardio]] | [[rooms/cardiogram]] | 22 diseases |
| [[objects/scanner]] | [[rooms/scanner]] | 29 diseases |
| [[objects/ultrascanner]] | [[rooms/ultrascan]] | 21 diseases |
| [[objects/blood_machine]] | [[rooms/blood_machine]] | 17 diseases |
| [[objects/x_ray]] | [[rooms/x_ray]] | 17 diseases |

### Common Objects

| Object | Rooms Used In |
|--------|--------------|
| [[objects/console]] | [[rooms/scanner]], [[rooms/hair_restoration]], [[rooms/electrolysis]], [[rooms/dna_fixer]], [[rooms/jelly_vat]], [[rooms/decontamination]] |
| [[objects/screen]] | [[rooms/gp]], [[rooms/cardiogram]], [[rooms/general_diag]], [[rooms/scanner]], [[objects/psych]] |
| [[objects/desk]] | [[rooms/gp]], [[rooms/ward]], [[rooms/research]] |
| [[objects/cabinet]] | [[rooms/gp]], [[rooms/research]] |
| [[objects/extinguisher]] | All rooms (additional) |
| [[objects/radiator]] | All rooms (additional) |
| [[objects/plant]] | All rooms (additional) |
| [[objects/bin]] | All rooms (additional) |

## 4. Wall → Room Matrix

| Wall Type | Rooms Using It |
|-----------|---------------|
| [[walls/blue]] | [[rooms/inflation]], [[rooms/slack_tongue]], [[rooms/fracture_clinic]], [[rooms/hair_restoration]], [[rooms/electrolysis]], [[rooms/dna_fixer]], [[rooms/jelly_vat]], [[rooms/decontamination]] |
| [[walls/green]] | [[rooms/general_diag]], [[rooms/research]], [[rooms/staff_room]], [[rooms/training]], [[rooms/toilets]] |
| [[walls/white]] | [[rooms/gp]], [[rooms/psych]], [[rooms/ward]], [[rooms/operating_theatre]], [[rooms/pharmacy]] |
| [[walls/yellow]] | [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]] |
| [[walls/external]] | Hospital boundary (no room association) |

## 5. Level Config → Room → Object Matrix

| Level | Start Cash | Key Rooms Available | Objects Available |
|-------|-----------|---------------------|-------------------|
| 1 | 40,000 | [[rooms/gp]], [[rooms/pharmacy]], [[rooms/ward]] | [[objects/desk]], [[objects/cabinet]], [[objects/chair]], [[objects/bed]], [[objects/screen]], [[objects/pharmacy_cabinet]] |
| 2-3 | 40-50k | + [[rooms/psych]], [[rooms/staff_room]] | + [[objects/couch]], [[objects/comfortable_chair]], [[objects/sofa]] |
| 4-5 | 50k | + [[rooms/cardiogram]], [[rooms/scanner]] | + [[objects/cardio]], [[objects/scanner]], [[objects/console]] |
| 6-7 | 50k | + [[rooms/x_ray]], [[rooms/ultrascan]], [[rooms/blood_machine]] | + [[objects/x_ray]], [[objects/ultrascanner]], [[objects/blood_machine]], [[objects/radiation_shield]] |
| 8-9 | 60k | + [[rooms/operating_theatre]] | + [[objects/operating_table]], [[objects/surgeon_screen]], [[objects/op_sink1]] |
| 10+ | 60-70k | All rooms available | All objects available |

### Object Availability by Level

| Level | Objects Unlocked |
|-------|-----------------|
| 1 | Desk, Cabinet, Door, Bench, Chair, Drinks Machine, Bed, Reception Desk, Screen, Couch, Sofa, Crash Trolley, TV, Op Sink 1/2, Surgeon Screen, Lecture Chair, Pharmacy Cabinet, Fire Extinguisher, Radiator, Plant, Bin, Toilet, Sink, Bookcase, Skeleton, Comfy Chair, Radiation Shield, X-Ray Viewer |
| 2+ | Inflator (2500), Cardiogram (1000), Scanner (5000) |
| 3+ | Ultrascan (6000), Hair Restorer (1000), Slicer (1500) |
| 4+ | Cast Remover (2000), Electrolyser (3500) |
| 5+ | X-Ray (4000), Blood Machine (3000) |
| 6+ | Operating Table (5000), Jelly Moulder (6500) |
| 7+ | DNA Restorer (10000), Decontamination Shower (6500) |
| 8+ | Autopsy (4000), Research Computer (5000) |

## Catalog Index

| Catalog | Location | Items |
|---------|----------|-------|
| [[diseases/CATALOG]] | `track-c/diseases/` | 34 diseases |
| [[rooms/CATALOG]] | `track-c/rooms/` | 23 rooms |
| [[objects/CATALOG]] | `track-c/objects/` | 41 objects + 15 machines + 4 doors |
| [[walls/CATALOG]] | `track-c/walls/` | 5 wall types |
| [[level-config/CATALOG]] | `track-c/level-config/` | Configuration data |
