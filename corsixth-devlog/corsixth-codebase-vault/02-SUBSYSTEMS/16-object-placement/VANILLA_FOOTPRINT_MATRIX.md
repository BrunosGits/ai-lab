# Vanilla Footprint Matrix — Ultrascan (3441)

| Orientation | Tile | Current (CorsixTH) | Strict vanilla | Minimal | Impact |
|-------------|------|--------------------|----------------|---------|--------|
| north | -1,-1 | need_west_side | complete_cell+need_west_side | need_west_side | Strict blocks corner wall adjacency, fixes build where original blocks |
| north | 1,-1 | only_passable+complete_cell | complete_cell | only_passable+complete_cell | Strict makes top-right solid |
| north | -1,0 | only_passable+need_west_side | need_west_side | need_west_side | Minimal flips contested gap where doctor stands |
| north | 1,0 | only_passable | blocked | only_passable | Strict blocks walk through table |
| north | -1,1 | only_passable+need_west_side | need_west_side | only_passable+need_west_side | Strict solidifies bottom-left |
| north | 0,1 | only_passable | blocked or only_passable | only_passable | Depends on strict vs minimal |
| east | -1,-1 | complete_cell | complete_cell | complete_cell | No change |
| east | 0,-1 | only_passable+need_north_side | need_north_side | only_passable+need_north_side | Strict blocks north edge |
| east | 1,-1 | only_passable+need_north_side | need_north_side | only_passable+need_north_side | Strict blocks |
| east | 1,0 | only_passable | blocked | only_passable | Strict blocks walk through |

South copies north, west mirrored via orient_mirror. Origin shift via processTypeDefinition nearest solid to use_position.

World:occupyTilesByObjectFootprintAt will enforce new passable flags. Strict may invalidate old saves where ultrascanner sits on now blocked tile. Note in 12-saveload-migrations if strict chosen.
