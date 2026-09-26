class_name RoomDecor
extends Node2D
## The lived-in bits of an ordinary room, over its painted walls and floor
## and under everyone: lamps on the back wall and the light they throw,
## cracks and cobwebs, and the clutter of each floor --
##   0 basement:  a barred window and its shaft of daylight, puddles, straw,
##                barrels and crates against the walls, a mouse hole
##   1 boiler:    caged bulbs, gauges, copper pipes down the side walls, a
##                leaking joint, oil, a drain grate, coal
##   2 catacombs: niches with skulls, chains, moss, candles, bones
## Laid out by the room's seed, so a room looks the same every visit. The
## flames, needles and dust move; the rest holds still.
##
## Nothing here stands on open floor where a brother could walk through it:
## furniture leans on the walls, and what lies on the floor lies flat.

const WOOD := Color("8a5a36")
const WOOD_DARK := Color("5e3a20")
const IRON := Color("3a302a")
const COPPER := Color("c07a44")
const BONE := Color("e9dfc8")
const WATER := Color(0.3, 0.38, 0.45, 0.42)

var room: Room
var seed_value := 0
var style := 0

var _clock := 0.0
var _drawing := -1


func _process(delta: float) -> void:
	_clock += delta
	var d := int(_clock * Toon.FPS)
	if d != _drawing:
		_drawing = d
		queue_redraw()


func _h(k: int) -> float:
	return Toon.hash01(seed_value, k)


## A place along a side wall's foot that is clear of its door, and low
## enough not to hide under the cards of the interface in the top corners.
func _beside_door(k: int) -> float:
	var f := Room.FLOOR
	return f.end.y - 60.0 - _h(k + 1) * 200.0


func _draw() -> void:
	_wall_marks()
	match style:
		0:
			_basement()
		1:
			_boiler()
		_:
			_catacombs()
	_lamps()


## Cracks and damp on the walls, and cobwebs in the two back corners.
func _wall_marks() -> void:
	for i in 4:
		var x := 300.0 + _h(i) * 1320.0
		if absf(x - 960.0) < 130.0:
			x += 280.0
		var a := Vector2(x, 50.0 + _h(i + 10) * 50.0)
		var b := a + Vector2(_h(i + 20) * 30.0 - 15.0, 24.0)
		var c := b + Vector2(_h(i + 30) * 30.0 - 15.0, 20.0)
		var e := b + Vector2(_h(i + 35) * 20.0 - 10.0, 14.0)
		Toon.stroke(self, PackedVector2Array([a, b, c]), 2.4, Color(0, 0, 0, 0.4))
		Toon.stroke(self, PackedVector2Array([b, e]), 1.6, Color(0, 0, 0, 0.35))
	for i in 2:
		var at := Vector2(320.0 + _h(i + 40) * 1280.0, 70.0 + _h(i + 50) * 50.0)
		Toon.glow(self, at, Vector2(70, 40) * (0.7 + _h(i + 60) * 0.6), Color(0, 0, 0, 0.18))
	for side: float in [-1.0, 1.0]:
		var corner := Vector2(Room.FLOOR.position.x if side < 0.0 else Room.FLOOR.end.x, Room.FLOOR.position.y)
		var reach := 86.0 + _h(70 + int(side)) * 30.0
		for k in 5:
			var a := PI * 0.5 * k / 4.0
			var dir := Vector2(-side * cos(a), sin(a))
			draw_line(corner, corner + dir * reach, Color(1, 1, 1, 0.32), 1.4, true)
		for r in 4:
			var pts := PackedVector2Array()
			for k in 5:
				var a := PI * 0.5 * k / 4.0
				var dir := Vector2(-side * cos(a), sin(a))
				pts.append(corner + dir * (18.0 + r * 20.0))
				if k < 4:
					var b := PI * 0.5 * (k + 0.5) / 4.0
					pts.append(corner + Vector2(-side * cos(b), sin(b)) * (14.0 + r * 20.0))
			draw_polyline(pts, Color(1, 1, 1, 0.28), 1.3, true)


