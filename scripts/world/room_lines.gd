class_name RoomLines
extends Node2D
## The ink of a room, over its painted walls and floor: the shadow where the
## floor meets the walls, the grout between floor tiles, bricks, the outlines
## of the box, and the four doors. It is a background, so it holds still --
## only characters boil.

const DOOR_WIDTH := 150.0
const BRICK := Color(0.2, 0.08, 0.04, 0.55)
const FRAME := Color("c9b08a")
## Frames of doors to special rooms: the boss's is iron with a red glow
## beyond, the treasure room's gold.
const FRAMES := {"boss": Color("5a4a44"), "treasure": Color("e0b23a")}
const DOOR_WOOD := Color("7a4a2a")
const DOOR_PLANK := Color(0.2, 0.1, 0.05, 0.8)

var room: Room
var seed_value := 0


func _draw() -> void:
	var quads := room.faces()
	_floor_shadow()
	_grout()
	for side: String in Room.DOORS:
		_bricks(quads[side], side)
	_outlines()
	for side: String in room.doors:
		_door(quads[side], side, bool(room.open_doors.get(side, false)), str(room.doors[side]))


## The floor darkens towards the walls: light from the middle of the room
## does not reach into the corners.
func _floor_shadow() -> void:
	var f := Room.FLOOR
	var depth := 70.0
	var dark := Color(Toon.INK, 0.4)
	var clear := Color(Toon.INK, 0.0)
	var edges := [
		[f.position, Vector2(f.end.x, f.position.y), Vector2(0, 1)],
		[Vector2(f.end.x, f.position.y), f.end, Vector2(-1, 0)],
		[f.end, Vector2(f.position.x, f.end.y), Vector2(0, -1)],
		[Vector2(f.position.x, f.end.y), f.position, Vector2(1, 0)],
	]
	for edge: Array in edges:
		var a: Vector2 = edge[0]
		var b: Vector2 = edge[1]
		var inward: Vector2 = edge[2]
		# The top wall is the tall one facing us: its shadow reaches further.
		var reach := depth * (1.6 if inward == Vector2(0, 1) else 1.0)
		draw_polygon(PackedVector2Array([a, b, b + inward * reach, a + inward * reach]),
				PackedColorArray([dark, dark, clear, clear]))


## Grout lines between the stone tiles, each tile edge drawn as its own
## slightly crooked stroke with small gaps at the corners, the way a hand
## draws a grid.
func _grout() -> void:
	var f := Room.FLOOR
	var t := Room.TILE
	var n := 0
	for col in range(1, Room.COLS):
		for row in Room.ROWS:
			var x := f.position.x + col * t
			_grout_stroke(Vector2(x, f.position.y + row * t), Vector2(x, f.position.y + (row + 1) * t), n)
			n += 1
	for row in range(1, Room.ROWS):
		for col in Room.COLS:
			var y := f.position.y + row * t
			_grout_stroke(Vector2(f.position.x + col * t, y), Vector2(f.position.x + (col + 1) * t, y), n)
			n += 1
	# A few cracked tiles.
	for i in 9:
		var cell := Vector2i(int(Toon.hash01(seed_value + i, 11) * Room.COLS),
				int(Toon.hash01(seed_value + i, 12) * Room.ROWS))
		var c := f.position + (Vector2(cell) + Vector2(0.5, 0.5)) * t
		var a := Toon.hash01(seed_value + i, 13) * TAU
		var p0 := c + Vector2(cos(a), sin(a)) * t * 0.3
		var p1 := c + Vector2(cos(a + 2.6), sin(a + 2.6)) * t * 0.08
		var p2 := p1 + Vector2(cos(a + 0.9), sin(a + 0.9)) * t * 0.22
		Toon.stroke(self, PackedVector2Array([p0, p1, p2]), 2.2, Room.GROUT)


func _grout_stroke(a: Vector2, b: Vector2, n: int) -> void:
	var gap := 5.0 + Toon.hash01(seed_value, n) * 6.0
	var dir := (b - a).normalized()
	Toon.hand_line(self, a + dir * gap, b - dir * gap, 2.6, seed_value * 7 + n, Room.GROUT, 1.8)


