class_name BotInput
extends PlayerInput
## The demo player: keeps away from enemies and their spit, lines up with the
## nearest enemy along an axis and shoots; with the room beaten, picks up
## what is worth picking up and walks on -- to the nearest room it has not
## been in, then to the boss, then down the trapdoor. Not clever: it is there
## to show the game on screenshots and to play floors through in the checks.

const KEEP_AWAY := 240.0
const LINED_UP := 34.0

## The tile path it is following to a door, and where that path leads.
var _path: Array[Vector2i] = []
var _path_goal := Vector2i(-1, -1)
var _path_room: Room


func update(brother: Brother, _delta: float) -> void:
	var room := brother.room
	move = Vector2.ZERO
	shoot = Vector2.ZERO
	use = false
	if room == null:
		return
	# The item in its hands, charged, on a crowd or a boss.
	if brother.is_charged() and (room.enemies.size() >= 3 or (not room.enemies.is_empty() and room.enemies[0] is Boss)):
		use = true
	var me := brother.global_position
	var away := _danger(room, me)
	var nearest: Enemy = null
	var nearest_d := INF
	for enemy in room.enemies:
		var d := me.distance_to(enemy.global_position)
		if enemy.can_be_hit() and d < nearest_d:
			nearest_d = d
			nearest = enemy
	if not room.enemies.is_empty():
		if nearest == null:
			# Nothing to shoot (a boss in the air): just keep clear.
			move = (away * 2.0).limit_length(1.0)
			return
		_fight(nearest, me, away)
		return
	var goal := _next_stop(room, brother)
	if goal == Vector2.INF:
		move = (((room.center() + Vector2(0, 120)) - me) / 200.0).limit_length(1.0)
		return
	move = ((goal - me) / 40.0 + _apart(room, me)).limit_length(1.0)


## A push away from enemies closer than [constant KEEP_AWAY] (more for big
## ones), from spit coming its way, from its brother, and off the walls.
func _danger(room: Room, me: Vector2) -> Vector2:
	var away := Vector2.ZERO
	for enemy in room.enemies:
		var d := me - enemy.global_position
		var keep := KEEP_AWAY + enemy.radius
		if d.length() < keep:
			away += d.normalized() * (keep - d.length()) / keep
	for node in room.actors.get_children():
		var shot := node as Shot
		if shot != null and shot.hostile and shot.global_position.distance_to(me) < 180.0:
			var side := shot.velocity.orthogonal().normalized()
			away += side * signf(side.dot(me - shot.global_position) + 0.01) * 1.5
	away += _apart(room, me)
	# Off the spikes, and clear of a keg about to go.
	var here := room.tile_at(me)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := here + Vector2i(dx, dy)
			var gap := me - room.tile_center(cell)
			if room.is_spike(cell) and gap.length() < Room.TILE * 0.95:
				away += gap.normalized() * 1.2
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var cell := here + Vector2i(dx, dy)
			if room.is_barrel(cell):
				var keg: Barrel = room._barrels[cell][0]
				var gap := me - room.tile_center(cell)
				if keg.hits > 0 and gap.length() < Barrel.REACH * 1.2:
					away += gap.normalized()
	var inside := room.floor_rect().grow(-80.0)
	if not inside.has_point(me):
		away += (inside.get_center() - me).normalized() * 0.8
	return away


func _fight(nearest: Enemy, me: Vector2, away: Vector2) -> void:
	var room := nearest.room
	var to := nearest.global_position - me
	var lined := LINED_UP + nearest.radius * 0.5
	var clear := _clear(room, me, nearest.global_position)
	if clear and absf(to.y) < lined:
		shoot = Vector2(signf(to.x), 0)
	elif clear and absf(to.x) < lined:
		shoot = Vector2(0, signf(to.y))
	# Where to stand: the nearest tile in line with the enemy, with nothing
	# between, not too close. Rocks make "just line up" useless.
	var here := room.tile_at(me)
	var spot := _firing_tile(room, here, room.tile_at(nearest.global_position))
	var line_up := Vector2.ZERO
	if spot != Vector2i(-1, -1) and spot != here:
		var path := room.path_to(here, spot)
		var next := room.tile_center(path[1]) if path.size() > 1 else room.tile_center(spot)
		line_up = (next - me).normalized()
	else:
		# In place: line up exactly, and keep a distance along the other axis.
		var keep := 280.0 + nearest.radius
		if absf(to.x) < absf(to.y):
			line_up.x = clampf(to.x / 60.0, -1.0, 1.0)
			if absf(to.y) < keep:
				line_up.y = -signf(to.y)
		else:
			line_up.y = clampf(to.y / 60.0, -1.0, 1.0)
			if absf(to.x) < keep:
				line_up.x = -signf(to.x)
	move = (line_up + away * 2.0).limit_length(1.0)