## Lamps on the back wall, flames flickering, each glowing on the wall round
## it. (The pools they throw on the floor are painted with the floor.)
func _lamps() -> void:
	var f := Room.FLOOR
	var d := _drawing
	for i in 2:
		var x := f.position.x + f.size.x * (0.22 + 0.56 * i)
		var wall := Vector2(x, 86)
		var flick: float = [1.0, 0.93, 1.05, 0.97][(d + i * 2) % 4]
		Toon.glow(self, wall + Vector2(0, -6), Vector2(96, 70) * flick, Color(1, 0.85, 0.45, 0.35))
		Toon.glow(self, Vector2(x, f.position.y + 30), Vector2(240, 80) * flick, Color(1, 0.85, 0.5, 0.12))
		match style:
			1:
				# A bulb in a wire cage, on a bracket.
				Toon.box(self, wall + Vector2(0, -26), Vector2(12, 6), Color("5a5550"), 0, 2, 3.0)
				Toon.glow(self, wall, Vector2(30, 30), Color(1, 0.95, 0.6, 0.6))
				Toon.blob(self, wall, Vector2(13, 16), Color("fff4b8"), 0, 1, 3.5)
				Toon.spot(self, wall + Vector2(-4, -5), Vector2(3, 6), Color(1, 1, 1, 0.8))
				for k in 3:
					Toon.stroke(self, Toon.bent(wall + Vector2(-8 + k * 8, -20), wall + Vector2(-8 + k * 8, 20),
							(k - 1) * 7.0), 2.2, IRON)
				Toon.stroke(self, PackedVector2Array([wall + Vector2(-16, 4), wall + Vector2(16, 4)]), 2.2, IRON)
			2:
				# A candle in a niche, wax run down its side.
				Toon.box(self, wall + Vector2(0, 2), Vector2(24, 30), Color(0.1, 0.08, 0.06), 0, 3, 4.0)
				Toon.box(self, wall + Vector2(0, 14), Vector2(7, 14), BrotherLook.WHITE, 0, 4, 2.5)
				Toon.spot(self, wall + Vector2(3, 10), Vector2(2, 6), Color("e9dfc8"))
				_flame(wall + Vector2(0, -1), 6.0, 17.0 * flick, d + i)
			_:
				# An oil lamp on an iron bracket, in a glass chimney.
				Toon.stroke(self, PackedVector2Array([wall + Vector2(-16, 30), wall + Vector2(0, 30),
						wall + Vector2(0, 20)]), 4.0, IRON)
				Toon.box(self, wall + Vector2(0, 20), Vector2(14, 6), Color("b8863a"), 0, 5, 3.0)
				Toon.ball(self, wall + Vector2(0, 12), Vector2(12, 8), Color("c99a48"), 0, 6, 3.0)
				_flame(wall + Vector2(0, 2), 7.0, 19.0 * flick, d + i)
				draw_arc(wall + Vector2(0, -2), 13.0, PI * 0.9, PI * 2.1, 16, Color(0, 0, 0, 0.55), 2.2, true)
				draw_line(wall + Vector2(-13, -2), wall + Vector2(-11, 10), Color(0, 0, 0, 0.55), 2.2, true)
				draw_line(wall + Vector2(13, -2), wall + Vector2(11, 10), Color(0, 0, 0, 0.55), 2.2, true)
				Toon.spot(self, wall + Vector2(-7, -6), Vector2(2, 6), Color(1, 1, 1, 0.7))


func _flame(base: Vector2, width: float, height: float, d: int) -> void:
	var lean: float = [1.0, -1.5, 2.0, -0.5][d % 4]
	var points := PackedVector2Array()
	for k in 12:
		var t := TAU * k / 12.0
		var y := -cos(t)
		var up := (1.0 - y) * 0.5
		points.append(base + Vector2(sin(t) * sin(t * 0.5) * width + lean * up * up * 3.0, -up * height + width * 0.3))
	Toon.glow(self, base + Vector2(0, -height * 0.3), Vector2(width * 3.2, height * 1.4), Color(1, 0.8, 0.35, 0.35))
	Toon.shape(self, points, StoveBoss.FIRE, 2.5)
	Toon.spot(self, base + Vector2(0, -height * 0.2), Vector2(width * 0.4, height * 0.25), StoveBoss.FIRE_CORE)


