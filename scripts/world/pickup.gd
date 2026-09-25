class_name Pickup
extends Node2D
## Something to pick up off the floor: a half heart, a heart, or a heart
## container that adds a heart for good. It drops in with a bounce, sits
## bobbing, and goes when a brother who can use it walks over it -- a full
## brother leaves hearts where they are, as in Isaac.

signal taken(by: Brother)

const REACH := 48.0
const RED := Color("d8412f")
const GOLD := Color("e0b23a")

## "half_heart", "heart" or "heart_container".
var kind := "heart"
var room: Room
var gone := false

var _clock := 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	if gone or _clock < 0.4:
		return
	for brother in room.brothers:
		if brother.dead or brother.global_position.distance_to(global_position) > REACH:
			continue
		if _use(brother):
			gone = true
			taken.emit(brother)
			var puff := Puff.new()
			puff.radius = 26.0
			puff.stars = 3
			room.effects.add_child(puff)
			puff.global_position = global_position
			queue_free()
			return


func _use(brother: Brother) -> bool:
	match kind:
		"half_heart":
			if brother.hp >= brother.stats.max_hp():
				return false
			brother.heal(1)
		"heart":
			if brother.hp >= brother.stats.max_hp():
				return false
			brother.heal(2)
		"heart_container":
			brother.add_heart()
	return true


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var drawing := int(_clock * Toon.FPS)
	# Drops in from above, bounces once, then bobs.
	var fall := [70.0, 30.0, 0.0, 12.0, 0.0]
	var up: float = fall[drawing] if drawing < fall.size() else [0.0, 2.0, 4.0, 2.0][drawing % 4]
	var size := 44.0 if kind == "heart_container" else 34.0
	Toon.spot(self, Vector2(0, 4), Vector2(size * 0.5, 7), Color(Toon.INK, 0.25))
	if kind == "heart_container":
		# On a little stone pedestal, with a gold rim: a heart for keeps.
		Toon.box(self, Vector2(0, -8), Vector2(34, 16), Room.ROCK, 0, 5, 4.0)
		Toon.heart(self, Vector2(0, -52 - up), size + 8.0, 2, GOLD, GOLD)
		Toon.heart(self, Vector2(0, -52 - up), size - 4.0, 2, RED, RED)
		return
	Toon.heart(self, Vector2(0, -22 - up), size, 1 if kind == "half_heart" else 2, RED, Color("4a2c22"))
