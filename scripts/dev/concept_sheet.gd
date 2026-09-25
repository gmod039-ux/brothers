extends Node2D
## A sheet of candidate looks for the brothers, each pair side by side, for
## choosing who they are. Not part of the game:
##
##     godot --path . -- concepts shot dev/out/concepts.png 40
##     godot --path . -- concepts walk shot dev/out/concepts_walk.png 40
##
## `walk` shows them walking and turned to the side instead of standing.

const PAIRS := [
	["Коты", {
		"head": "cat", "size": 1.08, "head_color": "#302a2e", "face_color": "#f6e3c4",
		"shirt": "#302a2e", "pants": "#c8392b", "hat": "bow", "hat_color": "#f2c14e",
	}, {
		"head": "cat", "size": 0.94, "head_color": "#e38a3a", "face_color": "#f8e6c8",
		"shirt": "#e38a3a", "pants": "#3f6fb5", "hat": "tuft",
	}],
	["Спички", {
		"head": "match", "size": 1.08, "head_color": "#cf3b2c",
		"shirt": "#e3b979", "pants": "#c99a58", "hat": "bow", "hat_color": "#3f6fb5",
	}, {
		"head": "match", "size": 0.94, "head_color": "#3f78c0",
		"shirt": "#e3b979", "pants": "#c99a58", "hat": "none",
	}],
	["Лампочки", {
		"head": "bulb", "size": 1.08, "head_color": "#fff0a0",
		"shirt": "#3f6fb5", "pants": "#2e3350", "hat": "bow", "hat_color": "#c8392b",
	}, {
		"head": "bulb", "size": 0.94, "head_color": "#e2f3ff",
		"shirt": "#e0b23a", "pants": "#3f7a57", "hat": "none",
	}],
	["Чернильницы", {
		"head": "inkwell", "size": 1.08, "head_color": "#2c3f73", "face_color": "#f3e6c8",
		"shirt": "#f3e6c8", "pants": "#3a3a48", "hat": "quill",
	}, {
		"head": "inkwell", "size": 0.94, "head_color": "#8a2c3c", "face_color": "#f3e6c8",
		"shirt": "#9fc4d8", "pants": "#5a3a2a", "hat": "none",
	}],
]


func _ready() -> void:
	var walking := OS.get_cmdline_user_args().has("walk")
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)])
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/paper.gdshader")
	material.set_shader_parameter("base", BrotherSelect.CARD)
	material.set_shader_parameter("stain", BrotherSelect.CARD_STAIN)
	material.set_shader_parameter("blotch", 320.0)
	material.set_shader_parameter("amount", 0.5)
	paper.material = material
	add_child(paper)
	var title := Ui.label("Кто такие братья?", Ui.title(96))
	title.position = Vector2(0, 40)
	add_child(title)
	for i in PAIRS.size():
		var pair: Array = PAIRS[i]
		var x := 240.0 + i * 480.0
		for j in 2:
			var look := BrotherLook.new()
			look.configure(pair[j + 1])
			look.scale = Vector2(1.9, 1.9)
			look.position = Vector2(x + (j * 2 - 1) * 95.0, 700)
			if walking:
				look.moving = true
				look.facing = Vector2.RIGHT if j == 0 else Vector2.LEFT
			add_child(look)
		var caption := Ui.label("%d. %s" % [i + 1, pair[0]], Ui.title(46), 480)
		caption.position = Vector2(x - 240, 760)
		add_child(caption)
	var note := Ui.label("слева старший, справа младший", Ui.text(32, Color("3a2418")))
	note.label_settings.outline_size = 0
	note.position = Vector2(0, 930)
	add_child(note)