## A puddle lying on the floor: a few overlapping pools, a light rim on the
## side away from the lamps and a glint of reflected lamp.
func _puddle(at: Vector2, size: float, k: int, color := WATER) -> void:
	var parts: Array = []
	for i in 3:
		var off := Vector2(_h(k + i) - 0.5, (_h(k + i + 7) - 0.5) * 0.5) * size * 1.2
		parts.append([at + off, Vector2(size * (0.55 + _h(k + i + 3) * 0.3), size * (0.22 + _h(k + i + 5) * 0.1))])
	for part: Array in parts:
		Toon.spot(self, part[0] + Vector2(0, 2), (part[1] as Vector2) + Vector2(3, 3), Color(0, 0, 0, 0.1), 0, k)
	for part: Array in parts:
		Toon.spot(self, part[0], part[1], color, 0, k)
	var main: Array = parts[0]
	var c: Vector2 = main[0]
	var r: Vector2 = main[1]
	Toon.stroke(self, Toon.bent(c + Vector2(-r.x * 0.5, -r.y * 0.3), c + Vector2(-r.x * 0.1, -r.y * 0.5), -2.0),
			2.4, Color(1, 1, 1, 0.5))
	Toon.stroke(self, PackedVector2Array([c + Vector2(r.x * 0.05, -r.y * 0.45), c + Vector2(r.x * 0.15, -r.y * 0.48)]),
			2.4, Color(1, 1, 1, 0.5))


