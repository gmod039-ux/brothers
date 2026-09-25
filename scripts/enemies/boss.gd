class_name Boss
extends Enemy
## Громила Бруно, boss of the basement: a bulldog thug in a bowler hat and a
## convict's stripes. Three phases by health, each with its own tricks, and
## every attack announced by a wind-up the way a cartoon's anticipation
## always tells you what is coming:
##   1  walks at you; jumps and lands with a shockwave; now and then throws
##   2  throws more, and calls flies in
##   3  red with rage: charges across the room until he hits a wall and sees
##      stars (that is the time to hit him), and jumps
## He is in the room's enemies like any other, so shots and touching work
## the same; he is simply never knocked back.

signal stomped
signal phase_changed(phase: int)

const SKIN := Color("b98a5e")
const SKIN_LIGHT := Color("dcb489")
const RAGE := Color("d0553c")
const AIR_TIME := 0.85
const JUMP_HEIGHT := 280.0
const STOMP_REACH := 135.0
const CHARGE_SPEED := 760.0

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
		_go("roar")
		return
	velocity = Vector2.ZERO
	match state:
		"walk":
			if t != null:
				velocity = _aim * speed * (1.5 if phase == 3 else 1.0)
			if _t > _walk_for:
				_choose()
		"windup":
			if _t > 0.5:
				_take_off()
		"air":
			var k := minf(_t / AIR_TIME, 1.0)
			global_position = _from.lerp(_to, k)
			_height = sin(k * PI) * JUMP_HEIGHT
			if k >= 1.0:
				_land()
		"land":
			if _t > 0.55:
				_go("walk")
		"throw_windup":
			if _t > 0.45:
				_throw()
				_go("recover")
		"recover":
			if _t > 0.55:
				_go("walk")
		"charge_windup":
			if _t > 0.7:
				_charge = _aim
				_go("charge")
		"charge":
			velocity = _charge * CHARGE_SPEED
		"stunned":
			if _t > 1.2:
				_go("walk")
		"roar":
			if _t > 0.8:
				if phase == 2:
					_summon()
				_go("walk")
	if state != "air":
		move_and_slide()
	if state == "charge" and (get_slide_collision_count() > 0 or _t > 1.8):
		_squash = 3.0 / Toon.FPS
		stomped.emit()
		Sfx.play("stomp", 0.0)
		Sfx.play("stars", -6.0)
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
			options = ["charge", "charge", "jump", "throw"]
	var pick := options[rng.randi() % options.size()]
	match pick:
		"jump":
			_go("windup")
		"throw":
			_go("throw_windup")
		"charge":
			_go("charge_windup")
		"summon":
			_summon()
			_go("recover")


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


func _summon() -> void:
	var flies := 0
	for enemy in room.enemies:
		if enemy != self:
			flies += 1
	for i in maxi(0, 2 - flies):
		var side := -1.0 if i == 0 else 1.0
		Waves.spawn("fly", room, rng, global_position + Vector2(side * 110.0, -40.0))


func _shoot(direction: Vector2, shot_speed: float, tiles: float, size: float, height: float,
		tint := Color(0, 0, 0, 0)) -> Shot:
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + direction * radius * 0.8, height, direction * shot_speed,
			tiles * Room.TILE, 1.0, size, true)
	shot.tint = tint
	return shot


