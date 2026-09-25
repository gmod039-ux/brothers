class_name ShooterEnemy
extends Enemy
## Плевун: keeps its distance and spits at you. Before every spit it puffs up
## for half a second -- the wind-up is the warning, as a cartoon's
## anticipation always is.

const BODY := Color("9a6ab0")
const LIPS := Color("e27c8c")

var _reload := 0.0
var _windup := 0.0
var _aim := Vector2.DOWN
var spits := 0


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_reload = rng.randf_range(0.8, float(def.get("shot_every", 2.4)))


func think(delta: float) -> Vector2:
	var t := target()
	if t != null:
		_aim = (t.global_position - global_position).normalized()
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_spit()
			_reload = float(def.get("shot_every", 2.4))
		return Vector2.ZERO
	_reload -= delta
	if _reload <= 0.0 and t != null:
		_windup = float(def.get("windup", 0.5))
		return Vector2.ZERO
	if t != null and global_position.distance_to(t.global_position) < 330.0:
		return -_aim * speed
	return Vector2.ZERO


func _spit() -> void:
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + _aim * radius, 38.0,
			_aim * float(def.get("shot_speed", 420.0)),
			float(def.get("shot_range", 9.0)) * Room.TILE, 1.0, 12.0, true)
	spits += 1
	Sfx.play("spit", -8.0)
	_squash = 2.0 / Toon.FPS


func draw_body(boil: int, flash: bool) -> void:
	var puff := 1.0
	if _windup > 0.0:
		var total := float(def.get("windup", 0.5))
		# Puffs up in three steps.
		puff = 1.0 + 0.07 * ceilf((1.0 - _windup / total) * 3.0)
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		Toon.blob(self, Vector2(sx * 13.0, -4.0), Vector2(10.0, 7.0), paint(Color("5a3a2a"), flash), boil, _seed + i, 4.0)
	var at := Vector2(0, -38.0)
	Toon.blob(self, at, Vector2(30.0, 31.0) * puff, paint(BODY, flash), boil, _seed + 2)
	var look := gaze()
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var eye := at + Vector2(sx * 11.0, -12.0 * puff)
		Toon.pie_eye(self, eye, Vector2(8.5, 11.0), look, boil, _seed + 4 + i, 3.0)
		brow(eye + Vector2(0, -15.0), 13.0, sx < 0.0, 3.5)
	# Lips pointed the way it will spit; puckered while winding up.
	var mouth := at + Vector2(_aim.x * 12.0, 12.0 + _aim.y * 6.0)
	var lips := Vector2(12.0, 9.0) if _windup <= 0.0 else Vector2(8.0, 8.0)
	Toon.blob(self, mouth, lips, paint(LIPS, flash), boil, _seed + 7, 3.5)
	Toon.blob(self, mouth, lips * 0.42, Toon.INK, boil, _seed + 8, 0.0)