func _basement() -> void:
	var f := Room.FLOOR
	# A barred window high in the back wall, and the shaft of daylight it
	# lets in, dust turning in it.
	var window := Vector2(f.position.x + f.size.x * (0.35 + _h(300) * 0.3), 66)
	if absf(window.x - f.get_center().x) < 170.0:
		window.x += 300.0
	var top := [window + Vector2(-34, 22), window + Vector2(34, 22)]
	var foot := [window + Vector2(150, 600), window + Vector2(-20, 600)]
	draw_polygon(PackedVector2Array([top[0], top[1], foot[0], foot[1]]),
			PackedColorArray([Color(1, 0.97, 0.82, 0.2), Color(1, 0.97, 0.82, 0.2),
					Color(1, 0.97, 0.82, 0.0), Color(1, 0.97, 0.82, 0.0)]))
	Toon.glow(self, window + Vector2(80, 560), Vector2(120, 50), Color(1, 0.97, 0.82, 0.18))
	for k in 8:
		var t := fmod(_clock * 0.06 + _h(310 + k), 1.0)
		var mote := window + Vector2(-16 + _h(320 + k) * 60.0 + t * 110.0, 50 + t * 500.0)
		Toon.spot(self, mote, Vector2(2.2, 2.2), Color(1, 1, 0.9, 0.55 * sin(t * PI)))
	Toon.box(self, window, Vector2(48, 28), Color("f0e2bc"), 0, 12, 5.0)
	Toon.box(self, window, Vector2(38, 20), Color("9fb4c0"), 0, 11, 3.0)
	Toon.spot(self, window + Vector2(-14, -6), Vector2(12, 4), Color(1, 1, 1, 0.5))
	for k in 4:
		Toon.stroke(self, PackedVector2Array([window + Vector2(-27 + k * 18, -22), window + Vector2(-27 + k * 18, 22)]), 4.5)
	# A mouse hole in the foot of the back wall, and someone at home.
	var hole := Vector2(f.position.x + f.size.x * (0.1 + _h(330) * 0.25), f.position.y)
	var arch := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		arch.append(hole + Vector2(cos(a) * 20.0, sin(a) * 22.0))
	Toon.shape(self, arch, Color("140c08"), 3.0)
	if Toon.hash01(_drawing / 6, 5) > 0.18:
		for e: float in [-5.0, 5.0]:
			Toon.spot(self, hole + Vector2(e, -9), Vector2(2.4, 3.2), BrotherLook.WHITE)
	# Puddles.
	for i in 2:
		var at := f.position + Vector2(160 + _h(70 + i) * (f.size.x - 320), 120 + _h(80 + i) * (f.size.y - 240))
		_puddle(at, 50.0 + _h(90 + i) * 30.0, 400 + i * 20)
	# Straw in tufts along the foot of the walls.
	for i in 4:
		var base := Vector2(f.position.x + 30 + _h(100 + i) * (f.size.x - 60), f.end.y - 16) if i % 2 == 0 \
				else Vector2(f.position.x + 14 if i == 1 else f.end.x - 14, _beside_door(104 + i))
		for k in 7:
			var a := -PI * 0.5 + (k - 3) * 0.32 + (_h(110 + i * 7 + k) - 0.5) * 0.3
			var l := 18.0 + _h(130 + i * 7 + k) * 16.0
			Toon.stroke(self, Toon.bent(base, base + Vector2(cos(a), sin(a) * 0.6) * l, 3.0), 3.0, Color("b89238"))
			Toon.stroke(self, Toon.bent(base, base + Vector2(cos(a), sin(a) * 0.6) * l * 0.9, 3.0), 1.4, Color("e8c860"))
	# A barrel against one side wall, crates against the other.
	var left := _h(150) < 0.5
	var barrel := Vector2(f.position.x - 20 if left else f.end.x + 20, _beside_door(151))
	Toon.spot(self, barrel + Vector2(0, 34), Vector2(34, 10), Color(0, 0, 0, 0.3))
	Toon.ball(self, barrel, Vector2(30, 38), WOOD, 0, 7, 4.5)
	for k in 3:
		Toon.stroke(self, Toon.bent(barrel + Vector2(-12 + k * 12, -35), barrel + Vector2(-12 + k * 12, 35), -3.0 + k * 3.0),
				1.6, Color(0, 0, 0, 0.3))
	for k in 2:
		Toon.stroke(self, Toon.bent(barrel + Vector2(-29, -18 + k * 36), barrel + Vector2(29, -18 + k * 36), -5.0), 5.0, IRON)
	Toon.blob(self, barrel + Vector2(0, -30), Vector2(22, 7), WOOD_DARK, 0, 8, 3.0)
	var crate := Vector2(f.end.x + 16 if left else f.position.x - 16, _beside_door(161))
	for c in 2:
		var at := crate + Vector2(0, -c * 50.0) + Vector2(c * 6.0, 0)
		var half := 30.0 - c * 6.0
		if c == 0:
			Toon.spot(self, at + Vector2(0, half + 4), Vector2(half + 6, 9), Color(0, 0, 0, 0.3))
		Toon.box(self, at, Vector2(half, half), Color("a8763f"), 0, 8 + c, 4.5)
		for k in 2:
			Toon.stroke(self, PackedVector2Array([at + Vector2(-half + 4, (k - 0.5) * half * 0.66),
					at + Vector2(half - 4, (k - 0.5) * half * 0.66)]), 1.6, Color(0, 0, 0, 0.3))
		Toon.stroke(self, PackedVector2Array([at + Vector2(-half + 6, -half + 6), at + Vector2(half - 6, half - 6)]), 4.0, WOOD_DARK)
		Toon.spot(self, at + Vector2(-half * 0.5, -half * 0.6), Vector2(half * 0.3, 3), Color(1, 1, 1, 0.3))


