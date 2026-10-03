class_name HeadStoker
extends MiniBoss
## Бригадир, foreman of the boiler room's stokers: one of them twice over,
## a miner's helmet with its lamp lit, a walrus moustache grey with ash,
## braces over his singlet and a shovel like a door. He keeps his distance
## and heaves coal -- three lumps in a fan, each coming down where its
## shadow grows; or swings the shovel up over his head and brings it down
## on the floor: a ring of dust that hurts anyone too near, and two embers
## jump out of the iron (never more than three about). From half health he
## lowers the shovel and charges, till he hits a wall and sees stars --
## the time to hit him.

const SINGLET := Color("e6dcc8")
const TROUSERS := Color("3d4a66")
const FACE := Color("d9a27a")
const WOOD := Color("8a5a36")
const IRON := Color("5d5c64")
const HELMET := Color("c9a03a")
const POUND_REACH := 150.0
const RUSH_SPEED := 640.0
const MOST_EMBERS := 3

var _strafe := 1.0
var _rush := Vector2.ZERO


func setup_boss(room_: Room, rng_: RandomNumberGenerator, floor_index_: int) -> void:
	setup("head_stoker", room_, rng_)
	title = "Бригадир"
	subtitle = "правая рука Пыхтуна"
	floor_index = floor_index_
	hp = max_hp
	contact = 1
	_spawn = 0.0
	_strafe = 1.0 if rng.randf() < 0.5 else -1.0


func _calm_states() -> Array:
	return ["walk", "recover", "stunned"]


func _fight(_delta: float, t: Brother) -> void:
	match state:
		"walk":
			if t != null:
				var d := global_position.distance_to(t.global_position)
				if d < 280.0:
					velocity = -_aim * speed
				elif d > 520.0:
					velocity = _aim * speed
				else:
					if is_on_wall():
						_strafe = -_strafe
					velocity = _aim.orthogonal() * speed * 0.6 * _strafe
			if _t > _walk_for:
				_choose()
		"heave_windup":
			if _t > 0.7:
				if t != null:
					_heave(t)
				_go("recover")
		"pound_windup":
			if _t > 0.65:
				_pound()
				_go("recover")
		"charge_windup":
			if int(_t * 8.0) != int((_t - get_physics_process_delta_time()) * 8.0):
				Fx.burst(room, global_position - _aim * 40.0, "dust", 3, 0.6)
				Sfx.play("stomp", -16.0, 0.3)
			if _t > 0.7:
				_rush = _aim
				_go("charge")
		"charge":
			velocity = _rush * RUSH_SPEED
			if int(_t * 30.0) % 2 == 0:
				Fx.burst(room, global_position + Vector2(0, -4), "dust", 1, 0.4)
		"stunned":
			if _t > 1.1:
				_go("walk")
		"recover":
			if _t > 0.55:
				_go("walk")


## Into a wall at full tilt: stars.
func _moved() -> void:
	if state == "charge" and (get_slide_collision_count() > 0 or _t > 1.6):
		_squash = 3.0 / Toon.FPS
		stomped.emit()
		Sfx.play("stomp", 0.0)
		Sfx.play("stars", -6.0)
		Fx.burst(room, global_position + Vector2(0, -170), "stars", 6, 0.6)
		Fx.burst(room, global_position, "dust", 8, 1.0)
		_go("stunned")


func _choose() -> void:
	var options := ["heave", "heave", "pound"]
	if phase >= 2:
		options.append_array(["charge", "charge"])
	match str(options[rng.randi() % options.size()]):
		"heave":
			_go("heave_windup")
			Sfx.play("stomp", -16.0, 0.3)
		"pound":
			_go("pound_windup")
			Sfx.play("whistle_up", -10.0, 0.1)
		_:
			_go("charge_windup")
			Sfx.play("roar", -8.0, 0.1)


## Three lumps in a fan over the brother: one where he will be, one either
## side of him.
func _heave(t: Brother) -> void:
	var ahead := t.global_position + t.velocity * 0.4
	var floor_box := room.floor_rect().grow(-40.0)
	var across := _aim.orthogonal() * 150.0
	for i in 3:
		var at := (ahead + across * (i - 1)).clamp(floor_box.position, floor_box.end)
		var lump := Falling.new()
		lump.room = room
		lump.source = title
		lump.delay = i * 0.12
		lump.thrown_from = global_position + Vector2(_aim.x * 70.0, -150.0)
		room.effects.add_child(lump)
		lump.global_position = at
	Sfx.play("whistle_up", -6.0, 0.1)
	_squash = 2.0 / Toon.FPS


