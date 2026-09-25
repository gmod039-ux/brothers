class_name Bomb
extends Node2D
## A lit bomb: sits fizzing for a moment, swells and flashes red, then goes
## off -- hurting every enemy near it, the brothers too if they did not get
## clear, and blowing up any rocks in reach.

signal exploded(at: Vector2)

const FUSE := 1.6
const REACH := 160.0
const DAMAGE := 25.0

var room: Room

var _clock := 0.0
var _done := false


func _physics_process(delta: float) -> void:
	_clock += delta
	if _done or _clock < FUSE:
		return
	_done = true
	_explode()


func _explode() -> void:
	var at := global_position
	for enemy in room.enemies.duplicate():
		if enemy.can_be_hit() and enemy.global_position.distance_to(at) < REACH + enemy.radius * 0.5:
			enemy.hurt(DAMAGE, (enemy.global_position - at).normalized(), 2.0)
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(at) < REACH * 0.8:
			brother.hurt(2, at)
	for row in Room.ROWS:
		for col in Room.COLS:
			var cell := Vector2i(col, row)
			if room.is_rock(cell) and room.tile_center(cell).distance_to(at) < REACH + 30.0:
				room.break_rock(cell)
	Sfx.play("blast", 0.0)
	var blast := Blast.new()
	blast.radius = REACH
	room.effects.add_child(blast)
	blast.global_position = at
	exploded.emit(at)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var drawing := int(_clock * Toon.FPS)
	var left := 1.0 - _clock / FUSE
	# Swells as the fuse burns down, and flashes red in the last half second.
	var swell := 1.0 + (1.0 - left) * 0.25 + (0.06 if drawing % 2 == 0 else 0.0)
	var hot := left < 0.33 and drawing % 2 == 0
	Toon.spot(self, Vector2(0, 2), Vector2(24, 8), Color(Toon.INK, 0.3))
	Toon.blob(self, Vector2(0, -22), Vector2(24, 22) * swell, Color("b8322a") if hot else Toon.INK, drawing, 3, 3.5)
	Toon.spot(self, Vector2(-9, -30) * swell, Vector2(5, 8), Color(1, 1, 1, 0.45))
	var fuse_end := Vector2(14, -48) * swell + Vector2(0, 10) * (1.0 - left)
	Toon.stroke(self, Toon.bent(Vector2(8, -42) * swell, fuse_end, 4.0), 3.5, ItemIcon.BROWN)
	Toon.star(self, fuse_end, 8.0 + (drawing % 2) * 3.0, drawing * 0.9, ItemIcon.GOLD)


## The explosion itself: a flash, a ring of smoke, stars, and the word for
## it, all in a few drawings.
class Blast:
	extends Node2D

	var radius := 160.0
	var _clock := 0.0

	func _process(delta: float) -> void:
		_clock += delta
		if _clock * Toon.FPS >= 7.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var d := int(_clock * Toon.FPS)
		var t := d / 7.0
		if d < 2:
			Toon.blob(self, Vector2(0, -20), Vector2(radius, radius * 0.7) * (0.6 + 0.2 * d), Color("fff1a8"), d, 1, 6.0)
		for i in 9:
			var a := TAU * i / 9.0
			var at := Vector2(cos(a), sin(a) * 0.65) * radius * (0.45 + 0.55 * t) + Vector2(0, -20)
			var r := radius * 0.28 * (1.0 - t * 0.7)
			Toon.blob(self, at, Vector2(r, r * 0.85), Color("d9cdb8").lerp(Color("6d6360"), t), d, 10 + i, 4.0)
		for i in 5:
			var a := TAU * i / 5.0 + 0.4
			Toon.star(self, Vector2(cos(a), sin(a) * 0.7) * radius * (0.3 + 0.9 * t) + Vector2(0, -30),
					14.0 * (1.0 - t * 0.5), a + d, ItemIcon.GOLD)
		if d >= 1 and d <= 5:
			draw_string(Ui.font(), Vector2(-120, -radius * 0.55), "БАХ!", HORIZONTAL_ALIGNMENT_CENTER, 240,
					72, Toon.INK)
