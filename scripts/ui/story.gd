class_name Story
extends Node2D
## The story of the picture, told the way a silent picture told it: a card
## with the words, a scene, the next card. The opening (the Baron carries
## off the brothers' sweethearts, and down they go after them) plays before
## the first brother choice; the ending (the girls free, the Baron's hat in
## the dust) after the Baron is beaten.
##
## Enter, Space or A: the next shot. Esc or Start: skip the lot.

signal finished

## Each shot is a card of words, a scene for some seconds, or the end card.
## A card may change the record on the gramophone.
const OPENING: Array[Dictionary] = [
	{"card": "Жили-были два брата —\nСтарший и Младший…", "music": "menu"},
	{"scene": "sweethearts", "seconds": 4.0},
	{"card": "Но однажды ночью в город нагрянул\nБарон Когтев со своей бандой…", "music": "boss"},
	{"scene": "kidnap", "seconds": 4.5},
	{"card": "…и утащил подружек под землю —\nв самые катакомбы!"},
	{"scene": "descent", "seconds": 4.2},
	{"card": "Держись, Барон!\nБратья идут!", "music": "menu"},
]
const ENDING: Array[Dictionary] = [
	{"card": "Барон Когтев получил по заслугам…", "music": "menu"},
	{"scene": "reunion", "seconds": 4.5},
	{"end": "Конец"},
]
## The sweethearts: the older brother's tall girl with a bow, the
## younger's round one in a hat with a daisy.
const GIRLS: Array[Dictionary] = [
	{"build": "lanky", "top": "bow", "size": 0.96, "shirt": "#c8392b", "pants": "#c8392b",
			"shoes": "#c8392b", "accent": "#c8392b", "wear": "dress", "lashes": true},
	{"build": "chubby", "top": "flower", "size": 0.94, "shirt": "#3f6fb5", "pants": "#3f6fb5",
			"shoes": "ink", "accent": "#e0b23a", "wear": "dress", "lashes": true},
]
const CREAM := Color("f3e6c8")
const SEPIA := Color("1f140e")
const GOLD := Color("e0b23a")
const RED := Color("c8392b")
const GROUND := 830.0
## Black between two shots: a splice in the film.
const CUT := 0.12
## A scene opens out of a circle and closes down into one, the way the
## silent pictures went from scene to scene.
const IRIS_OPEN := 0.55
const IRIS_CLOSE := 0.45
## A circle this big shows the whole screen from its middle.
const IRIS_FULL := 1160.0

var shots: Array[Dictionary] = []

var _index := -1
var _t := 0.0
var _length := 0.0
var _cut := 0.0
var _clock := 0.0
var _drawing := -1
var _nav: MenuNav
var _words: Label
var _end: Label
## Figures of the scene now showing, and what moves them.
var _cast: Array[Node2D] = []
var _walkers: Array[BrotherLook] = []
var _hoppers: Array[Node2D] = []
var _over: Node2D
## Enemies want a room to look for brothers in; this one is never built.
var _room: Room
var _done := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_nav = MenuNav.new()
	_room = Room.new()
	var style := Ui.text(66, CREAM)
	style.line_spacing = 14.0
	_words = Ui.label("", style, 1360)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.size = Vector2(1360, 560)
	_words.position = Vector2(280, 250)
	add_child(_words)
	_end = Ui.label("", Ui.title(230), 1920)
	_end.size = Vector2(1920, 400)
	_end.position = Vector2(0, 330)
	_end.pivot_offset = _end.size * 0.5
	add_child(_end)
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	add_child(_over)
	_next()


func _exit_tree() -> void:
	if _room != null:
		_room.free()
		_room = null


## The story has every key while it runs, but for the fullscreen one.
func _input(event: InputEvent) -> void:
	if event.is_action("fullscreen"):
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	_t += delta
	var d := int(_clock * Toon.FPS)
	if d != _drawing or _cut > 0.0 or _iris() < IRIS_FULL:
		# The splice is redrawn every frame, so it lasts as long as it should.
		_drawing = d
		queue_redraw()
		_over.queue_redraw()
	_cut = maxf(_cut - delta, 0.0)
	_move_cast(delta)
	if _done:
		return
	if _nav.pressed("pause") or _nav.pressed("menu_back"):
		_finish()
	elif _nav.pressed("confirm") or _t >= _length:
		_next()