## A push off its brother: two bots would stand in the very same spot and
## look like one.
static func _apart(room: Room, me: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for other in room.brothers:
		var gap := me - other.global_position
		if gap.length() > 0.5 and gap.length() < 110.0:
			push += gap.normalized() * (110.0 - gap.length()) / 110.0 * 0.7
	return push


## True when a shot from [param a] to [param b] would not hit a rock.
static func _clear(room: Room, a: Vector2, b: Vector2) -> bool:
	var steps := int(a.distance_to(b) / 30.0)
	for i in range(1, steps):
		if room.is_rock(room.tile_at(a.lerp(b, float(i) / steps))):
			return false
	return true


## The open tile nearest to [param here] (by walking) in the same row or
## column as [param enemy], two to six tiles from it, with a clear line of
## fire; (-1, -1) if there is none.
static func _firing_tile(room: Room, here: Vector2i, enemy: Vector2i) -> Vector2i:
	if not room.in_floor(here):
		return Vector2i(-1, -1)
	var seen := {here: true}
	var queue: Array[Vector2i] = [here]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		var gap := absi(tile.x - enemy.x) + absi(tile.y - enemy.y)
		if (tile.x == enemy.x or tile.y == enemy.y) and gap >= 2 and gap <= 6 \
				and _clear(room, room.tile_center(tile), room.tile_center(enemy)):
			return tile
		for step: Vector2i in FloorPlan.SIDES.values():
			var next := tile + step
			if room.in_floor(next) and not room.is_blocked(next) and not room.is_spike(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return Vector2i(-1, -1)


## The next point to walk to with the room beaten, or INF for nowhere.
func _next_stop(room: Room, brother: Brother) -> Vector2:
	# Hearts it can use first.
	for node in room.actors.get_children():
		var pickup := node as Pickup
		if pickup != null and not pickup.gone and not pickup.wait_clear and pickup.price <= brother.coins:
			var hearts := pickup.kind == "heart" or pickup.kind == "half_heart"
			var useful := not hearts or brother.hp < brother.stats.max_hp()
			# One item in the hands is enough: swapping would leave the old
			# one under its feet, to be swapped back for ever.
			if pickup.kind == "item" and brother.active != "" \
					and GameData.items().get(pickup.item, {}).has("active"):
				useful = false
			if pickup.kind == "gold_chest" and brother.keys <= 0:
				useful = false
			if useful:
				return _walk_to(room, brother, room.tile_at(pickup.global_position), pickup.global_position)
	var run := room.run
	if run == null or run.busy:
		return Vector2.INF
	if run.trapdoor != null:
		return _walk_to(room, brother, room.tile_at(run.trapdoor.global_position), run.trapdoor.global_position)
	var side := run.plan.step_towards(run.cell, run.bot_goal(brother.keys > 0))
	if side == "":
		return Vector2.INF
	var door_tile: Vector2i = RoomLayouts.DOOR_TILES[side]
	var beyond := room.door_point(side) + Vector2(FloorPlan.SIDES[side]) * (Room.EXIT_DEPTH + 30.0)
	return _walk_to(room, brother, door_tile, beyond)


## The next point along a tile path to [param tile], then [param end].
func _walk_to(room: Room, brother: Brother, tile: Vector2i, end: Vector2) -> Vector2:
	var here := room.tile_at(brother.global_position)
	if _path_room != room or _path_goal != tile or _path.is_empty() or not _path.has(here):
		_path.clear()
		if room.in_floor(here):
			_path = room.path_to(here, tile)
		_path_goal = tile
		_path_room = room
	if _path.is_empty():
		return end
	var at := _path.find(here)
	if at < 0 or at >= _path.size() - 1:
		return end
	return room.tile_center(_path[at + 1])
