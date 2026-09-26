class_name FlyEnemy
extends Enemy
## Муха: a housefly the size of a cat. Weaves at you through the air, over
## rocks; now and then it stops dead, buzzes with its brows down -- the
## warning -- and darts in a straight line at where you stood, then drifts
## to a stop.
##
## Floors: plain in the basement; in the boiler room an aviator's leather
## cap and goggles, soot on it; in the catacombs pale, wings in tatters,
## stitched up.

const BODY := Color("4b3f58")
const BELLY := Color("c9a44a")
const WING := Color("dfe9ee")
const LEATHER := Color("7a4a2a")
const BUZZ_TIME := 0.5
const DART_TIME := 0.32

## "fly", "buzz", "dart" or "drift".
var state := "fly"
var _t := 0.0
var _next := 3.0
var _dart := Vector2.ZERO
var _weave := 0.0


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_next = rng.randf_range(1.8, 3.6)
	_weave = rng.randf() * TAU


func _switch(to: String) -> void:
	state = to
	_t = 0.0


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	if t == null:
		return Vector2.ZERO
	var to := t.global_position - global_position
	match state:
		"buzz":
			_dart = to.normalized()
			if _t > BUZZ_TIME:
				_switch("dart")
				Sfx.play("whistle_up", -14.0, 0.25)
			return Vector2.ZERO
		"dart":
			if _t > DART_TIME or is_on_wall():
				_switch("drift")
			return _dart * speed * 3.4
		"drift":
			if _t > 0.5:
				_switch("fly")
				_next = rng.randf_range(2.4, 4.0) - floor_look * 0.4
			return _dart * speed * 0.6 * (1.0 - _t / 0.5)
	_weave += delta * 5.0
	if _t > _next and to.length() < 460.0:
		_switch("buzz")
		Sfx.play("fuse", -16.0, 0.3)
	var dir := to.normalized()
	return (dir + dir.orthogonal() * sin(_weave) * 0.7).normalized() * speed


func draw_body(boil: int, flash: bool) -> void:
	var bob: float = [0.0, 3.0, 5.0, 3.0][boil % 4]
	var at := Vector2(0, -34.0 - bob)
	if state == "buzz":
		# Trembling with rage.
		at += Vector2(Toon.hash01(boil, 1) - 0.5, Toon.hash01(boil, 2) - 0.5) * 6.0
	# Drawn for a radius of 20 and scaled to the data's.
	var k := radius / 20.0
	var body := skin(BODY, flash)
	var fast := state == "buzz" or state == "dart"
	_wings(at, k, boil, flash, fast)
	# Six legs dangling from under it, paddling the air.
	for i in 3:
		for sx: float in [-1.0, 1.0]:
			var root := at + Vector2(sx * (3.0 + i * 3.0), 8.0) * k
			var swing := sin(boil * 1.4 + i * 1.7 + sx) * 3.0
			var foot := root + Vector2(sx * (7.0 + i * 3.0) + swing, 13.0 - i * 2.0) * k
			Toon.hose(self, root, foot, sx * 3.0 * k, 2.6 * k)
	# The abdomen, striped, hanging behind and below.
	var belly_at := at + Vector2(0, 10.0) * k
	Toon.ball(self, belly_at, Vector2(12.0, 10.0) * k, skin(BELLY, flash), boil, _seed + 1, 3.5, 0.0, 0.25)
	for j in 2:
		Toon.stroke(self, Toon.bent(belly_at + Vector2(-10.0 + j * 1.5, -4.0 + j * 4.5) * k,
				belly_at + Vector2(10.0 - j * 1.5, -4.0 + j * 4.5) * k, 2.5 * k), 2.6 * k)
	# Head and thorax in one.
	Toon.ball(self, at, Vector2(16.0, 14.0) * k, body, boil, _seed)
	soot(at, Vector2(16.0, 14.0) * k, boil)
	# Fuzz on its crown.
	for j in 3:
		Toon.stroke(self, PackedVector2Array([at + Vector2(-6 + j * 6, -12) * k, at + Vector2(-7 + j * 7, -18) * k]), 1.8)
	if floor_look == 2:
		# Stitches across its head.
		Toon.stroke(self, Toon.bent(at + Vector2(4, -12) * k, at + Vector2(14, -2) * k, 2.0), 1.6)
		for j in 3:
			var p := (at + Vector2(4, -12) * k).lerp(at + Vector2(14, -2) * k, (j + 0.5) / 3.0)
			Toon.stroke(self, PackedVector2Array([p + Vector2(-3, -2), p + Vector2(3, 2)]), 1.6)
	# Big bulging eyes, and the sucker it drinks with.
	var look := gaze() if not fast else _dart
	for sx: float in [-1.0, 1.0]:
		eye(at + Vector2(sx * 6.5, -2.0) * k, Vector2(6.0, 7.5) * k, look, boil, _seed + 5 + int(sx), 2.5)
	var snout := at + Vector2(0, 6.0) * k
	Toon.stroke(self, PackedVector2Array([snout, snout + Vector2(0, 6.0) * k]), 3.5 * k)
	Toon.blob(self, snout + Vector2(0, 7.5) * k, Vector2(3.5, 2.5) * k, skin(BELLY.darkened(0.3), flash), boil, _seed + 9, 2.0)
	if not eyes_shut():
		# Brows in white: black on a dark body would not show. Steeper when
		# it means it.
		var tilt := 7.0 if fast else 4.0
		for sx: float in [-1.0, 1.0]:
			Toon.stroke(self, PackedVector2Array([at + Vector2(sx * 10.5, -12.0 - tilt * 0.3) * k,
					at + Vector2(sx * 2.0, -12.0 + tilt) * k]), 2.5, Toon.WHITE)
	if floor_look == 1:
		_aviator(at, k, boil, flash)
	if state == "buzz":
		# Buzz lines either side.
		for sx: float in [-1.0, 1.0]:
			for j in 2:
				var from := at + Vector2(sx * (24.0 + j * 6.0), -6.0 + j * 10.0) * k
				Toon.stroke(self, PackedVector2Array([from, from + Vector2(sx * 7.0, -3.0) * k]), 2.0)


