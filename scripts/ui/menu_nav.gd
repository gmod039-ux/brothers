class_name MenuNav
extends RefCounted
## Steering a menu from anything: WASD or the arrows, a d-pad, the left
## stick. A press moves one step; held, it steps again after a moment and
## then quickly, the way a key repeats.
##
## Polled every frame rather than fed events, so a stick pushed over reads
## as one press and not as a stream of them.

const FIRST_REPEAT := 0.38
const REPEAT := 0.085

var _held := Vector2i.ZERO
var _wait := 0.0
## Nothing counts in the frame the menu was made in, or woken in: the press
## that opened it must not also act on it.
var _quiet_until := 0


func _init() -> void:
	hold()


## Ignores what is pressed in this frame.
func hold() -> void:
	_quiet_until = Engine.get_process_frames()


## The step to take this frame: one of the four directions, or zero.
func step(delta: float) -> Vector2i:
	if Engine.get_process_frames() <= _quiet_until:
		_held = direction()
		_wait = FIRST_REPEAT
		return Vector2i.ZERO
	var dir := direction()
	if dir == Vector2i.ZERO:
		_held = Vector2i.ZERO
		return Vector2i.ZERO
	if dir != _held:
		_held = dir
		_wait = FIRST_REPEAT
		return dir
	_wait -= delta
	if _wait <= 0.0:
		_wait += REPEAT
		return dir
	return Vector2i.ZERO


## [param action] went down this frame.
func pressed(action: String) -> bool:
	return Engine.get_process_frames() > _quiet_until and Input.is_action_just_pressed(action)


## Which way the menu keys are held now: up and down win over left and
## right when both are.
static func direction() -> Vector2i:
	var y := int(Input.is_action_pressed("menu_down")) - int(Input.is_action_pressed("menu_up"))
	if y != 0:
		return Vector2i(0, y)
	var x := int(Input.is_action_pressed("menu_right")) - int(Input.is_action_pressed("menu_left"))
	return Vector2i(x, 0)
