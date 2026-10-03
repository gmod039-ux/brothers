extends Node2D
## Every item of the game on one card, each with its picture, its name and
## what it does; the ones for the hands (Space) marked with their charge.
## Not part of the game:
##
##     godot --path . -- items shot dev/out/items.png 40

const COLS := 10


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
	# Those that count by themselves, then those for the hands, then the
	# trinkets.
	var rank := func(id: String) -> int:
		var item: Dictionary = GameData.items()[id]
		return 2 if item.get("trinket", false) else (1 if item.has("active") else 0)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra: int = rank.call(a)
		var rb: int = rank.call(b)
		if ra != rb:
			return ra < rb
		return a < b)
	for i in ids.size():
		var id: String = ids[i]
		var item: Dictionary = GameData.items()[id]
		var at := Vector2(100 + (i % COLS) * 191.0, 150 + (i / COLS) * 186.0)
		var icon := Node2D.new()
		icon.position = at
		icon.draw.connect(func() -> void:
			Toon.blob(icon, Vector2.ZERO, Vector2(40, 40), Color(1, 1, 1, 0.35), 0, i, 3.0)
			ItemIcon.draw(icon, id, Vector2.ZERO, 60.0, 0))
		add_child(icon)
		var lines := [[str(item.get("name", id)), 22, Color("3a2418")], [str(item.get("text", "")), 16,
				Color("6a4a30")]]
		if item.has("active"):
			lines.append(["Пробел · заряд %d" % int(item["active"]), 16, Color("9a2f24")])
		elif item.get("trinket", false):
			lines.append(["брелок", 16, Color("8a6a1a")])
		for k in lines.size():
			var line: Array = lines[k]
			var size: int = line[1]
			# Shrunk to fit its column.
			var wide := Ui.font().get_string_size(str(line[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			if wide > 180.0:
				size = int(size * 180.0 / wide)
			var style := Ui.text(size, line[2])
			style.outline_size = 0
			var label := Ui.label(str(line[0]), style, 184)
			label.position = at + Vector2(-92, 40 + k * 22 + (4 if k > 0 else 0))
			add_child(label)
