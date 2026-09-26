class_name Boss
extends Enemy
## Громила Бруно, boss of the basement: a bulldog thug in a bowler hat and a
## convict's stripes. Three phases by health, each with its own tricks, and
## every attack announced by a wind-up the way a cartoon's anticipation
## always tells you what is coming:
##   1  walks at you; jumps and lands with a shockwave (a target on the floor
##      shows where); now and then throws
##   2  throws more, and whistles his boys in
##   3  red with rage: paws the floor and charges across the room until he
##      hits a wall and sees stars (that is the time to hit him); jumps three
##      times running
## He is in the room's enemies like any other, so shots and touching work
## the same; he is simply never knocked back.
##
## What every boss shares lives here too: the show while the title card is
## up, breathing and blinking, getting more beaten up phase by phase, and
## the knockout -- a shaking, flashing, exploding fall flat on his back with
## stars going round, before the last poof. A boss draws himself through
## [method _pose] and [method _figure].

signal stomped
signal phase_changed(phase: int)

const SKIN := Color("b98a5e")
const SKIN_LIGHT := Color("dcb489")
const RAGE := Color("d0553c")
const AIR_TIME := 0.85
const JUMP_HEIGHT := 280.0
const STOMP_REACH := 135.0
const CHARGE_SPEED := 760.0
## The knockout: shaking and exploding, then falling over, then lying there.
const SHAKE_TIME := 1.2
const FALL_TIME := 0.35
const DEFEAT_TIME := 2.8
const PLASTER := Color("e8c9a0")

var title := "Громила Бруно"
var subtitle := "гроза подвала"
var phase := 1
## "wait" until the title card is over, then "walk", "windup", "air",
## "land", "throw_windup", "recover", "charge_windup", "charge", "stunned",
## "roar".
var state := "wait"
var floor_index := 0

var _t := 0.0
var _walk_for := 1.5
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _height := 0.0
var _charge := Vector2.ZERO
var _aim := Vector2.DOWN
var _throws := 0
## Jumps still to come in a run of them (phase 3).
var _combo := 0
## Seconds to the next explosion while being knocked out.
var _boom_in := 0.0
## Which way he falls when knocked out: -1 left, 1 right.
var _fall_side := 1.0


func setup_boss(room_: Room, rng_: RandomNumberGenerator, floor_index_: int) -> void:
	setup("boss", room_, rng_)
	floor_index = floor_index_
	max_hp *= 1.0 + 0.4 * floor_index
	hp = max_hp
	contact = 1 if floor_index < 2 else 2
	_spawn = 0.0


## Starts the fight, once the title card has had its moment.
func wake() -> void:
	if state == "wait":
		_go("walk")


func can_touch() -> bool:
	return not dead and state != "wait" and state != "air"


func can_be_hit() -> bool:
	return not dead and state != "air" and state != "wait"


func hurt(damage: float, _direction: Vector2, _strength := 1.0) -> void:
	super.hurt(damage, Vector2.ZERO)
	# A boss takes a stream of hits: screwing his eyes up at every one would
	# leave them shut the whole fight.
	_wince = 0.0


func ko_time() -> float:
	return DEFEAT_TIME


func blink_now() -> bool:
	if dead or state in ["stunned", "air", "charge"]:
		return false
	return fmod(_clock + _seed * 0.37, 3.3) < 0.14


## The knockout: everything stops, the screen flashes, and he takes his
## time going down.
func knock_out() -> void:
	if dead:
		return
	super.knock_out()
	_height = 0.0
	_fall_side = -1.0 if rng != null and rng.randf() < 0.5 else 1.0
	_boom_in = 0.0
	Fx.flash(Color(1, 1, 1), 0.2)
	Fx.shake(0.6)
	Sfx.play("roar", 0.0, 0.0)


