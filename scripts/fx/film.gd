class_name Film
extends CanvasLayer
## Old film over everything, the interface included: in the cartoons this
## game borrows its look from, the titles were on the same film as the rest.
##
## `strength` is the one knob: 0 is the clean picture, 1 the full effect.

const FILM_FPS := 24.0

var strength := 1.0:
	set(value):
		strength = value
		if _material != null:
			_material.set_shader_parameter("strength", value)
			_rect.visible = value > 0.0

var _material: ShaderMaterial
var _rect: ColorRect
var _clock := 0.0


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/film.gdshader")
	_rect.material = _material
	add_child(_rect)
	strength = strength


func _process(delta: float) -> void:
	# The projector keeps running while the game is paused.
	_clock += delta
	_material.set_shader_parameter("film_frame", floorf(_clock * FILM_FPS))
