class_name Room
extends Node2D
## One room of a floor: a screen-sized box seen from above and a little in
## front, the way Isaac's rooms are. 13 by 7 tiles of floor, walls on all
## four sides, and a door in the middle of each wall that has a room beyond.
##
## The room is its own coordinate frame: (0, 0) is the top-left corner of the
## screen it fills, and everything inside -- brothers, enemies, shots -- lives
## under [member actors] and is placed in world coordinates.

const TILE := 112.0
const COLS := 13
const ROWS := 7
const SIZE := Vector2(1920, 1080)
## The floor inside the walls. The side walls are thicker than the top and
## bottom ones: the room is as wide as the screen, and 13 tiles are not.
const FLOOR := Rect2(232, 148, TILE * COLS, TILE * ROWS)
## Where the tops of the walls meet the dark around the room.
const RIM := Rect2(26, 22, 1920 - 52, 1080 - 44)

const WALL_LAYER := 1
const ROCK_LAYER := 32

const DOORS := ["top", "right", "bottom", "left"]
## Width of the gap a door leaves in its wall.
const DOOR_GAP := 124.0
## How far past the floor's edge, through an open door, a brother has to
## walk before he is in the next room.
const EXIT_DEPTH := 34.0

## The look of each floor: the basement in red brick and warm sandstone
## tiles, the boiler room in riveted steel and concrete slabs, the catacombs
## in rough stone and mossy flagstones. "floor_pattern" and "wall_pattern"
## pick the shader's patterns (see shaders/room_paint.gdshader); "joint" is
## the grout between floor stones, "mortar" between wall ones; "grout" the
## ink of cracks drawn over the floor.
const STYLES := [
	{"wall": Color("a8573b"), "wall_stain": Color("74382a"), "mortar": Color("4a271b"),
			"cap": Color("c9a57e"), "floor": Color("e6cc9c"), "floor_stain": Color("c79c68"),
			"joint": Color("8a6646"), "grout": Color(0.42, 0.29, 0.18, 0.5),
			"floor_pattern": 0, "wall_pattern": 0, "ambient": 0.8,
			"light": Color(1.0, 0.8, 0.5)},
	{"wall": Color("6d7a8a"), "wall_stain": Color("414a57"), "mortar": Color("242a31"),
			"cap": Color("9ca3aa"), "floor": Color("d6cfbf"), "floor_stain": Color("a2988a"),
			"joint": Color("6b6660"), "grout": Color(0.25, 0.24, 0.26, 0.5),
			"floor_pattern": 1, "wall_pattern": 1, "ambient": 0.78,
			"light": Color(1.0, 0.68, 0.38)},
	{"wall": Color("7f8569"), "wall_stain": Color("4c5340"), "mortar": Color("2a2e22"),
			"cap": Color("aeb094"), "floor": Color("cacbac"), "floor_stain": Color("8f9672"),
			"joint": Color("545b44"), "grout": Color(0.24, 0.29, 0.2, 0.5),
			"floor_pattern": 2, "wall_pattern": 2, "ambient": 0.74,
			"light": Color(1.0, 0.78, 0.5)},
]
## Painted textures for the floors and walls of each style (see
## textures/LICENSE.txt), two to choose between for each. A floor's is
## {path, repeat: pixels to one repeat}; a wall's is {path, rows: courses of
## stone in the picture, courses: courses on the wall} -- or {fit: true} to
## stretch one repeat over the whole height of every wall. Either may say
## how far its colours are pulled towards the room's palette ("tint",
## "desat") and brightened ("gain").
## [member texture_variant] picks which of the two.
const TEXTURES := [
	{"floor": [{"path": "res://textures/terracotta_tiles_002.png", "repeat": 448.0},
				{"path": "res://textures/stone_floor_010.png", "repeat": 820.0}],
			"wall": [{"path": "res://textures/bricks_003.png", "rows": 9.0, "courses": 4.0},
				{"path": "res://textures/bricks_001.png", "rows": 13.0, "courses": 5.0}]},
	{"floor": [{"path": "res://textures/stone_floor_011.png", "repeat": 700.0},
				{"path": "res://textures/stone_floor_012.png", "repeat": 1100.0}],
			"wall": [{"path": "res://textures/metal_pattern_001.png", "rows": 6.0, "courses": 2.0},
				{"path": "res://textures/metal_gate_001.png", "fit": true, "courses": 4.0}]},
	{"floor": [{"path": "res://textures/stone_floor_003.png", "repeat": 900.0},
				{"path": "res://textures/stone_floor_003.png", "repeat": 700.0}],
			"wall": [{"path": "res://textures/stone_wall_004.png", "rows": 8.0, "courses": 4.0, "tint": 0.55,
					"desat": 0.4},
				{"path": "res://textures/stone_wall_003.png", "rows": 6.0, "courses": 3.0, "tint": 0.5}]},
]
## The bosses' rooms: textures where the arena has none of its own drawn.
const ARENA_TEXTURES := {
	"ring": {"wall": {"path": "res://textures/bricks_003.png", "rows": 9.0, "courses": 4.0, "tint": 0.35}},
	"boiler": {"wall": {"path": "res://textures/metal_gate_001.png", "fit": true, "courses": 4.0},
			"floor": {"path": "res://textures/metal_plates_001.png", "repeat": 560.0, "tint": 0.6, "desat": 0.6,
					"gain": 1.1, "contrast": 0.5}},
}
## Which of each pair in [constant TEXTURES] the rooms are painted with;
## -1 paints them with the drawn patterns instead. `-- textures N`.
static var texture_variant := 0

