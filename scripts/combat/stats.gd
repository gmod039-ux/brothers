class_name Stats
extends RefCounted
## A brother's numbers, in the units the data file uses (Isaac's: speed 1.0,
## tears a second, range in tiles), and what they come to on screen.
##
## Items add to the base numbers, then multiply ([method apply]); what is on
## screen is always worked out from the result, so an item never has to know
## about pixels.

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
## Shot size and knockback, only ever changed by multiplying.
var size := 1.0
var knockback := 1.0
## Special shots: "triple", "homing", "pierce", "spectral".
var flags: Array[String] = []


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


## Applies an item from data/items.json: its "add" numbers, then its "mult"
## ones, then its flags. Floors keep the numbers playable.
func apply(item: Dictionary) -> void:
	var add: Dictionary = item.get("add", {})
	hearts += int(add.get("hearts", 0))
	speed += float(add.get("speed", 0.0))
	damage += float(add.get("damage", 0.0))
	tears += float(add.get("tears", 0.0))
	range_tiles += float(add.get("range", 0.0))
	shot_speed += float(add.get("shot_speed", 0.0))
	luck += float(add.get("luck", 0.0))
	var mult: Dictionary = item.get("mult", {})
	damage *= float(mult.get("damage", 1.0))
	tears *= float(mult.get("tears", 1.0))
	size *= float(mult.get("size", 1.0))
	knockback *= float(mult.get("knockback", 1.0))
	for flag: String in item.get("flags", []):
		if not flags.has(flag):
			flags.append(flag)
	speed = clampf(speed, 0.5, 2.0)
	tears = maxf(tears, 0.5)
	range_tiles = maxf(range_tiles, 2.0)
	shot_speed = maxf(shot_speed, 0.5)
	damage = maxf(damage, 0.5)


## Takes back what [method apply] gave for [param item]: its "add" numbers
## and its flags (a trinket swapped for another). Items with "mult" numbers
## are never taken back, so those are left alone.
func unapply(item: Dictionary) -> void:
	var add: Dictionary = item.get("add", {})
	hearts -= int(add.get("hearts", 0))
	speed -= float(add.get("speed", 0.0))
	damage -= float(add.get("damage", 0.0))
	tears -= float(add.get("tears", 0.0))
	range_tiles -= float(add.get("range", 0.0))
	shot_speed -= float(add.get("shot_speed", 0.0))
	luck -= float(add.get("luck", 0.0))
	for flag: String in item.get("flags", []):
		flags.erase(flag)
	speed = clampf(speed, 0.5, 2.0)
	tears = maxf(tears, 0.5)
	range_tiles = maxf(range_tiles, 2.0)
	shot_speed = maxf(shot_speed, 0.5)
	damage = maxf(damage, 0.5)


func has(flag: String) -> bool:
	return flags.has(flag)


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
	return (11.0 + damage * 1.5) * size
