class_name FlyEnemy
extends Enemy
## Муха: small, fragile, always coming at you, weaving as it flies. Goes over
## rocks.

const BODY := Color("4b3f58")
const WING := Color(0.98, 0.96, 0.9, 0.9)

var _weave := 0.0


func think(delta: float) -> Vector2:
	var t := target()
	if t == null:
		return Vector2.ZERO
	_weave += delta * 5.0
	var to := (t.global_position - global_position).normalized()
	return (to + to.orthogonal() * sin(_weave) * 0.7).normalized() * speed


func draw_body(boil: int, flash: bool) -> void:
	var bob: float = [0.0, 3.0, 5.0, 3.0][boil % 4]
	var hover := 34.0 + bob
	var at := Vector2(0, -hover)
	# Drawn for a radius of 20 and scaled to the data's.
	var k := radius / 20.0
	# Wings flap every drawing: up, down.
	var up := boil % 2 == 0
	for sx: float in [-1.0, 1.0]:
		var rot := sx * (0.9 if up else 0.25)
		var wing_at := at + Vector2(sx * 12.0, -10.0 if up else -4.0) * k
		Toon.blob(self, wing_at, Vector2(12.0, 7.0) * k, paint(WING, flash), boil, _seed + int(sx) + 3, 3.5, rot)
	Toon.blob(self, at, Vector2(16.0, 14.0) * k, paint(BODY, flash), boil, _seed)
	var look := gaze()
	Toon.pie_eye(self, at + Vector2(-6.0, -2.0) * k, Vector2(5.5, 7.0) * k, look, boil, _seed + 5, 2.5)
	Toon.pie_eye(self, at + Vector2(6.0, -2.0) * k, Vector2(5.5, 7.0) * k, look, boil, _seed + 6, 2.5)
	# Brows in white: black on a dark body would not show.
	var brow_color := Toon.WHITE
	Toon.stroke(self, PackedVector2Array([at + Vector2(-10.0, -12.0) * k, at + Vector2(-2.0, -8.0) * k]), 2.5, brow_color)
	Toon.stroke(self, PackedVector2Array([at + Vector2(10.0, -12.0) * k, at + Vector2(2.0, -8.0) * k]), 2.5, brow_color)
