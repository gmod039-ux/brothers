class_name Puff
extends Node2D
## The cartoon "poof": a burst of cloud and a few stars flying out, when
## something is knocked out of the picture or pops into it.

const CLOUD := Color("f6ecd6")
const STAR := Color("f2c14e")

## How big: about the radius of what went poof.
var radius := 30.0
var stars := 4
var drawings := 6

var _clock := 0.0
var _seed := 0


func _ready() -> void:
	_seed = get_instance_id() % 127


func _process(delta: float) -> void:
	_clock += delta
	if int(_clock * Toon.FPS) >= drawings:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var d := int(_clock * Toon.FPS)
	var t := float(d) / drawings
	var r := radius
	# Clouds swell, then thin out.
	var swell := 0.55 + 0.7 * sqrt(t)
	var shrink := 1.0 - maxf(t - 0.5, 0.0) * 1.6
	for i in 7:
		var a := TAU * i / 7.0 + Toon.hash01(_seed, i) * 0.6
		var out := r * (0.35 + 0.75 * t)
		var at := Vector2(cos(a), sin(a) * 0.7) * out + Vector2(0, -r * 0.6)
		var size := r * (0.42 + Toon.hash01(_seed, i + 10) * 0.2) * swell * shrink
		if size > 2.0:
			Toon.blob(self, at, Vector2(size, size * 0.85), CLOUD, d, _seed + i, 4.0)
	for i in stars:
		var a := TAU * (i + 0.5) / stars + Toon.hash01(_seed, i + 20) * 0.7 - PI * 0.5
		var at := Vector2(cos(a), sin(a) * 0.8) * r * (0.6 + 1.5 * t) + Vector2(0, -r * 0.7)
		Toon.star(self, at, r * 0.26 * (1.0 - t * 0.5), a + d * 0.5, STAR)