## The shovel on the floor: a ring of dust, a hit for anyone near, and
## embers out of the iron.
func _pound() -> void:
	var at := global_position + Vector2(_aim.x * 60.0, 10.0)
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(at) < POUND_REACH:
			brother.hurt(1, at, title)
	Fx.ring(room, at, POUND_REACH * 2.2, Toon.INK, 0.4, 10.0)
	Fx.burst(room, at, "dust", 10, 1.2)
	Fx.burst(room, at + Vector2(0, -20), "embers", 8, 1.0)
	Sfx.play("stomp", 0.0)
	stomped.emit()
	for i in mini(2, MOST_EMBERS - minions("ember")):
		_call("ember", at + Vector2(-90.0 + i * 180.0, 30.0))
	_squash = 3.0 / Toon.FPS


func _shadow_size() -> Vector2:
	return Vector2(64, 20)


func _height_of_head() -> float:
	return 150.0


func _pose(boil: int) -> Array:
	var squash := 0.0
	match state:
		"heave_windup", "pound_windup":
			squash = 0.08
		"charge_windup":
			squash = 0.12
		"charge":
			squash = -0.06 if boil % 2 == 0 else 0.0
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
		"wait":
			# Spitting on his hands.
			squash = [0.0, 0.05, 0.0, -0.03][boil % 4]
	if _squash > 0.0:
		squash = 0.14
	return [Vector2.ZERO, 0.0, Vector2(1.0 + squash, 1.0 - squash)]


