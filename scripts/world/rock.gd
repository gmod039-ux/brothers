class_name Rock
extends Node2D
## A rock on the floor: blocks walking and shots, and a bomb blows it away.
## Part of the background, so it does not boil. Sits among the actors so that
## whoever stands behind it is drawn behind it.
##
## What a "rock" is depends on the floor: a boulder in the basement, a heap
## of coal in the boiler room, a mossy block of masonry or a pile of skulls in
## the catacombs. Each is painted with the floor's own stone texture under
## ink, lit from the upper left like everything else.

const STONE := [
	preload("res://textures/stone_wall_004.png"),
	preload("res://textures/stone_wall_003.png"),
	preload("res://textures/stone_wall_004.png"),
]
const TINTS := [Color("f0dcbc"), Color("8a8a90"), Color("c9cdb6")]
const COAL := Color("2a282c")
const MOSS := Color("6f8a4a")
const BONE := Color("e9dfc8")

var seed_value := 0
## Which floor it is on: 0 basement, 1 boiler room, 2 catacombs.
var style := 0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _h(k: int) -> float:
	return Toon.hash01(seed_value, k)


func _draw() -> void:
	match style:
		1:
			_coal()
		2:
			if _h(40) < 0.3:
				_skulls()
			else:
				_block()
		_:
			_boulder()


## A lumpy outline: an ellipse whose radius wanders with the seed.
func _lumpy(center: Vector2, radii: Vector2, grow: float, k: int, rough := 0.08) -> PackedVector2Array:
	var points := PackedVector2Array()
	var p1 := _h(k) * TAU
	var p2 := _h(k + 1) * TAU
	var n := 40
	for i in n:
		var a := TAU * i / n
		var r := 1.0 + rough * sin(3.0 * a + p1) + rough * 0.6 * sin(5.0 * a + p2)
		points.append(center + Vector2(cos(a) * (radii.x * r + grow), sin(a) * (radii.y * r + grow)))
	return points


## A polygon filled with [param texture] (by world pixels, [param scale] of
## them to one repeat), tinted.
func _textured(points: PackedVector2Array, texture: Texture2D, tint: Color, scale := 360.0) -> void:
	var uvs := PackedVector2Array()
	var offset := Vector2(_h(50), _h(51))
	for p in points:
		uvs.append(p / scale + offset)
	draw_polygon(points, PackedColorArray([tint]), uvs, texture)


func _boulder() -> void:
	var radii := Vector2(48.0 + _h(1) * 6.0, 38.0 + _h(2) * 6.0)
	var body := Vector2(0, -10)
	Toon.glow(self, Vector2(4, 28), Vector2(radii.x * 1.3, 22), Color(0, 0, 0, 0.45), 2)
	draw_colored_polygon(_lumpy(body, radii, 3.0, 3), Toon.INK)
	var fill := _lumpy(body, radii, -2.0, 3)
	_textured(fill, STONE[0], TINTS[0])
	# The underside in shade, the top catching the light.
	Toon.polygon(self, Toon.crescent(body, radii - Vector2(3, 3), 0, 0, 0.0), Color(0.15, 0.08, 0.04, 0.4))
	Toon.spot(self, body + Vector2(-radii.x * 0.32, -radii.y * 0.5), Vector2(radii.x * 0.34, radii.y * 0.14),
			Color(1, 0.97, 0.88, 0.45), 0, 0, -0.25)
	# A crack from the top edge, and a chip knocked out of the side.
	var a := body + Vector2((_h(4) - 0.5) * radii.x * 0.6, -radii.y * 0.8)
	var b := a + Vector2(10 - _h(5) * 20, radii.y * 0.4)
	var c := b + Vector2(14 - _h(6) * 8, radii.y * 0.35)
	var e := b + Vector2(-12, radii.y * 0.2)
	Toon.stroke(self, PackedVector2Array([a, b, c]), 3.0)
	Toon.stroke(self, PackedVector2Array([b, e]), 2.0)
	var side := 1.0 if _h(7) > 0.5 else -1.0
	var chip := body + Vector2(side * radii.x * 0.62, radii.y * 0.1)
	Toon.stroke(self, PackedVector2Array([chip + Vector2(0, -10), chip + Vector2(-side * 8, -2), chip + Vector2(0, 8)]), 2.4)
	# Pebbles broken off it.
	for i in 2:
		var at := Vector2((_h(8 + i) - 0.5) * 90.0, 28.0 + _h(10 + i) * 8.0)
		Toon.blob(self, at, Vector2(7, 5), TINTS[0].darkened(0.25), 0, i, 3.0)


