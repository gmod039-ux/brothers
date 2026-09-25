class_name Trapdoor
extends Node2D
## The way down to the next floor: a hatch in the floor that swings open
## once the boss is beaten. Stepping on it takes the brothers down -- but
## only after they have stepped off it once, so nobody falls through the
## moment it opens under them.

signal entered(brother: Brother)

const REACH := 46.0
const WOOD := Color("8a5a36")

var room: Room
var used := false

var _clock := 0.0
var _armed := false


func _physics_process(delta: float) -> void:
	_clock += delta
	if used or _clock < 0.6:
		return
	var anyone_on := false
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(global_position) < REACH:
			anyone_on = true
			if _armed:
				used = true
				entered.emit(brother)
				return
	if not anyone_on:
		_armed = true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var drawing := int(_clock * Toon.FPS)
	var open := clampf(drawing / 5.0, 0.0, 1.0)
	Toon.blob(self, Vector2.ZERO, Vector2(74, 44), WOOD.darkened(0.2), 0, 3, 6.0)
	Toon.blob(self, Vector2.ZERO, Vector2(60, 34) * (0.3 + 0.7 * open), Color("0d0806"), drawing, 4, 3.0)
	# The two lids folding back.
	for sx: float in [-1.0, 1.0]:
		var hinge := Vector2(sx * 62.0, 0)
		var width := 60.0 * (1.0 - open) + 8.0
		var lid := Vector2(sx * (62.0 - width * 0.5), -open * 12.0)
		Toon.box(self, lid, Vector2(width * 0.5, 34.0 - open * 10.0), WOOD, 0, 6 + int(sx), 4.0)
		Toon.stroke(self, PackedVector2Array([hinge + Vector2(-sx * 4.0, -20), hinge + Vector2(-sx * 4.0, 20)]), 4.0)
	if open >= 1.0:
		# An arrow of light pointing down into it, now and then.
		if (drawing / 4) % 2 == 0:
			Toon.star(self, Vector2(0, -70), 9.0, drawing * 0.3, Color("f2c14e"))
