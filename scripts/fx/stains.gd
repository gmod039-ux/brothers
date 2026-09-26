class_name Stains
extends Node2D
## What a fight leaves on the floor: blots of ink where enemies went poof,
## drops where shots came down. Lies flat under everyone and stays for as
## long as the room does. One node draws them all.

const MOST := 70
const INK := Color(0.1, 0.07, 0.06, 0.42)

## [local position, radius, colour, seed, big] each.
var _stains: Array = []


## Leaves a stain at world point [param at]. [param big] is an enemy's blot,
## with drips running from it; otherwise a shot's drop.
func add(at: Vector2, radius: float, color := INK, big := false) -> void:
	_stains.append([at - global_position, radius, color, randi() % 997, big])
	if _stains.size() > MOST:
		_stains.pop_front()
	queue_redraw()


func _draw() -> void:
	for stain: Array in _stains:
		var at: Vector2 = stain[0]
		var r: float = stain[1]
		var color: Color = stain[2]
		var seed: int = stain[3]
		var big: bool = stain[4]
		var body := Toon.ellipse_points(at, Vector2(r, r * 0.62), seed, seed, 0.0, 0.0, 5.0 if big else 2.5)
		Toon.polygon(self, body, color)
		# A darker rim where the ink dried.
		var rim := body.duplicate()
		rim.append(body[0])
		draw_polyline(rim, Color(color.darkened(0.3), color.a * 0.6), 2.0, true)
		var drops := 6 if big else 3
		for i in drops:
			var a := Toon.hash01(seed, i) * TAU
			var d := r * (1.2 + Toon.hash01(seed, i + 10) * (0.9 if big else 0.5))
			var p := at + Vector2(cos(a), sin(a) * 0.62) * d
			var s := r * (0.1 + Toon.hash01(seed, i + 20) * 0.14)
			Toon.spot(self, p, Vector2(s, s * 0.7), color, 0, seed + i)
		if big:
			# A shine on the wet blot.
			Toon.spot(self, at + Vector2(-r * 0.35, -r * 0.2), Vector2(r * 0.25, r * 0.08), Color(1, 1, 1, 0.12))
