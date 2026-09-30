class_name Options
extends RefCounted
## The player's settings, kept between launches in user://options.cfg: how
## loud the gramophone and the sounds are, how old the film looks, whether
## the screen shakes, and whether the game fills the screen.
##
## Read once at start ([method load_file]); a change is heard or seen at
## once ([method apply_sound], Main for the rest) and written down when the
## settings card closes ([method save]).

const PATH := "user://options.cfg"

## 0 to 1, in tenths on the settings card.
static var music := 1.0
static var sounds := 1.0
## The old-film look: 0 is a clean picture.
static var film := 1.0
static var shake := true
static var fullscreen := false
## The last choice on the poster, to be there again next time.
static var brother := "older"
static var together := false


static func load_file() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	music = _level(config.get_value("sound", "music", music))
	sounds = _level(config.get_value("sound", "sounds", sounds))
	film = _level(config.get_value("screen", "film", film))
	shake = bool(config.get_value("screen", "shake", shake))
	fullscreen = bool(config.get_value("screen", "fullscreen", fullscreen))
	brother = str(config.get_value("choice", "brother", brother))
	if not brother in ["older", "younger"]:
		brother = "older"
	together = bool(config.get_value("choice", "together", together))


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("sound", "music", music)
	config.set_value("sound", "sounds", sounds)
	config.set_value("screen", "film", film)
	config.set_value("screen", "shake", shake)
	config.set_value("screen", "fullscreen", fullscreen)
	config.set_value("choice", "brother", brother)
	config.set_value("choice", "together", together)
	config.save(PATH)


## One setting by the name the settings card knows it by.
static func value(id: String) -> Variant:
	match id:
		"music": return music
		"sounds": return sounds
		"film": return film
		"shake": return shake
		"fullscreen": return fullscreen
	return null


static func set_value(id: String, v: Variant) -> void:
	match id:
		"music": music = _level(v)
		"sounds": sounds = _level(v)
		"film": film = _level(v)
		"shake": shake = bool(v)
		"fullscreen": fullscreen = bool(v)
	apply_sound()


## Turns the gramophone's bus and the sounds' bus to their settings. The
## ear hears loudness on a curve: a slider at half is a quarter of the
## power, which is what sounds like half.
static func apply_sound() -> void:
	_bus(Music.BUS, music)
	_bus(Sfx.BUS, sounds)


static func _bus(bus: String, level: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, level <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level * level, 0.0001)))


static func _level(v: Variant) -> float:
	return snappedf(clampf(float(v), 0.0, 1.0), 0.1)
