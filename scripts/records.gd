class_name Records
extends RefCounted
## The best each brother has done, kept between launches in
## user://records.cfg: the deepest floor he got to, how many times he got
## out, and his fastest way out. The card at the end of a run says it.

const PATH := "user://records.cfg"


## Writes down a run that has just ended and gives the line about it for the
## card: a new best, or the best to beat.
static func note(brother: String, won: bool, floor_reached: int, seconds: float) -> String:
	var file := ConfigFile.new()
	file.load(PATH)
	var deepest := int(file.get_value(brother, "deepest", 0))
	var wins := int(file.get_value(brother, "wins", 0))
	var best := float(file.get_value(brother, "best_time", 0.0))
	var line := ""
	if won:
		wins += 1
		if best <= 0.0:
			line = "первый раз на воле!"
			best = seconds
		elif seconds < best:
			line = "новый рекорд! было %s" % clock(best)
			best = seconds
		else:
			line = "рекорд %s   ·   побед: %d" % [clock(best), wins]
	elif floor_reached > deepest and deepest > 0:
		line = "так глубоко ещё не забирался!"
	elif wins > 0:
		line = "рекорд %s   ·   побед: %d" % [clock(best), wins]
	elif deepest > 0:
		line = "лучший забег: этаж %d из %d" % [deepest, Run.FLOORS]
	file.set_value(brother, "deepest", maxi(deepest, floor_reached))
	file.set_value(brother, "wins", wins)
	file.set_value(brother, "best_time", best)
	file.save(PATH)
	return line


## Minutes and seconds: 4:07.
static func clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
