class_name RoomDecor
extends Node2D
## The lived-in bits of an ordinary room, over its painted walls and floor
## and under everyone: lamps on the back wall and the light they throw,
## cracks and cobwebs, and the clutter of each floor --
##   0 basement:  a barred window and its shaft of daylight, puddles, straw,
##                a mouse hole (barrels and crates are RoomProps')
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
	_clutter()
	_lamps()


# --- odds and ends on the floor ---------------------------------------------


## A spot on the floor for something lying flat, [param margin] in from the
## walls, from the room's seed.
func _spot(k: int, margin := 90.0) -> Vector2:
	var f := Room.FLOOR
	return f.position + Vector2(margin + _h(k) * (f.size.x - margin * 2.0),
			margin + _h(k + 1) * (f.size.y - margin * 2.0))


## What lies about the floor of each floor, drawn in ink like everything:
## one bigger thing now and then, and a scatter of small ones. Nothing that
## looks like something to pick up -- no coins, keys or hearts.
func _clutter() -> void:
	# The first room's floor has the controls chalked on it: left clear.
	var big := room.kind != "start" and _h(600) < 0.75
	match style:
		0:
			if big:
				var pick := int(_h(601) * 3.0)
				var at := _spot(602, 200.0)
				var turn := (_h(604) - 0.5) * 0.8
				if pick == 0:
					_rug(at, turn)
				elif pick == 1:
					_newspaper(at, turn)
				else:
					_flyer(at, turn)
			for i in 3 + int(_h(610) * 4.0):
				_nail(_spot(611 + i * 2, 60.0), _h(640 + i) * TAU, _h(650 + i) < 0.4)
			for i in 2 + int(_h(660) * 3.0):
				_shavings(_spot(661 + i * 2, 70.0), i)
			if _h(690) < 0.3:
				_mousetrap(Vector2(Room.FLOOR.position.x + 60.0 + _h(691) * (Room.FLOOR.size.x - 120.0),
						Room.FLOOR.end.y - 34.0))
		1:
			for i in 4 + int(_h(700) * 4.0):
				_nut(_spot(701 + i * 2, 60.0), i)
			if big:
				if _h(720) < 0.5:
					_wrench(_spot(721, 160.0), _h(723) * TAU)
				else:
					_shovel(_spot(724, 180.0), (_h(726) - 0.5) * 1.2)
			if _h(730) < 0.6:
				_footprints(_spot(731, 160.0), _h(733) * TAU)
			for i in 3 + int(_h(740) * 3.0):
				var at := _spot(741 + i * 2, 50.0)
				Toon.ball(self, at, Vector2(7, 5) * (0.7 + _h(760 + i) * 0.6), Color("2c2a2e"), 0, 120 + i, 2.5, 0.3)
		_:
			for i in 6 + int(_h(800) * 6.0):
				_pebble(_spot(801 + i * 2, 50.0), i)
			if big:
				if _h(830) < 0.55:
					_ribcage(_spot(831, 180.0), (_h(833) - 0.5) * 0.9)
				else:
					for i in 3:
						_stub(_spot(834 + i * 2, 120.0), i)
			if _h(850) < 0.7:
				_spider(Vector2(Room.FLOOR.position.x + 120.0 + _h(851) * (Room.FLOOR.size.x - 240.0), 0.0))


