class_name Waves
extends Node
## The test room's fight: the waves listed in data/waves.json, each thrown in
## once the one before it is beaten. Stands in for the rooms of a floor until
## there is a floor.

signal wave_started(number: int, total: int)
signal cleared

## A breath between the last enemy of a wave going poof and the next wave.
const BREATHER := 1.2
## No enemy appears closer than this to a brother.
const SAFE_DISTANCE := 3.2 * Room.TILE

var room: Room
var rng: RandomNumberGenerator
var list: Array = []
## Waves thrown in so far.
var current := 0
var done := false
var kills := 0

var _pause := 0.7
var _running := false


func begin(room_: Room, rng_: RandomNumberGenerator, list_: Array) -> void:
	room = room_
	rng = rng_
	list = list_
	_running = true


func stop() -> void:
	_running = false


func _physics_process(delta: float) -> void:
	if not _running or done or not room.enemies.is_empty():
		return
	if current >= list.size():
		done = true
		cleared.emit()
		return
	_pause -= delta
	if _pause > 0.0:
		return
	_spawn_wave(list[current])
	current += 1
	_pause = BREATHER
	wave_started.emit(current, list.size())


func _spawn_wave(wave: Dictionary) -> void:
	var cells := room.free_tiles()
	var usable: Array[Vector2i] = []
	for cell in cells:
		var at := room.tile_center(cell)
		var clear := true
		for brother in room.brothers:
			if at.distance_to(brother.global_position) < SAFE_DISTANCE:
				clear = false
		if clear:
			usable.append(cell)
	if usable.is_empty():
		usable = cells
	for kind: String in wave:
		for i in int(wave[kind]):
			var cell := usable[rng.randi() % usable.size()]
			if usable.size() > 1:
				usable.erase(cell)
			var enemy := spawn(kind, room, rng, room.tile_center(cell))
			if enemy != null:
				enemy.knocked_out.connect(func(_e: Enemy) -> void: kills += 1)


## Puts an enemy of [param kind] into [param room] at [param at].
static func spawn(kind: String, room_: Room, rng_: RandomNumberGenerator, at: Vector2) -> Enemy:
	var enemy: Enemy
	match kind:
		"fly":
			enemy = FlyEnemy.new()
		"walker":
			enemy = WalkerEnemy.new()
		"shooter":
			enemy = ShooterEnemy.new()
		_:
			push_error("no enemy called %s" % kind)
			return null
	enemy.setup(kind, room_, rng_)
	room_.actors.add_child(enemy)
	enemy.global_position = at
	room_.enemies.append(enemy)
	var puff := Puff.new()
	puff.radius = enemy.radius * 0.8
	puff.stars = 0
	puff.drawings = 5
	room_.effects.add_child(puff)
	puff.global_position = at
	return enemy
