class_name FirePatch
extends Node2D
## A puddle of fire left on the floor where a fireball came down: it burns
## for a couple of seconds, hurting anyone who walks through it, then
## gutters out.

const REACH := 40.0
const LIFE := 2.6

var room: Room

var _clock := 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	if _clock > LIFE:
		queue_free()
		return
	if _clock < 0.15:
		return
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(global_position) < REACH:
			brother.hurt(1, global_position, "Пыхтун")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var d := int(_clock * Toon.FPS)
	var fade := 1.0 - maxf(_clock - LIFE + 0.6, 0.0) / 0.6
	Toon.spot(self, Vector2.ZERO, Vector2(REACH, REACH * 0.4) * fade, Color(0.35, 0.12, 0.05, 0.5))
	for k in 4:
		var x := (k - 1.5) * 18.0
		var h: float = [26.0, 34.0, 22.0, 30.0][(d + k) % 4] * fade
		var flame := PackedVector2Array()
		for i in 12:
			var t := TAU * i / 12.0
			var y := -cos(t)
			var up := (1.0 - y) * 0.5
			flame.append(Vector2(x + sin(t) * sin(t * 0.5) * 9.0 * fade, -up * h + 4.0))
		Toon.shape(self, flame, StoveBoss.FIRE, 2.5)
		Toon.spot(self, Vector2(x, -h * 0.25), Vector2(4, 6) * fade, StoveBoss.FIRE_CORE)
