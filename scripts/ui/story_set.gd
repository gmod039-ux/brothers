class_name StorySet
extends RefCounted
## The painted backgrounds of the story's cartoon, in the game's ink: a
## street of the brothers' town -- shops and houses, gas lamps, a sewer
## manhole in the cobbles, the cellar hatch at the far end -- and the sky
## over it, at dusk or at night. Like the backgrounds of the old cartoons
## they are painted once and stand still; only the figures boil.
##
## Everything here is a static function drawing into the canvas item it is
## given, in the street's own coordinates: the houses stand on
## [constant WALL_BASE], the cast walks the pavement in front of them, the
## road is below [constant ROAD].

const WALL_BASE := 700.0
const CURB := 872.0
const ROAD := 892.0
const GROUND_FLOOR := 250.0
const STOREY := 200.0
## The houses, left to right. "floors" counts the ground floor; "ground" is
## what it has: a "door", a "shop" with a sign and an awning, or a "poster"
## on its wall.
const HOUSES: Array[Dictionary] = [
	{"x": -420.0, "w": 400.0, "floors": 3, "wall": "b5653f", "roof": "flat", "ground": "door"},
	{"x": -20.0, "w": 400.0, "floors": 2, "wall": "c99a52", "roof": "flat", "ground": "door"},
	{"x": 380.0, "w": 420.0, "floors": 3, "wall": "b5653f", "roof": "gable", "ground": "shop", "sign": "ПЕКАРНЯ",
			"awning": "c8392b"},
	{"x": 800.0, "w": 340.0, "floors": 2, "wall": "7f8f6a", "roof": "mansard", "ground": "poster"},
	{"x": 1140.0, "w": 420.0, "floors": 2, "wall": "6f7f9a", "roof": "gable", "ground": "shop", "sign": "КАФЕ",
			"awning": "c8392b"},
	{"x": 1560.0, "w": 410.0, "floors": 3, "wall": "a4776a", "roof": "mansard", "ground": "door"},
	{"x": 2070.0, "w": 420.0, "floors": 2, "wall": "c99a52", "roof": "flat", "ground": "shop", "sign": "ЦИРЮЛЬНЯ",
			"awning": "3f6fb5"},
	{"x": 2490.0, "w": 400.0, "floors": 3, "wall": "7f8f6a", "roof": "gable", "ground": "door"},
	{"x": 2890.0, "w": 440.0, "floors": 2, "wall": "a4776a", "roof": "mansard", "ground": "shop", "sign": "КИНО",
			"awning": "e0b23a"},
	{"x": 3330.0, "w": 460.0, "floors": 3, "wall": "b5653f", "roof": "flat", "ground": "door"},
]
## The dark gap between two houses where something watches.
const ALLEY := Vector2(1970.0, 2070.0)
const LAMPS: Array[float] = [330.0, 1340.0, 2400.0]
const LAMP_TOP := 330.0
const LEFT := -1600.0
const RIGHT := 5200.0

## The glass the street's lights show in, gathered as it is painted, for
## [method lights] to light: [kind, rect, id, shop name, house].
static var _glazing: Array = []


## A painted colour as the hour lights it: [param night] 0 is a warm dusk,
## 1 a blue moonlit night.
static func tint(c: Color, night: float) -> Color:
	var by := Color(1.0, 0.88, 0.8).lerp(Color(0.46, 0.5, 0.68), night)
	return Color(c.r * by.r, c.g * by.g, c.b * by.b, c.a)


# --- the sky ---------------------------------------------------------------------


## The sky, the moon and the stars, and the roofs of the far side of town
## in silhouette: the far layer, which pans slower than the street.
static func sky(ci: CanvasItem, night: float, drawing: int) -> void:
	var top := Color("3b2b57").lerp(Color("0c1122"), night)
	var mid := Color("a35a6c").lerp(Color("1b2440"), night)
	var low := Color("f0a660").lerp(Color("37456a"), night)
	ci.draw_polygon(PackedVector2Array([Vector2(LEFT, -1400), Vector2(RIGHT, -1400), Vector2(RIGHT, 180),
			Vector2(LEFT, 180)]), PackedColorArray([top, top, mid, mid]))
	ci.draw_polygon(PackedVector2Array([Vector2(LEFT, 180), Vector2(RIGHT, 180), Vector2(RIGHT, 1300),
			Vector2(LEFT, 1300)]), PackedColorArray([mid, mid, low, low]))
	if night > 0.2:
		var shown := (night - 0.2) / 0.8
		for k in 90:
			var at := Vector2(-900.0 + Toon.hash01(k, 21) * 4600.0, -260.0 + Toon.hash01(k, 22) * 560.0)
			var twinkle := 0.35 + 0.65 * Toon.hash01(k, drawing / 4)
			ci.draw_circle(at, 1.5 + Toon.hash01(k, 23) * 2.2, Color(Toon.PAPER, twinkle * shown))
			if k % 11 == 0:
				var r := 7.0 + 4.0 * twinkle
				ci.draw_line(at - Vector2(r, 0), at + Vector2(r, 0), Color(Toon.PAPER, 0.6 * shown), 2.0)
				ci.draw_line(at - Vector2(0, r), at + Vector2(0, r), Color(Toon.PAPER, 0.6 * shown), 2.0)
	# The moon: pale in the dusk, bright at night, a few seas on its face.
	var moon := Vector2(1720, 120)
	var bright := lerpf(0.55, 1.0, night)
	Toon.glow(ci, moon, Vector2(260, 260), Color(1, 0.95, 0.8, 0.22 * bright), 3)
	Toon.blob(ci, moon, Vector2(78, 78), Color("f3e6c8").lerp(low, 1.0 - bright), 0, 3, 4.0)
	for k in 4:
		var at := moon + Vector2(-34.0 + Toon.hash01(k, 41) * 60.0, -30.0 + Toon.hash01(k, 42) * 56.0)
		Toon.spot(ci, at, Vector2(9, 7) * (0.8 + Toon.hash01(k, 43)), Color(0.6, 0.5, 0.4, 0.22))
	_skyline(ci, night)


