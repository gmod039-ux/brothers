class_name RoomDecor
extends Node2D
## The lived-in bits of an ordinary room, over its walls and floor and under
## everyone: lamps on the back wall and the pools of light they throw,
## cracks, stains and cobwebs, tiles a shade off from their neighbours, and
## the clutter of each floor --
##   0 basement:  puddles, straw, barrels and crates against the walls
##   1 boiler:    pipes down the walls, oil stains, drain grates
##   2 catacombs: bones and skulls, moss, candles, niches in the wall
## Laid out by the room's seed, so a room looks the same every visit. The
## flames move; the rest holds still.

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


func _draw() -> void:
	_tiles()
	_wall_marks()
	match style:
		0:
			_basement()
		1:
			_boiler()
		_:
			_catacombs()
	_lamps()


## Every tile a touch lighter or darker than the next, the way no two
## stones of a floor are quite the same colour.
func _tiles() -> void:
	var f := Room.FLOOR
	for row in Room.ROWS:
		for col in Room.COLS:
			var v := _h(1000 + row * 31 + col) - 0.5
			var rect := Rect2(f.position + Vector2(col, row) * Room.TILE, Vector2(Room.TILE, Room.TILE)).grow(-4.0)
			if absf(v) > 0.15:
				draw_rect(rect, Color(1, 1, 1, v * 0.12) if v > 0.0 else Color(0, 0, 0, -v * 0.1))


## Cracks and stains on the walls, and cobwebs in the two back corners.
func _wall_marks() -> void:
	for i in 5:
		var x := 260.0 + _h(i) * 1400.0
		var y := 40.0 + _h(i + 10) * 70.0
		var a := Vector2(x, y)
		var b := a + Vector2(_h(i + 20) * 30.0 - 15.0, 22.0)
		var c := b + Vector2(_h(i + 30) * 30.0 - 15.0, 18.0)
		Toon.stroke(self, PackedVector2Array([a, b, c]), 2.2, Color(0, 0, 0, 0.35))
	for i in 3:
		Toon.spot(self, Vector2(300.0 + _h(i + 40) * 1300.0, 60.0 + _h(i + 50) * 60.0),
				Vector2(40, 22) * (0.6 + _h(i + 60)), Color(0, 0, 0, 0.12), 0, i)
	for side: float in [-1.0, 1.0]:
		var corner := Vector2(Room.FLOOR.position.x if side < 0.0 else Room.FLOOR.end.x, Room.FLOOR.position.y)
		for k in 4:
			var a := PI * 0.5 * k / 3.0
			var dir := Vector2(-side * cos(a), sin(a))
			draw_line(corner, corner + dir * 70.0, Color(1, 1, 1, 0.3), 1.2, true)
		for r in 3:
			var pts := PackedVector2Array()
			for k in 4:
				var a := PI * 0.5 * k / 3.0
				pts.append(corner + Vector2(-side * cos(a), sin(a)) * (20.0 + r * 18.0))
			draw_polyline(pts, Color(1, 1, 1, 0.28), 1.2, true)


