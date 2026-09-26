class_name BrotherSelect
extends Node2D
## Choosing a brother, on the poster of a picture house: velvet curtains, a
## sunburst behind the title in a marquee of lamps, both brothers on the
## boards with the chosen one in the spotlight, each with his playbill card
## of numbers.

signal chosen(id: String)

const IDS := ["older", "younger"]
const SPOTS := [Vector2(620, 700), Vector2(1300, 700)]
const BAR := Color("c8392b")
## The paper of title cards and dev sheets.
const CARD := Color("efe0bd")
const CARD_STAIN := Color("d9c08f")
const VELVET := Color("8e1f24")
const VELVET_DARK := Color("4e0d12")
const GOLD := Color("e0b23a")
const CREAM := Color("f3e6c8")
const BOARDS := Color("8a5a36")
## Where the boards of the stage begin.
const STAGE_Y := 610.0
## Each number against the most any brother will have, so a bar reads as
## "a lot" or "a little".
const BARS := [
	["Сердца", "hearts", 5.0],
	["Скорость", "speed", 1.4],
	["Урон", "damage", 6.0],
	["Выстрелы", "tears", 4.0],
	["Дальность", "range", 9.0],
]

var index := 0
var _looks: Array[BrotherLook] = []
var _names: Array[Label] = []
var _taken := false
var _clock := 0.0
var _drawing := -1


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var title := Ui.label("БРАТЬЯ", Ui.title(150))
	title.position = Vector2(0, 72)
	add_child(title)
	var sub_style := Ui.text(38, CREAM)
	var sub := Ui.label("кого ведём в подвал?", sub_style, 1920)
	sub.position = Vector2(0, 282)
	add_child(sub)
	for i in IDS.size():
		var character := GameData.character(IDS[i])
		var look := BrotherLook.new()
		look.configure(character.get("look", {}))
		look.position = SPOTS[i]
		look.scale = Vector2(2.3, 2.3)
		add_child(look)
		_looks.append(look)
		var x: float = (SPOTS[i] as Vector2).x
		var name_label := Ui.label(str(character.get("name", IDS[i])), Ui.title(60), 520)
		name_label.position = Vector2(x - 260, 742)
		add_child(name_label)
		_names.append(name_label)
		var about_style := Ui.text(26, Color("3a2418"))
		about_style.outline_size = 0
		var about := Ui.label(str(character.get("about", "")), about_style, 520)
		about.position = Vector2(x - 260, 818)
		add_child(about)
	var hint := Ui.label("←  →  выбрать     ·     Пробел — в бой", Ui.text(32), 1920)
	hint.position = Vector2(0, 1000)
	add_child(hint)
	_show()


func _process(delta: float) -> void:
	_clock += delta
	var d := int(_clock * Toon.FPS)
	if d != _drawing:
		_drawing = d
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _taken:
		return
	if event.is_action_pressed("p1_left") or event.is_action_pressed("p1_shoot_left"):
		index = 0
		Sfx.play("select", -6.0, 0.0)
		_show()
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p1_shoot_right"):
		index = 1
		Sfx.play("select", -6.0, 0.0)
		_show()
	elif event.is_action_pressed("confirm"):
		pick()


func pick() -> void:
	if _taken:
		return
	_taken = true
	Sfx.play("confirm", -4.0, 0.0)
	chosen.emit(IDS[index])


func select(i: int) -> void:
	index = clampi(i, 0, IDS.size() - 1)
	_show()


func _show() -> void:
	for i in _looks.size():
		var on := i == index
		_looks[i].moving = on
		_looks[i].walk_rate = 0.8
		_looks[i].modulate = Color.WHITE if on else Color(0.5, 0.46, 0.44)
		_names[i].modulate = Color.WHITE if on else Color(1, 1, 1, 0.55)
	queue_redraw()


func _draw() -> void:
	_backdrop()
	_stage()
	for i in IDS.size():
		_spotlight(i)
	_marquee()
	Frames.ribbon(self, Vector2(960, 312), 560.0, 66.0)
	for i in IDS.size():
		_playbill(i)
	_curtains()
	_footlights()