const ROCK := Color("a79a86")
const ROCK_DARK := Color("7d705f")

## Brothers in this room, for enemies to chase and enemy shots to hit.
var brothers: Array[Brother] = []
## Living enemies in this room.
var enemies: Array[Enemy] = []
## Everything that moves and is drawn in depth order: brothers, enemies,
## rocks, shots.
var actors: Node2D
## Puffs, splats and the like, drawn over the actors.
var effects: Node2D
## Things lying flat on the floor, under everyone: the trapdoor.
var decals: Node2D
## Ink left on the floor by the fighting.
var stains: Stains
## The doors: side -> the kind of room beyond it ("normal", "boss",
## "treasure", "start"). Sides without a door are plain wall.
var doors := {}
## Which doors are open. A door that is shut is a wall.
var open_doors := {}
## The cell of the floor this room is in.
var cell := Vector2i.ZERO
## The run this room is part of; null in tests and the arena.
var run: Run
## Which of [constant STYLES] it is painted in; set before [method build].
var style := 0
## What the room is on the floor's plan ("normal", "start", "treasure",
## "shop", "boss"): dresses it. Set before [method build].
var kind := "normal"
## A boss's own room ("ring", "boiler", "cabaret"), or "" for a plain one.
## Set before [method build].
var arena := ""

var _blockers := {}
var _doors_set := false
var _rocks := {}
## Doors that stay shut until someone brings a key: side -> true.
var locked := {}

## A rock was blown up, so the run can remember it.
signal rock_broken(cell: Vector2i)

var _solid := PackedByteArray()
var _paint: Node2D
var _layout_seed := 0


func _init() -> void:
	_solid.resize(COLS * ROWS)


## Builds the room from a text layout: [constant ROWS] lines of
## [constant COLS] characters, `.` floor and `#` rock (letters for enemies
## are the run's business). [param doors_] is [member doors]; they start
## shut.
func build(layout: PackedStringArray, seed_value: int, doors_ := {}, broken := {}) -> void:
	_layout_seed = seed_value
	doors = doors_
	for side: String in doors:
		open_doors[side] = false
	_paint = Node2D.new()
	_paint.name = "Paint"
	add_child(_paint)
	_paint_floor_and_walls()
	var lines := RoomLines.new()
	lines.room = self
	lines.seed_value = seed_value
	lines.name = "Lines"
	add_child(lines)
	if arena == "":
		var decor := RoomDecor.new()
		decor.name = "Decor"
		decor.room = self
		decor.seed_value = seed_value
		decor.style = style
		add_child(decor)
	var props := RoomProps.new()
	props.name = "Props"
	props.room = self
	props.seed_value = seed_value
	add_child(props)
	_add_walls()
	decals = Node2D.new()
	decals.name = "Decals"
	add_child(decals)
	if arena != "":
		var dressing := Arena.new()
		dressing.kind = arena
		dressing.room = self
		decals.add_child(dressing)
	stains = Stains.new()
	stains.name = "Stains"
	decals.add_child(stains)
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	add_child(actors)
	effects = Node2D.new()
	effects.name = "Effects"
	add_child(effects)
	for row in mini(layout.size(), ROWS):
		var line := layout[row]
		for col in mini(line.length(), COLS):
			if line[col] == "#" and not broken.has(Vector2i(col, row)):
				_add_rock(Vector2i(col, row))


