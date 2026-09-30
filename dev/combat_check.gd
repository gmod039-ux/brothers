extends SceneTree
## The fight's arithmetic, on a real room with the real classes: a shot takes
## exactly the brother's damage off what it hits, rocks stop shots, touching
## an enemy costs half a heart and then a second of grace, spit hurts, shots
## fall where their range runs out, and a wave appears away from the brother
## and ends when it is knocked out. Two brothers share one pocket, and one
## knocked out gets up once the room is clear -- unless both are down. The
## items in hand charge by rooms and do what they say.
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
	await _items()
	await _bomb()
	await _shop()
	await _coop()
	await _actives()
	await _trapdoor_stays()
	await _last_blow()
	await _key_opens_door()
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
	shooter._spit(shooter._aim)
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


func _items() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(1, 3))
	var items := GameData.items()
	var damage := brother.stats.damage
	brother.take_item("pepper")
	_expect(is_equal_approx(brother.stats.damage, damage + float(items["pepper"]["add"]["damage"])),
			"the pepper adds its damage (%.1f → %.1f)" % [damage, brother.stats.damage])
	var hearts := brother.stats.hearts
	brother.take_item("pie")
	_expect(brother.stats.hearts == hearts + 1 and brother.hp == brother.stats.max_hp(), "the pie adds a full heart")
	# The fork: three shots a press.
	brother.take_item("fork")
	var before := room.actors.get_child_count()
	await _fire(brother, Vector2.RIGHT)
	_expect(room.actors.get_child_count() - before == 3, "the fork fires three shots (%d)"
			% (room.actors.get_child_count() - before))
	# The needle: one shot through two walkers in a row.
	await _fresh_room(EMPTY)
	brother = _brother(Vector2i(1, 3))
	brother.take_item("needle")
	var first := _enemy("walker", Vector2i(4, 3))
	var second := _enemy("walker", Vector2i(6, 3))
	var shot := await _fire(brother, Vector2.RIGHT)
	await _finish(shot, 120)
	_expect(first.hp < first.max_hp and second.hp < second.max_hp, "the needle's shot goes through both walkers")
	# Ghost ink: over a rock.
	await _fresh_room(ROCK_IN_ROW_3)
	brother = _brother(Vector2i(2, 3))
	brother.take_item("ghost")
	var walker := _enemy("walker", Vector2i(8, 3))
	shot = await _fire(brother, Vector2.RIGHT)
	await _finish(shot, 120)
	_expect(walker.hp < walker.max_hp, "ghost ink flies over the rock")


func _bomb() -> void:
	await _fresh_room(ROCK_IN_ROW_3)
	var brother := _brother(Vector2i(4, 3))
	var walker := _enemy("walker", Vector2i(4, 2))
	var bombs := brother.bombs
	var bomb := brother.place_bomb()
	_expect(brother.bombs == bombs - 1, "placing a bomb uses one up")
	var full := brother.hp
	await _steps(int(Bomb.FUSE * 60) + 4)
	_expect(not room.is_rock(Vector2i(5, 3)), "the blast breaks the rock next to it")
	_expect(not is_instance_valid(walker) or walker.hp <= walker.max_hp - Bomb.DAMAGE, "the blast hurts the walker")
	_expect(brother.hp == full - 2, "standing on it costs a whole heart (hp %d → %d)" % [full, brother.hp])
	_expect(not is_instance_valid(bomb), "the bomb is gone")


func _shop() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(2, 3))
	var pickup := Pickup.new()
	pickup.kind = "bomb"
	pickup.price = 5
	pickup.room = room
	room.actors.add_child(pickup)
	pickup.global_position = brother.global_position
	var bombs := brother.bombs
	await _steps(40)
	_expect(is_instance_valid(pickup) and brother.bombs == bombs, "no coins, no bomb")
	brother.coins = 7
	await _steps(4)
	_expect(not is_instance_valid(pickup) and brother.bombs == bombs + 1 and brother.coins == 2,
			"with the coins it is bought (coins 7 → %d)" % brother.coins)


func _coop() -> void:
	await _fresh_room(EMPTY)
	var first := _brother(Vector2i(2, 3))
	var second := _brother(Vector2i(10, 3))
	second.purse = first.purse
	var coin := Pickup.new()
	coin.kind = "coin"
	coin.room = room
	room.actors.add_child(coin)
	coin.global_position = second.global_position
	var before := first.coins
	await _steps(40)
	_expect(first.coins == before + 1 and second.coins == first.coins,
			"a coin one brother picks up is in both brothers' pocket (%d, %d)" % [first.coins, second.coins])
	room.queue_free()
	room = null
	# On a real floor: the first room has nobody in it.
	var camera := Camera2D.new()
	root.add_child(camera)
	var run := Run.new()
	root.add_child(run)
	var a := Brother.new()
	a.setup("older", null, PlayerInput.new())
	var b := Brother.new()
	b.setup("younger", null, PlayerInput.new())
	b.purse = a.purse
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	run.begin(rng, camera, [a, b] as Array[Brother])
	await _steps(2)
	b.hp = 1
	b.hurt(1, b.global_position + Vector2(40, 0))
	_expect(b.dead and not a.dead, "the second brother is knocked out, the first is up")
	await _steps(int(Run.REVIVE_AFTER * 60.0) + 10)
	_expect(not b.dead and b.hp == 2, "once the room is clear he gets up with a heart (hp %d)" % b.hp)
	# Past the blinking after getting up, then both go down.
	await _steps(int(Brother.INVULNERABLE * 2.0 * 60.0) + 10)
	a.hp = 1
	b.hp = 1
	a.hurt(1, a.global_position + Vector2(40, 0))
	b.hurt(1, b.global_position + Vector2(40, 0))
	await _steps(int(Run.REVIVE_AFTER * 60.0) + 10)
	_expect(a.dead and b.dead, "with both knocked out nobody gets up")
	run.queue_free()
	camera.queue_free()
	await process_frame


