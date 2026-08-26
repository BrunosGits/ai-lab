# Walls Catalog

> Source: `CorsixTH/Lua/walls/` — 5 wall type definitions

## Wall Type Table

| # | ID | Inside Tiles (N/W) | Outside Tiles (N/W) | Window Tiles (N/W) | Swing Inside (NL/WR/NR/WL) | Swing Outside (NL/WR/NR/WL) | Used By Rooms |
|---|-----|-------------------|---------------------|--------------------|-----------------------------|------------------------------|---------------|
| 1 | [[walls/blue]] | 86/87 | 94/95 | 136/137 | 102/103/138/139 | 110/111/152/153 | [[rooms/inflation]], [[rooms/slack_tongue]], [[rooms/fracture_clinic]], [[rooms/hair_restoration]], [[rooms/electrolysis]], [[rooms/dna_fixer]], [[rooms/jelly_vat]], [[rooms/decontamination]] |
| 2 | [[walls/external]] | 122/123 | 114/115 | *(none)* | *(none)* | *(none)* | External walls / hospital boundary |
| 3 | [[walls/green]] | 88/89 | 96/97 | 140/141 | 104/105/146/147 | 112/113/154/155 | [[rooms/general_diag]], [[rooms/research]], [[rooms/staff_room]], [[rooms/training]], [[rooms/toilets]] |
| 4 | [[walls/white]] | 82/83 | 90/91 | 128/129 | 98/99/130/131 | 106/107/148/149 | [[rooms/gp]], [[rooms/psych]], [[rooms/ward]], [[rooms/operating_theatre]], [[rooms/pharmacy]] |
| 5 | [[walls/yellow]] | 84/85 | 92/93 | 132/133 | 100/101/134/135 | 108/109/150/151 | [[rooms/cardiogram]], [[rooms/scanner]], [[rooms/ultrascan]], [[rooms/blood_machine]], [[rooms/x_ray]] |

## Wall Properties

All interior wall types (blue, green, white, yellow) share:
- `inside_tiles`: north and west variants
- `outside_tiles`: north and west variants
- `window_tiles`: north and west variants
- `swing_inside_tiles`: north_left, west_left, north_right, west_right
- `swing_outside_tiles`: north_left, west_left, north_right, west_right

The **external** wall type differs:
- Has extended tile variants: `north_window_1`, `north_window_2`, `north_expansion`, `west_window_1`, `west_window_2`, `west_expansion`
- Has `north_window_long` / `west_window_long` outside variants
- No swing door tiles (external walls don't use swing doors)
- No standard window tiles

## Wall Color Grouping

| Color | Room Category | Rooms |
|-------|--------------|-------|
| **blue** | Clinics | Inflation, Slack Tongue, Fracture, Hair Restoration, Electrolysis, DNA Fixer, Jelly Vat, Decontamination |
| **green** | Facilities + Diagnosis | General Diagnosis, Research, Staff Room, Training, Toilets |
| **white** | Core Treatment + GP | GP's Office, Psychiatry, Ward, Operating Theatre, Pharmacy |
| **yellow** | Diagnosis | Cardiogram, Scanner, Ultrascan, Blood Machine, X-Ray |

## Cross-Reference Matrix

See [[MASTER_CROSSREF]] for the full wall-room matrix.

## Related Pages

- [[rooms/CATALOG]]
- [[objects/CATALOG]]
- [[diseases/CATALOG]]
- [[level-config/CATALOG]]