## A braided rag rug: a long coil of plaited rag going round and round an
## oval, its colours changing as the rags ran out, frayed at the ends.
func _rug(at: Vector2, turn: float) -> void:
	draw_set_transform(at, turn * 0.3, Vector2.ONE)
	var colours := [Color("8e4a36"), Color("b89a6a"), Color("6e5038"), Color("a8392e"), Color("c9b48a"),
			Color("5e6a4a"), Color("8e4a36"), Color("b89a6a")]
	var r := Vector2(150, 82)
	Toon.spot(self, Vector2(6, 10), r + Vector2(8, 6), Color(0, 0, 0, 0.22))
	var rings := colours.size()
	for k in rings:
		var rr := r * (1.0 - float(k) / rings * 0.92)
		Toon.blob(self, Vector2.ZERO, rr, colours[k], 0, 900 + k, 3.0 if k == 0 else 1.5)
	# The plait: slanted ticks all round every coil, the slant flipping coil
	# to coil.
	for k in rings:
		var rr := r * (1.0 - (k + 0.5) / rings * 0.92)
		var n := int(46.0 * rr.x / r.x) + 8
		for i in n:
			var a := TAU * i / n
			var p := Vector2(cos(a) * rr.x, sin(a) * rr.y)
			var slant := a + (1.0 if k % 2 == 0 else -1.0) * 0.8
			draw_line(p - Vector2(cos(slant), sin(slant)) * 3.0, p + Vector2(cos(slant), sin(slant)) * 3.0,
					Color(Toon.INK, 0.4), 1.6)
	# Fringe at the ends.
	for side: float in [-1.0, 1.0]:
		for i in 7:
			var y := (i - 3) * 9.0
			var x := side * sqrt(maxf(1.0 - pow(y / r.y, 2.0), 0.0)) * r.x
			Toon.stroke(self, PackedVector2Array([Vector2(x, y), Vector2(x + side * 14.0, y + (i % 2) * 3.0)]),
					2.0, Color("c9b48a"))
	draw_set_transform(Vector2.ZERO)


## An old newspaper lying open: a masthead, a headline, a picture, columns.
func _newspaper(at: Vector2, turn: float) -> void:
	draw_set_transform(at, turn, Vector2.ONE)
	var page := Rect2(-110, -76, 220, 152)
	Toon.spot(self, Vector2(6, 8), Vector2(116, 78), Color(0, 0, 0, 0.2))
	var paper := PackedVector2Array([page.position, Vector2(page.end.x, page.position.y + 4), page.end,
			Vector2(page.position.x + 6, page.end.y), Vector2(page.position.x - 4, page.position.y + 70)])
	Toon.shape(self, paper, Color("e9e0c8"), 3.0)
	# The fold down the middle.
	draw_line(Vector2(0, page.position.y + 3), Vector2(2, page.end.y - 2), Color(0, 0, 0, 0.15), 3.0)
	var font := Ui.font()
	draw_string(font, Vector2(page.position.x, page.position.y + 26), "ВЕЧЕРНИЙ ГОРОД", HORIZONTAL_ALIGNMENT_CENTER,
			page.size.x, 18, Toon.INK)
	draw_line(Vector2(page.position.x + 10, page.position.y + 32), Vector2(page.end.x - 10, page.position.y + 32),
			Toon.INK, 2.0)
	draw_string(font, Vector2(page.position.x, page.position.y + 52), "БАРОН СНОВА НА ВОЛЕ!",
			HORIZONTAL_ALIGNMENT_CENTER, page.size.x, 15, Color("7a1e18"))
	# A picture: the Baron's silhouette, top hat and all.
	var pic := Rect2(page.position.x + 12, page.position.y + 62, 70, 72)
	draw_rect(pic, Color("bfb39a"))
	draw_rect(pic, Toon.INK, false, 2.0)
	Toon.blob(self, pic.get_center() + Vector2(0, 14), Vector2(18, 20), Toon.INK, 0, 905, 0.0)
	Toon.blob(self, pic.get_center() + Vector2(0, -8), Vector2(12, 12), Toon.INK, 0, 906, 0.0)
	draw_rect(Rect2(pic.get_center() + Vector2(-8, -34), Vector2(16, 18)), Toon.INK)
	draw_rect(Rect2(pic.get_center() + Vector2(-14, -18), Vector2(28, 4)), Toon.INK)
	# Columns of print.
	for col in 2:
		for row in 9:
			var x0 := page.position.x + 92 + col * 60.0
			var y := page.position.y + 66 + row * 8.0
			var w := 50.0 - (12.0 if (row * 7 + col * 3) % 5 == 0 else 0.0)
			draw_line(Vector2(x0, y), Vector2(x0 + w, y), Color(Toon.INK, 0.55), 2.0)
	draw_set_transform(Vector2.ZERO)


