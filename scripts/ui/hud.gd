class_name Hud
extends Node2D
## What is on the screen over the room: hearts in the top-left corner, as in
## Isaac, the map of the floor in the top-right with the floor's name under
## it, and the boss's health across the bottom while there is a boss.

const RED := Color("d8412f")
const EMPTY := Color("4a2c22")
const HEART := 40.0
## The map: one little card per room, laid out like the floor.
const MAP_CELL := Vector2(40, 26)
const MAP_GAP := 6.0
const MAP_CENTER := Vector2(1920 - 200, 120)
const MAP_VISITED := Color("c9b08a")
const MAP_HERE := Color("f7f0e1")
const MAP_UNKNOWN := Color("5a463a")

var brother: Brother:
	set(value):
		brother = value
		queue_redraw()
var run: Run:
	set(value):
		run = value
		queue_redraw()
## The bosses in the room, whose health the bar at the bottom shows as one.
var bosses: Array[Boss] = []:
	set(value):
		bosses = value
		var names: Array[String] = []
		for boss in bosses:
			names.append(boss.title)
		_boss_name.text = " и ".join(names)
		queue_redraw()

var _floor: Label
var _name: Label
var _boss_name: Label


func _ready() -> void:
	var floor_style := Ui.text(26, Toon.INK)
	floor_style.outline_size = 0
	_floor = Ui.label("", floor_style, 360)
	_floor.position = MAP_CENTER + Vector2(-180, 104)
	add_child(_floor)
	var name_style := Ui.title(30, Color("b8322a"))
	_name = Ui.label("", name_style, 260)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name.position = Vector2(62, 262)
	add_child(_name)
	_boss_name = Ui.label("", Ui.text(38), 900)
	_boss_name.position = Vector2(510, 952)
	add_child(_boss_name)


## The wave count of the arena, where there is no floor.
func set_wave(number: int, total: int) -> void:
	_floor.text = "Волна %d из %d" % [number, total]


func set_health(_hp: int, _max_hp: int) -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	if brother != null and _name.text != brother.display_name:
		_name.text = brother.display_name
	if run != null:
		var text := "%s · этаж %d" % [run.floor_name(), run.floor_index + 1]
		if _floor.text != text:
			_floor.text = text
	if not bosses.is_empty():
		queue_redraw()


