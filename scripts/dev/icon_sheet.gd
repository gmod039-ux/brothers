extends Node2D
## The game's icon and the card shown while it loads, drawn with the game's
## own pictures and written into the project as files. Not part of the game:
##
##     godot --path . --resolution 1920x1080 --film 0 -- iconsheet icon
##     godot --path . --resolution 1920x1080 --film 0 -- iconsheet splash
##
## "icon" writes icon.png: the brothers' grinning heads in a red roundel
## with a sunburst behind them, 512 px, see-through round it. "splash"
## writes splash.png: the title card, 1920 x 1080.

const BADGE := Vector2(960, 540)
const RADIUS := 480.0
const CREAM := Color("f3e6c8")
const RED := Color("b8322a")
const GOLD := Color("e0b23a")
const SEPIA := Color("1f140e")

var _mode := "icon"
var _frames := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("iconsheet")
	if at >= 0 and at + 1 < args.size():
		_mode = args[at + 1]
	if _mode == "icon":
		get_viewport().transparent_bg = true
		_icon()
	else:
		_splash()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		_save()


## The brothers' heads over a sunburst, masked to the inside of the ring,
## the ring drawn over them.
func _icon() -> void:
	var disc := Node2D.new()
	disc.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	disc.draw.connect(func() -> void:
		disc.draw_circle(BADGE, RADIUS * 0.84, Color("e6c994"))
		for i in 24:
			var a0 := TAU * i / 24.0
			var a1 := a0 + TAU * 0.5 / 24.0
			disc.draw_polygon(PackedVector2Array([BADGE, BADGE + Vector2(cos(a0), sin(a0)) * RADIUS,
					BADGE + Vector2(cos(a1), sin(a1)) * RADIUS]),
					PackedColorArray([Color("f6e7c1"), Color("f0dcae"), Color("f0dcae")]))
		Toon.glow(disc, BADGE + Vector2(0, -60), Vector2(360, 300), Color(1, 1, 0.9, 0.5), 3))
	add_child(disc)
	# Older on the left, a little behind; younger in front on the right.
	var older := _figure("older", Vector2(BADGE.x - 150, BADGE.y + 760), 5.0)
	var younger := _figure("younger", Vector2(BADGE.x + 150, BADGE.y + 660), 5.0)
	disc.add_child(older)
	disc.add_child(younger)
	var ring := Node2D.new()
	ring.draw.connect(func() -> void:
		ring.draw_arc(BADGE, RADIUS * 0.92, 0.0, TAU, 128, Toon.INK, RADIUS * 0.2, true)
		ring.draw_arc(BADGE, RADIUS * 0.92, 0.0, TAU, 128, RED, RADIUS * 0.15, true)
		ring.draw_arc(BADGE, RADIUS * 0.92, 0.0, TAU, 128, GOLD, 6.0, true)
		for i in 12:
			var a := TAU * i / 12.0 - PI * 0.5
			Toon.star(ring, BADGE + Vector2(cos(a), sin(a)) * RADIUS * 0.92, 20.0, a, GOLD))
	add_child(ring)


## The title card: the name on a ribbon, the brothers under it on a pool of
## light, the double rule round the edge.
func _splash() -> void:
	var card := Node2D.new()
	card.draw.connect(func() -> void:
		card.draw_rect(Rect2(0, 0, 1920, 1080), SEPIA)
		for i in 36:
			var a0 := TAU * i / 36.0
			var a1 := a0 + TAU * 0.5 / 36.0
			card.draw_polygon(PackedVector2Array([Vector2(960, 470), Vector2(960, 470) + Vector2(cos(a0), sin(a0)) * 1500.0,
					Vector2(960, 470) + Vector2(cos(a1), sin(a1)) * 1500.0]),
					PackedColorArray([Color(CREAM, 0.08), Color(CREAM, 0.0), Color(CREAM, 0.0)]))
		Toon.glow(card, Vector2(960, 560), Vector2(620, 380), Color(1, 0.9, 0.7, 0.14), 3)
		Frames.double_rule(card, Rect2(50, 50, 1820, 980))
		Toon.glow(card, Vector2(960, 842), Vector2(360, 44), Color(0, 0, 0, 0.6), 2)
		var width := Ui.title_font().get_string_size("БРАТЬЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 200).x
		Frames.ribbon(card, Vector2(960, 250), width + 160.0, 230.0)
		for side: float in [-1.0, 1.0]:
			Toon.star(card, Vector2(960 + side * (width * 0.5 + 200.0), 250), 30.0, 0.0, GOLD))
	add_child(card)
	var title := Ui.label("БРАТЬЯ", Ui.title(200), 1920)
	title.size = Vector2(1920, 320)
	title.position = Vector2(0, 90)
	add_child(title)
	add_child(_figure("older", Vector2(820, 840), 2.4, Vector2.RIGHT))
	add_child(_figure("younger", Vector2(1100, 840), 2.4, Vector2.LEFT))


func _figure(id: String, at: Vector2, size: float, face := Vector2.DOWN) -> BrotherLook:
	var look := BrotherLook.new()
	look.configure(GameData.character(id).get("look", {}))
	look.position = at
	look.scale = Vector2(size, size)
	look.facing = face
	# Still, so the picture is the same every time it is made.
	look.set_process(false)
	look.ready.connect(func() -> void:
		# And not caught blinking.
		while Toon.hash01(look._drawing, look._seed) < 0.03:
			look._drawing += 1
		look.queue_redraw())
	return look


func _save() -> void:
	var image := get_viewport().get_texture().get_image()
	var scale := image.get_width() / 1920.0
	var path := ""
	if _mode == "icon":
		var side := int((RADIUS * 2.0 + 16.0) * scale)
		var corner := Vector2i(int((BADGE.x - RADIUS - 8.0) * scale), int((BADGE.y - RADIUS - 8.0) * scale))
		image = image.get_region(Rect2i(corner, Vector2i(side, side)))
		image.resize(512, 512, Image.INTERPOLATE_LANCZOS)
		path = "res://icon.png"
	else:
		image.convert(Image.FORMAT_RGB8)
		path = "res://splash.png"
	var error := image.save_png(ProjectSettings.globalize_path(path))
	print("wrote %s: %s" % [path, "ok" if error == OK else str(error)])
	get_tree().quit(0 if error == OK else 1)
