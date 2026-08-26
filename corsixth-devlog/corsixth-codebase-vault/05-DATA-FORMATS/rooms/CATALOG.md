# Rooms Catalog

> Source: `CorsixTH/Lua/rooms/` — 23 room definitions

## Room Table

| # | ID | Name | Category | Min Size | Wall Type | Required Staff | Objects Needed | VIP Visit | Swing Doors |
|---|-----|------|----------|----------|-----------|---------------|----------------|-----------|-------------|
| 1 | [[gp]] | GP's Office | diagnosis:1 | 4 | white | Doctor ×1 | [[objects/desk]] ×1, [[objects/cabinet]] ×1, [[objects/chair]] ×1 | No | No |
| 2 | [[general_diag]] | General Diagnosis | diagnosis:2 | 5 | green | Doctor ×1 | [[objects/screen]] ×1, [[objects/crash_trolley]] ×1 | No | No |
| 3 | [[cardiogram]] | Cardiogram | diagnosis:3 | 4 | yellow | Doctor ×1 | [[objects/cardio]] ×1, [[objects/screen]] ×1 | No | No |
| 4 | [[scanner]] | Scanner | diagnosis:4 | 5 | yellow | Doctor ×1 | [[objects/scanner]] ×1, [[objects/console]] ×1, [[objects/screen]] ×1 | No | No |
| 5 | [[ultrascan]] | Ultrascan | diagnosis:5 | 4 | yellow | Doctor ×1 | [[objects/ultrascanner]] ×1 | No | No |
| 6 | [[blood_machine]] | Blood Machine Room | diagnosis:6 | 4 | yellow | Doctor ×1 | [[objects/blood_machine]] ×1 | No | No |
| 7 | [[x_ray]] | X-Ray | diagnosis:7 | 6 | yellow | Doctor ×1 | [[objects/x_ray]] ×1, [[objects/radiation_shield]] ×1 | No | No |
| 8 | [[psych]] | Psychiatry | diagnosis:8, treatment:1 | 5 | white | Psychiatrist ×1 | [[objects/screen]] ×1, [[objects/couch]] ×1, [[objects/comfortable_chair]] ×1 | No | No |
| 9 | [[ward]] | Ward | diagnosis:9, treatment:2 | 6 | white | Nurse ×1+ | [[objects/desk]] ×1, [[objects/bed]] ×1+ | Yes | Yes |
| 10 | [[operating_theatre]] | Operating Theatre | treatment:3 | 6 | white | Surgeon ×2 | [[objects/operating_table]] ×1, [[objects/surgeon_screen]] ×1, [[objects/op_sink1]] ×1, [[objects/x_ray_viewer]] ×1 | Yes | Yes |
| 11 | [[pharmacy]] | Pharmacy | treatment:4 | 4 | white | Nurse ×1 | [[objects/pharmacy_cabinet]] ×1 | No | No |
| 12 | [[inflation]] | Inflation Room | clinics:1 | 4 | blue | Doctor ×1 | [[objects/inflator]] ×1 | No | No |
| 13 | [[slack_tongue]] | Slack Tongue Clinic | clinics:2 | 4 | blue | Doctor ×1 | [[objects/slicer]] ×1 | No | No |
| 14 | [[fracture_clinic]] | Fracture Clinic | clinics:3 | 4 | blue | Nurse ×1 | [[objects/cast_remover]] ×1 | No | No |
| 15 | [[hair_restoration]] | Hair Restoration | clinics:4 | 4 | blue | Doctor ×1 | [[objects/hair_restorer]] ×1, [[objects/console]] ×1 | No | No |
| 16 | [[electrolysis]] | Electrolysis | clinics:5 | 5 | blue | Doctor ×1 | [[objects/electrolyser]] ×1, [[objects/console]] ×1 | No | No |
| 17 | [[dna_fixer]] | DNA Fixer | clinics:6 | 5 | blue | Researcher ×1 | [[objects/dna_fixer]] ×1, [[objects/console]] ×1 | Yes | Yes |
| 18 | [[jelly_vat]] | Jelly Vat | clinics:7 | 4 | blue | Doctor ×1 | [[objects/jelly_moulder]] ×1 | No | No |
| 19 | [[decontamination]] | Decontamination | clinics:8 | 5 | blue | Doctor ×1 | [[objects/shower]] ×1, [[objects/console]] ×1 | No | No |
| 20 | [[research]] | Research Room | facilities:2 | 5 | green | Researcher ×1+ | [[objects/desk]] ×1, [[objects/cabinet]] ×1, [[objects/autopsy]] ×1 | Yes | No |
| 21 | [[staff_room]] | Staff Room | facilities:1 | 4 | green | *(none)* | [[objects/sofa]] ×1 | No | No |
| 22 | [[training]] | Training Room | facilities:4 | 4 | green | Consultant ×1 | [[objects/lecture_chair]] ×1, [[objects/projector]] ×1 | No | No |
| 23 | [[toilets]] | Toilets | facilities:3 | 4 | green | *(none)* | [[objects/loo]] ×1, [[objects/sink]] ×1 | No | No |

## Objects Additional (Available in Room)

All rooms allow: [[objects/extinguisher]], [[objects/radiator]], [[objects/plant]], [[objects/bin]]

Additional per room:
- **Psych**: [[objects/bookcase]], [[objects/skeleton]]
- **Research**: [[objects/computer]], [[objects/desk]], [[objects/cabinet]], [[objects/analyser]]
- **Staff Room**: [[objects/sofa]], [[objects/pool_table]], [[objects/tv]], [[objects/video_game]]
- **Training**: [[objects/lecture_chair]], [[objects/bookcase]], [[objects/skeleton]]
- **Ward**: [[objects/desk]], [[objects/bed]]
- **Toilets**: [[objects/loo]], [[objects/sink]]

## Room Cost (from base_config)

| Room | Config Index | Build Cost |
|------|-------------|-----------|
| GP's Office | 7 | 2280 |
| Psychiatry | 8 | 2270 |
| Ward | 9 | 1700 |
| Operating Theatre | 10 | 2250 |
| Pharmacy | 11 | 500 |
| Cardiogram | 12 | 470 |
| Scanner | 13 | 3970 |
| Ultrascan | 14 | 2000 |
| Blood Machine | 15 | 3000 |
| X-Ray | 16 | 2000 |
| Inflation | 17 | 1500 |
| DNA Fixer (Alien) | 18 | 7000 |
| Hair Restoration | 19 | 500 |
| Slack Tongue | 20 | 1500 |
| Fracture Clinic | 21 | 500 |
| Training Room | 22 | 1850 |
| Electrolysis | 23 | 500 |
| Jelly Vat | 24 | 4500 |
| Staff Room | 25 | 1350 |
| General Diagnosis | 27 | 720 |
| Research | 28 | 800 |
| Toilets | 29 | 1170 |
| Decontamination | 30 | 5500 |

## Cross-Reference Matrix

See [[MASTER_CROSSREF]] for the full room-object-disease matrix.

## Related Pages

- [[diseases/CATALOG]]
- [[objects/CATALOG]]
- [[walls/CATALOG]]
- [[level-config/CATALOG]]