func _next() -> void:
	_index += 1
	if _index >= shots.size():
		_finish()
		return
	_clear_cast()
	var shot := shots[_index]
	_t = 0.0
	_cut = CUT
	_words.text = ""
	_end.text = ""
	if shot.has("music"):
		Music.play(str(shot["music"]))
	if shot.has("card"):
		var words := str(shot["card"])
		_words.text = words
		_length = clampf(1.6 + words.length() * 0.055, 2.6, 5.5)
	elif shot.has("end"):
		_end.text = str(shot["end"])
		_length = 3.5
	else:
		_length = float(shot.get("seconds", 4.0))
		_stage(str(shot["scene"]))
	queue_redraw()
	_over.queue_redraw()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


func _kind() -> String:
	if _index < 0 or _index >= shots.size():
		return ""
	var shot := shots[_index]
	if shot.has("card"):
		return "card"
	if shot.has("end"):
		return "end"
	return str(shot["scene"])


# --- the cast ----------------------------------------------------------------


func _brother(id: String, at: Vector2, face: Vector2, scale_by := 2.0) -> BrotherLook:
	return _look(GameData.character(id).get("look", {}), at, face, scale_by)


func _girl(i: int, at: Vector2, face: Vector2, scale_by := 2.0) -> BrotherLook:
	return _look(GIRLS[i], at, face, scale_by)


func _look(look: Dictionary, at: Vector2, face: Vector2, scale_by: float) -> BrotherLook:
	var figure := BrotherLook.new()
	figure.configure(look)
	figure.position = at
	figure.scale = Vector2(scale_by, scale_by)
	figure.facing = face
	add_child(figure)
	move_child(figure, _over.get_index())
	_cast.append(figure)
	return figure


func _enemy(enemy: Enemy, kind: String, at: Vector2, scale_by: float) -> Enemy:
	enemy.setup(kind, _room, RandomNumberGenerator.new())
	enemy._spawn = 0.0
	enemy.position = at
	enemy.scale = Vector2(scale_by, scale_by)
	add_child(enemy)
	move_child(enemy, _over.get_index())
	# After it is in: a node with _physics_process switches it on as it
	# enters the tree.
	enemy.set_physics_process(false)
	_cast.append(enemy)
	return enemy


func _stage(scene: String) -> void:
	match scene:
		"sweethearts", "reunion":
			var gap := 172.0 if scene == "sweethearts" else 150.0
			for pair in 2:
				var x := 620.0 + pair * 620.0
				var him := _brother(["older", "younger"][pair], Vector2(x - gap * 0.5, GROUND), Vector2.RIGHT)
				var her := _girl(pair, Vector2(x + gap * 0.5, GROUND), Vector2.LEFT)
				_hoppers.append(him)
				_hoppers.append(her)
		"kidnap":
			for i in 2:
				var him := _brother(["older", "younger"][i], Vector2(300 + i * 200, GROUND), Vector2.RIGHT)
				him.pose_shocked = true
			var baron := BaronBoss.new()
			baron.setup_boss(_room, RandomNumberGenerator.new(), 2)
			baron.position = Vector2(1130, GROUND + 10)
			baron.scale = Vector2(1.25, 1.25)
			add_child(baron)
			move_child(baron, _over.get_index())
			baron.set_physics_process(false)
			_cast.append(baron)
			_enemy(KittenEnemy.new(), "kitten", Vector2(840, GROUND + 20), 1.7)
			_enemy(KittenEnemy.new(), "kitten", Vector2(1760, GROUND + 20), 1.7)
			for i in 2:
				var her := _girl(i, Vector2(1420 + i * 120, GROUND - 14), Vector2.LEFT, 1.45)
				her.pose_shocked = true
		"descent":
			for i in 2:
				var him := _brother(["older", "younger"][i], Vector2(180 + i * 170, GROUND), Vector2.RIGHT)
				him.moving = true
				him.walk_rate = 1.1
				_walkers.append(him)


