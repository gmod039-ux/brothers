class_name ValveEnemy
extends Enemy
## Вентиль: a steam valve come alive on its stub of pipe -- a brass body
## with a sulky face and a red handwheel on top. It cannot move a step, but
## every few seconds its wheel spins, it rattles and whistles (the
## warning), and it blows four jets of steam: in a cross one time, in an X
## the next.

const BRASS := Color("c9a03a")
const PIPE := Color("6d6a70")
const WHEEL := Color("c8392b")

var _reload := 2.0
var _windup := 0.0
var _diagonal := false
var _spin := 0.0
var blows := 0


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_reload = rng.randf_range(1.2, float(def.get("shot_every", 2.8)))
	_diagonal = rng.randf() < 0.5


func think(delta: float) -> Vector2:
	_spin += delta * (14.0 if _windup > 0.0 else 0.8)
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_blow()
			_reload = float(def.get("shot_every", 2.8)) - floor_look * 0.2
		return Vector2.ZERO
	_reload -= delta
	if _reload <= 0.0 and target() != null:
		_windup = float(def.get("windup", 0.55))
		Sfx.play("fuse", -12.0, 0.2)
	return Vector2.ZERO


## Bolted to the floor: nothing shoulders it aside.
func _separation() -> Vector2:
	return Vector2.ZERO


func _blow() -> void:
	for k in 4:
		var dir := Vector2.RIGHT.rotated(PI * 0.5 * k + (PI * 0.25 if _diagonal else 0.0))
		var shot := Shot.new()
		room.actors.add_child(shot)
		shot.launch(room, global_position + dir * radius, 34.0, dir * float(def.get("shot_speed", 330.0)),
				float(def.get("shot_range", 5.0)) * Room.TILE, 1.0, 15.0, true)
		shot.source = display_name
		shot.look = "steam"
		shot.tint = Color("e9eeee")
	_diagonal = not _diagonal
	blows += 1
	Sfx.play("spit", -6.0, 0.15)
	Fx.burst(room, global_position + Vector2(0, -70), "steam", 6, 0.8)
	_squash = 2.0 / Toon.FPS


func draw_body(boil: int, flash: bool) -> void:
	var rattle := Vector2.ZERO
	if _windup > 0.0:
		rattle = Vector2(Toon.hash01(boil, _seed) - 0.5, Toon.hash01(_seed, boil) - 0.5) * 6.0
	var pipe := paint(PIPE, flash).darkened(0.15 * floor_look)
	# The stub of pipe out of the floor, a flange of bolts round its foot.
	Toon.ball(self, Vector2(0, -4), Vector2(26, 9), pipe.darkened(0.2), boil, _seed, 3.5)
	for k in 6:
		var a := TAU * k / 6.0
		Toon.spot(self, Vector2(cos(a) * 19.0, -4.0 + sin(a) * 6.0), Vector2(3, 2), Toon.INK)
	Toon.box(self, Vector2(0, -20), Vector2(13, 16), pipe, boil, _seed + 1, 3.5)
	Toon.shine(self, Vector2(0, -20), Vector2(13, 16), 0.3)
	# The brass body, and its face.
	var body := Vector2(0, -46) + rattle
	Toon.ball(self, body, Vector2(25, 20), paint(BRASS, flash), boil, _seed + 2)
	soot(body, Vector2(25, 20), boil)
	var look := gaze()
	var cheeks := 1.0 + (0.25 if _windup > 0.0 else 0.0)
	for sx: float in [-1.0, 1.0]:
		var e := body + Vector2(sx * 9.0, -3.0)
		eye(e, Vector2(5.0, 6.0), look, boil, _seed + 3 + int(sx), 2.5)
		if not eyes_shut():
			brow(e + Vector2(0, -7.0), 10.0, sx < 0.0, 3.0)
		Toon.spot(self, body + Vector2(sx * 16.0, 7.0), Vector2(5, 3) * cheeks, Color("e27c8c", 0.5), boil, _seed + 5)
	if _windup > 0.0:
		# Lips pursed for the whistle.
		Toon.ball(self, body + Vector2(0, 10), Vector2(4, 4), Toon.INK, boil, _seed + 6, 0.0)
	else:
		Toon.stroke(self, Toon.bent(body + Vector2(-7, 11), body + Vector2(7, 11), -2.0), 3.0)
	# The stem, and the handwheel on it seen from a little above, turning.
	var hub := body + Vector2(0, -30)
	Toon.stroke(self, PackedVector2Array([body + Vector2(0, -18), hub]), 8.0)
	Toon.stroke(self, PackedVector2Array([body + Vector2(0, -18), hub]), 4.0, paint(BRASS, flash).darkened(0.2))
	var wheel := paint(WHEEL, flash)
	var rim := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		rim.append(hub + Vector2(cos(a) * 27.0, sin(a) * 12.0))
	for k in 3:
		var a := _spin + TAU * k / 3.0
		var spoke := Vector2(cos(a) * 25.0, sin(a) * 11.0)
		Toon.stroke(self, PackedVector2Array([hub - spoke, hub + spoke]), 5.5)
		Toon.stroke(self, PackedVector2Array([hub - spoke, hub + spoke]), 2.5, wheel)
	Toon.stroke(self, rim, 8.0)
	Toon.stroke(self, rim, 3.5, wheel)
	Toon.blob(self, hub, Vector2(6, 4), paint(BRASS, flash), boil, _seed + 7, 2.5)
	if _windup > 0.0 and boil % 2 == 0:
		Toon.spot(self, hub + Vector2(0, -16), Vector2(10, 7), Color(1, 1, 1, 0.6), boil, _seed + 8)
