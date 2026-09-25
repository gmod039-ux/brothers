extends Node2D
## A model sheet of the brothers, the way cartoon studios pinned one up for
## the animators: each brother in the poses the game uses, side by side.
## Not part of the game:
##
##     godot --path . -- concepts shot dev/out/model_sheet.png 40

const POSES := [
	["стоит", Vector2.DOWN, Vector2.ZERO, false, false],
	["идёт", Vector2.DOWN, Vector2.ZERO, true, false],
	["вбок", Vector2.RIGHT, Vector2.ZERO, true, false],
	["спиной", Vector2.UP, Vector2.ZERO, true, false],
	["стреляет", Vector2.RIGHT, Vector2.RIGHT, false, false],
	["вниз", Vector2.DOWN, Vector2.DOWN, false, false],
	["ой!", Vector2.DOWN, Vector2.ZERO, false, true],
]


func _ready() -> void:
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
	var title := Ui.label("Братья — лист модели", Ui.title(72))
	title.position = Vector2(0, 14)
	add_child(title)
	var ids := ["older", "younger"]
	for row in ids.size():
		var character := GameData.character(ids[row])
		var y := 470.0 + row * 440.0
		var name_label := Ui.label(str(character.get("name", ids[row])), Ui.title(44), 300)
		name_label.position = Vector2(80, y - 300)
		add_child(name_label)
		for col in POSES.size():
			var pose: Array = POSES[col]
			var look := BrotherLook.new()
			look.configure(character.get("look", {}))
			look.scale = Vector2(1.55, 1.55)
			look.position = Vector2(230 + col * 255.0, y)
			look.facing = pose[1]
			look.aim = pose[2]
			look.moving = pose[3]
			look.pose_shocked = pose[4]
			add_child(look)
			if row == 0:
				var caption := Ui.label(str(pose[0]), Ui.text(30, Color("3a2418")), 250)
				caption.label_settings.outline_size = 0
				caption.position = Vector2(230 + col * 255.0 - 125, 1010)
				add_child(caption)
