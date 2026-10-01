class_name RoomLines
extends Node2D
## The ink of a room, over its painted walls and floor: a few cracks, the
## outlines of the box, and the four doors. It is a background, so it holds still --
## only characters boil.

const DOOR_WIDTH := 150.0
const FRAME := Color("c9b08a")
## Frames of doors to special rooms: the boss's is iron with a red glow
## beyond, the treasure room's gold.
const FRAMES := {"boss": Color("6a5a54"), "treasure": Color("e8c050")}
const DOOR_WOOD := Color("7a4a2a")
const IRON := Color("3a302a")
const STONE := preload("res://textures/stone_wall_004.png")
const DOOR_PLANK := Color(0.2, 0.1, 0.05, 0.8)

var room: Room
var seed_value := 0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	var quads := room.faces()
	_cracks()
	_outlines()
	for side: String in room.doors:
		_door(quads[side], side, bool(room.open_doors.get(side, false)), str(room.doors[side]))
	for side: String in room.hidden_doors:
		_cracked(quads[side], side)


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


## A door: an arched opening in a frame of dressed stones -- a keystone at
## the top, voussoirs round the arch, quoins down the jambs -- dark when open
## with the light of the room beyond on its floor, and filled with a plank
## door when shut. Drawn in the face's own (u, v) coordinates, so a door in
## a side wall is foreshortened the way the wall is.
func _door(quad: Array, side: String, open: bool, beyond: String) -> void:
	var length: float = (quad[3] as Vector2).distance_to(quad[2])
	var half := DOOR_WIDTH * 0.5 / length
	var stone: Color = FRAMES.get(beyond, room.palette().get("cap", FRAME))
	var outer := [half * 1.36, 0.1, 0.34]
	var inner := [half, 0.26, 0.44]
	# The whole frame in ink first: the stones are drawn over it with a gap
	# between, which leaves the joints dark.
	draw_colored_polygon(Toon.grown(_arch(quad, outer[0], outer[1], outer[2]), 5.0), Toon.INK)
	var stones := 7
	for i in stones:
		var a0 := PI + PI * i / stones
		var a1 := PI + PI * (i + 1) / stones
		var key := i == stones / 2
		var lift := 0.06 if key else 0.0
		_stone(_voussoir(quad, outer, inner, a0, a1, lift), stone.lightened(0.08 if key else 0.0), i + side.length() * 10)
	for jamb: float in [-1.0, 1.0]:
		var courses: Array = [[inner[2], 0.66], [0.66, 1.0]]
		for c in courses.size():
			var v0: float = courses[c][0]
			var v1: float = courses[c][1]
			# Quoins: every other one juts out further.
			var out: float = outer[0] * (1.0 if c % 2 == 0 else 0.9)
			var points := PackedVector2Array()
			for corner: Vector2 in [Vector2(inner[0], v0), Vector2(out, v0), Vector2(out, v1), Vector2(inner[0], v1)]:
				points.append(Room.face_point(quad, 0.5 + jamb * corner.x, corner.y))
			_stone(points, stone.darkened(0.06 * c), 20 + c + int(jamb) + side.length() * 10)
	if beyond == "boss":
		# Horns on the boss's door, and a skull for a keystone.
		for u: float in [0.5 - half * 1.3, 0.5 + half * 1.3]:
			var root := Room.face_point(quad, u, 0.2)
			var tip := Room.face_point(quad, u + (u - 0.5) * 0.35, 0.0)
			Toon.shape(self, PackedVector2Array([root + (tip - root).orthogonal().normalized() * 10.0,
					tip, root - (tip - root).orthogonal().normalized() * 10.0]), Color("e8dcc4"), 4.0)
		var skull := Room.face_point(quad, 0.5, 0.12)
		Toon.ball(self, skull, Vector2(14, 12), Color("e9dfc8"), 0, 3, 3.0)
		Toon.spot(self, skull + Vector2(-5, 0), Vector2(3.5, 4), Toon.INK)
		Toon.spot(self, skull + Vector2(5, 0), Vector2(3.5, 4), Toon.INK)
	elif beyond == "treasure":
		Toon.star(self, Room.face_point(quad, 0.5, 0.1), 13.0, 0.0, Color("fff1a8"))
	var hole := _arch(quad, inner[0], inner[1], inner[2])
	draw_colored_polygon(Toon.grown(hole, 3.0), Toon.INK)
	if open:
		_doorway(quad, hole, beyond)
		return
	_shut(quad, hole, half, side)


