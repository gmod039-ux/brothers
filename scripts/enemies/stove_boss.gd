class_name StoveBoss
extends Boss
## Пыхтун, boss of the boiler room: a cast-iron stove come to life, fire in
## his belly-door of a mouth, a chimney for a hat, puffing smoke. Like Bruno,
## three phases and a wind-up before everything:
##   1  waddles at you and spits fireballs in a fan; now and then shovels
##      coal into the air to rain down (watch the shadows)
##   2  more coal, bigger fans; crouches, glows, and bursts out a ring of
##      fireballs with a gap in it to slip through
##   3  red-hot: spins on the spot throwing fire out in a spiral
## He comes apart as the fight goes on: a crack across his front in phase 2,
## the chimney knocked askew and glowing seams in phase 3.
## Everything else -- health, the title card, being in the room's enemies --
## is [Boss]'s.

const IRON := Color("4d4a52")
const IRON_LIGHT := Color("6f6c76")
const HOT := Color("b8402a")
const FIRE := Color("f08a24")
const FIRE_CORE := Color("ffd84a")
const SMOKE := Color("9a9490")

var _spin := 0.0
var _next_ember := 0.0


func setup_boss(room_: Room, rng_: RandomNumberGenerator, floor_index_: int) -> void:
	setup("stove", room_, rng_)
	title = "Пыхтун"
	subtitle = "хозяин котельной"
	floor_index = floor_index_
	# Made for the second floor: tougher only below it.
	max_hp *= 1.0 + 0.4 * maxi(floor_index - 1, 0)
	hp = max_hp
	contact = 1 if floor_index < 2 else 2
	_spawn = 0.0


func can_touch() -> bool:
	return not dead and state != "wait"


func can_be_hit() -> bool:
	return not dead and state != "wait"


func _physics_process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(_flash - delta, 0.0)
	_squash = maxf(_squash - delta, 0.0)
	if state == "wait":
		return
	_t += delta
	var t := target()
	if t != null:
		_aim = (t.global_position - global_position).normalized()
	var now := 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
	if now != phase and state in ["walk", "recover"]:
		phase = now
		phase_changed.emit(phase)
		Sfx.play("roar", 0.0, 0.0)
		Fx.flash(Color(1, 0.55, 0.3), 0.18)
		Fx.shake(0.3)
		Fx.burst(room, global_position + Vector2(0, -150), "embers", 16, 1.3)
		_go("roar")
		return
	velocity = Vector2.ZERO
	match state:
		"walk":
			if t != null:
				velocity = _aim * speed * (1.4 if phase == 3 else 1.0)
			if _t > _walk_for:
				_choose()
		"fire_windup":
			if _t > 0.55:
				_fireballs()
				_go("recover")
		"coal_windup":
			if _t > 0.6:
				_coal_rain()
				_go("recover")
		"belch_windup":
			if _t > 0.5:
				_belch()
				_go("recover")
		"ring_windup":
			if _t > 0.8:
				_fire_ring()
				_go("recover")
		"spin_windup":
			if _t > 0.5:
				_next_ember = 0.0
				_go("spin")
		"spin":
			velocity = _aim * speed * 0.5
			_spin += delta * 4.5
			_next_ember -= delta
			if _next_ember <= 0.0:
				_next_ember = 0.1
				for k in 2:
					var direction := Vector2.from_angle(_spin + PI * k)
					_shoot(direction, 330.0, 8.0, 13.0, 50.0, FIRE)
				Sfx.play("spit", -12.0, 0.2)
				Fx.burst(room, global_position + Vector2(0, -80), "embers", 2, 0.8)
			if _t > 2.4:
				_go("recover")
		"recover":
			if _t > 0.6:
				_go("walk")
		"roar":
			if _t > 0.8:
				_go("walk")
	move_and_slide()


