class_name Pickup
extends Node2D
## Something to pick up off the floor: a half heart, a heart, a coin, a
## bomb, a key -- or an item on a pedestal. It drops in with a bounce, sits
## bobbing, and goes when a brother who can use it walks over it. A full
## brother leaves hearts where they are, as in Isaac. In a shop it has a
## price and waits for someone with the coins.

signal taken(by: Brother)

const REACH := 48.0
const RED := Color("d8412f")

## "half_heart", "heart", "coin", "bomb", "key" or "item".
var kind := "heart"
## For an item: its id in data/items.json.
var item := ""
## Coins it costs; 0 is free.
var price := 0
var room: Room
var gone := false

var _clock := 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	if gone or _clock < 0.4:
		return
	for brother in room.brothers:
		if brother.dead:
			continue
		if brother.global_position.distance_to(global_position) > REACH:
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
	if brother.coins < price:
		return false
	match kind:
		"half_heart", "heart":
			if brother.hp >= brother.stats.max_hp():
				return false
			brother.heal(1 if kind == "half_heart" else 2)
		"coin":
			brother.coins += 1
		"bomb":
			brother.bombs += 1
		"key":
			brother.keys += 1
		"item":
			brother.take_item(item)
	brother.coins -= price
	brother.inventory_changed.emit()
	return true


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var drawing := int(_clock * Toon.FPS)
	# Drops in from above, bounces once, then bobs.
	var fall := [70.0, 30.0, 0.0, 12.0, 0.0]
	var up: float = fall[drawing] if drawing < fall.size() else [0.0, 2.0, 4.0, 2.0][drawing % 4]
	if kind == "item":
		# On a stone pedestal, floating.
		Toon.spot(self, Vector2(0, 4), Vector2(34, 9), Color(Toon.INK, 0.28))
		Toon.box(self, Vector2(0, -14), Vector2(32, 18), Room.ROCK, 0, 5, 4.5)
		Toon.box(self, Vector2(0, -34), Vector2(38, 6), Room.ROCK.lightened(0.15), 0, 6, 4.0)
		Toon.spot(self, Vector2(0, -44), Vector2(22, 6), Color(Toon.INK, 0.2))
		ItemIcon.draw(self, item, Vector2(0, -84 - up), 64.0, drawing)
	else:
		var size := 34.0
		Toon.spot(self, Vector2(0, 4), Vector2(size * 0.5, 7), Color(Toon.INK, 0.25))
		match kind:
			"half_heart", "heart":
				Toon.heart(self, Vector2(0, -22 - up), size, 1 if kind == "half_heart" else 2, RED, Color("4a2c22"))
			_:
				ItemIcon.draw(self, kind, Vector2(0, -22 - up), 40.0, drawing)
	if price > 0:
		# A price tag on the floor in front.
		var tag := Vector2(0, 26)
		Toon.box(self, tag, Vector2(26, 13), BrotherLook.WHITE, 0, 7, 3.0)
		ItemIcon.draw(self, "coin", tag + Vector2(-12, 0), 18.0, 0)
		draw_string(Ui.font(), tag + Vector2(-2, 8), str(price), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Toon.INK)
