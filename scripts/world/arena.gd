class_name Arena
extends Node2D
## A boss's own room, dressed for him, over the plain room it is built on:
##   "ring"     Bruno's underground boxing ring: a canvas mat, ropes and
##              corner posts, posters on the walls, a lamp, and a crowd of
##              eyes in the dark along the sides
##   "boiler"   the heart of the boiler room, Пыхтун's: iron plate floor,
##              copper pipes with gauges whose needles twitch, coal heaped
##              in the corners, a red glow -- and steam vents in the floor
##   "cabaret"  the Baron's cabaret, the Golden Claw: red carpet, velvet
##              curtains, footlights, a chandelier and spotlights roaming
## Drawn under the actors; the boiler room's vents are hazards of their own.

## Floor and wall colours for each, over the floor's usual ones.
const PALETTES := {
	"ring": {"wall": Color("7e4a3a"), "wall_stain": Color("4e2b21"), "mortar": Color("2e1a14"),
			"cap": Color("a67c68"), "floor": Color("e2e0d4"), "floor_stain": Color("a3aab0"),
			"joint": Color("3a3a3a"), "grout": Color(0, 0, 0, 0), "floor_pattern": 3,
			"wall_pattern": 0, "ambient": 0.68},
	"boiler": {"wall": Color("5e6672"), "wall_stain": Color("353b44"), "mortar": Color("1e2228"),
			"cap": Color("8a9098"), "floor": Color("9a9ca4"), "floor_stain": Color("5e6068"),
			"joint": Color("26282c"), "grout": Color(0, 0, 0, 0), "floor_pattern": 4,
			"wall_pattern": 1, "ambient": 0.72},
	"cabaret": {"wall": Color("8e2328"), "wall_stain": Color("5c1519"), "mortar": Color("2e0a0c"),
			"cap": Color("c9a050"), "floor": Color("a8282c"), "floor_stain": Color("6e1519"),
			"joint": Color("2e0a0c"), "trim": Color("e8b83a"), "grout": Color(0, 0, 0, 0),
			"floor_pattern": 5, "wall_pattern": 3, "ambient": 0.72},
}
const GOLD := Color("e8b83a")

var kind := "ring"
var room: Room

var _clock := 0.0


func _ready() -> void:
	if kind == "boiler":
		for cell: Vector2i in [Vector2i(3, 2), Vector2i(9, 2), Vector2i(3, 4), Vector2i(9, 4)]:
			var vent := SteamVent.new()
			vent.room = room
			vent.delay = 2.5 + cell.x * 0.35 + cell.y * 0.6
			add_child(vent)
			vent.global_position = room.tile_center(cell)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		"ring":
			_ring()
		"boiler":
			_boiler()
		"cabaret":
			_cabaret()


# --- the ring ----------------------------------------------------------------


