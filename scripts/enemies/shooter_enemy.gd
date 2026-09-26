class_name ShooterEnemy
extends Enemy
## Плевун: a toad of a thing that keeps its distance and spits at you.
## Before every spit its cheeks puff up for half a second -- the wind-up is
## the warning, as a cartoon's anticipation always is.
##
## Floors: in the basement one gob at a time; in the boiler room it has
## eaten coal -- sooty, a battered stovepipe hat, and it spits three
## burning gobs in a fan; in the catacombs it is pale, a candle stuck on its
## head, and spits three green gobs one after another.

const BODY := Color("9a6ab0")
const BELLY := Color("d9b8e0")
const LIPS := Color("e27c8c")
const FIRE := Color("e8702a")
const GOO := Color("6fae4a")

var _reload := 0.0
var _windup := 0.0
var _aim := Vector2.DOWN
## Gobs still to come in a burst (the catacombs' kind), and the wait
## before the next.
var _burst := 0
var _burst_in := 0.0
var spits := 0


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_reload = rng.randf_range(0.8, float(def.get("shot_every", 2.4)))


func think(delta: float) -> Vector2:
	var t := target()
	if t != null:
		_aim = (t.global_position - global_position).normalized()
	if _burst > 0:
		_burst_in -= delta
		if _burst_in <= 0.0:
			_spit(_aim)
			_burst -= 1
			_burst_in = 0.16
		return Vector2.ZERO
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_attack()
			_reload = float(def.get("shot_every", 2.4))
		return Vector2.ZERO
	_reload -= delta
	if _reload <= 0.0 and t != null:
		_windup = float(def.get("windup", 0.5))
		return Vector2.ZERO
	if t != null and global_position.distance_to(t.global_position) < 330.0:
		return -_aim * speed
	return Vector2.ZERO


func _attack() -> void:
	match floor_look:
		1:
			for turn: float in [-0.26, 0.0, 0.26]:
				_spit(_aim.rotated(turn))
		2:
			_spit(_aim)
			_burst = 2
			_burst_in = 0.16
		_:
			_spit(_aim)


func _spit(dir: Vector2) -> void:
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + dir * radius, 38.0,
			dir * float(def.get("shot_speed", 420.0)),
			float(def.get("shot_range", 9.0)) * Room.TILE, 1.0, 12.0, true)
	match floor_look:
		1:
			shot.tint = FIRE
		2:
			shot.tint = GOO
	spits += 1
	Sfx.play("spit", -8.0)
	_squash = 2.0 / Toon.FPS


