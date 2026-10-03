class_name ChalkHints
extends Node2D
## The controls chalked on the floor of the very first room, the way Isaac's
## basement has them: little keys drawn in chalk, a word under each group,
## read once and then walked over. With two brothers, a line for the
## second one's gamepad.

const CHALK := Color(1.0, 0.98, 0.92, 0.62)
## Chalk on a light stone floor needs a faint dark edge to read.
const DUST := Color(0.1, 0.07, 0.05, 0.22)
const KEY := 58.0

var coop := false


func _draw() -> void:
	# Walking: W over A S D.
	_keys(Vector2(540, 650), [["W", Vector2(0, -1)], ["A", Vector2(-1, 0)], ["S", Vector2(0, 0)],
			["D", Vector2(1, 0)]], -0.04, 3)
	_word(Vector2(540, 745), "ходить", -0.04)
	# Shooting: the arrows, laid out the same way.
	_keys(Vector2(1380, 650), [["↑", Vector2(0, -1)], ["←", Vector2(-1, 0)], ["↓", Vector2(0, 0)],
			["→", Vector2(1, 0)]], 0.03, 11)
	_word(Vector2(1380, 745), "стрелять", 0.03)
	# The rest in a line along the bottom.
	var line := "E — бомба     Пробел — предмет     Esc — пауза"
	_word(Vector2(960, 850), line, -0.01, 30)
	if coop:
		_word(Vector2(960, 196), "второй игрок — на геймпаде", -0.01, 28)


## Keycaps in a cluster round [param at], each [label, offset in keys].
func _keys(at: Vector2, caps: Array, tilt: float, seed: int) -> void:
	draw_set_transform(at, tilt)
	for i in caps.size():
		var cap: Array = caps[i]
		var center: Vector2 = (cap[1] as Vector2) * (KEY + 10.0)
		_chalk_box(Rect2(center - Vector2(KEY, KEY) * 0.5, Vector2(KEY, KEY)), seed + i)
		_text(center + Vector2(-KEY * 0.5, 13), str(cap[0]), KEY, 34)
	draw_set_transform(Vector2.ZERO)


func _word(at: Vector2, text: String, tilt: float, size := 36) -> void:
	draw_set_transform(at, tilt)
	_text(Vector2(-500, size * 0.35), text, 1000.0, size)
	# A chalk rule under it, not quite straight.
	var half := minf(Ui.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, 480.0)
	draw_polyline(PackedVector2Array([Vector2(-half, size * 0.7), Vector2(0, size * 0.7 + 4),
			Vector2(half, size * 0.7 - 2)]), Color(CHALK, CHALK.a * 0.7), 3.0, true)
	draw_set_transform(Vector2.ZERO)


## A square drawn by hand: each side a little off true and overshooting at
## the corners, the way chalk goes on a floor.
func _chalk_box(r: Rect2, seed: int) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		var along := (b - a).normalized()
		var wobble := Vector2(Toon.hash01(seed, k) - 0.5, Toon.hash01(seed, k + 7) - 0.5) * 4.0
		draw_line(a - along * 4.0 + wobble + Vector2(2, 2), b + along * 5.0 - wobble + Vector2(2, 2), DUST, 3.5, true)
		draw_line(a - along * 4.0 + wobble, b + along * 5.0 - wobble, CHALK, 3.0, true)


func _text(at: Vector2, text: String, width: float, size: int) -> void:
	draw_string(Ui.font(), at + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, DUST)
	draw_string(Ui.font(), at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, CHALK)
