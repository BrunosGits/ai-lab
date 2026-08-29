# Ultrascanner Object Deep — thob 22

## Identity
thob 22, id ultrascanner, research_category diagnosis, fallback 40, ticks false, build_preview 5068, default_strength 12, crashed 3396, smoke 3436, show_in_town_map true.

## Animations
idle north 1556 via copy_north_to_south, usage Handyman 664, multi_usage Standard Male 1560/1568/1614/1574/1610 and Female 3084/3092/3096/3100/1618. Female finish reuses male 1618. Markers patient -0.9,-0.9 staff 60,-4 px.

## Orientations
north 8 tiles and east 8 tiles as in VANILLA_FOOTPRINT_MATRIX, south copies north, west mirrored via orient_mirror. north use {-1,0 need_west_side}, secondary {1,-1}, handyman {2,0}, smoke {0,0}. east use {0,-1}, secondary {-1,1}, handyman {0,2}, render_attach {{0,0},{1,0},{-1,1}} split anims.

## Process
Origin shift via processTypeDefinition nearest solid to use_position, pathfind_allowed_dirs derived, occupyTiles via 462-549.

## Links
object.lua:36-110 initOrientation, 462-549 occupy, 926-1047 process, machine.lua 20-38 smoke.