## The backcloth: a sunburst of cream rays from behind the title, fading into
## the dark of the wings.
func _backdrop() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("2a1510"))
	var center := Vector2(960, 190)
	var rays := 36
	var turn := _clock * 0.02
	for i in rays:
		var a0 := turn + TAU * i / rays
		var a1 := turn + TAU * (i + 0.5) / rays
		var far := 1500.0
		draw_polygon(PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * far,
				center + Vector2(cos(a1), sin(a1)) * far]),
				PackedColorArray([Color("f0dcae"), Color("c79a5c"), Color("c79a5c")]))
		var a2 := a1
		var a3 := turn + TAU * (i + 1) / rays
		draw_polygon(PackedVector2Array([center, center + Vector2(cos(a2), sin(a2)) * far,
				center + Vector2(cos(a3), sin(a3)) * far]),
				PackedColorArray([Color("e6c994"), Color("a87a44"), Color("a87a44")]))
	# The light falls off towards the stage and the wings.
	draw_polygon(PackedVector2Array([Vector2(0, 300), Vector2(1920, 300), Vector2(1920, STAGE_Y), Vector2(0, STAGE_Y)]),
			PackedColorArray([Color(0.16, 0.08, 0.06, 0.0), Color(0.16, 0.08, 0.06, 0.0),
					Color(0.16, 0.08, 0.06, 0.75), Color(0.16, 0.08, 0.06, 0.75)]))
	Toon.glow(self, center, Vector2(700, 420), Color(1, 0.96, 0.82, 0.35), 3)


## The boards of the stage, seen from the stalls: planks running away from
## us, darker at the front edge.
func _stage() -> void:
	var top := STAGE_Y
	var floor_rect := Rect2(0, top, 1920, 1080 - top)
	draw_rect(floor_rect, BOARDS)
	# Planks: lines converging on a point far above the middle.
	var vanish := Vector2(960, -900)
	for k in range(-16, 17):
		var x := 960.0 + k * 150.0
		var t0 := (top - vanish.y) / (1080.0 - vanish.y)
		var a := vanish.lerp(Vector2(x, 1080), t0)
		Toon.hand_line(self, a, Vector2(x, 1080), 2.5, 400 + k, Color(0.2, 0.1, 0.05, 0.6), 0.8)
	# Board ends, staggered.
	for r in 6:
		var y := top + 30.0 + r * r * 14.0 + r * 30.0
		if y > 1080:
			break
		for k in range(-16, 17):
			if (k + r) % 3 != 0:
				continue
			var t := (y - vanish.y) / (1080.0 - vanish.y)
			var a := vanish.lerp(Vector2(960.0 + k * 150.0, 1080), t)
			var b := vanish.lerp(Vector2(960.0 + (k + 1) * 150.0, 1080), t)
			draw_line(a, b, Color(0.2, 0.1, 0.05, 0.5), 2.0)
	# Shine along the boards, and the back edge in shadow.
	draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(1920, top), Vector2(1920, top + 60), Vector2(0, top + 60)]),
			PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]))
	Toon.hand_line(self, Vector2(0, top), Vector2(1920, top), 5.0, 390)


## A cone of light from the flies down onto a brother, and the pool it makes
## on the boards. Bright on the chosen one, a glimmer on the other.
func _spotlight(i: int) -> void:
	var spot: Vector2 = SPOTS[i]
	var on := i == index
	var strength := 0.3 if on else 0.07
	var flick := 1.0 + (Toon.hash01(_drawing, i) - 0.5) * 0.06
	var top_x := spot.x + (i - 0.5) * 300.0
	# The beam in slices across its width: bright down the middle, fading to
	# nothing at its edges.
	var slices := 10
	for k in slices:
		var u0 := float(k) / slices
		var u1 := float(k + 1) / slices
		var a0 := strength * flick * sin(u0 * PI)
		var a1 := strength * flick * sin(u1 * PI)
		var t0 := Vector2(top_x - 40 + 80 * u0, -20)
		var t1 := Vector2(top_x - 40 + 80 * u1, -20)
		var b0 := spot + Vector2(-210 + 420 * u0, 10)
		var b1 := spot + Vector2(-210 + 420 * u1, 10)
		draw_polygon(PackedVector2Array([t0, t1, b1, b0]),
				PackedColorArray([Color(1, 0.97, 0.85, a0), Color(1, 0.97, 0.85, a1),
						Color(1, 0.97, 0.85, a1 * 0.45), Color(1, 0.97, 0.85, a0 * 0.45)]))
	Toon.glow(self, spot + Vector2(0, 8), Vector2(230, 60), Color(1, 0.96, 0.8, (0.7 if on else 0.15) * flick), 3)