func _choose() -> void:
	var options: Array[String] = []
	match phase:
		1:
			options = ["fire", "fire", "coal", "belch"]
		2:
			options = ["fire", "coal", "ring", "ring", "belch"]
		_:
			options = ["spin", "spin", "fire", "ring", "coal", "belch"]
	_go(options[rng.randi() % options.size()] + "_windup")


func _fireballs() -> void:
	var n := 3 if phase == 1 else 5
	for i in n:
		var spread := (i - (n - 1) * 0.5) * 0.24
		var ball := _shoot(_aim.rotated(spread), 430.0, 9.0, 16.0, 70.0, FIRE)
		# Where a fireball comes down it leaves a puddle of fire.
		ball.finished.connect(func(how: String) -> void:
			if how == "floor" or how == "wall":
				_fire_patch(ball.global_position))
	Fx.burst(room, global_position + Vector2(0, -76), "embers", 8, 1.0)
	Sfx.play("spit", -2.0)
	_squash = 2.0 / Toon.FPS


## A ring of fireballs out in every direction, three missing together on a
## random side: that gap is the way through.
func _fire_ring() -> void:
	var n := 20
	var gap := rng.randi() % n
	for i in n:
		var d := (i - gap + n) % n
		if d < 3:
			continue
		_shoot(Vector2.from_angle(TAU * i / n), 300.0, 9.0, 15.0, 40.0, FIRE)
	Fx.ring(room, global_position, 260.0, Color(1.0, 0.5, 0.15, 0.8), 0.4, 10.0)
	Fx.burst(room, global_position + Vector2(0, -80), "embers", 20, 1.4)
	Fx.shake(0.25)
	Sfx.play("blast", -4.0)
	_squash = 3.0 / Toon.FPS


func _fire_patch(at: Vector2) -> void:
	var inside := room.floor_rect().grow(-30.0)
	var patch := FirePatch.new()
	patch.room = room
	room.decals.add_child(patch)
	patch.global_position = Vector2(clampf(at.x, inside.position.x, inside.end.x),
			clampf(at.y, inside.position.y, inside.end.y))


## Coughs up live coals that waddle at the brother. At most four about.
func _belch() -> void:
	var coals := 0
	for enemy in room.enemies:
		if enemy is EmberEnemy:
			coals += 1
	for i in maxi(0, mini(2 + (phase - 1), 4 - coals)):
		var at := global_position + Vector2((i - 1) * 50.0, 40.0)
		Waves.spawn("ember", room, rng, at)
	Fx.burst(room, global_position + Vector2(0, -76), "embers", 14, 1.2)
	Sfx.play("spit", 0.0, 0.0)
	_squash = 2.0 / Toon.FPS


## A shovelful of coal up in the air: the first lump at the brother, the
## rest scattered about the room.
func _coal_rain() -> void:
	var n := 4 + phase * 2
	var floor_box := room.floor_rect().grow(-60.0)
	var t := target()
	for i in n:
		var at := Vector2(rng.randf_range(floor_box.position.x, floor_box.end.x),
				rng.randf_range(floor_box.position.y, floor_box.end.y))
		if i == 0 and t != null:
			at = t.global_position
		var lump := Falling.new()
		lump.room = room
		lump.delay = i * 0.14
		room.effects.add_child(lump)
		lump.global_position = at
	Sfx.play("whistle_up", -6.0)


func _shadow_size() -> Vector2:
	return Vector2(78, 22)


func _height_of_head() -> float:
	return 130.0


func _pose(boil: int) -> Array:
	var squash := 0.0
	match state:
		"fire_windup", "coal_windup", "spin_windup", "belch_windup":
			squash = 0.1
		"ring_windup":
			# Crouches lower and lower, shaking.
			squash = 0.08 + 0.12 * minf(_t / 0.8, 1.0)
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
		"wait":
			# Stamping to get the fire going.
			squash = [0.0, 0.08, 0.0, -0.04][boil % 4]
	if _squash > 0.0:
		squash = 0.14
	var turn := sin(_spin) * 0.15 if state == "spin" else 0.0
	var offset := Vector2.ZERO
	if state == "ring_windup":
		offset = Vector2(Toon.hash01(boil, 7) - 0.5, 0) * 8.0
	return [offset, turn, Vector2(1.0 + squash, 1.0 - squash)]


