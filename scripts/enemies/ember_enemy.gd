class_name EmberEnemy
extends Enemy
## Уголёк, spat out by Пыхтун: a lump of coal with a flame for hair,
## waddling at you. It will not wait for ever: a few seconds in it swells up
## red-hot and bursts, burning whoever is next to it. Shot down first, it
## only crumbles.

const COAL := Color("2e2826")
const BURST_REACH := 95.0

var _life := 0.0
var _flare := 0.0


func think(delta: float) -> Vector2:
	_life += delta
	var t := target()
	if _flare > 0.0:
		_flare += delta
		if _flare > 0.7:
			_burst()
		return Vector2.ZERO
	if _life > float(def.get("fuse", 5.0)):
		_flare = 0.001
		Sfx.play("fuse", -6.0)
		return Vector2.ZERO
	if t == null:
		return Vector2.ZERO
	return (t.global_position - global_position).normalized() * speed


func _burst() -> void:
	if dead:
		return
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(global_position) < BURST_REACH:
			brother.hurt(1, global_position, display_name)
	Fx.ring(room, global_position, BURST_REACH * 1.4, Color("f08a24"), 0.35, 8.0)
	Fx.burst(room, global_position + Vector2(0, -20), "embers", 12, 1.0)
	Sfx.play("blast", -8.0, 0.2)
	knock_out()


func knock_out() -> void:
	if not dead:
		Fx.burst(room, global_position + Vector2(0, -16), "embers", 6, 0.6)
	super.knock_out()


func draw_body(boil: int, flash: bool) -> void:
	var swell := 1.0 + (_flare * 0.5 if _flare > 0.0 else 0.0)
	var hot := _flare > 0.0 and boil % 2 == 0
	var body := Vector2(0, -20)
	for sx: float in [-1.0, 1.0]:
		var lift := -4.0 if velocity.length() > 10.0 and (boil % 2 == 0) == (sx < 0.0) else 0.0
		Toon.blob(self, Vector2(sx * 8.0, -3.0 + lift), Vector2(6, 4), Toon.INK, boil, _seed + int(sx), 2.5)
	# The flame for hair.
	var flick: float = [0.0, 3.0, -2.0][boil % 3]
	var flame := PackedVector2Array()
	for k in 14:
		var t := TAU * k / 14.0
		var y := -cos(t)
		var up := (1.0 - y) * 0.5
		flame.append(body + Vector2(sin(t) * sin(t * 0.5) * 11.0 + flick * up * up, -12.0 - up * 26.0 * swell))
	Toon.shape(self, flame, StoveBoss.FIRE, 3.0)
	Toon.ball(self, body, Vector2(18, 15) * swell, paint(Color("c8452c") if hot else COAL, flash), boil, _seed + 2, 3.5)
	# Glowing cracks.
	Toon.stroke(self, PackedVector2Array([body + Vector2(-10, 4), body + Vector2(-3, 0), body + Vector2(2, 7)]), 2.0,
			StoveBoss.FIRE)
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		eye(body + Vector2(sx * 6.0, -3.0), Vector2(4.5, 5.5), look, boil, _seed + 3 + int(sx), 2.0)
	Toon.stroke(self, PackedVector2Array([body + Vector2(-9, -11), body + Vector2(-2, -8)]), 2.5, StoveBoss.FIRE)
	Toon.stroke(self, PackedVector2Array([body + Vector2(9, -11), body + Vector2(2, -8)]), 2.5, StoveBoss.FIRE)
