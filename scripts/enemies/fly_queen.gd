class_name FlyQueen
extends MiniBoss
## Мадам Жужу, queen of the basement's flies: a fly the size of a sideboard
## with a little gold crown askew on her head, a pink feather boa, long
## lashes and lipstick. She flies -- rocks are nothing to her -- weaving
## round the brother a few steps off. She lays flies, two at a time (her
## striped behind wiggles first), never more than four about; buzzes with
## her brows down -- the warning -- and dives at where he stood. From half
## health she also puffs out her cheeks and spits a fan of five.

const BODY := Color("4b3f58")
const BELLY := Color("c9a44a")
const BOA := Color("e88aa8")
const LIPS := Color("d23a4c")
const MOST_FLIES := 4
const HOVER := 64.0

var _weave := 0.0
var _dart := Vector2.ZERO


func setup_boss(room_: Room, rng_: RandomNumberGenerator, floor_index_: int) -> void:
	setup("fly_queen", room_, rng_)
	title = "Мадам Жужу"
	subtitle = "королева мух"
	floor_index = floor_index_
	hp = max_hp
	contact = 1
	_spawn = 0.0
	_weave = rng.randf() * TAU


func _calm_states() -> Array:
	return ["walk", "recover", "drift"]


func _fight(delta: float, t: Brother) -> void:
	match state:
		"walk":
			_weave += delta * 3.0
			if t != null:
				var to := t.global_position - global_position
				var keep := 1.0 if to.length() > 330.0 else -0.7
				var want := to.normalized() * keep + to.orthogonal().normalized() * sin(_weave) * 0.9
				# Off the walls: up against one she is half out of the picture.
				var inside := room.floor_rect().grow(-150.0)
				if not inside.has_point(global_position):
					want += (inside.get_center() - global_position).normalized() * 1.2
				velocity = want.normalized() * speed
			if _t > _walk_for:
				_choose()
		"lay_windup":
			if _t > 0.6:
				_lay()
				_go("recover")
		"buzz":
			_dart = _aim
			if _t > 0.55:
				_go("dart")
				Sfx.play("whistle_up", -8.0, 0.2)
		"dart":
			velocity = _dart * speed * 3.4
			if _t > 0.42 or is_on_wall():
				_go("drift")
		"drift":
			velocity = _dart * speed * 0.8 * maxf(1.0 - _t / 0.5, 0.0)
			if _t > 0.5:
				_go("walk")
		"spit_windup":
			if _t > 0.5:
				for i in 5:
					_shoot(_aim.rotated((i - 2) * 0.2), 430.0, 8.0, 13.0, HOVER + 20.0, Color("9a6ab0"))
				Sfx.play("spit", -4.0)
				_squash = 2.0 / Toon.FPS
				_go("recover")
		"recover":
			if _t > 0.5:
				_go("walk")


func _choose() -> void:
	var options := ["dive", "dive", "lay"]
	if phase >= 2:
		options.append_array(["spit", "spit", "dive"])
	if minions("fly") >= MOST_FLIES:
		options.erase("lay")
	match str(options[rng.randi() % options.size()]):
		"dive":
			_go("buzz")
			Sfx.play("fuse", -12.0, 0.3)
		"lay":
			_go("lay_windup")
			Sfx.play("whistle_down", -12.0, 0.2)
		_:
			_go("spit_windup")


## Two flies out of her, never more than four about.
func _lay() -> void:
	for i in mini(2, MOST_FLIES - minions("fly")):
		_call("fly", global_position + Vector2(-50.0 + i * 100.0, 40.0))
	Sfx.play("poof", -8.0)


func _shadow_size() -> Vector2:
	return Vector2(58, 18)


func _height_of_head() -> float:
	return 150.0


func daze_height() -> float:
	return 190.0 + HOVER


func _pose(boil: int) -> Array:
	var squash := 0.0
	var bob: float = [0.0, 4.0, 7.0, 4.0][boil % 4]
	var offset := Vector2(0, -HOVER - bob)
	match state:
		"lay_windup", "spit_windup":
			squash = 0.08
		"buzz":
			offset += Vector2(Toon.hash01(boil, 1) - 0.5, Toon.hash01(boil, 2) - 0.5) * 8.0
		"dart":
			squash = -0.1
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
		"wait":
			# Fluttering her lashes for the audience.
			squash = [0.0, 0.03, 0.0, -0.03][boil % 4]
	if _squash > 0.0:
		squash = 0.12
	return [offset, 0.0, Vector2(1.0 + squash, 1.0 - squash)]


