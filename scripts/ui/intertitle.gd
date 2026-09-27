class_name Intertitle
extends Node2D
## The cards between the scenes of a silent picture: the end of a run and
## the way out. (The pause is a [CardMenu].)
##   "dead"   the brother flat on his back with stars going round, "Эх,
##            братец…", and what he got done
##   "won"    the brother dancing under a shower of stars, "Выбрались!"
## Each is lettered like a title card and framed like one: a double rule
## with fans in the corners. Pops in over three drawings.

const CREAM := Color("f3e6c8")
const SEPIA := Color("1f140e")
const GOLD := Color("e0b23a")
const RED := Color("b8322a")

var _kind := ""
var _title: Label
var _lines: Label
var _hint: Label
var _figures: Array[BrotherLook] = []
var _items: Array[String] = []
var _clock := 0.0
var _drawing := -1
var _pop := 1.0
var _shown_at := 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _ready() -> void:
	_title = Ui.label("", Ui.title(120))
	add_child(_title)
	var line_style := Ui.text(34, CREAM)
	line_style.line_spacing = 6.0
	_lines = Ui.label("", line_style)
	add_child(_lines)
	_hint = Ui.label("", Ui.text(30, CREAM))
	add_child(_hint)


## Puts up the card. [param lines] are the numbers of the run, one to a line;
## [param looks] the brothers' looks, one figure each; [param items] the
## items they had, shown as a row of pictures.
func show_card(kind: String, title: String, lines: PackedStringArray, hint: String,
		looks: Array[Dictionary] = [], items: Array[String] = []) -> void:
	_kind = kind
	_items = items
	_title.text = title
	_lines.text = "\n".join(lines)
	_hint.text = hint
	_clear_figures()
	_title.label_settings.font_size = Ui.fit(title, 116, 1300.0)
	_title.size = Vector2(1920, 180)
	_title.position = Vector2(0, 76)
	_lines.size = Vector2(1920, 300)
	_lines.position = Vector2(0, 660)
	_lines.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_hint.position = Vector2(0, 958)
	_shown_at = Time.get_ticks_msec()
	for i in looks.size():
		var figure := BrotherLook.new()
		figure.configure(looks[i])
		figure.scale = Vector2(2.0, 2.0)
		figure.position = Vector2(960 + (i - (looks.size() - 1) * 0.5) * 260.0, 600)
		figure.knocked = kind == "dead"
		figure.moving = kind == "won"
		figure.walk_rate = 1.4 - i * 0.2
		add_child(figure)
		move_child(figure, 0)
		_figures.append(figure)
	visible = true
	_pop = 0.3
	var tween := create_tween()
	for step: float in [0.75, 1.1, 1.0]:
		tween.tween_callback(func() -> void:
			_pop = step
			_title.scale = Vector2(step, step)
			queue_redraw())
		tween.tween_interval(1.0 / Toon.FPS)


## The card has been up long enough to be read: a key held from the fight
## (the A button shoots down) must not throw it away unseen.
func is_settled() -> bool:
	return visible and Time.get_ticks_msec() - _shown_at > 700


func hide_card() -> void:
	visible = false
	_kind = ""
	_clear_figures()


func _clear_figures() -> void:
	for figure in _figures:
		figure.queue_free()
	_figures.clear()


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	var d := int(_clock * Toon.FPS)
	if d != _drawing:
		_drawing = d
		queue_redraw()


func _draw() -> void:
	if _kind == "":
		return
	_title.pivot_offset = _title.size * 0.5
	draw_rect(Rect2(0, 0, 1920, 1080), SEPIA)
	# A sunburst, faint, behind the figure: the title card of a picture.
	var center := Vector2(960, 470)
	var rays := 28
	for i in rays:
		var a0 := TAU * i / rays + _clock * (0.03 if _kind == "won" else 0.0)
		var a1 := a0 + TAU * 0.5 / rays
		var tint := Color(GOLD, 0.1) if _kind == "won" else Color(CREAM, 0.05)
		draw_polygon(PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * 1400.0,
				center + Vector2(cos(a1), sin(a1)) * 1400.0]),
				PackedColorArray([tint, Color(tint, 0.0), Color(tint, 0.0)]))
	Toon.glow(self, center, Vector2(560, 360), Color(1, 0.9, 0.7, 0.12), 3)
	_frame(Vector2(1920, 1080), 40.0)
	# A ribbon behind the title.
	var width := Ui.title_font().get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_title.label_settings.font_size).x
	Frames.ribbon(self, Vector2(960, 170), (width + 140.0) * _pop, 150.0 * _pop,
			RED if _kind == "dead" else Color("a8781f"))
	# The floor under the figures.
	Toon.glow(self, Vector2(960, 612), Vector2(210 + 130 * maxi(_figures.size() - 1, 0), 34), Color(0, 0, 0, 0.6), 2)
	if _kind == "won":
		_confetti()
	_item_row()
	# A thin rule over the hint.
	for side: float in [-1.0, 1.0]:
		draw_line(Vector2(960 + side * 120, 945), Vector2(960 + side * 560, 945), Color(CREAM, 0.5), 2.0)
		Toon.star(self, Vector2(960 + side * 100, 945), 7.0, 0.0, CREAM)


## Pictures of the items he had, in a row under the numbers.
func _item_row(at := Vector2(960, 890)) -> void:
	if _items.is_empty():
		return
	var shown := _items.slice(0, 12)
	var step := 72.0
	var x0 := at.x - (shown.size() - 1) * step * 0.5
	for i in shown.size():
		var p := Vector2(x0 + i * step, at.y)
		Toon.blob(self, p, Vector2(30, 30), Color(CREAM, 0.14), 0, i, 2.0)
		ItemIcon.draw(self, shown[i], p, 46.0, _drawing / 3)


## Stars and streamers falling on the dancer.
func _confetti() -> void:
	for i in 26:
		var fall := fmod(_clock * (0.18 + Toon.hash01(i, 1) * 0.12) + Toon.hash01(i, 2), 1.0)
		var x := 240.0 + Toon.hash01(i, 3) * 1440.0 + sin(_clock * 2.0 + i) * 20.0
		var y := -40.0 + fall * 1100.0
		var colors := [GOLD, RED, CREAM, Color("3f6fb5")]
		var color: Color = colors[i % colors.size()]
		if i % 3 == 0:
			Toon.star(self, Vector2(x, y), 12.0, _clock * 2.0 + i, color)
		else:
			var a := _clock * 4.0 + i
			draw_line(Vector2(x, y) + Vector2(cos(a), sin(a)) * 9.0, Vector2(x, y) - Vector2(cos(a), sin(a)) * 9.0,
					color, 6.0)


## The double rule round a title card, with a fan in each corner.
func _frame(size: Vector2, inset: float) -> void:
	Frames.double_rule(self, Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0))
