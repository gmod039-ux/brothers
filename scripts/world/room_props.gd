class_name RoomProps
extends Node2D
## The furniture of a room, painted with real textures under the same ink as
## everything else, so it sits in the world rather than on it:
##   posters    old bills pasted on the walls (circus, boxing, magic --
##              public-domain lithographs, see posters/LICENSE.txt), torn,
##              or framed in the boss's rooms
##   basement   barrels and crates of planks
##   boiler     a firebox in the back wall, lava glowing behind its bars,
##              and a vent grille
##   catacombs  stone half-columns along the walls
##   shop       shelves of jars and bottles, a sign
##   treasure   heaps of gold against the walls
## Everything stands on the walls or leans on their foot: nothing takes floor
## a brother walks on. Laid out by the room's seed.
##
## Textures are brought into the palette once, when first used: some colour
## taken out and the rest leaned towards a tint (see [method tex]).

const POSTERS := {
	"circus": "res://posters/circus_brothers.jpg",
	"boxing1": "res://posters/boxing_wolgast.jpg",
	"boxing2": "res://posters/boxing_johnson.jpg",
	"magic1": "res://posters/magic_cards.jpg",
	"magic2": "res://posters/magic_kellar.jpg",
}
const GOLD := Color("d9a93a")
const IRON := Color("3a302a")
const PAPER := Color("f0e2c0")

## [path, saturation, brightness] -> ImageTexture, shared by every room.
static var _cache := {}

var room: Room
var seed_value := 0

var _clock := 0.0
var _drawing := -1
## Places on the back wall taken by something else: [x, half-width] each.
var _taken: Array = []
## Where things on the back wall went, worked out once: name -> x (NAN when
## there was no room).
var _spots := {}


## Lets go of the textures before quitting (see Main._exit_tree).
static func release() -> void:
	_cache.clear()


## The texture at [param path] with its saturation and brightness adjusted
## -- 1.0 leaves them -- and mipmaps, made once and kept.
static func tex(path: String, saturation := 1.0, brightness := 1.0) -> Texture2D:
	var key := "%s|%.2f|%.2f" % [path, saturation, brightness]
	if _cache.has(key):
		return _cache[key]
	var source := load(path) as Texture2D
	var image := source.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() > 512:
		image.resize(512, int(512.0 * image.get_height() / image.get_width()), Image.INTERPOLATE_LANCZOS)
	image.adjust_bcs(brightness, 1.0, saturation)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_taken = _back_wall_taken()
	var f := Room.FLOOR
	if room.arena == "" and room.kind == "shop":
		_spots["shelf0"] = _free_x(f.get_center().x - 330.0, 130.0)
		_spots["shelf1"] = _free_x(f.get_center().x + 330.0, 130.0)
	if room.arena == "" and room.style == 1:
		_spots["firebox"] = _free_x(f.position.x + f.size.x * (0.3 + _h(30) * 0.4), 66.0)


func _process(delta: float) -> void:
	_clock += delta
	var d := int(_clock * Toon.FPS)
	if d != _drawing:
		_drawing = d
		queue_redraw()


func _h(k: int) -> float:
	return Toon.hash01(seed_value, 5000 + k)


func _draw() -> void:
	var f := Room.FLOOR
	match room.arena:
		"ring":
			_framed("left", 0.2, "boxing1", Color("6e4a2a"))
			_framed("right", 0.8, "boxing2", Color("6e4a2a"))
			return
		"boiler":
			_wall_firebox("left", 0.22, 0.07)
			_wall_firebox("right", 0.78, 0.07)
			return
		"cabaret":
			_framed("left", 0.2, "magic1", GOLD)
			_framed("right", 0.8, "magic2", GOLD)
			return
	match room.kind:
		"shop":
			_shop()
		"treasure":
			_treasure()
		"start":
			_pasted_low(1, "circus", 0.0)
	match room.style:
		0:
			_basement()
		1:
			_boiler()
		_:
			_catacombs()


# --- where things go ---------------------------------------------------------


