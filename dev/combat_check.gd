extends SceneTree
## The fight's arithmetic, on a real room with the real classes: a shot takes
## exactly the brother's damage off what it hits, rocks stop shots, touching
## an enemy costs half a heart and then a second of grace, spit hurts, shots
## fall where their range runs out, and a wave appears away from the brother
## and ends when it is knocked out.
##
##     godot --headless --fixed-fps 60 --path . --script res://dev/combat_check.gd
##
## Numbers are read from the data, never written in here: tuning a brother
## must not break this check.

const EMPTY := [
	".............", ".............", ".............", ".............",
	".............", ".............", ".............",
]
const ROCK_IN_ROW_3 := [
	".............", ".............", ".............", ".....#.......",
	".............", ".............", ".............",
]

var _failures := 0
var _checks := 0
var room: Room


func _initialize() -> void:
	Controls.setup()
	_run()


func _run() -> void:
	await process_frame
	await _shot_hits()
	await _two_shots_knock_out_a_fly()
	await _rock_stops_shot()
	await _shot_falls_at_range()
	await _touch_and_grace()
	await _spit_hurts()
	await _wave_spawns_clear_and_ends()
	print("combat: %d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _shot_hits() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(2, 3))
	var walker := _enemy("walker", Vector2i(7, 3))
	var before := walker.hp
	var shot := await _fire(brother, Vector2.RIGHT)
	await _finish(shot, 120)
	_expect(is_equal_approx(walker.hp, before - brother.stats.damage),
			"a shot takes the brother's damage (%.1f → %.1f, damage %.1f)" % [before, walker.hp, brother.stats.damage])


func _two_shots_knock_out_a_fly() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(2, 3))
	var fly := _enemy("fly", Vector2i(6, 3))
	var fly_hp := fly.max_hp
	var needed := ceili(fly_hp / brother.stats.damage)
	var out := [false]
	fly.knocked_out.connect(func(_e: Enemy) -> void: out[0] = true)
	for i in needed:
		await _fire(brother, Vector2.RIGHT)
		await _steps(40)
	_expect(out[0], "%d shots knock out a fly (%.0f hp at %.1f a shot)" % [needed, fly_hp, brother.stats.damage])
	_expect(room.enemies.is_empty(), "a knocked-out enemy leaves the room's list")


func _rock_stops_shot() -> void:
	await _fresh_room(ROCK_IN_ROW_3)
	var brother := _brother(Vector2i(2, 3))
	var walker := _enemy("walker", Vector2i(8, 3))
	var shot := await _fire(brother, Vector2.RIGHT)
	var result := await _finish(shot, 120)
	_expect(is_equal_approx(walker.hp, walker.max_hp), "a rock in the way keeps the enemy whole")
	_expect(result[0] == "wall", "the shot ends on the rock (ended: '%s')" % result[0])


func _shot_falls_at_range() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(0, 3))
	var shot := await _fire(brother, Vector2.RIGHT)
	var result := await _finish(shot, 240)
	var reach := brother.stats.range_px()
	_expect(result[0] == "floor", "an unobstructed shot lands on the floor (ended: '%s')" % result[0])
	_expect(result[1] > reach * 0.9 and result[1] < reach * 1.3,
			"it lands near its range (%.0f px for a range of %.0f)" % [result[1], reach])


func _touch_and_grace() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(6, 3))
	var full := brother.hp
	var fly := _enemy("fly", Vector2i(6, 3))
	fly.global_position = brother.global_position
	await _steps(2)
	_expect(brother.hp == full - fly.contact, "touching an enemy costs %d half heart (hp %d → %d)" % [fly.contact, full, brother.hp])
	_expect(not brother.hurt(1, fly.global_position), "no second hit during the grace second")
	_expect(brother.hp == full - fly.contact, "grace keeps the hearts")
	fly.knock_out()
	await _steps(int(Brother.INVULNERABLE * 60) + 2)
	_expect(brother.hurt(1, brother.global_position + Vector2.RIGHT), "hits land again after the grace second")
	brother.hp = 1
	var died := [false]
	brother.died.connect(func() -> void: died[0] = true)
	await _steps(int(Brother.INVULNERABLE * 60) + 2)
	brother.hurt(1, brother.global_position + Vector2.RIGHT)
	_expect(died[0] and brother.dead and brother.hp == 0, "the last half heart knocks him out")


