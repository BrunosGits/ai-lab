# TH Original Tiles vs CorsixTH

## Block LUT
CorsixTH Src/th_map.cpp gs_iTHMapBlockLUT 256 entries maps TH block ID to sprite. Vanilla hospital tiles allowed: 17,70,18,19,23,16,21,22,66,76,20 per fixOutdoorTiles. Original_cells preserves tiles at load.

## Ultrascan context
Map is 128x128, parcel pricing via parcelTileCount*LandCostPerTile. Footprint flags hospital/buildable/passable are derived from object footprints, not block LUT directly.

## 3441 relevance
Original TH blocks for Ultrascan room walls vs CorsixTH yellow wall type. The mismatch is in object footprint, not block LUT, but tile overlay should eventually show avoid flags per 3475.

## Next
Extract TH block IDs for Ultrascan area from original SAM and compare to CorsixTH original_cells dump.