func _actives() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(2, 3))
	var walker := _enemy("walker", Vector2i(8, 3))
	brother.take_item("camera")
	_expect(brother.active == "camera" and brother.is_charged(), "a camera picked up is in his hands, charged")
	var before := walker.hp
	_expect(brother.use_active(), "the flash goes off")
	_expect(is_equal_approx(walker.hp, before - ActiveItems.FLASH_DAMAGE) and walker.is_dazed(),
			"it singes the walker and dazes it (%.1f → %.1f)" % [before, walker.hp])
	_expect(brother.charge == 0 and not brother.use_active(), "then it is empty and does nothing")
	walker.global_position = brother.global_position
	var hp := brother.hp
	await _steps(10)
	_expect(brother.hp == hp, "a dazed walker does not hurt on touch")
	for i in brother.max_charge():
		brother.add_charge()
	_expect(brother.is_charged(), "%d beaten rooms charge it again" % brother.max_charge())
	# Dynamite: a big bang ahead, and the brother untouched even close by.
	await _fresh_room(EMPTY)
	brother = _brother(Vector2i(3, 3))
	brother.look.facing = Vector2.RIGHT
	walker = _enemy("walker", Vector2i(6, 3))
	before = walker.hp
	hp = brother.hp
	brother.take_item("dynamite")
	brother.use_active()
	await _steps(90)
	_expect(not is_instance_valid(walker) or walker.hp < before, "the dynamite hurts the walker")
	_expect(brother.hp == hp, "and spares the brother (hp %d)" % brother.hp)
	# Another item for his hands: the old one is left on the floor.
	brother.take_item("watch")
	var left: Pickup = null
	for node in room.actors.get_children():
		if node is Pickup:
			left = node
	_expect(brother.active == "watch" and left != null and left.item == "dynamite",
			"taking the watch leaves the dynamite on the floor")
	await _steps(60)
	_expect(is_instance_valid(left) and brother.active == "watch", "and it is not picked straight back up")


## The boss beaten, the brothers walk out to finish the floor and come
## back: the way down must still be there.
func _trapdoor_stays() -> void:
	if room != null:
		room.queue_free()
		room = null
	var camera := Camera2D.new()
	root.add_child(camera)
	var run := Run.new()
	root.add_child(run)
	var brother := Brother.new()
	brother.setup("older", null, PlayerInput.new())
	brother.god = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	run.begin(rng, camera, [brother] as Array[Brother])
	await _steps(2)
	run.teleport("boss")
	await _steps(int(Run.BOSS_INTRO * 60.0) + 10)
	for boss in run.bosses:
		boss.hurt(boss.hp + 1.0, Vector2.ZERO)
	await _until(func() -> bool: return run.plan.info(run.cell).cleared, 600)
	_expect(run.trapdoor != null, "a beaten boss leaves the trapdoor")
	run.teleport("start")
	await _steps(2)
	_expect(run.trapdoor == null, "it stays behind in his room")
	run.teleport("boss")
	await _steps(2)
	_expect(run.trapdoor != null and run.trapdoor.is_inside_tree(),
			"and is there again on coming back to finish the floor")
	run.queue_free()
	camera.queue_free()
	await process_frame


## Below the first floor the treasure room is locked: a key opens it, and
## the brother walks in.
func _key_opens_door() -> void:
	if room != null:
		room.queue_free()
		room = null
	var camera := Camera2D.new()
	root.add_child(camera)
	var run := Run.new()
	root.add_child(run)
	var brother := Brother.new()
	brother.setup("older", null, PlayerInput.new())
	brother.god = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	run.begin(rng, camera, [brother] as Array[Brother])
	await _steps(2)
	run.start_floor(1)
	await _steps(2)
	# A room next to the locked one, already beaten, to stand in.
	var locked := Vector2i(-99, -99)
	var beside := Vector2i(-99, -99)
	var side := ""
	for at: Vector2i in run.plan.rooms:
		if run.plan.info(at).locked:
			locked = at
	for s: String in FloorPlan.SIDES:
		var next: Vector2i = locked - FloorPlan.SIDES[s]
		if run.plan.rooms.has(next) and run.plan.doors(next).has(s):
			beside = next
			side = s
	_expect(side != "", "floor 2 has a locked room with a way to it")
	if side == "":
		run.queue_free()
		camera.queue_free()
		return
	run.plan.info(beside).cleared = true
	run.room = null
	run._enter(beside, "")
	await _steps(2)
	_expect(run.room.locked.has(side) and not bool(run.room.open_doors.get(side, false)),
			"its door is locked and shut")
	brother.keys = 1
	brother.global_position = run.room.door_point(side) - Vector2(FloorPlan.SIDES[side]) * 50.0
	await _steps(3)
	_expect(brother.keys == 0 and not run.room.locked.has(side) and bool(run.room.open_doors.get(side, false)),
			"a key opens it")
	brother.global_position = run.room.door_point(side) + Vector2(FloorPlan.SIDES[side]) * 60.0
	await _until(func() -> bool: return run.cell == locked, 120)
	_expect(run.cell == locked, "and he walks through into it")
	run.queue_free()
	camera.queue_free()
	await process_frame


## The card at the end names who dealt the last blow.
func _last_blow() -> void:
	await _fresh_room(EMPTY)
	var brother := _brother(Vector2i(4, 3))
	var walker := _enemy("walker", Vector2i(4, 3))
	brother.hp = 1
	await _steps(4)
	_expect(brother.dead and brother.killed_by == walker.display_name,
			"the last blow is written down (%s)" % brother.killed_by)


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
