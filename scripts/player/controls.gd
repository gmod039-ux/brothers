class_name Controls
extends RefCounted
## The input map, made in code rather than in project.godot: the second
## brother's controls are then the first one's with another prefix and
## another gamepad, not forty hand-written entries.
##
## Keys are physical keys, so WASD is WASD whatever layout the keyboard is
## switched to -- with Russian on, the letters under those keys are ЦФЫВ.
##
## Alone, a brother answers to the keyboard and every gamepad. Two brothers
## share out the devices ([method assign]): the second always has a gamepad
## of his own, since two people cannot play a twin-stick game on one
## keyboard.

const DEADZONE := 0.45
## A device number that is no gamepad at all.
const NO_PAD := -2


static func setup() -> void:
	if InputMap.has_action("p1_left"):
		return
	_player("p1_", -1, true)
	_action("restart", [KEY_R], [])
	_action("pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_action("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [JOY_BUTTON_A])
	_action("fullscreen", [KEY_F11], [])
	# Menus: either set of keys, the d-pad or the left stick.
	_action("menu_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], -1, JOY_AXIS_LEFT_Y, -1.0)
	_action("menu_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], -1, JOY_AXIS_LEFT_Y, 1.0)
	_action("menu_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], -1, JOY_AXIS_LEFT_X, -1.0)
	_action("menu_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], -1, JOY_AXIS_LEFT_X, 1.0)
	_action("menu_back", [KEY_BACKSPACE], [JOY_BUTTON_B])


## The gamepads to play two brothers with: [first, second], a device number
## each, [constant NO_PAD] for the keyboard alone. Empty with no gamepad
## plugged in. With two pads each brother has one (and the first the
## keyboard too); with one, the first brother has the keyboard and the
## second the pad.
static func coop_pads() -> Array[int]:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return []
	if pads.size() == 1:
		return [NO_PAD, pads[0]]
	return [pads[0], pads[1]]


## Hands out the devices: to one brother everything, or to two as
## [method coop_pads] says. False when two were asked for and there is no
## gamepad for the second.
static func assign(two: bool) -> bool:
	var pads := coop_pads()
	if two and pads.is_empty():
		return false
	for prefix: String in ["p1_", "p2_"]:
		for action in InputMap.get_actions():
			if str(action).begins_with(prefix):
				InputMap.erase_action(action)
	if two:
		_player("p1_", pads[0], true)
		_player("p2_", pads[1], false)
	else:
		_player("p1_", -1, true)
	return true


## Actions for one brother: `<prefix>left` … for walking, `<prefix>shoot_left`
## … for shooting. [param device] -1 listens to every gamepad,
## [constant NO_PAD] to none; [param keys] gives him the keyboard as well.
static func _player(prefix: String, device: int, keys: bool) -> void:
	var k := func(key: Key) -> Array: return [key] if keys else []
	var pad := device != NO_PAD
	var b := func(button: JoyButton) -> Array: return [button] if pad else []
	var axis := func(a: JoyAxis) -> JoyAxis: return a if pad else JOY_AXIS_INVALID
	_action(prefix + "left", k.call(KEY_A), [], device, axis.call(JOY_AXIS_LEFT_X), -1.0)
	_action(prefix + "right", k.call(KEY_D), [], device, axis.call(JOY_AXIS_LEFT_X), 1.0)
	_action(prefix + "up", k.call(KEY_W), [], device, axis.call(JOY_AXIS_LEFT_Y), -1.0)
	_action(prefix + "down", k.call(KEY_S), [], device, axis.call(JOY_AXIS_LEFT_Y), 1.0)
	# Shooting as in Isaac: arrows, or the face buttons as four directions,
	# or the right stick.
	_action(prefix + "shoot_left", k.call(KEY_LEFT), b.call(JOY_BUTTON_X), device, axis.call(JOY_AXIS_RIGHT_X), -1.0)
	_action(prefix + "shoot_right", k.call(KEY_RIGHT), b.call(JOY_BUTTON_B), device, axis.call(JOY_AXIS_RIGHT_X), 1.0)
	_action(prefix + "shoot_up", k.call(KEY_UP), b.call(JOY_BUTTON_Y), device, axis.call(JOY_AXIS_RIGHT_Y), -1.0)
	_action(prefix + "shoot_down", k.call(KEY_DOWN), b.call(JOY_BUTTON_A), device, axis.call(JOY_AXIS_RIGHT_Y), 1.0)
	_action(prefix + "bomb", k.call(KEY_E), b.call(JOY_BUTTON_LEFT_SHOULDER), device)
	_action(prefix + "item", k.call(KEY_SPACE), b.call(JOY_BUTTON_RIGHT_SHOULDER), device)


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
