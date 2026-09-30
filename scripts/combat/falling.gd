class_name Falling
extends Node2D
## Something dropped from above -- a lump of coal. First only its shadow,
## growing on the floor where it will land; then it comes down, hurting
## whoever is still standing there, and breaks.

const WARN := 0.9
const REACH := 54.0
const COAL := Color("2a2626")

var room: Room
## Seconds before the shadow even starts, so a shower lands one by one.
var delay := 0.0
## "coal", "card", or "bag": a sack of money that bursts into coins where
## it lands.
var look := "coal"

var _clock := 0.0
var _landed := false


func _physics_process(delta: float) -> void:
	_clock += delta
	if _landed:
		if _clock > delay + WARN + 0.35:
			queue_free()
		return
	if _clock < delay + WARN:
		return
	_landed = true
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(global_position) < REACH:
			brother.hurt(1, global_position, "Пыхтун" if look == "coal" else "Барон Когтев")
	Sfx.play("hit", -2.0, 0.2)
	if look == "bag":
		# What the Baron throws is his own money: it stays on the floor.
		for i in 2:
			var coin := Pickup.new()
			coin.kind = "coin"
			coin.room = room
			room.actors.add_child(coin)
			coin.global_position = global_position + Vector2(i * 30.0 - 15.0, 6.0)
	var puff := Puff.new()
	puff.radius = 30.0
	puff.stars = 0
	puff.drawings = 4
	room.effects.add_child(puff)
	puff.global_position = global_position


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _clock < delay:
		return
	var t := clampf((_clock - delay) / WARN, 0.0, 1.0)
	var d := int(_clock * Toon.FPS)
	if not _landed:
		Toon.spot(self, Vector2.ZERO, Vector2(REACH, REACH * 0.34) * (0.3 + 0.7 * t), Color(Toon.INK, 0.35))
		var height := (1.0 - t) * (1.0 - t) * 700.0
		if look == "card":
			var spin := _clock * 7.0
			Toon.box(self, Vector2(0, -height - 20), Vector2(13, 18), BrotherLook.WHITE, d, 1, 3.5, spin)
			Toon.heart(self, Vector2(0, -height - 20), 14.0, 2, Color("c8392b"), Color("c8392b"))
		elif look == "bag":
			var bag := Vector2(0, -height - 24)
			Toon.blob(self, bag, Vector2(24, 22), Color("c9a86a"), d, 1, 4.0)
			Toon.blob(self, bag + Vector2(0, -22), Vector2(10, 7), Color("c9a86a"), d, 2, 3.5)
			draw_string(Ui.font(), bag + Vector2(-12, 12), "$", HORIZONTAL_ALIGNMENT_CENTER, 24, 30, Toon.INK)
		else:
			Toon.blob(self, Vector2(0, -height - 18), Vector2(22, 18), COAL, d, 1, 4.0, t * 3.0)
			Toon.spot(self, Vector2(-7, -height - 25), Vector2(6, 4), Color(1, 1, 1, 0.35))
	elif look == "coal":
		# Broken bits lying about.
		for i in 4:
			var a := TAU * i / 4.0 + 0.5
			Toon.blob(self, Vector2(cos(a) * 20.0, sin(a) * 8.0 - 6.0), Vector2(8, 6), COAL, d, 2 + i, 3.0, a)
