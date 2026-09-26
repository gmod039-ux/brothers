class_name ChalkHints
extends Node2D
## The controls written in chalk on the floor of the very first room, the
## way Isaac's basement has them: read once, then walked over.

const CHALK := Color(0.96, 0.93, 0.84, 0.45)
## Where each block of lines goes on the floor (room coordinates), its tilt,
## its lines.
const BLOCKS := [
	[Vector2(500, 470), -0.05, ["WASD — ходить", "стрелки — стрелять"]],
	[Vector2(1420, 470), 0.04, ["E — бомба", "Пробел — предмет", "Esc — пауза"]],
]


func _draw() -> void:
	var font := Ui.font()
	for block: Array in BLOCKS:
		var lines: Array = block[2]
		draw_set_transform(block[0], block[1])
		for i in lines.size():
			var y := (i - (lines.size() - 1) * 0.5) * 60.0
			draw_string(font, Vector2(-300, y + 12), str(lines[i]), HORIZONTAL_ALIGNMENT_CENTER, 600, 38, CHALK)
		# A chalk rule under the block, not quite straight.
		var under := (lines.size() - 1) * 30.0 + 46.0
		draw_polyline(PackedVector2Array([Vector2(-150, under), Vector2(0, under + 4), Vector2(150, under - 2)]),
				CHALK, 3.0, true)
	draw_set_transform(Vector2.ZERO)