## What already hangs on the back wall -- lamps, the door, the decor's
## window, gauges or niches -- as [x, half-width] each, so props keep clear.
func _back_wall_taken() -> Array:
	var f := Room.FLOOR
	var taken: Array = []
	if room.doors.has("top"):
		taken.append([f.get_center().x, 130.0])
	for i in 2:
		taken.append([f.position.x + f.size.x * (0.22 + 0.56 * i), 60.0])
	if room.arena == "" and room.style == 0:
		var window := f.position.x + f.size.x * (0.35 + Toon.hash01(seed_value, 300) * 0.3)
		if absf(window - f.get_center().x) < 170.0:
			window += 300.0
		taken.append([window, 70.0])
		taken.append([f.position.x + f.size.x * (0.1 + Toon.hash01(seed_value, 330) * 0.25), 30.0])
	elif room.arena == "" and room.style == 1:
		for k in 2:
			taken.append([f.position.x + f.size.x * (0.1 + 0.8 * k), 40.0])
	elif room.arena == "":
		for k in 3:
			var x := f.position.x + f.size.x * (0.14 + 0.36 * k) + (60.0 if k == 1 else 0.0)
			if absf(x - f.get_center().x) < 130.0:
				x += 200.0
			taken.append([x, 45.0])
	return taken


## A free spot on the back wall for something [param half] wide, near
## [param want]; NAN if there is none.
func _free_x(want: float, half: float) -> float:
	var f := Room.FLOOR
	for step in 24:
		var x := want + (step / 2) * 40.0 * (1.0 if step % 2 == 0 else -1.0)
		if x - half < f.position.x + 20.0 or x + half > f.end.x - 20.0:
			continue
		var clear := true
		for t: Array in _taken:
			if absf(x - float(t[0])) < half + float(t[1]) + 10.0:
				clear = false
				break
		if clear:
			_taken.append([x, half])
			return x
	return NAN


## Four points of a rectangle on a wall face: [param u0]..[param u1] along
## the wall (as seen from the floor, left to right), [param v0]..[param v1]
## from its top down to the floor. Top-left, top-right, bottom-right,
## bottom-left.
func _on_wall(side: String, u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	var quad: Array = room.faces()[side]
	return PackedVector2Array([Room.face_point(quad, u0, v0), Room.face_point(quad, u1, v0),
			Room.face_point(quad, u1, v1), Room.face_point(quad, u0, v1)])


## The same on the back wall by screen x: from [param x0] to [param x1]
## along the floor's edge.
func _on_back(x0: float, x1: float, v0: float, v1: float) -> PackedVector2Array:
	var f := Room.FLOOR
	return _on_wall("top", (x0 - f.position.x) / f.size.x, (x1 - f.position.x) / f.size.x, v0, v1)


## Draws [param texture] over a four-cornered shape, the whole picture
## ([param uv] its part) stretched over it.
func _picture(corners: PackedVector2Array, texture: Texture2D, tint := Color.WHITE,
		uv := Rect2(0, 0, 1, 1)) -> void:
	var uvs := PackedVector2Array([uv.position, Vector2(uv.end.x, uv.position.y), uv.end,
			Vector2(uv.position.x, uv.end.y)])
	draw_polygon(corners, PackedColorArray([tint, tint, tint, tint]), uvs, texture)


## [param points] filled with [param texture] laid flat, [param scale]
## pixels to one repeat.
func _fill(points: PackedVector2Array, texture: Texture2D, tint := Color.WHITE, scale := 256.0,
		offset := Vector2.ZERO) -> void:
	var uvs := PackedVector2Array()
	for p in points:
		uvs.append(p / scale + offset)
	draw_polygon(points, PackedColorArray([tint]), uvs, texture)


# --- posters -----------------------------------------------------------------


## A bill low on one of the side walls -- the upper halves are under the
## hearts and the map.
func _pasted_low(k: int, which: String, tilt: float) -> void:
	if _h(k) < 0.5:
		_pasted("left", 0.2, which, tilt)
	else:
		_pasted("right", 0.8, which, tilt)


## A bill pasted straight onto the wall: aged, a corner torn off or curling
## away, nails in the others.
func _pasted(side: String, u: float, which: String, tilt: float) -> void:
	var length: float = (room.faces()[side][3] as Vector2).distance_to(room.faces()[side][2])
	var half := 58.0 / length
	var q := _on_wall(side, u - half, u + half, 0.14, 0.9) if side != "top" \
			else _on_wall(side, u - half * 0.62, u + half * 0.62, 0.14, 0.92)
	if tilt != 0.0:
		var middle := (q[0] + q[2]) * 0.5
		for i in 4:
			q[i] = middle + (q[i] - middle).rotated(tilt)
	# Its shadow on the wall.
	var shadow := PackedVector2Array()
	for p in q:
		shadow.append(p + Vector2(4, 5))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.3))
	var texture := tex(POSTERS[which], 0.62, 0.92)
	# One corner torn off: the picture is cut there and the paper's back
	# curls out.
	var torn := int(_h(10 + which.length()) * 4.0)
	var a := q[torn]
	var b := q[(torn + 1) % 4]
	var c := q[(torn + 3) % 4]
	var cut1 := a.lerp(b, 0.3)
	var cut2 := a.lerp(c, 0.26)
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var points := PackedVector2Array()
	var uv_points := PackedVector2Array()
	for i in 4:
		if i == torn:
			# Round the corner the way the polygon goes: in along the edge
			# from the corner before, out along the edge to the one after.
			points.append(cut2)
			uv_points.append((uvs[i] as Vector2).lerp(uvs[(i + 3) % 4], 0.26))
			points.append(cut1)
			uv_points.append((uvs[i] as Vector2).lerp(uvs[(i + 1) % 4], 0.3))
		else:
			points.append(q[i])
			uv_points.append(uvs[i])
	draw_colored_polygon(Toon.grown(points, 2.5), Toon.INK)
	draw_polygon(points, PackedColorArray([Color(1.0, 0.95, 0.84)]), uv_points, texture)
	# The curl: a small triangle of the paper's back.
	var curl := PackedVector2Array([cut1, cut2, a.lerp((cut1 + cut2) * 0.5, 0.45)])
	Toon.shape(self, curl, PAPER.darkened(0.08), 2.0)
	# Nails in the other corners.
	for i in 4:
		if i == torn:
			continue
		var at := q[i].lerp((q[0] + q[2]) * 0.5, 0.08)
		draw_circle(at, 3.2, IRON)
		draw_circle(at + Vector2(-1, -1), 1.2, Color(1, 1, 1, 0.5))


