class_name Banner
extends Node2D
## Big lettering across the middle of the screen: "ВОЛНА 2", "ЧИСТО!", the
## pause and the end of a run. Pops in like a title card.

var _title: Label
var _sub: Label
var _tween: Tween


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_title = Ui.label("", Ui.title(128))
	_title.position = Vector2(0, 360)
	add_child(_title)
	_sub = Ui.label("", Ui.text(42))
	_sub.position = Vector2(0, 520)
	add_child(_sub)
	visible = false


## Shows [param text] with [param sub] under it for [param seconds]; 0 keeps
## it up until [method clear].
func say(text: String, sub := "", seconds := 1.4) -> void:
	_title.text = text
	_sub.text = sub
	visible = true
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