## A flyer for the Baron's cabaret, dropped by his gang.
func _flyer(at: Vector2, turn: float) -> void:
	draw_set_transform(at, turn, Vector2.ONE)
	Toon.spot(self, Vector2(5, 7), Vector2(62, 84), Color(0, 0, 0, 0.2))
	Toon.box(self, Vector2.ZERO, Vector2(58, 80), Color("8e2328"), 0, 910, 3.5)
	Toon.box(self, Vector2.ZERO, Vector2(50, 72), Color("8e2328"), 0, 911, 0.0)
	draw_rect(Rect2(-48, -70, 96, 140), Color("e8b83a"), false, 2.0)
	var font := Ui.font()
	draw_string(font, Vector2(-58, -40), "КАБАРЕ", HORIZONTAL_ALIGNMENT_CENTER, 116, 16, Color("f3e6c8"))
	draw_string(font, Vector2(-58, -18), "«Золотой", HORIZONTAL_ALIGNMENT_CENTER, 116, 15, Color("e8b83a"))
	draw_string(font, Vector2(-58, 0), "Коготь»", HORIZONTAL_ALIGNMENT_CENTER, 116, 15, Color("e8b83a"))
	Toon.star(self, Vector2(0, 30), 13.0, 0.0, Color("e8b83a"))
	draw_string(font, Vector2(-58, 62), "каждую ночь", HORIZONTAL_ALIGNMENT_CENTER, 116, 11, Color("f3e6c8"))
	draw_set_transform(Vector2.ZERO)


## A nail lying about: a shank and a head, or bent double.
func _nail(at: Vector2, a: float, bent: bool) -> void:
	var dir := Vector2(cos(a), sin(a) * 0.7)
	var steel := Color("8a8a90")
	if bent:
		var mid := at + dir * 7.0
		var tip := mid + dir.rotated(1.3) * 8.0
		Toon.stroke(self, PackedVector2Array([at - dir * 7.0, mid, tip]), 4.5)
		Toon.stroke(self, PackedVector2Array([at - dir * 7.0, mid, tip]), 2.0, steel)
	else:
		Toon.stroke(self, PackedVector2Array([at - dir * 9.0, at + dir * 9.0]), 4.5)
		Toon.stroke(self, PackedVector2Array([at - dir * 9.0, at + dir * 9.0]), 2.0, steel)
	Toon.blob(self, at - dir * 9.0, Vector2(3.2, 3.2), steel, 0, int(a * 10.0), 2.0)


## A few curls of wood shaving.
func _shavings(at: Vector2, k: int) -> void:
	for i in 3:
		var c := at + Vector2((_h(670 + k * 3 + i) - 0.5) * 40.0, (_h(680 + k * 3 + i) - 0.5) * 20.0)
		var start := _h(690 + k * 3 + i) * TAU
		draw_arc(c, 6.0 + i * 2.0, start, start + 4.2, 10, Toon.INK, 3.5, true)
		draw_arc(c, 6.0 + i * 2.0, start, start + 4.2, 10, Color("e6c48a"), 1.8, true)


