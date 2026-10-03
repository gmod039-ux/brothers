class_name BatEnemy
extends Enemy
## Нетопырь of the catacombs: a round black bat with ears as big as its
## head, a white face like the brothers' own, two fangs and scalloped
## wings going like mad. It never comes straight: it zigzags at you, and
## every few seconds it folds its wings with a squeak (the warning) and
## drops on you in a swoop.

const BODY := Color("2a2430")
const WING := Color("3b3342")

## "flutter", "squeak" or "swoop".
var state := "flutter"
var _t := 0.0
var _next := 2.5
var _zig := 0.0
var _swoop := Vector2.ZERO


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_next = rng.randf_range(1.6, 3.2)
	_zig = rng.randf() * TAU


func _switch(to: String) -> void:
	state = to
	_t = 0.0


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	if t == null:
		return Vector2.ZERO
	var to := t.global_position - global_position
	match state:
		"squeak":
			_swoop = to.normalized()
			if _t > 0.35:
				_switch("swoop")
				Sfx.play("whistle_down", -14.0, 0.3)
			return Vector2.ZERO
		"swoop":
			if _t > 0.4 or is_on_wall():
				_switch("flutter")
				_next = rng.randf_range(1.8, 3.2) - floor_look * 0.3
			return _swoop * speed * 3.0
	_zig += delta * 6.0
	if _t > _next:
		_switch("squeak")
		Sfx.play("select", -16.0, 0.4)
		return Vector2.ZERO
	var ahead := to.normalized()
	return (ahead + ahead.orthogonal() * sin(_zig) * 1.4).normalized() * speed


func lift() -> float:
	if state == "swoop":
		return 30.0
	return 52.0 + sin(_clock * 9.0) * 6.0


func draw_body(boil: int, flash: bool) -> void:
	var body := paint(BODY, flash)
	var wing := paint(WING, flash)
	var at := Vector2(0, -30)
	# Wings: two drawings, up and down; folded tight before the swoop.
	var up := boil % 2 == 0
	var spread := 0.35 if state in ["squeak", "swoop"] else 1.0
	for sx: float in [-1.0, 1.0]:
		var root := at + Vector2(sx * 10.0, -6.0)
		var low := at + Vector2(sx * 10.0, 8.0)
		var tip := root + Vector2(sx * 42.0 * spread, -22.0 if up else 12.0)
		var knuckle := root.lerp(tip, 0.5) + Vector2(0, -10.0 if up else -4.0)
		var points := PackedVector2Array([root, knuckle, tip])
		# The trailing edge back to the body: three scallops bitten out.
		var prev := tip
		for k in 3:
			var next := tip.lerp(low, (k + 1) / 3.0) + Vector2(0, (6.0 if up else 4.0) * spread)
			points.append(prev.lerp(next, 0.5) + Vector2(0, -8.0 * spread))
			points.append(next)
			prev = next
		Toon.polygon(self, points, wing)
		points.append(points[0])
		Toon.stroke(self, points, 3.0)
		Toon.stroke(self, PackedVector2Array([root, knuckle, tip]), 2.5)
	# Ears.
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([at + Vector2(sx * 5.0, -12.0), at + Vector2(sx * 16.0, -34.0),
				at + Vector2(sx * 17.0, -8.0)]), body, 3.0)
	Toon.ball(self, at, Vector2(16.0, 15.0), body, boil, _seed + 2, 3.5)
	# The face mask, peaked between the eyes.
	Toon.union(self, [[at + Vector2(0, 5), Vector2(10, 7)], [at + Vector2(-5.5, -2), Vector2(6, 7)],
			[at + Vector2(5.5, -2), Vector2(6, 7)]], paint(BrotherLook.WHITE, flash), boil, _seed + 3, 2.0)
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		eye(at + Vector2(sx * 5.0, -2.0), Vector2(3.5, 5.0), look, boil, _seed + 5 + int(sx), 2.0)
	Toon.spot(self, at + Vector2(0, 4), Vector2(2.5, 2.0), Toon.INK)
	var mouth := 4.0 if state == "squeak" else 0.0
	Toon.stroke(self, Toon.bent(at + Vector2(-5, 8), at + Vector2(5, 8), -2.0 - mouth), 2.0)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([at + Vector2(sx * 3.0 - 1.5, 8.5), at + Vector2(sx * 3.0 + 1.5, 8.5),
				at + Vector2(sx * 3.0, 13.0)]), paint(BrotherLook.WHITE, flash), 1.5)
