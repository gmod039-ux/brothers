class_name FloorPlan
extends RefCounted
## A floor's map: which cells of a small grid hold rooms, what each room is
## and which layout it uses. Grown the way Isaac grows its floors: out from
## the start, a room at a time, never next to more than one room already
## there -- so the floor branches instead of clumping -- with the boss in the
## dead end furthest from the start and the treasure room in another.

const WIDTH := 9
const HEIGHT := 8
const SIDES := {
	"top": Vector2i(0, -1),
	"right": Vector2i(1, 0),
	"bottom": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
}
const OPPOSITE := {"top": "bottom", "bottom": "top", "left": "right", "right": "left"}


class RoomInfo:
	var cell := Vector2i.ZERO
	## "start", "normal", "boss" or "treasure".
	var kind := "normal"
	var layout_name := ""
	var rows := PackedStringArray()
	## Steps from the start.
	var depth := 0
	var visited := false
	var cleared := false
	## The treasure room's prize has been picked up.
	var looted := false


var index := 0
var rooms := {}
var start := Vector2i(4, 4)
var boss := Vector2i.ZERO
var treasure := Vector2i.ZERO


## Grows floor [param floor_index] (0 is the first): more rooms deeper down.
static func generate(rng: RandomNumberGenerator, floor_index: int, layouts: RoomLayouts) -> FloorPlan:
	var target := 7 + floor_index * 2 + rng.randi_range(0, 2)
	for attempt in 500:
		var plan := _grow(rng, target)
		if plan != null:
			plan.index = floor_index
			plan._furnish(rng, layouts)
			return plan
	push_error("no floor after 500 tries")
	return null


static func _grow(rng: RandomNumberGenerator, target: int) -> FloorPlan:
	var plan := FloorPlan.new()
	var depth := {plan.start: 0}
	var queue: Array[Vector2i] = [plan.start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var directions: Array = SIDES.values()
		_shuffle(directions, rng)
		for step: Vector2i in directions:
			var next := cell + step
			if depth.size() >= target:
				break
			if next.x < 0 or next.y < 0 or next.x >= WIDTH or next.y >= HEIGHT:
				continue
			if depth.has(next) or _neighbours(depth, next) > 1:
				continue
			if rng.randf() < 0.5:
				continue
			depth[next] = int(depth[cell]) + 1
			queue.append(next)
	if depth.size() < target:
		return null
	var ends: Array[Vector2i] = []
	for cell: Vector2i in depth:
		if cell != plan.start and _neighbours(depth, cell) == 1:
			ends.append(cell)
	if ends.size() < 2:
		return null
	# The boss: the dead end furthest from the start, never right next to it.
	var far := ends[0]
	for cell in ends:
		if int(depth[cell]) > int(depth[far]):
			far = cell
	if int(depth[far]) < 2:
		return null
	ends.erase(far)
	plan.boss = far
	plan.treasure = ends[rng.randi() % ends.size()]
	for cell: Vector2i in depth:
		var info := RoomInfo.new()
		info.cell = cell
		info.depth = int(depth[cell])
		plan.rooms[cell] = info
	return plan


func _furnish(rng: RandomNumberGenerator, layouts: RoomLayouts) -> void:
	var fights := layouts.fights()
	var deck: Array[String] = []
	for cell: Vector2i in rooms:
		var info: RoomInfo = rooms[cell]
		if cell == start:
			info.kind = "start"
		elif cell == boss:
			info.kind = "boss"
		elif cell == treasure:
			info.kind = "treasure"
		if info.kind != "normal":
			info.layout_name = "@" + info.kind
			info.cleared = info.kind != "boss"
		else:
			# Deal layouts from a shuffled deck, so a floor repeats one only
			# once it has used them all.
			if deck.is_empty():
				deck.assign(fights)
				_shuffle(deck, rng)
			info.layout_name = deck.pop_back()
		info.rows = layouts.get_rows(info.layout_name)
	var first: RoomInfo = rooms[start]
	first.visited = true


## The sides of [param cell] that have a room beyond them.
func doors(cell: Vector2i) -> Dictionary:
	var out := {}
	for side: String in SIDES:
		var next: Vector2i = cell + SIDES[side]
		if rooms.has(next):
			var info: RoomInfo = rooms[next]
			out[side] = info.kind
	return out


func info(cell: Vector2i) -> RoomInfo:
	return rooms.get(cell)


## Rooms to be shown on the map: those visited, and those next to a
## visited one (seen through an open door).
func known(cell: Vector2i) -> bool:
	var here: RoomInfo = rooms.get(cell)
	if here == null:
		return false
	if here.visited:
		return true
	for step: Vector2i in SIDES.values():
		var next: RoomInfo = rooms.get(cell + step)
		if next != null and next.visited:
			return true
	return false


## The side of [param from] to leave by to get one step closer to
## [param to], through rooms of the plan; "" if already there.
func step_towards(from: Vector2i, to: Vector2i) -> String:
	if from == to:
		return ""
	var came := {to: to}
	var queue: Array[Vector2i] = [to]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in SIDES.values():
			var next := cell + step
			if rooms.has(next) and not came.has(next):
				came[next] = cell
				queue.append(next)
	if not came.has(from):
		return ""
	var toward: Vector2i = came[from]
	for side: String in SIDES:
		if from + SIDES[side] == toward:
			return side
	return ""


static func _neighbours(cells: Dictionary, cell: Vector2i) -> int:
	var n := 0
	for step: Vector2i in SIDES.values():
		if cells.has(cell + step):
			n += 1
	return n


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = items[i]
		items[i] = items[j]
		items[j] = t
