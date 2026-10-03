class_name Records
extends RefCounted
## What the player has done, kept between launches in user://records.cfg:
## how many runs, how many ways out and the quickest, the deepest floor
## reached. Shown on a board on the stage of the brother choice and on the
## card at the end of a run. The demo bot and screenshot tours leave it
## alone (Main decides).

## Where they are kept. The checks point it at a file of their own, so a
## check run on someone's own machine never touches their records.
static var path := "user://records.cfg"

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
## Which scenes between the floors have been shown, one bit each: they play
## the first time down each trapdoor, and from the settings after that.
static var interludes := 0
## The deeds done (see [Unlocks]), by id.
static var deeds: Array[String] = []
## Every item and trinket ever picked up, by id: the album shows these.
static var found: Array[String] = []
## Tallies for the album, by name: "minibosses", "secrets", "jackpots",
## "runs_older", "wins_younger"...
static var counts := {}


static func load_file() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	runs = int(config.get_value("runs", "runs", 0))
	wins = int(config.get_value("runs", "wins", 0))
	best_time = float(config.get_value("runs", "best_time", 0.0))
	deepest = int(config.get_value("runs", "deepest", 0))
	knockouts = int(config.get_value("runs", "knockouts", 0))
	bosses = int(config.get_value("runs", "bosses", 0))
	story_seen = bool(config.get_value("story", "seen", false))
	interludes = int(config.get_value("story", "interludes", 0))
	deeds.assign(config.get_value("unlocks", "deeds", []))
	found.assign(config.get_value("album", "found", []))
	counts = config.get_value("album", "counts", {})


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("runs", "runs", runs)
	config.set_value("runs", "wins", wins)
	config.set_value("runs", "best_time", best_time)
	config.set_value("runs", "deepest", deepest)
	config.set_value("runs", "knockouts", knockouts)
	config.set_value("runs", "bosses", bosses)
	config.set_value("story", "seen", story_seen)
	config.set_value("story", "interludes", interludes)
	config.set_value("unlocks", "deeds", deeds)
	config.set_value("album", "found", found)
	config.set_value("album", "counts", counts)
	config.save(path)


## One more of tally [param key], kept at once.
static func bump(key: String, by := 1) -> void:
	counts[key] = int(counts.get(key, 0)) + by
	save()


static func count(key: String) -> int:
	return int(counts.get(key, 0))


## An item or trinket picked up: in the album from now on. True the first
## time.
static func find(id: String) -> bool:
	if found.has(id):
		return false
	found.append(id)
	save()
	return true


## Writes down a run that has ended, played by [param who] (ids). Returns
## true when it was a way out quicker than any before.
static func add_run(won: bool, seconds: float, floor_reached: int, kos: int, beaten: int,
		who: Array[String] = []) -> bool:
	runs += 1
	for id in who:
		counts["runs_" + id] = int(counts.get("runs_" + id, 0)) + 1
		if won:
			counts["wins_" + id] = int(counts.get("wins_" + id, 0)) + 1
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
