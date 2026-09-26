class_name WalkerEnemy
extends Enemy
## Топтун: a grumpy lump on two big shoes, fists like hams. Wanders about
## until a brother comes near, then stomps at him, faster, fists up. Close
## enough, it crouches -- the warning -- and leaps at him, landing with a
## thump that shakes the floor.
##
## Floors: plain in the basement; in the boiler room a miner's helmet with
## its lamp lit, soot all over; in the catacombs a mummy, bandaged, pale.

const BODY := Color("8fae5e")
const SHOE := Color("4a3a2a")
const BANDAGE := Color("e6dcc2")
const CROUCH_TIME := 0.42
const LEAP_TIME := 0.46
const LAND_TIME := 0.34
const LEAP_SPEED := 520.0

## "wander", "chase", "crouch", "leap" or "land".
var state := "wander"
var chasing := false
var _t := 0.0
var _cool := 2.0
var _leap := Vector2.ZERO
var _heading := Vector2.ZERO
var _turn_in := 0.0


func _switch(to: String) -> void:
	state = to
	_t = 0.0


func think(delta: float) -> Vector2:
	_t += delta
	_cool -= delta
	var t := target()
	match state:
		"crouch":
			if t != null:
				_leap = (t.global_position - global_position).normalized()
			if _t > CROUCH_TIME:
				_switch("leap")
				Sfx.play("whistle_up", -12.0, 0.2)
			return Vector2.ZERO
		"leap":
			if _t > LEAP_TIME or is_on_wall():
				_switch("land")
				Fx.ring(room, global_position, 90.0, Toon.INK, 0.35, 8.0)
				Fx.burst(room, global_position, "dust", 6, 0.8)
				Sfx.play("stomp", -8.0, 0.15)
				Fx.shake(0.1)
			return _leap * LEAP_SPEED
		"land":
			if _t > LAND_TIME:
				_switch("chase")
				_cool = rng.randf_range(2.2, 3.4) - floor_look * 0.4
			return Vector2.ZERO
	var notice := float(def.get("notice", 380.0))
	chasing = t != null and global_position.distance_to(t.global_position) < notice
	if chasing:
		var to := t.global_position - global_position
		if _cool <= 0.0 and to.length() < 300.0:
			_switch("crouch")
			return Vector2.ZERO
		state = "chase"
		return to.normalized() * float(def.get("chase_speed", speed))
	state = "wander"
	_turn_in -= delta
	if _turn_in <= 0.0 or is_on_wall():
		_heading = Vector2.from_angle(rng.randf() * TAU)
		_turn_in = rng.randf_range(1.2, 2.6)
	return _heading * speed


func lift() -> float:
	if state == "leap":
		return sin(clampf(_t / LEAP_TIME, 0.0, 1.0) * PI) * 70.0
	return 0.0


func stretch() -> Vector2:
	match state:
		"crouch":
			return Vector2(1.16, 0.8)
		"leap":
			return Vector2(0.9, 1.14)
		"land":
			return Vector2(1.2, 0.78) if _t < 0.12 else Vector2(1.05, 0.95)
	return Vector2.ONE


func draw_body(boil: int, flash: bool) -> void:
	var moving := velocity.length() > 20.0 and state in ["wander", "chase"]
	var step := boil % 2 if moving else -1
	var body := skin(BODY, flash)
	var bob := -3.0 if step == 0 else 0.0
	var at := Vector2(0, -36.0 + bob)
	# Legs and big shoes, one lifted each drawing.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var up := -7.0 if step == i else 0.0
		var hip := at + Vector2(sx * 12.0, 18.0)
		var foot := Vector2(sx * 15.0, -6.0 + up)
		Toon.hose(self, hip, foot, -sx * 3.0, 7.0)
		Toon.ball(self, foot + Vector2(sx * 3.0, 0.0), Vector2(14.0, 8.0), paint(SHOE, flash), boil, _seed + i, 4.0)
		Toon.stroke(self, PackedVector2Array([foot + Vector2(sx * 1.0 - 4.0, -5.0), foot + Vector2(sx * 1.0 + 4.0, -5.0)]),
				1.6, Toon.WHITE)
	# Arms behind the body when swinging back.
	var fists := _fists(at, step)
	for i in 2:
		if not fists[i][2]:
			_arm(at, fists[i], i, boil, body, flash)
	Toon.pear(self, at, Vector2(31.0, 28.0), 0.18, body, boil, _seed + 2)
	Toon.shade(self, at, Vector2(31.0, 28.0), body, boil, _seed + 2, Toon.LINE, 0.18, 0.0, 0.18)
	Toon.shine(self, at, Vector2(31.0, 28.0), 0.4)
	soot(at, Vector2(31.0, 28.0), boil)
	# Warts, and a belly patch.
	for w: Vector2 in [Vector2(-21, -8), Vector2(19, 8), Vector2(-7, -22)]:
		Toon.blob(self, at + w, Vector2(3.5, 3.0), body.darkened(0.15), boil, _seed + 9, 2.0)
	Toon.spot(self, at + Vector2(0, 12.0), Vector2(17.0, 10.0), Color(1, 1, 0.85, 0.22), boil, _seed + 3)
	if floor_look == 2:
		_bandages(at, boil, flash)
	# The face.
	var look := gaze()
	var angry := chasing or state != "wander"
	var lid := 0.55 if angry else 0.35
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var e := at + Vector2(sx * 11.0, -9.0)
		eye(e, Vector2(8.0, 10.0), look, boil, _seed + 4 + i, 3.0)
		if not eyes_shut():
			_lid(e, Vector2(8.0, 10.0), lid, body, sx, angry)
	# An underbite with one tooth up over the lip; wide open mid-leap.
	var mouth_a := at + Vector2(-13.0, 12.0)
	var mouth_b := at + Vector2(13.0, 12.0)
	if state == "leap":
		Toon.blob(self, at + Vector2(0, 13.0), Vector2(9.0, 7.0), Toon.INK, boil, _seed + 12, 0.0)
		Toon.blob(self, at + Vector2(0, 16.0), Vector2(5.0, 3.0), Color("c24a3c"), boil, _seed + 13, 0.0)
	else:
		Toon.blob(self, at + Vector2(6.0, 14.0), Vector2(3.5, 4.0), Toon.WHITE, boil, _seed + 8, 2.0)
		Toon.stroke(self, Toon.bent(mouth_a, mouth_b, 3.0 if angry else 6.0), 3.5)
	# Arms in front when swinging forward or raised.
	for i in 2:
		if fists[i][2]:
			_arm(at, fists[i], i, boil, body, flash)
	if floor_look == 1:
		_helmet(at, boil, flash)


