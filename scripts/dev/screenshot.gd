extends Node
## Screenshots from a real run of the game, so "does it look right" can be
## answered without someone at the window.
##
##     godot --path . -- brother older demo shot dev/out/look.png [frames]
##     godot --path . -- brother older demo tour wait 200 dev/out/a.png film 0 dev/out/b.png
##
## A tour is one launch and many pictures: the window takes the screen and the
## keyboard for as long as it is up, so five looks are one launch, not five.
## Its words, in order:
##   wait N        let N frames pass
##   film X        set the old-film strength
##   press ACTION  press an input action for one frame (p1_right, confirm …)
##   hurt | die    hit the brother, or knock him out
##   bomb          drop a bomb at his feet
##   goto KIND     jump to the floor's shop, treasure room, boss room …
##   coins N       give him N coins
##   floor N       go down to floor N (1 is the first)
##   god on|off    whether hits cost anything
##   *.png         save the screen there
##
## Without `shot` or `tour` on the command line this node does nothing.

## The first picture waits this long: shaders compile on first use.
const FIRST_WAIT := 60


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("shot")
	if at >= 0:
		var path := args[at + 1] if args.size() > at + 1 else "dev/out/look.png"
		var frames := int(args[at + 2]) if args.size() > at + 2 and args[at + 2].is_valid_int() \
				else 120
		_single(path, frames)
		return
	at = args.find("tour")
	if at >= 0:
		_tour(args.slice(at + 1))


func _single(path: String, frames: int) -> void:
	await _frames(frames)
	get_tree().quit(0 if _save(path) else 1)


func _tour(words: PackedStringArray) -> void:
	await _frames(FIRST_WAIT)
	var main := get_parent()
	var failed := false
	var i := 0
	while i < words.size():
		var word := words[i]
		var value := words[i + 1] if i + 1 < words.size() else ""
		match word:
			"wait":
				await _frames(int(value))
				i += 2
			"film":
				(main.get("film") as Film).strength = float(value)
				i += 2
			"press":
				Input.action_press(value)
				await _frames(1)
				Input.action_release(value)
				var event := InputEventAction.new()
				event.action = value
				event.pressed = true
				Input.parse_input_event(event)
				await _frames(1)
				i += 2
			"hurt", "die":
				var brother := main.get("brother") as Brother
				if brother != null:
					if word == "die":
						brother.god = false
						brother.hp = 1
					brother.hurt(1, brother.global_position + Vector2(40, 0))
				i += 1
			"bomb":
				var bomber := main.get("brother") as Brother
				if bomber != null:
					bomber.bombs += 1
					bomber.place_bomb()
				i += 1
			"goto":
				var run := main.get("run") as Run
				if run != null:
					run.teleport(value)
				i += 2
			"floor":
				var run_down := main.get("run") as Run
				if run_down != null:
					while run_down.floor_index < int(value) - 1:
						run_down.descend()
				i += 2
			"coins":
				var rich := main.get("brother") as Brother
				if rich != null:
					rich.coins = int(value)
					rich.inventory_changed.emit()
				i += 2
			"god":
				var brother := main.get("brother") as Brother
				if brother != null:
					brother.god = value == "on"
				i += 2
			_:
				if word.ends_with(".png"):
					await _frames(2)
					failed = not _save(word) or failed
				else:
					printerr("tour: what is %s?" % word)
				i += 1
	get_tree().quit(1 if failed else 0)


func _frames(n: int) -> void:
	for _i in maxi(n, 1):
		await RenderingServer.frame_post_draw


func _save(path: String) -> bool:
	var image := get_viewport().get_texture().get_image()
	var absolute := path if path.begins_with("/") \
			else ProjectSettings.globalize_path("res://").path_join(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := image.save_png(absolute)
	if error == OK:
		print("wrote %s  (%d x %d)" % [path, image.get_width(), image.get_height()])
	else:
		printerr("could not write %s: %d" % [absolute, error])
	return error == OK