## A mousetrap against the front wall, a wedge of cheese on it.
func _mousetrap(at: Vector2) -> void:
	Toon.spot(self, at + Vector2(3, 6), Vector2(34, 10), Color(0, 0, 0, 0.2))
	Toon.box(self, at, Vector2(30, 13), Color("b8854e"), 0, 920, 3.0)
	draw_arc(at + Vector2(-8, 0), 10.0, -PI * 0.5, PI * 0.5, 10, Color("b0b0b8"), 2.5, true)
	draw_line(at + Vector2(-20, -10), at + Vector2(20, -10), Color("b0b0b8"), 2.5)
	Toon.shape(self, PackedVector2Array([at + Vector2(6, 4), at + Vector2(22, -2), at + Vector2(22, 8)]),
			Color("f0c43a"), 2.5)
	Toon.spot(self, at + Vector2(16, 3), Vector2(1.6, 1.6), Color("c89a20"))


## A nut or a bolt off some machine.
func _nut(at: Vector2, k: int) -> void:
	var steel := Color("8c8e94")
	if k % 3 == 0:
		# A bolt: a hex head and a threaded shank.
		var a := _h(780 + k) * TAU
		var dir := Vector2(cos(a), sin(a) * 0.7)
		Toon.stroke(self, PackedVector2Array([at, at + dir * 18.0]), 6.0)
		Toon.stroke(self, PackedVector2Array([at, at + dir * 18.0]), 3.0, steel)
		for t in 3:
			var p := at + dir * (8.0 + t * 4.0)
			draw_line(p - dir.orthogonal() * 2.0, p + dir.orthogonal() * 2.0, Toon.INK, 1.2)
	var hexa := PackedVector2Array()
	var turn := _h(790 + k)
	for i in 6:
		var a := turn + TAU * i / 6.0
		hexa.append(at + Vector2(cos(a), sin(a) * 0.8) * 7.0)
	Toon.shape(self, hexa, steel, 2.5)
	if k % 3 != 0:
		Toon.spot(self, at, Vector2(2.6, 2.2), Toon.INK)


## A big spanner lying where it was dropped.
func _wrench(at: Vector2, a: float) -> void:
	var dir := Vector2(cos(a), sin(a) * 0.7)
	var steel := Color("9a9ca2")
	Toon.spot(self, at + Vector2(4, 8), Vector2(60, 12), Color(0, 0, 0, 0.18))
	Toon.stroke(self, PackedVector2Array([at - dir * 44.0, at + dir * 44.0]), 15.0)
	Toon.stroke(self, PackedVector2Array([at - dir * 44.0, at + dir * 44.0]), 9.0, steel)
	for end: float in [-1.0, 1.0]:
		var jaw := at + dir * 50.0 * end
		Toon.ball(self, jaw, Vector2(13, 11), steel, 0, 930 + int(end), 3.5, a)
		Toon.spot(self, jaw + dir * 6.0 * end, Vector2(6, 4), Color("3a3836"), 0, 931, a)


## A coal shovel lying flat.
func _shovel(at: Vector2, a: float) -> void:
	var dir := Vector2(cos(a), sin(a) * 0.7)
	Toon.spot(self, at + Vector2(6, 10), Vector2(80, 16), Color(0, 0, 0, 0.18))
	Toon.stroke(self, PackedVector2Array([at - dir * 70.0, at + dir * 20.0]), 11.0)
	Toon.stroke(self, PackedVector2Array([at - dir * 70.0, at + dir * 20.0]), 6.0, WOOD)
	Toon.box(self, at - dir * 78.0, Vector2(12, 6), WOOD_DARK, 0, 940, 3.0, a)
	var blade := at + dir * 46.0
	var side := dir.orthogonal()
	Toon.shape(self, PackedVector2Array([blade - dir * 20.0 - side * 16.0, blade + dir * 26.0 - side * 22.0,
			blade + dir * 30.0 + side * 22.0, blade - dir * 20.0 + side * 16.0]), Color("4a4a50"), 3.5)
	Toon.ball(self, blade + dir * 8.0, Vector2(12, 8), Color("2c2a2e"), 0, 941, 2.5, a)


