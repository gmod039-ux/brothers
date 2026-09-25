class_name Run
extends Node2D
## A run through the floors: builds the room the brothers are in, walks them
## through doors with the camera sliding along, fills a room with its
## enemies and shuts the doors until they are beaten, puts the boss in his
## room, and opens the trapdoor down to the next floor. Only the room the
## brothers are in exists; the rest of the floor is the [FloorPlan].

signal room_entered(info: FloorPlan.RoomInfo)
signal room_cleared(info: FloorPlan.RoomInfo)
signal boss_appeared(boss: Boss)
signal boss_beaten(boss: Boss)
signal trapdoor_entered
signal floor_started(index: int)
signal map_changed

const FLOORS := 3
const FLOOR_NAMES := ["Подвал", "Подвал поглубже", "Самое дно"]
## Seconds for the camera to slide from one room to the next.
const SLIDE_TIME := 0.38
## Seconds of title card before the boss starts.
const BOSS_INTRO := 2.0
## Chance a cleared room leaves a heart behind.
const HEART_CHANCE := 0.3

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
var boss: Boss
var trapdoor: Trapdoor
var kills := 0
var rooms_cleared := 0
var bosses_beaten := 0

var _floor_seed := 0
var _fighting := false


func begin(rng_: RandomNumberGenerator, camera_: Camera2D, brothers_: Array[Brother]) -> void:
	rng = rng_
	camera = camera_
	brothers = brothers_
	layouts = RoomLayouts.load_file("res://data/rooms/basement.txt")
	start_floor(0)


func floor_name() -> String:
	return FLOOR_NAMES[mini(floor_index, FLOOR_NAMES.size() - 1)]


func is_last_floor() -> bool:
	return floor_index >= FLOORS - 1


func start_floor(index: int) -> void:
	floor_index = index
	_floor_seed = rng.randi()
	plan = FloorPlan.generate(rng, index, layouts)
	boss = null
	trapdoor = null
	_fighting = false
	var old := room
	room = null
	_enter(plan.start, "")
	if old != null:
		old.queue_free()
	camera.position = room.center()
	floor_started.emit(index)


## Moves the brothers into the room at [param to], having left the last one
## by its [param through] door ("" to appear in the middle of it).
func _enter(to: Vector2i, through: String) -> void:
	var info := plan.info(to)
	var old := room
	var next := Room.new()
	next.name = "Room_%d_%d" % [to.x, to.y]
	next.cell = to
	next.run = self
	add_child(next)
	next.position = Vector2(to) * Room.SIZE
	next.build(info.rows, _floor_seed + to.x * 131 + to.y * 17, plan.doors(to))
	next.set_doors_open(info.cleared)
	room = next
	cell = to
	info.visited = true
	var entry: String = FloorPlan.OPPOSITE[through] if through != "" else ""
	next.brothers.assign(brothers)
	for brother in brothers:
		if brother.get_parent() == null:
			next.actors.add_child(brother)
		else:
			brother.reparent(next.actors)
		brother.room = next
		brother.stop()
		brother.global_position = next.entry_point(entry) if entry != "" else next.tile_center(Vector2i(6, 3))
	map_changed.emit()
	if old != null:
		old.brothers.clear()
		busy = true
		for brother in brothers:
			brother.frozen = true
		var tween := create_tween()
		tween.tween_property(camera, "position", next.center(), SLIDE_TIME) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		old.queue_free()
		for brother in brothers:
			brother.frozen = false
		busy = false
	room_entered.emit(info)
	_populate(info)


func _populate(info: FloorPlan.RoomInfo) -> void:
	if info.kind == "treasure" and not info.looted:
		var prize := _drop("heart_container", room.tile_center(Vector2i(6, 3)))
		prize.taken.connect(func(_by: Brother) -> void: info.looted = true)
		return
	if info.cleared:
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


## Deeper floors, tougher enemies.
func _toughen(enemy: Enemy) -> void:
	if enemy == null:
		return
	enemy.max_hp *= 1.0 + 0.25 * floor_index
	enemy.hp = enemy.max_hp
	enemy.knocked_out.connect(func(_e: Enemy) -> void: kills += 1)


func _start_boss() -> void:
	room.set_doors_open(false)
	boss = Boss.new()
	boss.setup_boss(room, rng, floor_index)
	room.actors.add_child(boss)
	boss.global_position = room.tile_center(Vector2i(6, 1))
	room.enemies.append(boss)
	boss.knocked_out.connect(_on_boss_down)
	_fighting = true
	boss_appeared.emit(boss)
	# Everyone holds still for the title card, as the curtain goes up.
	for brother in brothers:
		brother.frozen = true
	var woken := boss
	await get_tree().create_timer(BOSS_INTRO, false).timeout
	for brother in brothers:
		brother.frozen = false
	if is_instance_valid(woken):
		woken.wake()


func _on_boss_down(beaten: Enemy) -> void:
	bosses_beaten += 1
	kills += 1
	# His flies go with him.
	for enemy in room.enemies.duplicate():
		enemy.knock_out()
	boss_beaten.emit(beaten)
	trapdoor = Trapdoor.new()
	trapdoor.room = room
	room.decals.add_child(trapdoor)
	trapdoor.global_position = room.tile_center(Vector2i(6, 3))
	trapdoor.entered.connect(func(_b: Brother) -> void: trapdoor_entered.emit())
	_drop("heart", room.tile_center(Vector2i(6, 5)))


## Down the trapdoor: the next floor, same brothers, same hearts.
func descend() -> void:
	start_floor(floor_index + 1)
	busy = false


func _physics_process(_delta: float) -> void:
	if busy or room == null:
		return
	if _fighting and room.enemies.is_empty():
		_fighting = false
		var info := plan.info(cell)
		info.cleared = true
		rooms_cleared += 1
		room.set_doors_open(true)
		if info.kind == "normal" and rng.randf() < HEART_CHANCE:
			_drop("half_heart" if rng.randf() < 0.6 else "heart", room.tile_center(_open_tile_near(Vector2i(6, 3))))
		room_cleared.emit(info)
	for brother in brothers:
		if brother.dead:
			continue
		var side := room.exit_side(brother.global_position)
		if side != "" and bool(room.open_doors.get(side, false)):
			_enter(cell + FloorPlan.SIDES[side], side)
			return


func _drop(kind: String, at: Vector2) -> Pickup:
	var pickup := Pickup.new()
	pickup.kind = kind
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
## in, the boss once it has been everywhere else.
func bot_goal() -> Vector2i:
	var seen := {cell: true}
	var queue: Array[Vector2i] = [cell]
	while not queue.is_empty():
		var here: Vector2i = queue.pop_front()
		var info := plan.info(here)
		if not info.visited and info.kind != "boss":
			return here
		for step: Vector2i in FloorPlan.SIDES.values():
			var next := here + step
			if plan.rooms.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return plan.boss
