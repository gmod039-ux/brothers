class_name SkeletonEnemy
extends Enemy
## Костяшка, straight out of a 1929 skeleton dance: a grinning skull on a
## rattling bag of bones. Clatters after you and now and then winds an arm
## back (the warning) and throws a bone that comes spinning. Knocked down
## the first time it only falls apart into a heap -- leave it, and a moment
## later it pulls itself together and comes on again, the worse for wear.
## The second time it stays down.

const BONE := Color("efe6cf")
const PILE_TIME := 2.6
const RISE_TIME := 0.55

## "walk", "windup", "pile" or "rise".
var state := "walk"
var collapsed := false
var _t := 0.0
var _reload := 2.0
var _aim := Vector2.DOWN


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_reload = rng.randf_range(1.2, float(def.get("throw_every", 3.0)))


func _switch(to: String) -> void:
	state = to
	_t = 0.0


func can_touch() -> bool:
	return super.can_touch() and state in ["walk", "windup"]


func can_be_hit() -> bool:
	return super.can_be_hit() and state in ["walk", "windup"]


## The first knockout only scatters the bones.
func hurt(damage: float, direction: Vector2, strength := 1.0) -> void:
	if dead or state in ["pile", "rise"]:
		return
	if not collapsed and hp - damage <= 0.0:
		collapsed = true
		hp = max_hp * 0.5
		_switch("pile")
		_flash = 1.0 / Toon.FPS
		_knock = Vector2.ZERO
		Sfx.play("hit", -6.0, 0.15)
		Sfx.play("poof", -12.0, 0.2)
		Fx.burst(room, global_position + Vector2(0, -30), "dust", 6, 0.8)
		return
	super.hurt(damage, direction, strength)


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	if t != null:
		_aim = (t.global_position - global_position).normalized()
	match state:
		"pile":
			if _t > PILE_TIME:
				_switch("rise")
				Sfx.play("whistle_up", -12.0, 0.2)
			return Vector2.ZERO
		"rise":
			if _t > RISE_TIME:
				_switch("walk")
			return Vector2.ZERO
		"windup":
			if _t > float(def.get("windup", 0.5)):
				_throw()
				_switch("walk")
				_reload = float(def.get("throw_every", 3.0))
			return Vector2.ZERO
	if t == null:
		return Vector2.ZERO
	_reload -= delta
	if _reload <= 0.0 and global_position.distance_to(t.global_position) < 640.0:
		_switch("windup")
		return Vector2.ZERO
	return _aim * speed


func _throw() -> void:
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + _aim * radius, 60.0, _aim * float(def.get("shot_speed", 400.0)),
			float(def.get("shot_range", 8.0)) * Room.TILE, 1.0, 14.0, true)
	shot.source = display_name
	shot.look = "bone"
	shot.tint = BONE
	Sfx.play("spit", -10.0, 0.2)


## A bone from [param a] to [param b]: a white shaft with a knob at each end.
func _bone(a: Vector2, b: Vector2, width: float, boil: int, seed_: int, flash: bool) -> void:
	var bone := paint(BONE, flash).darkened(0.08 * floor_look)
	Toon.stroke(self, PackedVector2Array([a, b]), width + 5.0)
	var across := (b - a).normalized().orthogonal() * width * 0.45
	for end: Vector2 in [a, b]:
		Toon.blob(self, end + across, Vector2(width * 0.55, width * 0.55), bone, boil, seed_, 2.5)
		Toon.blob(self, end - across, Vector2(width * 0.55, width * 0.55), bone, boil, seed_ + 1, 2.5)
	Toon.stroke(self, PackedVector2Array([a, b]), width, bone)