func _ring() -> void:
	var f := Room.FLOOR
	var d := int(_clock * Toon.FPS)
	# The crowd: eyes in the dark along the side walls, blinking now and then.
	for side: float in [-1.0, 1.0]:
		# Down to where the posters hang.
		for k in 5:
			var x := (70.0 + (k % 2) * 60.0) if side < 0.0 else (1920.0 - 70.0 - (k % 2) * 60.0)
			var y := 250.0 + k * 100.0
			Toon.spot(self, Vector2(x, y), Vector2(26, 22), Color(0.08, 0.05, 0.04, 0.85))
			if Toon.hash01(d / 4 + k, int(side)) > 0.1:
				for e: float in [-7.0, 7.0]:
					Toon.spot(self, Vector2(x + e, y - 4), Vector2(4, 6), BrotherLook.WHITE)
	# Posters on the back wall.
	for i in 2:
		var at := Vector2(560 + i * 800, 84)
		Toon.box(self, at, Vector2(120, 44), Color("e9d6ac"), 0, 40 + i, 4.0, (i - 0.5) * 0.08)
		var text := "БРУНО" if i == 0 else "ЧЕМПИОН"
		draw_string(Ui.font(), at + Vector2(-110, 12), text, HORIZONTAL_ALIGNMENT_CENTER, 220, 34 if text.length() > 5 else 40, Color("b8322a"))
	var mat := f.grow(-18.0)
	# The ring's emblem painted on the mat: a laurel round a big Б.
	var emblem := f.get_center() + Vector2(0, 20)
	draw_arc(emblem, 150.0, 0.0, TAU, 64, Color(0.55, 0.12, 0.1, 0.35), 10.0, true)
	draw_arc(emblem, 128.0, 0.0, TAU, 64, Color(0.55, 0.12, 0.1, 0.25), 3.0, true)
	for side: float in [-1.0, 1.0]:
		for k in 7:
			var a := PI * 0.5 + side * (0.5 + k * 0.28)
			var at := emblem + Vector2(cos(a), sin(a)) * 108.0
			Toon.spot(self, at, Vector2(12, 5), Color(0.55, 0.12, 0.1, 0.3), 0, k, a + side * 0.9)
	draw_string(Ui.font(), emblem + Vector2(-60, 44), "Б", HORIZONTAL_ALIGNMENT_CENTER, 120, 130,
			Color(0.55, 0.12, 0.1, 0.35))
	# Ropes: red, white, blue, round the mat, with a post in each corner.
	var corners := [mat.position, Vector2(mat.end.x, mat.position.y), mat.end, Vector2(mat.position.x, mat.end.y)]
	var colors := [Color("c8392b"), BrotherLook.WHITE, Color("3f6fb5")]
	for r in 3:
		var lift := Vector2(0, -12.0 - r * 16.0)
		for i in 4:
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % 4]
			var sag := 6.0 if i % 2 == 0 else 3.0
			Toon.stroke(self, Toon.bent(a + lift, b + lift, -sag), 9.0)
			Toon.stroke(self, Toon.bent(a + lift, b + lift, -sag), 5.0, colors[r])
	for c: Vector2 in corners:
		Toon.box(self, c + Vector2(0, -28), Vector2(12, 34), Color("d9d4cc"), 0, 50, 4.0)
		Toon.box(self, c + Vector2(0, -60), Vector2(14, 8), Color("c8392b"), 0, 51, 3.5)


# --- the boiler room -----------------------------------------------------------


func _boiler() -> void:
	var f := Room.FLOOR
	var d := int(_clock * Toon.FPS)
	# Pipes along the back wall, with a gauge and a valve wheel on each.
	for p in 2:
		var y := 58.0 + p * 44.0
		Toon.stroke(self, PackedVector2Array([Vector2(120, y), Vector2(1800, y)]), 22.0)
		Toon.stroke(self, PackedVector2Array([Vector2(120, y), Vector2(1800, y)]), 15.0, Color("b86f3c"))
		Toon.stroke(self, PackedVector2Array([Vector2(120, y - 3), Vector2(1800, y - 3)]), 3.0, Color(1, 1, 1, 0.35))
		for k in 3:
			var x := 380.0 + k * 580.0 + p * 150.0
			Toon.box(self, Vector2(x, y), Vector2(10, 16), Color("8a5230"), 0, 60 + k, 3.0)
	for k in 4:
		var at := Vector2(300 + k * 440, 60)
		Toon.blob(self, at, Vector2(24, 24), BrotherLook.WHITE, 0, 70 + k, 5.0)
		var needle := -0.8 + 1.6 * Toon.hash01(d / 2 + k * 7, k)
		Toon.stroke(self, PackedVector2Array([at, at + Vector2(sin(needle), -cos(needle)) * 18.0]), 3.0, Color("b8322a"))
		Toon.spot(self, at, Vector2(3, 3), Toon.INK)
	for k in 2:
		var at := Vector2(620 + k * 680, 104)
		var wheel := PackedVector2Array()
		for i in 21:
			var a := TAU * i / 20.0
			wheel.append(at + Vector2(cos(a), sin(a)) * 18.0)
		Toon.stroke(self, wheel, 6.0, Color("b8322a"))
		for i in 3:
			var a := PI * i / 3.0 + d * 0.05
			Toon.stroke(self, PackedVector2Array([at - Vector2(cos(a), sin(a)) * 18.0, at + Vector2(cos(a), sin(a)) * 18.0]),
					4.0, Color("b8322a"))
	# Coal heaped against the walls in the corners.
	for c: Vector2 in [Vector2(f.position.x + 60, f.end.y - 30), Vector2(f.end.x - 60, f.end.y - 30)]:
		for i in 7:
			var at := c + Vector2((i % 4 - 1.5) * 26.0, -(i / 4) * 22.0)
			Toon.blob(self, at, Vector2(18, 14), StoveBoss.IRON.darkened(0.4), 0, 80 + i, 3.5, i * 0.7)


# --- the cabaret -----------------------------------------------------------------


