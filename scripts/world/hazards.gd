class_name Hazards
extends Node2D
## What lies in wait on a room's floor besides the rocks, drawn under
## everyone and in the floor's own ink:
##   pits    holes in the floor -- nobody walks into one, but shots fly over
##           and fliers too. Broken floorboards round the edge in the
##           basement, a riveted iron rim in the boiler room, cut stone in
##           the catacombs; neighbouring holes are one hole.
##   spikes  a board of upturned nails in the basement, a red-hot grate in
##           the boiler room, iron spikes in the catacombs. Nothing stops a
##           brother walking on them, but each step costs half a heart.
## The room keeps which tiles are which; this draws them and does the
## hurting.

## What hurt him, by floor, for the death card.
const SOURCES := ["гвозди", "раскалённая решётка", "шипы"]
## A brother is on a spike tile once his feet are this far into it.
const INSET := 18.0

var room: Room
var pits := {}
var spikes := {}
var style := 0

var _clock := 0.0
var _drawing := -1


func _process(delta: float) -> void:
	_clock += delta
	# The boiler room's grates glow and fade; the rest stands still.
	if style == 1 and not spikes.is_empty():
		var d := int(_clock * Toon.FPS)
		if d != _drawing:
			_drawing = d
			queue_redraw()


func _physics_process(_delta: float) -> void:
	if spikes.is_empty() or room == null:
		return
	for brother in room.brothers:
		if brother.dead or brother.stats.has("galoshes"):
			continue
		var feet := brother.global_position
		var cell := room.tile_at(feet)
		if not spikes.has(cell):
			continue
		var tile := Rect2(room.tile_center(cell) - Vector2.ONE * Room.TILE * 0.5, Vector2.ONE * Room.TILE)
		if tile.grow(-INSET).has_point(feet):
			brother.hurt(1, feet + Vector2(0, 30), SOURCES[clampi(style, 0, 2)])


func _draw() -> void:
	for cell: Vector2i in pits:
		_pit(cell)
	for cell: Vector2i in pits:
		_pit_rim(cell)
	for cell: Vector2i in spikes:
		match style:
			1:
				_grate(cell)
			2:
				_iron_spikes(cell)
			_:
				_nails(cell)


func _rect(cell: Vector2i) -> Rect2:
	return Rect2(Room.FLOOR.position + Vector2(cell) * Room.TILE, Vector2.ONE * Room.TILE)


func _h(cell: Vector2i, k: int) -> float:
	return Toon.hash01(cell.x * 31 + cell.y * 7 + 5, k)


# --- pits ------------------------------------------------------------------------


## The dark of the hole, and the far wall of it seen going down -- where
## the tile above is not a hole too.
func _pit(cell: Vector2i) -> void:
	var r := _rect(cell)
	draw_rect(r, Color("0b0807"))
	if pits.has(cell + Vector2i.UP):
		return
	var wall := r.size.y * 0.36
	var top: Color = [Color("6b4529"), Color("4b4a52"), Color("6a6c5c")][clampi(style, 0, 2)]
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + wall),
			Vector2(r.position.x, r.position.y + wall)]),
			PackedColorArray([top, top, Color("0b0807"), Color("0b0807")]))
	match style:
		0:
			# The ends of the floorboards, and the joist under them.
			for k in 5:
				var x := r.position.x + (k + 0.5) * r.size.x / 5.0
				draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + wall * 0.7), Color(0, 0, 0, 0.35), 2.0)
			draw_rect(Rect2(r.position + Vector2(0, wall * 0.55), Vector2(r.size.x, 12)), Color(0.12, 0.08, 0.05, 0.8))
		1:
			for k in 4:
				var at := Vector2(r.position.x + (k + 0.5) * r.size.x / 4.0, r.position.y + 10)
				draw_circle(at, 3.0, Color(0, 0, 0, 0.45))
		_:
			draw_line(Vector2(r.position.x, r.position.y + wall * 0.45),
					Vector2(r.end.x, r.position.y + wall * 0.45), Color(0, 0, 0, 0.4), 2.5)
			draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5,
					r.position.y + wall * 0.45), Color(0, 0, 0, 0.4), 2.5)


