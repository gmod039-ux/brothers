class_name Banner
extends Node2D
## Big lettering across the middle of the screen: "ВОЛНА 2", "ЧИСТО!", the
## pause and the end of a run. Pops in like a title card.

var _title: Label
var _sub: Label
var _tween: Tween
## The smaller line at the top: what was just picked up.
var _caption: Node2D
var _caption_title: Label
var _caption_sub: Label
var _caption_tween: Tween
## How the big lettering is dressed: "ribbon" (a red band behind it),
## "boss" (a slanted band of rays sliding across the screen, "Встречайте!"
## over it) or "knockout" (a starburst).
var _style := "ribbon"
## How far the boss band has slid in, 0 to 1.
var _slide := 1.0
var _clock := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_title = Ui.label("", Ui.title(128))
	_title.position = Vector2(0, 360)
	add_child(_title)
	_sub = Ui.label("", Ui.text(42))
	_sub.position = Vector2(0, 548)
	add_child(_sub)
	visible = false
	_caption = Node2D.new()
	_caption.draw.connect(_draw_caption)
	add_sibling.call_deferred(_caption)
	_caption_title = Ui.label("", Ui.title(64, Color("b8322a")))
	_caption_title.position = Vector2(0, 112)
	_caption.add_child(_caption_title)
	var sub_style := Ui.text(32, Toon.INK)
	sub_style.outline_size = 0
	_caption_sub = Ui.label("", sub_style)
	_caption_sub.position = Vector2(0, 190)
	_caption.add_child(_caption_sub)
	_caption.visible = false


## A smaller line at the top of the screen for a moment: the name of an item
## just picked up and what it does, the way Isaac shows it.
func caption(text: String, sub := "", seconds := 2.2) -> void:
	_caption_title.text = text
	_caption_title.label_settings.font_size = Ui.fit(text, 60, 1100.0)
	_caption_sub.text = sub
	_caption.visible = true
	_caption.queue_redraw()
	_caption.modulate.a = 1.0
	if _caption_tween != null:
		_caption_tween.kill()
	_caption_tween = create_tween()
	for step: float in [0.7, 1.1, 1.0]:
		_caption_tween.tween_callback(func() -> void: _caption_title.scale = Vector2(step, step))
		_caption_tween.tween_interval(1.0 / Toon.FPS)
	_caption_tween.tween_interval(seconds)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, 0.3)
	_caption_tween.tween_callback(func() -> void: _caption.visible = false)


## Shows [param text] with [param sub] under it for [param seconds]; 0 keeps
## it up until [method clear].
func say(text: String, sub := "", seconds := 1.4, style := "ribbon") -> void:
	_style = style
	_title.text = text
	_title.label_settings.font_size = Ui.fit(text, 128, 1500.0 if style == "boss" else 1300.0)
	_sub.text = sub
	_title.position = Vector2(0, 360)
	_sub.position = Vector2(0, 548)
	if style == "boss":
		_title.position = Vector2(0, 330)
		_sub.position = Vector2(0, 522)
	visible = true
	queue_redraw()
	if _tween != null:
		_tween.kill()
	_title.scale = Vector2(0.3, 0.3)
	modulate.a = 1.0
	_tween = create_tween()
	if style == "boss":
		# The band slides in from the left in three drawings, then the name
		# pops.
		_title.scale = Vector2.ZERO
		for step: float in [0.35, 0.8, 1.0]:
			_tween.tween_callback(func() -> void:
				_slide = step
				queue_redraw())
			_tween.tween_interval(1.0 / Toon.FPS)
	# Stepped, not smooth: a pop in three drawings.
	for step: float in [0.75, 1.15, 1.0]:
		_tween.tween_callback(func() -> void: _title.scale = Vector2(step, step))
		_tween.tween_interval(1.0 / Toon.FPS)
	if seconds > 0.0:
		_tween.tween_interval(seconds)
		_tween.tween_property(self, "modulate:a", 0.0, 0.25)
		_tween.tween_callback(func() -> void: visible = false)


func _process(delta: float) -> void:
	if visible and _style != "ribbon":
		_clock += delta
		queue_redraw()


func clear() -> void:
	if _tween != null:
		_tween.kill()
	visible = false


## A ribbon, a band or a starburst behind the big title.
func _draw() -> void:
	if _title == null or _title.text == "":
		return
	var width := Ui.title_font().get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_title.label_settings.font_size).x
	match _style:
		"boss":
			_boss_band(width)
		"knockout":
			_burst(Vector2(960, 462), width)
		_:
			Frames.ribbon(self, Vector2(960, 462), width + 140.0, 150.0)


## A slanted band across the screen, dark red with rays turning in it and
## gold rules along its edges; "Встречайте!" on a little ribbon over it.
func _boss_band(width: float) -> void:
	var shift := (1.0 - _slide) * -2200.0
	var band := PackedVector2Array([Vector2(-40 + shift, 300), Vector2(1960 + shift, 262),
			Vector2(1960 + shift, 648), Vector2(-40 + shift, 686)])
	draw_colored_polygon(Toon.grown(band, 8.0), Toon.INK)
	draw_colored_polygon(band, Color("6e1714"))
	var center := Vector2(960 + shift, 474)
	var rays := 30
	for i in rays:
		var a0 := TAU * i / rays + _clock * 0.25
		var a1 := a0 + TAU * 0.5 / rays
		var ray := PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * 1600.0,
				center + Vector2(cos(a1), sin(a1)) * 1600.0])
		for piece in Geometry2D.intersect_polygons(ray, band):
			draw_colored_polygon(piece, Color("8e2420"))
	Toon.glow(self, center, Vector2(620, 200), Color(1, 0.8, 0.5, 0.25), 3)
	for edge: Array in [[band[0], band[1]], [band[3], band[2]]]:
		var inward := Vector2(0, 14) if edge[0] == band[0] else Vector2(0, -14)
		draw_line(edge[0] + inward, edge[1] + inward, Frames.GOLD, 4.0, true)
	if _slide >= 1.0:
		Frames.ribbon(self, Vector2(960, 270), 420.0, 62.0, Frames.CREAM.darkened(0.1))
		var greet := "Встречайте!"
		var size := 40
		var at := Vector2(960 - Ui.font().get_string_size(greet, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, 284)
		draw_string(Ui.font(), at, greet, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Frames.RED)
		for side: float in [-1.0, 1.0]:
			Toon.star(self, Vector2(960 + side * (width * 0.5 + 90.0), 462), 26.0, _clock * side, Frames.GOLD)


## A starburst behind "НОКАУТ!": jagged, gold round red, turning a notch
## every drawing.
func _burst(center: Vector2, width: float) -> void:
	var d := int(_clock * Toon.FPS)
	for layer in 2:
		var points := PackedVector2Array()
		var n := 18
		var outer := Vector2(width * 0.72, 250.0) * (1.0 if layer == 0 else 0.8)
		var inner := outer * 0.62
		var turn := (d % 2) * PI / n
		for i in n * 2:
			var a := turn + PI * i / n
			var r := outer if i % 2 == 0 else inner
			points.append(center + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_colored_polygon(Toon.grown(points, 6.0), Toon.INK)
		draw_colored_polygon(points, Frames.GOLD if layer == 0 else Frames.RED)


## A scroll behind the name of an item.
func _draw_caption() -> void:
	if _caption_title.text == "":
		return
	var width := maxf(Ui.title_font().get_string_size(_caption_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_caption_title.label_settings.font_size).x,
			Ui.font().get_string_size(_caption_sub.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x)
	Frames.scroll(_caption, Vector2(960, 190), width + 120.0, 170.0)