func draw_body(boil: int, flash: bool) -> void:
	var puff := 0.0
	if _windup > 0.0:
		var total := float(def.get("windup", 0.5))
		# Puffs up in three steps.
		puff = ceilf((1.0 - _windup / total) * 3.0) / 3.0
	var body := skin(BODY, flash)
	# Webbed feet, three toes each.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var foot := Vector2(sx * 15.0, -4.0)
		Toon.blob(self, foot, Vector2(11.0, 6.0), body.darkened(0.25), boil, _seed + i, 3.5)
		for k in 3:
			Toon.blob(self, foot + Vector2(sx * 3.0 + (k - 1) * 7.0, 4.0), Vector2(3.2, 2.6), body.darkened(0.25), boil,
					_seed + 50 + k, 2.0)
	var at := Vector2(0, -38.0)
	var size := Vector2(30.0, 30.0) * (1.0 + puff * 0.08)
	Toon.ball(self, at, size, body, boil, _seed + 2)
	soot(at, size, boil)
	# A pale belly, spots on its hide.
	Toon.spot(self, at + Vector2(0, 12.0), Vector2(18.0, 12.0) * (1.0 + puff * 0.08), skin(BELLY, flash).lerp(body, 0.3),
			boil, _seed + 3)
	for w: Vector2 in [Vector2(-19, -2), Vector2(20, -8), Vector2(14, 12), Vector2(-8, -20)]:
		Toon.spot(self, at + w, Vector2(4.5, 3.5), body.darkened(0.2), boil, _seed + 11)
	# Cheeks: little pouches that blow up into balloons on the wind-up.
	for sx: float in [-1.0, 1.0]:
		var r := Vector2(7.0, 6.0) * (1.0 + puff * 1.1)
		Toon.ball(self, at + Vector2(sx * (18.0 + puff * 6.0), 8.0), r, body.lightened(0.08), boil, _seed + 14 + int(sx), 3.0)
		Toon.spot(self, at + Vector2(sx * (18.0 + puff * 6.0), 9.0), r * 0.5, Color("e27c8c", 0.45), boil, _seed + 16)
	# A tuft on top.
	for k in 3:
		var root := at + Vector2((k - 1) * 5.0, -28.0)
		Toon.stroke(self, Toon.bent(root, root + Vector2((k - 1) * 6.0, -10.0 - (k % 2) * 4.0), 4.0), 2.6)
	var look := gaze()
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var e := at + Vector2(sx * 11.0, -10.0)
		eye(e, Vector2(8.5, 11.0), look, boil, _seed + 4 + i, 3.0)
		if not eyes_shut():
			brow(e + Vector2(0, -15.0), 13.0, sx < 0.0, 3.5)
	# Lips pointed the way it will spit; puckered while winding up; a
	# string of drool the rest of the time.
	var mouth := at + Vector2(_aim.x * 10.0, 12.0 + _aim.y * 5.0)
	var lips := Vector2(12.0, 9.0) if _windup <= 0.0 else Vector2(7.0, 7.0)
	Toon.blob(self, mouth, lips, paint(LIPS, flash), boil, _seed + 7, 3.5)
	Toon.blob(self, mouth, lips * 0.42, Toon.INK, boil, _seed + 8, 0.0)
	if _windup <= 0.0 and _burst == 0:
		var drip := mouth + Vector2(lips.x * 0.4, lips.y * 0.6)
		var length := 6.0 + (boil % 6) * 1.5
		Toon.stroke(self, PackedVector2Array([drip, drip + Vector2(0, length)]), 2.0, Color(0.85, 0.95, 1.0, 0.8))
		Toon.spot(self, drip + Vector2(0, length), Vector2(2.4, 2.8), Color(0.85, 0.95, 1.0, 0.8))
	match floor_look:
		1:
			_stovepipe(at, boil, flash)
		2:
			_candle(at, boil, flash)


## A battered stovepipe hat, dented, a patch on it.
func _stovepipe(at: Vector2, boil: int, flash: bool) -> void:
	var crown := at + Vector2(4.0, -40.0)
	Toon.box(self, crown + Vector2(0, 16.0), Vector2(20.0, 4.0), paint(Color("2a2628"), flash), boil, _seed + 60, 3.5, 0.12)
	Toon.box(self, crown, Vector2(12.0, 14.0), paint(Color("2a2628"), flash), boil, _seed + 61, 3.5, 0.12)
	Toon.stroke(self, PackedVector2Array([crown + Vector2(-10, 7), crown + Vector2(10, 9)]), 3.0, Color("6a5a50"))
	Toon.box(self, crown + Vector2(4, -4), Vector2(4, 4), paint(Color("6a4a3a"), flash), boil, _seed + 62, 2.0)


## A stub of candle stuck on its head, wax running, flame flickering.
func _candle(at: Vector2, boil: int, flash: bool) -> void:
	var base := at + Vector2(6.0, -28.0)
	Toon.blob(self, base + Vector2(0, 2), Vector2(9.0, 3.5), paint(Color("f3ecd8"), flash), boil, _seed + 70, 2.5)
	Toon.box(self, base + Vector2(0, -9), Vector2(5.0, 10.0), paint(Color("f3ecd8"), flash), boil, _seed + 71, 2.5)
	Toon.stroke(self, PackedVector2Array([base + Vector2(4, -14), base + Vector2(5, -6)]), 3.0, Color("f3ecd8"))
	var tip := base + Vector2(0, -20)
	var lean: float = [1.0, -1.5, 2.0, -0.5][boil % 4]
	Toon.glow(self, tip + Vector2(0, -6), Vector2(26, 26), Color(1, 0.85, 0.4, 0.4), 2)
	Toon.shape(self, PackedVector2Array([tip + Vector2(-4, 0), tip + Vector2(lean, -14), tip + Vector2(4, 0),
			tip + Vector2(0, 3)]), StoveBoss.FIRE, 2.5)
	Toon.spot(self, tip + Vector2(0, -3), Vector2(1.6, 3.0), StoveBoss.FIRE_CORE)