## An ink line round a closed shape: for thin ones, which
## [method Toon.grown] would only widen at their ends.
func _outline(points: PackedVector2Array, width: float) -> void:
	var loop := points.duplicate()
	loop.append(points[0])
	draw_polyline(loop, Toon.INK, width, true)


## [param points] in order round their middle.
static func _around(points: PackedVector2Array) -> PackedVector2Array:
	var middle := Vector2.ZERO
	for p in points:
		middle += p
	middle /= points.size()
	var list: Array = Array(points)
	list.sort_custom(func(p: Vector2, r: Vector2) -> bool:
		return (p - middle).angle() < (r - middle).angle())
	return PackedVector2Array(list)


## A poster in a frame on a side wall, at [param u] along it.
func _framed(side: String, u: float, which: String, frame: Color) -> void:
	var length: float = (room.faces()[side][3] as Vector2).distance_to(room.faces()[side][2])
	var half := 62.0 / length
	var pad := 12.0 / length
	var outer := _on_wall(side, u - half - pad, u + half + pad, 0.08, 0.95)
	var inner := _on_wall(side, u - half, u + half, 0.16, 0.87)
	var shadow := PackedVector2Array()
	for p in outer:
		shadow.append(p + Vector2(5, 7))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	draw_colored_polygon(Toon.grown(outer, 4.0), Toon.INK)
	_fill(outer, tex("res://textures/wood_planks_004.png", 0.4, 1.0), frame.lightened(0.25), 90.0)
	# The frame's bevel: the edge towards the light lighter.
	Toon.stroke(self, PackedVector2Array([outer[3], outer[0], outer[1]]), 3.0, Color(1, 1, 0.9, 0.35))
	draw_colored_polygon(Toon.grown(inner, 2.5), Toon.INK)
	_picture(inner, tex(POSTERS[which], 0.7, 0.95), Color(1.0, 0.96, 0.88))
	# Glass: a streak of shine across it.
	var shine := PackedVector2Array([inner[0].lerp(inner[1], 0.15), inner[0].lerp(inner[1], 0.35),
			inner[3].lerp(inner[2], 0.1), inner[3].lerp(inner[2], -0.1 + 0.0)])
	draw_colored_polygon(_around(shine), Color(1, 1, 1, 0.1))