## The walkers walk towards the cellar; the couples hop, one of each pair
## a beat after the other.
func _move_cast(delta: float) -> void:
	for i in _walkers.size():
		# Up to the sign, and there they stop and read it.
		var stop := 640.0 + i * 170.0
		_walkers[i].position.x = minf(_walkers[i].position.x + 170.0 * delta, stop)
		_walkers[i].moving = _walkers[i].position.x < stop
	for i in _hoppers.size():
		var beat := _t * 3.6 + i * 0.9
		_hoppers[i].position.y = GROUND - absf(sin(beat)) * 26.0


func _clear_cast() -> void:
	for figure in _cast:
		figure.queue_free()
	_cast.clear()
	_walkers.clear()
	_hoppers.clear()


# --- drawing -------------------------------------------------------------------


func _draw() -> void:
	match _kind():
		"card", "end":
			_draw_card()
		"sweethearts", "reunion":
			_sunburst(Vector2(960, 330), Color("f0dcae"), Color("c79a5c"))
			_ground(Color("8a5a36"))
			if _kind() == "reunion":
				_hat(Vector2(300, 960))
		"kidnap", "descent":
			_night()
			if _kind() == "descent":
				_cellar(Vector2(1300, GROUND + 60))


## What goes over the figures: the cage bars, hearts, confetti, the
## speech bubble, the hint, and the black of a splice.
func _draw_over() -> void:
	match _kind():
		"sweethearts", "reunion":
			for pair in 2:
				_hearts(Vector2(620.0 + pair * 620.0, GROUND - 330), pair)
			if _kind() == "reunion":
				_confetti()
		"kidnap":
			_cage(Vector2(1480, GROUND + 6))
		"descent":
			if _t > 1.2:
				_bubble(Vector2(1440, 560), "Спаси-и-ите!")
	var iris := _iris()
	if iris < IRIS_FULL:
		_draw_iris(Vector2(960, 560), iris)
	var hint := "Enter — дальше   ·   Esc — пропустить"
	var font := Ui.font()
	_over.draw_string_outline(font, Vector2(0, 1046), hint, HORIZONTAL_ALIGNMENT_RIGHT, 1860, 24, 6, Toon.INK)
	_over.draw_string(font, Vector2(0, 1046), hint, HORIZONTAL_ALIGNMENT_RIGHT, 1860, 24, Color(CREAM, 0.45))
	if _cut > 0.0:
		_over.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.01, 0.01))


## The radius of the circle the scene now shows through: growing as it
## opens, shrinking at its end, the whole screen in between. Cards are not
## irised.
func _iris() -> float:
	var kind := _kind()
	if kind == "" or kind == "card" or kind == "end":
		return IRIS_FULL
	var k := 1.0
	if _t < IRIS_OPEN:
		k = ease(_t / IRIS_OPEN, 0.4)
	elif _t > _length - IRIS_CLOSE:
		k = ease(maxf(_length - _t, 0.0) / IRIS_CLOSE, 2.2)
	return IRIS_FULL * k


## Black round a circle of [param radius] at [param center].
func _draw_iris(center: Vector2, radius: float) -> void:
	var n := 72
	var far := 2400.0
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		_over.draw_colored_polygon(PackedVector2Array([center + d0 * radius, center + d1 * radius,
				center + d1 * far, center + d0 * far]), Color(0.02, 0.01, 0.01))


## A card of words: dark, the double rule round it, a little ornament over
## and under the words. The end card has a ribbon under its word.
func _draw_card() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), SEPIA)
	Toon.glow(self, Vector2(960, 540), Vector2(900, 520), Color(1, 0.9, 0.7, 0.07), 3)
	Frames.double_rule(self, Rect2(60, 60, 1800, 960))
	if _kind() == "end":
		var width := Ui.title_font().get_string_size(_end.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 230).x
		Frames.ribbon(self, Vector2(960, 540), width + 160.0, 230.0)
		for side: float in [-1.0, 1.0]:
			Toon.star(self, Vector2(960 + side * (width * 0.5 + 200.0), 540), 30.0, _clock * side, GOLD)
		return
	for y: float in [200.0, 880.0]:
		for side: float in [-1.0, 1.0]:
			draw_line(Vector2(960 + side * 40, y), Vector2(960 + side * 300, y), Color(CREAM, 0.6), 2.0)
		Toon.star(self, Vector2(960, y), 12.0, 0.0, GOLD)