## The far side of town against the sky: roofs, chimneys with smoke, a
## water tower, a dome with a spire, a factory stack.
static func _skyline(ci: CanvasItem, night: float) -> void:
	var dark := Color("6b4563").lerp(Color("1a2138"), night)
	var darker := dark.darkened(0.25)
	var x := LEFT
	var k := 0
	while x < RIGHT:
		var w := 150.0 + Toon.hash01(k, 61) * 170.0
		var top := 250.0 + Toon.hash01(k, 62) * 130.0
		var roof := PackedVector2Array([Vector2(x, 900), Vector2(x, top + 30), Vector2(x + w * 0.5, top - 20),
				Vector2(x + w, top + 30), Vector2(x + w, 900)])
		if Toon.hash01(k, 63) < 0.45:
			roof = PackedVector2Array([Vector2(x, 900), Vector2(x, top), Vector2(x + w, top), Vector2(x + w, 900)])
		ci.draw_colored_polygon(roof, dark)
		if Toon.hash01(k, 64) < 0.6:
			var cx := x + w * (0.2 + Toon.hash01(k, 65) * 0.6)
			ci.draw_rect(Rect2(cx, top - 50, 22, 70), dark)
			if night > 0.5 and Toon.hash01(k, 66) < 0.5:
				for s in 3:
					Toon.spot(ci, Vector2(cx + 11 + s * 16, top - 70 - s * 26), Vector2(14 + s * 5, 10 + s * 3),
							Color(dark.lightened(0.2), 0.5 - s * 0.12))
		for wy in 2:
			for wx in int(w / 60.0):
				if Toon.hash01(k * 13 + wx, wy + 70) < 0.22 * (0.3 + night):
					ci.draw_rect(Rect2(x + 20 + wx * 60, top + 50 + wy * 70, 14, 18), Color(1, 0.8, 0.45, 0.55))
		match k % 9:
			3:
				# A water tower on stilts.
				var tx := x + w * 0.5
				for leg: float in [-30.0, 30.0]:
					ci.draw_line(Vector2(tx + leg, top), Vector2(tx + leg * 0.6, top - 90), darker, 6.0)
				ci.draw_rect(Rect2(tx - 40, top - 170, 80, 86), darker)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 46, top - 170), Vector2(tx + 46, top - 170),
						Vector2(tx, top - 210)]), darker)
			6:
				# A dome with a spire.
				var dx := x + w * 0.5
				var dome := PackedVector2Array()
				for i in 17:
					var a := PI + PI * i / 16.0
					dome.append(Vector2(dx + cos(a) * 70.0, top + sin(a) * 70.0))
				ci.draw_colored_polygon(dome, darker)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(dx - 8, top - 66), Vector2(dx + 8, top - 66),
						Vector2(dx, top - 170)]), darker)
			8:
				# A factory stack.
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 30, top), Vector2(x + 70, top),
						Vector2(x + 62, top - 230), Vector2(x + 38, top - 230)]), darker)
		x += w - 6.0
		k += 1


# --- the street -------------------------------------------------------------------


## The street down to the kerb, every light in it out: houses, the alley,
## lamps, the pavement with the cellar hatch at [param hatch] in it.
static func street(ci: CanvasItem, night: float, hatch: Vector2, hatch_r: Vector2) -> void:
	_glazing.clear()
	for i in HOUSES.size():
		_house(ci, HOUSES[i], i, night)
	_alley(ci, night)
	_pavement(ci, night)
	_hatch(ci, hatch, hatch_r, night)
	for x in LAMPS:
		_lamp(ci, x, night)


## The street's lights, over [method street]: [param lights] runs from 1
## (every window that is lit tonight) down to 0 (all dark), each window
## going out at its own point of it; [param lamp] is how lit the gas lamps
## are. A layer of its own, so a light going out does not repaint the
## whole street.
static func lights(ci: CanvasItem, night: float, lights: float, lamp: float) -> void:
	for glass: Array in _glazing:
		var r: Rect2 = glass[1]
		var id: int = glass[2]
		match str(glass[0]):
			"pane":
				if _lit(id, lights):
					_halo(ci, r, 1.0)
					_pane(ci, r, id, night, true)
			"round":
				if _lit(id, lights):
					_halo(ci, r, 0.7)
					Toon.blob(ci, r.get_center(), r.size * 0.5, Color("f5c66a"), 0, id, 4.0)
					Toon.stroke(ci, PackedVector2Array([r.get_center() - Vector2(r.size.x * 0.45, 0),
							r.get_center() + Vector2(r.size.x * 0.45, 0)]), 3.0)
			"display":
				if _lit(id, lights) or _lit(id + 1, lights):
					var house: Dictionary = glass[3]
					_halo(ci, r, 1.4)
					ci.draw_rect(r, Color("f2c46e"))
					_wares(ci, r, str(house["sign"]), int(glass[4]), true)
					ci.draw_line(Vector2(r.position.x, r.end.y - 30), Vector2(r.end.x, r.end.y - 30), Color(Toon.INK, 0.6), 4.0)
					var door: Rect2 = glass[5]
					ci.draw_rect(door, Color("f2c46e"))
					# The awning hangs over the window's top: back over the light.
					_awning(ci, house, night)
	if lamp > 0.0:
		for x in LAMPS:
			_lamp_light(ci, x, lamp)


## A glow in a few soft steps, each a plain ellipse: [method Toon.glow]
## is smoother, but too dear to repaint every frame the lights change.
static func _soft(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, steps := 5) -> void:
	for k in steps:
		var r := radii * (1.0 - float(k) / steps)
		var points := PackedVector2Array()
		points.resize(32)
		for i in 32:
			var a := TAU * i / 32.0
			points[i] = center + Vector2(cos(a) * r.x, sin(a) * r.y)
		ci.draw_colored_polygon(points, Color(color, color.a / steps * 1.6))


## A warm halo round a lit window: a couple of soft steps of light.
static func _halo(ci: CanvasItem, r: Rect2, strength: float) -> void:
	ci.draw_rect(r.grow(30.0 * strength), Color(1, 0.8, 0.45, 0.05))
	ci.draw_rect(r.grow(16.0 * strength), Color(1, 0.8, 0.45, 0.08))


## The cobbled road below the kerb, with the open manhole at [param hole]:
## painted apart from the street, since the lights do not change it and
## its cobbles are the most of the drawing.
static func road(ci: CanvasItem, night: float, hole: Vector2, hole_r: Vector2) -> void:
	_road(ci, night, hole, hole_r)
	_manhole(ci, hole, hole_r, night)


