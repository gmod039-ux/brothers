extends Node2D
## The game as it stands: choose a brother, then go down through the floors
## of the basement -- rooms of enemies, a treasure room, a boss and a
## trapdoor on each. Dying or getting out ends the run; R starts another.
##
## Command line, after `--`:
##   brother older|younger  skip the choice
##   arena                  the old test room with its waves, not a floor
##   seed N                 the first run's seed
##   demo                   a bot plays (and cannot lose)
##   god                    hits cost nothing
##   film X                 strength of the old-film look, 0 to switch off
##   autoplay S             quit after S seconds of play, printing a summary
##   shot / tour …          screenshots, see scripts/dev/screenshot.gd

var world: Node2D
var camera: Camera2D
var hud: Hud
var banner: Banner
var intertitle: Intertitle
var iris: Iris
var film: Film
var select: BrotherSelect
var room: Room
var brother: Brother
var waves: Waves
var run: Run
var rng := RandomNumberGenerator.new()
var run_seed := 0
## "select", "play" or "over".
var state := ""
var chosen := "older"
var demo := false
var god := false

var _select_layer: CanvasLayer
var _flash: ColorRect
var _shake := 0.0
## Seconds of play in this run: game time, so it is right in fast checks
## and stops while paused.
var _play_time := 0.0
var _busy := false
var _args := PackedStringArray()


func _ready() -> void:
	Controls.setup()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_args = OS.get_cmdline_user_args()
	_fit_window()
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	camera = Camera2D.new()
	camera.position = Room.SIZE * 0.5
	add_child(camera)
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = Hud.new()
	hud_layer.add_child(hud)
	_select_layer = CanvasLayer.new()
	_select_layer.layer = 12
	add_child(_select_layer)
	iris = Iris.new()
	add_child(iris)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 25
	add_child(ui_layer)
	banner = Banner.new()
	ui_layer.add_child(banner)
	var card_layer := CanvasLayer.new()
	card_layer.layer = 30
	add_child(card_layer)
	intertitle = Intertitle.new()
	card_layer.add_child(intertitle)
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 18
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	flash_layer.add_child(_flash)
	Fx.on_flash = _screen_flash
	Fx.on_shake = func(seconds: float) -> void: _shake = maxf(_shake, seconds)
	film = Film.new()
	film.strength = float(_arg("film", "1.0"))
	add_child(film)
	add_child(Sfx.new())
	var music := Music.new()
	music.enabled = not _args.has("mute") and DisplayServer.get_name() != "headless"
	add_child(music)
	var shooter := preload("res://scripts/dev/screenshot.gd").new()
	shooter.name = "Screenshot"
	add_child(shooter)

	if _args.has("concepts"):
		_select_layer.add_child(preload("res://scripts/dev/concept_sheet.gd").new())
		return
	if _args.has("bestiary"):
		_select_layer.add_child(preload("res://scripts/dev/bestiary.gd").new())
		return
	if _args.has("textures"):
		Room.texture_variant = int(_arg("textures", "0"))
	demo = _args.has("demo")
	god = _args.has("god") or demo
	var first_seed := int(_arg("seed", str(randi() % 1000000)))
	if _args.has("brother"):
		chosen = _arg("brother", chosen)
		start_run(first_seed)
	else:
		show_select()
	if _args.has("autoplay"):
		_autoplay(float(_arg("autoplay", "60")))
	if _args.has("watch"):
		add_child(load("res://dev/watch.gd").new())


## A window of 1280 by 720 is 1280 by 720 pixels, and on a Retina screen
## that is under half its width: the brothers came out the size of a
## fingernail. So the window takes most of the screen it opens on, 16:9,
## centred. Screenshots and anything given a --resolution keep theirs.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--resolution"):
		return
	if _args.has("shot") or _args.has("tour"):
		return
	var screen := DisplayServer.window_get_current_screen()
	var area := DisplayServer.screen_get_usable_rect(screen)
	var width := mini(int(area.size.x * 0.9), int(area.size.y * 0.9 * 16.0 / 9.0))
	var size := Vector2i(width, int(width * 9.0 / 16.0))
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(area.position + (area.size - size) / 2)


