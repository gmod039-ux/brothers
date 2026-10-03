class_name FloorPlan
extends RefCounted
## A floor's map: which cells of a small grid hold rooms, what each room is
## and which layout it uses. Grown the way Isaac grows its floors: out from
## the start, a room at a time, never next to more than one room already
## there -- so the floor branches instead of clumping -- with the boss in the
## dead end furthest from the start, the treasure room in another and, when
## there is a third, a shop. Below the first floor both are locked. Dead
## ends to spare get an arcade with a slot machine and a challenge room.
##
## And, as in Isaac, a secret room: in a gap between two or three rooms,
## behind a wall with a crack in it. It is not on the plan's [member rooms]
## until a bomb opens the wall ([method reveal_secret]); till then nothing
## knows it is there -- no doors, no map, no way for the bot.

const WIDTH := 9
const HEIGHT := 8
const SIDES := {
	"top": Vector2i(0, -1),
	"right": Vector2i(1, 0),
	"bottom": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
}
const OPPOSITE := {"top": "bottom", "bottom": "top", "left": "right", "right": "left"}
## How many floors have a mini-boss in one of their fight rooms.
const MINIBOSS_CHANCE := 0.7


class RoomInfo:
	var cell := Vector2i.ZERO
	## "start", "normal", "boss", "treasure", "shop", "arcade",
	## "challenge", "miniboss" or "secret".
	var kind := "normal"
	var layout_name := ""
	var rows := PackedStringArray()
	## Steps from the start.
	var depth := 0
	var visited := false
	## On the map without having been near it: the glasses show it.
	var seen := false
	var cleared := false
	## The treasure room's prize has been picked up.
	var looted := false
	## Needs a key to get in.
	var locked := false
	## The item waiting here (treasure room), once chosen.
	var prize := ""
	## A shop's wares: [kind, item, price] each; bought ones are removed.
	var stock: Array = []
	## The Baron's contract in a beaten boss's room: [item, hearts] each.
	var deal: Array = []
	## Things left lying on the floor when the brothers walked out:
	## [kind, item, price, position in the room].
	var pickups: Array = []
	## Rocks blown up: cell -> true.
	var broken := {}


var index := 0
var rooms := {}
var start := Vector2i(4, 4)
var boss := Vector2i.ZERO
var treasure := Vector2i.ZERO
## No shop when the floor has only two dead ends: (-1, -1).
var shop := Vector2i(-1, -1)
## The arcade (a slot machine) and the challenge room, in dead ends left
## over: (-1, -1) for none.
var arcade := Vector2i(-1, -1)
var challenge := Vector2i(-1, -1)
## The fight room the floor's mini-boss waits in, (-1, -1) for none.
var miniboss := Vector2i(-1, -1)
## The secret room, (-1, -1) for none; its info, kept off [member rooms]
## while it is hidden.
var secret := Vector2i(-1, -1)
var secret_info: RoomInfo
## The compass points at the hidden secret room: the map shows where.
var secret_hinted := false


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
	ends.erase(plan.treasure)
	if not ends.is_empty():
		plan.shop = ends[rng.randi() % ends.size()]
		ends.erase(plan.shop)
	# Then, in any dead ends left, an arcade and a challenge -- which first
	# is a toss of a coin.
	var extras := ["arcade", "challenge"]
	if rng.randf() < 0.5:
		extras.reverse()
	for extra: String in extras:
		if ends.is_empty():
			break
		var end := ends[rng.randi() % ends.size()]
		ends.erase(end)
		if extra == "arcade":
			plan.arcade = end
		else:
			plan.challenge = end
	for cell: Vector2i in depth:
		var info := RoomInfo.new()
		info.cell = cell
		info.depth = int(depth[cell])
		plan.rooms[cell] = info
	plan._hide_secret(rng, depth)
	return plan


