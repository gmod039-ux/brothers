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

## Palettes of the basement: walls in brick red-brown, floor in warm stone.
const WALL_FACE := Color("a0563a")
const WALL_STAIN := Color("6e3524")
const FLOOR_BASE := Color("e9d6ac")
const FLOOR_STAIN := Color("c6a26c")
const GROUT := Color(0.42, 0.29, 0.18, 0.55)
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
## The doors: side -> the kind of room beyond it ("normal", "boss",
## "treasure", "start"). Sides without a door are plain wall.
var doors := {}
## Which doors are open. A door that is shut is a wall.
var open_doors := {}
## The cell of the floor this room is in.
var cell := Vector2i.ZERO
## The run this room is part of; null in tests and the arena.
var run: Run

var _blockers := {}

var _solid := PackedByteArray()
var _paint: Node2D
var _layout_seed := 0


func _init() -> void:
	_solid.resize(COLS * ROWS)


## Builds the room from a text layout: [constant ROWS] lines of
## [constant COLS] characters, `.` floor and `#` rock (letters for enemies
## are the run's business). [param doors_] is [member doors]; they start
## shut.
func build(layout: PackedStringArray, seed_value: int, doors_ := {}) -> void:
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
	_add_walls()
	decals = Node2D.new()
	decals.name = "Decals"
	add_child(decals)
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
			if line[col] == "#":
				_add_rock(Vector2i(col, row))


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
## wall, or a rock.
func blocks_shot(at: Vector2) -> bool:
	var local := at - global_position
	if not FLOOR.has_point(local):
		return true
	return is_rock(tile_at(at))


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


func set_doors_open(open: bool) -> void:
	for side: String in doors:
		open_doors[side] = open
		var blocker := _blockers.get(side) as CollisionShape2D
		if blocker != null:
			blocker.set_deferred("disabled", open)
	var lines := get_node_or_null("Lines") as CanvasItem
	if lines != null:
		lines.queue_redraw()


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
	var shades := {"top": 1.0, "right": 0.86, "bottom": 0.72, "left": 0.86}
	var quads := faces()
	for side in DOORS:
		var face := Polygon2D.new()
		face.polygon = PackedVector2Array(quads[side])
		var shade: float = shades[side]
		face.color = Color(shade, shade, shade)
		face.material = _paper(WALL_FACE, WALL_STAIN, 180.0, 0.55)
		_paint.add_child(face)
	var ground := Polygon2D.new()
	var f := FLOOR
	ground.polygon = PackedVector2Array([f.position, Vector2(f.end.x, f.position.y), f.end,
			Vector2(f.position.x, f.end.y)])
	ground.material = _paper(FLOOR_BASE, FLOOR_STAIN, 260.0, 0.7)
	_paint.add_child(ground)


func _paper(base: Color, stain: Color, blotch: float, amount: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/paper.gdshader")
	material.set_shader_parameter("base", base)
	material.set_shader_parameter("stain", stain)
	material.set_shader_parameter("blotch", blotch)
	material.set_shader_parameter("amount", amount)
	material.set_shader_parameter("seed", float(_layout_seed % 97))
	return material


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


func _add_rock(cell: Vector2i) -> void:
	_solid[cell.y * COLS + cell.x] = 1
	var rock := Rock.new()
	rock.seed_value = _layout_seed * 131 + cell.x * 17 + cell.y * 5
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
