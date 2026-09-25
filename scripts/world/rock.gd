class_name Rock
extends Node2D
## A rock on the floor: blocks walking and shots. Part of the background, so
## it does not boil. Sits among the actors so that whoever stands behind it
## is drawn behind it.

var seed_value := 0


func _draw() -> void:
	var h := func(k: int) -> float: return Toon.hash01(seed_value, k)
	var radii := Vector2(46.0 + h.call(1) * 6.0, 36.0 + h.call(2) * 6.0)
	var tilt: float = (h.call(3) - 0.5) * 0.5
	var body := Vector2(0, -10)
	Toon.spot(self, Vector2(0, 26), Vector2(radii.x * 1.05, 14), Color(Toon.INK, 0.28))
	Toon.blob(self, body, radii, Room.ROCK, seed_value, 0, 5.0, tilt)
	# The underside in shade, the top catching the light.
	Toon.spot(self, body + Vector2(4, radii.y * 0.45), Vector2(radii.x * 0.78, radii.y * 0.4),
			Room.ROCK_DARK, 0, 0, tilt)
	Toon.spot(self, body + Vector2(-radii.x * 0.3, -radii.y * 0.45),
			Vector2(radii.x * 0.3, radii.y * 0.16), Color(1, 0.97, 0.9, 0.55), 0, 0, tilt - 0.3)
	# A crack.
	var a := body + Vector2((h.call(4) - 0.5) * radii.x * 0.8, -radii.y * 0.7)
	var b := a + Vector2(8 - h.call(5) * 16, radii.y * 0.45)
	var c := b + Vector2(12 - h.call(6) * 6, radii.y * 0.3)
	Toon.stroke(self, PackedVector2Array([a, b, c]), 3.0)
