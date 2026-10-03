class_name StokerEnemy
extends Enemy
## Кочегар, a stoker of the boiler room: a squat little fellow in a flat cap
## and a singlet black with coal dust, a walrus moustache, and a shovel as
## big as he is. He keeps his distance and shovels coal at you: he digs in
## (the shovel goes back -- that is the warning), heaves, and a lump flies
## over in an arc to where you were going, its shadow growing where it will
## land.

const SINGLET := Color("e6dcc8")
const TROUSERS := Color("3d4a66")
const FACE := Color("d9a27a")
const WOOD := Color("8a5a36")
const IRON := Color("5d5c64")

## "walk", "dig" or "heave".
var state := "walk"
var _t := 0.0
var _reload := 2.0
var _aim := Vector2.DOWN
var _strafe := 1.0


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_reload = rng.randf_range(1.0, float(def.get("throw_every", 3.0)))
	_strafe = 1.0 if rng.randf() < 0.5 else -1.0


func _switch(to: String) -> void:
	state = to
	_t = 0.0


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	if t != null:
		_aim = (t.global_position - global_position).normalized()
	match state:
		"dig":
			if _t > float(def.get("windup", 0.6)):
				if t != null:
					_heave(t)
				_switch("heave")
			return Vector2.ZERO
		"heave":
			if _t > 0.35:
				_switch("walk")
				_reload = float(def.get("throw_every", 3.0)) - floor_look * 0.3
			return Vector2.ZERO
	_reload -= delta
	if t == null:
		return Vector2.ZERO
	if _reload <= 0.0:
		_switch("dig")
		Sfx.play("stomp", -16.0, 0.3)
		return Vector2.ZERO
	# Not too near, not too far; sidestepping in between.
	var d := global_position.distance_to(t.global_position)
	if d < 300.0:
		return -_aim * speed
	if d > 520.0:
		return _aim * speed * 0.8
	if is_on_wall():
		_strafe = -_strafe
	return _aim.orthogonal() * speed * 0.5 * _strafe


## The lump: up out of the shovel, over, and down where the brother will be
## in a moment, never off the floor.
func _heave(t: Brother) -> void:
	var lead := t.velocity * 0.45
	var at := t.global_position + lead
	var floor_rect := room.floor_rect().grow(-40.0)
	at = at.clamp(floor_rect.position, floor_rect.end)
	var lump := Falling.new()
	lump.room = room
	lump.source = display_name
	lump.thrown_from = global_position + Vector2(_aim.x * 40.0, -70.0)
	room.effects.add_child(lump)
	lump.global_position = at
	Sfx.play("whistle_up", -12.0, 0.2)
	_squash = 2.0 / Toon.FPS


