class_name PupEnemy
extends Enemy
## Щенок-хулиган, one of Bruno's boys: a bulldog pup in a striped vest.
## Trots at you, stops to take aim -- a wiggle and a bead of sweat, that is
## the warning -- then comes at you in a straight dash and skids to a stop.

const SKIN := Color("c9975f")

## "trot", "aim", "dash" or "skid".
var state := "trot"
var _t := 0.0
var _trot_for := 1.4
var _dash := Vector2.ZERO


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	if t == null:
		return Vector2.ZERO
	var to := t.global_position - global_position
	match state:
		"trot":
			if _t > _trot_for and to.length() < 520.0:
				_switch("aim")
				Fx.burst(room, global_position + Vector2(10, -50), "sweat", 2, 0.4)
			return to.normalized() * speed
		"aim":
			_dash = to.normalized()
			if _t > 0.45:
				_switch("dash")
				Sfx.play("whistle_up", -12.0, 0.2)
			return Vector2.ZERO
		"dash":
			if _t > 0.55 or is_on_wall():
				_switch("skid")
				Fx.burst(room, global_position, "dust", 4, 0.6)
			elif int(_t * 20.0) % 3 == 0:
				Fx.burst(room, global_position, "dust", 1, 0.2)
			return _dash * float(def.get("dash_speed", 640.0))
		_:
			if _t > 0.6:
				_switch("trot")
				_trot_for = rng.randf_range(0.9, 1.8)
			return Vector2.ZERO


func _switch(next: String) -> void:
	state = next
	_t = 0.0


func draw_body(boil: int, flash: bool) -> void:
	var moving := state in ["trot", "dash"]
	var bob := -3.0 if moving and boil % 2 == 0 else 0.0
	var wiggle := (3.0 if boil % 2 == 0 else -3.0) if state == "aim" else 0.0
	var lean := 0.25 if state == "dash" else 0.0
	var skin := paint(SKIN, flash)
	for sx: float in [-1.0, 1.0]:
		var lift := -5.0 if moving and (boil % 2 == 0) == (sx < 0.0) else 0.0
		Toon.blob(self, Vector2(sx * 10.0, -4.0 + lift), Vector2(8, 5), paint(Toon.INK, flash), boil, _seed + int(sx), 3.0)
	# A striped vest.
	var body := Vector2(wiggle, -20 + bob)
	var fill := Toon.ellipse_points(body, Vector2(15, 12), boil, _seed + 2, -2.0)
	draw_colored_polygon(Toon.ellipse_points(body, Vector2(15, 12), boil, _seed + 2, 2.0), Toon.INK)
	draw_colored_polygon(fill, paint(BrotherLook.WHITE, flash))
	for k in 2:
		var band := Toon.clip_above(Toon.clip_below(fill, body.y - 8.0 + k * 8.0), body.y - 4.0 + k * 8.0)
		if band.size() >= 3:
			draw_colored_polygon(band, Toon.INK)
	var head := Vector2(wiggle * 1.5 + lean * 20.0, -44 + bob)
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, head + Vector2(sx * 17.0, -2.0), Vector2(7, 11), skin.darkened(0.35), boil, _seed + 3 + int(sx), 3.0, sx * 0.4)
	Toon.ball(self, head, Vector2(19, 16), skin, boil, _seed + 5)
	Toon.blob(self, head + Vector2(0, 7), Vector2(11, 7), paint(Color("e6c89a"), flash), boil, _seed + 6, 3.0)
	Toon.blob(self, head + Vector2(0, 2), Vector2(6, 4.5), Toon.INK, boil, _seed + 7, 2.0)
	# A little fang sticking up out of the underbite.
	Toon.shape(self, PackedVector2Array([head + Vector2(3, 12), head + Vector2(8, 12), head + Vector2(5, 6)]),
			BrotherLook.WHITE, 2.0)
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		Toon.pie_eye(self, head + Vector2(sx * 7.0, -6.0), Vector2(5, 6.5), look, boil, _seed + 8 + int(sx), 2.5)
		brow(head + Vector2(sx * 7.0, -14.0), 10.0, sx < 0.0, 3.0)