## Lamps on the back wall, flames flickering, each throwing a warm pool of
## light onto the floor below it.
func _lamps() -> void:
	var f := Room.FLOOR
	var d := _drawing
	for i in 2:
		var x := f.position.x + f.size.x * (0.22 + 0.56 * i)
		var wall := Vector2(x, 88)
		var flick: float = [1.0, 0.92, 1.06, 0.97][(d + i * 2) % 4]
		Toon.spot(self, Vector2(x, f.position.y + 70), Vector2(210, 90) * flick, Color(1, 0.85, 0.45, 0.1))
		Toon.spot(self, wall + Vector2(0, -8), Vector2(40, 34) * flick, Color(1, 0.85, 0.4, 0.22))
		match style:
			1:
				# A caged electric bulb.
				Toon.blob(self, wall, Vector2(10, 12), Color("fff1a8"), 0, 1, 3.0)
				for k in 3:
					Toon.stroke(self, PackedVector2Array([wall + Vector2(-12 + k * 12, -14), wall + Vector2(-10 + k * 10, 14)]), 2.0)
				Toon.box(self, wall + Vector2(0, -18), Vector2(8, 4), Color("5a5550"), 0, 2, 2.5)
			2:
				# A candle in a niche.
				draw_rect(Rect2(wall + Vector2(-20, -22), Vector2(40, 52)), Color(0, 0, 0, 0.35))
				Toon.box(self, wall + Vector2(0, 16), Vector2(6, 12), BrotherLook.WHITE, 0, 4, 2.5)
				_flame(wall + Vector2(0, 2), 6.0, 16.0 * flick, d + i)
			_:
				# An oil lamp on a bracket.
				Toon.stroke(self, PackedVector2Array([wall + Vector2(0, 22), wall + Vector2(0, 34)]), 4.0)
				Toon.blob(self, wall + Vector2(0, 16), Vector2(12, 8), Color("b8863a"), 0, 5, 3.0)
				_flame(wall + Vector2(0, 8), 7.0, 18.0 * flick, d + i)
				# Its glass chimney: just an outline and a glint.
				draw_arc(wall + Vector2(0, 2), 11.0, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 2.0, true)
				Toon.spot(self, wall + Vector2(-5, -2), Vector2(2, 6), Color(1, 1, 1, 0.6))


func _flame(base: Vector2, width: float, height: float, d: int) -> void:
	var lean: float = [1.0, -1.5, 2.0, -0.5][d % 4]
	var points := PackedVector2Array()
	for k in 12:
		var t := TAU * k / 12.0
		var y := -cos(t)
		var up := (1.0 - y) * 0.5
		points.append(base + Vector2(sin(t) * sin(t * 0.5) * width + lean * up * up * 3.0, -up * height + width * 0.3))
	Toon.shape(self, points, StoveBoss.FIRE, 2.5)
	Toon.spot(self, base + Vector2(0, -height * 0.2), Vector2(width * 0.4, height * 0.25), StoveBoss.FIRE_CORE)


func _basement() -> void:
	var f := Room.FLOOR
	# A barred window high in the back wall, and the shaft of daylight it
	# lets in, dust turning in it.
	var window := Vector2(f.position.x + f.size.x * (0.35 + _h(300) * 0.3), 70)
	if absf(window.x - f.get_center().x) < 140.0:
		window.x += 260.0
	var shaft := PackedVector2Array([window + Vector2(-34, 20), window + Vector2(34, 20),
			window + Vector2(120, 560), window + Vector2(-40, 560)])
	draw_colored_polygon(shaft, Color(1, 0.96, 0.8, 0.12))
	for k in 6:
		var t := fmod(_clock * 0.07 + _h(310 + k), 1.0)
		var mote := window + Vector2(-20 + _h(320 + k) * 90.0 + t * 60.0, 60 + t * 460.0)
		Toon.spot(self, mote, Vector2(2.2, 2.2), Color(1, 1, 0.9, 0.5 * sin(t * PI)))
	Toon.box(self, window, Vector2(44, 26), Color("2a1d16"), 0, 11, 5.0)
	Toon.spot(self, window + Vector2(0, 6), Vector2(36, 16), Color(0.8, 0.85, 0.9, 0.35))
	for k in 4:
		Toon.stroke(self, PackedVector2Array([window + Vector2(-30 + k * 20, -24), window + Vector2(-30 + k * 20, 24)]), 4.5)
	# Puddles.
	for i in 2:
		var at := f.position + Vector2(_h(70 + i) * f.size.x, _h(80 + i) * f.size.y)
		Toon.spot(self, at, Vector2(60, 22) * (0.7 + _h(90 + i) * 0.6), Color(0.35, 0.42, 0.48, 0.35), 0, i)
		Toon.spot(self, at + Vector2(-14, -4), Vector2(16, 3), Color(1, 1, 1, 0.35), 0, i + 5)
	# Straw.
	for i in 14:
		var at := f.position + Vector2(_h(100 + i) * f.size.x, _h(120 + i) * f.size.y)
		var a := _h(140 + i) * PI
		Toon.stroke(self, PackedVector2Array([at, at + Vector2(cos(a), sin(a)) * 24.0]), 3.0, Color("c9a44a"))
	# A barrel and a crate against the side walls.
	var barrel := Vector2(f.position.x + 30, f.position.y + 60 + _h(150) * 500.0)
	Toon.ball(self, barrel, Vector2(30, 38), Color("8a5a36"), 0, 7, 4.5)
	for k in 2:
		Toon.stroke(self, Toon.bent(barrel + Vector2(-29, -16 + k * 32), barrel + Vector2(29, -16 + k * 32), -5.0), 4.5,
				Color("3a302a"))
	for k in 3:
		Toon.stroke(self, Toon.bent(barrel + Vector2(-14 + k * 14, -34), barrel + Vector2(-14 + k * 14, 34), 3.0), 1.6,
				Color(0, 0, 0, 0.3))
	var crate := Vector2(f.end.x - 34, f.position.y + 60 + _h(160) * 500.0)
	Toon.box(self, crate, Vector2(32, 32), Color("a0703f"), 0, 8, 4.5)
	for k in 2:
		Toon.stroke(self, PackedVector2Array([crate + Vector2(-28, -9 + k * 18), crate + Vector2(28, -9 + k * 18)]), 1.6,
				Color(0, 0, 0, 0.3))
	Toon.stroke(self, PackedVector2Array([crate + Vector2(-24, -24), crate + Vector2(24, 24)]), 3.5, Color("5a3a20"))
	Toon.stroke(self, PackedVector2Array([crate + Vector2(24, -24), crate + Vector2(-24, 24)]), 3.5, Color("5a3a20"))


