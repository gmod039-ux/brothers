class_name CardMenu
extends Node2D
## A card of choices over the dimmed screen, framed and lettered like the
## cards between the scenes of a silent picture: the pause, the settings.
## Steered by anything ([MenuNav]): up and down pick a line, left and right
## turn a setting, confirm takes the choice, Esc (Start) or Backspace (B)
## backs out.
##
## A line is {"id", "text"} and, for a setting, a "level" (0 to 1, in
## tenths: a row of lamps) or a "toggle" (да / нет). Turning one emits
## [signal changed] at once, so the music is heard getting louder as the
## lamps light.

## A line without a setting was chosen.
signal picked(id: String)
signal changed(id: String, value: Variant)
## Backed out of: Esc, or the gamepad's B.
signal closed

const CREAM := Color("f3e6c8")
const SEPIA := Color("1f140e")
const GOLD := Color("e0b23a")
const WIDTH := 940.0
const ROW := 76.0
const LAMPS := 10

var title := ""
var lines: Array[Dictionary] = []
## Pictures of items in a row under the lines: what the brothers carry.
var items: Array[String] = []
## Small lines under the items: the brothers' numbers.
var notes: PackedStringArray = []
var hint := ""
var index := 0
## Only the card on top listens; the one under it waits (see [method wake]).
var active := true
## Actions that go past the card to Main: the fullscreen key, R.
var let_through: Array[String] = ["fullscreen"]

var _nav: MenuNav
var _title: Label
var _clock := 0.0
var _drawing := -1
var _pop := 1.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_nav = MenuNav.new()
	_title = Ui.label(title, Ui.title(Ui.fit(title, 92, WIDTH - 300.0)))
	_title.position = Vector2(0, _card().position.y + 44.0)
	add_child(_title)
	_pop = 0.3
	var tween := create_tween()
	for step: float in [0.75, 1.1, 1.0]:
		tween.tween_callback(func() -> void:
			_pop = step
			_title.scale = Vector2(step, step)
			queue_redraw())
		tween.tween_interval(1.0 / Toon.FPS)


## Back on top, once the card over it has gone: the key that closed that
## one must not act on this one too.
func wake() -> void:
	active = true
	visible = true
	_nav.hold()


## The card on top has every key: nothing under it hears one, except the
## few let through.
func _input(event: InputEvent) -> void:
	if not active:
		return
	for action in let_through:
		if event.is_action(action):
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	var d := int(_clock * Toon.FPS)
	if d != _drawing:
		_drawing = d
		queue_redraw()
	if not active or lines.is_empty():
		return
	var step := _nav.step(delta)
	if step.y != 0:
		index = wrapi(index + step.y, 0, lines.size())
		Sfx.play("select", -6.0, 0.0)
		queue_redraw()
	elif step.x != 0:
		_turn(step.x)
	if _nav.pressed("confirm"):
		_choose()
	elif _nav.pressed("pause") or _nav.pressed("menu_back"):
		Sfx.play("select", -6.0, 0.0)
		close()


## Backs out: the card goes and says so.
func close() -> void:
	closed.emit()
	queue_free()


## Shows [param v] for the setting [param id], changed from elsewhere (F11).
func set_value(id: String, v: Variant) -> void:
	for line in lines:
		if line.get("id") == id:
			if line.has("level"):
				line["level"] = v
			elif line.has("toggle"):
				line["toggle"] = v
	queue_redraw()


func _turn(dir: int) -> void:
	var line := lines[index]
	if line.has("level"):
		var old := float(line["level"])
		var now := snappedf(clampf(old + dir * 0.1, 0.0, 1.0), 0.1)
		if now == old:
			return
		line["level"] = now
		changed.emit(line["id"], now)
	elif line.has("toggle"):
		line["toggle"] = not bool(line["toggle"])
		changed.emit(line["id"], line["toggle"])
	else:
		return
	Sfx.play("select", -4.0, 0.0)
	queue_redraw()


func _choose() -> void:
	var line := lines[index]
	if line.has("toggle"):
		_turn(1)
		return
	if line.has("level"):
		return
	Sfx.play("confirm", -4.0, 0.0)
	picked.emit(str(line["id"]))


## Settings have their value at the right and read left to right; a card
## of plain choices has them centred.
func _has_values() -> bool:
	for line in lines:
		if line.has("level") or line.has("toggle"):
			return true
	return false


func _card() -> Rect2:
	var height := 200.0 + lines.size() * ROW + (110.0 if not items.is_empty() else 0.0) + notes.size() * 34.0 \
			+ (92.0 if hint != "" else 20.0)
	return Rect2(960.0 - WIDTH * 0.5, 540.0 - height * 0.5, WIDTH, height)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.06, 0.04, 0.03, 0.66))
	var card := _card()
	Frames.card(self, card.grow(6), SEPIA, 0.97)
	Frames.double_rule(self, card.grow(-22))
	var width := Ui.title_font().get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			_title.label_settings.font_size).x
	Frames.ribbon(self, Vector2(960, card.position.y + 96.0), (width + 120.0) * _pop, 124.0 * _pop)
	_title.pivot_offset = _title.size * 0.5
	var top := card.position.y + 196.0
	var centred := not _has_values()
	for i in lines.size():
		_line(i, Vector2(card.position.x, top + i * ROW), centred)
	var below := top + lines.size() * ROW
	if not items.is_empty():
		_item_row(Vector2(960, below + 46.0))
		below += 110.0
	for note in notes:
		var font := Ui.font()
		# Shrunk to fit inside the frame, whatever the numbers come to.
		var size := 24
		var wide := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if wide > WIDTH - 140.0:
			size = int(size * (WIDTH - 140.0) / wide)
		draw_string_outline(font, Vector2(card.position.x, below + 22.0), note, HORIZONTAL_ALIGNMENT_CENTER,
				WIDTH, size, 6, Toon.INK)
		draw_string(font, Vector2(card.position.x, below + 22.0), note, HORIZONTAL_ALIGNMENT_CENTER,
				WIDTH, size, Color(GOLD, 0.85))
		below += 34.0
	if hint != "":
		var font := Ui.font()
		draw_string_outline(font, Vector2(card.position.x, below + 36.0), hint, HORIZONTAL_ALIGNMENT_CENTER,
				WIDTH, 26, 6, Toon.INK)
		draw_string(font, Vector2(card.position.x, below + 36.0), hint, HORIZONTAL_ALIGNMENT_CENTER,
				WIDTH, 26, Color(CREAM, 0.6))


