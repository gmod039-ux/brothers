class_name Run
extends Node2D
## A run through the floors: builds the room the brothers are in, walks them
## through doors with the camera sliding along, fills a room with its
## enemies and shuts the doors until they are beaten, puts the boss in his
## room, and opens the trapdoor down to the next floor. Only the room the
## brothers are in exists; the rest of the floor is the [FloorPlan], which
## also remembers what each room had left lying about.

signal room_entered(info: FloorPlan.RoomInfo)
signal room_cleared(info: FloorPlan.RoomInfo)
## The boss (or bosses: the last floor has two) is in and the title card
## should go up.
signal bosses_appeared(bosses: Array[Boss])
signal boss_beaten(boss: Boss)
signal trapdoor_entered
signal floor_started(index: int)
signal map_changed
signal unlocked

const FLOORS := 3
const FLOOR_NAMES := ["Подвал", "Котельная", "Катакомбы"]
## Seconds for the camera to slide from one room to the next.
const SLIDE_TIME := 0.38
## Seconds of title card before the boss starts.
const BOSS_INTRO := 2.0
## Each boss's own room, floor by floor.
const ARENAS := ["ring", "boiler", "cabaret"]
## What a shop sells, and for how much.
const PRICES := {"item": 15, "heart": 3, "bomb": 5, "key": 5}
## Seconds a knocked-out brother lies there once the room is clear, before
## his brother gets him up.
const REVIVE_AFTER := 1.2

var rng: RandomNumberGenerator
var layouts: RoomLayouts
var plan: FloorPlan
var floor_index := 0
var room: Room
var cell := Vector2i.ZERO
var brothers: Array[Brother] = []
var camera: Camera2D
## True while moving between rooms or floors: nothing else happens then.
var busy := false
var bosses: Array[Boss] = []
var trapdoor: Trapdoor
var kills := 0
var rooms_cleared := 0
var bosses_beaten := 0
## Items not yet offered this run: each turns up once at most.
var pool: Array[String] = []

var _revive_in := 0.0
## The camera sliding to the next room, and the room being left.
var _slide: Tween
var _leaving: Room

var _floor_seed := 0
var _fighting := false


func begin(rng_: RandomNumberGenerator, camera_: Camera2D, brothers_: Array[Brother]) -> void:
	rng = rng_
	camera = camera_
	brothers = brothers_
	layouts = RoomLayouts.load_file("res://data/rooms/basement.txt")
	for id: String in GameData.items():
		pool.append(id)
	pool.sort()
	start_floor(0)


func floor_name() -> String:
	return FLOOR_NAMES[mini(floor_index, FLOOR_NAMES.size() - 1)]


func is_last_floor() -> bool:
	return floor_index >= FLOORS - 1


func start_floor(index: int) -> void:
	_stop_slide()
	floor_index = index
	_floor_seed = rng.randi()
	plan = FloorPlan.generate(rng, index, layouts)
	bosses.clear()
	trapdoor = null
	_fighting = false
	var old := room
	room = null
	_enter(plan.start, "")
	if old != null:
		old.queue_free()
	camera.position = room.center()
	floor_started.emit(index)


## Cuts short a slide between rooms: jumping to another floor or room in the
## middle of one left the camera to finish it over the old floor, black,
## and the room it was going to got filled after all.
func _stop_slide() -> void:
	if _slide == null:
		return
	_slide.kill()
	_slide = null
	if is_instance_valid(_leaving):
		_leaving.queue_free()
	_leaving = null
	for brother in brothers:
		brother.frozen = false
	busy = false


## Straight into the first room of [param kind] on the floor, without
## walking there: for screenshots and trying things out.
func teleport(kind: String) -> void:
	_stop_slide()
	for at: Vector2i in plan.rooms:
		var info := plan.info(at)
		if info.kind == kind:
			info.locked = false
			var old := room
			room = null
			_enter(at, "")
			if old != null:
				old.queue_free()
			camera.position = room.center()
			return


## Down the trapdoor: the next floor, same brothers, same hearts.
func descend() -> void:
	start_floor(floor_index + 1)
	busy = false


## An item from the pool, gone from it; "" once every item has turned up.
func draw_item() -> String:
	if pool.is_empty():
		return ""
	return pool.pop_at(rng.randi() % pool.size())