static func _house(ci: CanvasItem, h: Dictionary, i: int, night: float) -> void:
	var x0 := float(h["x"])
	var w := float(h["w"])
	var floors := int(h["floors"])
	var top := WALL_BASE - GROUND_FLOOR - (floors - 1) * STOREY
	var wall := tint(Color(str(h["wall"])), night)
	var roofing := tint(Color("5b3b34") if i % 2 == 0 else Color("47505f"), night)
	# The roof, behind the top of the wall.
	match str(h["roof"]):
		"gable":
			var gable := PackedVector2Array([Vector2(x0 - 16, top + 4), Vector2(x0 + w * 0.5, top - 150),
					Vector2(x0 + w + 16, top + 4)])
			Toon.shape(ci, gable, roofing, Toon.LINE)
			for row in 4:
				var y := top - 26.0 - row * 32.0
				var half := (w * 0.5 + 16.0) * (1.0 - (top - y) / 154.0)
				Toon.hand_line(ci, Vector2(x0 + w * 0.5 - half + 8, y), Vector2(x0 + w * 0.5 + half - 8, y), 2.5,
						i * 10 + row, Color(Toon.INK, 0.45))
			# A round window in the gable.
			Toon.blob(ci, Vector2(x0 + w * 0.5, top - 56), Vector2(22, 22), _dark_glass(night), 0, i, 4.0)
			_glazing.append(["round", Rect2(x0 + w * 0.5 - 22, top - 78, 44, 44), i * 7 + 99])
			Toon.stroke(ci, PackedVector2Array([Vector2(x0 + w * 0.5 - 20, top - 56), Vector2(x0 + w * 0.5 + 20, top - 56)]), 3.0)
		"mansard":
			var mansard := PackedVector2Array([Vector2(x0 - 10, top + 4), Vector2(x0 + 36, top - 100),
					Vector2(x0 + w - 36, top - 100), Vector2(x0 + w + 10, top + 4)])
			Toon.shape(ci, mansard, roofing, Toon.LINE)
			for k in int((w - 80.0) / 26.0):
				var sx := x0 + 44.0 + k * 26.0
				ci.draw_line(Vector2(sx, top - 96), Vector2(sx + (sx - x0 - w * 0.5) * 0.06, top), Color(Toon.INK, 0.25), 2.0)
			# A dormer.
			var dx := x0 + w * 0.5
			Toon.shape(ci, PackedVector2Array([Vector2(dx - 44, top - 6), Vector2(dx - 44, top - 74),
					Vector2(dx, top - 110), Vector2(dx + 44, top - 74), Vector2(dx + 44, top - 6)]), wall, 4.0)
			_glaze(ci, Rect2(dx - 24, top - 72, 48, 60), i * 7 + 98, night)
		_:
			ci.draw_rect(Rect2(x0 - 8, top - 26, w + 16, 30), Toon.INK)
			ci.draw_rect(Rect2(x0 - 4, top - 22, w + 8, 22), wall.darkened(0.18))
	# A chimney or two.
	for c in (2 if w > 410.0 else 1):
		var cx := x0 + w * (0.22 + 0.5 * c + Toon.hash01(i, 3 + c) * 0.12)
		var ctop := top - (150.0 if str(h["roof"]) == "gable" else 110.0) + absf(cx - x0 - w * 0.5) * (
				0.9 if str(h["roof"]) == "gable" else 0.0)
		var stack := Rect2(cx - 20, ctop - 40, 40, top - ctop + 40)
		ci.draw_rect(stack.grow(4), Toon.INK)
		ci.draw_rect(stack, tint(Color("8c4a34"), night))
		ci.draw_rect(Rect2(cx - 26, ctop - 50, 52, 14).grow(4), Toon.INK)
		ci.draw_rect(Rect2(cx - 26, ctop - 50, 52, 14), tint(Color("6f3a2a"), night))
		for pot in 2:
			ci.draw_rect(Rect2(cx - 15 + pot * 18, ctop - 70, 12, 22).grow(3), Toon.INK)
			ci.draw_rect(Rect2(cx - 15 + pot * 18, ctop - 70, 12, 22), tint(Color("a8603e"), night))
	# The wall, shaded on the side away from the light.
	var body := Rect2(x0, top, w, WALL_BASE - top)
	ci.draw_rect(body.grow(4), Toon.INK)
	ci.draw_rect(body, wall)
	ci.draw_rect(Rect2(x0 + w - 26, top, 26, WALL_BASE - top), wall.darkened(0.12))
	# The cornice: a darker band with teeth under it.
	ci.draw_rect(Rect2(x0 - 6, top, w + 12, 20), Toon.INK)
	ci.draw_rect(Rect2(x0 - 3, top + 3, w + 6, 14), wall.darkened(0.22))
	for k in int(w / 22.0):
		ci.draw_rect(Rect2(x0 + 6 + k * 22, top + 20, 10, 9), wall.darkened(0.3))
	# A ledge between each two storeys.
	for f in floors - 1:
		var y := WALL_BASE - GROUND_FLOOR - f * STOREY
		ci.draw_rect(Rect2(x0 - 4, y - 4, w + 8, 12), Toon.INK)
		ci.draw_rect(Rect2(x0 - 2, y - 2, w + 4, 7), wall.lightened(0.12))
	if str(h["wall"]) == "b5653f":
		_bricks(ci, x0, top, w, i, wall)
	else:
		_cracks(ci, x0, top, w, i)
	# The windows of the upper storeys.
	for f in range(1, floors):
		var storey_top := WALL_BASE - GROUND_FLOOR - f * STOREY
		var n := maxi(1, int(w / 135.0))
		for k in n:
			var cx := x0 + (w - 26.0) * (k + 0.5) / n
			_window(ci, Vector2(cx, storey_top + STOREY * 0.5 + 8), i * 31 + f * 7 + k, night, f == 1)
	match str(h["ground"]):
		"shop":
			_shop(ci, h, i, night)
		"poster":
			_door(ci, Vector2(x0 + w * 0.28, WALL_BASE), i, night)
			_wanted(ci, Vector2(x0 + w * 0.68, 560), night)
		_:
			_door(ci, Vector2(x0 + w * 0.3, WALL_BASE), i, night)
			_window(ci, Vector2(x0 + w * 0.72, WALL_BASE - GROUND_FLOOR * 0.52), i * 31 + 3, night, false)
	# A drainpipe down the corner.
	var px := x0 + w - 12.0
	Toon.stroke(ci, PackedVector2Array([Vector2(px, top + 26), Vector2(px, WALL_BASE)]), 13.0)
	Toon.stroke(ci, PackedVector2Array([Vector2(px, top + 26), Vector2(px, WALL_BASE)]), 6.0, tint(Color("6d6a70"), night))
	for k in floors + 1:
		ci.draw_rect(Rect2(px - 9, top + 60 + k * 170, 18, 8), Toon.INK)


## A few patches of bricks drawn in, the way a background painter hints
## at a brick wall instead of painting every one.
static func _bricks(ci: CanvasItem, x0: float, top: float, w: float, i: int, wall: Color) -> void:
	for patch in 3:
		var at := Vector2(x0 + 30.0 + Toon.hash01(i, 10 + patch) * (w - 120.0),
				top + 60.0 + Toon.hash01(i, 20 + patch) * (WALL_BASE - top - 160.0))
		for row in 3:
			for col in 3 - row % 2:
				var b := Rect2(at + Vector2(col * 34.0 + (17.0 if row % 2 == 1 else 0.0), row * 17.0), Vector2(30, 13))
				if Toon.hash01(i * 7 + patch, row * 5 + col) < 0.75:
					ci.draw_rect(b, wall.darkened(0.1))
					ci.draw_rect(b, Color(Toon.INK, 0.5), false, 2.0)


static func _cracks(ci: CanvasItem, x0: float, top: float, w: float, i: int) -> void:
	for k in 2:
		var at := Vector2(x0 + 40.0 + Toon.hash01(i, 30 + k) * (w - 80.0), top + 80.0 + Toon.hash01(i, 40 + k) * 250.0)
		var points := PackedVector2Array([at])
		for s in 4:
			at += Vector2((Toon.hash01(i * 3 + k, s) - 0.5) * 26.0, 14.0 + Toon.hash01(k, s + i) * 12.0)
			points.append(at)
		Toon.stroke(ci, points, 2.2, Color(Toon.INK, 0.4))


## Unlit glass: the dark of the sky in it.
static func _dark_glass(night: float) -> Color:
	return tint(Color("44506e"), night)


## Whether window [param id] is lit: about two in three are tonight, and as
## [param lights] goes down they go out one by one.
static func _lit(id: int, lights: float) -> bool:
	return Toon.hash01(id, 5) < 0.66 * lights


## Dark glass in a frame, noted down for [method lights].
static func _glaze(ci: CanvasItem, glass: Rect2, id: int, night: float) -> void:
	_pane(ci, glass, id, night, false)
	_glazing.append(["pane", glass, id])


## Glass in a frame: lit, with curtains, or dark with the sky's glint
## across it; a cross of glazing bars.
static func _pane(ci: CanvasItem, glass: Rect2, id: int, night: float, lit: bool) -> void:
	ci.draw_rect(glass.grow(4), Toon.INK)
	ci.draw_rect(glass, Color("f5c66a") if lit else _dark_glass(night))
	if lit:
		ci.draw_rect(Rect2(glass.position + Vector2(glass.size.x * 0.25, glass.size.y * 0.2), glass.size * Vector2(0.5, 0.5)),
				Color(1, 0.95, 0.75, 0.5))
		# Curtains, tied back.
		var drape := Color("b8483c")
		for side: float in [0.0, 1.0]:
			var edge := glass.position.x + glass.size.x * side
			var inward := 1.0 - side * 2.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(edge, glass.position.y),
					Vector2(edge + inward * glass.size.x * 0.34, glass.position.y),
					Vector2(edge + inward * glass.size.x * 0.1, glass.position.y + glass.size.y * 0.6),
					Vector2(edge, glass.end.y)]), drape)
	else:
		for k in 2:
			var a := glass.position + Vector2(glass.size.x * (0.2 + k * 0.25), glass.size.y * 0.15)
			ci.draw_line(a, a + Vector2(glass.size.x * 0.3, glass.size.y * 0.3), Color(1, 1, 1, 0.18), 4.0)
	ci.draw_line(Vector2(glass.get_center().x, glass.position.y), Vector2(glass.get_center().x, glass.end.y), Toon.INK, 4.0)
	ci.draw_line(Vector2(glass.position.x, glass.position.y + glass.size.y * 0.42),
			Vector2(glass.end.x, glass.position.y + glass.size.y * 0.42), Toon.INK, 4.0)


