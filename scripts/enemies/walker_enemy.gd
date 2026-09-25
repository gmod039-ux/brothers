class_name WalkerEnemy
extends Enemy
## Топтун: a grumpy lump on two feet. Wanders about until a brother comes
## near, then stomps straight at him, faster.

const BODY := Color("8fae5e")
const FEET := Color("4a3a2a")

var chasing := false
var _heading := Vector2.ZERO
var _turn_in := 0.0


func think(delta: float) -> Vector2:
	var t := target()
	var notice := float(def.get("notice", 380.0))
	chasing = t != null and global_position.distance_to(t.global_position) < notice
	if chasing:
		return (t.global_position - global_position).normalized() \
				* float(def.get("chase_speed", speed))
	_turn_in -= delta
	if _turn_in <= 0.0 or is_on_wall():
		_heading = Vector2.from_angle(rng.randf() * TAU)
		_turn_in = rng.randf_range(1.2, 2.6)
	return _heading * speed


func draw_body(boil: int, flash: bool) -> void:
	var moving := velocity.length() > 20.0
	var step := boil % 2 if moving else -1
	var bob := -3.0 if step == 0 else 0.0
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var lift := -6.0 if step == i else 0.0
		Toon.blob(self, Vector2(sx * 14.0, -4.0 + lift), Vector2(12.0, 8.0), paint(FEET, flash), boil, _seed + i, 4.0)
	var at := Vector2(0, -34.0 + bob)
	Toon.blob(self, at, Vector2(31.0, 27.0), paint(BODY, flash), boil, _seed + 2)
	# Belly patch.
	Toon.spot(self, at + Vector2(0, 10.0), Vector2(17.0, 10.0), Color(1, 1, 0.85, 0.28), boil, _seed + 3)
	var look := gaze()
	var lid := 0.55 if chasing else 0.35
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var eye := at + Vector2(sx * 11.0, -8.0)
		Toon.pie_eye(self, eye, Vector2(8.0, 10.0), look, boil, _seed + 4 + i, 3.0)
		_lid(eye, Vector2(8.0, 10.0), lid, paint(BODY, flash), sx)
	# A sulky mouth with one tooth.
	var mouth_a := at + Vector2(-13.0, 12.0)
	var mouth_b := at + Vector2(13.0, 12.0)
	Toon.blob(self, at + Vector2(6.0, 14.0), Vector2(3.5, 4.0), Toon.WHITE, boil, _seed + 8, 2.0)
	Toon.stroke(self, Toon.bent(mouth_a, mouth_b, 6.0 if not chasing else 3.0), 3.5)


## A heavy upper eyelid covering the top [param amount] of an eye, slanted
## down towards the nose.
##
## The lid is the part of the eye's ellipse above a chord -- an arc and the
## chord closing it -- so the shape never crosses itself; the slant is the
## whole lid turned a little about the eye.
func _lid(eye: Vector2, radii: Vector2, amount: float, color: Color, side: float) -> void:
	var r := radii + Vector2(1.5, 1.5)
	var edge_y := -r.y + r.y * 2.0 * amount
	var k := clampf(-edge_y / r.y, -0.95, 0.95)
	var a0 := PI + asin(k)
	var a1 := TAU - asin(k)
	var slant := -side * (0.3 if chasing else 0.12)
	var points := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		points.append(eye + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(slant))
	draw_colored_polygon(points, color)
	Toon.stroke(self, PackedVector2Array([points[0], points[n]]), 3.5)
