class_name GameData
extends RefCounted
## The game's numbers, read from data/ once and kept. Everything a friend
## might want to tune without touching code lives there: brothers, enemies,
## waves and room layouts.
##
## An export has to list *.json and *.txt as extra files to include: they are
## not resources, and the exporter leaves out what it does not know.

static var _cache := {}


static func json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("%s is not a JSON object" % path)
		parsed = {}
	_cache[path] = parsed
	return parsed


static func characters() -> Dictionary:
	return json("res://data/characters.json")


static func character(id: String) -> Dictionary:
	var all := characters()
	return all.get(id, {})


static func enemies() -> Dictionary:
	return json("res://data/enemies.json")


static func items() -> Dictionary:
	return json("res://data/items.json")


static func waves(set_name: String) -> Array:
	var all := json("res://data/waves.json")
	return all.get(set_name, [])


## A room layout: one string per row of tiles.
static func room_layout(room_name: String) -> PackedStringArray:
	var text := FileAccess.get_file_as_string("res://data/rooms/%s.txt" % room_name)
	var rows := PackedStringArray()
	for line in text.split("\n"):
		var row := line.strip_edges()
		if not row.is_empty():
			rows.append(row)
	return rows