func _process(delta: float) -> void:
	super._process(delta)
	if _ko < 0.0 or _gone:
		return
	if _ko < SHAKE_TIME:
		# Pops going off all over him.
		_boom_in -= delta
		if _boom_in <= 0.0:
			_boom_in = 0.13
			var at := global_position + Vector2(rng.randf_range(-1.0, 1.0) * radius * 1.3,
					-rng.randf_range(0.3, 2.6) * radius)
			var puff := Puff.new()
			puff.radius = radius * rng.randf_range(0.45, 0.7)
			puff.stars = 2
			room.effects.add_child(puff)
			puff.global_position = at
			Sfx.play("blast", -10.0, 0.3)
			Fx.shake(0.1)
	elif _ko - delta < SHAKE_TIME + FALL_TIME and _ko >= SHAKE_TIME + FALL_TIME:
		# Hits the floor.
		Sfx.play("stomp", 0.0)
		Sfx.play("stars", -4.0)
		Fx.burst(room, global_position + Vector2(_fall_side * radius * 1.5, 0), "dust", 14, 1.4)
		Fx.shake(0.35)


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
	if now != phase and state in ["walk", "recover", "land", "stunned"]:
		phase = now
		phase_changed.emit(phase)
		Sfx.play("roar", 0.0, 0.0)
		Fx.flash(Color(1, 0.95, 0.85), 0.12)
		Fx.shake(0.3)
		_combo = 0
		_go("roar")
		return
	velocity = Vector2.ZERO
	match state:
		"walk":
			if t != null:
				velocity = _aim * speed * (1.5 if phase == 3 else 1.0)
			if _t > _walk_for:
				_choose()
		"whistle":
			if _t > 0.7:
				_summon()
				_go("recover")
		"windup":
			if _t > (0.5 if _combo == 0 else 0.3):
				_take_off()
		"air":
			var k := minf(_t / AIR_TIME, 1.0)
			global_position = _from.lerp(_to, k)
			_height = sin(k * PI) * JUMP_HEIGHT
			if k >= 1.0:
				_land()
		"land":
			if _combo > 0 and _t > 0.3:
				_combo -= 1
				_go("windup")
			elif _t > 0.55:
				_go("walk")
		"throw_windup":
			if _t > 0.45:
				_throw()
				_go("recover")
		"recover":
			if _t > 0.55:
				_go("walk")
		"charge_windup":
			# Pawing the floor like a bull.
			if int(_t * 8.0) != int((_t - delta) * 8.0):
				Fx.burst(room, global_position - _aim * 40.0, "dust", 3, 0.6)
				Sfx.play("stomp", -16.0, 0.3)
			if _t > 0.7:
				_charge = _aim
				_go("charge")
		"charge":
			velocity = _charge * CHARGE_SPEED
			if int(_t * 30.0) % 2 == 0:
				Fx.burst(room, global_position + Vector2(0, -4), "dust", 1, 0.4)
		"stunned":
			if _t > 1.2:
				_go("walk")
		"roar":
			if _t > 0.8:
				if phase >= 2:
					_go("whistle")
				else:
					_go("walk")
	if state != "air":
		move_and_slide()
	if state == "charge" and (get_slide_collision_count() > 0 or _t > 1.8):
		_squash = 3.0 / Toon.FPS
		stomped.emit()
		Sfx.play("stomp", 0.0)
		Sfx.play("stars", -6.0)
		Fx.burst(room, global_position + Vector2(0, -200), "stars", 6, 0.6)
		Fx.burst(room, global_position, "dust", 8, 1.0)
		_go("stunned")


func _go(next: String) -> void:
	state = next
	_t = 0.0
	if next == "walk":
		_walk_for = rng.randf_range(1.2, 2.2) / (1.3 if phase == 3 else 1.0)


func _choose() -> void:
	var options: Array[String] = []
	match phase:
		1:
			options = ["jump", "jump", "throw"]
		2:
			options = ["jump", "throw", "throw", "summon"]
		_:
			options = ["charge", "charge", "jumps", "throw", "summon"]
	var pick := options[rng.randi() % options.size()]
	match pick:
		"jump":
			_go("windup")
		"jumps":
			_combo = 2
			_go("windup")
		"throw":
			_go("throw_windup")
		"charge":
			_go("charge_windup")
			Sfx.play("roar", -8.0, 0.1)
		"summon":
			_go("whistle")
			Sfx.play("whistle_up", -2.0, 0.0)


func _take_off() -> void:
	_from = global_position
	var t := target()
	Sfx.play("whistle_up", -4.0)
	var aim_at := t.global_position if t != null else room.center()
	# Lands where the brother was at take-off, but never in a wall.
	var inside := room.floor_rect().grow(-radius)
	_to = Vector2(clampf(aim_at.x, inside.position.x, inside.end.x),
			clampf(aim_at.y, inside.position.y, inside.end.y))
	_go("air")