func _figure(boil: int, flash: bool) -> void:
	var side := -1.0 if _aim.x < 0.0 else 1.0
	var walking := velocity.length() > 20.0 and state in ["walk", "charge"]
	var step := boil % 2 if walking else -1
	var at := Vector2(0, -66)
	# Boots.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var up := -10.0 if step == i else 0.0
		var foot := Vector2(sx * 24.0, -9.0 + up)
		Toon.hose(self, at + Vector2(sx * 18.0, 30.0), foot, -sx * 4.0, 15.0, paint(TROUSERS, flash).darkened(0.2))
		Toon.ball(self, foot + Vector2(sx * 6.0, 0.0), Vector2(24.0, 13.0), Toon.INK, boil, _seed + i, 4.0)
	# The shovel: over his shoulder walking, back for a heave, up over his
	# head to pound, down in front for a charge.
	var grip := at + Vector2(side * 38.0, 0.0)
	var blade := at + Vector2(-side * 44.0, -110.0)
	match state:
		"heave_windup":
			blade = at + Vector2(-side * 90.0, 50.0)
			grip = at + Vector2(-side * 10.0, -10.0)
		"pound_windup":
			blade = at + Vector2(side * 10.0, -200.0)
			grip = at + Vector2(side * 10.0, -70.0)
		"charge_windup", "charge":
			blade = at + Vector2(side * 120.0, 30.0)
			grip = at + Vector2(side * 30.0, -10.0)
		"recover":
			blade = at + Vector2(side * 96.0, 60.0)
			grip = at + Vector2(side * 30.0, -14.0)
	var handle := grip.lerp(blade, -0.35)
	_shovel(handle, blade, boil, flash)
	# The body: a singlet over a big belly, trousers on braces, soot.
	var size := Vector2(48, 44)
	Toon.pear(self, at, size, 0.25, paint(SINGLET, flash).darkened(0.18), boil, _seed + 2)
	var legs := Toon.clip_below(Toon.ellipse_points(at, size, boil, _seed + 2, -2.5, 0.0, 1.2, 2.0, 0.25), at.y + 12.0)
	Toon.polygon(self, legs, paint(TROUSERS, flash))
	for sx: float in [-1.0, 1.0]:
		Toon.stroke(self, PackedVector2Array([at + Vector2(sx * 20.0, 12.0), at + Vector2(sx * 24.0, -40.0)]), 7.0,
				paint(TROUSERS, flash))
		Toon.spot(self, at + Vector2(sx * 22.0, 6.0), Vector2(3.5, 3.5), Color("e0b23a"))
	for k in 6:
		var a := Toon.hash01(_seed, k) * TAU
		Toon.spot(self, at + Vector2(cos(a) * 24.0, sin(a) * 16.0 - 10.0), Vector2(9, 5), Color(0.1, 0.08, 0.08, 0.4),
				boil, k)
	# Arms to the handle.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := at + Vector2(sx * 36.0, -28.0)
		var hand := grip.lerp(handle, 0.15 + i * 0.45)
		Toon.hose(self, shoulder, hand, sx * 10.0, 13.0, paint(FACE, flash).darkened(0.1))
		Toon.ball(self, hand, Vector2(11.0, 11.0), paint(FACE, flash), boil, _seed + 20 + i, 3.5)
	# The head: red nose, a great grey moustache, a helmet with its lamp.
	var head := at + Vector2(0, -66)
	Toon.ball(self, head, Vector2(34, 30), paint(FACE, flash), boil, _seed + 4)
	Toon.spot(self, head + Vector2(-16, 8), Vector2(10, 7), Color(0.12, 0.1, 0.1, 0.45), boil, _seed + 5)
	var look := gaze()
	var angry := phase >= 2 or state in ["charge_windup", "charge", "pound_windup"]
	for sx: float in [-1.0, 1.0]:
		var e := head + Vector2(sx * 13.0, -4.0)
		eye(e, Vector2(8, 10), look, boil, _seed + 8 + int(sx), 3.0)
		if not eyes_shut():
			brow(e + Vector2(0, -13.0), 18.0 if angry else 14.0, sx < 0.0, 5.0)
	var grey := paint(Color("b8b4ac"), flash)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([head + Vector2(0, 12), head + Vector2(sx * 28.0, 14.0),
				head + Vector2(sx * 34.0, 28.0), head + Vector2(sx * 10.0, 22.0)]), grey, 3.0)
	Toon.ball(self, head + Vector2(side * 2.0, 8.0), Vector2(10, 9), paint(Color("c8553c"), flash), boil, _seed + 10, 3.5)
	if state == "stunned":
		Toon.blob(self, head + Vector2(0, 30), Vector2(8, 6), Toon.INK, boil, _seed + 11, 0.0)
	var helmet := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		helmet.append(head + Vector2(cos(a) * 38.0, -6.0 + sin(a) * 34.0))
	Toon.shape(self, helmet, paint(HELMET, flash), 4.0)
	Toon.box(self, head + Vector2(0, -6), Vector2(44, 6), paint(HELMET.darkened(0.2), flash), boil, _seed + 12, 3.0)
	var lamp := head + Vector2(0, -26)
	Toon.ball(self, lamp, Vector2(10, 9), paint(Color("fff1a8"), flash), boil, _seed + 13, 3.0)
	if not flash:
		var reach := lamp + _aim * 140.0
		draw_colored_polygon(PackedVector2Array([lamp, reach + _aim.orthogonal() * 50.0, reach - _aim.orthogonal() * 50.0]),
				Color(1, 0.95, 0.6, 0.12))


## The shovel from [param handle]'s end to [param blade], coal heaped on it.
func _shovel(handle: Vector2, blade: Vector2, boil: int, flash: bool) -> void:
	Toon.stroke(self, PackedVector2Array([handle, blade]), 14.0)
	Toon.stroke(self, PackedVector2Array([handle, blade]), 7.0, paint(WOOD, flash))
	var dir := (blade - handle).normalized()
	var across := dir.orthogonal()
	var face := PackedVector2Array([blade - across * 22.0, blade + across * 22.0, blade + across * 18.0 + dir * 44.0,
			blade + dir * 52.0, blade - across * 18.0 + dir * 44.0])
	Toon.shape(self, face, paint(IRON, flash), 4.0)
	if state in ["heave_windup", "walk"]:
		for k in 3:
			Toon.blob(self, blade + dir * (16.0 + k * 10.0) + across * (k - 1) * 12.0, Vector2(11, 9), Color("2a2626"), boil,
					_seed + 30 + k, 3.0)
