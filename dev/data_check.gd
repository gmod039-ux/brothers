extends SceneTree
## Every data file reads, and holds together: brothers have their numbers,
## items have their words and actives an effect, waves name enemies that
## exist, room layouts are the right size.
##
##     godot --headless --path . --script res://dev/data_check.gd

var _failures := 0


func _initialize() -> void:
	var characters := GameData.characters()
	_expect(characters.size() >= 2, "at least two brothers")
	for id: String in characters:
		var c: Dictionary = characters[id]
		for key in ["name", "hearts", "speed", "damage", "tears", "range", "shot_speed", "look"]:
			_expect(c.has(key), "%s has %s" % [id, key])
		var stats := Stats.from_character(c)
		_expect(stats.max_hp() >= 2, "%s has at least one heart" % id)
		_expect(stats.fire_interval() > 0.05 and stats.fire_interval() < 2.0,
				"%s shoots at a sane rate (%.2f s)" % [id, stats.fire_interval()])
	var enemies := GameData.enemies()
	for kind: String in enemies:
		var e: Dictionary = enemies[kind]
		_expect(float(e.get("hp", 0)) > 0.0, "%s has health" % kind)
		_expect(float(e.get("radius", 0)) > 0.0, "%s has a size" % kind)
	var items := GameData.items()
	for id: String in items:
		var item: Dictionary = items[id]
		_expect(item.has("name") and item.has("text"), "item %s has a name and a line" % id)
		if item.has("active"):
			var charge := int(item["active"])
			_expect(charge >= 1 and charge <= 6, "active %s charges in 1 to 6 rooms (%d)" % [id, charge])
			_expect(ActiveItems.EFFECTS.has(id), "active %s does something" % id)
	var waves := GameData.waves("arena")
	_expect(not waves.is_empty(), "the arena has waves")
	for wave: Dictionary in waves:
		for kind: String in wave:
			_expect(enemies.has(kind), "wave enemy %s exists" % kind)
	var layout := GameData.room_layout("arena")
	_expect(layout.size() == Room.ROWS, "arena has %d rows (has %d)" % [Room.ROWS, layout.size()])
	for row in layout:
		_expect(row.length() == Room.COLS, "arena row '%s' is %d wide" % [row, Room.COLS])
	print("data: %d brothers, %d enemies, %d items, %d waves, layout %dx%d" % [characters.size(),
			enemies.size(), items.size(), waves.size(), layout[0].length() if layout.size() > 0 else 0, layout.size()])
	quit(1 if _failures > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: " + what)
