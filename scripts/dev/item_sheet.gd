extends Node2D
## Every item of the game on one card, each with its picture, its name and
## what it does; the ones for the hands (Space) marked with their charge.
## Not part of the game:
##
##     godot --path . -- items shot dev/out/items.png 40

const COLS := 6


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
	var title := Ui.label("Предметы", Ui.title(64))
	title.position = Vector2(0, 8)
	add_child(title)
	var ids := GameData.items().keys()
	# The ones that count by themselves first, then the ones for the hands.
	ids.sort_custom(func(a: String, b: String) -> bool:
		var aa: bool = GameData.items()[a].has("active")
		var bb: bool = GameData.items()[b].has("active")
		if aa != bb:
			return bb
		return a < b)
	for i in ids.size():
		var id: String = ids[i]
		var item: Dictionary = GameData.items()[id]
		var at := Vector2(180 + (i % COLS) * 312.0, 190 + (i / COLS) * 230.0)
		var icon := Node2D.new()
		icon.position = at
		icon.draw.connect(func() -> void:
			Toon.blob(icon, Vector2.ZERO, Vector2(52, 52), Color(1, 1, 1, 0.35), 0, i, 3.0)
			ItemIcon.draw(icon, id, Vector2.ZERO, 80.0, 0))
		add_child(icon)
		var lines := [[str(item.get("name", id)), 26, Color("3a2418")], [str(item.get("text", "")), 19,
				Color("6a4a30")]]
		if item.has("active"):
			lines.append(["Пробел · заряд %d комнаты" % int(item["active"]), 19, Color("9a2f24")])
		for k in lines.size():
			var line: Array = lines[k]
			var size: int = line[1]
			# Shrunk to fit its column.
			var wide := Ui.font().get_string_size(str(line[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			if wide > 296.0:
				size = int(size * 296.0 / wide)
			var style := Ui.text(size, line[2])
			style.outline_size = 0
			var label := Ui.label(str(line[0]), style, 300)
			label.position = at + Vector2(-150, 58 + k * 30 + (8 if k > 0 else 0))
			add_child(label)