## The title in a marquee: a red board, a cream rule inside its edge, and a
## ring of lamps round it lighting in a chase.
func _marquee() -> void:
	var rect := Rect2(520, 70, 880, 200)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("a32a24")
	box.border_color = Toon.INK
	box.set_border_width_all(6)
	box.set_corner_radius_all(40)
	box.anti_aliasing = true
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 14
	box.shadow_offset = Vector2(8, 10)
	draw_style_box(box, rect)
	var rule := StyleBoxFlat.new()
	rule.bg_color = Color(0, 0, 0, 0)
	rule.border_color = GOLD
	rule.set_border_width_all(4)
	rule.set_corner_radius_all(28)
	rule.anti_aliasing = true
	draw_style_box(rule, rect.grow(-16))
	# Lamps round the board.
	var lamps := _rim_points(rect.grow(-4), 30)
	var chase := _drawing / 2
	for k in lamps.size():
		var lit := (k + chase) % 3 != 0
		var at := lamps[k]
		if lit:
			Toon.glow(self, at, Vector2(22, 22), Color(1, 0.9, 0.5, 0.55), 2)
		Toon.blob(self, at, Vector2(8, 8), Color("fff1a8") if lit else Color("8a6a3a"), 0, k, 3.0)
		if lit:
			Toon.spot(self, at + Vector2(-2.5, -2.5), Vector2(2.2, 2.2), Color(1, 1, 1, 0.9))
	# Stars either side of the name.
	for side: float in [-1.0, 1.0]:
		Toon.star(self, rect.get_center() + Vector2(side * 380, 4), 22.0, _clock * 0.5 * side, GOLD)


## [param n] points spaced evenly round a rounded rectangle.
func _rim_points(rect: Rect2, n: int) -> PackedVector2Array:
	var perimeter := (rect.size.x + rect.size.y) * 2.0
	var points := PackedVector2Array()
	for k in n:
		var d := perimeter * k / n
		var p: Vector2
		if d < rect.size.x:
			p = rect.position + Vector2(d, 0)
		elif d < rect.size.x + rect.size.y:
			p = Vector2(rect.end.x, rect.position.y + d - rect.size.x)
		elif d < rect.size.x * 2.0 + rect.size.y:
			p = Vector2(rect.end.x - (d - rect.size.x - rect.size.y), rect.end.y)
		else:
			p = Vector2(rect.position.x, rect.end.y - (d - rect.size.x * 2.0 - rect.size.y))
		# Pull the corners in to follow the rounding.
		var inset := Vector2(clampf(40.0 - minf(p.x - rect.position.x, rect.end.x - p.x), 0.0, 40.0),
				clampf(40.0 - minf(p.y - rect.position.y, rect.end.y - p.y), 0.0, 40.0))
		if inset.x > 0.0 and inset.y > 0.0:
			var toward := rect.get_center() - p
			p += Vector2(signf(toward.x), signf(toward.y)) * minf(inset.x, inset.y) * 0.3
		points.append(p)
	return points


## A playbill card under each brother: his name, a line about him, and his
## numbers as bars.
func _playbill(i: int) -> void:
	var character := GameData.character(IDS[i])
	var x: float = (SPOTS[i] as Vector2).x
	var on := i == index
	var card := Rect2(x - 250, 740, 500, 246)
	Frames.card(self, card, CREAM if on else Color("cdbd9c"), 0.97)
	for b in BARS.size():
		var row: Array = BARS[b]
		var value := float(character.get(row[1], 0.0)) / float(row[2])
		var y := 876.0 + b * 21.0
		draw_string(Ui.font(), Vector2(x - 210, y + 7), str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, 150, 19,
				Color("3a2418"))
		var bar := Rect2(x - 60, y - 7, 260, 14)
		var back := StyleBoxFlat.new()
		back.bg_color = Color("e2cfa6")
		back.border_color = Toon.INK
		back.set_border_width_all(2)
		back.set_corner_radius_all(7)
		draw_style_box(back, bar)
		var fill := StyleBoxFlat.new()
		fill.bg_color = BAR if on else Color("8d7a66")
		fill.set_corner_radius_all(6)
		var width := maxf(bar.size.x * clampf(value, 0.0, 1.0) - 4.0, 12.0)
		draw_style_box(fill, Rect2(bar.position + Vector2(2, 2), Vector2(width, bar.size.y - 4)))
		draw_line(bar.position + Vector2(8, 4), bar.position + Vector2(width - 4, 4), Color(1, 1, 1, 0.35), 2.0)


