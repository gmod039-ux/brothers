class_name Hud
extends Node2D
## Hearts in the top-left corner over the wall, as in Isaac, and the wave
## count at the top.

const RED := Color("d8412f")
const EMPTY := Color("4a2c22")
const HEART := 40.0

var brother: Brother:
	set(value):
		brother = value
		queue_redraw()

var _wave: Label
var _name: Label


func _ready() -> void:
	_wave = Ui.label("", Ui.text(36), 400)
	_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wave.position = Vector2(1920 - 64 - 400, 36)
	add_child(_wave)
	_name = Ui.label("", Ui.text(30), 400)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name.position = Vector2(64, 98)
	add_child(_name)


func set_wave(number: int, total: int) -> void:
	_wave.text = "Волна %d из %d" % [number, total]


func set_health(_hp: int, _max_hp: int) -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	if brother != null and _name.text != brother.display_name:
		_name.text = brother.display_name


func _draw() -> void:
	if brother == null:
		return
	var hearts := brother.stats.max_hp() / 2
	for i in hearts:
		var fill := clampi(brother.hp - i * 2, 0, 2)
		Toon.heart(self, Vector2(88 + i * 58, 66), HEART, fill, RED, EMPTY)