func _boiler() -> void:
	var f := Room.FLOOR
	# Gauges on the back wall, needles twitching.
	for k in 2:
		var at := Vector2(f.position.x + f.size.x * (0.1 + 0.8 * k), 74)
		Toon.stroke(self, PackedVector2Array([at + Vector2(0, 22), at + Vector2(0, 60)]), 7.0, IRON)
		Toon.ball(self, at, Vector2(24, 24), Color("c9a050"), 0, 12 + k, 5.0)
		Toon.blob(self, at, Vector2(18, 18), BrotherLook.WHITE, 0, 14 + k, 2.5)
		var needle := -0.9 + 1.8 * Toon.hash01(_drawing / 2 + k * 5, k)
		for m in 7:
			var a := -1.3 + m * 0.43
			draw_line(at + Vector2(sin(a), -cos(a)) * 12.0, at + Vector2(sin(a), -cos(a)) * 16.0, Toon.INK, 1.8)
		draw_arc(at, 14.0, -PI * 0.5 + 0.7, -PI * 0.5 + 1.3, 6, Color("b8322a"), 3.0)
		Toon.stroke(self, PackedVector2Array([at, at + Vector2(sin(needle), -cos(needle)) * 14.0]), 2.6, Color("b8322a"))
		Toon.spot(self, at, Vector2(3, 3), Toon.INK)
	# Copper pipes down the side walls, broken round the doors: into the wall
	# above a door and out again below it.
	for side: float in [-1.0, 1.0]:
		var x := 118.0 if side < 0.0 else 1802.0
		var runs: Array = [[70.0, 400.0], [680.0, 1010.0]] if room.doors.has("left" if side < 0.0 else "right") \
				else [[70.0, 1010.0]]
		for run: Array in runs:
			var a := Vector2(x, run[0])
			var b := Vector2(x, run[1])
			Toon.stroke(self, PackedVector2Array([a, b]), 22.0)
			Toon.stroke(self, PackedVector2Array([a, b]), 14.0, COPPER)
			Toon.stroke(self, PackedVector2Array([a + Vector2(-3, 0), b + Vector2(-3, 0)]), 3.0, Color(1, 0.9, 0.7, 0.45))
			for end: Vector2 in [a, b]:
				Toon.box(self, end, Vector2(16, 8), COPPER.darkened(0.2), 0, int(end.y), 4.0)
			var k := 0
			var y: float = run[0] + 90.0
			while y < run[1] - 50.0:
				Toon.box(self, Vector2(x, y), Vector2(15, 6), Color("5a5550"), 0, 9 + k, 3.0)
				y += 170.0
				k += 1
	# A joint on one pipe hisses steam.
	var joint := Vector2(130, 250 + _h(330) * 120.0)
	for k in 3:
		var rise := fmod(_clock * 1.3 + k * 0.33, 1.0)
		Toon.spot(self, joint + Vector2(18 + rise * 40.0, -rise * 30.0), Vector2(10, 8) * (0.6 + rise),
				Color(1, 1, 1, 0.5 * (1.0 - rise)))
	# Oil, dark and rainbow-sheened.
	for i in 2:
		var at := f.position + Vector2(160 + _h(170 + i) * (f.size.x - 320), 120 + _h(180 + i) * (f.size.y - 240))
		_puddle(at, 40.0 + _h(190 + i) * 20.0, 500 + i * 20, Color(0.08, 0.07, 0.09, 0.4))
		Toon.spot(self, at + Vector2(-8, -3), Vector2(12, 3), Color(0.6, 0.5, 0.9, 0.3), 0, i + 3)
	# A drain grate.
	var grate := f.position + Vector2(_h(200) * (f.size.x - 300) + 150, _h(201) * (f.size.y - 300) + 150)
	Toon.box(self, grate, Vector2(34, 22), Color("3a3836"), 0, 10, 4.0)
	for k in 5:
		Toon.stroke(self, PackedVector2Array([grate + Vector2(-22 + k * 11, -13), grate + Vector2(-22 + k * 11, 13)]), 3.0)
	Toon.spot(self, grate + Vector2(-12, -14), Vector2(14, 3), Color(1, 1, 1, 0.2))
	# Coal spilled in a front corner.
	var heap := Vector2(f.position.x + 40 if _h(210) < 0.5 else f.end.x - 40, f.end.y - 10)
	for i in 6:
		var at := heap + Vector2((i % 3 - 1) * 22.0, -(i / 3) * 16.0)
		Toon.ball(self, at, Vector2(15, 11), Color("2c2a2e"), 0, 80 + i, 3.5, 0.3)