func _draw() -> void:
	var boil := int(_clock * Toon.FPS)
	var high := clampf(_height / JUMP_HEIGHT, 0.0, 1.0)
	# The shadow stays on the floor and shrinks as he goes up; in the air it
	# is where he will come down.
	var shadow := Vector2(72, 22) * (1.0 - 0.45 * high)
	Toon.spot(self, Vector2(0, 4), shadow, Color(Toon.INK, 0.3 + 0.1 * high))
	var squash := 0.0
	match state:
		"windup", "charge_windup":
			squash = 0.12
		"air":
			squash = -0.1
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
	if _squash > 0.0:
		squash = 0.15
	draw_set_transform(Vector2(0, -_height), 0.0, Vector2(1.0 + squash, 1.0 - squash))
	_draw_bruno(boil, _flash > 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bruno(boil: int, flash: bool) -> void:
	var angry := phase == 3
	var skin := paint(SKIN.lerp(RAGE, 0.45) if angry else SKIN, flash)
	var light := paint(SKIN_LIGHT.lerp(RAGE, 0.3) if angry else SKIN_LIGHT, flash)
	var ink := Toon.INK
	var white := paint(BrotherLook.WHITE, flash)
	# Legs and shoes.
	var step := 0.0
	if state in ["walk", "charge"]:
		step = [1.0, 0.0, -1.0, 0.0][boil % 4]
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
	# Arms: fists at rest, one wound back to throw, both up to jump, both
	# forward to charge, hanging when he sees stars.
	var fists := [Vector2(-74, -64), Vector2(74, -64)]
	match state:
		"throw_windup":
			fists[1] = Vector2(60, -190)
		"windup", "air":
			fists = [Vector2(-70, -170), Vector2(70, -170)]
		"charge_windup", "charge":
			fists = [Vector2(-40, -70) + _aim * 40.0, Vector2(40, -70) + _aim * 40.0]
		"stunned":
			fists = [Vector2(-64, -30), Vector2(64, -30)]
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := Vector2(sx * 46.0, -110.0)
		var fist: Vector2 = fists[i]
		Toon.hose(self, shoulder, fist + (shoulder - fist).normalized() * 16.0, sx * -10.0, 14.0)
		Toon.blob(self, fist, Vector2(21, 19), white, boil, _seed + 10 + i, 4.5)
		for k in 3:
			var x := fist.x + (k - 1) * 6.0
			Toon.stroke(self, PackedVector2Array([Vector2(x, fist.y - 8.0), Vector2(x, fist.y - 1.0)]), 2.2)
	# Head.
	var head := Vector2(0, -158)
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, head + Vector2(sx * 52.0, -14.0), Vector2(15, 26), skin.darkened(0.35), boil,
				_seed + 20 + int(sx), 4.5, sx * 0.5)
	Toon.blob(self, head, Vector2(56, 46), skin, boil, _seed + 22)
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, head + Vector2(sx * 32.0, 20.0), Vector2(30, 22), light, boil, _seed + 24 + int(sx), 4.5)
	# The underbite: a dark jaw with two fangs sticking up.
	Toon.blob(self, head + Vector2(0, 34.0), Vector2(36, 13), Color("2a1712"), boil, _seed + 26, 4.0)
	for sx: float in [-1.0, 1.0]:
		var base := head + Vector2(sx * 20.0, 28.0)
		Toon.shape(self, PackedVector2Array([base + Vector2(-6, 4), base + Vector2(6, 4), base + Vector2(sx * 2.0, -14)]),
				white, 3.0)
	Toon.blob(self, head + Vector2(0, 8.0), Vector2(26, 16), light, boil, _seed + 28, 4.0)
	var nose := head + Vector2(0, 0)
	Toon.blob(self, nose, Vector2(17, 12), ink, boil, _seed + 29, 3.0)
	Toon.spot(self, nose + Vector2(-5, -5), Vector2(5, 3), Color(1, 1, 1, 0.8))
	# Small mean eyes under a heavy brow.
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var eye := head + Vector2(sx * 20.0, -20.0)
		if state == "stunned":
			Toon.stroke(self, PackedVector2Array([eye + Vector2(-6, -6), eye + Vector2(6, 6)]), 3.5)
			Toon.stroke(self, PackedVector2Array([eye + Vector2(-6, 6), eye + Vector2(6, -6)]), 3.5)
		else:
			Toon.pie_eye(self, eye, Vector2(9, 11), look, boil, _seed + 30 + int(sx), 3.0, 0.8)
		brow(eye + Vector2(0, -14), 26.0 if angry else 22.0, sx < 0.0, 7.0)
	# The bowler hat.
	Toon.blob(self, head + Vector2(0, -40), Vector2(52, 9), ink, boil, _seed + 34, 3.0)
	Toon.blob(self, head + Vector2(0, -56), Vector2(34, 22), ink, boil, _seed + 35, 3.0)
	Toon.stroke(self, Toon.bent(head + Vector2(-30, -46), head + Vector2(30, -46), 3.0), 5.0, Color("7a6a60"))
	Toon.stroke(self, Toon.bent(head + Vector2(-18, -70), head + Vector2(-4, -74), 2.0), 3.0, Color(1, 1, 1, 0.5))
	if angry and boil % 2 == 0:
		# Steam out of his ears.
		for sx: float in [-1.0, 1.0]:
			Toon.blob(self, head + Vector2(sx * 70.0, -40.0 - (boil % 4) * 6.0), Vector2(10, 9),
					BrotherLook.WHITE, boil, _seed + 40 + int(sx), 3.0)
	if state == "stunned":
		for i in 3:
			var a := boil * 0.7 + TAU * i / 3.0
			Toon.star(self, head + Vector2(cos(a) * 60.0, -64.0 + sin(a) * 14.0), 11.0, a, Color("f2c14e"))