func _coal() -> void:
	Toon.glow(self, Vector2(4, 30), Vector2(64, 22), Color(0, 0, 0, 0.5), 2)
	# Lumps heaped into a mound: the bottom row first, so the top ones sit
	# over them.
	var lumps := [
		[Vector2(-30, 12), Vector2(22, 17)], [Vector2(2, 16), Vector2(24, 18)], [Vector2(32, 10), Vector2(20, 16)],
		[Vector2(-16, -8), Vector2(22, 18)], [Vector2(18, -10), Vector2(21, 17)], [Vector2(0, -28), Vector2(20, 16)],
	]
	for i in lumps.size():
		var lump: Array = lumps[i]
		var at: Vector2 = lump[0] + Vector2(_h(20 + i) - 0.5, _h(30 + i) - 0.5) * 6.0
		var r: Vector2 = lump[1]
		draw_colored_polygon(_lumpy(at, r, 3.0, 60 + i * 3, 0.14), Toon.INK)
		draw_colored_polygon(_lumpy(at, r, -1.5, 60 + i * 3, 0.14), COAL)
		# Facets: coal breaks in flat, glinting planes.
		Toon.spot(self, at + Vector2(-r.x * 0.3, -r.y * 0.35), Vector2(r.x * 0.35, r.y * 0.18),
				Color(0.55, 0.6, 0.75, 0.55), 0, i, -0.4)
		draw_line(at + Vector2(-r.x * 0.1, -r.y * 0.1), at + Vector2(r.x * 0.4, r.y * 0.3), Color(0.5, 0.55, 0.7, 0.35), 2.0)
	# Glow from the furnaces on its side.
	Toon.glow(self, Vector2(26, 12), Vector2(34, 26), Color(1.0, 0.45, 0.15, 0.25), 2)


func _block() -> void:
	var half := Vector2(48, 38)
	var body := Vector2(0, -8)
	Toon.glow(self, Vector2(4, 30), Vector2(58, 18), Color(0, 0, 0, 0.45), 2)
	# The top and the front face of a block of masonry, tipped a little.
	var tilt := (_h(1) - 0.5) * 0.12
	var top := PackedVector2Array()
	var front := PackedVector2Array()
	var corners := [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y * 0.2),
			Vector2(-half.x, half.y * 0.2)]
	for p: Vector2 in corners:
		top.append(body + p.rotated(tilt))
	for p: Vector2 in [Vector2(-half.x, half.y * 0.2), Vector2(half.x, half.y * 0.2), Vector2(half.x, half.y),
			Vector2(-half.x, half.y)]:
		front.append(body + p.rotated(tilt))
	var whole := PackedVector2Array([top[0], top[1], front[2], front[3]])
	draw_colored_polygon(Toon.grown(whole, 4.0), Toon.INK)
	_textured(top, STONE[0], TINTS[2], 300.0)
	_textured(front, STONE[0], TINTS[2].darkened(0.3), 300.0)
	Toon.stroke(self, PackedVector2Array([front[0], front[1]]), 3.0)
	# Chipped corners.
	Toon.stroke(self, PackedVector2Array([top[0] + Vector2(10, 0), top[0] + Vector2(4, 8), top[0] + Vector2(0, 14)]), 2.2)
	# Moss over its top and down its front.
	for i in 3:
		var at := body + Vector2(-half.x * 0.6 + _h(70 + i) * half.x * 1.2, -half.y * 0.9 + _h(73 + i) * 12.0)
		Toon.spot(self, at, Vector2(14, 5) * (0.7 + _h(76 + i) * 0.6), Color(MOSS, 0.85), 0, i)
		Toon.spot(self, at + Vector2(-3, -2), Vector2(7, 2), MOSS.lightened(0.3), 0, i + 3)
	for i in 2:
		var x := -half.x * 0.5 + _h(80 + i) * half.x
		Toon.stroke(self, PackedVector2Array([body + Vector2(x, half.y * 0.2), body + Vector2(x + 2, half.y * 0.2 + 10 + _h(82 + i) * 10)]),
				4.0, MOSS)
	Toon.spot(self, body + Vector2(-half.x * 0.4, -half.y * 0.6), Vector2(16, 4), Color(1, 1, 0.95, 0.3))


func _skulls() -> void:
	Toon.glow(self, Vector2(4, 30), Vector2(58, 18), Color(0, 0, 0, 0.45), 2)
	# Three on the ground, two on them, one on top.
	var rows := [[-34.0, 0.0, 34.0], [-17.0, 17.0], [0.0]]
	for r in rows.size():
		var row: Array = rows[r]
		for i in row.size():
			var at := Vector2(float(row[i]) + (_h(90 + r * 3 + i) - 0.5) * 4.0, 16.0 - r * 24.0)
			_skull(at, 17.0 - r * 0.5, r * 3 + i)


func _skull(at: Vector2, r: float, k: int) -> void:
	Toon.ball(self, at, Vector2(r, r * 0.88), BONE, 0, 100 + k, 3.5)
	Toon.box(self, at + Vector2(0, r * 0.62), Vector2(r * 0.5, r * 0.28), BONE, 0, 110 + k, 3.0)
	Toon.spot(self, at + Vector2(-r * 0.38, 0), Vector2(r * 0.26, r * 0.3), Toon.INK)
	Toon.spot(self, at + Vector2(r * 0.38, 0), Vector2(r * 0.26, r * 0.3), Toon.INK)
	Toon.spot(self, at + Vector2(0, r * 0.36), Vector2(r * 0.1, r * 0.14), Toon.INK)
	for t in 3:
		draw_line(at + Vector2(-r * 0.25 + t * r * 0.25, r * 0.5), at + Vector2(-r * 0.25 + t * r * 0.25, r * 0.8),
				Toon.INK, 1.6)