## Moves the brothers into the room at [param to], having left the last one
## by its [param through] door ("" to appear in the middle of it).
func _enter(to: Vector2i, through: String) -> void:
	var info := plan.info(to)
	var old := room
	if old != null:
		_remember(old)
	# The trapdoor goes with the room it is in (and comes back with it).
	trapdoor = null
	var next := Room.new()
	next.name = "Room_%d_%d" % [to.x, to.y]
	next.cell = to
	next.run = self
	add_child(next)
	next.position = Vector2(to) * Room.SIZE
	next.style = floor_index
	next.kind = info.kind
	if info.kind == "boss":
		next.arena = ARENAS[mini(floor_index, ARENAS.size() - 1)]
	var doors := plan.doors(to)
	next.build(info.rows, _floor_seed + to.x * 131 + to.y * 17, doors, info.broken)
	next.rock_broken.connect(func(c: Vector2i) -> void: info.broken[c] = true)
	# The controls in chalk on the floor where the run begins.
	if info.kind == "start" and floor_index == 0:
		var chalk := ChalkHints.new()
		chalk.coop = brothers.size() > 1
		next.decals.add_child(chalk)
	for side: String in doors:
		var beyond := plan.info(to + FloorPlan.SIDES[side])
		if beyond.locked:
			next.locked[side] = true
	# Open as they come in; a fight slams them shut behind them
	# (see _slam_doors).
	next.set_doors_open(true)
	room = next
	cell = to
	info.visited = true
	var entry: String = FloorPlan.OPPOSITE[through] if through != "" else ""
	next.brothers.assign(brothers)
	for i in brothers.size():
		var brother := brothers[i]
		if brother.get_parent() == null:
			next.actors.add_child(brother)
		else:
			brother.reparent(next.actors)
		brother.room = next
		brother.stop()
		brother.global_position = next.entry_point(entry) if entry != "" else next.tile_center(Vector2i(6, 3))
		if brothers.size() > 1:
			# Side by side through the door, not one inside the other.
			var across := Vector2(FloorPlan.SIDES[entry]).orthogonal() if entry != "" else Vector2.RIGHT
			brother.global_position += across * (i - 0.5) * 70.0
	map_changed.emit()
	if old != null:
		old.brothers.clear()
		busy = true
		for brother in brothers:
			brother.frozen = true
		_leaving = old
		_slide = create_tween()
		_slide.tween_property(camera, "position", next.center(), SLIDE_TIME) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await _slide.finished
		_slide = null
		_leaving = null
		old.queue_free()
		for brother in brothers:
			brother.frozen = false
		busy = false
	room_entered.emit(info)
	_populate(info)


## Writes down what is still lying on the floor of a room being left, so it
## is there on coming back. Shop wares are the shop's own list.
func _remember(left: Room) -> void:
	var info := plan.info(left.cell)
	info.pickups.clear()
	for node in left.actors.get_children():
		var pickup := node as Pickup
		if pickup != null and not pickup.gone and pickup.price == 0:
			info.pickups.append([pickup.kind, pickup.item, 0, pickup.global_position - left.global_position])


func _populate(info: FloorPlan.RoomInfo) -> void:
	for kept: Array in info.pickups:
		_drop(kept[0], room.global_position + (kept[3] as Vector2), kept[1])
	info.pickups.clear()
	match info.kind:
		"treasure":
			if not info.looted:
				if info.prize == "":
					info.prize = draw_item()
				if info.prize != "":
					var prize := _drop("item", room.tile_center(Vector2i(6, 3)), info.prize)
					prize.taken.connect(func(_by: Brother) -> void: info.looted = true)
			return
		"shop":
			_open_shop(info)
			return
	if info.cleared:
		if info.kind == "boss":
			# Back in a beaten boss's room: the way down is still open. It
			# was made only as he fell, and gone for good once they walked
			# out to finish the floor.
			_place_trapdoor()
		return
	if info.kind == "boss":
		_start_boss()
		return
	var spawns := RoomLayouts.enemies_in(info.rows)
	if spawns.is_empty():
		info.cleared = true
		room.set_doors_open(true)
		return
	for spawn: Array in spawns:
		var enemy := Waves.spawn(spawn[0], room, rng, room.tile_center(spawn[1]))
		_toughen(enemy)
	_fighting = true
	_slam_doors()


## Bang: the doors shut behind the brothers, dust out of every doorway.
func _slam_doors() -> void:
	room.set_doors_open(false)
	Fx.shake(0.12)
	for side: String in room.doors:
		Fx.burst(room, room.door_point(side), "dust", 5, 0.7)


