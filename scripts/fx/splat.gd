class_name Splat
extends Node2D
## A shot bursting: a blot and a ring of droplets, three drawings and gone.

var color := Shot.INK_BLUE
var radius := 13.0

var _clock := 0.0
var _seed := 0


func _ready() -> void:
	_seed = get_instance_id() % 113


func _process(delta: float) -> void:
	_clock += delta
	if int(_clock * Toon.FPS) >= 3:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var drawing := int(_clock * Toon.FPS)
	var r := radius
	var spread := [1.3, 2.0, 2.4][mini(drawing, 2)] as float
	var blot := [1.15, 1.25, 0.7][mini(drawing, 2)] as float
	var drop := [0.42, 0.34, 0.2][mini(drawing, 2)] as float
	Toon.blob(self, Vector2.ZERO, Vector2(r * blot, r * blot * 0.8), color, drawing, _seed, 4.0)
	for i in 6:
		var a := TAU * i / 6.0 + Toon.hash01(_seed, i) * 0.8
		var at := Vector2(cos(a), sin(a) * 0.8) * r * spread
		Toon.blob(self, at, Vector2.ONE * r * drop, color, drawing, _seed + i + 1, 3.0)
