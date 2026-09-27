extends Node2D
## The game as it stands: choose a brother, then go down through the floors
## of the basement -- rooms of enemies, a treasure room, a boss and a
## trapdoor on each. Dying or getting out ends the run; R starts another.
##
## Command line, after `--`:
##   brother older|younger  skip the choice
##   coop                   both brothers, the second on a gamepad (or a
##                          second bot in the demo)
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
## The card of choices up now (the pause, or the settings over it), or null.
var menu: CardMenu
var room: Room
## The first player's brother; in co-op [member brothers] has both.
var brother: Brother
var brothers: Array[Brother] = []
## Both brothers play: the second on a gamepad of his own.
var coop := false
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
var _menu_layer: CanvasLayer
var _story_layer: CanvasLayer
## Runs go into the records: not the bot's, not a screenshot tour's.
var _recording := true
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
	Options.load_file()
	Records.load_file()
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
	_story_layer = CanvasLayer.new()
	_story_layer.layer = 35
	add_child(_story_layer)
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 40
	add_child(_menu_layer)
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
	film.strength = float(_arg("film", str(Options.film)))
	add_child(film)
	add_child(Sfx.new())
	var music := Music.new()
	music.enabled = not _args.has("mute") and DisplayServer.get_name() != "headless"
	add_child(music)
	Options.apply_sound()
	var shooter := preload("res://scripts/dev/screenshot.gd").new()
	shooter.name = "Screenshot"
	add_child(shooter)

	# The dev sheets: pictures only, no game behind them. Esc closes them.
	if _args.has("concepts"):
		state = "sheet"
		_select_layer.add_child(preload("res://scripts/dev/concept_sheet.gd").new())
		return
	if _args.has("bestiary"):
		state = "sheet"
		_select_layer.add_child(preload("res://scripts/dev/bestiary.gd").new())
		return
	if _args.has("textures"):
		Room.texture_variant = int(_arg("textures", "0"))
	demo = _args.has("demo")
	god = _args.has("god") or demo
	_recording = not demo and not _args.has("tour") and not _args.has("shot")
	var first_seed := int(_arg("seed", str(randi() % 1000000)))
	coop = _args.has("coop")
	if _args.has("brother"):
		chosen = _arg("brother", chosen)
		start_run(first_seed)
	elif _args.has("story") or (_recording and not Records.story_seen):
		# The first time, the story of the picture before anything else.
		state = "story"
		play_story(Story.OPENING).connect(func() -> void:
			Records.story_seen = true
			if _recording:
				Records.save()
			show_select())
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
	if Options.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
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
	_set_fullscreen(mode != DisplayServer.WINDOW_MODE_FULLSCREEN
			and mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	Options.save()
	if menu != null:
		menu.set_value("fullscreen", Options.fullscreen)


func _set_fullscreen(on: bool) -> void:
	Options.fullscreen = on
	if DisplayServer.get_name() == "headless":
		return
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_fit_window()


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
	_dismiss_menus()
	_clear_world()
	hud.visible = false
	select = BrotherSelect.new()
	_select_layer.add_child(select)
	var index := BrotherSelect.IDS.find(chosen)
	select.select(maxi(index, 0))
	select.together = coop
	select.chosen.connect(_on_chosen)
	select.options_wanted.connect(func() -> void:
		select.active = false
		_open_options(true).closed.connect(func() -> void:
			if select != null and not _story_layer.get_child_count():
				select.wake()))
	iris.open(camera.position, 0.6)
	Music.play("menu")


func _on_chosen(id: String, both: bool) -> void:
	chosen = id
	coop = both
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
	var two := coop and not _args.has("arena")
	if not demo and not Controls.assign(two):
		# No gamepad for the second brother: alone, then.
		two = false
		Controls.assign(false)
		banner.caption("Второму брату нужен геймпад", "подключи и выбери «вдвоём» снова", 3.0)
	var ids: Array[String] = [chosen]
	if two:
		ids.append(BrotherSelect.IDS[1 - BrotherSelect.IDS.find(chosen)])
	brothers.clear()
	for i in ids.size():
		var one := Brother.new()
		var input: PlayerInput = BotInput.new() if demo else DeviceInput.new("p%d_" % (i + 1))
		one.setup(ids[i], null, input)
		one.player = i + 1
		one.god = god
		if i > 0:
			one.purse = brothers[0].purse
		one.health_changed.connect(hud.set_health)
		one.hurt_taken.connect(_on_hurt)
		one.died.connect(_on_died)
		one.revived.connect(func() -> void: banner.caption("Братец снова в строю!", "", 1.6))
		one.inventory_changed.connect(hud.queue_redraw)
		one.item_taken.connect(func(id: String) -> void:
			var item: Dictionary = GameData.items().get(id, {})
			banner.caption(str(item.get("name", id)), str(item.get("text", ""))))
		brothers.append(one)
	brother = brothers[0]
	hud.brothers = brothers.duplicate()
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
		if _args.has("verbose"):
			run.room_entered.connect(func(info: FloorPlan.RoomInfo) -> void:
				print("%6.1f s  enter %s %s (%s)" % [_play_time, info.kind, info.cell, info.layout_name]))
			run.room_cleared.connect(func(info: FloorPlan.RoomInfo) -> void:
				print("%6.1f s  cleared %s" % [_play_time, info.cell]))
		run.begin(rng, camera, brothers.duplicate())
		room = run.room
	hud.run = run
	_play_time = 0.0
	print("run: seed %d, %s" % [seed_value, " + ".join(ids)])
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
	banner.say("НОКАУТ!", sub, 1.1, "knockout")
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
	get_tree().paused = true
	var seconds := _play_time
	var best := _record(true)
	if _recording and run != null:
		# The girls are free: the end of the picture, before the numbers.
		await play_story(Story.ENDING)
	Music.play("menu")
	var lines := _run_lines()
	if best:
		lines.append("новый рекорд — быстрее всех!")
	elif Records.best_time > 0.0 and _recording:
		lines.append("рекорд — %s" % Records.clock(Records.best_time))
	intertitle.show_card("won", "Выбрались!", lines, _over_hint(), _looks(), _items())
	print("finished in %.1f s" % seconds)


## Plays [param shots] of the story over everything. Await the signal it
## returns for the end of it, skipped or not.
func play_story(shots: Array[Dictionary]) -> Signal:
	var story := Story.new()
	story.shots = shots
	_story_layer.add_child(story)
	return story.finished


## R, Enter or A: another run; Esc or Start: back to the brothers.
func _over_hint() -> String:
	return "R, Enter — ещё раз   ·   Esc — выбрать брата"


## Writes the run that has just ended into the records. True when it was
## the quickest way out yet.
func _record(won: bool) -> bool:
	if not _recording or run == null:
		return false
	return Records.add_run(won, _play_time, run.floor_index + 1, run.kills, run.bosses_beaten)


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


## How the brothers look, for the figures on the card at the end.
func _looks() -> Array[Dictionary]:
	var looks: Array[Dictionary] = []
	for one in brothers:
		looks.append(GameData.character(one.id).get("look", {}))
	if looks.is_empty():
		looks.append(GameData.character(chosen).get("look", {}))
	return looks


## Every item the brothers have, the first one's first.
func _items() -> Array[String]:
	var all: Array[String] = []
	for one in brothers:
		all.append_array(one.items)
	return all


func _clear_world() -> void:
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	room = null
	brother = null
	brothers.clear()
	waves = null
	run = null
	if hud != null:
		hud.run = null
		hud.bosses = []
		hud.brothers = []


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
	for one in brothers:
		if not one.dead:
			# His brother is still up, and will get him up once the room is
			# clear.
			banner.caption("Братец в нокауте!", "расчисти комнату — и он встанет", 2.2)
			return
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
	_record(false)
	intertitle.show_card("dead", "Эх, братцы…" if brothers.size() > 1 else "Эх, братец…", _run_lines(),
			_over_hint(), _looks(), _items())


func _unhandled_input(event: InputEvent) -> void:
	if state == "sheet":
		if event.is_action_pressed("pause"):
			get_tree().quit()
		return
	if _busy or state == "select" or state == "story":
		return
	if event.is_action_pressed("restart"):
		_restart(false)
	elif event.is_action_pressed("pause"):
		if state == "over":
			_restart(true)
		elif not get_tree().paused:
			_pause()
	elif event.is_action_pressed("confirm") and state == "over" and intertitle.is_settled():
		_restart(false)


## The game stops under a card of choices.
func _pause() -> void:
	get_tree().paused = true
	Sfx.play("select", -4.0, 0.0)
	var card := CardMenu.new()
	card.title = "Пауза"
	card.lines = [
		{"id": "resume", "text": "Дальше"},
		{"id": "options", "text": "Настройки"},
		{"id": "restart", "text": "Заново"},
		{"id": "select", "text": "Выбрать брата"},
		{"id": "quit", "text": "Выйти из игры"},
	]
	card.items = _items()
	card.hint = "Esc — дальше   ·   R — заново"
	card.let_through = ["fullscreen", "restart"]
	card.picked.connect(_on_pause_pick.bind(card))
	card.closed.connect(_unpause)
	_menu_layer.add_child(card)
	menu = card


func _on_pause_pick(id: String, card: CardMenu) -> void:
	match id:
		"resume":
			_unpause()
		"options":
			card.active = false
			card.visible = false
			_open_options(false).closed.connect(func() -> void:
				if is_instance_valid(card):
					menu = card
					card.wake())
		"restart":
			_restart(false)
		"select":
			_restart(true)
		"quit":
			get_tree().quit()


func _unpause() -> void:
	_dismiss_menus()
	get_tree().paused = false


## The settings, over whatever is on screen. From the brother choice there
## are also the story and the way out of the game, which the pause has of
## its own.
func _open_options(from_select: bool) -> CardMenu:
	var card := CardMenu.new()
	card.title = "Настройки"
	card.lines = [
		{"id": "music", "text": "Музыка", "level": Options.music},
		{"id": "sounds", "text": "Звуки", "level": Options.sounds},
		{"id": "film", "text": "Старая плёнка", "level": Options.film},
		{"id": "shake", "text": "Тряска экрана", "toggle": Options.shake},
		{"id": "fullscreen", "text": "Во весь экран", "toggle": Options.fullscreen},
		{"id": "back", "text": "Назад"},
	]
	if from_select:
		card.lines.insert(card.lines.size() - 1, {"id": "story", "text": "Смотреть историю"})
		card.lines.append({"id": "quit", "text": "Выйти из игры"})
	card.hint = "← → менять   ·   Esc — назад"
	card.changed.connect(_on_option_changed)
	card.picked.connect(func(id: String) -> void:
		if id == "quit":
			get_tree().quit()
		elif id == "story":
			var story := play_story(Story.OPENING)
			card.close()
			story.connect(func() -> void:
				if select != null:
					select.wake())
		else:
			card.close())
	card.closed.connect(func() -> void:
		Options.save()
		if menu == card:
			menu = null)
	_menu_layer.add_child(card)
	menu = card
	return card


## A setting turned on the card: heard or seen at once.
func _on_option_changed(id: String, value: Variant) -> void:
	Options.set_value(id, value)
	match id:
		"film":
			film.strength = Options.film
		"fullscreen":
			_set_fullscreen(Options.fullscreen)
		"sounds":
			# A sample of how loud they are now.
			Sfx.play("coin", 0.0, 0.0)


## Takes down every card of choices, without the backing out they do on
## Esc.
func _dismiss_menus() -> void:
	for card: CardMenu in _menu_layer.get_children():
		card.active = false
		card.visible = false
		card.queue_free()
	menu = null


## A new run, or back to choosing a brother, through the iris.
func _restart(to_select: bool) -> void:
	_busy = true
	get_tree().paused = false
	banner.clear()
	intertitle.hide_card()
	_dismiss_menus()
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
		var k := _shake / 0.25 * (1.0 if Options.shake else 0.0)
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
		var shots := 0
		for one in brothers:
			shots += one.shots_fired
		var visited := 0
		for info: FloorPlan.RoomInfo in run.plan.rooms.values():
			if info.visited:
				visited += 1
		print("autoplay: %.0f s, %s, floor %d, rooms %d/%d visited, %d cleared, bosses %d, knocked out %d, shots %d, %s" % [
				seconds, chosen, run.floor_index + 1, visited, run.plan.rooms.size(), run.rooms_cleared,
				run.bosses_beaten, kills, shots, state])
	# `need_bosses N`: the run must also have got past that many bosses.
	var bosses := run.bosses_beaten if run != null else 0
	var needed := int(_arg("need_bosses", "0"))
	if bosses < needed:
		printerr("autoplay: %d bosses beaten, %d needed" % [bosses, needed])
	get_tree().quit(0 if kills > 0 and bosses >= needed else 1)