func _sunburst(center: Vector2, light: Color, dark: Color) -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), dark)
	var rays := 32
	var turn := _clock * 0.03
	for i in rays:
		var a0 := turn + TAU * i / rays
		var a1 := turn + TAU * (i + 0.5) / rays
		draw_polygon(PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * 1600.0,
				center + Vector2(cos(a1), sin(a1)) * 1600.0]),
				PackedColorArray([light, Color(light, 0.0), Color(light, 0.0)]))
	Toon.glow(self, center, Vector2(700, 440), Color(1, 0.97, 0.85, 0.35), 3)


func _ground(color: Color) -> void:
	draw_rect(Rect2(0, GROUND - 10, 1920, 1090 - GROUND), color)
	Toon.hand_line(self, Vector2(0, GROUND - 10), Vector2(1920, GROUND - 10), 5.0, 17)
	for k in 26:
		var x := Toon.hash01(k, 1) * 1920.0
		var y := GROUND + 20 + Toon.hash01(k, 2) * 220.0
		draw_line(Vector2(x, y), Vector2(x + 40 + Toon.hash01(k, 3) * 60, y), Color(0, 0, 0, 0.18), 3.0)
	draw_polygon(PackedVector2Array([Vector2(0, GROUND - 10), Vector2(1920, GROUND - 10), Vector2(1920, GROUND + 50),
			Vector2(0, GROUND + 50)]), PackedColorArray([Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0),
			Color(0, 0, 0, 0)]))


## A night in town: dark sky, a crescent moon, stars, the roofs and
## chimneys of the street in black against it, cobbles underfoot.
func _night() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1920, 0), Vector2(1920, GROUND), Vector2(0, GROUND)]),
			PackedColorArray([Color("0f1420"), Color("0f1420"), Color("2b3040"), Color("2b3040")]))
	for k in 40:
		var at := Vector2(Toon.hash01(k, 21) * 1920.0, Toon.hash01(k, 22) * 520.0)
		var twinkle := 0.4 + 0.6 * Toon.hash01(k, _drawing / 3)
		draw_circle(at, 2.0 + Toon.hash01(k, 23) * 2.0, Color(CREAM, twinkle))
	var moon := Vector2(1600, 190)
	Toon.glow(self, moon, Vector2(220, 220), Color(1, 0.95, 0.8, 0.18), 3)
	Toon.blob(self, moon, Vector2(80, 80), Color("f3e6c8"), _drawing, 3, 4.0)
	Toon.blob(self, moon + Vector2(-38, -18), Vector2(70, 70), Color("0f1420"), 0, 4, 0.0)
	# Roofs.
	var x := -40.0
	var k := 0
	while x < 1960.0:
		var w := 180.0 + Toon.hash01(k, 31) * 160.0
		var h := 190.0 + Toon.hash01(k, 32) * 170.0
		var top := GROUND - h
		var roof := PackedVector2Array([Vector2(x, GROUND), Vector2(x, top + 40), Vector2(x + w * 0.5, top - 30),
				Vector2(x + w, top + 40), Vector2(x + w, GROUND)])
		draw_colored_polygon(roof, Color("07090e"))
		if Toon.hash01(k, 33) < 0.6:
			var cx := x + w * (0.2 + Toon.hash01(k, 34) * 0.2)
			draw_rect(Rect2(cx, top - 30, 26, 60), Color("07090e"))
		if Toon.hash01(k, 35) < 0.5:
			# A lit window.
			var win := Rect2(x + w * 0.4, top + 90, 34, 44)
			Toon.glow(self, win.get_center(), Vector2(60, 60), Color(1, 0.8, 0.4, 0.2), 2)
			draw_rect(win, Color("e8b85a"))
			draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y),
					Color("07090e"), 4.0)
		x += w - 10.0
		k += 1
	draw_rect(Rect2(0, GROUND - 10, 1920, 1090 - GROUND), Color("26221e"))
	Toon.hand_line(self, Vector2(0, GROUND - 10), Vector2(1920, GROUND - 10), 5.0, 18)
	for row in 6:
		var y := GROUND + 16 + row * row * 9.0 + row * 24.0
		for col in 24:
			var cx := col * 90.0 + (45.0 if row % 2 == 1 else 0.0)
			Toon.spot(self, Vector2(cx, y), Vector2(34, 8 + row * 1.5), Color(1, 1, 1, 0.05), 0, row * 30 + col, 0.0)


