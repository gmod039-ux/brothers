class_name Settings
extends RefCounted
## What the player chose and the game keeps between launches: how loud the
## music and the sounds are, and whether the window takes the whole screen.
## Kept in user://settings.cfg; M and N go round the loudness steps.

const PATH := "user://settings.cfg"
## The steps M and N go round, loudest first.
const STEPS := [1.0, 0.75, 0.5, 0.25, 0.0]

static var music := 1.0
static var sounds := 1.0
static var fullscreen := false


static func load_saved() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	music = clampf(float(file.get_value("sound", "music", music)), 0.0, 1.0)
	sounds = clampf(float(file.get_value("sound", "sounds", sounds)), 0.0, 1.0)
	fullscreen = bool(file.get_value("window", "fullscreen", fullscreen))


static func save() -> void:
	var file := ConfigFile.new()
	file.set_value("sound", "music", music)
	file.set_value("sound", "sounds", sounds)
	file.set_value("window", "fullscreen", fullscreen)
	file.save(PATH)


## The next step down from [param level], and from silence back to loudest.
static func next_step(level: float) -> float:
	for step: float in STEPS:
		if step < level - 0.01:
			return step
	return STEPS[0]


## Sets the loudness of the bus called [param bus_name], if there is one:
## squared, so half way sounds half as loud rather than hardly quieter.
static func apply_to_bus(bus_name: String, level: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, level <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level * level, 0.0001)))


## "75%", or "выкл" for silence.
static func shown(level: float) -> String:
	return "выкл" if level <= 0.0 else "%d%%" % roundi(level * 100.0)
