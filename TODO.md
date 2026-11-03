# Hexa tiles

## To-Do

bottom mesh: export old generation
curve 5: connect hole to center / make slope
curve 6: hole size with no extra margin (to connect with canyon)
cliff vegetation
material overhaul
cliff_offset=2: extrapolate bottom slope
cliff slope: more chaos
top models: make grass do not overpass rock cliff
remove top if up tile fully overlaps
under rock models! allowing tunnels and disconnected vertical cliff_offsets

## Mesh naming

CURVE_PART_OFFSET_BIOME_ALT_DATATYPE.res

CURVE: 1, 2, .., 7 (full)
PART: bottom, cliff, top
OFFSET: 0000, 11, 1100, 2110, `{first_bottom}{second_bottom}[{first_top}{second_top}`
BIOME: rock, sand, dirt
ALT: 00, 01, 02, ... (alternative random seed)
DATATYPE: model, veg01, veg02 (veg density)

special offset/curve for no neighbor cliff: middle slope is more flat than edges

curve 1-5: bottom offset 0-2 , top offset 0-1
curve 6: offset 0-1 ;
curve 7: offset N/A ;

curve 1-2: alt 0-1
curve: 3-6: alt 0
curve 7: alt 0-2



cliff { "total": 1240, "002.res": 237, "001.res": 834, "004.res": 24, "003.res": 138, "006.res": 5, "005.res": 2 }
{ "total": 4112,
"top_002.res": 237, "ground_002.res": 237, "cliff_002.res": 237,
"cliff_001.res": 834, "ground_001.res": 834, "top_001.res": 834,
"top_007.res": 392,
"cliff_004.res": 24, "ground_004.res": 24, "top_004.res": 24,
"cliff_003.res": 138, "ground_003.res": 138, "top_003.res": 138,
"top_006.res": 5, "ground_006.res": 5, "cliff_006.res": 5,
"top_005.res": 2, "ground_005.res": 2, "cliff_005.res": 2 }