func _boiler() -> void:
	var f := Room.FLOOR
	# Gauges on the back wall, needles twitching, and a leaky joint hissing.
	for k in 2:
		var at := Vector2(f.position.x + f.size.x * (0.12 + 0.76 * k), 76)
		Toon.ball(self, at, Vector2(22, 22), BrotherLook.WHITE, 0, 12 + k, 5.0)
		var needle := -0.9 + 1.8 * Toon.hash01(_drawing / 2 + k * 5, k)
		Toon.stroke(self, PackedVector2Array([at, at + Vector2(sin(needle), -cos(needle)) * 15.0]), 3.0, Color("b8322a"))
		for m in 5:
			var a := -1.2 + m * 0.6
			draw_line(at + Vector2(sin(a), -cos(a)) * 17.0, at + Vector2(sin(a), -cos(a)) * 20.0, Toon.INK, 2.0)
	var joint := Vector2(150, 300 + _h(330) * 400.0)
	for k in 3:
		var rise := fmod(_clock * 1.3 + k * 0.33, 1.0)
		Toon.spot(self, joint + Vector2(18 + rise * 40.0, -rise * 30.0), Vector2(10, 8) * (0.6 + rise),
				Color(1, 1, 1, 0.5 * (1.0 - rise)))
	# Pipes down the side walls, with brackets.
	for side: float in [-1.0, 1.0]:
		var x := 150.0 if side < 0.0 else 1770.0
		Toon.stroke(self, PackedVector2Array([Vector2(x, 60), Vector2(x, 1000)]), 20.0)
		Toon.stroke(self, PackedVector2Array([Vector2(x, 60), Vector2(x, 1000)]), 13.0, Color("b86f3c"))
		Toon.stroke(self, PackedVector2Array([Vector2(x - 3, 60), Vector2(x - 3, 1000)]), 2.5, Color(1, 1, 1, 0.3))
		for k in 5:
			Toon.box(self, Vector2(x, 180 + k * 190.0), Vector2(14, 6), Color("5a5550"), 0, 9 + k, 3.0)
	# Oil stains.
	for i in 3:
		var at := f.position + Vector2(_h(170 + i) * f.size.x, _h(180 + i) * f.size.y)
		Toon.spot(self, at, Vector2(46, 18) * (0.6 + _h(190 + i)), Color(0.1, 0.08, 0.1, 0.3), 0, i)
		Toon.spot(self, at + Vector2(-10, -3), Vector2(10, 3), Color(0.6, 0.5, 0.9, 0.25), 0, i + 3)
	# A drain grate.
	var grate := f.position + Vector2(_h(200) * (f.size.x - 100) + 50, _h(201) * (f.size.y - 100) + 50)
	Toon.box(self, grate, Vector2(30, 18), Color("3a3836"), 0, 10, 3.5)
	for k in 5:
		Toon.stroke(self, PackedVector2Array([grate + Vector2(-22 + k * 11, -12), grate + Vector2(-22 + k * 11, 12)]), 2.5)


