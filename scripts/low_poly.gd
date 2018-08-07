extends Node

"""
Cliff modeling
global shape h=100m, thickness=15m
extrude (10m) and bevel 7.5m on jonction
{extrude bottom 10m}
subdivide main visible faces
 - vertical 150m / 10 -> 15m    | 160m (-10 -> 150) / 8 -> 20m
 - horizontal 100m / 10 -> 10m, | 100m / 10 -> 10m
RANDOM_SELECT {select all, remove visible, random select, random select, invert selection}
grab tangente horiz, +2m, random enable 30m radius
RANDOM_SELECT
grab tangente horiz, -2m, random enable 30m radius
select even column
extrude (0.15)
RANDOM SELECT
grab normal, individual origin, 3m, random enable 30m radius
triangulate
decimate 0.5, vertex group visible face	

extrude vertical block
select random (select no visible, add random select, invert select)
translate tangente random : ??m
translate normal random : ??m
extrude bottom (below water level)


environnement
canyon - forest/water
forest montain - go down
foret avec arbre en toit (feuille en haut)
grotte
circuit sol/mer
city gratte-ciel -> horizontal / structure avec extension -> vertical climb/down
"""