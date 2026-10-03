class_name RoomLayouts
extends RefCounted
## The room layouts of a floor, read from a text file of them (see
## data/rooms/basement.txt): each one a name and seven rows of tiles. Each
## floor has its own fights in its own file; the special rooms (start,
## treasure, shop, boss, secret) are the basement's on every floor.

## Each floor's file, top to bottom.
const FILES := ["res://data/rooms/basement.txt", "res://data/rooms/boiler.txt", "res://data/rooms/catacombs.txt"]

## Tiles in front of the doors: these must be floor, or a door could open
## onto a rock.
const DOOR_TILES := {
	"top": Vector2i(6, 0),
	"bottom": Vector2i(6, 6),
	"left": Vector2i(0, 3),
	"right": Vector2i(12, 3),
}
## Enemies a layout letter stands for.
const ENEMIES := {
	"f": "fly", "w": "walker", "s": "shooter", "p": "pup", "e": "ember", "k": "kitten",
	"c": "stoker", "v": "valve", "g": "ghost", "b": "skeleton", "t": "bat",
}

## name -> rows
var rooms := {}


static func load_file(path: String) -> RoomLayouts:
	var layouts := RoomLayouts.new()
	var text := FileAccess.get_file_as_string(path)
	var name := ""
	var rows := PackedStringArray()
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		# Comments are "# " lines; a row of tiles may start with a rock but
		# never with a rock and a space.
		if line == "#" or line.begins_with("# "):
			continue
		if line.begins_with("="):
			if name != "":
				layouts.rooms[name] = rows
			name = line.substr(1).strip_edges()
			rows = PackedStringArray()
		elif not line.is_empty() and name != "":
			rows.append(line)
	if name != "":
		layouts.rooms[name] = rows
	return layouts


## The layouts of floor [param index]: its own fights, and the special
## rooms every floor shares.
static func for_floor(index: int) -> RoomLayouts:
	var layouts := load_file(FILES[0])
	if index <= 0 or index >= FILES.size():
		return layouts
	var own := load_file(FILES[index])
	for name in layouts.fights():
		layouts.rooms.erase(name)
	for name: String in own.rooms:
		layouts.rooms[name] = own.rooms[name]
	return layouts


## Layouts for fights: every name not starting with @.
func fights() -> Array[String]:
	var names: Array[String] = []
	for name: String in rooms:
		if not name.begins_with("@"):
			names.append(name)
	names.sort()
	return names


func get_rows(name: String) -> PackedStringArray:
	return rooms.get(name, PackedStringArray())


## The enemies a layout places: [kind, cell] pairs.
static func enemies_in(rows: PackedStringArray) -> Array:
	var found := []
	for row in rows.size():
		for col in rows[row].length():
			var letter := rows[row][col]
			if ENEMIES.has(letter):
				found.append([ENEMIES[letter], Vector2i(col, row)])
	return found