func draw_body(boil: int, flash: bool) -> void:
	var walking := velocity.length() > 20.0 and state == "walk"
	var step := boil % 2 if walking else -1
	var side := -1.0 if _aim.x < 0.0 else 1.0
	var dig := state == "dig"
	var heave := state == "heave"
	var at := Vector2(0, -34.0 + (2.0 if dig else 0.0))
	# Boots.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var up := -6.0 if step == i else 0.0
		var foot := Vector2(sx * 12.0, -5.0 + up)
		Toon.hose(self, at + Vector2(sx * 9.0, 16.0), foot, -sx * 2.0, 8.0, paint(TROUSERS, flash).darkened(0.2))
		Toon.ball(self, foot + Vector2(sx * 3.0, 0.0), Vector2(12.0, 7.0), Toon.INK, boil, _seed + i, 3.0)
	# The shovel: on his shoulder walking, down in the coal digging, up and
	# over heaving.
	var grip := at + Vector2(side * 20.0, 0.0)
	var blade := at + Vector2(-side * 22.0, -56.0)
	if dig:
		blade = at + Vector2(side * 46.0, 32.0)
		grip = at + Vector2(side * 12.0, -6.0)
	elif heave:
		blade = at + Vector2(side * 40.0, -66.0)
		grip = at + Vector2(side * 16.0, -14.0)
	var handle := grip.lerp(blade, -0.35)
	if not heave:
		_shovel(handle, blade, boil, flash, dig)
	# The body: a singlet over a round belly, trousers on braces.
	Toon.pear(self, at, Vector2(25.0, 23.0), 0.25, paint(SINGLET, flash).darkened(0.12 * floor_look), boil, _seed + 2)
	var legs := Toon.clip_below(Toon.ellipse_points(at, Vector2(25.0, 23.0), boil, _seed + 2, -2.5, 0.0, 1.2, 2.0, 0.25),
			at.y + 6.0)
	Toon.polygon(self, legs, paint(TROUSERS, flash))
	for sx: float in [-1.0, 1.0]:
		Toon.stroke(self, PackedVector2Array([at + Vector2(sx * 10.0, 6.0), at + Vector2(sx * 12.0, -20.0)]), 3.5,
				paint(TROUSERS, flash))
	for k in 4:
		var a := Toon.hash01(_seed, k) * TAU
		Toon.spot(self, at + Vector2(cos(a) * 12.0, sin(a) * 8.0 - 6.0), Vector2(5, 3), Color(0.1, 0.08, 0.08, 0.4), boil, k)
	# Arms to the handle.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := at + Vector2(sx * 18.0, -14.0)
		var hand := grip.lerp(handle, 0.15 + i * 0.45)
		Toon.hose(self, shoulder, hand, sx * 6.0, 7.0, paint(FACE, flash).darkened(0.1))
		Toon.ball(self, hand, Vector2(6.0, 6.0), paint(FACE, flash), boil, _seed + 20 + i, 2.5)
	if heave:
		_shovel(handle, blade, boil, flash, true)
	# The head: a red nose, a moustache, soot, a cap pulled down.
	var head := at + Vector2(0, -34.0)
	Toon.ball(self, head, Vector2(19.0, 17.0), paint(FACE, flash), boil, _seed + 4)
	Toon.spot(self, head + Vector2(-9, 4), Vector2(6, 4), Color(0.12, 0.1, 0.1, 0.45), boil, _seed + 5)
	Toon.spot(self, head + Vector2(10, -2), Vector2(4, 3), Color(0.12, 0.1, 0.1, 0.45), boil, _seed + 6)
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var e := head + Vector2(sx * 7.0, -3.0)
		eye(e, Vector2(4.5, 5.5), look, boil, _seed + 8 + int(sx), 2.5)
		if not eyes_shut():
			brow(e + Vector2(0, -7.0), 9.0, sx < 0.0, 3.0)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([head + Vector2(0, 7), head + Vector2(sx * 15.0, 9.0 + (2.0 if dig else 0.0)),
				head + Vector2(sx * 17.0, 15.0), head + Vector2(sx * 6.0, 12.0)]), Toon.INK, 1.5)
	Toon.ball(self, head + Vector2(side * 1.5, 4.0), Vector2(5.5, 5.0), paint(Color("c8553c"), flash), boil, _seed + 10, 2.5)
	if heave:
		# Puffing with the effort.
		Toon.blob(self, head + Vector2(0, 14), Vector2(4, 4), Toon.INK, boil, _seed + 11, 0.0)
	var cap := head + Vector2(-side * 1.0, -13.0)
	Toon.box(self, cap + Vector2(side * 10.0, 4.0), Vector2(14.0, 4.0), paint(Color("3a3438"), flash), boil, _seed + 12,
			3.0, side * 0.1)
	Toon.ball(self, cap, Vector2(19.0, 9.0), paint(Color("4a444a"), flash), boil, _seed + 13, 3.0)


## The shovel from [param handle]'s end to [param blade], with a heap of
## coal on the blade when it is [param full].
func _shovel(handle: Vector2, blade: Vector2, boil: int, flash: bool, full: bool) -> void:
	Toon.stroke(self, PackedVector2Array([handle, blade]), 7.5)
	Toon.stroke(self, PackedVector2Array([handle, blade]), 3.5, paint(WOOD, flash))
	var dir := (blade - handle).normalized()
	var across := dir.orthogonal()
	var face := PackedVector2Array([blade - across * 11.0, blade + across * 11.0, blade + across * 9.0 + dir * 22.0,
			blade + dir * 26.0, blade - across * 9.0 + dir * 22.0])
	Toon.shape(self, face, paint(IRON, flash), 3.0)
	if full:
		for k in 3:
			Toon.blob(self, blade + dir * (8.0 + k * 5.0) + across * (k - 1) * 6.0, Vector2(6, 5), Color("2a2626"), boil,
					_seed + 30 + k, 2.0)