## A shop: the shopkeeper behind his counter, across the room from the
## door, and his wares in a row in front of it.
func _open_shop(info: FloorPlan.RoomInfo) -> void:
	if info.stock.is_empty() and not info.looted:
		var item := draw_item()
		if item != "":
			info.stock.append(["item", item, PRICES["item"]])
		info.stock.append(["heart", "", PRICES["heart"]])
		info.stock.append(["bomb", "", PRICES["bomb"]])
		info.stock.append(["key", "", PRICES["key"]])
		# Stocked once: what is bought is gone for good.
		info.looted = true
	var keeper_row := 5 if room.doors.has("top") else 1
	var keeper := Shopkeeper.new()
	room.actors.add_child(keeper)
	keeper.global_position = room.tile_center(Vector2i(6, keeper_row)) + Vector2(0, 44)
	for col: int in [5, 6, 7]:
		room.block_tile(Vector2i(col, keeper_row))
	var cols := [3, 5, 7, 9]
	for i in info.stock.size():
		var ware: Array = info.stock[i]
		var pickup := _drop(ware[0], room.tile_center(Vector2i(cols[i], 3)), ware[1])
		pickup.price = ware[2]
		pickup.taken.connect(func(_by: Brother) -> void:
			info.stock.erase(ware)
			if is_instance_valid(keeper):
				keeper.say("Спасибо!"))
		pickup.refused.connect(func(why: String) -> void:
			if is_instance_valid(keeper):
				keeper.say("Маловато монет!" if why == "coins" else "Ты и так здоров!", 1.6, true))


## Deeper floors, tougher enemies.
func _toughen(enemy: Enemy) -> void:
	if enemy == null:
		return
	enemy.max_hp *= 1.0 + 0.25 * floor_index
	enemy.hp = enemy.max_hp
	enemy.speed *= 1.0 + 0.06 * floor_index
	enemy.floor_look = floor_index
	enemy.knocked_out.connect(func(_e: Enemy) -> void: kills += 1)


## Who waits in the boss room of each floor: Bruno in the basement, the
## stove in the boiler room, the Baron himself at the bottom.
func _boss_lineup() -> Array[Boss]:
	var lineup: Array[Boss] = []
	match floor_index:
		0:
			lineup.append(Boss.new())
		1:
			lineup.append(StoveBoss.new())
		_:
			lineup.append(BaronBoss.new())
	return lineup


func _start_boss() -> void:
	_slam_doors()
	bosses = _boss_lineup()
	for i in bosses.size():
		var boss := bosses[i]
		boss.setup_boss(room, rng, floor_index)
		if bosses.size() > 1:
			# Two at once: each a good deal less tough.
			boss.max_hp *= 0.65
			boss.hp = boss.max_hp
		if brothers.size() > 1:
			# Two brothers hit twice as often.
			boss.max_hp *= 1.4
			boss.hp = boss.max_hp
		room.actors.add_child(boss)
		var col := 6 if bosses.size() == 1 else (3 + i * 6)
		boss.global_position = room.tile_center(Vector2i(col, 1))
		room.enemies.append(boss)
		boss.knocked_out.connect(_on_boss_down)
	_fighting = true
	bosses_appeared.emit(bosses)
	# Everyone holds still for the title card, as the curtain goes up.
	for brother in brothers:
		brother.frozen = true
	var woken := bosses.duplicate()
	# A tween of the run's own, not a timer of the tree's: a run thrown
	# away during the title card must not wake up afterwards.
	await create_tween().tween_interval(BOSS_INTRO).finished
	for brother in brothers:
		brother.frozen = false
	for boss: Boss in woken:
		if is_instance_valid(boss):
			boss.wake()


func _on_boss_down(beaten: Enemy) -> void:
	kills += 1
	for boss in bosses:
		if is_instance_valid(boss) and not boss.dead:
			# One down, one to go.
			return
	bosses_beaten += 1
	# His flies go with him.
	for enemy in room.enemies.duplicate():
		enemy.knock_out()
	boss_beaten.emit(beaten)
	_place_trapdoor()
	# A boss always leaves an item behind, as in Isaac, and a heart.
	var prize := draw_item()
	if prize != "":
		_drop("item", room.tile_center(Vector2i(6, 1)), prize)
	_drop("heart", room.tile_center(Vector2i(4, 3)))