## Wings: two veined ovals, up then down, a blur of arcs when it is in a
## hurry. In the catacombs they are torn.
func _wings(at: Vector2, k: float, boil: int, flash: bool, fast: bool) -> void:
	var up := boil % 2 == 0
	for sx: float in [-1.0, 1.0]:
		var rot := sx * (0.95 if up else 0.3)
		var wing_at := at + Vector2(sx * 13.0, -10.0 if up else -3.0) * k
		var radii := Vector2(13.0, 7.5) * k
		if fast:
			# The blur: a fan of faint copies.
			for j in 3:
				var r := sx * (0.2 + j * 0.35)
				Toon.spot(self, at + Vector2(sx * 13.0, -8.0 + j * 3.0) * k, radii, Color(1, 1, 1, 0.18), 0, j, r)
		Toon.blob(self, wing_at, radii, paint(WING, flash), boil, _seed + int(sx) + 3, 3.0, rot)
		# Veins.
		var dir := Vector2(cos(rot), sin(rot)) * sx
		Toon.stroke(self, PackedVector2Array([wing_at - dir * radii.x * 0.7, wing_at + dir * radii.x * 0.6]), 1.2,
				Color(Toon.INK, 0.5))
		Toon.stroke(self, PackedVector2Array([wing_at, wing_at + dir.rotated(-0.5 * sx) * radii.x * 0.6]), 1.0,
				Color(Toon.INK, 0.45))
		if floor_look == 2:
			# Holes in them.
			Toon.spot(self, wing_at + dir * radii.x * 0.35, Vector2(3.0, 2.2) * k, Color(0.1, 0.1, 0.1, 0.55))
			Toon.spot(self, wing_at - dir * radii.x * 0.2 + Vector2(0, 2) * k, Vector2(2.0, 1.5) * k,
					Color(0.1, 0.1, 0.1, 0.55))


## A leather flying cap with the goggles pushed up on it.
func _aviator(at: Vector2, k: float, boil: int, flash: bool) -> void:
	var leather := paint(LEATHER, flash)
	var cap := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		cap.append(at + Vector2(cos(a) * 15.5, -2.0 + sin(a) * 13.0) * k)
	Toon.shape(self, cap, leather, 3.0)
	# Ear flaps.
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, at + Vector2(sx * 14.0, 2.0) * k, Vector2(4.0, 6.5) * k, leather, boil, _seed + 20 + int(sx), 2.5)
	# Goggles on the forehead.
	Toon.stroke(self, PackedVector2Array([at + Vector2(-15, -9) * k, at + Vector2(15, -9) * k]), 3.0 * k)
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, at + Vector2(sx * 6.0, -10.0) * k, Vector2(5.0, 4.5) * k, Color("c9c6c0"), boil, _seed + 22, 2.5)
		Toon.blob(self, at + Vector2(sx * 6.0, -10.0) * k, Vector2(3.2, 2.8) * k, Color("8fb4c8"), boil, _seed + 23, 0.0)
		Toon.spot(self, at + Vector2(sx * 6.0 - 1.2, -11.0) * k, Vector2(1.2, 0.9) * k, Color(1, 1, 1, 0.9))
