class_name Records
extends RefCounted
## What the player has done, kept between launches in user://records.cfg:
## how many runs, how many ways out and the quickest, the deepest floor
## reached. Shown on a board on the stage of the brother choice and on the
## card at the end of a run. The demo bot and screenshot tours leave it
## alone (Main decides).

const PATH := "user://records.cfg"

static var runs := 0
static var wins := 0
## Seconds of the quickest way out; 0 before the first.
static var best_time := 0.0
## The deepest floor reached, counted from 1.
static var deepest := 0
static var knockouts := 0
static var bosses := 0
## The story has been shown once: after that it waits for a key to skip.
static var story_seen := false


static func load_file() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	runs = int(config.get_value("runs", "runs", 0))
	wins = int(config.get_value("runs", "wins", 0))
	best_time = float(config.get_value("runs", "best_time", 0.0))
	deepest = int(config.get_value("runs", "deepest", 0))
	knockouts = int(config.get_value("runs", "knockouts", 0))
	bosses = int(config.get_value("runs", "bosses", 0))
	story_seen = bool(config.get_value("story", "seen", false))


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("runs", "runs", runs)
	config.set_value("runs", "wins", wins)
	config.set_value("runs", "best_time", best_time)
	config.set_value("runs", "deepest", deepest)
	config.set_value("runs", "knockouts", knockouts)
	config.set_value("runs", "bosses", bosses)
	config.set_value("story", "seen", story_seen)
	config.save(PATH)


## Writes down a run that has ended. Returns true when it was a way out
## quicker than any before.
static func add_run(won: bool, seconds: float, floor_reached: int, kos: int, beaten: int) -> bool:
	runs += 1
	deepest = maxi(deepest, floor_reached)
	knockouts += kos
	bosses += beaten
	var best := false
	if won:
		wins += 1
		best = best_time <= 0.0 or seconds < best_time
		if best:
			best_time = seconds
	save()
	return best


static func clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