func _land() -> void:
	_height = 0.0
	_squash = 3.0 / Toon.FPS
	stomped.emit()
	Sfx.play("stomp", 0.0)
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(global_position) < STOMP_REACH:
			brother.hurt(contact, global_position)
	Fx.ring(room, global_position, STOMP_REACH * 2.4, Toon.INK, 0.45, 12.0)
	Fx.burst(room, global_position, "dust", 12, 1.3)
	Fx.shake(0.3)
	# A ring of dust thrown out along the floor.
	var n := 10 if phase < 3 else 14
	for i in n:
		var direction := Vector2.from_angle(TAU * i / n + rng.randf() * 0.2)
		_shoot(direction, 360.0, 5.0, 13.0, 18.0)
	_go("land")


func _throw() -> void:
	var n := 3 if phase == 1 else 5
	for i in n:
		var spread := (i - (n - 1) * 0.5) * 0.22
		_shoot(_aim.rotated(spread), 470.0, 10.0, 16.0, 70.0)
	_throws += 1
	Sfx.play("spit", -4.0)


## Bruno whistles his boys in: bulldog pups come in through the ropes from
## both sides of the ring. Never more than three about at once.
func _summon() -> void:
	var boys := 0
	for enemy in room.enemies:
		if not enemy is Boss:
			boys += 1
	var floor_box := room.floor_rect()
	for i in maxi(0, (2 if phase < 3 else 3) - boys):
		var side := i % 2
		var x := floor_box.position.x + 50.0 if side == 0 else floor_box.end.x - 50.0
		var y := floor_box.position.y + floor_box.size.y * (0.3 + 0.4 * rng.randf())
		var pup := Waves.spawn("pup", room, rng, Vector2(x, y))
		Fx.burst(room, Vector2(x, y), "dust", 5, 0.8)
		if pup != null:
			pup.max_hp *= 1.0 + 0.3 * floor_index
			pup.hp = pup.max_hp


func _shoot(direction: Vector2, shot_speed: float, tiles: float, size: float, height: float,
		tint := Color(0, 0, 0, 0)) -> Shot:
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + direction * radius * 0.8, height, direction * shot_speed,
			tiles * Room.TILE, 1.0, size, true)
	shot.tint = tint
	return shot


# --- drawing --------------------------------------------------------------------


func _draw() -> void:
	if not _shown():
		return
	var boil := int(_clock * Toon.FPS)
	var pose := _pose(boil)
	var offset: Vector2 = pose[0]
	var turn: float = pose[1]
	var size: Vector2 = pose[2]
	var flash := _flash > 0.0
	if _ko >= 0.0:
		var k := _defeat_pose(boil)
		offset = k[0]
		turn = k[1]
		size = k[2]
		flash = _ko < SHAKE_TIME and boil % 2 == 0
	elif state in ["walk", "wait", "recover"]:
		# Breathing.
		var b := sin(_clock * 3.2) * 0.5 + 0.5
		size *= Vector2(1.0 - 0.012 * b, 1.0 + 0.022 * b)
	# The shadow stays on the floor and shrinks as he goes up.
	var high := clampf(-offset.y / JUMP_HEIGHT, 0.0, 1.0)
	var lying := clampf(absf(turn) / (PI * 0.5), 0.0, 1.0)
	var shadow := _shadow_size() * (1.0 - 0.45 * high)
	shadow.x *= 1.0 + lying * 1.4
	Toon.spot(self, Vector2(_fall_side * shadow.x * 0.45 * lying, 4), shadow, Color(Toon.INK, 0.3 + 0.1 * high))
	_under(boil)
	draw_set_transform(offset, turn, size)
	_figure(boil, flash)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_over(boil)


## False while he is not there to be drawn (the Baron, vanished).
func _shown() -> bool:
	return true


## The shadow's radii on the floor.
func _shadow_size() -> Vector2:
	return Vector2(72, 22)


## How the figure sits this drawing: [offset, turn, scale] about his feet.
func _pose(boil: int) -> Array:
	var squash := 0.0
	match state:
		"windup", "charge_windup":
			squash = 0.12
		"air":
			squash = -0.1
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
		"wait":
			# The entrance: bouncing on his toes.
			squash = [0.0, 0.05, 0.0, -0.05][boil % 4]
	if _squash > 0.0:
		squash = 0.15
	return [Vector2(0, -_height), 0.0, Vector2(1.0 + squash, 1.0 - squash)]


