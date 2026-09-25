class_name DeviceInput
extends PlayerInput
## A brother driven by a person: keyboard and gamepad through the actions
## [Controls] makes, under one prefix per player.

const DIRECTIONS := {
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT,
	"up": Vector2.UP,
	"down": Vector2.DOWN,
}

var prefix := "p1_"
## Shooting keys held, oldest first. As in Isaac, the latest one pressed wins:
## holding right and tapping up shoots up, and letting go of up goes back to
## shooting right.
var _held: Array[String] = []


func _init(action_prefix := "p1_") -> void:
	prefix = action_prefix


func update(_brother: Brother, _delta: float) -> void:
	move = Input.get_vector(prefix + "left", prefix + "right", prefix + "up", prefix + "down")
	for direction: String in DIRECTIONS:
		var action := prefix + "shoot_" + direction
		if Input.is_action_pressed(action):
			if not _held.has(direction):
				_held.append(direction)
		else:
			_held.erase(direction)
	shoot = DIRECTIONS[_held.back()] if not _held.is_empty() else Vector2.ZERO
	bomb = Input.is_action_just_pressed(prefix + "bomb")