## Boot prints in the coal dust, walking off.
func _footprints(at: Vector2, a: float) -> void:
	var dir := Vector2(cos(a), sin(a) * 0.7)
	for i in 6:
		var side := dir.orthogonal() * (9.0 if i % 2 == 0 else -9.0)
		var p := at + dir * i * 34.0 + side
		Toon.spot(self, p, Vector2(9, 5), Color(0.1, 0.1, 0.12, 0.35 - i * 0.04), 0, 950 + i, a)
		Toon.spot(self, p - dir * 10.0, Vector2(5, 4), Color(0.1, 0.1, 0.12, 0.3 - i * 0.04), 0, 960 + i, a)


## A pebble or a chip of stone.
func _pebble(at: Vector2, k: int) -> void:
	var r := Vector2(5, 4) * (0.6 + _h(870 + k) * 0.9)
	Toon.spot(self, at + Vector2(1.5, 2.5), r, Color(0, 0, 0, 0.18))
	Toon.ball(self, at, r, Color("a9a68e").darkened(_h(880 + k) * 0.3), 0, 970 + k, 2.0, _h(890 + k) * PI)


## The ribs of something long dead, and its backbone.
func _ribcage(at: Vector2, turn: float) -> void:
	draw_set_transform(at, turn, Vector2.ONE)
	Toon.spot(self, Vector2(4, 12), Vector2(70, 22), Color(0, 0, 0, 0.18))
	Toon.stroke(self, PackedVector2Array([Vector2(-66, 0), Vector2(66, 0)]), 10.0)
	Toon.stroke(self, PackedVector2Array([Vector2(-66, 0), Vector2(66, 0)]), 5.0, BONE)
	for i in 6:
		var x := -44.0 + i * 17.0
		for side: float in [-1.0, 1.0]:
			var rib := Toon.bent(Vector2(x, 0), Vector2(x - 10.0, side * (30.0 - absf(i - 2.5) * 3.0)), side * 9.0, 6)
			Toon.stroke(self, rib, 7.0)
			Toon.stroke(self, rib, 3.4, BONE)
	for i in 8:
		Toon.blob(self, Vector2(-60.0 + i * 17.0, 0), Vector2(4, 4), BONE, 0, 980 + i, 2.0)
	draw_set_transform(Vector2.ZERO)


## A candle stub burnt down and out, in its puddle of wax.
func _stub(at: Vector2, k: int) -> void:
	Toon.spot(self, at + Vector2(0, 6), Vector2(16, 6), Color("e9dfc8"), 0, 990 + k)
	Toon.box(self, at, Vector2(5, 6), BrotherLook.WHITE, 0, 993 + k, 2.5)
	Toon.stroke(self, PackedVector2Array([at + Vector2(0, -6), at + Vector2(1, -11)]), 1.8)


## A spider let down from the top of the back wall on its thread, bobbing.
func _spider(top: Vector2) -> void:
	var drop := 150.0 + sin(_clock * 1.1 + top.x) * 18.0
	var body := top + Vector2(0, drop)
	draw_line(top, body, Color(1, 1, 1, 0.5), 1.2)
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var a := -0.9 + i * 0.6
			var knee := body + Vector2(side * 9.0, -2.0 + i * 3.0) + Vector2(side * cos(a), sin(a)) * 6.0
			var foot := knee + Vector2(side * 6.0, 7.0 + sin(_clock * 6.0 + i) * 1.5)
			Toon.stroke(self, PackedVector2Array([body, knee, foot]), 2.0)
	Toon.blob(self, body, Vector2(8, 9), Toon.INK, 0, 999, 0.0)
	Toon.blob(self, body + Vector2(0, -9), Vector2(5, 5), Toon.INK, 0, 998, 0.0)
	for e: float in [-1.0, 1.0]:
		Toon.spot(self, body + Vector2(e * 2.2, -10), Vector2(1.3, 1.6), BrotherLook.WHITE)


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
		var runs: Array = [[70.0, 400.0], [680.0, 1010.0]] if room.has_door("left" if side < 0.0 else "right") \
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
