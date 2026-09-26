class_name Hud
extends Node2D
## What is on the screen over the room, kept out of the way the way Isaac
## keeps it: hearts in the top-left corner over the dark of the wall, the
## pockets under them, the map of the floor in the top-right on a little
## plate just big enough for the rooms found so far, the floor's name under
## it, and the boss's health across the bottom while there is a boss.
## Lettered like a title card: cream with a thick ink edge.

const RED := Color("d8412f")
const EMPTY := Color("4a2c22")
const HEART := 46.0
const CREAM := Color("f6e7c1")
## The map: one little card per room, laid out like the floor.
const MAP_CELL := Vector2(38, 24)
const MAP_GAP := 6.0
## The map's top-right corner: it grows down and to the left from here.
const MAP_CORNER := Vector2(1920 - 36, 30)
const MAP_MOST := Vector2(330, 170)
const MAP_VISITED := Color("c9b08a")
const MAP_HERE := Color("fbf6ea")
const MAP_UNKNOWN := Color("6a5446")

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
	var floor_style := Ui.text(28, CREAM)
	_floor = Ui.label("", floor_style, 420)
	_floor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_floor)
	_name = Ui.label("", Ui.title(30, Color("e0584a")), 300)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name.visible = false
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
		_draw_hearts()
		_draw_pockets()
	if run != null and run.plan != null:
		_draw_map()
	elif _floor.text != "":
		_floor.position = Vector2(MAP_CORNER.x - 420, MAP_CORNER.y)
	if not bosses.is_empty():
		_draw_boss_bar()
	elif _boss_name.text != "":
		_boss_name.text = ""


## A soft dark pool behind the corner, so hearts and numbers read on any
## wall.
func _shade(at: Vector2, radii: Vector2) -> void:
	Toon.glow(self, at, radii, Color(0.05, 0.03, 0.02, 0.55), 3)


func _draw_hearts() -> void:
	var hearts := brother.stats.max_hp() / 2
	var rows := 1 + (hearts - 1) / 6
	_shade(Vector2(150, 110), Vector2(300, 150 + rows * 20))
	for i in hearts:
		var fill := clampi(brother.hp - i * 2, 0, 2)
		var row := i / 6
		var at := Vector2(78 + (i % 6) * 62, 66 + row * 56)
		Toon.heart(self, at, HEART, fill, RED, EMPTY)


## Coins, bombs and keys under the hearts, as in Isaac: an icon and a count
## each.
func _draw_pockets() -> void:
	var rows := 1 + (brother.stats.max_hp() / 2 - 1) / 6
	var y := 66.0 + rows * 56.0 + 22.0
	var counts := [["coin", brother.coins], ["bomb", brother.bombs], ["key", brother.keys]]
	for i in counts.size():
		var at := Vector2(78, y + i * 50.0)
		# Each on a little cream medallion, so a black bomb reads on a dark
		# wall.
		Toon.blob(self, at, Vector2(21, 21), Color(CREAM, 0.95), 0, 7 + i, 4.0)
		ItemIcon.draw(self, counts[i][0], at, 30.0, 0)
		var text := "%02d" % int(counts[i][1])
		var base := at + Vector2(32, 13)
		draw_string_outline(Ui.font(), base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 9, Toon.INK)
		draw_string(Ui.font(), base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, CREAM)


func _draw_map() -> void:
	var plan := run.plan
	var cells: Array[Vector2i] = []
	for cell: Vector2i in plan.rooms:
		if plan.known(cell):
			cells.append(cell)
	if cells.is_empty():
		return
	# The rooms round the one the brothers are in, as many as fit.
	var step := MAP_CELL + Vector2(MAP_GAP, MAP_GAP)
	var span := Vector2i(int(MAP_MOST.x / step.x), int(MAP_MOST.y / step.y))
	var shown: Array[Vector2i] = []
	var low := run.cell
	var high := run.cell
	for cell in cells:
		var d := cell - run.cell
		if absi(d.x) <= span.x / 2 and absi(d.y) <= span.y / 2:
			shown.append(cell)
			low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	var size := Vector2(high - low + Vector2i.ONE) * step - Vector2(MAP_GAP, MAP_GAP)
	var plate := Rect2(MAP_CORNER - Vector2(size.x + 36, 0), size + Vector2(36, 36))
	var origin := plate.position + Vector2(18, 18) + MAP_CELL * 0.5
	_shade(plate.get_center() + Vector2(0, 20), plate.size * 0.9 + Vector2(80, 60))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.07, 0.05, 0.82)
	box.border_color = Color(CREAM, 0.9)
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.anti_aliasing = true
	draw_style_box(box, plate)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.border_color = Color(CREAM, 0.35)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(6)
	draw_style_box(inner, plate.grow(-6))
	# Doors between known rooms: short bars in the gaps.
	for cell in shown:
		for side: String in ["right", "bottom"]:
			var next: Vector2i = cell + FloorPlan.SIDES[side]
			if shown.has(next):
				var a := origin + Vector2(cell - low) * step
				var b := origin + Vector2(next - low) * step
				var mid := (a + b) * 0.5
				var bar := Vector2(MAP_GAP + 4, 8) if side == "right" else Vector2(10, MAP_GAP + 4)
				draw_rect(Rect2(mid - bar * 0.5, bar), Color(CREAM, 0.6))
	for cell in shown:
		var info := plan.info(cell)
		var at := origin + Vector2(cell - low) * step
		var rect := Rect2(at - MAP_CELL * 0.5, MAP_CELL)
		var here := cell == run.cell
		var fill := MAP_HERE if here else (MAP_VISITED if info.visited else MAP_UNKNOWN)
		var room_box := StyleBoxFlat.new()
		room_box.bg_color = fill
		room_box.border_color = Toon.INK
		room_box.set_border_width_all(2)
		room_box.set_corner_radius_all(4)
		if here:
			Toon.glow(self, at, MAP_CELL * 1.1, Color(1, 0.95, 0.75, 0.45), 2)
		draw_style_box(room_box, rect)
		match info.kind:
			"boss":
				Toon.spot(self, at, Vector2(7, 6.5), Color("b8322a"))
				Toon.spot(self, at + Vector2(-2.6, -1.5), Vector2(1.7, 1.9), Toon.INK)
				Toon.spot(self, at + Vector2(2.6, -1.5), Vector2(1.7, 1.9), Toon.INK)
			"treasure":
				Toon.star(self, at, 7.0, 0.0, Color("e0b23a"))
			"shop":
				ItemIcon.draw(self, "coin", at, 18.0, 0)
	_floor.position = Vector2(MAP_CORNER.x - 420, plate.end.y + 4)


func _draw_boss_bar() -> void:
	var bar := Rect2(560, 1014, 800, 24)
	var hp := 0.0
	var most := 0.0
	for boss in bosses:
		if is_instance_valid(boss):
			hp += maxf(boss.hp, 0.0) if not boss.dead else 0.0
			most += boss.max_hp
	if most <= 0.0 or hp <= 0.0:
		# Nobody left to show: the name goes with the bar.
		_boss_name.text = ""
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