## A window centred on [param c]: shutters on some, a frame, a sill and,
## on the first floor, a box of flowers on some.
static func _window(ci: CanvasItem, c: Vector2, id: int, night: float, flowers: bool) -> void:
	var size := Vector2(64, 100)
	var trim := tint(Color("eadcc0"), night)
	if Toon.hash01(id, 6) < 0.45:
		var shutter := tint(Color("4f6b45") if Toon.hash01(id, 7) < 0.5 else Color("3f5f8a"), night)
		for side: float in [-1.0, 1.0]:
			var r := Rect2(c + Vector2(side * (size.x * 0.5 + 12.0) - 17.0, -size.y * 0.5 - 6.0), Vector2(34, size.y + 12))
			ci.draw_rect(r.grow(3), Toon.INK)
			ci.draw_rect(r, shutter)
			for k in 6:
				var y := r.position.y + 10.0 + k * 17.0
				ci.draw_line(Vector2(r.position.x + 5, y), Vector2(r.end.x - 5, y), Color(Toon.INK, 0.45), 2.0)
	var frame := Rect2(c - size * 0.5 - Vector2(10, 10), size + Vector2(20, 20))
	ci.draw_rect(frame.grow(4), Toon.INK)
	ci.draw_rect(frame, trim)
	_glaze(ci, Rect2(c - size * 0.5, size), id, night)
	# A lintel over it and a sill under it.
	ci.draw_rect(Rect2(c.x - size.x * 0.5 - 16, frame.position.y - 12, size.x + 32, 12).grow(3), Toon.INK)
	ci.draw_rect(Rect2(c.x - size.x * 0.5 - 16, frame.position.y - 12, size.x + 32, 12), trim.darkened(0.08))
	var sill := Rect2(c.x - size.x * 0.5 - 14, frame.end.y, size.x + 28, 10)
	ci.draw_rect(sill.grow(3), Toon.INK)
	ci.draw_rect(sill, trim.darkened(0.15))
	if flowers and Toon.hash01(id, 8) < 0.4:
		var box := Rect2(c.x - size.x * 0.5 - 6, sill.end.y + 2, size.x + 12, 22)
		for k in 7:
			var at := Vector2(box.position.x + 8 + k * (box.size.x - 16) / 6.0, box.position.y - 6 - Toon.hash01(id, k) * 8.0)
			Toon.spot(ci, at + Vector2(0, 6), Vector2(9, 6), tint(Color("4f7a3a"), night))
			Toon.blob(ci, at, Vector2(6, 6), tint(Color("d8412f") if k % 2 == 0 else Color("e8b83a"), night), 0, id + k, 2.5)
		ci.draw_rect(box.grow(3), Toon.INK)
		ci.draw_rect(box, tint(Color("7a4c2c"), night))


## A front door with its foot at [param foot]: an arch over it, panels, a
## brass knob and number, a step.
static func _door(ci: CanvasItem, foot: Vector2, i: int, night: float) -> void:
	var wood := tint(Color("6b4428") if i % 3 != 1 else Color("3f5f4a"), night)
	var r := Rect2(foot.x - 48, foot.y - 196, 96, 196)
	var arch := PackedVector2Array([r.end, Vector2(r.end.x, r.position.y)])
	for k in 13:
		var a := PI * k / 12.0
		arch.append(Vector2(r.get_center().x + cos(a) * 48.0, r.position.y - sin(a) * 30.0))
	arch.append(Vector2(r.position.x, r.end.y))
	var stone := tint(Color("d9c9a6"), night)
	Toon.shape(ci, Toon.grown(arch, 12.0), stone, 4.0)
	Toon.shape(ci, arch, wood, 4.0)
	for row in 2:
		for col in 2:
			var p := Rect2(r.position + Vector2(12 + col * 40, 24 + row * 86), Vector2(32, 70))
			ci.draw_rect(p, wood.darkened(0.2))
			ci.draw_rect(p, Color(Toon.INK, 0.6), false, 2.5)
	Toon.blob(ci, Vector2(r.end.x - 16, r.position.y + 110), Vector2(6, 6), Color("e0b23a"), 0, i, 2.5)
	ci.draw_rect(Rect2(r.get_center().x - 14, r.position.y - 26, 28, 18).grow(3), Toon.INK)
	ci.draw_rect(Rect2(r.get_center().x - 14, r.position.y - 26, 28, 18), Color("e0b23a").darkened(0.1))
	var step := Rect2(foot.x - 66, foot.y - 4, 132, 16)
	ci.draw_rect(step.grow(3), Toon.INK)
	ci.draw_rect(step, stone.darkened(0.1))


## A shop front: its name on a board, a striped awning with a scalloped
## edge, a lit window full of what it sells, a glazed door.
static func _shop(ci: CanvasItem, h: Dictionary, i: int, night: float) -> void:
	var x0 := float(h["x"])
	var w := float(h["w"])
	var name := str(h["sign"])
	var top := WALL_BASE - GROUND_FLOOR
	# The board.
	var board := Rect2(x0 + w * 0.08, top + 14, w * 0.84 - 26.0, 54)
	ci.draw_rect(board.grow(5), Toon.INK)
	ci.draw_rect(board, tint(Color("2c2220"), night))
	ci.draw_rect(board.grow(-6), Color("e0b23a").darkened(0.15 + 0.2 * night), false, 2.0)
	var font := Ui.font()
	ci.draw_string(font, Vector2(board.position.x, board.position.y + 40), name, HORIZONTAL_ALIGNMENT_CENTER,
			board.size.x, 34, Color("f3d58a").lerp(Color("c9b27a"), night * 0.4))
	# The window and the door under the awning.
	var display := Rect2(x0 + 22, top + 120, w * 0.6, WALL_BASE - top - 140)
	ci.draw_rect(display.grow(12), Toon.INK)
	ci.draw_rect(display.grow(8), tint(Color("3b2a22"), night))
	ci.draw_rect(display, tint(Color("3a4560"), night))
	_wares(ci, display, name, i, false)
	ci.draw_line(Vector2(display.position.x, display.end.y - 30), Vector2(display.end.x, display.end.y - 30),
			Color(Toon.INK, 0.6), 4.0)
	var door := Rect2(display.end.x + 30, WALL_BASE - 190, 84, 190)
	ci.draw_rect(door.grow(4), Toon.INK)
	ci.draw_rect(door, tint(Color("5a3a24"), night))
	var pane := Rect2(door.position + Vector2(12, 14), Vector2(60, 84))
	ci.draw_rect(pane.grow(3), Toon.INK)
	ci.draw_rect(pane, tint(Color("3a4560"), night))
	_glazing.append(["display", display, i * 31 + 77, h, i, pane])
	Toon.blob(ci, Vector2(door.end.x - 14, door.position.y + 110), Vector2(5, 5), Color("e0b23a"), 0, i, 2.5)
	if name == "ЦИРЮЛЬНЯ":
		_barber_pole(ci, Vector2(door.end.x + 30, WALL_BASE - 120), night)
	_awning(ci, h, night)