func draw_body(boil: int, flash: bool) -> void:
	if state == "pile" or (state == "rise" and _t < RISE_TIME * 0.4):
		_draw_heap(boil, flash)
		return
	var walking := velocity.length() > 20.0 and state == "walk"
	var step := boil % 2 if walking else -1
	var rise := clampf(_t / RISE_TIME, 0.0, 1.0) if state == "rise" else 1.0
	var sink := (1.0 - rise) * 30.0
	var hip := Vector2(0, -34.0 + sink)
	var side := -1.0 if _aim.x < 0.0 else 1.0
	# Legs: thigh bones, little bone feet, a knock-kneed clatter.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var up := -7.0 if step == i else 0.0
		var foot := Vector2(sx * 11.0, -4.0 + up)
		_bone(hip + Vector2(sx * 6.0, 4.0), foot, 5.0, boil, _seed + i * 3, flash)
		Toon.blob(self, foot + Vector2(sx * 5.0, 1.0), Vector2(8.0, 4.0), paint(BONE, flash), boil, _seed + 10 + i, 2.5)
	# Pelvis, spine and ribs.
	Toon.blob(self, hip, Vector2(13.0, 7.0), paint(BONE, flash), boil, _seed + 12, 3.0)
	var chest := hip + Vector2(0, -26.0)
	Toon.stroke(self, PackedVector2Array([hip, chest + Vector2(0, -10)]), 8.0)
	Toon.stroke(self, PackedVector2Array([hip, chest + Vector2(0, -10)]), 4.0, paint(BONE, flash))
	for k in 3:
		var y := chest.y - 6.0 + k * 8.0
		for sx: float in [-1.0, 1.0]:
			var rib := Toon.bent(Vector2(chest.x, y), Vector2(chest.x + sx * (15.0 - k * 2.0), y + 7.0), -sx * 5.0, 6)
			Toon.stroke(self, rib, 6.0)
			Toon.stroke(self, rib, 2.8, paint(BONE, flash))
	# Arms: one hanging, one back with a bone when winding up.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := chest + Vector2(sx * 12.0, -8.0)
		var hand := shoulder + Vector2(sx * 8.0, 26.0 + (6.0 if step == i else 0.0))
		var throwing := state == "windup" and sx == side
		if throwing:
			hand = shoulder + Vector2(-side * 14.0, -24.0)
		_bone(shoulder, hand, 4.0, boil, _seed + 20 + i * 3, flash)
		Toon.blob(self, hand, Vector2(5.0, 5.0), paint(BONE, flash), boil, _seed + 26 + i, 2.5)
		if throwing:
			_bone(hand + Vector2(-8, -6), hand + Vector2(8, 6), 4.0, boil, _seed + 30, flash)
	_skull(chest + Vector2(0, -30.0), boil, flash, false)


## The skull: a grin full of teeth, black sockets with a glint in them.
func _skull(at: Vector2, boil: int, flash: bool, dazed: bool) -> void:
	var bone := paint(BONE, flash).darkened(0.08 * floor_look)
	Toon.ball(self, at, Vector2(17.0, 16.0), bone, boil, _seed + 40)
	Toon.box(self, at + Vector2(0, 12.0), Vector2(11.0, 6.0), bone, boil, _seed + 41, 3.0)
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var e := at + Vector2(sx * 6.5, -2.0)
		Toon.blob(self, e, Vector2(5.0, 6.0), Toon.INK, boil, _seed + 42 + int(sx), 0.0)
		if dazed:
			Toon.star(self, e, 3.5, _clock * 6.0, Color("f2c14e"))
		elif not eyes_shut():
			Toon.spot(self, e + look * 1.5 + Vector2(-1, -1.5), Vector2(1.8, 2.0), Color(1, 1, 1, 0.9))
	Toon.shape(self, PackedVector2Array([at + Vector2(0, 3), at + Vector2(-2.5, 8), at + Vector2(2.5, 8)]), Toon.INK, 0.5)
	for k in 5:
		var x := -8.0 + k * 4.0
		Toon.stroke(self, PackedVector2Array([at + Vector2(x, 10.0), at + Vector2(x, 15.0)]), 1.6)
	Toon.stroke(self, PackedVector2Array([at + Vector2(-10, 12.5), at + Vector2(10, 12.5)]), 1.6)


## Fallen apart: a heap of bones with the skull on top, seeing stars --
## and, as it gets up, the bones jumping back together.
func _draw_heap(boil: int, flash: bool) -> void:
	var shake := 0.0
	if state == "pile" and _t > PILE_TIME - 0.6:
		shake = (Toon.hash01(boil, 3) - 0.5) * 6.0
	for k in 6:
		var a := Toon.hash01(_seed, k) * PI
		var c := Vector2(-22.0 + k * 9.0 + shake, -6.0 - (k % 2) * 6.0)
		var half := Vector2(cos(a), sin(a) * 0.4) * 12.0
		_bone(c - half, c + half, 4.5, boil, _seed + 50 + k, flash)
	_skull(Vector2(4.0 + shake, -26.0), boil, flash, true)