## The knockout pose: shaking where he stands, then toppling over sideways
## about his feet, a bounce, and flat out.
func _defeat_pose(boil: int) -> Array:
	if _ko < SHAKE_TIME:
		var jitter := Vector2(Toon.hash01(boil, 3) - 0.5, Toon.hash01(boil, 4) - 0.5) * 10.0
		var wobble := sin(_ko * 38.0) * 0.06
		return [jitter, wobble, Vector2(1.0 + 0.04 * sin(_ko * 50.0), 1.0 - 0.04 * sin(_ko * 50.0))]
	var k := clampf((_ko - SHAKE_TIME) / FALL_TIME, 0.0, 1.0)
	var fall := k * k
	var bounce := 0.0
	var after := _ko - SHAKE_TIME - FALL_TIME
	if after > 0.0 and after < 0.3:
		bounce = sin(after / 0.3 * PI) * 0.12
	return [Vector2.ZERO, _fall_side * (PI * 0.5 * fall - bounce), Vector2(1.0, 1.0 - 0.1 * fall)]


## Drawn on the floor under him: Bruno's landing target.
func _under(_boil: int) -> void:
	if state == "air":
		var at := _to - global_position
		var k := clampf(_t / AIR_TIME, 0.0, 1.0)
		var r := STOMP_REACH * (1.2 - 0.3 * k)
		draw_arc(at, r, 0.0, TAU, 40, Color(0.75, 0.15, 0.1, 0.35 + 0.4 * k), 5.0, true)
		draw_arc(at, r * 0.5, 0.0, TAU, 28, Color(0.75, 0.15, 0.1, 0.25 + 0.3 * k), 3.0, true)
		for i in 4:
			var d := Vector2.from_angle(PI * 0.5 * i + PI * 0.25)
			draw_line(at + d * r * 0.62, at + d * r * 0.95, Color(0.75, 0.15, 0.1, 0.4 + 0.4 * k), 4.0, true)