func _spit_hurts() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(3, 3))
	var full := brother.hp
	var shooter := _enemy("shooter", Vector2i(9, 3)) as ShooterEnemy
	shooter._aim = (brother.global_position - shooter.global_position).normalized()
	shooter._spit()
	await _steps(120)
	_expect(brother.hp == full - 1, "spit costs half a heart (hp %d → %d)" % [full, brother.hp])


func _wave_spawns_clear_and_ends() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(6, 3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var waves := Waves.new()
	room.add_child(waves)
	var ended := [false]
	waves.cleared.connect(func() -> void: ended[0] = true)
	waves.begin(room, rng, [{"fly": 2, "walker": 1}])
	await _until(func() -> bool: return not room.enemies.is_empty(), 120)
	_expect(room.enemies.size() == 3, "the wave brings its three enemies (%d)" % room.enemies.size())
	var nearest := INF
	for enemy in room.enemies:
		nearest = minf(nearest, enemy.global_position.distance_to(brother.global_position))
	_expect(nearest >= Waves.SAFE_DISTANCE - 1.0, "none appears within reach (nearest %.0f px)" % nearest)
	for enemy in room.enemies.duplicate():
		enemy.knock_out()
	await _until(func() -> bool: return ended[0], 30)
	_expect(ended[0], "knocking out the last wave clears the room")


# --- helpers ---------------------------------------------------------------


func _fresh_room(layout: Array) -> void:
	if room != null:
		room.queue_free()
		await process_frame
	room = Room.new()
	root.add_child(room)
	room.build(PackedStringArray(layout), 1)
	await process_frame


func _brother(cell: Vector2i) -> Brother:
	var brother := Brother.new()
	brother.setup("younger", room, PlayerInput.new())
	room.actors.add_child(brother)
	brother.global_position = room.tile_center(cell)
	room.brothers.append(brother)
	return brother


## An enemy that has finished popping in and stands still: these checks are
## about hits, not about aim.
func _enemy(kind: String, cell: Vector2i) -> Enemy:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var enemy := Waves.spawn(kind, room, rng, room.tile_center(cell))
	enemy._spawn = 0.0
	enemy.set_physics_process(false)
	return enemy


## Holds the shoot button for one tick and returns the shot that came out.
##
## `physics_frame` fires at the start of a tick, before any node's
## _physics_process: the first await lands before the tick the brother will
## see the button in, the second after it.
func _fire(brother: Brother, aim: Vector2) -> Shot:
	var before := brother.shots_fired
	brother.input.shoot = aim
	await physics_frame
	await physics_frame
	brother.input.shoot = Vector2.ZERO
	_expect(brother.shots_fired == before + 1, "holding shoot for a tick fires once")
	for node in room.actors.get_children():
		if node is Shot and not (node as Shot).hostile:
			return node as Shot
	return null


## Waits for [param shot] to end; returns [what stopped it, how far it flew].
## Read from its signal: a shot frees itself the tick it ends, so polling
## for it never sees how it ended.
func _finish(shot: Shot, max_steps: int) -> Array:
	var result := ["", 0.0]
	if shot == null:
		return result
	shot.finished.connect(func(how: String) -> void:
		result[0] = how
		result[1] = shot.travelled)
	await _until(func() -> bool: return result[0] != "", max_steps)
	return result


func _steps(n: int) -> void:
	for i in n:
		await physics_frame


func _until(done: Callable, max_steps: int) -> void:
	for i in max_steps:
		if done.call():
			return
		await physics_frame


func _expect(ok: bool, what: String) -> void:
	_checks += 1
	if ok:
		print("   ok  " + what)
	else:
		_failures += 1
		printerr("FAILED: " + what)