func _catacombs() -> void:
	var f := Room.FLOOR
	# Niches in the back wall with a skull in each, and chains hanging.
	for k in 3:
		var at := Vector2(f.position.x + f.size.x * (0.14 + 0.36 * k) + (60.0 if k == 1 else 0.0), 84)
		if absf(at.x - f.get_center().x) < 110.0:
			at.x += 180.0
		Toon.box(self, at, Vector2(28, 30), Color(0.08, 0.07, 0.05), 0, 13 + k, 4.0)
		Toon.ball(self, at + Vector2(0, 8), Vector2(16, 14), Color("e9dfc8"), 0, 16 + k, 3.0)
		Toon.spot(self, at + Vector2(-6, 7), Vector2(4, 5), Toon.INK)
		Toon.spot(self, at + Vector2(6, 7), Vector2(4, 5), Toon.INK)
		Toon.spot(self, at + Vector2(0, 15), Vector2(2, 2.5), Toon.INK)
	for k in 2:
		var top := Vector2(f.position.x + f.size.x * (0.3 + 0.4 * k), 24)
		var sway := sin(_clock * 1.2 + k) * 4.0
		for m in 6:
			var link := top + Vector2(sway * m / 6.0, m * 14.0)
			draw_arc(link, 5.0, 0.0, TAU, 10, Color("3a3836"), 3.0, true)
	# Moss creeping down the walls and over the edge of the floor.
	for i in 8:
		var at := Vector2(260 + _h(210 + i) * 1400.0, f.position.y - 6)
		Toon.spot(self, at, Vector2(40, 12) * (0.6 + _h(220 + i)), Color(0.35, 0.5, 0.25, 0.45), 0, i)
	# Bones and skulls about the floor.
	for i in 5:
		var at := f.position + Vector2(40 + _h(230 + i) * (f.size.x - 80), 40 + _h(240 + i) * (f.size.y - 80))
		var a := _h(250 + i) * PI
		var dir := Vector2(cos(a), sin(a) * 0.6)
		Toon.stroke(self, PackedVector2Array([at - dir * 24.0, at + dir * 24.0]), 10.0)
		Toon.stroke(self, PackedVector2Array([at - dir * 24.0, at + dir * 24.0]), 5.5, Color("e9dfc8"))
		for e: float in [-1.0, 1.0]:
			for s: float in [-1.0, 1.0]:
				Toon.blob(self, at + dir * 24.0 * e + dir.orthogonal() * 4.0 * s, Vector2(5, 5), Color("e9dfc8"), 0, 20 + i, 2.5)
	for i in 2:
		var at := f.position + Vector2(40 + _h(260 + i) * (f.size.x - 80), 40 + _h(270 + i) * (f.size.y - 80))
		Toon.ball(self, at, Vector2(22, 19), Color("e9dfc8"), 0, 30 + i, 4.0)
		Toon.spot(self, at + Vector2(-8, 0), Vector2(5.5, 6.5), Toon.INK)
		Toon.spot(self, at + Vector2(8, 0), Vector2(5.5, 6.5), Toon.INK)
		Toon.spot(self, at + Vector2(0, 10), Vector2(2.5, 3), Toon.INK)
		for t in 4:
			draw_line(at + Vector2(-9 + t * 6, 15), at + Vector2(-9 + t * 6, 20), Toon.INK, 2.0)
	# Candles standing along the foot of the side walls.
	for i in 3:
		var at := Vector2(f.position.x + 18 if i % 2 == 0 else f.end.x - 18, f.position.y + 120 + i * 230.0)
		Toon.spot(self, at + Vector2(0, -20), Vector2(30, 24), Color(1, 0.85, 0.4, 0.18))
		Toon.box(self, at, Vector2(5, 11), BrotherLook.WHITE, 0, 40 + i, 2.5)
		_flame(at + Vector2(0, -12), 4.5, 12.0, _drawing + i)