func _draw() -> void:
	if brother != null:
		# A card for the hearts and pockets, like a ticket.
		var rows_of_hearts := 1 + (brother.stats.max_hp() / 2 - 1) / 6
		var width := 76.0 + mini(brother.stats.max_hp() / 2, 6) * 58.0
		Frames.card(self, Rect2(40, 24, maxf(width, 250.0), 90.0 + rows_of_hearts * 52.0 + 150.0), Frames.CREAM, 0.92)
		var hearts := brother.stats.max_hp() / 2
		for i in hearts:
			var fill := clampi(brother.hp - i * 2, 0, 2)
			var row := i / 6
			Toon.heart(self, Vector2(88 + (i % 6) * 58, 66 + row * 52), HEART, fill, RED, EMPTY)
	if brother != null:
		# Coins, bombs and keys under the hearts, as in Isaac.
		var rows := 1 + (brother.stats.max_hp() / 2 - 1) / 6
		var y := 66.0 + rows * 52.0 + 30.0
		var counts := [["coin", brother.coins], ["bomb", brother.bombs], ["key", brother.keys]]
		for i in counts.size():
			var at := Vector2(88, y + i * 40.0)
			ItemIcon.draw(self, counts[i][0], at, 34.0, 0)
			draw_string(Ui.font(), at + Vector2(26, 12), "× %02d" % int(counts[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1,
					30, Toon.INK)
	if run != null and run.plan != null:
		_draw_map()
	if not bosses.is_empty():
		_draw_boss_bar()


func _draw_map() -> void:
	var plan := run.plan
	var cells: Array[Vector2i] = []
	for cell: Vector2i in plan.rooms:
		if plan.known(cell):
			cells.append(cell)
	if cells.is_empty():
		return
	# Centred on the room the brothers are in, like Isaac's, on a dark card
	# just big enough for the rooms known so far.
	var step := MAP_CELL + Vector2(MAP_GAP, MAP_GAP)
	var limit := Rect2(MAP_CENTER - Vector2(180, 92), Vector2(360, 184))
	var used := Rect2()
	for cell in cells:
		var at := MAP_CENTER + Vector2(cell - run.cell) * step
		var rect := Rect2(at - MAP_CELL * 0.5, MAP_CELL)
		used = rect if used.size == Vector2.ZERO else used.merge(rect)
	# The map sits on a card of its own, the floor's name under it.
	Frames.card(self, Rect2(limit.position - Vector2(14, 14), limit.size + Vector2(28, 76)), Frames.CREAM, 0.92)
	draw_rect(limit, Color("2a1d16", 0.85))
	for cell in cells:
		var info := plan.info(cell)
		var at := MAP_CENTER + Vector2(cell - run.cell) * step
		var rect := Rect2(at - MAP_CELL * 0.5, MAP_CELL)
		if not limit.encloses(rect):
			continue
		var fill := MAP_HERE if cell == run.cell else (MAP_VISITED if info.visited else MAP_UNKNOWN)
		draw_rect(rect.grow(2.5), Toon.INK)
		draw_rect(rect, fill)
		match info.kind:
			"boss":
				Toon.spot(self, at, Vector2(7, 7), Color("b8322a"))
				Toon.spot(self, at + Vector2(-3, -2), Vector2(1.6, 1.6), Toon.INK)
				Toon.spot(self, at + Vector2(3, -2), Vector2(1.6, 1.6), Toon.INK)
			"treasure":
				Toon.star(self, at, 7.0, 0.0, Color("e0b23a"))
	# Doors between known rooms: small ticks in the gaps.
	for cell in cells:
		for side: String in ["right", "bottom"]:
			var next: Vector2i = cell + FloorPlan.SIDES[side]
			if cells.has(next):
				var a := MAP_CENTER + Vector2(cell - run.cell) * step
				var b := MAP_CENTER + Vector2(next - run.cell) * step
				var mid := (a + b) * 0.5
				if limit.has_point(mid):
					draw_rect(Rect2(mid - Vector2(3, 3), Vector2(6, 6)), Toon.INK)


func _draw_boss_bar() -> void:
	var bar := Rect2(560, 1014, 800, 24)
	var hp := 0.0
	var most := 0.0
	for boss in bosses:
		if is_instance_valid(boss):
			hp += maxf(boss.hp, 0.0) if not boss.dead else 0.0
			most += boss.max_hp
	if most <= 0.0 or hp <= 0.0:
		return
	var share := clampf(hp / most, 0.0, 1.0)
	# A card behind name and bar, a skull at one end.
	Frames.card(self, Rect2(bar.position.x - 70, bar.position.y - 70, bar.size.x + 110, bar.size.y + 92),
			Color("2a1d16"), 0.85)
	draw_rect(bar.grow(5), Toon.INK)
	draw_rect(bar, Color("4a2c22"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * share, bar.size.y)), RED)
	draw_rect(Rect2(bar.position + Vector2(0, 3), Vector2(bar.size.x * share, 5)), Color(1, 1, 1, 0.25))
	var skull := bar.position + Vector2(-34, 12)
	Toon.ball(self, skull, Vector2(20, 18), Color("e9dfc8"), 0, 1, 4.0)
	Toon.spot(self, skull + Vector2(-7, 0), Vector2(5, 6), Toon.INK)
	Toon.spot(self, skull + Vector2(7, 0), Vector2(5, 6), Toon.INK)
	for t in 3:
		draw_line(skull + Vector2(-6 + t * 6, 12), skull + Vector2(-6 + t * 6, 17), Toon.INK, 2.0)
	# Marks where the phases change.
	for mark: float in [0.33, 0.66]:
		var x := bar.position.x + bar.size.x * mark
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Toon.INK, 3.0)