## Red velvet curtains drawn back to either side, a valance with a gold
## fringe across the top.
func _curtains() -> void:
	for side: float in [-1.0, 1.0]:
		var edge := 0.0 if side < 0.0 else 1920.0
		var width := 250.0
		var folds := 6
		for k in folds:
			var x0 := edge - side * (width * k / folds)
			var x1 := edge - side * (width * (k + 1) / folds)
			# Gathered in at the tie-back two-thirds of the way down.
			var pinch := 0.55 + 0.45 * float(k) / folds
			var tie := Vector2(edge - side * width * 0.55, 700)
			var top0 := Vector2(x0, 0)
			var top1 := Vector2(x1, 0)
			var mid0 := top0.lerp(tie, pinch * 0.9)
			var mid1 := top1.lerp(tie, pinch * 0.9)
			var bottom0 := Vector2(edge - side * (width * 1.1 * k / folds), 1080)
			var bottom1 := Vector2(edge - side * (width * 1.1 * (k + 1) / folds), 1080)
			var light := VELVET if k % 2 == 0 else VELVET.darkened(0.25)
			draw_polygon(PackedVector2Array([top0, top1, mid1, mid0]),
					PackedColorArray([light.darkened(0.3), light.darkened(0.3), light, light]))
			draw_polygon(PackedVector2Array([mid0, mid1, bottom1, bottom0]),
					PackedColorArray([light, light, light.darkened(0.35), light.darkened(0.35)]))
		# The inner edge in ink, and a gold tie-back cord with a tassel.
		var inner_top := Vector2(edge - side * width, 0)
		var tie := Vector2(edge - side * width * 0.55, 700)
		Toon.stroke(self, Toon.bent(inner_top, tie, side * 30.0), 6.0)
		Toon.stroke(self, Toon.bent(tie, Vector2(edge - side * width * 1.1, 1080), -side * 20.0), 6.0)
		Toon.stroke(self, PackedVector2Array([tie + Vector2(-side * 60, -10), tie + Vector2(side * 30, 8)]), 12.0)
		Toon.stroke(self, PackedVector2Array([tie + Vector2(-side * 60, -10), tie + Vector2(side * 30, 8)]), 7.0, GOLD)
		var tassel := tie + Vector2(side * 30, 8)
		Toon.shape(self, PackedVector2Array([tassel + Vector2(-9, 0), tassel + Vector2(9, 0), tassel + Vector2(14, 44),
				tassel + Vector2(-14, 44)]), GOLD, 4.0)
		Toon.ball(self, tassel, Vector2(10, 10), GOLD, 0, 3, 3.5)
	# The valance.
	draw_rect(Rect2(0, 0, 1920, 46), VELVET_DARK)
	for k in 12:
		var x := k * 160.0
		var swag := PackedVector2Array()
		for i in 13:
			var u := i / 12.0
			swag.append(Vector2(x + u * 160.0, 40 + sin(u * PI) * 34.0))
		var body := PackedVector2Array([Vector2(x, 0), Vector2(x + 160, 0)])
		for i in range(swag.size() - 1, -1, -1):
			body.append(swag[i])
		draw_colored_polygon(body, VELVET)
		Toon.stroke(self, swag, 9.0)
		Toon.stroke(self, swag, 5.0, GOLD)
		Toon.ball(self, Vector2(x, 44), Vector2(9, 12), GOLD, 0, 20 + k, 3.0)


## Footlights along the front of the stage.
func _footlights() -> void:
	draw_rect(Rect2(0, 1052, 1920, 28), Color("1a0e0a"))
	for k in 16:
		var at := Vector2(60 + k * 120.0, 1054)
		Toon.glow(self, at + Vector2(0, -20), Vector2(90, 50), Color(1, 0.9, 0.55, 0.35), 2)
		var shell := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			shell.append(at + Vector2(cos(a) * 26.0, sin(a) * 18.0))
		Toon.shape(self, shell, Color("3a302a"), 4.0)
		Toon.blob(self, at + Vector2(0, -6), Vector2(10, 8), Color("fff1a8"), 0, 40 + k, 3.0)