## Picks the secret room's cell: an empty one touching the most rooms (two
## at least), none of them the boss's, the treasure room or the shop -- they
## stay dead ends.
func _hide_secret(rng: RandomNumberGenerator, depth: Dictionary) -> void:
	var best: Array[Vector2i] = []
	var most := 1
	for cell: Vector2i in depth:
		for step: Vector2i in SIDES.values():
			var spot: Vector2i = cell + step
			if depth.has(spot) or spot.x < 0 or spot.y < 0 or spot.x >= WIDTH or spot.y >= HEIGHT:
				continue
			var n := 0
			var shallow := 99
			var special := false
			for around: Vector2i in SIDES.values():
				var next: Vector2i = spot + around
				if depth.has(next):
					n += 1
					shallow = mini(shallow, int(depth[next]))
					special = special or next in [boss, treasure, shop]
			if special or n < 2 or best.has(spot):
				continue
			if n > most:
				most = n
				best.clear()
			if n == most:
				best.append(spot)
	if best.is_empty():
		return
	secret = best[rng.randi() % best.size()]
	secret_info = RoomInfo.new()
	secret_info.cell = secret
	var shallow := 99
	for around: Vector2i in SIDES.values():
		if depth.has(secret + around):
			shallow = mini(shallow, int(depth[secret + around]))
	secret_info.depth = shallow + 1


## True while [param cell] is the secret room and still hidden.
func is_hidden_secret(cell: Vector2i) -> bool:
	return secret_info != null and cell == secret and not rooms.has(secret)


## Every room on the map, as with the glasses on: all but a secret room
## still hidden.
func reveal_all() -> void:
	for cell: Vector2i in rooms:
		var room_info: RoomInfo = rooms[cell]
		room_info.seen = true


## The special rooms on the map, and where the secret room is (shown with
## a question mark while still hidden): the compass.
func reveal_special() -> void:
	for cell: Vector2i in rooms:
		var room_info: RoomInfo = rooms[cell]
		if not room_info.kind in ["normal", "start"]:
			room_info.seen = true
	secret_hinted = secret_info != null


## The wall is down: the secret room joins the floor.
func reveal_secret() -> void:
	if secret_info != null and not rooms.has(secret):
		rooms[secret] = secret_info


func _furnish(rng: RandomNumberGenerator, layouts: RoomLayouts) -> void:
	var fights := layouts.fights()
	var deck: Array[String] = []
	# On most floors one fight room, two steps from the start at least, is
	# the mini-boss's.
	if rng.randf() < MINIBOSS_CHANCE:
		var fit: Array[Vector2i] = []
		for cell: Vector2i in rooms:
			var room_info: RoomInfo = rooms[cell]
			if room_info.depth >= 2 and not cell in [start, boss, treasure, shop, arcade, challenge]:
				fit.append(cell)
		if not fit.is_empty():
			miniboss = fit[rng.randi() % fit.size()]
			var chosen: RoomInfo = rooms[miniboss]
			chosen.kind = "miniboss"
	for cell: Vector2i in rooms:
		var info: RoomInfo = rooms[cell]
		if cell == start:
			info.kind = "start"
		elif cell == boss:
			info.kind = "boss"
		elif cell == treasure:
			info.kind = "treasure"
		elif cell == shop:
			info.kind = "shop"
		elif cell == arcade:
			info.kind = "arcade"
		elif cell == challenge:
			info.kind = "challenge"
		if info.kind != "normal":
			info.layout_name = "@" + info.kind
			info.cleared = not info.kind in ["boss", "challenge", "miniboss"]
			info.locked = index > 0 and info.kind in ["treasure", "shop"]
		else:
			# Deal layouts from a shuffled deck, so a floor repeats one only
			# once it has used them all.
			if deck.is_empty():
				deck.assign(fights)
				_shuffle(deck, rng)
			info.layout_name = deck.pop_back()
		info.rows = layouts.get_rows(info.layout_name)
	if secret_info != null:
		secret_info.kind = "secret"
		secret_info.layout_name = "@secret"
		secret_info.cleared = true
		secret_info.rows = layouts.get_rows("@secret")
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
	if here.visited or here.seen:
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
