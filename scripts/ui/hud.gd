class_name Hud
extends Node2D
## What is on the screen over the room, kept out of the way the way Isaac
## keeps it: hearts in the top-left corner over the dark of the wall (with
## two brothers, a row each behind a medallion with his number), the pockets
## they share under them, the map of the floor in the top-right on a little
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

var brothers: Array[Brother] = []:
	set(value):
		brothers = value
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
var _boss_name: Label


func _ready() -> void:
	var floor_style := Ui.text(28, CREAM)
	_floor = Ui.label("", floor_style, 420)
	_floor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_floor)
	_boss_name = Ui.label("", Ui.text(38), 900)
	_boss_name.position = Vector2(510, 952)
	add_child(_boss_name)


## The wave count of the arena, where there is no floor.
func set_wave(number: int, total: int) -> void:
	_floor.text = "Волна %d из %d" % [number, total]


func set_health(_hp: int, _max_hp: int) -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	if run != null:
		var text := "%s · этаж %d" % [run.floor_name(), run.floor_index + 1]
		if run.evil:
			text += " · злой"
		if _floor.text != text:
			_floor.text = text
	if not bosses.is_empty():
		queue_redraw()
	for one in brothers:
		if is_instance_valid(one) and (one.dead or one.is_charged() or _low(one)):
			# The stars round a knocked-out brother's medallion go round,
			# a charged item glows.
			queue_redraw()
			break


func _draw() -> void:
	if not brothers.is_empty():
		var y := _draw_hearts()
		_draw_pockets(y)
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


## Each brother's hearts, six to a row; returns where the pockets go.
func _draw_hearts() -> float:
	var two := brothers.size() > 1
	var x0 := 112.0 if two else 78.0
	var rows := 0
	for one in brothers:
		rows += 1 + (one.stats.max_hp() / 2 - 1) / 6
	_shade(Vector2(150 + (30 if two else 0), 110 + (rows - 1) * 28), Vector2(300 + (40 if two else 0), 150 + rows * 30))
	var y := 66.0
	for j in brothers.size():
		var one := brothers[j]
		var hearts := one.stats.max_hp() / 2
		if two:
			_badge(one, Vector2(46, y))
		# Down to his last heart, it beats: lub-dub, a rest, lub-dub.
		var last := (one.hp - 1) / 2 if _low(one) else -1
		for i in hearts:
			var fill := clampi(one.hp - i * 2, 0, 2)
			var at := Vector2(x0 + (i % 6) * 62, y + (i / 6) * 56)
			var size := HEART
			if i == last:
				size *= 1.0 + 0.16 * _beat()
			Toon.heart(self, at, size, fill, RED, EMPTY)
		if one.active != "":
			_active(one, Vector2(x0 + 6 * 62 + 28, y + 4))
		y += (1 + (hearts - 1) / 6) * 56.0 + (8.0 if two else 0.0)
	return y


## The item in a brother's hands on a medallion, and its charge as a
## column of little lamps beside it; charged, it glows.
func _active(one: Brother, at: Vector2) -> void:
	var most := one.max_charge()
	var ready := one.is_charged()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
	if ready:
		Toon.glow(self, at, Vector2(56, 56), Color(1, 0.88, 0.45, 0.35 + 0.25 * pulse), 3)
	Toon.blob(self, at, Vector2(29, 29), Color(CREAM, 0.95) if ready else Color("b8a88a"), 0, 50 + one.player, 4.0)
	ItemIcon.draw(self, one.active, at, 44.0, 0)
	var step := 58.0 / most
	for k in most:
		var lamp := Vector2(at.x + 42, at.y + 26 - step * (k + 0.5))
		var lit := k < one.charge
		Toon.blob(self, lamp, Vector2(7, minf(step * 0.36, 9.0)), Color("fff1a8") if lit else Color("4a3a2c"), 0,
				60 + k, 3.0)


## Down to one heart or less, and still up.
func _low(one: Brother) -> bool:
	return is_instance_valid(one) and not one.dead and one.hp <= 2 and one.stats.max_hp() > 2


## 0 to 1: a heartbeat, two quick thumps a little over once a second.
func _beat() -> float:
	var t := fmod(Time.get_ticks_msec() / 1000.0, 0.85)
	var thump := func(at: float) -> float: return maxf(0.0, 1.0 - absf(t - at) / 0.07)
	return maxf(thump.call(0.07), thump.call(0.24) * 0.7)


