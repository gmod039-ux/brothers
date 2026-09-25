class_name KittenEnemy
extends Enemy
## Котёнок, out of the Baron's hat: a ginger kitten in a tiny top hat.
## Creeps up, crouches and wiggles its bottom the way every cat does before
## it jumps -- that is the time to shoot it or step aside -- then pounces
## where you were.

## "creep", "crouch", "pounce" or "land".
var state := "creep"
var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _height := 0.0


func can_touch() -> bool:
	return super.can_touch() and state != "pounce"


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	if t == null:
		return Vector2.ZERO
	var to := t.global_position - global_position
	match state:
		"creep":
			if to.length() < 300.0 and _t > 0.8:
				_switch("crouch")
			return to.normalized() * speed * (0.7 if to.length() < 400.0 else 1.0)
		"crouch":
			_to = t.global_position
			if _t > 0.6:
				_from = global_position
				_switch("pounce")
				Sfx.play("whistle_up", -14.0, 0.2)
			return Vector2.ZERO
		"pounce":
			var k := minf(_t / 0.45, 1.0)
			_height = sin(k * PI) * 70.0
			var want := _from.lerp(_to, k)
			if k >= 1.0:
				_height = 0.0
				_switch("land")
				Fx.burst(room, global_position, "dust", 3, 0.5)
			return (want - global_position) / maxf(delta, 0.001)
		_:
			if _t > 0.5:
				_switch("creep")
			return Vector2.ZERO


func _switch(next: String) -> void:
	state = next
	_t = 0.0


func draw_body(boil: int, flash: bool) -> void:
	var fur := paint(BaronBoss.FUR, flash)
	draw_set_transform(Vector2(0, -_height), 0.0, Vector2(1.0, 0.85 if state == "crouch" else 1.0))
	var wiggle := (4.0 if boil % 2 == 0 else -4.0) if state == "crouch" else 0.0
	# The tail, up and waving.
	var tail_tip := Vector2(-22 + wiggle, -46 + (4.0 if boil % 2 == 0 else -2.0))
	Toon.hose(self, Vector2(-10 + wiggle, -16), tail_tip, 8.0, 7.0)
	Toon.hose(self, Vector2(-10 + wiggle, -16), tail_tip, 8.0, 3.5, fur)
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, Vector2(sx * 8.0 + wiggle * 0.5, -3.0), Vector2(6, 4), paint(BrotherLook.WHITE, flash), boil, _seed + int(sx), 2.5)
	Toon.ball(self, Vector2(wiggle, -16), Vector2(13, 10), fur, boil, _seed + 2, 3.5)
	var head := Vector2(0, -34)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([head + Vector2(sx * 15, -2), head + Vector2(sx * 5, -12),
				head + Vector2(sx * 15, -22)]), fur, 3.0)
	Toon.ball(self, head, Vector2(17, 14), fur, boil, _seed + 3)
	for j in 2:
		Toon.stroke(self, PackedVector2Array([head + Vector2(-5 + j * 10, -14), head + Vector2(-4 + j * 8, -8)]), 2.5,
				fur.darkened(0.3))
	Toon.blob(self, head + Vector2(0, 5), Vector2(10, 6), paint(BaronBoss.MUZZLE, flash), boil, _seed + 4, 2.5)
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		Toon.pie_eye(self, head + Vector2(sx * 6.5, -3.0), Vector2(5.5, 7), look, boil, _seed + 5 + int(sx), 2.5)
	Toon.spot(self, head + Vector2(0, 3), Vector2(3, 2), Color("c86a6a"))
	# A tiny top hat, cocked.
	Toon.box(self, head + Vector2(3, -14), Vector2(12, 3), Toon.INK, boil, _seed + 7, 2.0, -0.2)
	Toon.box(self, head + Vector2(4, -22), Vector2(8, 8), Toon.INK, boil, _seed + 8, 2.0, -0.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