func _figure(boil: int, flash: bool) -> void:
	_draw_stove(boil, flash)


func _draw_stove(boil: int, flash: bool) -> void:
	var heat := 0.55 if phase == 3 else (0.2 if phase == 2 else 0.0)
	if state == "ring_windup":
		heat = minf(heat + 0.5 * _t / 0.8, 0.9)
	if _ko >= 0.0:
		heat = 0.0
	var iron := paint(IRON.lerp(HOT, heat), flash)
	var light := paint(IRON_LIGHT.lerp(HOT.lightened(0.2), heat), flash)
	var white := paint(BrotherLook.WHITE, flash)
	# Short cast-iron legs.
	var step := 0.0
	if state == "walk" and _ko < 0.0:
		step = [1.0, 0.0, -1.0, 0.0][boil % 4]
	for sx: float in [-1.0, 1.0]:
		var foot := Vector2(sx * 42.0, -(7.0 if step * sx > 0.0 else 0.0))
		Toon.box(self, foot + Vector2(0, -10), Vector2(10, 14), iron, boil, 2 + int(sx), 4.0)
		Toon.blob(self, foot + Vector2(sx * 4.0, -2.0), Vector2(20, 9), paint(Toon.INK, flash), boil, 4 + int(sx), 3.0)
	# Arms: hose arms with gloves; up with both hands to throw, one wound
	# back with the shovel for coal.
	var hands := [Vector2(-92, -70), Vector2(92, -70)]
	match state:
		"fire_windup", "spin", "spin_windup":
			hands = [Vector2(-96, -170), Vector2(96, -170)]
		"coal_windup":
			hands[1] = Vector2(80, -200)
		"ring_windup", "wait":
			hands = [Vector2(-70, -40), Vector2(70, -40)]
	if _ko >= 0.0:
		hands = [Vector2(-100, -180), Vector2(100, -180)] if _ko < SHAKE_TIME else [Vector2(-90, -20), Vector2(90, -20)]
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := Vector2(sx * 56.0, -112.0)
		var hand: Vector2 = hands[i]
		Toon.hose(self, shoulder, hand + (shoulder - hand).normalized() * 14.0, sx * -12.0, 11.0)
		Toon.ball(self, hand, Vector2(17, 15), white, boil, 10 + i, 4.0, 0.0, 0.14)
	# The body: a riveted iron box.
	var body := Vector2(0, -98)
	Toon.box(self, body, Vector2(64, 72), iron, boil, 12, 6.0)
	# The shadowed side of the iron, and a sheen down the lit one.
	draw_rect(Rect2(body + Vector2(34, -60), Vector2(26, 124)), iron.darkened(0.25))
	draw_rect(Rect2(body + Vector2(-54, -56), Vector2(8, 110)), Color(1, 1, 1, 0.12))
	# The maker's plate.
	Toon.box(self, body + Vector2(0, 54), Vector2(22, 7), paint(Color("b8863a"), flash), boil, 27, 2.5)
	Toon.box(self, body + Vector2(0, -70), Vector2(70, 9), light, boil, 13, 4.0)
	for k in 5:
		var x := -48.0 + k * 24.0
		Toon.spot(self, body + Vector2(x, 60), Vector2(3.5, 3.5), Toon.INK)
		Toon.spot(self, body + Vector2(x, -58), Vector2(3.5, 3.5), Toon.INK)
	if phase >= 2:
		# A crack across his front, and a rivet gone.
		var crack := PackedVector2Array([body + Vector2(-60, -40), body + Vector2(-44, -34), body + Vector2(-40, -18),
				body + Vector2(-26, -10)])
		Toon.stroke(self, crack, 3.0)
		Toon.stroke(self, PackedVector2Array([crack[2], crack[2] + Vector2(-12, 10)]), 2.0)
		if phase >= 3 and _ko < 0.0:
			# Glowing through it.
			Toon.stroke(self, crack, 1.4, FIRE_CORE)
			var seam := PackedVector2Array([body + Vector2(40, 30), body + Vector2(30, 40), body + Vector2(36, 54)])
			Toon.stroke(self, seam, 3.0)
			Toon.stroke(self, seam, 1.4, FIRE_CORE)
	# The mouth: the fire door, wide open while he gets ready to spit.
	var open := 1.35 if state in ["fire_windup", "spin", "roar", "belch_windup", "ring_windup", "wait"] else 1.0
	if _ko >= 0.0:
		open = 1.4
	var mouth := body + Vector2(0, 22)
	Toon.box(self, mouth, Vector2(38, 22 * open), Color("1a0d08"), boil, 14, 4.5)
	if _ko >= SHAKE_TIME:
		# The fire's gone out: a wisp of smoke from the cold grate.
		Toon.blob(self, mouth + Vector2(0, 10), Vector2(22, 8), Color("3a3432"), boil, 15, 0.0)
	else:
		if state in ["fire_windup", "ring_windup", "spin_windup"]:
			# Stoking up: the glow spills out of the door.
			Toon.glow(self, mouth, Vector2(80, 60), Color(1, 0.6, 0.2, 0.5), 3)
		for k in 3:
			var flick := [0.0, 4.0, -3.0][(boil + k) % 3] as float
			Toon.blob(self, mouth + Vector2(-20 + k * 20, 6 - flick), Vector2(12, 14 * open), FIRE, boil, 15 + k, 0.0)
			Toon.blob(self, mouth + Vector2(-20 + k * 20, 10 - flick), Vector2(6, 7 * open), FIRE_CORE, boil, 18 + k, 0.0)
	# The grate across it: bars for teeth.
	for k in 5:
		var x := -28.0 + k * 14.0
		Toon.stroke(self, PackedVector2Array([mouth + Vector2(x, -20 * open), mouth + Vector2(x, 20 * open)]), 3.5, light)
	# Eyes under heavy iron brows, and a knob for a nose.
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var e := body + Vector2(sx * 25.0, -30.0)
		eye(e, Vector2(13, 16), look, boil, 20 + int(sx), 3.5)
		if _ko < 0.0:
			brow(e + Vector2(0, -20), 30.0, sx < 0.0, 8.0)
	Toon.blob(self, body + Vector2(0, -6), Vector2(9, 8), light, boil, 23, 3.5)
	# The chimney for a hat -- knocked askew in phase 3 -- and the smoke out
	# of it: thick and black while he is stoking up, a thin grey wisp when
	# he is out.
	var lean := 0.25 if phase >= 3 else 0.0
	var pipe := body + Vector2(18, -74)
	Toon.box(self, pipe + Vector2(0, -30).rotated(lean), Vector2(16, 30), iron, boil, 24, 4.5, lean)
	var top := pipe + Vector2(0, -60).rotated(lean)
	Toon.box(self, top, Vector2(22, 7), light, boil, 25, 4.0, lean)
	var puffs := 3 if phase < 3 else 5
	var smoke := SMOKE
	if state in ["fire_windup", "ring_windup", "wait", "roar"]:
		puffs += 2
		smoke = Color("4a4442")
	if _ko >= 0.0:
		puffs = 2 if _ko >= SHAKE_TIME else 6
		smoke = Color("4a4442") if _ko < SHAKE_TIME else Color(SMOKE, 0.6)
	for k in puffs:
		var rise := float((boil + k * 3) % 9) / 9.0
		var at := top + Vector2(sin(rise * 6.0 + k) * 10.0 + lean * 40.0 * rise, -16 - rise * 90.0)
		Toon.blob(self, at, Vector2(12, 10) * (0.6 + rise), Color(smoke, smoke.a * (1.0 - rise * 0.7)), boil, 26 + k, 3.0)