func _cabaret() -> void:
	var f := Room.FLOOR
	var d := int(_clock * Toon.FPS)
	# Velvet curtains along the back wall, with a scalloped valance.
	for k in 22:
		var x := 40.0 + k * 84.0
		Toon.stroke(self, Toon.bent(Vector2(x, 30), Vector2(x + 6, 146), 6.0), 5.0, Color("4a0e12"))
	for k in 12:
		var x := 40.0 + k * 160.0
		var swag := PackedVector2Array()
		for i in 9:
			var u := i / 8.0
			swag.append(Vector2(x + u * 160.0, 26 + sin(u * PI) * 30.0))
		Toon.stroke(self, swag, 8.0)
		Toon.stroke(self, swag, 4.0, GOLD)
		Toon.blob(self, Vector2(x, 34), Vector2(6, 10), GOLD, 0, 90 + k, 3.0)
	# Footlights along the front of the stage (the back wall), glowing.
	for k in 14:
		var at := Vector2(f.position.x + 40 + k * 106.0, f.position.y + 12)
		var lit := Toon.hash01(d / 3 + k, 3) > 0.12
		if lit:
			Toon.glow(self, at + Vector2(0, 16), Vector2(70, 34), Color(1, 0.9, 0.5, 0.35))
		Toon.blob(self, at, Vector2(9, 9), Color("fff1a8") if lit else Color("8a7a5a"), 0, 100 + k, 3.0)
	# Spotlights roaming over the floor.
	for i in 2:
		var t := _clock * 0.35 + i * PI
		var at := f.get_center() + Vector2(cos(t) * f.size.x * 0.33, sin(t * 1.3) * f.size.y * 0.3)
		Toon.glow(self, at, Vector2(230, 110), Color(1, 0.96, 0.8, 0.3))
	# The chandelier's shadow, cast on the carpet from above.
	var c := f.get_center() + Vector2(0, -40)
	for k in 8:
		var a := TAU * k / 8.0 + 0.2
		Toon.spot(self, c + Vector2(cos(a) * 90, sin(a) * 34), Vector2(14, 7), Color(0, 0, 0, 0.15))
	Toon.spot(self, c, Vector2(40, 16), Color(0, 0, 0, 0.18))


## A steam vent in the boiler room's floor: quiet for a while, then a hiss
## and wisps -- the warning -- then a column of steam that scalds anyone on
## it.
class SteamVent:
	extends Node2D

	const REACH := 52.0
	var room: Room
	var delay := 3.0
	var _clock := 0.0
	## Seconds into the current cycle.
	var _t := 0.0
	## The boss is beaten: the boilers are let down and the vent is quiet.
	var _quiet := false

	func _ready() -> void:
		add_to_group("hazard")

	func quench() -> void:
		_quiet = true

	func _physics_process(delta: float) -> void:
		_clock += delta
		if _quiet:
			return
		if _clock < delay:
			return
		_t += delta
		var burst := _t > 1.0 and _t < 2.2
		if burst:
			for brother in room.brothers:
				if not brother.dead and brother.global_position.distance_to(global_position) < REACH:
					brother.hurt(1, global_position + Vector2(0, -10), "горячий пар")
		if _t > 1.0 and _t - delta <= 1.0:
			Sfx.play("fuse", -2.0, 0.2)
		if _t > 5.5:
			_t = 0.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var d := int(_clock * Toon.FPS)
		Toon.box(self, Vector2.ZERO, Vector2(36, 20), Color("3a3836"), 0, 3, 4.0)
		for k in 4:
			Toon.stroke(self, PackedVector2Array([Vector2(-24 + k * 16, -12), Vector2(-24 + k * 16, 12)]), 3.0)
		if _clock < delay or _quiet:
			return
		if _t < 1.0:
			# The hiss: a few wisps.
			for k in 2:
				var rise := fmod(_t * 2.0 + k * 0.5, 1.0)
				Toon.spot(self, Vector2((k - 0.5) * 16.0, -10 - rise * 30.0), Vector2(8, 7) * (0.5 + rise),
						Color(1, 1, 1, 0.6 * (1.0 - rise)))
		elif _t < 2.2:
			# The column.
			for k in 7:
				var up := float(k) * 34.0 + (d % 2) * 8.0
				Toon.spot(self, Vector2(sin(k * 1.7 + d) * 6.0, -up), Vector2(30 + k * 5, 22), Color(0.97, 0.96, 0.93, 0.8 - k * 0.08))