## A shop's awning: stripes, sloping out over the pavement, scalloped.
static func _awning(ci: CanvasItem, h: Dictionary, night: float) -> void:
	var x0 := float(h["x"])
	var w := float(h["w"])
	var top := WALL_BASE - GROUND_FLOOR
	var a0 := top + 76.0
	var a1 := top + 128.0
	var left := x0 + 6.0
	var right := x0 + w - 32.0
	var stripe := tint(Color(str(h["awning"])), night)
	var cream := tint(Color("efe2c4"), night)
	var n := int((right - left) / 34.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(left - 4, a0 - 4), Vector2(right + 4, a0 - 4),
			Vector2(right + 18, a1 + 4), Vector2(left - 18, a1 + 4)]), Toon.INK)
	for k in n:
		var u0 := float(k) / n
		var u1 := float(k + 1) / n
		ci.draw_colored_polygon(PackedVector2Array([Vector2(left + (right - left) * u0, a0),
				Vector2(left + (right - left) * u1, a0),
				Vector2(left - 14 + (right - left + 28) * u1, a1),
				Vector2(left - 14 + (right - left + 28) * u0, a1)]), stripe if k % 2 == 0 else cream)
	var scallop := (right - left + 28.0) / n
	for k in n:
		var cx := left - 14.0 + scallop * (k + 0.5)
		var points := PackedVector2Array()
		for s in 9:
			var a := PI * s / 8.0
			points.append(Vector2(cx + cos(a) * scallop * 0.5, a1 + sin(a) * 14.0))
		ci.draw_colored_polygon(Toon.grown(points, 3.0), Toon.INK)
		ci.draw_colored_polygon(points, stripe if k % 2 == 0 else cream)
	ci.draw_rect(Rect2(left, a0 + (a1 - a0) * 0.5, right - left, 6), Color(0, 0, 0, 0.12))


## What is in a shop's window, by its name.
static func _wares(ci: CanvasItem, display: Rect2, name: String, i: int, lit: bool) -> void:
	var shade := 0.0 if lit else 0.45
	var shelf := display.end.y - 34.0
	var count := int(display.size.x / 52.0)
	for k in count:
		var x := display.position.x + 30.0 + k * (display.size.x - 60.0) / maxf(count - 1, 1)
		match name:
			"ПЕКАРНЯ":
				Toon.blob(ci, Vector2(x, shelf - 14), Vector2(22, 13), Color("c98a44").darkened(shade), 0, i + k, 3.0)
				for c in 3:
					ci.draw_line(Vector2(x - 10 + c * 9, shelf - 22), Vector2(x - 4 + c * 9, shelf - 8),
							Color(Toon.INK, 0.5), 2.0)
				if k % 2 == 0:
					Toon.blob(ci, Vector2(x + 6, shelf - 52), Vector2(14, 12), Color("e0b070").darkened(shade), 0, i + k + 9, 3.0)
			"ЦВЕТЫ":
				ci.draw_rect(Rect2(x - 12, shelf - 24, 24, 24), Color("b35a3a").darkened(shade))
				for f in 3:
					var at := Vector2(x - 12 + f * 12, shelf - 44 - (f % 2) * 12)
					Toon.blob(ci, at, Vector2(8, 8), [Color("d8412f"), Color("e8b83a"), Color("d07ab0")][f].darkened(shade),
							0, i + k + f, 2.5)
			"КАФЕ":
				# A cake on a stand, cups.
				if k % 2 == 0:
					Toon.blob(ci, Vector2(x, shelf - 22), Vector2(22, 16), Color("f0d9b0").darkened(shade), 0, i + k, 3.0)
					Toon.blob(ci, Vector2(x, shelf - 40), Vector2(5, 5), Color("c8392b"), 0, i + k + 3, 2.0)
				else:
					Toon.box(ci, Vector2(x, shelf - 12), Vector2(10, 11), Color("f7f0e1").darkened(shade), 0, i + k, 3.0)
			"ЦИРЮЛЬНЯ":
				if k % 2 == 0:
					ci.draw_rect(Rect2(x - 6, shelf - 40, 12, 40), Color("3f6fb5").darkened(shade))
					Toon.blob(ci, Vector2(x, shelf - 46), Vector2(9, 7), Color("f7f0e1").darkened(shade), 0, i + k, 2.5)
				else:
					Toon.blob(ci, Vector2(x, shelf - 20), Vector2(12, 18), Color("8a5a36").darkened(shade), 0, i + k, 2.5)
			_:
				# Film posters.
				if k % 2 == 0:
					var r := Rect2(x - 22, display.position.y + 14, 44, 60)
					ci.draw_rect(r.grow(3), Toon.INK)
					ci.draw_rect(r, Color("efe2c4").darkened(shade))
					Toon.blob(ci, r.get_center(), Vector2(12, 12), Toon.INK, 0, k, 2.0)
					Toon.spot(ci, r.get_center() + Vector2(0, 5), Vector2(8, 5), Color("f7f0e1"))
	ci.draw_line(Vector2(display.position.x, shelf), Vector2(display.end.x, shelf), Color(Toon.INK, 0.7), 4.0)


static func _barber_pole(ci: CanvasItem, at: Vector2, night: float) -> void:
	var r := Rect2(at.x - 11, at.y - 70, 22, 140)
	ci.draw_rect(r.grow(4), Toon.INK)
	ci.draw_rect(r, tint(Color("f7f0e1"), night))
	for k in 6:
		var y := r.position.y + k * 26.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, y + 10), Vector2(r.end.x, y),
				Vector2(r.end.x, y + 10), Vector2(r.position.x, y + 20)]), tint(Color("c8392b"), night))
	Toon.blob(ci, Vector2(at.x, r.position.y - 8), Vector2(14, 10), Color("e0b23a"), 0, 1, 3.0)
	Toon.blob(ci, Vector2(at.x, r.end.y + 8), Vector2(14, 10), Color("e0b23a"), 0, 2, 3.0)


## A "wanted" poster pasted on a wall: the Baron's face, his name, a
## reward, one corner torn and curling.
static func _wanted(ci: CanvasItem, at: Vector2, night: float) -> void:
	var paper := tint(Color("efe2c4"), night)
	var r := Rect2(at - Vector2(72, 96), Vector2(144, 192))
	var corners := PackedVector2Array([r.position, Vector2(r.end.x - 24, r.position.y), Vector2(r.end.x, r.position.y + 22),
			r.end, Vector2(r.position.x, r.end.y)])
	Toon.shape(ci, corners, paper, 4.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(r.end.x - 24, r.position.y), Vector2(r.end.x, r.position.y + 22),
			Vector2(r.end.x - 20, r.position.y + 18)]), paper.darkened(0.2))
	var font := Ui.font()
	var ink := tint(Color("3a2218"), night)
	ci.draw_string(font, Vector2(r.position.x, r.position.y + 30), "РАЗЫСКИВАЕТСЯ", HORIZONTAL_ALIGNMENT_CENTER,
			r.size.x, 15, ink)
	var face := r.get_center() + Vector2(0, -2)
	var fur := tint(BaronBoss.FUR, night)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(ci, PackedVector2Array([face + Vector2(sx * 30, -8), face + Vector2(sx * 12, -30),
				face + Vector2(sx * 32, -40)]), fur, 3.0)
	Toon.blob(ci, face, Vector2(34, 28), fur, 0, 7, 3.5)
	Toon.blob(ci, face + Vector2(0, 10), Vector2(20, 13), tint(BaronBoss.MUZZLE, night), 0, 8, 2.5)
	for sx: float in [-1.0, 1.0]:
		Toon.spot(ci, face + Vector2(sx * 12, -6), Vector2(4, 5), Toon.INK)
	ci.draw_arc(face + Vector2(12, -6), 9.0, 0.0, TAU, 16, Color("e0b23a"), 2.5)
	ci.draw_rect(Rect2(face + Vector2(-20, -66), Vector2(40, 34)), Toon.INK)
	ci.draw_rect(Rect2(face + Vector2(-30, -36), Vector2(60, 7)), Toon.INK)
	ci.draw_string(font, Vector2(r.position.x, r.end.y - 34), "БАРОН КОГТЕВ", HORIZONTAL_ALIGNMENT_CENTER,
			r.size.x, 15, ink)
	ci.draw_string(font, Vector2(r.position.x, r.end.y - 12), "награда 100 р.", HORIZONTAL_ALIGNMENT_CENTER,
			r.size.x, 13, tint(Color("a83a2b"), night))


