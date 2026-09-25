class_name Stats
extends RefCounted
## A brother's numbers, in the units the data file uses (Isaac's: speed 1.0,
## tears a second, range in tiles), and what they come to on screen.
##
## Items will change the base numbers; everything on screen is worked out
## from them, so an item never has to know about pixels.

## Pixels a second at speed 1.0.
const SPEED_PX := 430.0
## Pixels a second at shot speed 1.0.
const SHOT_SPEED_PX := 780.0

var hearts := 3
var speed := 1.0
var damage := 3.5
var tears := 2.7
var range_tiles := 6.5
var shot_speed := 1.0
var luck := 0.0


static func from_character(character: Dictionary) -> Stats:
	var s := Stats.new()
	s.hearts = int(character.get("hearts", s.hearts))
	s.speed = float(character.get("speed", s.speed))
	s.damage = float(character.get("damage", s.damage))
	s.tears = float(character.get("tears", s.tears))
	s.range_tiles = float(character.get("range", s.range_tiles))
	s.shot_speed = float(character.get("shot_speed", s.shot_speed))
	s.luck = float(character.get("luck", s.luck))
	return s


## Health is counted in half hearts.
func max_hp() -> int:
	return hearts * 2


func walk_px() -> float:
	return speed * SPEED_PX


func fire_interval() -> float:
	return 1.0 / maxf(tears, 0.1)


func range_px() -> float:
	return range_tiles * Room.TILE


func shot_px() -> float:
	return shot_speed * SHOT_SPEED_PX


## Bigger hits make bigger shots, as in Isaac: you can see how hard a brother
## hits.
func shot_radius() -> float:
	return 11.0 + damage * 1.5
