extends SceneTree
## Floors hold together:
## - each floor has its own dozen fights or more (data/rooms/*.txt);
## - every room layout is 13 by 7, uses only known letters, leaves the tiles
##   in front of doors open, and has all its open tiles connected, so no
##   enemy is walled off and every door is reachable from every other;
## - on 1000 seeds for each floor, the plan has as many rooms as it should,
##   the boss sits in a dead end at least two rooms from the start and as far
##   as any dead end, the treasure room in another dead end, and every room
##   has a layout.
##
##     godot --headless --path . --script res://dev/floor_check.gd

const SEEDS := 1000

var _failures := 0


func _initialize() -> void:
	for floor_index in Run.FLOORS:
		var layouts := RoomLayouts.for_floor(floor_index)
		_check_layouts(layouts)
		_expect(layouts.fights().size() >= 12, "floor %d has a dozen fights at least (%d)"
				% [floor_index, layouts.fights().size()])
		if floor_index > 0:
			# Its own: no fight shared with the basement.
			for name in RoomLayouts.load_file(RoomLayouts.FILES[floor_index]).rooms:
				_expect(not name.begins_with("@"), "floor %d keeps its special rooms in the basement's file (%s)"
						% [floor_index, name])
		_check_floors(layouts, floor_index)
	quit(1 if _failures > 0 else 0)


func _check_layouts(layouts: RoomLayouts) -> void:
	for name: String in layouts.rooms:
		var rows := layouts.get_rows(name)
		_expect(rows.size() == Room.ROWS, "%s has %d rows" % [name, Room.ROWS])
		var open := {}
		for r in rows.size():
			_expect(rows[r].length() == Room.COLS, "%s row %d is %d wide" % [name, r, Room.COLS])
			for c in rows[r].length():
				var letter := rows[r][c]
				_expect(letter in [".", "#"] or RoomLayouts.ENEMIES.has(letter),
						"%s: unknown tile '%s'" % [name, letter])
				if letter != "#":
					open[Vector2i(c, r)] = true
		for side: String in RoomLayouts.DOOR_TILES:
			_expect(open.has(RoomLayouts.DOOR_TILES[side]), "%s keeps the %s door clear" % [name, side])
		# Flood from one open tile: it must reach them all.
		var first: Vector2i = open.keys()[0]
		var reached := {first: true}
		var queue: Array[Vector2i] = [first]
		while not queue.is_empty():
			var at: Vector2i = queue.pop_front()
			for step: Vector2i in FloorPlan.SIDES.values():
				if open.has(at + step) and not reached.has(at + step):
					reached[at + step] = true
					queue.append(at + step)
		_expect(reached.size() == open.size(), "%s: all %d open tiles connected (%d reached)"
				% [name, open.size(), reached.size()])
		if not name.begins_with("@"):
			_expect(not RoomLayouts.enemies_in(rows).is_empty(), "%s has enemies" % name)
	print("floor: %d layouts, %d fights" % [layouts.rooms.size(), layouts.fights().size()])


func _check_floors(layouts: RoomLayouts, floor_index: int) -> void:
	var rng := RandomNumberGenerator.new()
	var smallest := 99
	var largest := 0
	var shops := 0
	var secrets := 0
	for seed_value in SEEDS:
		rng.seed = seed_value
		var plan := FloorPlan.generate(rng, floor_index, layouts)
		if plan == null:
			_expect(false, "floor %d seed %d grows a plan" % [floor_index, seed_value])
			continue
		var n := plan.rooms.size()
		smallest = mini(smallest, n)
		largest = maxi(largest, n)
		var boss := plan.info(plan.boss)
		var treasure := plan.info(plan.treasure)
		_expect(plan.doors(plan.boss).size() == 1, "boss room is a dead end (seed %d)" % seed_value)
		_expect(plan.doors(plan.treasure).size() == 1, "treasure room is a dead end (seed %d)" % seed_value)
		_expect(boss.depth >= 2, "boss not next to the start (seed %d)" % seed_value)
		_expect(plan.boss != plan.treasure, "boss and treasure apart (seed %d)" % seed_value)
		_expect(boss.kind == "boss" and treasure.kind == "treasure", "kinds set (seed %d)" % seed_value)
		if plan.secret_info != null:
			secrets += 1
			_expect(not plan.rooms.has(plan.secret), "the secret room is hidden (seed %d)" % seed_value)
			var around := 0
			for step: Vector2i in FloorPlan.SIDES.values():
				if plan.rooms.has(plan.secret + step):
					around += 1
					_expect(not (plan.secret + step in [plan.boss, plan.treasure, plan.shop]),
							"the secret room is not next to a dead end (seed %d)" % seed_value)
			_expect(around >= 2, "the secret room touches two rooms (seed %d)" % seed_value)
			_expect(plan.secret_info.rows.size() == Room.ROWS, "the secret room has a layout (seed %d)" % seed_value)
		_expect(treasure.locked == (floor_index > 0), "treasure locked below the first floor (seed %d)" % seed_value)
		if plan.shop != Vector2i(-1, -1):
			shops += 1
			var shop := plan.info(plan.shop)
			_expect(shop.kind == "shop" and plan.doors(plan.shop).size() == 1, "a shop is a dead end (seed %d)" % seed_value)
		for cell: Vector2i in plan.rooms:
			var info := plan.info(cell)
			_expect(info.rows.size() == Room.ROWS, "room %s has a layout (seed %d)" % [cell, seed_value])
			if plan.doors(cell).size() == 1 and cell != plan.start:
				_expect(info.depth <= boss.depth, "no dead end deeper than the boss (seed %d)" % seed_value)
		if _failures > 20:
			break
	print("floor %d: %d seeds, %d to %d rooms, a shop on %d%%, a secret room on %d%%" % [floor_index + 1, SEEDS,
			smallest, largest, shops * 100 / SEEDS, secrets * 100 / SEEDS])


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		if _failures <= 20:
			printerr("FAILED: " + what)