## The whole screen flashes a colour for a moment: a boss losing his temper.
func _screen_flash(color: Color, seconds: float) -> void:
	_flash.color = Color(color, 0.55)
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, seconds)


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_fit_window()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _input(event: InputEvent) -> void:
	# Before anything else gets it, in every state, the menu included.
	if event.is_action_pressed("fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


## Static references die last, after the engine has already taken down what
## they point at: a Callable into this node left in Fx made Godot abort on
## every quit ("recursive_mutex lock failed"), and macOS showed a crash
## report each time. So they are all let go of here, while things still
## stand.
func _exit_tree() -> void:
	Fx.on_flash = Callable()
	Fx.on_shake = Callable()
	Ui.release()
	RoomProps.release()


func _arg(key: String, fallback: String) -> String:
	var at := _args.find(key)
	return _args[at + 1] if at >= 0 and at + 1 < _args.size() else fallback


func show_select() -> void:
	state = "select"
	get_tree().paused = false
	banner.clear()
	intertitle.hide_card()
	_clear_world()
	hud.visible = false
	select = BrotherSelect.new()
	_select_layer.add_child(select)
	var index := BrotherSelect.IDS.find(chosen)
	select.select(maxi(index, 0))
	select.chosen.connect(_on_chosen)
	iris.open(camera.position, 0.6)
	Music.play("menu")


func _on_chosen(id: String) -> void:
	chosen = id
	await iris.close(select.SPOTS[select.index] + Vector2(0, -150), 0.7)
	select.queue_free()
	select = null
	start_run(randi() % 1000000)


func start_run(seed_value: int) -> void:
	state = "play"
	run_seed = seed_value
	rng.seed = seed_value
	get_tree().paused = false
	banner.clear()
	intertitle.hide_card()
	_clear_world()
	brother = Brother.new()
	var input: PlayerInput = BotInput.new() if demo else DeviceInput.new("p1_")
	brother.setup(chosen, null, input)
	brother.god = god
	brother.health_changed.connect(hud.set_health)
	brother.hurt_taken.connect(_on_hurt)
	brother.died.connect(_on_died)
	brother.inventory_changed.connect(hud.queue_redraw)
	brother.item_taken.connect(func(id: String) -> void:
		var item: Dictionary = GameData.items().get(id, {})
		banner.caption(str(item.get("name", id)), str(item.get("text", ""))))
	hud.brother = brother
	hud.visible = true
	if _args.has("arena"):
		_start_arena()
	else:
		run = Run.new()
		run.name = "Run"
		world.add_child(run)
		run.floor_started.connect(_on_floor)
		run.map_changed.connect(hud.queue_redraw)
		run.bosses_appeared.connect(_on_bosses)
		run.boss_beaten.connect(_on_boss_beaten)
		run.trapdoor_entered.connect(_descend)
		run.unlocked.connect(hud.queue_redraw)
		var brothers: Array[Brother] = [brother]
		if _args.has("verbose"):
			run.room_entered.connect(func(info: FloorPlan.RoomInfo) -> void:
				print("%6.1f s  enter %s %s (%s)" % [_play_time, info.kind, info.cell, info.layout_name]))
			run.room_cleared.connect(func(info: FloorPlan.RoomInfo) -> void:
				print("%6.1f s  cleared %s" % [_play_time, info.cell]))
		run.begin(rng, camera, brothers)
		room = run.room
	hud.run = run
	_play_time = 0.0
	print("run: seed %d, %s" % [seed_value, chosen])
	iris.open(brother.global_position + Vector2(0, -60))


## The test room of the first days: one room, waves of enemies. Kept for
## trying out enemies and numbers without a floor round them.
func _start_arena() -> void:
	room = Room.new()
	room.name = "Room"
	world.add_child(room)
	room.build(GameData.room_layout("arena"), run_seed,
			{"top": "normal", "right": "normal", "bottom": "normal", "left": "normal"})
	room.set_doors_open(false)
	room.actors.add_child(brother)
	brother.room = room
	brother.global_position = room.tile_center(Vector2i(6, 4))
	room.brothers.append(brother)
	waves = Waves.new()
	room.add_child(waves)
	waves.wave_started.connect(_on_wave)
	waves.cleared.connect(_on_cleared)
	waves.begin(room, rng, GameData.waves("arena"))
	Music.play("floor0")
	hud.set_wave(0, waves.list.size())


func _on_floor(index: int) -> void:
	room = run.room
	Music.play("floor%d" % clampi(index, 0, 2))
	banner.say(run.floor_name(), "этаж %d из %d" % [index + 1, Run.FLOORS])


func _on_bosses(bosses: Array[Boss]) -> void:
	hud.bosses = bosses
	Music.play("boss")
	Sfx.play("roar", 0.0, 0.0)
	var names: Array[String] = []
	for boss in bosses:
		boss.stomped.connect(func() -> void: _shake = 0.3)
		names.append(boss.title)
	var sub := bosses[0].subtitle if bosses.size() == 1 else "оба разом!"
	banner.say(" и ".join(names), sub, Run.BOSS_INTRO - 0.25, "boss")


func _on_boss_beaten(_boss: Enemy) -> void:
	hud.bosses = []
	Music.play("floor%d" % clampi(run.floor_index, 0, 2))
	Sfx.play("blast", -2.0)
	Sfx.play("item", 0.0, 0.0)
	_shake = 0.4
	var sub := "люк открыт — вниз!" if not run.is_last_floor() else "люк открыт — на волю!"
	banner.say("НОКАУТ!", sub, 2.2, "knockout")
	print("boss beaten on floor %d at %.0f s" % [run.floor_index + 1, _play_time])


## Down the trapdoor: through the iris to the next floor, or out.
func _descend() -> void:
	if _busy or state != "play":
		return
	_busy = true
	run.busy = true
	Sfx.play("whistle_down", 0.0, 0.0)
	await iris.close(brother.global_position + Vector2(0, -60), 0.7)
	if run.is_last_floor():
		_busy = false
		_finish()
		return
	run.descend()
	room = run.room
	iris.open(brother.global_position + Vector2(0, -60))
	_busy = false


func _finish() -> void:
	state = "over"
	Music.play("menu")
	get_tree().paused = true
	var seconds := _play_time
	intertitle.show_card("won", "Выбрались!", _run_lines(),
			"R — ещё раз   ·   Esc — выбрать брата", _look(), _items())
	print("finished in %.1f s" % seconds)


## The numbers of the run for the card at its end.
func _run_lines() -> PackedStringArray:
	var seconds := int(_play_time)
	var lines := PackedStringArray()
	if run != null:
		lines.append("%s, этаж %d из %d   ·   комнат пройдено: %d" % [run.floor_name(), run.floor_index + 1,
				Run.FLOORS, run.rooms_cleared])
		lines.append("нокаутов: %d   ·   боссов: %d   ·   время %d:%02d" % [run.kills, run.bosses_beaten,
				seconds / 60, seconds % 60])
	elif waves != null:
		lines.append("волна %d   ·   время %d:%02d" % [waves.current, seconds / 60, seconds % 60])
	lines.append("забег №%d" % run_seed)
	return lines


func _look() -> Dictionary:
	return GameData.character(chosen).get("look", {})


func _items() -> Array[String]:
	return brother.items if brother != null else ([] as Array[String])


func _clear_world() -> void:
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	room = null
	brother = null
	waves = null
	run = null
	if hud != null:
		hud.run = null
		hud.bosses = []


func _on_wave(number: int, total: int) -> void:
	hud.set_wave(number, total)
	banner.say("Волна %d" % number, "из %d" % total if number < total else "последняя!")


func _on_cleared() -> void:
	state = "over"
	room.set_doors_open(true)
	var seconds := _play_time
	banner.say("Чисто!", "за %d:%02d   ·   R — ещё раз" % [int(seconds) / 60, int(seconds) % 60], 0.0)
	print("cleared in %.1f s" % seconds)


func _on_hurt() -> void:
	_shake = 0.25


func _on_died() -> void:
	state = "over"
	if waves != null:
		waves.stop()
	var at := brother.global_position + Vector2(0, -40)
	await get_tree().create_timer(1.2).timeout
	if state != "over" or brother == null:
		return
	await iris.close(at, 0.8)
	get_tree().paused = true
	Music.stop()
	intertitle.show_card("dead", "Эх, братец…", _run_lines(),
			"R — ещё раз   ·   Esc — выбрать брата", _look(), _items())


func _unhandled_input(event: InputEvent) -> void:
	if _busy or state == "select":
		return
	if event.is_action_pressed("restart"):
		_restart(false)
	elif event.is_action_pressed("pause"):
		if state == "over":
			_restart(true)
		elif get_tree().paused:
			get_tree().paused = false
			intertitle.hide_card()
		else:
			get_tree().paused = true
			intertitle.show_card("pause", "Пауза", PackedStringArray(["Esc — дальше", "R — заново",
					"Enter — выбрать брата"]), "", {}, _items())
	elif event.is_action_pressed("confirm") and get_tree().paused and state == "play":
		_restart(true)


## A new run, or back to choosing a brother, through the iris.
func _restart(to_select: bool) -> void:
	_busy = true
	get_tree().paused = false
	banner.clear()
	intertitle.hide_card()
	if not iris.is_closed():
		var at := brother.global_position + Vector2(0, -60) if brother != null else camera.position + Vector2.ZERO
		await iris.close(at, 0.5)
	if to_select:
		show_select()
	else:
		start_run(randi() % 1000000)
	_busy = false


func _process(delta: float) -> void:
	if state == "play" and not get_tree().paused:
		_play_time += delta
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		var k := _shake / 0.25
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 12.0 * k
	else:
		camera.offset = Vector2.ZERO


## Plays for [param seconds], prints what happened and quits: a whole run
## with nobody at the keyboard, for the checks. Fails when the bot knocked
## nobody out -- something between shooting and hitting is broken.
func _autoplay(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout
	var kills := 0
	if waves != null:
		kills = waves.kills
		print("autoplay: %.0f s, %s, waves %d/%d, knocked out %d, shots %d, hits taken %d, %s" % [
				seconds, chosen, waves.current, waves.list.size(), kills,
				brother.shots_fired if brother != null else 0,
				brother.damage_taken if brother != null else 0, state])
	elif run != null:
		kills = run.kills
		var visited := 0
		for info: FloorPlan.RoomInfo in run.plan.rooms.values():
			if info.visited:
				visited += 1
		print("autoplay: %.0f s, %s, floor %d, rooms %d/%d visited, %d cleared, bosses %d, knocked out %d, shots %d, %s" % [
				seconds, chosen, run.floor_index + 1, visited, run.plan.rooms.size(), run.rooms_cleared,
				run.bosses_beaten, kills, brother.shots_fired if brother != null else 0, state])
	# `need_bosses N`: the run must also have got past that many bosses.
	var bosses := run.bosses_beaten if run != null else 0
	var needed := int(_arg("need_bosses", "0"))
	if bosses < needed:
		printerr("autoplay: %d bosses beaten, %d needed" % [bosses, needed])
	get_tree().quit(0 if kills > 0 and bosses >= needed else 1)