## The hatch down to the next floor, in the middle of the boss's room.
func _place_trapdoor() -> void:
	trapdoor = Trapdoor.new()
	trapdoor.room = room
	room.decals.add_child(trapdoor)
	trapdoor.global_position = room.tile_center(Vector2i(6, 3))
	trapdoor.entered.connect(func(_b: Brother) -> void: trapdoor_entered.emit())


func _physics_process(delta: float) -> void:
	if busy or room == null:
		return
	if _fighting and room.enemies.is_empty():
		_fighting = false
		var info := plan.info(cell)
		info.cleared = true
		rooms_cleared += 1
		room.set_doors_open(true)
		if info.kind == "normal":
			Sfx.play("clear", -6.0, 0.0)
			_reward()
		for brother in brothers:
			brother.add_charge()
		room_cleared.emit(info)
	_revive_knocked(delta)
	for brother in brothers:
		if brother.dead:
			continue
		var side := room.exit_side(brother.global_position)
		if side != "" and bool(room.open_doors.get(side, false)):
			_enter(cell + FloorPlan.SIDES[side], side)
			return
		if brother.keys > 0 and not room.locked.is_empty():
			_try_unlock(brother)


## A brother knocked out gets up again once the room is clear, if his
## brother is still standing: half the fight is getting him through it.
func _revive_knocked(delta: float) -> void:
	var down: Array[Brother] = []
	var up := 0
	for brother in brothers:
		if brother.dead:
			down.append(brother)
		else:
			up += 1
	if down.is_empty() or up == 0 or not room.enemies.is_empty():
		_revive_in = REVIVE_AFTER
		return
	_revive_in -= delta
	if _revive_in > 0.0:
		return
	for brother in down:
		brother.revive(2)
		Fx.burst(room, brother.global_position + Vector2(0, -60), "stars", 10, 1.0)


## A brother with a key walking up to a locked door opens it.
func _try_unlock(brother: Brother) -> void:
	for side: String in room.locked.keys():
		if brother.global_position.distance_to(room.door_point(side)) < 90.0:
			brother.keys -= 1
			brother.inventory_changed.emit()
			room.locked.erase(side)
			plan.info(cell + FloorPlan.SIDES[side]).locked = false
			room.set_doors_open(plan.info(cell).cleared)
			map_changed.emit()
			unlocked.emit()
			return


## What a beaten room leaves behind: often nothing, sometimes a coin or
## two, a heart, a bomb, a key. Luck makes nothing rarer.
func _reward() -> void:
	var luck := 0.0
	for brother in brothers:
		luck = maxf(luck, brother.stats.luck)
	var nothing := clampf(0.4 - luck * 0.06, 0.1, 0.4)
	var at := room.tile_center(_open_tile_near(Vector2i(6, 3)))
	if rng.randf() < nothing:
		return
	var roll := rng.randf()
	if roll < 0.45:
		for i in rng.randi_range(1, 3):
			_drop("coin", at + Vector2(i * 26.0 - 26.0, (i % 2) * 18.0))
	elif roll < 0.7:
		_drop("half_heart" if rng.randf() < 0.6 else "heart", at)
	elif roll < 0.85:
		_drop("bomb", at)
	else:
		_drop("key", at)


## Something on the floor at [param at], from anywhere: a hat's tricks.
func drop(kind: String, at: Vector2, item := "") -> Pickup:
	return _drop(kind, at, item)


func _drop(kind: String, at: Vector2, item := "") -> Pickup:
	var pickup := Pickup.new()
	pickup.kind = kind
	pickup.item = item
	pickup.room = room
	room.actors.add_child(pickup)
	pickup.global_position = at
	return pickup


func _open_tile_near(wanted: Vector2i) -> Vector2i:
	var best := wanted
	var best_d := INF
	for tile in room.free_tiles():
		var d := Vector2(tile - wanted).length()
		if d < best_d:
			best_d = d
			best = tile
	return best


## Where the demo bot should head next: the nearest room it has not been
## in (locked ones only with a key), the boss once it has been everywhere
## else.
func bot_goal(has_key := false) -> Vector2i:
	var seen := {cell: true}
	var queue: Array[Vector2i] = [cell]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_front()
		var info := plan.info(here)
		if not info.visited and info.kind != "boss" and (not info.locked or has_key):
			return here
		for step: Vector2i in FloorPlan.SIDES.values():
			var next := here + step
			if plan.rooms.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return plan.boss
