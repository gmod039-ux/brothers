class_name Controls
extends RefCounted
## The input map, made in code rather than in project.godot: the second
## brother's controls are then the first one's with another prefix and
## another gamepad, not forty hand-written entries.
##
## Keys are physical keys, so WASD is WASD whatever layout the keyboard is
## switched to -- with Russian on, the letters under those keys are ЦФЫВ.

const DEADZONE := 0.45


static func setup() -> void:
	if InputMap.has_action("p1_left"):
		return
	_player("p1_", -1)
	_action("restart", [KEY_R], [])
	_action("pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [JOY_BUTTON_A])


## Actions for one brother: `<prefix>left` … for walking, `<prefix>shoot_left`
## … for shooting. [param device] -1 listens to every gamepad.
static func _player(prefix: String, device: int) -> void:
	_action(prefix + "left", [KEY_A], [], device, JOY_AXIS_LEFT_X, -1.0)
	_action(prefix + "right", [KEY_D], [], device, JOY_AXIS_LEFT_X, 1.0)
	_action(prefix + "up", [KEY_W], [], device, JOY_AXIS_LEFT_Y, -1.0)
	_action(prefix + "down", [KEY_S], [], device, JOY_AXIS_LEFT_Y, 1.0)
	# Shooting as in Isaac: arrows, or the face buttons as four directions,
	# or the right stick.
	_action(prefix + "shoot_left", [KEY_LEFT], [JOY_BUTTON_X], device, JOY_AXIS_RIGHT_X, -1.0)
	_action(prefix + "shoot_right", [KEY_RIGHT], [JOY_BUTTON_B], device, JOY_AXIS_RIGHT_X, 1.0)
	_action(prefix + "shoot_up", [KEY_UP], [JOY_BUTTON_Y], device, JOY_AXIS_RIGHT_Y, -1.0)
	_action(prefix + "shoot_down", [KEY_DOWN], [JOY_BUTTON_A], device, JOY_AXIS_RIGHT_Y, 1.0)
	_action(prefix + "bomb", [KEY_E], [JOY_BUTTON_LEFT_SHOULDER], device)
	_action(prefix + "item", [KEY_SPACE], [JOY_BUTTON_RIGHT_SHOULDER], device)


static func _action(action: String, keys: Array, buttons: Array, device := -1,
		axis := JOY_AXIS_INVALID, direction := 0.0) -> void:
	InputMap.add_action(action, DEADZONE)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button: JoyButton in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.device = device
		InputMap.action_add_event(action, event)
	if axis != JOY_AXIS_INVALID:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = direction
		event.device = device
		InputMap.action_add_event(action, event)
