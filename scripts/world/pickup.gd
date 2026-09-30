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
## Left by a brother taking another item in its place: waits until nobody
## is standing on it, or it would go straight back into his hands.
var wait_clear := false
## Seconds left of the price tag's wiggle: someone short of coins stepped
## up to it.
var _nope := 0.0
## Somebody is standing at it without the coins; the tag only wiggles once
## for each time he steps up.
var _refused := false

var _clock := 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	if gone or _clock < 0.4:
		return
	if wait_clear:
		for brother in room.brothers:
			if brother.global_position.distance_to(global_position) <= REACH * 1.6:
				return
		wait_clear = false
	var short := false
	for brother in room.brothers:
		if brother.dead:
			continue
		if brother.global_position.distance_to(global_position) > REACH:
			continue
		if price > 0 and brother.coins < price:
			short = true
		if _use(brother):
			gone = true
			var sound: String = {"coin": "coin", "half_heart": "heart", "heart": "heart", "item": "item"}.get(kind, "pickup")
			Sfx.play(sound, -4.0, 0.03)
			if price > 0:
				# The till.
				Sfx.play("coin", -2.0, 0.0)
			taken.emit(brother)
			var puff := Puff.new()
			puff.radius = 26.0
			puff.stars = 3
			room.effects.add_child(puff)
			puff.global_position = global_position
			queue_free()
			return
	if short and not _refused:
		# Not enough coins: the tag shakes and the shopkeeper tuts.
		_nope = 0.4
		Sfx.play("nope", -4.0, 0.0)
	_refused = short


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
	_nope = maxf(_nope - delta, 0.0)
	queue_redraw()


## A fluted stone column, a red velvet cushion on it with gold tassels at the
## corners.
func _pedestal() -> void:
	var stone := Color("cfc3a8")
	Toon.glow(self, Vector2(4, 6), Vector2(56, 16), Color(0, 0, 0, 0.45), 2)
	# The base, the shaft, the capital.
	Toon.box(self, Vector2(0, -4), Vector2(40, 10), stone.darkened(0.1), 0, 5, 4.5)
	Toon.box(self, Vector2(0, -30), Vector2(28, 22), stone, 0, 6, 4.5)
	for k in 4:
		var x := -18.0 + k * 12.0
		draw_line(Vector2(x, -48), Vector2(x, -12), Color(0, 0, 0, 0.22), 3.0)
	draw_rect(Rect2(14, -50, 12, 40), Color(0, 0, 0, 0.12))
	Toon.box(self, Vector2(0, -56), Vector2(40, 9), stone.lightened(0.1), 0, 7, 4.5)
	# The cushion, puffed up, with a button in the middle.
	var velvet := Color("a32a2a")
	Toon.ball(self, Vector2(0, -70), Vector2(38, 12), velvet, 0, 8, 4.0, 0.0, 0.25)
	Toon.spot(self, Vector2(0, -70), Vector2(3, 2), Color(0, 0, 0, 0.4))
	for side: float in [-1.0, 1.0]:
		var corner := Vector2(side * 36, -68)
		Toon.stroke(self, PackedVector2Array([corner, corner + Vector2(side * 3, 12)]), 3.0, ItemIcon.GOLD)
		Toon.blob(self, corner + Vector2(side * 3, 16), Vector2(4, 6), ItemIcon.GOLD, 0, 9, 2.0)


func _draw() -> void:
	var drawing := int(_clock * Toon.FPS)
	# Drops in from above, bounces once, then bobs.
	var fall := [70.0, 30.0, 0.0, 12.0, 0.0]
	var up: float = fall[drawing] if drawing < fall.size() else [0.0, 2.0, 4.0, 2.0][drawing % 4]
	if kind == "item":
		_pedestal()
		# The item floats over the cushion in a golden glow, sparkling.
		var at := Vector2(0, -100 - up)
		Toon.glow(self, at, Vector2(70, 64), Color(1, 0.88, 0.45, 0.4), 3)
		ItemIcon.draw(self, item, at, 80.0, drawing)
		for k in 3:
			var t := fmod(_clock * 0.8 + k / 3.0, 1.0)
			var a := TAU * (k / 3.0) + _clock * 0.6
			var p := at + Vector2(cos(a) * 48.0, sin(a) * 30.0 - t * 20.0)
			Toon.star(self, p, 6.0 * sin(t * PI) + 1.0, a, Color("fff1a8"))
	else:
		var size := 40.0
		Toon.spot(self, Vector2(0, 4), Vector2(size * 0.5, 7), Color(Toon.INK, 0.25))
		match kind:
			"half_heart", "heart":
				Toon.heart(self, Vector2(0, -22 - up), size, 1 if kind == "half_heart" else 2, RED, Color("4a2c22"))
			_:
				ItemIcon.draw(self, kind, Vector2(0, -22 - up), 46.0, drawing)
		# Now and then a glint runs over it.
		if drawing % 18 < 2:
			Toon.star(self, Vector2(10, -34 - up), 6.0 + (drawing % 18) * 3.0, 0.3, Color("fffbe8"))
	if price > 0:
		# A paper tag on a string, tilted, with the price in coins.
		var tag := Vector2(sin(_nope * 60.0) * 7.0 * _nope / 0.4, 34)
		Toon.stroke(self, PackedVector2Array([Vector2(-6, 8), tag + Vector2(-20, -12)]), 2.0, Color(Toon.INK, 0.7))
		var corners := PackedVector2Array([tag + Vector2(-34, -14), tag + Vector2(30, -16), tag + Vector2(32, 14),
				tag + Vector2(-32, 16), tag + Vector2(-42, 1)])
		Toon.shape(self, corners, Color("f3e6c8"), 3.5)
		Toon.spot(self, tag + Vector2(-33, 1), Vector2(3, 3), Toon.INK)
		ItemIcon.draw(self, "coin", tag + Vector2(-12, 1), 22.0, 0)
		draw_string(Ui.font(), tag + Vector2(2, 11), str(price), HORIZONTAL_ALIGNMENT_LEFT, -1, 28,
				Color("d8412f") if _nope > 0.0 else Color("7a1e18"))
