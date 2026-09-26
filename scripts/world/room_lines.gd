class_name RoomLines
extends Node2D
## The ink of a room, over its painted walls and floor: a few cracks, the
## outlines of the box, and the four doors. It is a background, so it holds still --
## only characters boil.

const DOOR_WIDTH := 150.0
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
	_cracks()
	_outlines()
	for side: String in room.doors:
		_door(quads[side], side, bool(room.open_doors.get(side, false)), str(room.doors[side]))


## A few cracked stones, drawn in ink over the painted floor: a jagged
## line wandering across the stone, with a short branch off it.
func _cracks() -> void:
	var ink: Color = room.palette()["grout"]
	if ink.a <= 0.0:
		return
	var f := Room.FLOOR
	var t := Room.TILE
	for i in 5:
		var cell := Vector2i(int(Toon.hash01(seed_value + i, 11) * Room.COLS),
				int(Toon.hash01(seed_value + i, 12) * Room.ROWS))
		var c := f.position + (Vector2(cell) + Vector2(0.5, 0.5)) * t
		var a := Toon.hash01(seed_value + i, 13) * TAU
		var dir := Vector2(cos(a), sin(a))
		var points := PackedVector2Array()
		for k in 6:
			var along := (k / 5.0 - 0.5) * t * 0.7
			var side := (Toon.hash01(seed_value + i * 7 + k, 14) - 0.5) * 14.0
			points.append(c + dir * along + dir.orthogonal() * side)
		Toon.stroke(self, points, 2.0, ink)
		var fork := points[2]
		var b := a + (0.7 if Toon.hash01(seed_value + i, 15) > 0.5 else -0.7)
		Toon.stroke(self, PackedVector2Array([fork, fork + Vector2(cos(b), sin(b)) * 12.0,
				fork + Vector2(cos(b + 0.3), sin(b + 0.3)) * 22.0]), 1.4, ink)


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
	# Iron hinge straps across the planks, studs, and a ring for a handle.
	for v: float in [0.5, 0.86]:
		Toon.hand_line(self, Room.face_point(quad, 0.5 - half * 0.9, v), Room.face_point(quad, 0.5 + half * 0.2, v),
				5.0, seed_value + int(v * 100) + side.length(), Color("3a302a"), 0.3)
		for u: float in [-0.7, -0.35, 0.0]:
			draw_circle(Room.face_point(quad, 0.5 + half * u, v), 2.6, Color("c9b08a"))
	var ring := Room.face_point(quad, 0.5 + half * 0.55, 0.64)
	draw_arc(ring + Vector2(0, 6), 7.0, 0.0, TAU, 16, Color("3a302a"), 3.0, true)
	draw_circle(ring, 3.0, Color("3a302a"))
	if room.locked.has(side):
		# A padlock on it: a key opens it.
		var lock := Room.face_point(quad, 0.5, 0.66)
		var shackle := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			shackle.append(lock + Vector2(cos(a) * 11.0, -8.0 + sin(a) * 13.0))
		Toon.stroke(self, shackle, 5.0)
		Toon.box(self, lock + Vector2(0, 6), Vector2(16, 13), ItemIcon.GOLD, 0, 90, 4.0)
		Toon.spot(self, lock + Vector2(0, 5), Vector2(3, 4), Toon.INK)
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
