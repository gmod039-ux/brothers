class_name Chick
extends Node2D
## Цыплёнок: a yellow chick in a little sailor's cap that trots after its
## brother and, every other time he shoots, shoots too -- a smaller drop,
## the same way. Kept as a child of the brother but placed in the world on
## its own, so it goes from room to room with him and lags behind him.

const FOLLOW := 70.0
const DAMAGE := 2.5
const YELLOW := Color("f2c84a")

var brother: Brother

var _clock := 0.0
var _turn := 0
var _facing := 1.0
var _hop := 0.0


func _ready() -> void:
	top_level = true
	global_position = brother.global_position + Vector2(-FOLLOW, 10)
	brother.fired.connect(_on_fired)
	z_index = 0


func _process(delta: float) -> void:
	_clock += delta
	_hop = maxf(_hop - delta, 0.0)
	if not is_instance_valid(brother):
		return
	visible = not brother.dead and brother.room != null
	# Behind him, a little to the side, catching up in a hurry when left
	# far behind (a new room).
	var want := brother.global_position + Vector2(-FOLLOW * signf(_facing), 16)
	var gap := want - global_position
	if gap.length() > 600.0:
		global_position = want
	else:
		global_position += gap * minf(delta * 6.0, 1.0)
	if absf(gap.x) > 8.0:
		_facing = signf(brother.global_position.x - global_position.x)
	queue_redraw()


func _on_fired(aim: Vector2) -> void:
	_turn += 1
	if _turn % 2 == 1 or brother.room == null or brother.dead:
		return
	var room := brother.room
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + aim * 14.0, 26.0, aim * brother.stats.shot_px() * 0.9,
			brother.stats.range_px() * 0.8, DAMAGE, 9.0, false)
	shot.tint = Color("e8a83a")
	_hop = 0.15


func _draw() -> void:
	var boil := int(_clock * Toon.FPS)
	var walking := is_instance_valid(brother) and brother.velocity.length() > 40.0
	var bob := (-4.0 if boil % 2 == 0 else 0.0) if walking else 0.0
	bob -= _hop * 40.0
	Toon.spot(self, Vector2(0, 2), Vector2(16, 5), Color(Toon.INK, 0.25))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(_facing, 1.0))
	# Two orange legs.
	for sx: float in [-1.0, 1.0]:
		var up := -3.0 if walking and (boil % 2 == 0) == (sx < 0.0) else 0.0
		Toon.stroke(self, PackedVector2Array([Vector2(sx * 5, -10), Vector2(sx * 6, -2 + up)]), 3.0, Color("e0782a"))
		Toon.stroke(self, PackedVector2Array([Vector2(sx * 6, -2 + up), Vector2(sx * 6 + 5, -2 + up)]), 3.0, Color("e0782a"))
	# The body, a wing, the head.
	Toon.ball(self, Vector2(0, -18), Vector2(13, 11), YELLOW, boil, 1, 3.5)
	Toon.blob(self, Vector2(-3, -18), Vector2(6, 5), YELLOW.darkened(0.1), boil, 2, 2.5, -0.3)
	Toon.ball(self, Vector2(6, -32), Vector2(10, 9), YELLOW, boil, 3, 3.5)
	Toon.shape(self, PackedVector2Array([Vector2(14, -33), Vector2(22, -30), Vector2(14, -28)]), Color("e0782a"), 2.0)
	Toon.blob(self, Vector2(9, -34), Vector2(3, 4), Toon.WHITE, boil, 4, 1.5)
	Toon.spot(self, Vector2(10, -33.5), Vector2(1.6, 2.2), Toon.INK)
	# A sailor's cap with its ribbon.
	Toon.box(self, Vector2(4, -41), Vector2(10, 3), Toon.WHITE, boil, 5, 2.0)
	Toon.ball(self, Vector2(4, -45), Vector2(8, 4), Toon.WHITE, boil, 6, 2.0)
	Toon.stroke(self, PackedVector2Array([Vector2(-5, -42), Vector2(-10, -36)]), 2.0, Color("3f6fb5"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
