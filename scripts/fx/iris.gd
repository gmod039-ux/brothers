class_name Iris
extends CanvasLayer
## The iris: the picture closes down to a circle on something and goes black,
## or opens up out of black. Used for the start of a run, a death and moving
## to a new floor.

## A radius that covers the whole screen from any point on it.
const OPEN := 2.1

var _rect: ColorRect
var _material: ShaderMaterial
var _tween: Tween
var _radius := OPEN


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/iris.gdshader")
	_rect.material = _material
	add_child(_rect)
	_set_radius(OPEN)


## Closes down on [param at], a point in the world. Await the result.
func close(at: Vector2, seconds := 0.9) -> Signal:
	return _run(at, OPEN, 0.0, seconds, Tween.EASE_IN)


## Opens out of black from [param at].
func open(at: Vector2, seconds := 0.8) -> Signal:
	return _run(at, 0.0, OPEN, seconds, Tween.EASE_OUT)


## Black at once, to open from afterwards.
func shut() -> void:
	if _tween != null:
		_tween.kill()
	_set_radius(0.0)


func _run(at: Vector2, from: float, to: float, seconds: float,
		easing: Tween.EaseType) -> Signal:
	if _tween != null:
		_tween.kill()
	var size := get_viewport().get_visible_rect().size
	var on_screen := get_viewport().get_canvas_transform() * at
	_material.set_shader_parameter("center", on_screen / size)
	_material.set_shader_parameter("aspect", size.x / size.y)
	_set_radius(from)
	_tween = create_tween()
	_tween.tween_method(_set_radius, from, to, seconds) \
			.set_trans(Tween.TRANS_QUAD).set_ease(easing)
	return _tween.finished


## Fully black.
func is_closed() -> bool:
	return _radius <= 0.0


func _set_radius(r: float) -> void:
	_radius = r
	_material.set_shader_parameter("radius", r)
	_rect.visible = r < OPEN