static func _alley(ci: CanvasItem, night: float) -> void:
	var r := Rect2(ALLEY.x + 4, 140, ALLEY.y - ALLEY.x - 8, WALL_BASE - 140)
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
			PackedColorArray([tint(Color("2a2030"), night), tint(Color("2a2030"), night), Color("0c090c"), Color("0c090c")]))
	# A dustbin in the dark.
	var bin := Rect2(ALLEY.x + 24, WALL_BASE - 70, 52, 70)
	ci.draw_rect(bin.grow(3), Toon.INK)
	ci.draw_rect(bin, tint(Color("3a3a40"), night))
	Toon.box(ci, Vector2(bin.get_center().x, bin.position.y - 2), Vector2(32, 7), tint(Color("4a4a52"), night), 0, 5, 3.0)


static func _pavement(ci: CanvasItem, night: float) -> void:
	var stone := tint(Color("a0917c"), night)
	ci.draw_rect(Rect2(LEFT, WALL_BASE, RIGHT - LEFT, CURB - WALL_BASE), stone)
	# Shadow at the foot of the houses.
	ci.draw_polygon(PackedVector2Array([Vector2(LEFT, WALL_BASE), Vector2(RIGHT, WALL_BASE), Vector2(RIGHT, WALL_BASE + 26),
			Vector2(LEFT, WALL_BASE + 26)]), PackedColorArray([Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0),
			Color(0, 0, 0, 0)]))
	var joint := Color(Toon.INK, 0.35)
	ci.draw_line(Vector2(LEFT, 786), Vector2(RIGHT, 786), joint, 2.5)
	var x := LEFT
	var k := 0
	while x < RIGHT:
		ci.draw_line(Vector2(x, WALL_BASE + 2), Vector2(x - 18, 786), joint, 2.5)
		ci.draw_line(Vector2(x - 18 + 60, 786), Vector2(x - 40 + 60, CURB), joint, 2.5)
		if Toon.hash01(k, 51) < 0.2:
			Toon.stroke(ci, PackedVector2Array([Vector2(x + 20, 740), Vector2(x + 38, 752), Vector2(x + 34, 766)]), 2.0,
					Color(Toon.INK, 0.3))
		x += 130.0
		k += 1
	# The kerb.
	ci.draw_rect(Rect2(LEFT, CURB, RIGHT - LEFT, ROAD - CURB), tint(Color("c4b69c"), night))
	Toon.hand_line(ci, Vector2(LEFT, CURB), Vector2(RIGHT, CURB), 4.0, 81)
	Toon.hand_line(ci, Vector2(LEFT, ROAD), Vector2(RIGHT, ROAD), 4.0, 82)
	x = LEFT + 40.0
	while x < RIGHT:
		ci.draw_line(Vector2(x, CURB + 3), Vector2(x - 4, ROAD - 3), Color(Toon.INK, 0.4), 2.5)
		x += 190.0


static func _road(ci: CanvasItem, night: float, hole: Vector2, hole_r: Vector2) -> void:
	var road := tint(Color("5d5148"), night)
	ci.draw_rect(Rect2(LEFT, ROAD, RIGHT - LEFT, 600), road)
	ci.draw_polygon(PackedVector2Array([Vector2(LEFT, ROAD), Vector2(RIGHT, ROAD), Vector2(RIGHT, ROAD + 30),
			Vector2(LEFT, ROAD + 30)]), PackedColorArray([Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0),
			Color(0, 0, 0, 0)]))
	var edge := road.darkened(0.35)
	var y := ROAD + 16.0
	var row := 0
	while y < 1220.0:
		var size := Vector2(26.0 + row * 3.0, 9.0 + row * 1.6)
		var step := size.x * 2.0 + 10.0
		var x := LEFT + (step * 0.5 if row % 2 == 1 else 0.0)
		var k := 0
		while x < RIGHT:
			var at := Vector2(x, y)
			var d := (at - hole) / (hole_r + Vector2(40, 18))
			if d.length() > 1.0:
				var fill := road.lightened(0.05 + Toon.hash01(k, row) * 0.08)
				ci.draw_colored_polygon(Toon.ellipse_points(at, size + Vector2(2.5, 2.5), 0, k * 7 + row, 0.0, 0.0, 0.8, 4.0), edge)
				ci.draw_colored_polygon(Toon.ellipse_points(at, size, 0, k * 7 + row, 0.0, 0.0, 0.8, 4.0), fill)
			x += step
			k += 1
		y += size.y * 2.0 + 6.0
		row += 1


## The manhole without its cover: an iron rim, the black of the shaft, the
## top rungs of a ladder going down into it.
static func _manhole(ci: CanvasItem, at: Vector2, r: Vector2, night: float) -> void:
	var iron := tint(Color("4a4850"), night)
	Toon.blob(ci, at, r + Vector2(16, 7), iron, 0, 11, Toon.LINE)
	Toon.blob(ci, at, r, Color("070506"), 0, 12, 3.0)
	for x: float in [-0.3, 0.3]:
		ci.draw_line(at + Vector2(x * r.x, -r.y * 0.75), at + Vector2(x * r.x, r.y * 0.3), Color(0.2, 0.18, 0.2), 5.0)
	for k in 2:
		var y := at.y - r.y * 0.55 + k * 16.0
		ci.draw_line(Vector2(at.x - 0.3 * r.x, y), Vector2(at.x + 0.3 * r.x, y), Color(0.2, 0.18, 0.2), 4.0)


## The manhole cover at [param at], lying flat when [param flip] is 0 and
## turned up on edge or over as it goes up: an iron disc with a ring and a
## grid on it, and the thickness of its edge.
static func lid(ci: CanvasItem, at: Vector2, r: Vector2, flip: float, tilt: float, night: float) -> void:
	var up := absf(sin(flip))
	var radii := Vector2(r.x, lerpf(r.y, r.x * 0.95, up))
	var face_up := cos(flip) >= 0.0
	var iron := tint(Color("6a6670"), night)
	var dark := iron.darkened(0.4)
	Toon.blob(ci, at + Vector2(0, 9), radii, dark, 0, 21, Toon.LINE, tilt)
	Toon.blob(ci, at, radii, iron if face_up else iron.darkened(0.15), 0, 22, Toon.LINE, tilt)
	Toon.blob(ci, at, radii * 0.7, iron.darkened(0.1), 0, 23, 3.0, tilt)
	for k in 5:
		var u := (k - 2) / 2.6
		var a := at + Vector2(u * radii.x * 0.8, -radii.y * 0.42 * sqrt(1.0 - u * u * 0.5)).rotated(0.0)
		var b := at + Vector2(u * radii.x * 0.8, radii.y * 0.42 * sqrt(1.0 - u * u * 0.5))
		ci.draw_line((a - at).rotated(tilt) + at, (b - at).rotated(tilt) + at, Color(Toon.INK, 0.45), 3.0)
	Toon.spot(ci, at + Vector2(-radii.x * 0.35, -radii.y * 0.4).rotated(tilt), radii * Vector2(0.2, 0.1),
			Color(1, 1, 1, 0.18), 0, 0, tilt)