## Drawn over him: stars going round his head when he is down.
func _over(boil: int) -> void:
	if _ko < SHAKE_TIME + FALL_TIME * 0.8:
		return
	var head := Vector2(_fall_side * _height_of_head(), -40.0)
	for i in 4:
		var a := boil * 0.6 + TAU * i / 4.0
		Toon.star(self, head + Vector2(cos(a) * 50.0, sin(a) * 16.0 - 40.0), 11.0, a, Color("f2c14e"))
	# Little birds would be too much; a "Z" or two will do.
	if _ko > SHAKE_TIME + FALL_TIME + 0.6:
		var rise := fmod(_ko, 0.8) / 0.8
		draw_string(Ui.font(), head + Vector2(20, -80 - rise * 40.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1,
				int(28 + rise * 14), Color(Toon.WHITE, 1.0 - rise))


## How far from his feet his head is: where the stars go when he lies down.
func _height_of_head() -> float:
	return 160.0


## The figure itself, standing on (0, 0).
func _figure(boil: int, flash: bool) -> void:
	_draw_bruno(boil, flash)


func _draw_bruno(boil: int, flash: bool) -> void:
	var angry := phase == 3 and _ko < 0.0
	var skin := paint(SKIN.lerp(RAGE, 0.45) if angry else SKIN, flash)
	var light := paint(SKIN_LIGHT.lerp(RAGE, 0.3) if angry else SKIN_LIGHT, flash)
	var ink := Toon.INK
	var white := paint(BrotherLook.WHITE, flash)
	# Legs and shoes.
	var step := 0.0
	if state in ["walk", "charge"] and _ko < 0.0:
		step = [1.0, 0.0, -1.0, 0.0][boil % 4]
	if state == "charge_windup":
		step = [1.0, -1.0][boil % 2]
	for sx: float in [-1.0, 1.0]:
		var foot := Vector2(sx * 32.0, -(8.0 if step * sx > 0.0 else 0.0))
		Toon.hose(self, Vector2(sx * 22.0, -44.0), foot + Vector2(0, -8), sx * 5.0, 17.0)
		Toon.blob(self, foot + Vector2(sx * 4.0, -4.0), Vector2(27, 14), ink, boil, _seed + int(sx) + 2, 5.0)
		Toon.spot(self, foot + Vector2(sx * 4.0 - 8.0, -10.0), Vector2(8, 3.5), Color(1, 1, 1, 0.5))
	# The striped body.
	var body := Vector2(0, -84)
	var r := Vector2(58, 48)
	var outline := Toon.ellipse_points(body, r, boil, _seed + 1, 3.0, 0.0, 1.2, 2.0, 0.3)
	var fill := Toon.ellipse_points(body, r, boil, _seed + 1, -3.0, 0.0, 1.2, 2.0, 0.3)
	draw_colored_polygon(outline, ink)
	draw_colored_polygon(fill, white)
	for k in 5:
		var y0 := body.y - r.y + 10.0 + k * 20.0
		var band := Toon.clip_above(Toon.clip_below(fill, y0), y0 + 10.0)
		if band.size() >= 3:
			draw_colored_polygon(band, ink)
	Toon.polygon(self, Toon.crescent(body, r - Vector2(3, 3), boil, _seed + 1, 0.0, 0.0, 0.3), Color(0, 0, 0, 0.18))
	if phase >= 2:
		# A tear in the stripes, the shirt showing through.
		var tear := body + Vector2(-26, 12)
		Toon.shape(self, PackedVector2Array([tear + Vector2(-10, -8), tear + Vector2(4, -12), tear + Vector2(12, -2),
				tear + Vector2(2, 10), tear + Vector2(-8, 6)]), paint(Color("e8dcc4"), flash), 2.5)
		Toon.stroke(self, PackedVector2Array([tear + Vector2(-6, -2), tear + Vector2(6, 2)]), 1.6)
	# Arms: fists at rest, one wound back to throw, both up to jump, both
	# forward to charge, hanging when he sees stars, punching his palm while
	# the title card is up.
	var fists := [Vector2(-74, -64), Vector2(74, -64)]
	match state:
		"wait":
			fists = [Vector2(-20, -100), Vector2(18 + (8.0 if boil % 2 == 0 else -4.0), -104)]
		"whistle":
			# Two fingers in his mouth.
			fists[1] = Vector2(26, -126)
		"throw_windup":
			fists[1] = Vector2(60, -190)
		"windup", "air":
			fists = [Vector2(-70, -170), Vector2(70, -170)]
		"charge_windup", "charge":
			fists = [Vector2(-40, -70) + _aim * 40.0, Vector2(40, -70) + _aim * 40.0]
		"stunned":
			fists = [Vector2(-64, -30), Vector2(64, -30)]
	if _ko >= 0.0:
		fists = [Vector2(-80, -150), Vector2(80, -150)] if _ko < SHAKE_TIME else [Vector2(-64, -20), Vector2(64, -20)]
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := Vector2(sx * 46.0, -110.0)
		var fist: Vector2 = fists[i]
		Toon.hose(self, shoulder, fist + (shoulder - fist).normalized() * 16.0, sx * -10.0, 14.0)
		Toon.ball(self, fist, Vector2(21, 19), white, boil, _seed + 10 + i, 4.5, 0.0, 0.14)
		for k in 3:
			var x := fist.x + (k - 1) * 6.0
			Toon.stroke(self, PackedVector2Array([Vector2(x, fist.y - 8.0), Vector2(x, fist.y - 1.0)]), 2.2)
	if state == "wait" and boil % 2 == 0:
		# Smack: the fist meets the palm.
		Toon.star(self, Vector2(0, -122), 10.0, 0.3, Color("fff1a8"))
	# Head.
	var head := Vector2(0, -158)
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, head + Vector2(sx * 52.0, -14.0), Vector2(15, 26), skin.darkened(0.35), boil,
				_seed + 20 + int(sx), 4.5, sx * 0.5)
	Toon.ball(self, head, Vector2(56, 46), skin, boil, _seed + 22)
	# Stubble and a scar over the brow.
	for j in 5:
		Toon.spot(self, head + Vector2(-20 + j * 10, 30 + (j % 2) * 4), Vector2(1.6, 1.6), Color(0, 0, 0, 0.4))
	Toon.stroke(self, PackedVector2Array([head + Vector2(26, -34), head + Vector2(36, -18)]), 2.5, skin.darkened(0.4))
	for j in 3:
		var y := -30.0 + j * 7.0
		Toon.stroke(self, PackedVector2Array([head + Vector2(28, y), head + Vector2(35, y - 2)]), 2.0, skin.darkened(0.4))
	for sx: float in [-1.0, 1.0]:
		Toon.ball(self, head + Vector2(sx * 32.0, 20.0), Vector2(30, 22), light, boil, _seed + 24 + int(sx), 4.5, 0.0, 0.12)
	# The underbite: a dark jaw with two fangs sticking up -- one of them
	# knocked out by phase 3.
	Toon.blob(self, head + Vector2(0, 34.0), Vector2(36, 13), Color("2a1712"), boil, _seed + 26, 4.0)
	for sx: float in [-1.0, 1.0]:
		if phase >= 3 and sx > 0.0:
			continue
		var base := head + Vector2(sx * 20.0, 28.0)
		Toon.shape(self, PackedVector2Array([base + Vector2(-6, 4), base + Vector2(6, 4), base + Vector2(sx * 2.0, -14)]),
				white, 3.0)
	Toon.blob(self, head + Vector2(0, 8.0), Vector2(26, 16), light, boil, _seed + 28, 4.0)
	var nose := head + Vector2(0, 0)
	Toon.blob(self, nose, Vector2(17, 12), ink, boil, _seed + 29, 3.0)
	Toon.spot(self, nose + Vector2(-5, -5), Vector2(5, 3), Color(1, 1, 1, 0.8))
	# Small mean eyes under a heavy brow; a black eye from phase 2.
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var e := head + Vector2(sx * 20.0, -20.0)
		if phase >= 2 and sx < 0.0:
			Toon.spot(self, e + Vector2(0, 2), Vector2(15, 16), Color(0.3, 0.15, 0.3, 0.55), boil, _seed + 50)
		if state == "stunned":
			Toon.stroke(self, PackedVector2Array([e + Vector2(-6, -6), e + Vector2(6, 6)]), 3.5)
			Toon.stroke(self, PackedVector2Array([e + Vector2(-6, 6), e + Vector2(6, -6)]), 3.5)
		else:
			eye(e, Vector2(9, 11), look, boil, _seed + 30 + int(sx), 3.0, 0.8)
		if _ko < 0.0:
			brow(e + Vector2(0, -14), 26.0 if angry else 22.0, sx < 0.0, 7.0)
	if phase >= 2:
		# Sticking plaster, crossed.
		var at := head + Vector2(-30, -30)
		for turn: float in [0.6, -0.6]:
			Toon.box(self, at, Vector2(15, 5), paint(PLASTER, flash), boil, _seed + 52, 2.5, turn)
	# The bowler hat -- dented from phase 3, and knocked off when he is out.
	var hat := head + Vector2(0, -40)
	var tilt := 0.0
	if phase >= 3:
		tilt = -0.18
	if _ko >= SHAKE_TIME:
		# Knocked off, lying beyond his head.
		hat = head + Vector2(-30, -95)
		tilt = -0.9
	Toon.blob(self, hat, Vector2(52, 9), ink, boil, _seed + 34, 3.0, tilt)
	Toon.blob(self, hat + Vector2(0, -16).rotated(tilt), Vector2(34, 22), ink, boil, _seed + 35, 3.0, tilt)
	Toon.stroke(self, Toon.bent(hat + Vector2(-30, -6).rotated(tilt), hat + Vector2(30, -6).rotated(tilt), 3.0), 5.0,
			Color("7a6a60"))
	Toon.stroke(self, Toon.bent(hat + Vector2(-18, -30).rotated(tilt), hat + Vector2(-4, -34).rotated(tilt), 2.0), 3.0,
			Color(1, 1, 1, 0.5))
	if phase >= 3:
		Toon.stroke(self, PackedVector2Array([hat + Vector2(8, -34).rotated(tilt), hat + Vector2(16, -24).rotated(tilt),
				hat + Vector2(10, -16).rotated(tilt)]), 2.5, Color("7a6a60"))
	if angry and boil % 2 == 0:
		# Steam out of his ears.
		for sx: float in [-1.0, 1.0]:
			Toon.blob(self, head + Vector2(sx * 70.0, -40.0 - (boil % 4) * 6.0), Vector2(10, 9),
					BrotherLook.WHITE, boil, _seed + 40 + int(sx), 3.0)
	if state == "stunned":
		for i in 3:
			var a := boil * 0.7 + TAU * i / 3.0
			Toon.star(self, head + Vector2(cos(a) * 60.0, -64.0 + sin(a) * 14.0), 11.0, a, Color("f2c14e"))
