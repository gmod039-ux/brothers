extends SceneTree
## A sheet of the fonts in fonts/, each lettering the game's own titles the
## way the game letters them, to choose one by eye:
##
##     godot --path . --resolution 1920x1080 --script res://dev/font_sheet.gd

const SAMPLES := ["БРАТЬЯ", "Громила Бруно", "НОКАУТ!", "Эх, братец… · этаж 2 из 3"]


func _initialize() -> void:
	var files := DirAccess.get_files_at("res://fonts")
	var y := 20.0
	var root := Node2D.new()
	var back := ColorRect.new()
	back.color = Color("2a1510")
	back.size = Vector2(1920, 1080)
	root.add_child(back)
	var row := 0
	for file in files:
		if not file.ends_with(".ttf"):
			continue
		var font := FontFile.new()
		font.load_dynamic_font("res://fonts/" + file)
		var settings := LabelSettings.new()
		settings.font = font
		settings.font_size = 64
		settings.font_color = Color("f6e7c1")
		settings.outline_size = 10
		settings.outline_color = Color("1b1410")
		settings.shadow_size = 6
		settings.shadow_color = Color(0.1, 0.07, 0.06, 0.55)
		settings.shadow_offset = Vector2(3, 4)
		var name := Label.new()
		name.text = "%d. %s" % [row + 1, file.get_basename()]
		name.position = Vector2(30, y)
		name.add_theme_color_override("font_color", Color("e0b23a"))
		name.add_theme_font_size_override("font_size", 22)
		root.add_child(name)
		var label := Label.new()
		label.text = "  ·  ".join(SAMPLES.slice(0, 3))
		label.label_settings = settings
		label.position = Vector2(30, y + 24)
		root.add_child(label)
		var small := settings.duplicate() as LabelSettings
		small.font_size = 34
		small.outline_size = 6
		var line := Label.new()
		line.text = SAMPLES[3] + "   ·   Сердца  Скорость  Урон  × 07"
		line.label_settings = small
		line.position = Vector2(1000, y + 4)
		root.add_child(line)
		y += 172.0
		row += 1
	get_root().add_child(root)
	for _i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://dev/out/fonts.png"))
	print("wrote dev/out/fonts.png")
	quit()