## A wall with something behind it: a web of cracks where a door would be,
## a stone or two pushed out, a little rubble at its foot. Easy to miss.
func _cracked(quad: Array, side: String) -> void:
	var ink := Color(Toon.INK, 0.85)
	var seed := seed_value + side.length() * 31
	var middle := Room.face_point(quad, 0.5, 0.58)
	for k in 6:
		var a := TAU * (k + Toon.hash01(seed, k) * 0.6) / 6.0
		var points := PackedVector2Array([middle])
		var at := middle
		for step in 4:
			var bend := a + (Toon.hash01(seed + k, step) - 0.5) * 1.1
			at += Vector2(cos(bend), sin(bend) * 0.7) * (9.0 + Toon.hash01(seed + k, step + 9) * 8.0)
			points.append(at)
		Toon.stroke(self, points, 2.6 - k * 0.2, ink)
	# A stone pushed half out of the wall.
	var loose := Room.face_point(quad, 0.5 + (Toon.hash01(seed, 40) - 0.5) * 0.04, 0.45)
	Toon.box(self, loose, Vector2(16, 9), room.palette().get("cap", FRAME), 0, seed, 3.0)
	# Rubble at the foot of the wall.
	for k in 4:
		var foot := Room.face_point(quad, 0.47 + k * 0.02, 0.97)
		Toon.ball(self, foot, Vector2(5, 4) * (0.7 + Toon.hash01(seed, 50 + k) * 0.6),
				room.palette().get("cap", FRAME), 0, seed + k, 2.0)


## One stone of the frame, painted with stone and edged: the light catches
## its top, and its underside is in shade.
func _stone(points: PackedVector2Array, tint: Color, seed: int) -> void:
	var inset := Toon.grown(points, -2.0)
	var uvs := PackedVector2Array()
	var offset := Vector2(Toon.hash01(seed, 1), Toon.hash01(seed, 2))
	for p in inset:
		uvs.append(p / 260.0 + offset)
	draw_polygon(inset, PackedColorArray([tint.lightened(0.15)]), uvs, STONE)
	var middle := Vector2.ZERO
	for p in inset:
		middle += p
	middle /= inset.size()
	Toon.glow(self, middle + Vector2(-4, -4), Vector2(14, 10), Color(1, 1, 0.95, 0.22), 1)