func _figure(boil: int, flash: bool) -> void:
	var body := paint(BODY, flash)
	var head := Vector2(0, -110)
	var fast := state in ["buzz", "dart"]
	_wings(head, boil, flash, fast)
	# Six legs dangling, paddling the air.
	for i in 3:
		for sx: float in [-1.0, 1.0]:
			var root := head + Vector2(sx * (8.0 + i * 8.0), 30.0)
			var swing := sin(boil * 1.4 + i * 1.7 + sx) * 6.0
			var foot := root + Vector2(sx * (16.0 + i * 6.0) + swing, 34.0 - i * 6.0)
			Toon.hose(self, root, foot, sx * 7.0, 6.0)
			Toon.blob(self, foot, Vector2(5, 4), paint(Toon.INK, flash), boil, _seed + 30 + i, 0.0)
	# The abdomen, striped gold and black, wiggling before she lays.
	var wiggle := (8.0 if boil % 2 == 0 else -8.0) if state == "lay_windup" else 0.0
	var belly := head + Vector2(wiggle, 56.0)
	Toon.ball(self, belly, Vector2(40, 34), paint(BELLY, flash), boil, _seed + 1, 5.0, 0.0, 0.25)
	for j in 3:
		Toon.stroke(self, Toon.bent(belly + Vector2(-36.0 + j * 4.0, -14.0 + j * 12.0), belly + Vector2(36.0 - j * 4.0,
				-14.0 + j * 12.0), 8.0), 7.0)
	Toon.shape(self, PackedVector2Array([belly + Vector2(-8, 30), belly + Vector2(8, 30), belly + Vector2(0, 46)]),
			paint(Toon.INK, flash), 2.0)
	# The boa: a ring of pink fluff round her neck.
	for k in 11:
		var a := PI * 0.05 + PI * 0.9 * k / 10.0
		var at := head + Vector2(cos(a) * 46.0, 22.0 + sin(a) * 14.0)
		Toon.blob(self, at, Vector2(11, 9), paint(BOA, flash), boil, _seed + 40 + k, 2.5, a)
	# Head and thorax in one, with fuzz on it.
	Toon.ball(self, head, Vector2(46, 40), body, boil, _seed)
	for j in 4:
		Toon.stroke(self, PackedVector2Array([head + Vector2(-18 + j * 12, -36), head + Vector2(-20 + j * 13, -48)]), 3.0)
	# Eyes, great bulging ones, with lashes; brows down for a dive.
	var look := gaze() if not fast else _dart
	for sx: float in [-1.0, 1.0]:
		var e := head + Vector2(sx * 17.0, -6.0)
		eye(e, Vector2(15, 18), look, boil, _seed + 5 + int(sx), 4.0)
		if not eyes_shut():
			for j in 3:
				var a := -PI * 0.5 + sx * (0.25 + j * 0.3)
				Toon.stroke(self, PackedVector2Array([e + Vector2(cos(a), sin(a)) * 18.0, e + Vector2(cos(a), sin(a)) * 27.0]), 3.0)
			if fast:
				Toon.stroke(self, PackedVector2Array([e + Vector2(sx * 16.0, -24.0), e + Vector2(-sx * 6.0, -14.0)]), 5.0,
						Toon.WHITE)
	# Cheeks, puffed for a spit; lips in red.
	var puff := 1.8 if state == "spit_windup" else 1.0
	for sx: float in [-1.0, 1.0]:
		Toon.spot(self, head + Vector2(sx * 30.0, 16.0), Vector2(8, 6) * puff, Color(LIPS, 0.4))
	var mouth := head + Vector2(0, 24)
	if state == "spit_windup":
		Toon.blob(self, mouth, Vector2(7, 7), paint(LIPS, flash), boil, _seed + 9, 3.0)
	else:
		Toon.blob(self, mouth + Vector2(-5, 0), Vector2(7, 5), paint(LIPS, flash), boil, _seed + 9, 3.0)
		Toon.blob(self, mouth + Vector2(5, 0), Vector2(7, 5), paint(LIPS, flash), boil, _seed + 10, 3.0)
	# The crown, askew.
	var crown := head + Vector2(12, -44)
	var points := PackedVector2Array([crown + Vector2(-22, 6), crown + Vector2(-24, -16), crown + Vector2(-12, -6),
			crown + Vector2(0, -22), crown + Vector2(12, -6), crown + Vector2(24, -16), crown + Vector2(22, 6)])
	var turned := PackedVector2Array()
	for p in points:
		turned.append(crown + (p - crown).rotated(0.25))
	Toon.shape(self, turned, paint(Color("e0b23a"), flash), 3.5)
	for j in 3:
		Toon.spot(self, crown + Vector2(-14 + j * 14, -2).rotated(0.25), Vector2(3.5, 3.5), Color("c8392b"))
	if state == "buzz":
		for sx: float in [-1.0, 1.0]:
			for j in 2:
				var from := head + Vector2(sx * (64.0 + j * 12.0), -14.0 + j * 24.0)
				Toon.stroke(self, PackedVector2Array([from, from + Vector2(sx * 16.0, -6.0)]), 3.0)


## Wings: two veined ovals, up then down; a blur of arcs while she dives.
func _wings(head: Vector2, boil: int, flash: bool, fast: bool) -> void:
	var up := boil % 2 == 0
	for sx: float in [-1.0, 1.0]:
		var rot := sx * (0.95 if up else 0.3)
		var at := head + Vector2(sx * 52.0, -32.0 if up else -12.0)
		var radii := Vector2(46, 24)
		if fast:
			for j in 3:
				Toon.spot(self, head + Vector2(sx * 52.0, -26.0 + j * 9.0), radii, Color(1, 1, 1, 0.16), 0, j,
						sx * (0.2 + j * 0.35))
			continue
		Toon.blob(self, at, radii, paint(Color("dfe9ee"), flash), boil, _seed + 20 + int(sx), 3.5, rot)
		for j in 2:
			var from := at - Vector2(radii.x * 0.7, 0).rotated(rot) * sx
			var to := at + Vector2(radii.x * 0.6, (j - 0.5) * 18.0).rotated(rot) * sx
			Toon.stroke(self, Toon.bent(from, to, 4.0), 1.8, Color(Toon.INK, 0.5))