## The way down: a cellar hatch in the ground, its two doors thrown open,
## black inside, and a sign on a post.
func _cellar(at: Vector2) -> void:
	var hole := PackedVector2Array([at + Vector2(-150, -40), at + Vector2(150, -40), at + Vector2(180, 40),
			at + Vector2(-180, 40)])
	Toon.shape(self, hole, Color("050404"), 6.0)
	for step in 3:
		var y := -20.0 + step * 22.0
		draw_line(at + Vector2(-140 + step * 8, y), at + Vector2(140 - step * 8, y), Color(1, 1, 1, 0.07), 6.0)
	for side: float in [-1.0, 1.0]:
		var hinge := at + Vector2(side * 160, 0)
		var door := PackedVector2Array([hinge + Vector2(0, -40), hinge + Vector2(side * 150, -60),
				hinge + Vector2(side * 170, 30), hinge + Vector2(side * 16, 40)])
		Toon.shape(self, door, Color("7a4c2c"), 5.0)
		for plank in 3:
			var u := (plank + 1) / 4.0
			draw_line(door[0].lerp(door[3], u), door[1].lerp(door[2], u), Color(0, 0, 0, 0.35), 3.0)
	var post := at + Vector2(-300, 10)
	Toon.stroke(self, PackedVector2Array([post, post + Vector2(0, -220)]), 14.0)
	Toon.stroke(self, PackedVector2Array([post, post + Vector2(0, -220)]), 8.0, Color("7a4c2c"))
	var board := Rect2(post + Vector2(-110, -270), Vector2(220, 70))
	draw_rect(board.grow(6), Toon.INK)
	draw_rect(board, Color("c9ad7a"))
	draw_string(Ui.font(), board.position + Vector2(0, 50), "ПОДВАЛ", HORIZONTAL_ALIGNMENT_CENTER, board.size.x,
			40, Toon.INK)


## A birdcage on the ground: gold bars in a dome, a ring on top. Drawn
## over the girls inside it.
func _cage(base: Vector2) -> void:
	var half := 190.0
	var height := 330.0
	var gold := Color("c9a03a")
	var top := base.y - height
	var dome := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		dome.append(Vector2(base.x + cos(a) * half, top + 60 + sin(a) * 80))
	Toon.stroke(_over, dome, 12.0)
	Toon.stroke(_over, dome, 6.0, gold)
	for k in 9:
		var u := float(k) / 8.0
		var x := base.x - half + u * half * 2.0
		var y_top := top + 60 - sin(u * PI) * 80
		Toon.stroke(_over, PackedVector2Array([Vector2(x, y_top), Vector2(x, base.y)]), 9.0)
		Toon.stroke(_over, PackedVector2Array([Vector2(x, y_top), Vector2(x, base.y)]), 4.0, gold)
	for y: float in [base.y - 6.0, top + 170.0]:
		Toon.stroke(_over, PackedVector2Array([Vector2(base.x - half - 6, y), Vector2(base.x + half + 6, y)]), 14.0)
		Toon.stroke(_over, PackedVector2Array([Vector2(base.x - half - 6, y), Vector2(base.x + half + 6, y)]), 7.0, gold)
	var ring := Vector2(base.x, top - 40)
	_over.draw_arc(ring, 22.0, 0.0, TAU, 24, Toon.INK, 11.0, true)
	_over.draw_arc(ring, 22.0, 0.0, TAU, 24, gold, 5.0, true)
	Toon.shine(_over, Vector2(base.x - half * 0.6, top + 180), Vector2(5, 60), 0.3)


