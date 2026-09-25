extends Node2D
## The game as it stands: choose a brother, then fight the test room's waves.
## Dying or clearing the room ends the run; R starts another at once.
##
## Command line, after `--`:
##   brother older|younger  skip the choice
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
var iris: Iris
var film: Film
var select: BrotherSelect
var room: Room
var brother: Brother
var waves: Waves
var rng := RandomNumberGenerator.new()
var run_seed := 0
## "select", "play" or "over".
var state := ""
var chosen := "older"
var demo := false
var god := false

var _select_layer: CanvasLayer
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
	film = Film.new()
	film.strength = float(_arg("film", "1.0"))
	add_child(film)
	var shooter := preload("res://scripts/dev/screenshot.gd").new()
	shooter.name = "Screenshot"
	add_child(shooter)

	if _args.has("concepts"):
		_select_layer.add_child(preload("res://scripts/dev/concept_sheet.gd").new())
		return
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


func _arg(key: String, fallback: String) -> String:
	var at := _args.find(key)
	return _args[at + 1] if at >= 0 and at + 1 < _args.size() else fallback


func show_select() -> void:
	state = "select"
	get_tree().paused = false
	banner.clear()
	_clear_world()
	hud.visible = false
	select = BrotherSelect.new()
	_select_layer.add_child(select)
	var index := BrotherSelect.IDS.find(chosen)
	select.select(maxi(index, 0))
	select.chosen.connect(_on_chosen)
	iris.open(camera.position, 0.6)


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
	_clear_world()
	room = Room.new()
	room.name = "Room"
	world.add_child(room)
	room.build(GameData.room_layout("arena"), seed_value)
	room.set_doors_open(false)
	brother = Brother.new()
	var input: PlayerInput = BotInput.new() if demo else DeviceInput.new("p1_")
	brother.setup(chosen, room, input)
	brother.god = god
	room.actors.add_child(brother)
	brother.global_position = room.tile_center(Vector2i(6, 4))
	room.brothers.append(brother)
	brother.health_changed.connect(hud.set_health)
	brother.hurt_taken.connect(_on_hurt)
	brother.died.connect(_on_died)
	hud.brother = brother
	hud.visible = true
	waves = Waves.new()
	room.add_child(waves)
	waves.wave_started.connect(_on_wave)
	waves.cleared.connect(_on_cleared)
	waves.begin(room, rng, GameData.waves("arena"))
	hud.set_wave(0, waves.list.size())
	_play_time = 0.0
	print("run: seed %d, %s" % [seed_value, chosen])
	iris.open(brother.global_position + Vector2(0, -60))


func _clear_world() -> void:
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	room = null
	brother = null
	waves = null


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
	waves.stop()
	var at := brother.global_position + Vector2(0, -40)
	await get_tree().create_timer(1.2).timeout
	if state != "over" or brother == null:
		return
	await iris.close(at, 0.8)
	get_tree().paused = true
	banner.say("Эх, братец…", "волна %d   ·   R — ещё раз   ·   Esc — выбрать брата" % waves.current, 0.0)


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
			banner.clear()
		else:
			get_tree().paused = true
			banner.say("Пауза", "Esc — дальше   ·   Enter — выбрать брата", 0.0)
	elif event.is_action_pressed("confirm") and get_tree().paused and state == "play":
		_restart(true)


## A new run, or back to choosing a brother, through the iris.
func _restart(to_select: bool) -> void:
	_busy = true
	get_tree().paused = false
	banner.clear()
	if not iris.is_closed():
		var at := brother.global_position + Vector2(0, -60) if brother != null else camera.position
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
	var kills := waves.kills if waves != null else 0
	print("autoplay: %.0f s, %s, waves %d/%d, knocked out %d, shots %d, hits taken %d, %s" % [
			seconds, chosen, waves.current if waves != null else 0,
			waves.list.size() if waves != null else 0, kills,
			brother.shots_fired if brother != null else 0,
			brother.damage_taken if brother != null else 0, state])
	get_tree().quit(0 if kills > 0 else 1)