## The cellar hatch: an opening in the pavement, its two doors thrown open
## flat either side, steps going down into the black, and a sign on a post.
static func _hatch(ci: CanvasItem, at: Vector2, r: Vector2, night: float) -> void:
	var wood := tint(Color("7a4c2c"), night)
	var far := r.x * 0.86
	var hole := PackedVector2Array([at + Vector2(-far, -r.y), at + Vector2(far, -r.y), at + Vector2(r.x, r.y),
			at + Vector2(-r.x, r.y)])
	Toon.shape(ci, Toon.grown(hole, 10.0), tint(Color("8a7a66"), night), 4.0)
	Toon.shape(ci, hole, Color("060404"), 5.0)
	for step in 3:
		var y := at.y - r.y + 10.0 + step * 13.0
		ci.draw_line(Vector2(at.x - far + 14 + step * 6, y), Vector2(at.x + far - 14 - step * 6, y), Color(1, 1, 1, 0.07), 6.0)
	for side: float in [-1.0, 1.0]:
		var hinge_far := at + Vector2(side * far, -r.y)
		var hinge_near := at + Vector2(side * r.x, r.y)
		var door := PackedVector2Array([hinge_far, hinge_far + Vector2(side * 140, -6), hinge_near + Vector2(side * 150, -2),
				hinge_near])
		Toon.shape(ci, door, wood, 5.0)
		for plank in 3:
			var u := (plank + 1) / 4.0
			ci.draw_line(door[0].lerp(door[3], u), door[1].lerp(door[2], u), Color(0, 0, 0, 0.35), 3.0)
		for hinge in 2:
			var h := door[0].lerp(door[3], 0.25 + hinge * 0.5)
			ci.draw_line(h, h + Vector2(side * 40, 0), Color(0.2, 0.2, 0.22), 5.0)
	# The sign.
	var post := Vector2(at.x + 250, WALL_BASE + 40)
	Toon.stroke(ci, PackedVector2Array([post, post + Vector2(0, -250)]), 14.0)
	Toon.stroke(ci, PackedVector2Array([post, post + Vector2(0, -250)]), 7.0, wood)
	var board := Rect2(post + Vector2(-120, -300), Vector2(240, 74))
	ci.draw_rect(board.grow(6), Toon.INK)
	ci.draw_rect(board, tint(Color("d4ba86"), night))
	ci.draw_string(Ui.font(), board.position + Vector2(0, 52), "ПОДВАЛ", HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 42,
			Toon.INK)
	# An arrow pointing down at the hatch.
	var arrow := PackedVector2Array([post + Vector2(-140, -190), post + Vector2(-60, -190), post + Vector2(-60, -210),
			post + Vector2(-20, -170), post + Vector2(-60, -130), post + Vector2(-60, -150), post + Vector2(-140, -150)])
	var pointing := PackedVector2Array()
	for p in arrow:
		pointing.append(post + (p - post).rotated(PI) + Vector2(-60, -340))
	Toon.shape(ci, pointing, tint(Color("c8392b"), night), 4.0)


## A gas lamp on the pavement, unlit: an iron post, a crossbar, a lantern.
static func _lamp(ci: CanvasItem, x: float, night: float) -> void:
	var foot := Vector2(x, WALL_BASE + 50)
	var iron := tint(Color("2e2c34"), night)
	var top := Vector2(x, LAMP_TOP)
	Toon.shape(ci, PackedVector2Array([foot + Vector2(-26, 0), foot + Vector2(26, 0), foot + Vector2(12, -40),
			foot + Vector2(-12, -40)]), iron, 4.0)
	Toon.stroke(ci, PackedVector2Array([foot, top + Vector2(0, 40)]), 16.0)
	Toon.stroke(ci, PackedVector2Array([foot, top + Vector2(0, 40)]), 8.0, iron)
	for k in 3:
		ci.draw_line(foot + Vector2(-7, -60 - k * 120), foot + Vector2(7, -60 - k * 120), Toon.INK, 5.0)
	Toon.stroke(ci, PackedVector2Array([top + Vector2(-34, 56), top + Vector2(34, 56)]), 7.0)
	var glass := PackedVector2Array([top + Vector2(-26, -26), top + Vector2(26, -26), top + Vector2(18, 40),
			top + Vector2(-18, 40)])
	Toon.shape(ci, glass, tint(Color("3a4258"), night), 5.0)
	ci.draw_line(top + Vector2(0, -26), top + Vector2(0, 40), Toon.INK, 3.0)
	Toon.shape(ci, PackedVector2Array([top + Vector2(-38, -24), top + Vector2(38, -24), top + Vector2(0, -62)]), iron, 4.0)
	Toon.blob(ci, top + Vector2(0, -66), Vector2(7, 7), iron, 0, int(x), 3.0)


## The lamp at [param x] lit, [param lamp] of the way: the glow round the
## lantern, its glass alight, a pool of light on the pavement.
static func _lamp_light(ci: CanvasItem, x: float, lamp: float) -> void:
	var top := Vector2(x, LAMP_TOP)
	_soft(ci, Vector2(x, 790), Vector2(280, 72), Color(1, 0.82, 0.5, 0.26 * lamp), 6)
	_soft(ci, top + Vector2(0, 6), Vector2(160, 160), Color(1, 0.85, 0.5, 0.26 * lamp), 6)
	var glass := PackedVector2Array([top + Vector2(-23, -23), top + Vector2(23, -23), top + Vector2(15, 37),
			top + Vector2(-15, 37)])
	ci.draw_colored_polygon(glass, Color(Color("ffe7a6"), lamp))
	if lamp > 0.5:
		Toon.spot(ci, top + Vector2(0, 8), Vector2(9, 16), Color(1, 1, 0.9, 0.9))
	ci.draw_line(top + Vector2(0, -26), top + Vector2(0, 40), Toon.INK, 3.0)


# --- props ------------------------------------------------------------------------


## A gilded birdcage standing on (0, 0): a dome of bars, two hoops, a ring
## on top.
static func cage(ci: CanvasItem, boil: int) -> void:
	var half := 190.0
	var height := 330.0
	var gold := Color("c9a03a")
	var top := -height
	var dome := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		dome.append(Vector2(cos(a) * half, top + 60 + sin(a) * 80))
	Toon.stroke(ci, dome, 12.0)
	Toon.stroke(ci, dome, 6.0, gold)
	for k in 9:
		var u := float(k) / 8.0
		var x := -half + u * half * 2.0
		var y_top := top + 60 - sin(u * PI) * 80
		var sway := (Toon.hash01(boil, k) - 0.5) * 1.5
		Toon.stroke(ci, PackedVector2Array([Vector2(x, y_top), Vector2(x + sway, 0)]), 9.0)
		Toon.stroke(ci, PackedVector2Array([Vector2(x, y_top), Vector2(x + sway, 0)]), 4.0, gold)
	for y: float in [-6.0, top + 170.0]:
		Toon.stroke(ci, PackedVector2Array([Vector2(-half - 6, y), Vector2(half + 6, y)]), 14.0)
		Toon.stroke(ci, PackedVector2Array([Vector2(-half - 6, y), Vector2(half + 6, y)]), 7.0, gold)
	var ring := Vector2(0, top - 40)
	ci.draw_arc(ring, 22.0, 0.0, TAU, 24, Toon.INK, 11.0, true)
	ci.draw_arc(ring, 22.0, 0.0, TAU, 24, gold, 5.0, true)
	Toon.shine(ci, Vector2(-half * 0.6, top + 180), Vector2(5, 60), 0.3)