## Where the fists are: [shoulder, fist, in front] for each. Swinging with
## the steps as it wanders; raised like a boxer's when it means it.
func _fists(at: Vector2, step: int) -> Array:
	var list: Array = []
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := at + Vector2(sx * 24.0, -2.0)
		var fist: Vector2
		var front := true
		match state:
			"crouch":
				fist = at + Vector2(sx * 30.0, 20.0)
			"leap":
				fist = at + Vector2(sx * 36.0, -26.0)
			"chase":
				fist = at + Vector2(sx * 18.0, 4.0 + (4.0 if step == i else 0.0))
			_:
				var swing := 8.0 if step == i else -8.0
				fist = at + Vector2(sx * 34.0, 14.0 + swing * 0.3)
				front = step == i
		list.append([shoulder, fist, front])
	return list


func _arm(at: Vector2, fist: Array, i: int, boil: int, body: Color, flash: bool) -> void:
	var sx := -1.0 if i == 0 else 1.0
	var shoulder: Vector2 = fist[0]
	var hand: Vector2 = fist[1]
	Toon.hose(self, shoulder, hand, sx * 5.0, 9.0)
	Toon.hose(self, shoulder, hand, sx * 5.0, 5.0, body.darkened(0.1))
	Toon.ball(self, hand, Vector2(10.0, 9.0), body.darkened(0.12), boil, _seed + 30 + i, 3.5)
	# Knuckles.
	for k in 3:
		var x := (k - 1) * 4.0
		Toon.stroke(self, PackedVector2Array([hand + Vector2(x, -7.0), hand + Vector2(x, -3.0)]), 1.6)
	if floor_look == 2:
		Toon.stroke(self, PackedVector2Array([hand + Vector2(-9, 2), hand + Vector2(9, 5)]), 3.0, paint(BANDAGE, flash))


## A heavy upper eyelid covering the top [param amount] of an eye, slanted
## down towards the nose.
##
## The lid is the part of the eye's ellipse above a chord -- an arc and the
## chord closing it -- so the shape never crosses itself; the slant is the
## whole lid turned a little about the eye.
func _lid(e: Vector2, radii: Vector2, amount: float, color: Color, side: float, angry: bool) -> void:
	var r := radii + Vector2(1.5, 1.5)
	var edge_y := -r.y + r.y * 2.0 * amount
	var k := clampf(-edge_y / r.y, -0.95, 0.95)
	var a0 := PI + asin(k)
	var a1 := TAU - asin(k)
	var slant := -side * (0.3 if angry else 0.12)
	var points := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		points.append(e + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(slant))
	draw_colored_polygon(points, color)
	Toon.stroke(self, PackedVector2Array([points[0], points[n]]), 3.5)


## A miner's helmet with its lamp lit, the light thrown ahead of it.
func _helmet(at: Vector2, boil: int, flash: bool) -> void:
	var top := at + Vector2(0, -22.0)
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		dome.append(top + Vector2(cos(a) * 22.0, sin(a) * 16.0))
	Toon.shape(self, dome, paint(Color("c9a44a"), flash), 3.5)
	Toon.box(self, top + Vector2(0, 1.0), Vector2(27.0, 3.5), paint(Color("a8863a"), flash), boil, _seed + 40, 3.0)
	Toon.spot(self, top + Vector2(-8, -9), Vector2(5, 3), Color(1, 1, 0.9, 0.5))
	var lamp := top + Vector2(0, -9.0)
	Toon.glow(self, lamp, Vector2(40, 30), Color(1, 0.95, 0.6, 0.35), 2)
	Toon.blob(self, lamp, Vector2(6.0, 5.0), Color("fff1a8"), boil, _seed + 41, 3.0)


## Bandages round the mummy: strips across the body with a loose end
## trailing.
func _bandages(at: Vector2, boil: int, flash: bool) -> void:
	var band := paint(BANDAGE, flash)
	# Round the belly, and one across the crown of the head.
	for strip: Array in [[Vector2(-30, 6), Vector2(30, 2)], [Vector2(-27, 18), Vector2(28, 21)],
			[Vector2(-20, -22), Vector2(14, -27)]]:
		var a: Vector2 = at + (strip[0] as Vector2)
		var b: Vector2 = at + (strip[1] as Vector2)
		Toon.stroke(self, Toon.bent(a, b, 4.0), 9.0)
		Toon.stroke(self, Toon.bent(a, b, 4.0), 5.5, band)
	var loose := at + Vector2(24.0, 8.0)
	var wave := sin(boil * 1.3) * 4.0
	Toon.stroke(self, Toon.bent(loose, loose + Vector2(18.0, 12.0 + wave), 5.0), 6.0)
	Toon.stroke(self, Toon.bent(loose, loose + Vector2(18.0, 12.0 + wave), 5.0), 3.5, band)
