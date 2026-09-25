class_name PlayerInput
extends RefCounted
## What a brother wants to do this frame: where to walk and which way to
## shoot. The brother only ever reads these two, so a keyboard, a gamepad, a
## bot or a test can all drive him.
##
## This base class is a puppet: whoever holds it sets [member move] and
## [member shoot] directly.

## Walking direction, length up to 1.
var move := Vector2.ZERO
## Shooting direction: one of the four axes, or zero for not shooting.
var shoot := Vector2.ZERO


func update(_brother: Brother, _delta: float) -> void:
	pass