## Ink round the hole where it meets floor, and what its edge is made of.
func _pit_rim(cell: Vector2i) -> void:
	var r := _rect(cell)
	var edges := {
		"top": [r.position, Vector2(r.end.x, r.position.y), Vector2.UP],
		"bottom": [Vector2(r.position.x, r.end.y), r.end, Vector2.DOWN],
		"left": [r.position, Vector2(r.position.x, r.end.y), Vector2.LEFT],
		"right": [Vector2(r.end.x, r.position.y), r.end, Vector2.RIGHT],
	}
	var seed_k := 0
	for side: String in edges:
		var e: Array = edges[side]
		var out: Vector2 = e[2]
		if pits.has(cell + Vector2i(out)):
			continue
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		seed_k += 1
		match style:
			0:
				# Splintered board ends sticking out over the hole.
				var n := 4
				for k in n:
					var u0 := float(k) / n
					var u1 := float(k + 1) / n
					var depth := 6.0 + _h(cell, seed_k * 10 + k) * 14.0
					var p0 := a.lerp(b, u0)
					var p1 := a.lerp(b, u1)
					var tip := a.lerp(b, (u0 + u1) * 0.5 + (_h(cell, k + 40) - 0.5) * 0.15) - out * depth
					var splinter := PackedVector2Array([p0, p1, p1 - out * depth * 0.4, tip, p0 - out * depth * 0.3])
					Toon.polygon(self, splinter, Color("8a5a36"))
					splinter.append(p0)
					Toon.stroke(self, splinter, 2.5)
			1:
				var rim := PackedVector2Array([a, b, b - out * 12.0, a - out * 12.0])
				draw_colored_polygon(rim, Color("6d6a70"))
				for k in 4:
					draw_circle(a.lerp(b, (k + 0.5) / 4.0) - out * 6.0, 3.0, Toon.INK)
			_:
				var lip := PackedVector2Array([a, b, b - out * 10.0, a - out * 10.0])
				draw_colored_polygon(lip, Color("9a9a86"))
				draw_line(a.lerp(b, 0.5), a.lerp(b, 0.5) - out * 10.0, Color(0, 0, 0, 0.4), 2.0)
		Toon.hand_line(self, a, b, 5.0, cell.x * 13 + cell.y * 7 + seed_k)


# --- spikes ----------------------------------------------------------------------


## A board studded with nails, points up: the basement's.
func _nails(cell: Vector2i) -> void:
	var r := _rect(cell).grow(-12.0)
	Toon.spot(self, r.get_center() + Vector2(4, 8), r.size * 0.5, Color(0, 0, 0, 0.25))
	draw_rect(r.grow(4), Toon.INK)
	draw_rect(r, Color("8f5f38"))
	for k in 3:
		var y := r.position.y + (k + 0.5) * r.size.y / 3.0
		draw_line(Vector2(r.position.x, y + 14), Vector2(r.end.x, y + 14), Color(0, 0, 0, 0.25), 2.0)
	for row in 3:
		for col in 3:
			var base := r.position + Vector2((col + 0.5) * r.size.x / 3.0, (row + 0.5) * r.size.y / 3.0 + 10.0)
			var lean := (_h(cell, row * 3 + col) - 0.5) * 8.0
			_spike(base, Vector2(lean, -24.0), 5.5, Color("a9a7ae"))
			draw_circle(base, 4.0, Color("5a5a62"))


## A grate over a firebox, red-hot and glowing: the boiler room's.
func _grate(cell: Vector2i) -> void:
	var r := _rect(cell).grow(-8.0)
	var heat := 0.65 + 0.35 * sin(_clock * 3.0 + cell.x + cell.y * 2.0)
	draw_rect(r.grow(4), Toon.INK)
	draw_rect(r, Color("2a1410"))
	Toon.glow(self, r.get_center(), r.size * 0.62, Color(1, 0.45, 0.1, 0.55 * heat), 2)
	for k in 5:
		var x := r.position.x + (k + 0.5) * r.size.x / 5.0
		var bar := Rect2(x - 5, r.position.y + 4, 10, r.size.y - 8)
		draw_rect(bar, Color("3a2a26").lerp(Color("e8582a"), heat))
		draw_rect(Rect2(bar.position + Vector2(2, 0), Vector2(3, bar.size.y)), Color(1, 0.8, 0.4, 0.5 * heat))
	draw_rect(r, Toon.INK, false, 4.0)
	if int(_clock * Toon.FPS) % 6 < 2:
		var at := r.position + Vector2(_h(cell, int(_clock * 2.0)) * r.size.x, _h(cell, 9) * r.size.y * 0.5)
		Toon.blob(self, at, Vector2(4, 4), Color("f08a24"), 0, cell.x, 1.5)


## A slab with iron spikes standing up out of it: the catacombs'.
func _iron_spikes(cell: Vector2i) -> void:
	var r := _rect(cell).grow(-10.0)
	draw_rect(r.grow(4), Toon.INK)
	draw_rect(r, Color("7c7d6c"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), Color(1, 1, 1, 0.12))
	for row in 2:
		for col in 3:
			var base := r.position + Vector2((col + 0.5 + (0.5 if row == 1 else 0.0) - (0.25 if row == 1 else 0.0)) \
					* r.size.x / 3.0, (row + 0.75) * r.size.y / 2.0)
			_spike(base, Vector2(0, -34.0), 9.0, Color("8d8e96"), Color("9a4a2a"))


## One spike from [param base] to base + [param tip]: an inked cone with a
## shine down its lit side.
func _spike(base: Vector2, tip: Vector2, half: float, fill: Color, point := Color(0, 0, 0, 0)) -> void:
	var cone := PackedVector2Array([base + Vector2(-half, 0), base + tip, base + Vector2(half, 0)])
	Toon.shape(self, cone, fill, 3.0)
	draw_line(base + Vector2(-half * 0.4, -2), base + tip * 0.8, Color(1, 1, 1, 0.55), 2.0)
	if point.a > 0.0:
		var top := PackedVector2Array([base + tip * 0.65 + Vector2(-half * 0.35, 0), base + tip,
				base + tip * 0.65 + Vector2(half * 0.35, 0)])
		draw_colored_polygon(top, point)