## One line: its words, the lamps or да/нет of its setting, and when it
## is the chosen one a band of light behind it and a star pointing at it.
func _line(i: int, at: Vector2, centred: bool) -> void:
	var line := lines[i]
	var on := i == index and active
	var y := at.y + ROW * 0.5
	var font := Ui.font()
	var size := 40
	if on:
		var band := Rect2(at.x + 60.0, at.y + 6.0, WIDTH - 120.0, ROW - 12.0)
		draw_rect(band, Color(GOLD, 0.13))
		draw_line(band.position, Vector2(band.end.x, band.position.y), Color(GOLD, 0.35), 2.0)
		draw_line(Vector2(band.position.x, band.end.y), band.end, Color(GOLD, 0.35), 2.0)
	var text := str(line["text"])
	var color := CREAM if on else Color(CREAM, 0.55)
	var baseline := y + size * 0.36
	var x := at.x + 120.0
	var span := WIDTH - 240.0
	var align := HORIZONTAL_ALIGNMENT_LEFT
	if centred:
		x = at.x
		span = WIDTH
		align = HORIZONTAL_ALIGNMENT_CENTER
	draw_string_outline(font, Vector2(x, baseline), text, align, span, size, 8, Toon.INK)
	draw_string(font, Vector2(x, baseline), text, align, span, size, color)
	if on:
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var star_x := (960.0 - text_w * 0.5 - 44.0) if centred else (at.x + 88.0)
		var bob := sin(_clock * 6.0) * 4.0
		Toon.star(self, Vector2(star_x + bob, y), 14.0, _clock * 1.5, GOLD)
		if centred:
			Toon.star(self, Vector2(960.0 + text_w * 0.5 + 44.0 - bob, y), 14.0, -_clock * 1.5, GOLD)
	if line.has("level"):
		_lamps(float(line["level"]), Vector2(at.x + WIDTH - 110.0, y), on)
	elif line.has("toggle"):
		_yes_no(bool(line["toggle"]), Vector2(at.x + WIDTH - 110.0, y), on)


## A row of lamps, as many lit as the level in tenths, right-aligned at
## [param right]; arrows either side on the chosen line.
func _lamps(level: float, right: Vector2, on: bool) -> void:
	var step := 27.0
	var lit := roundi(level * LAMPS)
	var x0 := right.x - (LAMPS - 1) * step
	for k in LAMPS:
		var p := Vector2(x0 + k * step, right.y)
		if k < lit:
			Toon.glow(self, p, Vector2(20, 20), Color(1, 0.88, 0.45, 0.5 if on else 0.25), 2)
			Toon.blob(self, p, Vector2(9, 9), Color("fff1a8") if on else Color("c9ad6a"), 0, k, 3.0)
			Toon.spot(self, p + Vector2(-2.5, -2.5), Vector2(2.4, 2.4), Color(1, 1, 1, 0.85))
		else:
			Toon.blob(self, p, Vector2(8, 8), Color("4a3a2c"), 0, k, 3.0)
	if on:
		_arrow(Vector2(x0 - 30.0, right.y), -1.0, lit > 0)
		_arrow(Vector2(right.x + 30.0, right.y), 1.0, lit < LAMPS)


func _yes_no(yes: bool, right: Vector2, on: bool) -> void:
	var font := Ui.font()
	var words := [["да", true], ["нет", false]]
	var x := right.x - 190.0
	for word: Array in words:
		var chosen: bool = word[1] == yes
		var w := font.get_string_size(word[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
		var color := GOLD if chosen else Color(CREAM, 0.3)
		if not on and chosen:
			color = Color(GOLD, 0.7)
		var baseline := Vector2(x, right.y + 13.0)
		draw_string_outline(font, baseline, word[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 36, 7, Toon.INK)
		draw_string(font, baseline, word[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 36, color)
		if chosen:
			draw_line(baseline + Vector2(-2, 10), baseline + Vector2(w + 2, 10), color, 3.0)
		x += w + 44.0
	if on:
		_arrow(Vector2(right.x - 222.0, right.y), -1.0, true)
		_arrow(Vector2(right.x + 30.0, right.y), 1.0, true)


func _arrow(at: Vector2, side: float, lit: bool) -> void:
	var points := PackedVector2Array([at + Vector2(side * 11.0, 0), at + Vector2(-side * 7.0, -11.0),
			at + Vector2(-side * 7.0, 11.0)])
	Toon.shape(self, points, CREAM if lit else Color(CREAM, 0.25), 3.0)


func _item_row(at: Vector2) -> void:
	var shown := items.slice(0, 12)
	var step := 72.0
	var x0 := at.x - (shown.size() - 1) * step * 0.5
	for i in shown.size():
		var p := Vector2(x0 + i * step, at.y)
		Toon.blob(self, p, Vector2(30, 30), Color(CREAM, 0.14), 0, i, 2.0)
		ItemIcon.draw(self, shown[i], p, 46.0, _drawing / 3)