## The player's number on a cream medallion ringed in his brother's colour;
## grey with stars going round while he is knocked out.
func _badge(one: Brother, at: Vector2) -> void:
	var accent := BrotherLook._color(GameData.character(one.id).get("look", {}), "accent", Color.WHITE)
	var fill := Color("8a8076") if one.dead else Color(CREAM, 0.95)
	Toon.blob(self, at, Vector2(24, 24), accent, 0, 30 + one.player, 4.0)
	Toon.blob(self, at, Vector2(17, 17), fill, 0, 32 + one.player, 0.0)
	draw_string(Ui.title_font(), at + Vector2(-20, 11), str(one.player), HORIZONTAL_ALIGNMENT_CENTER, 40, 30, Toon.INK)
	if one.dead:
		var turn := Time.get_ticks_msec() / 400.0
		for k in 2:
			var a := turn + PI * k
			Toon.star(self, at + Vector2(cos(a) * 26.0, -22.0 + sin(a) * 6.0), 7.0, a, Color("f2c14e"))


## Coins, bombs and keys under the hearts, as in Isaac: an icon and a count
## each. Two brothers share them.
func _draw_pockets(top: float) -> void:
	var y := top + 22.0
	var brother := brothers[0]
	var counts := [["coin", brother.coins], ["bomb", brother.bombs], ["key", brother.keys]]
	# Each brother's trinket under them, on a gold-rimmed medallion.
	var trinket_x := 78.0
	for one in brothers:
		if one.trinket == "":
			continue
		var at := Vector2(trinket_x, y + 3 * 50.0 + 4.0)
		Toon.blob(self, at, Vector2(23, 23), Color("e0b23a"), 0, 70 + one.player, 4.0)
		Toon.blob(self, at, Vector2(18, 18), Color(CREAM, 0.95), 0, 72 + one.player, 0.0)
		ItemIcon.draw(self, one.trinket, at, 32.0, 0)
		trinket_x += 56.0
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
	var hint := plan.secret_hinted and plan.is_hidden_secret(plan.secret)
	if hint:
		cells.append(plan.secret)
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
		if hint and cell == plan.secret:
			# Where the compass points: a dashed outline and a question mark.
			var spot := origin + Vector2(cell - low) * step
			var dash := Rect2(spot - MAP_CELL * 0.5, MAP_CELL)
			for k in 6:
				var u := k / 6.0
				draw_line(dash.position + Vector2(dash.size.x * u, 0), dash.position + Vector2(dash.size.x * (u + 0.09), 0),
						Color(CREAM, 0.7), 2.0)
				draw_line(Vector2(dash.position.x + dash.size.x * u, dash.end.y),
						Vector2(dash.position.x + dash.size.x * (u + 0.09), dash.end.y), Color(CREAM, 0.7), 2.0)
			draw_string(Ui.font(), spot + Vector2(-10, 8), "?", HORIZONTAL_ALIGNMENT_CENTER, 20, 20, Color(CREAM, 0.8))
			continue
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
			"secret":
				draw_string(Ui.font(), at + Vector2(-10, 8), "?", HORIZONTAL_ALIGNMENT_CENTER, 20, 20, Toon.INK)
			"arcade":
				# A cherry pair: the slot machine.
				for sx: float in [-1.0, 1.0]:
					Toon.spot(self, at + Vector2(sx * 3.5, 3), Vector2(3.5, 3.5), Color("b8322a"))
				draw_line(at + Vector2(-3, 1), at + Vector2(1, -6), Toon.INK, 1.5)
				draw_line(at + Vector2(3, 1), at + Vector2(1, -6), Toon.INK, 1.5)
			"miniboss":
				# A crown, once they have been in.
				if info.visited:
					Toon.shape(self, PackedVector2Array([at + Vector2(-7, 5), at + Vector2(-8, -5), at + Vector2(-3, 0),
							at + Vector2(0, -7), at + Vector2(3, 0), at + Vector2(8, -5), at + Vector2(7, 5)]),
							Color("e0b23a"), 2.0)
			"challenge":
				# Crossed swords.
				for sx: float in [-1.0, 1.0]:
					draw_line(at + Vector2(-6 * sx, 6), at + Vector2(6 * sx, -6), Toon.INK, 2.5)
					draw_line(at + Vector2(-6 * sx, 6) + Vector2(sx * 2, -2) * 0.0, at + Vector2(-4 * sx, 2), Color("e0b23a"), 3.0)
		if info.locked:
			# A little padlock on the corner: a key opens it.
			var lock := at + Vector2(MAP_CELL.x * 0.5 - 4, MAP_CELL.y * 0.5 - 4)
			draw_arc(lock + Vector2(0, -5), 4.0, PI, TAU, 10, Toon.INK, 3.0, true)
			Toon.box(self, lock, Vector2(6, 5), Color("e0b23a"), 0, 70, 2.0)
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
	var marks: Array[float] = [0.33, 0.66]
	if is_instance_valid(bosses[0]):
		marks = bosses[0].phase_marks()
	for mark: float in marks:
		var x := bar.position.x + bar.size.x * mark
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Toon.INK, 3.0)