## Rows of bricks running along a wall face, with the joints staggered row
## to row. Rows follow the face's own perspective, so they converge into the
## corners.
func _bricks(quad: Array, side: String) -> void:
	var rows := 4 if side == "top" or side == "bottom" else 5
	var length: float = (quad[3] as Vector2).distance_to(quad[2])
	var brick_u := 88.0 / length
	var n := 0
	for r in range(1, rows):
		var v := float(r) / rows
		Toon.hand_line(self, Room.face_point(quad, 0.0, v), Room.face_point(quad, 1.0, v),
				2.4, seed_value * 13 + r + side.length() * 50, BRICK, 1.2)
	for r in rows:
		var v0 := float(r) / rows
		var v1 := float(r + 1) / rows
		var u := brick_u * (0.5 if r % 2 == 0 else 1.0)
		while u < 1.0 - brick_u * 0.3:
			var wobble := (Toon.hash01(seed_value + n, r + side.length()) - 0.5) * brick_u * 0.3
			Toon.hand_line(self, Room.face_point(quad, u + wobble, v0 + 0.03),
					Room.face_point(quad, u + wobble, v1 - 0.03), 2.2, seed_value + n * 3, BRICK, 0.6)
			u += brick_u
			n += 1


func _outlines() -> void:
	var o := Room.RIM
	var f := Room.FLOOR
	var rim := [o.position, Vector2(o.end.x, o.position.y), o.end, Vector2(o.position.x, o.end.y)]
	var inner := [f.position, Vector2(f.end.x, f.position.y), f.end, Vector2(f.position.x, f.end.y)]
	for i in 4:
		Toon.hand_line(self, rim[i], rim[(i + 1) % 4], 6.0, seed_value + 200 + i)
		Toon.hand_line(self, inner[i], inner[(i + 1) % 4], 5.0, seed_value + 210 + i)
		Toon.hand_line(self, rim[i], inner[i], 5.0, seed_value + 220 + i)


## A door: an arched opening in a stone frame, dark when open and filled with
## a plank door when shut. Drawn in the face's own (u, v) coordinates, so a
## door in a side wall is foreshortened the way the wall is.
func _door(quad: Array, side: String, open: bool, beyond: String) -> void:
	var length: float = (quad[3] as Vector2).distance_to(quad[2])
	var half := DOOR_WIDTH * 0.5 / length
	var frame := _arch(quad, half * 1.32, 0.12, 0.34)
	draw_colored_polygon(Toon.grown(frame, 5.0), Toon.INK)
	draw_colored_polygon(frame, FRAMES.get(beyond, FRAME))
	if beyond == "boss":
		# Horns on the boss's door.
		for u: float in [0.5 - half * 1.25, 0.5 + half * 1.25]:
			var root := Room.face_point(quad, u, 0.2)
			var tip := Room.face_point(quad, u + (u - 0.5) * 0.35, 0.02)
			Toon.shape(self, PackedVector2Array([root + (tip - root).orthogonal().normalized() * 9.0,
					tip, root - (tip - root).orthogonal().normalized() * 9.0]), Color("e8dcc4"), 4.0)
	elif beyond == "treasure":
		Toon.star(self, Room.face_point(quad, 0.5, 0.14), 12.0, 0.0, Color("fff1a8"))
	var hole := _arch(quad, half, 0.26, 0.44)
	draw_colored_polygon(Toon.grown(hole, 3.0), Toon.INK)
	if open:
		draw_colored_polygon(hole, Color("5a1a14") if beyond == "boss" else Color("24160f"))
		return
	draw_colored_polygon(hole, DOOR_WOOD)
	# Planks: lines along the door's height.
	for i in range(1, 4):
		var u := 0.5 - half + half * 2.0 * i / 4.0
		Toon.hand_line(self, Room.face_point(quad, u, 0.36), Room.face_point(quad, u, 0.98),
				2.4, seed_value + i * 31 + side.length(), DOOR_PLANK, 0.5)
	# An iron band across it.
	Toon.hand_line(self, Room.face_point(quad, 0.5 - half * 0.95, 0.72),
			Room.face_point(quad, 0.5 + half * 0.95, 0.72), 6.0, seed_value + 77 + side.length(),
			Color("3a302a"), 0.4)


## The outline of an arch in a face: straight jambs from the floor edge up to
## [param spring], then a half circle up to [param top].
func _arch(quad: Array, half: float, top: float, spring: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(Room.face_point(quad, 0.5 - half, 1.0))
	var n := 16
	for i in n + 1:
		var a := PI + PI * i / n
		points.append(Room.face_point(quad, 0.5 + cos(a) * half, spring + sin(a) * (spring - top)))
	points.append(Room.face_point(quad, 0.5 + half, 1.0))
	return points