func _catacombs() -> void:
	var f := Room.FLOOR
	# Niches in the back wall with a skull in each, and chains hanging.
	for k in 3:
		var at := Vector2(f.position.x + f.size.x * (0.14 + 0.36 * k) + (60.0 if k == 1 else 0.0), 84)
		if absf(at.x - f.get_center().x) < 130.0:
			at.x += 200.0
		var arch := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			arch.append(at + Vector2(cos(a) * 30.0, -6.0 + sin(a) * 26.0))
		arch.append(at + Vector2(30, 32))
		arch.append(at + Vector2(-30, 32))
		Toon.shape(self, arch, Color(0.08, 0.07, 0.05), 4.0)
		Toon.ball(self, at + Vector2(0, 12), Vector2(17, 15), BONE, 0, 16 + k, 3.0)
		Toon.spot(self, at + Vector2(-6, 11), Vector2(4.5, 5.5), Toon.INK)
		Toon.spot(self, at + Vector2(6, 11), Vector2(4.5, 5.5), Toon.INK)
		Toon.spot(self, at + Vector2(0, 19), Vector2(2, 2.5), Toon.INK)
	for k in 2:
		var top := Vector2(f.position.x + f.size.x * (0.3 + 0.4 * k), 24)
		var sway := sin(_clock * 1.2 + k) * 4.0
		for m in 7:
			var link := top + Vector2(sway * m / 7.0, m * 13.0)
			if m % 2 == 0:
				draw_arc(link, 5.0, 0.0, TAU, 10, IRON, 3.0, true)
			else:
				draw_line(link + Vector2(0, -5), link + Vector2(0, 5), IRON, 3.5)
	# Moss creeping over the top of the walls and the edge of the floor.
	for i in 8:
		var at := Vector2(280 + _h(210 + i) * 1360.0, f.position.y - 4)
		Toon.glow(self, at, Vector2(60, 16) * (0.6 + _h(220 + i)), Color(0.3, 0.48, 0.22, 0.55))
	# Bones and skulls about the floor.
	for i in 5:
		var at := f.position + Vector2(60 + _h(230 + i) * (f.size.x - 120), 60 + _h(240 + i) * (f.size.y - 120))
		var a := _h(250 + i) * PI
		var dir := Vector2(cos(a), sin(a) * 0.6)
		Toon.spot(self, at + Vector2(0, 5), Vector2(28, 7), Color(0, 0, 0, 0.18))
		Toon.stroke(self, PackedVector2Array([at - dir * 22.0, at + dir * 22.0]), 11.0)
		for e: float in [-1.0, 1.0]:
			for s: float in [-1.0, 1.0]:
				Toon.blob(self, at + dir * 22.0 * e + dir.orthogonal() * 4.0 * s, Vector2(5.5, 5.5), BONE, 0, 20 + i, 2.5)
		Toon.stroke(self, PackedVector2Array([at - dir * 22.0, at + dir * 22.0]), 6.0, BONE)
	for i in 2:
		var at := f.position + Vector2(60 + _h(260 + i) * (f.size.x - 120), 60 + _h(270 + i) * (f.size.y - 120))
		Toon.spot(self, at + Vector2(0, 16), Vector2(22, 6), Color(0, 0, 0, 0.2))
		Toon.ball(self, at, Vector2(22, 19), BONE, 0, 30 + i, 4.0)
		Toon.spot(self, at + Vector2(-8, 0), Vector2(5.5, 6.5), Toon.INK)
		Toon.spot(self, at + Vector2(8, 0), Vector2(5.5, 6.5), Toon.INK)
		Toon.spot(self, at + Vector2(0, 9), Vector2(2.5, 3), Toon.INK)
		for t in 4:
			draw_line(at + Vector2(-9 + t * 6, 14), at + Vector2(-9 + t * 6, 19), Toon.INK, 2.0)
	# Candles standing along the foot of the side walls, in puddles of wax.
	for i in 3:
		var at := Vector2(f.position.x - 12 if i % 2 == 0 else f.end.x + 12, f.position.y + 100 + i * 230.0)
		Toon.spot(self, at + Vector2(0, 11), Vector2(12, 4), BONE)
		Toon.box(self, at, Vector2(5, 11), BrotherLook.WHITE, 0, 40 + i, 2.5)
		_flame(at + Vector2(0, -12), 4.5, 12.0, _drawing + i)
