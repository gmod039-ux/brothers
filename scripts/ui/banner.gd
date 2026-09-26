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
func say(text: String, sub := "", seconds := 1.4) -> void:
	_title.text = text
	_sub.text = sub
	visible = true
	queue_redraw()
	if _tween != null:
		_tween.kill()
	_title.scale = Vector2(0.3, 0.3)
	modulate.a = 1.0
	_tween = create_tween()
	# Stepped, not smooth: a pop in three drawings.
	for step: float in [0.75, 1.15, 1.0]:
		_tween.tween_callback(func() -> void: _title.scale = Vector2(step, step))
		_tween.tween_interval(1.0 / Toon.FPS)
	if seconds > 0.0:
		_tween.tween_interval(seconds)
		_tween.tween_property(self, "modulate:a", 0.0, 0.25)
		_tween.tween_callback(func() -> void: visible = false)


func clear() -> void:
	if _tween != null:
		_tween.kill()
	visible = false


## A ribbon behind the big title.
func _draw() -> void:
	if _title == null or _title.text == "":
		return
	var width := Ui.font().get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 128).x
	Frames.ribbon(self, Vector2(960, 462), width + 140.0, 150.0)


## A scroll behind the name of an item.
func _draw_caption() -> void:
	if _caption_title.text == "":
		return
	var width := maxf(Ui.font().get_string_size(_caption_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x,
			Ui.font().get_string_size(_caption_sub.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x)
	Frames.scroll(_caption, Vector2(960, 190), width + 120.0, 170.0)