## The stone of the arch between angles [param a0] and [param a1], from the
## outer curve to the inner one. [param lift] raises its top: the keystone.
func _voussoir(quad: Array, outer: Array, inner: Array, a0: float, a1: float, lift: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 3
	for k in steps + 1:
		var a := lerpf(a0, a1, float(k) / steps)
		points.append(_arc_point(quad, outer, a, lift))
	for k in steps + 1:
		var a := lerpf(a1, a0, float(k) / steps)
		points.append(_arc_point(quad, inner, a, 0.0))
	return points


func _arc_point(quad: Array, arch: Array, a: float, lift: float) -> Vector2:
	var half: float = arch[0]
	var top: float = arch[1] - lift
	var spring: float = arch[2]
	return Room.face_point(quad, 0.5 + cos(a) * half, spring + sin(a) * (spring - top))


## An open doorway: dark, and on its floor the light of the room beyond --
## warm, or red for the boss's, gold for the treasure room's.
func _doorway(quad: Array, hole: PackedVector2Array, beyond: String) -> void:
	draw_colored_polygon(hole, Color("0e0806"))
	var glow: Color = {"boss": Color(0.9, 0.2, 0.1, 0.55), "treasure": Color(1.0, 0.85, 0.35, 0.5)}.get(beyond,
			Color(1.0, 0.85, 0.6, 0.28))
	var foot := Room.face_point(quad, 0.5, 0.94)
	var across := Room.face_point(quad, 0.62, 0.94).distance_to(Room.face_point(quad, 0.38, 0.94))
	var clipped := func(center: Vector2, radii: Vector2, color: Color) -> void:
		var disc := Toon.ellipse_points(center, radii, 0, 0, 0.0, 0.0, 0.0)
		for piece in Geometry2D.intersect_polygons(disc, hole):
			Toon.polygon(self, piece, color)
	foot = Room.face_point(quad, 0.5, 1.0)
	clipped.call(foot, Vector2(across * 0.62, across * 0.2), Color(glow, glow.a * 0.45))
	clipped.call(foot, Vector2(across * 0.4, across * 0.11), glow)
	# The top of the opening is in deep shadow.
	clipped.call(Room.face_point(quad, 0.5, 0.3), Vector2(across * 0.6, across * 0.35), Color(0, 0, 0, 0.5))


## A shut door: planks of a slightly different brown each, with grain,
## iron straps, studs and a ring for a handle -- and a padlock if locked.
func _shut(quad: Array, hole: PackedVector2Array, half: float, side: String) -> void:
	draw_colored_polygon(hole, DOOR_WOOD)
	var planks := 4
	for i in planks:
		var u0 := 0.5 - half + half * 2.0 * i / planks
		var u1 := 0.5 - half + half * 2.0 * (i + 1) / planks
		var band := PackedVector2Array([Room.face_point(quad, u0, 0.0), Room.face_point(quad, u1, 0.0),
				Room.face_point(quad, u1, 1.0), Room.face_point(quad, u0, 1.0)])
		var tone := DOOR_WOOD.lightened(0.12) if i % 2 == 0 else DOOR_WOOD.darkened(0.08)
		tone = tone.lerp(Color("8a5a36"), Toon.hash01(seed_value + i, 5) * 0.3)
		for piece in Geometry2D.intersect_polygons(band, hole):
			Toon.polygon(self, piece, tone)
		# Grain: long wavy lines down the plank.
		for g in 2:
			var u := lerpf(u0, u1, 0.3 + g * 0.4)
			var a := Room.face_point(quad, u, 0.4)
			var b := Room.face_point(quad, u + (Toon.hash01(seed_value + i, g) - 0.5) * half * 0.1, 0.96)
			Toon.hand_line(self, a, b, 1.4, seed_value + i * 5 + g, Color(0.25, 0.12, 0.05, 0.45), 1.5)
		if i > 0:
			Toon.hand_line(self, Room.face_point(quad, u0, 0.34), Room.face_point(quad, u0, 0.98),
					2.4, seed_value + i * 31 + side.length(), DOOR_PLANK, 0.5)
	# The arch's shadow on the top of the door.
	var shade := Toon.ellipse_points(Room.face_point(quad, 0.5, 0.3),
			Vector2(DOOR_WIDTH * 0.6, 30.0), 0, 0, 0.0, 0.0, 0.0)
	for piece in Geometry2D.intersect_polygons(shade, hole):
		Toon.polygon(self, piece, Color(0, 0, 0, 0.3))
	for v: float in [0.52, 0.86]:
		Toon.hand_line(self, Room.face_point(quad, 0.5 - half * 0.95, v), Room.face_point(quad, 0.5 + half * 0.25, v),
				6.0, seed_value + int(v * 100) + side.length(), IRON, 0.3)
		for u: float in [-0.75, -0.4, -0.05]:
			draw_circle(Room.face_point(quad, 0.5 + half * u, v), 3.0, Color("c9b08a"))
			draw_circle(Room.face_point(quad, 0.5 + half * u, v) + Vector2(-0.8, -0.8), 1.2, Color(1, 1, 1, 0.6))
	var ring := Room.face_point(quad, 0.5 + half * 0.55, 0.66)
	draw_circle(ring, 4.0, IRON)
	draw_arc(ring + Vector2(0, 7), 8.0, 0.0, TAU, 18, IRON, 3.5, true)
	draw_arc(ring + Vector2(-1, 6), 8.0, PI * 1.1, PI * 1.6, 6, Color(1, 1, 1, 0.35), 1.5, true)
	if room.locked.has(side):
		# A padlock on it: a key opens it.
		var lock := Room.face_point(quad, 0.5, 0.66)
		var shackle := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			shackle.append(lock + Vector2(cos(a) * 11.0, -8.0 + sin(a) * 13.0))
		Toon.stroke(self, shackle, 5.0)
		Toon.stroke(self, shackle, 2.0, Color("c9c6c0"))
		Toon.box(self, lock + Vector2(0, 6), Vector2(16, 13), ItemIcon.GOLD, 0, 90, 4.0)
		Toon.spot(self, lock + Vector2(0, 5), Vector2(3, 4), Toon.INK)
		Toon.spot(self, lock + Vector2(-6, 0), Vector2(3, 5), Color(1, 1, 1, 0.45))


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
