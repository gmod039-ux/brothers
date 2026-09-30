extends Node
## A cat on the keyboard: holds and taps every key the game knows at random,
## menus and all -- walking, shooting, bombs, the item in hand, the pause,
## the settings, starting again, going back to the poster -- to shake out
## the errors no tidy bot ever walks into. Not part of the game:
##
##     godot --headless --fixed-fps 60 --path . -- fuzz 7 autoplay 300
##
## The number after `fuzz` is its seed. Look for SCRIPT ERROR in what it
## prints.

const HOLD := ["p1_left", "p1_right", "p1_up", "p1_down", "p1_shoot_left", "p1_shoot_right",
		"p1_shoot_up", "p1_shoot_down"]
## Keys tapped now and then, with how often each comes up.
const TAP := [["p1_bomb", 3], ["p1_item", 3], ["pause", 2], ["confirm", 4], ["restart", 1],
		["menu_up", 3], ["menu_down", 3], ["menu_left", 2], ["menu_right", 2], ["menu_back", 1]]

var rng := RandomNumberGenerator.new()
## action -> frames left to hold it.
var _held := {}
## Events to let go of next frame.
var _release: Array[String] = []
var _taps := 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("fuzz")
	rng.seed = int(args[at + 1]) if at >= 0 and at + 1 < args.size() else 1


func _process(_delta: float) -> void:
	for action: String in _release:
		_event(action, false)
	_release.clear()
	for action: String in _held.keys():
		_held[action] -= 1
		if _held[action] <= 0:
			Input.action_release(action)
			_held.erase(action)
	if rng.randf() < 0.1:
		var action: String = HOLD[rng.randi() % HOLD.size()]
		if not _held.has(action):
			Input.action_press(action)
		_held[action] = rng.randi_range(8, 90)
	if rng.randf() < 0.025:
		var total := 0
		for tap: Array in TAP:
			total += int(tap[1])
		var pick := rng.randi() % total
		for tap: Array in TAP:
			pick -= int(tap[1])
			if pick < 0:
				_event(str(tap[0]), true)
				_release.append(str(tap[0]))
				_taps += 1
				break


func _exit_tree() -> void:
	print("fuzz: %d taps" % _taps)


func _event(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