## The Baron's calling card, as big as the screen holds it: a playing card,
## the king of clubs, with his note written across it and a paw print in
## red for a signature. [param shown] is how many of its lines are written
## yet (fractions fade the next one in).
static func calling_card(ci: CanvasItem, center: Vector2, turn: float, shown: float) -> void:
	ci.draw_set_transform(center, turn, Vector2.ONE)
	var r := Rect2(Vector2(-300, -410), Vector2(600, 820))
	ci.draw_colored_polygon(_rounded(Rect2(r.position + Vector2(22, 30), r.size), 36.0), Color(0, 0, 0, 0.45))
	ci.draw_colored_polygon(_rounded(r.grow(7), 40.0), Toon.INK)
	ci.draw_colored_polygon(_rounded(r, 34.0), Color("f4ead2"))
	ci.draw_colored_polygon(_rounded(r.grow(-14), 24.0), Color("efe2c4"))
	ci.draw_rect(r.grow(-34), Color("a83a2b"), false, 3.0)
	ci.draw_rect(r.grow(-44), Color("a83a2b"), false, 1.5)
	var font := Ui.font()
	for corner in 2:
		ci.draw_set_transform(center, turn + (PI if corner == 1 else 0.0), Vector2.ONE)
		ci.draw_string(font, Vector2(-262, -312), "К", HORIZONTAL_ALIGNMENT_LEFT, -1, 60, Toon.INK)
		_club(ci, Vector2(-240, -262), 14.0)
	ci.draw_set_transform(center, turn, Vector2.ONE)
	var lines := ["Ваши красотки", "теперь у меня!", "Ищите их", "в катакомбах —", "если духу хватит."]
	for i in lines.size():
		var alpha := clampf(shown - i, 0.0, 1.0)
		if alpha > 0.0:
			ci.draw_string(font, Vector2(-260, -170 + i * 70), lines[i], HORIZONTAL_ALIGNMENT_CENTER, 520, 44,
					Color(Color("2a1a12"), alpha))
	var sign_alpha := clampf(shown - lines.size(), 0.0, 1.0)
	if sign_alpha > 0.0:
		ci.draw_string(font, Vector2(-250, 262), "Барон К.", HORIZONTAL_ALIGNMENT_LEFT, -1, 54,
				Color(Color("5b3a7a"), sign_alpha))
		ci.draw_line(Vector2(-250, 280), Vector2(-20, 274), Color(Color("5b3a7a"), sign_alpha), 3.0)
		# A paw print stamped in red ink.
		var paw := Vector2(170, 262)
		var red := Color(Color("c8392b"), 0.85 * sign_alpha)
		Toon.spot(ci, paw, Vector2(30, 24), red, 0, 1)
		for k in 4:
			var a := -PI * 0.5 + (k - 1.5) * 0.55
			Toon.spot(ci, paw + Vector2(cos(a) * 40.0, sin(a) * 34.0 - 6.0), Vector2(11, 13), red, 0, k + 2)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The points round [param r] with its corners rounded off by [param radius].
static func _rounded(r: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners := [r.position + Vector2(r.size.x - radius, radius), r.end - Vector2(radius, radius),
			r.position + Vector2(radius, r.size.y - radius), r.position + Vector2(radius, radius)]
	for c in 4:
		for k in 7:
			var a := -PI * 0.5 + PI * 0.5 * (c + k / 6.0)
			points.append((corners[c] as Vector2) + Vector2(cos(a), sin(a)) * radius)
	return points


## A club, as on a playing card.
static func _club(ci: CanvasItem, at: Vector2, r: float) -> void:
	for d: Vector2 in [Vector2(0, -0.9), Vector2(-0.85, 0.15), Vector2(0.85, 0.15)]:
		ci.draw_circle(at + d * r, r * 0.62, Toon.INK, true, -1.0, true)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, 0), at + Vector2(r * 0.45, r * 1.5),
			at + Vector2(-r * 0.45, r * 1.5)]), Toon.INK)


## A sunburst: the happy-ending backdrop, rays turning slowly.
static func sunburst(ci: CanvasItem, center: Vector2, light: Color, dark: Color, turn: float) -> void:
	ci.draw_rect(Rect2(-400, -400, 2720, 1880), dark)
	var rays := 32
	for i in rays:
		var a0 := turn + TAU * i / rays
		var a1 := turn + TAU * (i + 0.5) / rays
		ci.draw_polygon(PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * 1900.0,
				center + Vector2(cos(a1), sin(a1)) * 1900.0]),
				PackedColorArray([light, Color(light, 0.0), Color(light, 0.0)]))
	Toon.glow(ci, center, Vector2(700, 440), Color(1, 0.97, 0.85, 0.35), 3)


## Plain ground under a backdrop, from [param y] down.
static func ground(ci: CanvasItem, y: float, color: Color) -> void:
	ci.draw_rect(Rect2(-400, y - 10, 2720, 900), color)
	Toon.hand_line(ci, Vector2(-400, y - 10), Vector2(2320, y - 10), 5.0, 17)
	for k in 26:
		var x := Toon.hash01(k, 1) * 1920.0
		var at := y + 20 + Toon.hash01(k, 2) * 220.0
		ci.draw_line(Vector2(x, at), Vector2(x + 40 + Toon.hash01(k, 3) * 60, at), Color(0, 0, 0, 0.18), 3.0)
	ci.draw_polygon(PackedVector2Array([Vector2(-400, y - 10), Vector2(2320, y - 10), Vector2(2320, y + 50),
			Vector2(-400, y + 50)]), PackedColorArray([Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0),
			Color(0, 0, 0, 0)]))


## The Baron's top hat lying in the dust, crushed, a hole shot through it.
static func hat(ci: CanvasItem, at: Vector2, boil: int) -> void:
	ci.draw_set_transform(at, -0.35, Vector2.ONE)
	Toon.spot(ci, Vector2(10, 30), Vector2(120, 22), Color(0, 0, 0, 0.3))
	Toon.ball(ci, Vector2(0, 16), Vector2(110, 22), Color("2a1f30"), boil, 5, 5.0)
	var crown := PackedVector2Array([Vector2(-66, 12), Vector2(-60, -120), Vector2(-20, -104), Vector2(8, -132),
			Vector2(62, -118), Vector2(66, 12)])
	Toon.shape(ci, crown, Color("2a1f30"), 5.0)
	ci.draw_rect(Rect2(-64, -20, 129, 26), Color(BaronBoss.COAT))
	Toon.spot(ci, Vector2(22, -70), Vector2(15, 13), Color("0a0608"))
	Toon.spot(ci, Vector2(24, -72), Vector2(6, 5), Color(1, 0.9, 0.7, 0.8))
	Toon.shine(ci, Vector2(-40, -60), Vector2(6, 40), 0.3)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