# --- the floors --------------------------------------------------------------


func _basement() -> void:
	var f := Room.FLOOR
	# A barrel against one side wall, crates against the other: where the
	# decor used to draw them.
	var left := Toon.hash01(seed_value, 150) < 0.5
	_barrel(Vector2(f.position.x - 20 if left else f.end.x + 20, _foot_y(151)))
	_crates(Vector2(f.end.x + 16 if left else f.position.x - 16, _foot_y(161)))
	if room.kind == "normal" and _h(20) < 0.55:
		var which: String = ["circus", "boxing1", "boxing2"][int(_h(21) * 3.0)]
		_pasted_low(22, which, (_h(24) - 0.5) * 0.08)


## As [method RoomDecor._beside_door]: low on a side wall's foot.
func _foot_y(k: int) -> float:
	return Room.FLOOR.end.y - 60.0 - Toon.hash01(seed_value, k + 1) * 200.0


func _barrel(at: Vector2) -> void:
	var r := Vector2(32, 40)
	Toon.glow(self, at + Vector2(4, 36), Vector2(44, 12), Color(0, 0, 0, 0.45), 2)
	var body := Toon.ellipse_points(at, r, 0, 7, 0.0, 0.0, 0.0, 2.6)
	draw_colored_polygon(Toon.grown(body, 4.5), Toon.INK)
	# Staves run top to bottom: the planks texture turned on its side.
	var uvs := PackedVector2Array()
	for p in body:
		var d := (p - at) / r
		uvs.append(Vector2(d.y * 0.5 + 0.5, (asin(clampf(d.x, -1.0, 1.0)) / PI + 0.5) * 0.6))
	draw_polygon(body, PackedColorArray([Color(1, 0.9, 0.8)]), uvs, tex("res://textures/wood_planks_004.png", 0.8, 1.0))
	Toon.polygon(self, Toon.crescent(at, r, 0, 7, 4.5), Color(0.2, 0.08, 0.02, 0.35))
	for k in 2:
		var y := -r.y * 0.5 + k * r.y
		Toon.stroke(self, Toon.bent(at + Vector2(-r.x * 0.93, y), at + Vector2(r.x * 0.93, y), -6.0), 7.0)
		Toon.stroke(self, Toon.bent(at + Vector2(-r.x * 0.93, y - 1), at + Vector2(r.x * 0.93, y - 1), -6.0), 3.5,
				Color("6a6660"))
	# The lid.
	Toon.blob(self, at + Vector2(0, -r.y * 0.82), Vector2(r.x * 0.72, 8), Color("5e3a20"), 0, 8, 3.5)
	Toon.spot(self, at + Vector2(-r.x * 0.4, -r.y * 0.35), Vector2(5, 14), Color(1, 1, 0.9, 0.25))


func _crates(at: Vector2) -> void:
	Toon.glow(self, at + Vector2(4, 34), Vector2(46, 12), Color(0, 0, 0, 0.45), 2)
	for c in 2:
		var half := 32.0 - c * 7.0
		var middle := at + Vector2(c * 6.0, -c * (32.0 + half))
		_crate(middle, half, 0.1 * c - 0.04)