## Hearts rising and swaying from between two heads, fading as they go.
func _hearts(at: Vector2, pair: int) -> void:
	for k in 3:
		var rise := fmod(_t * 0.45 + k / 3.0 + pair * 0.17, 1.0)
		var p := at + Vector2(sin(_t * 2.5 + k * 2.0) * 24.0, -rise * 190.0)
		var size := 22.0 + 10.0 * sin(rise * PI)
		var color := Color(RED, 1.0 - rise * rise)
		if color.a > 0.1:
			_over.draw_colored_polygon(Toon.heart_points(p, size + 8.0), Color(Toon.INK, color.a))
			_over.draw_colored_polygon(Toon.heart_points(p, size), color)


func _confetti() -> void:
	var colors := [GOLD, RED, CREAM, Color("3f6fb5")]
	for i in 30:
		var fall := fmod(_clock * (0.18 + Toon.hash01(i, 1) * 0.12) + Toon.hash01(i, 2), 1.0)
		var x := 120.0 + Toon.hash01(i, 3) * 1680.0 + sin(_clock * 2.0 + i) * 20.0
		var y := -40.0 + fall * 1100.0
		var color: Color = colors[i % colors.size()]
		if i % 3 == 0:
			Toon.star(_over, Vector2(x, y), 12.0, _clock * 2.0 + i, color)
		else:
			var a := _clock * 4.0 + i
			_over.draw_line(Vector2(x, y) + Vector2(cos(a), sin(a)) * 9.0, Vector2(x, y) - Vector2(cos(a), sin(a)) * 9.0,
					color, 6.0)


## A speech bubble, ink-edged cream, its tail pointing down to where the
## voice comes from.
func _bubble(at: Vector2, words: String) -> void:
	var font := Ui.font()
	var size := 44
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 80.0
	var shake := Vector2(Toon.hash01(_drawing, 1) - 0.5, Toon.hash01(_drawing, 2) - 0.5) * 5.0
	var center := at + shake
	var tail := PackedVector2Array([center + Vector2(-60, 40), center + Vector2(-10, 44), center + Vector2(-110, 190)])
	Toon.shape(_over, tail, CREAM, 5.0)
	Toon.blob(_over, center, Vector2(width * 0.5, 62), CREAM, _drawing, 9, 5.0)
	_over.draw_string(font, center + Vector2(-width * 0.5, 15), words, HORIZONTAL_ALIGNMENT_CENTER, width, size,
			Toon.INK)


## The Baron's top hat lying in the dust, crushed, a hole shot through it,
## a star or two still going round it.
func _hat(at: Vector2) -> void:
	var tilt := -0.35
	draw_set_transform(at, tilt, Vector2.ONE)
	Toon.spot(self, Vector2(10, 30), Vector2(120, 22), Color(0, 0, 0, 0.3))
	Toon.ball(self, Vector2(0, 16), Vector2(110, 22), Color("2a1f30"), _drawing, 5, 5.0)
	var crown := PackedVector2Array([Vector2(-66, 12), Vector2(-60, -120), Vector2(-20, -104), Vector2(8, -132),
			Vector2(62, -118), Vector2(66, 12)])
	Toon.shape(self, crown, Color("2a1f30"), 5.0)
	draw_rect(Rect2(-64, -20, 129, 26), Color(BaronBoss.COAT))
	Toon.spot(self, Vector2(22, -70), Vector2(15, 13), Color("0a0608"))
	Toon.spot(self, Vector2(24, -72), Vector2(6, 5), Color(1, 0.9, 0.7, 0.8))
	Toon.shine(self, Vector2(-40, -60), Vector2(6, 40), 0.3)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 3:
		var a := _clock * 3.0 + TAU * i / 3.0
		Toon.star(self, at + Vector2(cos(a) * 110.0, -150.0 + sin(a) * 24.0), 13.0, a, Color("f2c14e"))