func palette() -> Dictionary:
	if arena != "":
		return Arena.PALETTES[arena]
	return STYLES[clampi(style, 0, STYLES.size() - 1)]


## The middle of tile [param cell], in world coordinates.
func tile_center(cell: Vector2i) -> Vector2:
	return global_position + FLOOR.position + (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


## The tile under world point [param at]; may be outside the floor.
func tile_at(at: Vector2) -> Vector2i:
	var local := (at - global_position - FLOOR.position) / TILE
	return Vector2i(floori(local.x), floori(local.y))


func in_floor(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLS and cell.y < ROWS


func is_rock(cell: Vector2i) -> bool:
	return in_floor(cell) and _solid[cell.y * COLS + cell.x] != 0


## True when a shot at world point [param at] has hit something solid: a
## wall, or a rock unless [param over_rocks].
func blocks_shot(at: Vector2, over_rocks := false) -> bool:
	var local := at - global_position
	if not FLOOR.has_point(local):
		return true
	return not over_rocks and is_rock(tile_at(at))


## The floor rectangle in world coordinates.
func floor_rect() -> Rect2:
	return Rect2(global_position + FLOOR.position, FLOOR.size)


func center() -> Vector2:
	return global_position + SIZE * 0.5


## Open floor tiles, for spawning things on.
func free_tiles() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in ROWS:
		for col in COLS:
			if not is_rock(Vector2i(col, row)):
				cells.append(Vector2i(col, row))
	return cells


## The fight in here is over: steam vents go quiet, fire on the floor goes
## out, and whatever is still coming down lands on nobody.
func calm() -> void:
	for node in get_tree().get_nodes_in_group("hazard"):
		if is_ancestor_of(node) or node.get("room") == self:
			node.call("quench")


func set_doors_open(open: bool) -> void:
	var changed := false
	for side: String in doors:
		var really := open and not locked.has(side)
		changed = changed or bool(open_doors.get(side, false)) != really
		open_doors[side] = really
		var blocker := _blockers.get(side) as CollisionShape2D
		if blocker != null:
			blocker.set_deferred("disabled", really)
	var lines := get_node_or_null("Lines") as CanvasItem
	if lines != null:
		lines.queue_redraw()
	# The slam or creak of doors, but not when a room is first put up.
	if changed and _doors_set:
		Sfx.play("door", -3.0)
	_doors_set = true


## Where a door meets the floor, in world coordinates.
func door_point(side: String) -> Vector2:
	var f := FLOOR
	var local: Vector2 = {
		"top": Vector2(f.get_center().x, f.position.y),
		"bottom": Vector2(f.get_center().x, f.end.y),
		"left": Vector2(f.position.x, f.get_center().y),
		"right": Vector2(f.end.x, f.get_center().y),
	}[side]
	return global_position + local


## Where someone coming in through the door on [param side] stands: just
## inside it, on the floor.
func entry_point(side: String) -> Vector2:
	var inward: Vector2 = -Vector2(FloorPlan.SIDES[side])
	return door_point(side) + inward * TILE * 0.6


## The door [param at] has gone out through, or "" while still inside.
func exit_side(at: Vector2) -> String:
	var local := at - global_position
	var f := FLOOR
	if local.y < f.position.y - EXIT_DEPTH and doors.has("top"):
		return "top"
	if local.y > f.end.y + EXIT_DEPTH and doors.has("bottom"):
		return "bottom"
	if local.x < f.position.x - EXIT_DEPTH and doors.has("left"):
		return "left"
	if local.x > f.end.x + EXIT_DEPTH and doors.has("right"):
		return "right"
	return ""


## A path over open tiles from [param from] to [param to], both included,
## or an empty one if there is none.
func path_to(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not in_floor(from) or not in_floor(to):
		return path
	var came := {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_front()
		if here == to:
			break
		for step: Vector2i in FloorPlan.SIDES.values():
			var next := here + step
			if in_floor(next) and not is_rock(next) and not came.has(next):
				came[next] = here
				queue.append(next)
	if not came.has(to):
		return path
	var at := to
	while at != from:
		path.push_front(at)
		at = came[at]
	path.push_front(from)
	return path


## The four wall faces as quads: outer edge first (left to right as seen
## from the floor), then the matching floor edge.
func faces() -> Dictionary:
	var o := RIM
	var f := FLOOR
	return {
		"top": [o.position, Vector2(o.end.x, o.position.y),
				Vector2(f.end.x, f.position.y), f.position],
		"right": [Vector2(o.end.x, o.position.y), o.end, f.end, Vector2(f.end.x, f.position.y)],
		"bottom": [o.end, Vector2(o.position.x, o.end.y), Vector2(f.position.x, f.end.y), f.end],
		"left": [Vector2(o.position.x, o.end.y), o.position, f.position,
				Vector2(f.position.x, f.end.y)],
	}


## A point on a wall face: [param u] runs along the wall (0..1), [param v]
## from the top of the wall (0) down to the floor (1).
static func face_point(quad: Array, u: float, v: float) -> Vector2:
	var outer: Vector2 = (quad[0] as Vector2).lerp(quad[1], u)
	var inner: Vector2 = (quad[3] as Vector2).lerp(quad[2], u)
	return outer.lerp(inner, v)


func _paint_floor_and_walls() -> void:
	var dark := Polygon2D.new()
	dark.polygon = PackedVector2Array([Vector2.ZERO, Vector2(SIZE.x, 0), SIZE, Vector2(0, SIZE.y)])
	dark.color = Toon.INK
	_paint.add_child(dark)
	# The back wall faces the lamps; the side walls are turned from them, and
	# the front one is seen from behind its lit side.
	var shades := {"top": 1.0, "right": 0.84, "bottom": 0.7, "left": 0.84}
	var quads := faces()
	var look := palette()
	for side in DOORS:
		var face := Polygon2D.new()
		face.polygon = PackedVector2Array(quads[side])
		var shade: float = shades[side]
		face.color = Color(shade, shade, shade)
		var material := _painted(1, int(look.get("wall_pattern", 0)), look["wall"], look["wall_stain"],
				look.get("mortar", Toon.INK))
		var quad: Array = quads[side]
		for i in 4:
			material.set_shader_parameter("q%d" % i, quad[i])
		material.set_shader_parameter("rows", 4.0 if side == "top" or side == "bottom" else 5.0)
		var wall_texture := _texture("wall")
		if not wall_texture.is_empty():
			var courses: float = wall_texture.get("courses", 4.0)
			var rows := courses if side == "top" or side == "bottom" else courses * 1.25
			material.set_shader_parameter("rows", rows)
			_apply_texture(material, wall_texture)
			material.set_shader_parameter("tex_rows", rows if wall_texture.get("fit", false)
					else float(wall_texture.get("rows", 9.0)))
		face.material = material
		_paint.add_child(face)
	var ground := Polygon2D.new()
	var f := FLOOR
	ground.polygon = PackedVector2Array([f.position, Vector2(f.end.x, f.position.y), f.end,
			Vector2(f.position.x, f.end.y)])
	ground.material = _painted(0, int(look.get("floor_pattern", 0)), look["floor"], look["floor_stain"],
			look.get("joint", Toon.INK))
	var floor_texture := _texture("floor")
	if not floor_texture.is_empty():
		var material := ground.material as ShaderMaterial
		_apply_texture(material, floor_texture, 0.38, 0.25, 1.28)
		material.set_shader_parameter("tex_world", float(floor_texture.get("repeat", 600.0)))
	_paint.add_child(ground)


## The painted texture for this room's "floor" or "wall", or {} to draw the
## pattern.
func _texture(part: String) -> Dictionary:
	if texture_variant < 0:
		return {}
	if arena != "":
		return ARENA_TEXTURES.get(arena, {}).get(part, {})
	var choices: Array = TEXTURES[clampi(style, 0, TEXTURES.size() - 1)][part]
	return choices[clampi(texture_variant, 0, choices.size() - 1)]


func _apply_texture(material: ShaderMaterial, texture: Dictionary, tint := 0.3, desat := 0.25,
		gain := 1.0) -> void:
	material.set_shader_parameter("textured", true)
	material.set_shader_parameter("albedo", load(texture["path"]))
	material.set_shader_parameter("tex_tint", float(texture.get("tint", tint)))
	material.set_shader_parameter("tex_desat", float(texture.get("desat", desat)))
	material.set_shader_parameter("tex_gain", float(texture.get("gain", gain)))
	material.set_shader_parameter("tex_contrast", float(texture.get("contrast", 1.0)))


## The shader that paints a floor ([param part] 0) or a wall (1), lit by the
## room's lights.
func _painted(part: int, pattern: int, base: Color, stain: Color, joint: Color) -> ShaderMaterial:
	var look := palette()
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/room_paint.gdshader")
	material.set_shader_parameter("part", part)
	material.set_shader_parameter("pattern", pattern)
	material.set_shader_parameter("base", base)
	material.set_shader_parameter("stain", stain)
	material.set_shader_parameter("grout", joint)
	material.set_shader_parameter("cap", look.get("cap", base.lightened(0.2)))
	material.set_shader_parameter("trim", look.get("trim", Color("e0b23a")))
	material.set_shader_parameter("seed", float(_layout_seed % 97))
	material.set_shader_parameter("tile", TILE)
	material.set_shader_parameter("floor_origin", FLOOR.position)
	material.set_shader_parameter("floor_size", FLOOR.size)
	material.set_shader_parameter("ambient", float(look.get("ambient", 0.8)))
	var lights := PackedVector3Array()
	var colors := PackedColorArray()
	for light: Array in lights_of_room():
		var at: Vector2 = light[0]
		lights.append(Vector3(at.x, at.y, float(light[1])))
		colors.append(light[2])
	material.set_shader_parameter("light_count", lights.size())
	# Uniform arrays want their full length.
	while lights.size() < 8:
		lights.append(Vector3.ZERO)
		colors.append(Color(0, 0, 0, 0))
	material.set_shader_parameter("lights", lights)
	material.set_shader_parameter("light_colors", colors)
	return material


## The lights that paint this room: [where, radius, Color(rgb, strength)]
## each. One broad light over the middle of every room, and the lamps the
## decor or the arena hangs.
func lights_of_room() -> Array:
	var f := FLOOR
	var middle := f.get_center()
	var warm: Color = palette().get("light", Color(1, 0.85, 0.6))
	var list: Array = [[middle + Vector2(0, 30), 980.0, Color(warm, 0.3)]]
	match arena:
		"ring":
			list = [[middle + Vector2(0, 20), 720.0, Color(1, 0.96, 0.82, 0.55)]]
		"boiler":
			list.append([Vector2(f.position.x + 40, f.end.y - 40), 520.0, Color(1.0, 0.4, 0.15, 0.4)])
			list.append([Vector2(f.end.x - 40, f.end.y - 40), 520.0, Color(1.0, 0.4, 0.15, 0.4)])
			list.append([Vector2(middle.x, f.position.y - 40), 600.0, Color(1.0, 0.5, 0.2, 0.3)])
		"cabaret":
			list.append([Vector2(middle.x, f.position.y + 10), 700.0, Color(1.0, 0.85, 0.5, 0.35)])
		_:
			for i in 2:
				var x := f.position.x + f.size.x * (0.22 + 0.56 * i)
				list.append([Vector2(x, 100), 430.0, Color(warm, 0.45)])
			if style == 2:
				# Candles along the foot of the side walls.
				for i in 3:
					var at := Vector2(f.position.x - 12 if i % 2 == 0 else f.end.x + 12,
							f.position.y + 100 + i * 230.0)
					list.append([at, 210.0, Color(1.0, 0.75, 0.4, 0.4)])
	return list


## Walls are slabs round the floor, with a gap where a door is. A shut door
## fills its gap with a blocker at the floor's edge.
func _add_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = WALL_LAYER
	body.collision_mask = 0
	var f := FLOOR
	var cx := f.get_center().x
	var cy := f.get_center().y
	var half := DOOR_GAP * 0.5
	var slabs: Array[Rect2] = []
	# Top and bottom run the full width, split round a door; left and right
	# fill in between them.
	for side: String in ["top", "bottom"]:
		var y := 0.0 if side == "top" else f.end.y
		var h := f.position.y if side == "top" else SIZE.y - f.end.y
		if doors.has(side):
			slabs.append(Rect2(0, y, cx - half, h))
			slabs.append(Rect2(cx + half, y, SIZE.x - cx - half, h))
		else:
			slabs.append(Rect2(0, y, SIZE.x, h))
	for side: String in ["left", "right"]:
		var x := 0.0 if side == "left" else f.end.x
		var w := f.position.x if side == "left" else SIZE.x - f.end.x
		if doors.has(side):
			slabs.append(Rect2(x, f.position.y, w, cy - half - f.position.y))
			slabs.append(Rect2(x, cy + half, w, f.end.y - cy - half))
		else:
			slabs.append(Rect2(x, f.position.y, w, f.size.y))
	for slab in slabs:
		body.add_child(_box(slab))
	var blocks := {
		"top": Rect2(cx - half, f.position.y - 40.0, DOOR_GAP, 40.0),
		"bottom": Rect2(cx - half, f.end.y, DOOR_GAP, 40.0),
		"left": Rect2(f.position.x - 40.0, cy - half, 40.0, DOOR_GAP),
		"right": Rect2(f.end.x, cy - half, 40.0, DOOR_GAP),
	}
	for side: String in doors:
		var blocker := _box(blocks[side])
		body.add_child(blocker)
		_blockers[side] = blocker
	add_child(body)


static func _box(rect: Rect2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	return shape


## Makes a tile solid without a rock drawn on it: something else stands
## there (a shop counter).
func block_tile(cell: Vector2i) -> void:
	if not in_floor(cell) or is_rock(cell):
		return
	_solid[cell.y * COLS + cell.x] = 1
	var body := StaticBody2D.new()
	body.collision_layer = ROCK_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE * 0.8)
	shape.shape = rect
	body.add_child(shape)
	body.position = tile_center(cell) - global_position
	add_child(body)


## Blows a rock away: gone from the floor, the collision and the drawing.
func break_rock(cell: Vector2i) -> void:
	if not is_rock(cell):
		return
	_solid[cell.y * COLS + cell.x] = 0
	var parts: Array = _rocks.get(cell, [])
	for part: Node in parts:
		part.queue_free()
	_rocks.erase(cell)
	var puff := Puff.new()
	puff.radius = 44.0
	puff.stars = 0
	effects.add_child(puff)
	puff.global_position = tile_center(cell)
	rock_broken.emit(cell)


func _add_rock(cell: Vector2i) -> void:
	_solid[cell.y * COLS + cell.x] = 1
	var rock := Rock.new()
	rock.seed_value = _layout_seed * 131 + cell.x * 17 + cell.y * 5
	rock.style = style
	rock.position = tile_center(cell) - global_position
	actors.add_child(rock)
	var body := StaticBody2D.new()
	body.collision_layer = ROCK_LAYER
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE) * 0.92
	shape.shape = rect
	body.add_child(shape)
	body.position = rock.position
	add_child(body)
	_rocks[cell] = [rock, body]