func _crate(at: Vector2, half: float, tilt: float) -> void:
	var front := PackedVector2Array()
	for p: Vector2 in [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]:
		front.append(at + p.rotated(tilt))
	draw_colored_polygon(Toon.grown(front, 4.5), Toon.INK)
	_picture(front, tex("res://textures/crate_001.png", 0.75, 1.1), Color(1, 0.92, 0.82))
	Toon.stroke(self, PackedVector2Array([front[3], front[0], front[1]]), 3.0, Color(1, 1, 0.9, 0.3))
	Toon.stroke(self, PackedVector2Array([front[1], front[2], front[3]]), 3.0, Color(0, 0, 0, 0.35))
	# Stencilled on the side.
	draw_string(Ui.font(), at + Vector2(-half * 0.55, half * 0.2), "№%d" % (1 + int(_h(int(at.y)) * 9)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, int(half * 0.55), Color(0.15, 0.08, 0.04, 0.45))


func _boiler() -> void:
	var x: float = _spots.get("firebox", NAN)
	if not is_nan(x):
		var f := Room.FLOOR
		_wall_firebox("top", (x - f.position.x) / f.size.x, 62.0 / f.size.x)
	# A vent grille on a side wall.
	var side := "left" if _h(31) < 0.5 else "right"
	var u := 0.2 if side == "left" else 0.8
	var q := _on_wall(side, u - 0.06, u + 0.06, 0.25, 0.8)
	draw_colored_polygon(Toon.grown(q, 5.0), Toon.INK)
	draw_colored_polygon(q, Color("1a1614"))
	_picture(q, tex("res://textures/metal_gate_001.png", 0.3, 1.0), Color(0.85, 0.85, 0.9), Rect2(0, 0, 1, 1))
	for i in 4:
		draw_circle(q[i].lerp((q[0] + q[2]) * 0.5, 0.12), 3.5, Color("8a8680"))


## A firebox let into a wall at [param u] along it, [param half] of the
## wall's length wide either side: an iron front with a grate, the fire
## showing through it, its glow on the floor in front.
func _wall_firebox(side: String, u: float, half: float) -> void:
	var body := _on_wall(side, u - half, u + half, 0.12, 1.0)
	var mouth := _on_wall(side, u - half * 0.65, u + half * 0.65, 0.4, 0.94)
	var flick: float = [1.0, 0.9, 1.08, 0.95][_drawing % 4]
	var foot := Room.face_point(room.faces()[side], u, 1.0)
	var inward := (Room.FLOOR.get_center() - foot).normalized()
	Toon.glow(self, foot + inward * 30.0, Vector2(150, 90) * flick, Color(1, 0.45, 0.15, 0.35), 3)
	draw_colored_polygon(Toon.grown(body, 5.0), Toon.INK)
	_picture(body, tex("res://textures/metal_plates_001.png", 0.25, 0.75), Color(0.75, 0.72, 0.72),
			Rect2(0, 0, 0.5, 0.5))
	_fire(mouth, flick)
	# Rivets in its corners, and a handle across the top.
	for i in 4:
		draw_circle(body[i].lerp((body[0] + body[2]) * 0.5, 0.12), 3.5, Color("8a8680"))
	var top_left := body[0].lerp(body[3], 0.18)
	var top_right := body[1].lerp(body[2], 0.18)
	Toon.stroke(self, PackedVector2Array([top_left.lerp(top_right, 0.3), top_left.lerp(top_right, 0.7)]), 5.0, IRON)


## Fire behind bars: lava crawling in the opening, lit brighter in the
## middle, the grate over it.
func _fire(mouth: PackedVector2Array, flick: float) -> void:
	draw_colored_polygon(Toon.grown(mouth, 3.0), Toon.INK)
	var drift := Vector2(_clock * 0.05, -_clock * 0.12)
	var uvs := PackedVector2Array()
	for i in 4:
		uvs.append(Vector2(float(i == 1 or i == 2), float(i >= 2)) * 0.35 + drift)
	draw_polygon(mouth, PackedColorArray([Color(1.2, 1.0, 0.8) * flick]), uvs, tex("res://textures/lava_001.png", 1.0, 1.15))
	var middle := (mouth[0] + mouth[2]) * 0.5
	Toon.glow(self, middle, (mouth[2] - mouth[0]).abs() * 0.45, Color(1, 0.9, 0.5, 0.45), 2)
	for k in range(1, 4):
		var t := k / 4.0
		Toon.stroke(self, PackedVector2Array([mouth[0].lerp(mouth[1], t), mouth[3].lerp(mouth[2], t)]), 4.0, IRON)


func _catacombs() -> void:
	# An ossuary niche low on each side wall: skulls stacked in rows behind
	# an arch of stone, the way the catacombs keep their dead.
	_ossuary("left", 0.2)
	_ossuary("right", 0.8)
	# Clay urns at the foot of the back wall.
	var f := Room.FLOOR
	for k in 2:
		if _h(60 + k) < 0.6:
			var at := Vector2(f.position.x + 300.0 + _h(62 + k) * (f.size.x - 600.0), f.position.y + 2.0)
			if absf(at.x - f.get_center().x) > 110.0:
				_urn(at, k)


func _ossuary(side: String, u: float) -> void:
	var half := 0.075
	var frame := _on_wall(side, u - half, u + half, 0.1, 0.98)
	var hole := _on_wall(side, u - half * 0.78, u + half * 0.78, 0.2, 0.9)
	draw_colored_polygon(Toon.grown(frame, 4.0), Toon.INK)
	_fill(frame, tex("res://textures/stone_column_001.png", 0.0, 0.95), Color(0.8, 0.8, 0.7), 140.0)
	draw_colored_polygon(Toon.grown(hole, 2.5), Toon.INK)
	draw_colored_polygon(hole, Color("15110c"))
	# Rows of skulls filling the hole.
	var rows := 3
	var cols := 2
	for r in rows:
		for c in cols:
			var tu := (c + 0.5) / cols + (0.08 if r % 2 == 1 else -0.04)
			var tv := (r + 0.5) / rows
			var at := hole[0].lerp(hole[1], tu).lerp(hole[3].lerp(hole[2], tu), tv)
			_skull(at, 17.0, r * 3 + c)
	# Moss at its foot.
	Toon.glow(self, frame[3].lerp(frame[2], 0.5), Vector2(36, 16), Color(0.3, 0.48, 0.22, 0.6), 2)


## A skull, jaw and all, a little lopsided.
func _skull(at: Vector2, size: float, k: int) -> void:
	var bone := Color("ddd3bb")
	Toon.ball(self, at, Vector2(size, size * 0.86), bone, 0, k, 3.0)
	Toon.box(self, at + Vector2(0, size * 0.66), Vector2(size * 0.52, size * 0.26), bone, 0, k + 20, 2.5)
	for side: float in [-1.0, 1.0]:
		Toon.spot(self, at + Vector2(side * size * 0.36, size * 0.02), Vector2(size * 0.24, size * 0.28), Toon.INK)
	Toon.spot(self, at + Vector2(0, size * 0.36), Vector2(size * 0.08, size * 0.12), Toon.INK)
	for t in 3:
		var x := (t - 1) * size * 0.22
		draw_line(at + Vector2(x, size * 0.5), at + Vector2(x, size * 0.8), Toon.INK, 1.5)


## A clay urn against the back wall, a crack in it.
func _urn(at: Vector2, k: int) -> void:
	var clay := Color("a8643a") if k == 0 else Color("8a6a4a")
	Toon.glow(self, at + Vector2(4, 4), Vector2(34, 10), Color(0, 0, 0, 0.4), 2)
	Toon.pear(self, at + Vector2(0, -26), Vector2(20, 26), 0.25, clay, 0, 70 + k, 4.0)
	Toon.box(self, at + Vector2(0, -52), Vector2(12, 5), clay.darkened(0.15), 0, 72 + k, 3.5)
	Toon.polygon(self, Toon.crescent(at + Vector2(0, -26), Vector2(20, 26), 0, 70 + k, 4.0, 0.0, 0.25),
			Color(0, 0, 0, 0.3))
	Toon.stroke(self, PackedVector2Array([at + Vector2(-6, -40), at + Vector2(-2, -30), at + Vector2(-8, -20)]), 2.0)
	Toon.stroke(self, Toon.bent(at + Vector2(-16, -30), at + Vector2(16, -30), -4.0), 2.5, Color(0, 0, 0, 0.35))


func _shop() -> void:
	for k in 2:
		var x: float = _spots.get("shelf%d" % k, NAN)
		if not is_nan(x):
			_shelf(x)
	_pasted_low(40, "circus", 0.0)


## Two plank shelves on brackets, jars and bottles on them.
func _shelf(x: float) -> void:
	var colors := [Color("b8322a"), Color("3f6fb5"), Color("5f9a45"), Color("e0b23a"), Color("f3e6c8")]
	for row in 2:
		var v := 0.4 + row * 0.38
		var board := _on_back(x - 120.0, x + 120.0, v, v + 0.14)
		# Things standing on the board, drawn before it so their feet hide
		# behind its edge.
		for k in 5:
			var at := board[0].lerp(board[1], 0.12 + k * 0.19) + Vector2(0, -2)
			var color: Color = colors[int(_h(50 + row * 5 + k) * colors.size())]
			if (k + row) % 2 == 0:
				Toon.box(self, at + Vector2(0, -14), Vector2(9, 13), color, 0, k, 3.0)
				Toon.box(self, at + Vector2(0, -30), Vector2(7, 3), Color("8a5a36"), 0, k + 9, 2.5)
				Toon.spot(self, at + Vector2(-3, -18), Vector2(2, 6), Color(1, 1, 1, 0.5))
			else:
				Toon.box(self, at + Vector2(0, -12), Vector2(5, 11), color.darkened(0.2), 0, k, 3.0)
				Toon.box(self, at + Vector2(0, -28), Vector2(2.5, 6), color.darkened(0.2), 0, k + 3, 2.5)
		# A shadow under it on the wall, the board, and its ink.
		var shadow := PackedVector2Array()
		for p in board:
			shadow.append(p + Vector2(3, 8))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
		_fill(board, tex("res://textures/wood_planks_004.png", 0.8, 1.0), Color(0.85, 0.66, 0.48), 180.0)
		Toon.stroke(self, PackedVector2Array([board[0], board[1]]), 3.0, Color(1, 0.95, 0.8, 0.5))
		_outline(board, 3.5)
		for bracket: float in [0.15, 0.85]:
			var top := board[3].lerp(board[2], bracket)
			Toon.stroke(self, PackedVector2Array([top, top + Vector2(0, 14), top + Vector2(10, 4)]), 3.5, IRON)


func _treasure() -> void:
	var f := Room.FLOOR
	# Heaps of gold against the walls: two along the back wall either side of
	# the middle, two in the front corners (the back corners are under the
	# hearts and the map).
	for at: Vector2 in [Vector2(f.get_center().x - 300.0, f.position.y + 4), Vector2(f.get_center().x + 300.0,
			f.position.y + 4), Vector2(f.position.x + 10, f.end.y - 8), f.end - Vector2(10, 8)]:
		_heap(at)


func _heap(at: Vector2) -> void:
	var gold := tex("res://textures/coins_001.png", 0.85, 1.05)
	Toon.glow(self, at, Vector2(120, 70), Color(1, 0.85, 0.35, 0.3), 3)
	var mound := PackedVector2Array()
	var n := 18
	for i in n + 1:
		var a := PI + PI * i / n
		var bump := 1.0 + 0.08 * sin(i * 2.3 + at.x)
		mound.append(at + Vector2(cos(a) * 70.0, sin(a) * 44.0 * bump + 10.0))
	mound.append(at + Vector2(70, 14))
	mound.append(at + Vector2(-70, 14))
	mound = _around(mound)
	draw_colored_polygon(Toon.grown(mound, 4.0), Toon.INK)
	_fill(mound, gold, Color(1, 0.95, 0.8), 150.0, Vector2(at.x * 0.001, 0))
	Toon.polygon(self, Toon.crescent(at + Vector2(0, -6), Vector2(66, 38), 0, 2, 0.0), Color(0.4, 0.2, 0, 0.3))
	# Loose coins slid off it, lying flat, and a glint that comes and goes.
	for k in 4:
		var c := at + Vector2((k - 1.5) * 34.0 + (_h(int(at.x) + k) - 0.5) * 16.0, 24.0 + (k % 2) * 9.0)
		Toon.blob(self, c, Vector2(9, 4.5), Color("e8b83a"), 0, k, 2.5)
		Toon.spot(self, c + Vector2(-2, -1), Vector2(3, 1.2), Color(1, 1, 0.85, 0.8))
	if (_drawing + int(at.x)) % 20 < 3:
		Toon.star(self, at + Vector2(-20, -24), 7.0 + (_drawing % 20) * 3.0, 0.3, Color("fffbe8"))
