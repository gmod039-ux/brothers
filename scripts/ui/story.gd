class_name Story
extends Node2D
## The story of the picture, told as a little cartoon of its own in the
## game's own ink: the same brothers, the same Baron and his kittens,
## walking, leaping and getting knocked flat on a painted street, a camera
## that pans and pushes in, and a card of words between the acts the way a
## silent picture had them.
##
## The opening: one evening the brothers meet their sweethearts under the
## lamp outside the cafe. Night falls, the lights go out, the manhole
## cover flies off and the Baron climbs out with his kittens; he pulls a
## cage out of his hat and drops it on the girls, his kittens knock the
## brothers flat, and down the sewer they all go. The brothers come to, a
## card flutters down -- the Baron's: see you in the catacombs -- and they
## run for the cellar. The ending: the cage bursts, the girls run into
## their arms, confetti.
##
## Each scene is a function of the time into it ([method _act]): where
## everyone stands, which way they look, what pose -- so a shot can be
## skipped or cut short with nothing left half done. Sounds and bursts go
## off once, as the clock passes their moment ([method _on]).
##
## Enter, Space or A: the next shot. Esc or Start: skip the lot.

signal finished

## Each shot is a card of words, a scene for some seconds, or the end card.
## A card or scene may change the record on the gramophone. A scene opens
## out of a circle and closes down into one, unless it "open"s or
## "close"s on a "cut": two shots of the same moment, cut together.
const OPENING: Array[Dictionary] = [
	{"card": "Жили-были два брата —\nСтарший и Младший…", "music": "menu"},
	{"scene": "evening", "seconds": 9.0},
	{"card": "Но однажды ночью в город нагрянул\nБарон Когтев со своей бандой…", "music": "boss"},
	{"scene": "arrival", "seconds": 8.6, "close": "cut"},
	{"scene": "kidnap", "seconds": 10.6, "open": "cut"},
	{"scene": "aftermath", "seconds": 7.6, "close": "cut"},
	{"scene": "note", "seconds": 5.2, "open": "cut"},
	{"scene": "chase", "seconds": 6.8, "music": "floor0"},
	{"card": "Держись, Барон!\nБратья идут!", "music": "menu"},
]
const ENDING: Array[Dictionary] = [
	{"card": "Барон Когтев получил по заслугам…", "music": "menu"},
	{"scene": "reunion", "seconds": 8.5},
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
## The scenes in the street, with the sky over them.
const STREET := ["evening", "arrival", "kidnap", "aftermath", "chase"]
## The line on the pavement the cast stands on, and how big they are.
const WALK := 815.0
const FIGURE := 1.7
const HOLE := Vector2(1780, 965)
const HOLE_R := Vector2(118, 32)
const HATCH := Vector2(2700, 838)
const HATCH_R := Vector2(150, 30)
## Where the manhole cover lands when it flies off.
const LID_REST := Vector2(1560, 1045)
## Where the kittens land out of the manhole, and how long each leap takes.
const KITTEN_SPOTS: Array[Vector2] = [Vector2(700, 1030), Vector2(1250, 1050), Vector2(2150, 1010)]
const KITTEN_LEAPS: Array[float] = [0.8, 0.6, 0.5]
const BARON_SPOT := Vector2(1960, 1010)
const BARON_SIZE := 1.3
## Where the cage comes down on the girls.
const CAGE_AT := Vector2(1150, 860)
## The ending's ground, and its cage.
const GROUND := 830.0
const CAGE_END := Vector2(1300, 852)
## Black between two shots: a splice in the film.
const CUT := 0.12
const IRIS_OPEN := 0.55
const IRIS_CLOSE := 0.5

var shots: Array[Dictionary] = []

var _index := -1
var _t := 0.0
## [member _t] the frame before: what [method _on] goes by.
var _was := -1.0
var _length := 0.0
var _cut := 0.0
var _clock := 0.0
var _drawing := -1
var _nav: MenuNav
var _words: Label
var _end: Label
var _done := false
## Enemies want a room to look for brothers in; this one is never built.
var _room: Room

## The layers: the sky (it pans slower), the world the camera looks at --
## the painted set, the cast (clipped where they go down a hole), what is
## drawn over them, bursts -- and the screen: iris, splice, hint.
var _far: Node2D
var _world: Node2D
var _set: Node2D
var _lit: Node2D
var _road: Node2D
var _mask: Node2D
var _props: Node2D
var _fx: Node2D
var _screen: Node2D
var _set_drawn := ""

var _cam := Vector2(960, 540)
var _zoom := 1.0
var _shake := 0.0

## The light of the street: 0 dusk, 1 night; the windows lit; the lamps.
var _night := 1.0
var _lights := 1.0
var _lamp := 1.0
## Openings the cast can go down: [centre, radii, square-edged].
var _holes: Array = []

var _cast: Array[Node2D] = []
var _older: BrotherLook
var _younger: BrotherLook
var _girls: Array[BrotherLook] = []
var _baron: FilmBaron
var _kittens: Array[FilmKitten] = []
var _cage: Node2D
var _cage_ground := Vector2.ZERO
var _cage_height := 0.0
var _cage_squeeze := Vector2.ONE
var _cage_shadow := 0.0


## The Baron as an actor: his eyes go where the scene sends them.
class FilmBaron:
	extends BaronBoss

	var look := Vector2.ZERO

	func gaze() -> Vector2:
		return look


## A kitten as an actor: where it looks, and how high it leaps.
class FilmKitten:
	extends KittenEnemy

	var look := Vector2.ZERO

	func _init() -> void:
		_spawn = 0.0

	func gaze() -> Vector2:
		return look

	## [param height] in the street's pixels, whatever its scale.
	func leap(height: float) -> void:
		_height = height / scale.y


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_nav = MenuNav.new()
	_room = Room.new()
	_far = _layer(self, _draw_far)
	_world = Node2D.new()
	add_child(_world)
	_set = _layer(_world, _draw_set)
	_lit = _layer(_world, _draw_lights)
	_road = _layer(_world, _draw_road)
	_mask = _layer(_world, _draw_mask)
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_props = _layer(_world, _draw_props)
	_fx = Node2D.new()
	_world.add_child(_fx)
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
	_screen = _layer(self, _draw_screen)
	_next()


func _layer(parent: Node, painter: Callable) -> Node2D:
	var layer := Node2D.new()
	layer.draw.connect(painter)
	parent.add_child(layer)
	return layer


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
	_was = _t
	_t += delta
	_cut = maxf(_cut - delta, 0.0)
	_shake = maxf(_shake - delta, 0.0)
	var d := int(_clock * Toon.FPS)
	if d != _drawing:
		_drawing = d
		queue_redraw()
		_far.queue_redraw()
	if _scene() != "":
		_act()
		_camera()
		_sort_cast()
	_props.queue_redraw()
	_screen.queue_redraw()
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
	_was = -1.0
	_cut = 0.0 if str(shot.get("open", "")) == "cut" else CUT
	_words.text = ""
	_end.text = ""
	_far.visible = false
	_world.visible = false
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
		_act()
		_camera()
		_sort_cast()
	_set_drawn = ""
	queue_redraw()
	_far.queue_redraw()
	_set.queue_redraw()
	_lit.queue_redraw()
	_road.queue_redraw()
	_mask.queue_redraw()


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


## The scene showing, or "" between them.
func _scene() -> String:
	var kind := _kind()
	return "" if kind in ["", "card", "end"] else kind


# --- time ----------------------------------------------------------------------


## True on the one frame the shot passes [param moment].
func _on(moment: float) -> bool:
	return _was < moment and _t >= moment


## 0 before [param from], 1 after [param to], straight between.
func _lin(from: float, to: float) -> float:
	return clampf((_t - from) / (to - from), 0.0, 1.0)


## The same, eased in and out.
func _ease(from: float, to: float) -> float:
	return smoothstep(from, to, _t)


## A hop: up and down again between [param from] and [param to].
func _hop(from: float, to: float, height: float) -> float:
	if _t <= from or _t >= to:
		return 0.0
	return sin(_lin(from, to) * PI) * height


# --- the cast ------------------------------------------------------------------


func _person(look: Dictionary, at: Vector2, face: Vector2) -> BrotherLook:
	var figure := BrotherLook.new()
	figure.configure(look)
	figure.position = at
	figure.scale = Vector2(FIGURE, FIGURE)
	figure.facing = face
	_mask.add_child(figure)
	_cast.append(figure)
	return figure


func _brother(id: String, at: Vector2, face: Vector2) -> BrotherLook:
	return _person(GameData.character(id).get("look", {}), at, face)


## The four of them: the brothers and the girls, where the evening leaves
## them -- each couple facing each other, the girls between.
func _couples(older_x := 850.0, girl_x: Array = [1020.0, 1280.0], younger_x := 1450.0) -> void:
	_older = _brother("older", Vector2(older_x, WALK), Vector2.RIGHT)
	_younger = _brother("younger", Vector2(younger_x, WALK), Vector2.LEFT)
	_girls = [_person(GIRLS[0], Vector2(float(girl_x[0]), WALK), Vector2.LEFT),
			_person(GIRLS[1], Vector2(float(girl_x[1]), WALK), Vector2.RIGHT)]


func _make_baron(at: Vector2) -> FilmBaron:
	var baron := FilmBaron.new()
	baron.setup_boss(_room, RandomNumberGenerator.new(), 2)
	baron.state = "recover"
	baron.position = at
	baron.scale = Vector2(BARON_SIZE, BARON_SIZE)
	_mask.add_child(baron)
	# After it is in: a node with _physics_process switches it on as it
	# enters the tree.
	baron.set_physics_process(false)
	_cast.append(baron)
	return baron


func _make_kitten(at: Vector2) -> FilmKitten:
	var kitten := FilmKitten.new()
	kitten.setup("kitten", _room, RandomNumberGenerator.new())
	kitten.position = at
	kitten.scale = Vector2(1.5, 1.5)
	_mask.add_child(kitten)
	kitten.set_physics_process(false)
	_cast.append(kitten)
	return kitten


func _make_cage(at: Vector2) -> void:
	_cage = Node2D.new()
	_cage.draw.connect(_draw_cage.bind(_cage))
	_mask.add_child(_cage)
	_cast.append(_cage)
	_cage_ground = at
	_cage_height = 0.0
	_cage_shadow = 1.0
	_place_cage(at, 0.0, Vector2.ONE)


## The cage standing over [param ground], [param height] off it. It is
## sorted among the cast by where it stands, not by how high it is, so it
## stays in front of the girls inside it as it hops.
func _place_cage(ground: Vector2, height: float, squeeze: Vector2) -> void:
	_cage_ground = ground
	_cage_height = height
	_cage_squeeze = squeeze
	_cage.position = ground
	_cage.queue_redraw()


## Lifts [param figure] [param pixels] off the street, in the street's
## pixels.
static func _lift(figure: BrotherLook, pixels: float) -> void:
	figure.lift = pixels / figure.scale.y


## Over the top of [param figure]'s head.
static func _over_head(figure: Node2D, above := 30.0) -> Vector2:
	var height := 175.0
	if figure is BrotherLook:
		height = 175.0 + (figure as BrotherLook).lift
	return figure.position + Vector2(0, -(height + above) * figure.scale.y)


## The nearer the front, the later drawn. By hand: a node that clips its
## children does not clip them once it sorts them by y itself.
func _sort_cast() -> void:
	var order := _mask.get_children()
	order.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y < b.position.y)
	for i in order.size():
		if order[i].get_index() != i:
			_mask.move_child(order[i], i)


func _clear_cast() -> void:
	for figure in _cast:
		figure.queue_free()
	_cast.clear()
	_girls.clear()
	_kittens.clear()
	_older = null
	_younger = null
	_baron = null
	_cage = null
	for bit in _fx.get_children():
		bit.queue_free()


func _burst(at: Vector2, kind: String, count := 8, power := 1.0) -> void:
	var bits := Fx.Bits.new()
	bits.kind = kind
	bits.count = count
	bits.power = power
	bits.position = at
	_fx.add_child(bits)


func _poof(at: Vector2, radius: float, stars := 6) -> void:
	var puff := Puff.new()
	puff.radius = radius
	puff.stars = stars
	puff.drawings = 8
	puff.position = at
	_fx.add_child(puff)


# --- staging --------------------------------------------------------------------


func _stage(scene: String) -> void:
	_cam = Vector2(960, 540)
	_zoom = 1.0
	_holes = []
	_night = 1.0
	_lights = 1.0
	_lamp = 1.0
	_world.visible = true
	_far.visible = scene in STREET
	match scene:
		"evening":
			_night = 0.0
			_older = _brother("older", Vector2(100, WALK), Vector2.RIGHT)
			_younger = _brother("younger", Vector2(2400, WALK), Vector2.LEFT)
			_girls = [_person(GIRLS[0], Vector2(1020, WALK), Vector2.RIGHT),
					_person(GIRLS[1], Vector2(1280, WALK), Vector2.LEFT)]
		"arrival":
			_holes = [[HOLE, HOLE_R, false]]
			_couples()
			_baron = _make_baron(Vector2(HOLE.x, HOLE.y + 400))
			for i in 3:
				_kittens.append(_make_kitten(HOLE + Vector2(0, 120)))
		"kidnap":
			_holes = [[HOLE, HOLE_R, false]]
			_couples(850.0, [720.0, 1330.0], 1450.0)
			_baron = _make_baron(BARON_SPOT)
			for i in 3:
				_kittens.append(_make_kitten(KITTEN_SPOTS[i]))
			_make_cage(CAGE_AT)
			_cage.visible = false
		"aftermath":
			_holes = [[HOLE, HOLE_R, false]]
			_older = _brother("older", Vector2(930, WALK), Vector2.RIGHT)
			_younger = _brother("younger", Vector2(1370, WALK), Vector2.LEFT)
		"chase":
			_holes = [[HATCH, HATCH_R, true]]
			_older = _brother("older", Vector2(1690, WALK), Vector2.RIGHT)
			_younger = _brother("younger", Vector2(1830, WALK), Vector2.LEFT)
		"reunion":
			_older = _brother("older", Vector2(160, GROUND), Vector2.RIGHT)
			_younger = _brother("younger", Vector2(320, GROUND), Vector2.RIGHT)
			_girls = [_person(GIRLS[0], Vector2(CAGE_END.x - 70, GROUND), Vector2.LEFT),
					_person(GIRLS[1], Vector2(CAGE_END.x + 70, GROUND), Vector2.LEFT)]
			_make_cage(CAGE_END)


func _act() -> void:
	match _scene():
		"evening":
			_act_evening()
		"arrival":
			_act_arrival()
		"kidnap":
			_act_kidnap()
		"aftermath":
			_act_aftermath()
		"note":
			_act_note()
		"chase":
			_act_chase()
		"reunion":
			_act_reunion()
	var key := "%s %.3f %.2f" % [_scene(), _lights, _lamp]
	if key != _set_drawn:
		_set_drawn = key
		_lit.queue_redraw()
	if _scene() == "reunion":
		_set.queue_redraw()


func _camera() -> void:
	var jolt := Vector2.ZERO
	if _shake > 0.0:
		jolt = Vector2(Toon.hash01(_drawing, 1) - 0.5, Toon.hash01(_drawing, 2) - 0.5) * 40.0 * minf(_shake / 0.3, 1.0)
	_world.transform = Transform2D(0.0, Vector2(_zoom, _zoom), 0.0, Vector2(960, 540) - _cam * _zoom + jolt)
	# The sky is further off: it moves a third as much.
	var p := 0.35
	var far_zoom := 1.0 + (_zoom - 1.0) * p
	var far_cam := _cam * p + Vector2(960, 540) * (1.0 - p)
	_far.transform = Transform2D(0.0, Vector2(far_zoom, far_zoom), 0.0, Vector2(960, 540) - far_cam * far_zoom + jolt * 0.4)


# --- the opening, scene by scene ------------------------------------------------


## Dusk. The camera comes down the street with the older brother; the
## younger comes the other way; the girls chatting under the lamp turn,
## hearts pop out of the boys, and the two couples dance on the pavement.
## In the alley, two eyes open.
func _act_evening() -> void:
	_cam = Vector2(lerpf(620.0, 1150.0, _ease(0.0, 3.8)), 540.0).lerp(Vector2(1250, 590), _ease(4.6, 9.0))
	_zoom = lerpf(1.0, 1.12, _ease(4.6, 9.0))
	var walk := _lin(0.0, 3.6)
	_older.position.x = lerpf(100.0, 850.0, walk)
	_younger.position.x = lerpf(2400.0, 1450.0, walk)
	for him: BrotherLook in [_older, _younger]:
		him.moving = walk < 1.0
		him.walk_rate = 1.3
		# Smitten: eyes out on stalks, then a hop for joy.
		him.pose_shocked = _t >= 3.6 and _t < 4.05
	_girls[0].facing = Vector2.RIGHT if _t < 3.3 else Vector2.LEFT
	_girls[1].facing = Vector2.LEFT if _t < 3.3 else Vector2.RIGHT
	var four: Array[BrotherLook] = [_older, _girls[0], _girls[1], _younger]
	for i in four.size():
		var up := 0.0
		if _t < 3.3 and i in [1, 2]:
			# Chattering away.
			up = absf(sin(_t * 7.0 + i * 1.7)) * 7.0
		elif _t >= 4.6:
			up = absf(sin((_t - 4.6) * PI * 2.2 + (0.5 if i in [1, 2] else 0.0))) * 26.0
		if i in [0, 3]:
			up += _hop(4.05, 4.5, 90.0)
		_lift(four[i], up)
	if _on(3.3):
		Sfx.play("select", -8.0)
	if _on(3.6):
		Sfx.play("heart", 0.0, 0.0)
	if _on(4.05):
		Sfx.play("whistle_up", -10.0)


## Night. The couples dance on, the lights go out window by window, the
## lamp dies. The manhole cover rattles and flies off, three kittens leap
## out, and up comes the Baron -- hat raised to the audience.
func _act_arrival() -> void:
	_cam = Vector2(1340, 560).lerp(Vector2(1480, 600), _ease(3.0, 6.0))
	_zoom = lerpf(1.0, 1.08, _ease(3.0, 6.0))
	# The lights go out as he comes -- and back on, the street woken by the
	# racket, to show him standing there.
	_lights = 1.0 - _lin(0.5, 2.0) + _lin(5.8, 6.6)
	if _t < 1.3:
		_lamp = 1.0
	elif _t < 2.0:
		_lamp = 1.0 if Toon.hash01(_drawing, 9) < 0.45 else 0.2
	elif _t < 5.7:
		_lamp = 0.0
	elif _t < 6.1:
		_lamp = 1.0 if Toon.hash01(_drawing, 10) < 0.5 else 0.1
	else:
		_lamp = 1.0
	if _on(2.0):
		Sfx.play("poof", -12.0)
	if _on(6.1):
		Sfx.play("select", -6.0)
	var four: Array[BrotherLook] = [_older, _girls[0], _girls[1], _younger]
	for i in four.size():
		var figure := four[i]
		var up := 0.0
		if _t < 0.9:
			up = absf(sin((_t + 4.4) * PI * 2.2 + (0.5 if i in [1, 2] else 0.0))) * 26.0 * (1.0 - _lin(0.6, 0.9))
		up += _hop(3.0, 3.3, 50.0)
		_lift(figure, up)
		figure.pose_shocked = _t >= 3.0 and (i in [1, 2] or _t < 7.0)
		if _t < 1.0:
			continue
		elif _t < 2.6:
			# Looking about in the dark.
			var glance := int((_t - 1.0) / 0.4 + i) % 3
			figure.facing = [Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT][glance]
		else:
			figure.facing = Vector2.DOWN
	# The girls run behind their boys.
	var dash := _ease(4.4, 4.9)
	_girls[0].position.x = lerpf(1020.0, 720.0, dash)
	_girls[1].position.x = lerpf(1280.0, 1330.0, dash)
	for girl: BrotherLook in _girls:
		girl.moving = _t > 4.4 and _t < 4.9
	if _t > 4.4 and _t < 4.9:
		_girls[0].facing = Vector2.LEFT
		_girls[1].facing = Vector2.RIGHT
	elif _t >= 4.9:
		_girls[0].facing = Vector2.RIGHT
		_girls[1].facing = Vector2.RIGHT
	if _t >= 6.4:
		_older.facing = Vector2.RIGHT
		_younger.facing = Vector2.RIGHT
	# And the brothers point him out: "you!"
	_older.aim = Vector2.RIGHT if _t > 7.1 else Vector2.ZERO
	_younger.aim = Vector2.RIGHT if _t > 7.4 else Vector2.ZERO
	for moment: float in [2.3, 2.55, 2.8]:
		if _on(moment):
			Sfx.play("hit", -9.0)
	if _on(3.0):
		Sfx.play("whistle_up", 0.0)
		_shake = 0.15
	if _on(3.9):
		Sfx.play("stomp", -2.0)
		_burst(LID_REST, "dust", 10, 1.2)
		_shake = 0.25
	for i in 3:
		var start := 3.2 + i * 0.22
		var end := start + KITTEN_LEAPS[i]
		var kitten := _kittens[i]
		kitten.position = (HOLE + Vector2(0, 90)).lerp(KITTEN_SPOTS[i], _lin(start, end))
		kitten.leap(_hop(start, end, 300.0 if i == 0 else 240.0))
		kitten.state = "crouch" if _t > end and _t < end + 0.4 else "creep"
		kitten.look = (Vector2(1150, WALK - 200) - kitten.position).normalized()
		if _on(start):
			Sfx.play("whistle_up", -12.0, 0.2)
		if _on(end):
			_burst(KITTEN_SPOTS[i], "dust", 4, 0.6)
			Sfx.play("hit", -14.0)
	# The Baron: up out of the sewer, then a hop onto the street.
	var rise := _lin(4.2, 5.6)
	var at := Vector2(HOLE.x, lerpf(HOLE.y + 400.0, HOLE.y, 1.0 - pow(1.0 - rise, 2.5)))
	var out := _lin(5.7, 6.3)
	if out > 0.0:
		at = HOLE.lerp(BARON_SPOT, out) - Vector2(0, sin(out * PI) * 130.0)
	_baron.position = at
	_baron.state = "wait" if _t > 6.4 and _t < 8.2 else "recover"
	_baron.look = Vector2(-0.8, -0.2) if _t < 6.4 else Vector2(0, 0.3)
	if _on(4.2):
		Sfx.play("whistle_up", -6.0, 0.0)
		_burst(HOLE, "steam", 12, 1.2)
	if _on(5.7):
		Sfx.play("whistle_up", -10.0)
	if _on(6.3):
		Sfx.play("stomp", -10.0)
		_burst(BARON_SPOT, "dust", 6, 0.8)


## Out of his hat the Baron pulls a cage, up and away; the kittens send
## the girls running into each other, and the cage comes down on them.
## The brothers charge and are knocked flat. The cage hops off to the
## manhole, squeezes in and is gone; the kittens dive after it, the Baron
## tips his hat and jumps, and the cover flies back on.
func _act_kidnap() -> void:
	_cam = Vector2(1400, 580)
	_zoom = 1.04
	_baron.look = Vector2(-0.8, -0.1)
	if _t < 0.5:
		_baron.state = "recover"
	elif _t < 1.5:
		_baron.state = "hat_windup"
	elif _t < 4.0:
		_baron.state = "recover"
		_baron.look = Vector2(-0.5, -0.8) if _t < 2.4 else Vector2(-0.9, 0.0)
	elif _t < 5.0:
		_baron.state = "roar"
	elif _t < 7.0:
		_baron.state = "ring_windup"
	elif _t < 8.4:
		_baron.state = "wait"
	else:
		_baron.state = "recover"
	var hat := BARON_SPOT + Vector2(-26, -360)
	if _on(0.6):
		Sfx.play("item", -4.0)
		_burst(hat, "stars", 6, 0.8)
	if _on(4.0):
		Sfx.play("roar", -6.0)
	# The cage: out of the hat and up, then down on the girls, then off to
	# the manhole in hops, squeezed thin, and down it.
	_cage.visible = _t >= 1.0
	if _t < 1.45:
		# Stood just in front of the Baron, so it comes out over his hat.
		var k := _lin(1.0, 1.45)
		var ground := Vector2(hat.x, BARON_SPOT.y + 1.0)
		_place_cage(ground, ground.y - hat.y - 40.0 + 1000.0 * k * k, Vector2.ONE * lerpf(0.12, 1.0, k))
		_cage_shadow = 0.0
	elif _t < 2.85:
		var k := _lin(2.35, 2.85)
		_place_cage(CAGE_AT, lerpf(1400.0, 0.0, k * k), Vector2.ONE)
		_cage_shadow = k
	elif _t < 5.1:
		var squash := sin(_lin(2.85, 3.1) * PI) * 0.16
		_place_cage(CAGE_AT, 0.0, Vector2(1.0 + squash * 0.6, 1.0 - squash))
		_cage_shadow = 1.0
	elif _t < 6.3:
		var hops := (_t - 5.1) / 0.4
		var n := mini(int(hops), 2)
		var from := CAGE_AT.lerp(HOLE, n / 3.0)
		var to := CAGE_AT.lerp(HOLE, (n + 1) / 3.0)
		var k := clampf(hops - n, 0.0, 1.0)
		var squeeze := lerpf(1.0, 0.56, _ease(5.5, 6.3))
		_place_cage(from.lerp(to, k), sin(k * PI) * 90.0, Vector2(squeeze, 1.0 + (1.0 - squeeze) * 0.3))
	else:
		var k := _lin(6.3, 7.0)
		_place_cage(Vector2(HOLE.x, HOLE.y + k * k * 560.0), 0.0, Vector2(0.56, 1.13))
	for moment: float in [5.5, 5.9, 6.3]:
		if _on(moment):
			Sfx.play("stomp", -14.0)
			_burst(_cage_ground, "dust", 4, 0.5)
	if _on(1.0):
		Sfx.play("whistle_up")
	if _on(2.35):
		Sfx.play("whistle_down")
	if _on(2.85):
		Sfx.play("stomp", 0.0, 0.0)
		_shake = 0.35
		for side: float in [-1.0, 1.0]:
			_burst(CAGE_AT + Vector2(side * 170.0, 0), "dust", 8, 1.2)
	if _on(6.3):
		Sfx.play("whistle_down", 0.0, 0.0)
	# The girls: a fright, a run, a bump, caught, carried off.
	var girl_to: Array[float] = [1080.0, 1220.0]
	var girl_from: Array[float] = [720.0, 1330.0]
	for i in 2:
		var girl := _girls[i]
		girl.pose_shocked = true
		if _t < 2.85:
			var run := _ease(2.15, 2.7)
			girl.position = Vector2(lerpf(girl_from[i], girl_to[i], run), WALK)
			girl.moving = _t > 2.15 and _t < 2.7
			girl.facing = (Vector2.RIGHT if i == 0 else Vector2.LEFT) if _t > 1.8 and _t < 2.7 else (
					Vector2.RIGHT if i == 0 else Vector2.DOWN)
			if _t >= 2.7:
				girl.facing = Vector2.DOWN
			_lift(girl, _hop(1.8, 2.15, 130.0) + _hop(2.7, 2.85, 20.0))
			girl.scale = Vector2(FIGURE, FIGURE)
		else:
			# In the cage: where it goes, they go, squeezed with it.
			var offset := girl_to[i] - CAGE_AT.x
			girl.position = Vector2(_cage_ground.x + offset * _cage_squeeze.x, _cage_ground.y - 45.0)
			girl.scale = FIGURE * _cage_squeeze
			girl.moving = false
			girl.facing = Vector2.DOWN
			var rattle := absf(sin(_t * 11.0 + i)) * 10.0 if _t > 3.3 and _t < 5.0 else 0.0
			girl.lift = (_cage_height + rattle) / girl.scale.y
	if _on(2.7):
		Sfx.play("hit", -8.0)
	# The brothers point, charge, and are knocked flat.
	var heads: Array[BrotherLook] = [_older, _younger]
	var charge_to: Array[float] = [930.0, 1370.0]
	var charge_from: Array[float] = [850.0, 1450.0]
	var bonk: Array[float] = [3.5, 3.62]
	for i in 2:
		var him := heads[i]
		him.aim = Vector2.RIGHT if _t < 3.0 else Vector2.ZERO
		him.facing = Vector2.RIGHT if (i == 0 or _t < 3.0) else Vector2.LEFT
		var run := _lin(3.05, bonk[i])
		him.position.x = lerpf(charge_from[i], charge_to[i], run)
		him.moving = _t > 3.05 and _t < bonk[i]
		him.walk_rate = 2.8
		him.knocked = _t >= bonk[i]
		if _on(bonk[i]):
			Sfx.play("hit", 0.0)
			Sfx.play("stars", -6.0)
			_burst(him.position + Vector2(0, -60), "stars", 5, 0.8)
	# The kittens: pounce at the girls, then onto the brothers' heads, then
	# off down the manhole.
	var pounce_to: Array[Vector2] = [Vector2(700, 860), Vector2(1360, 880), KITTEN_SPOTS[2]]
	var bounce_to: Array[Vector2] = [Vector2(780, 950), Vector2(1330, 1060), KITTEN_SPOTS[2]]
	var dive: Array[float] = [7.0, 7.25, 7.5]
	for i in 3:
		var kitten := _kittens[i]
		var at := KITTEN_SPOTS[i]
		var height := 0.0
		kitten.state = "creep"
		kitten.look = (Vector2(1150, WALK - 150) - kitten.position).normalized()
		if i < 2:
			var head := heads[i]
			if _t >= 1.6:
				at = KITTEN_SPOTS[i].lerp(pounce_to[i], _lin(1.6, 1.95))
				height = _hop(1.6, 1.95, 140.0)
			kitten.state = "crouch" if _t > 1.3 and _t < 1.6 else kitten.state
			var leap := bonk[i] - 0.3
			if _t >= leap:
				var k := _lin(leap, bonk[i])
				at = pounce_to[i].lerp(Vector2(charge_to[i] + 10.0, WALK + 6.0), k)
				height = lerpf(0.0, 300.0, k) + sin(k * PI) * 150.0
			if _t >= bonk[i]:
				var k := _lin(bonk[i], bonk[i] + 0.4)
				at = Vector2(charge_to[i] + 10.0, WALK + 6.0).lerp(bounce_to[i], k)
				height = lerpf(300.0, 0.0, k) + sin(k * PI) * 120.0
			kitten.look = (head.position - kitten.position).normalized()
		if _t >= dive[i]:
			var k := _lin(dive[i], dive[i] + 0.5)
			at = bounce_to[i].lerp(HOLE + Vector2(0, 170), k)
			height = sin(k * PI) * 200.0
		kitten.position = at
		kitten.leap(height)
		if _on(dive[i]):
			Sfx.play("whistle_down", -10.0, 0.2)
	if _on(1.6):
		Sfx.play("spit", -2.0)
	# The Baron's exit, and the lid back on.
	var jump := _lin(8.4, 9.0)
	if jump > 0.0:
		_baron.position = BARON_SPOT.lerp(HOLE + Vector2(0, 460), jump * jump) - Vector2(0, sin(jump * PI) * 220.0)
		_baron.state = "recover"
	if _on(8.4):
		Sfx.play("whistle_down", 0.0, 0.0)
	if _on(9.1):
		Sfx.play("whistle_up", -6.0)
	if _on(9.6):
		Sfx.play("stomp", 0.0, 0.0)
		_burst(HOLE, "dust", 10, 1.2)
		_shake = 0.3


## The brothers come to, run to the manhole -- shut fast -- and hear the
## girls cry out under it. A card flutters down; the older brother picks
## it up.
func _act_aftermath() -> void:
	_cam = Vector2(1560, 700)
	_zoom = 1.3
	var ups: Array[float] = [1.3, 1.6]
	var heads: Array[BrotherLook] = [_older, _younger]
	var from: Array[float] = [930.0, 1370.0]
	var to: Array[float] = [1690.0, 1870.0]
	for i in 2:
		var him := heads[i]
		him.knocked = _t < ups[i]
		him.pose_shocked = (_t >= ups[i] and _t < ups[i] + 0.6) or (_t >= 3.9 and _t < 4.6)
		if _t >= ups[i] and _t < ups[i] + 0.6:
			# Shaking his head clear.
			him.facing = Vector2.LEFT if int(_t / 0.09) % 2 == 0 else Vector2.RIGHT
		elif _t < 3.4:
			him.facing = Vector2.RIGHT
		else:
			him.facing = Vector2.DOWN
		var run := _ease(2.2, 3.4)
		him.position.x = lerpf(from[i], to[i], run)
		him.moving = _t > 2.25 and _t < 3.35
		him.walk_rate = 3.0
		var tug := absf(sin(_t * 30.0)) * 6.0 if _t > 3.4 and _t < 3.9 else 0.0
		_lift(him, tug)
		if _on(ups[i]):
			Sfx.play("stars", -10.0)
	_younger.aim = Vector2.UP if _t > 4.8 and _t < 6.0 else Vector2.ZERO
	if _t > 6.6:
		_younger.position.x = lerpf(1870.0, 1810.0, _ease(6.6, 7.0))
		_younger.facing = Vector2.LEFT
	for moment: float in [3.5, 3.72]:
		if _on(moment):
			Sfx.play("hit", -14.0)
	if _on(6.1):
		Sfx.play("pickup", -6.0)
	if _on(6.4):
		Sfx.play("pickup")


## The card, close up, its note writing itself out.
func _act_note() -> void:
	_cam = Vector2(960, 540)
	_zoom = lerpf(1.0, 1.06, _ease(0.0, 5.2))


## "After them!" -- and off they run down the street to the cellar hatch,
## and in, one after the other.
func _act_chase() -> void:
	_cam = Vector2(lerpf(1700.0, 2560.0, _ease(0.8, 3.8)), 560.0)
	var jumps: Array[float] = [3.6, 3.15]
	var starts: Array[float] = [1.0, 0.9]
	var from: Array[float] = [1690.0, 1830.0]
	var heads: Array[BrotherLook] = [_older, _younger]
	for i in 2:
		var him := heads[i]
		var nod := _hop(0.3, 0.5, 30.0) + _hop(0.6, 0.8, 30.0)
		var run := _lin(starts[i], jumps[i])
		var at := Vector2(lerpf(from[i], 2560.0, run), WALK)
		var height := nod
		him.moving = _t > starts[i] and _t < jumps[i]
		him.walk_rate = 2.6
		if _t < starts[i]:
			him.facing = Vector2.RIGHT if i == 0 else Vector2.LEFT
		else:
			him.facing = Vector2.RIGHT
		if _t >= jumps[i]:
			var k := _lin(jumps[i], jumps[i] + 0.5)
			# Across at a run, down faster and faster.
			at = Vector2(lerpf(2560.0, HATCH.x, k), lerpf(WALK, HATCH.y + 330.0, k * k))
			height = sin(k * PI) * 150.0
			him.moving = false
			him.pose_shocked = k > 0.3
		him.position = at
		_lift(him, height)
		# A puff of dust off his heels every few steps.
		if him.moving and floorf((_t - starts[i]) / 0.22) != floorf((_was - starts[i]) / 0.22):
			_burst(at + Vector2(-30, 0), "dust", 2, 0.4)
		if _on(jumps[i]):
			Sfx.play("whistle_down", -4.0)
		if _on(jumps[i] + 0.5):
			Sfx.play("stomp", -10.0)
			_burst(HATCH, "dust", 8, 0.9)
	_younger.aim = Vector2.RIGHT if _t > 0.5 and _t < 0.9 else Vector2.ZERO


# --- the ending -----------------------------------------------------------------


## The brothers run in, the younger one shoots the cage, it bursts in a
## puff and the girls run to them; two couples, hearts and confetti.
func _act_reunion() -> void:
	_cam = Vector2(960, 540).lerp(Vector2(900, 580), _ease(3.0, 8.5))
	_zoom = lerpf(1.0, 1.08, _ease(3.0, 8.5))
	var run := _ease(0.0, 1.0)
	_older.position.x = lerpf(160.0, 620.0, run)
	_younger.position.x = lerpf(320.0, 1000.0, run)
	for him: BrotherLook in [_older, _younger]:
		him.moving = _t < 1.0
		him.walk_rate = 2.4
		him.facing = Vector2.RIGHT
	_younger.aim = Vector2.RIGHT if _t > 1.0 and _t < 1.4 else Vector2.ZERO
	if _on(1.05):
		Sfx.play("shot")
	_cage.visible = _t < 1.2
	if _on(1.2):
		Sfx.play("poof", 0.0, 0.0)
		Sfx.play("clear", -4.0)
		_poof(CAGE_END + Vector2(0, -170), 170.0, 8)
		_burst(CAGE_END + Vector2(0, -170), "confetti", 30, 1.4)
	var girl_from: Array[float] = [CAGE_END.x - 70.0, CAGE_END.x + 70.0]
	var girl_to: Array[float] = [790.0, 1170.0]
	for i in 2:
		var girl := _girls[i]
		girl.pose_shocked = _t < 1.3
		girl.facing = Vector2.DOWN if _t < 1.3 else Vector2.LEFT
		var dash := _ease(1.7, 2.5)
		girl.position.x = lerpf(girl_from[i], girl_to[i], dash)
		girl.moving = _t > 1.7 and _t < 2.5
		girl.walk_rate = 2.2
	var four: Array[BrotherLook] = [_older, _girls[0], _younger, _girls[1]]
	for i in four.size():
		var up := 0.0
		if i in [1, 3]:
			up += _hop(1.3, 1.7, 120.0)
		else:
			up += _hop(2.5, 2.9, 80.0)
		if _t >= 3.0:
			up += absf(sin((_t - 3.0) * PI * 2.2 + (0.5 if i in [1, 3] else 0.0))) * 26.0
		_lift(four[i], up)
	if _on(1.3):
		Sfx.play("whistle_up", -8.0)
	if _on(2.5):
		Sfx.play("heart", 0.0, 0.0)


# --- drawing ---------------------------------------------------------------------


func _draw() -> void:
	if _kind() in ["card", "end"]:
		_draw_card()


func _draw_far() -> void:
	if _scene() in STREET:
		StorySet.sky(_far, _night, _drawing)


func _draw_set() -> void:
	match _scene():
		"note":
			_set.draw_rect(Rect2(-400, -400, 2720, 1880), Color("17110e"))
			for k in 40:
				var at := Vector2(Toon.hash01(k, 1) * 1920.0, Toon.hash01(k, 2) * 1080.0)
				Toon.spot(_set, at, Vector2(80, 24), Color(1, 1, 1, 0.025), 0, k)
			Toon.glow(_set, Vector2(960, 540), Vector2(900, 620), Color(1, 0.85, 0.6, 0.12), 3)
		"reunion":
			StorySet.sunburst(_set, Vector2(960, 330), Color("f0dcae"), Color("c79a5c"), _clock * 0.03)
			StorySet.ground(_set, GROUND, Color("8a5a36"))
			StorySet.hat(_set, Vector2(300, 960), _drawing)
		"":
			pass
		_:
			StorySet.street(_set, _night, HATCH, HATCH_R)
			# The lights go where the street has just put its windows.
			_lit.queue_redraw()


func _draw_lights() -> void:
	if _scene() in STREET:
		StorySet.lights(_lit, _night, _lights, _lamp)


func _draw_road() -> void:
	if _scene() in STREET:
		StorySet.road(_road, _night, HOLE, HOLE_R)


## Where the cast may be seen: everywhere but below the near edge of an
## opening they go down -- so a figure in a hole is cut off at its rim.
func _draw_mask() -> void:
	var big := 8000.0
	var points := PackedVector2Array([Vector2(-big, -big), Vector2(big, -big), Vector2(big, big)])
	var holes := _holes.duplicate()
	holes.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).x > (b[0] as Vector2).x)
	for hole: Array in holes:
		var c: Vector2 = hole[0]
		var r: Vector2 = hole[1]
		points.append(Vector2(c.x + r.x, big))
		if hole[2]:
			points.append(Vector2(c.x + r.x, c.y + r.y))
			points.append(Vector2(c.x - r.x, c.y + r.y))
		else:
			for k in 17:
				var a := PI * k / 16.0
				points.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		points.append(Vector2(c.x - r.x, big))
	points.append(Vector2(-big, big))
	_mask.draw_colored_polygon(points, Color.WHITE)


func _draw_cage(cage: Node2D) -> void:
	if _cage_shadow > 0.0:
		var grow := lerpf(0.3, 1.0, _cage_shadow) * _cage_squeeze.x
		Toon.spot(cage, Vector2(0, 4), Vector2(200, 30) * grow, Color(Toon.INK, 0.3 * _cage_shadow))
	cage.draw_set_transform(Vector2(0, -_cage_height), 0.0, _cage_squeeze)
	StorySet.cage(cage, _drawing)
	cage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## What goes over the figures: hearts, the manhole cover, speech, the
## card, the eyes in the alley.
func _draw_props() -> void:
	match _scene():
		"evening":
			for him: BrotherLook in [_older, _younger]:
				_pop_heart(_over_head(him, 40.0), _t - 3.6)
			if _t > 4.6:
				_hearts(Vector2(935, WALK - 340), 0)
				_hearts(Vector2(1365, WALK - 330), 1)
			var open := _lin(6.6, 6.75) * (1.0 - _lin(7.55, 7.62) + _lin(7.7, 7.77))
			_watching_eyes(Vector2(2020, 540), open, _t > 7.9)
			StorySet.lid(_props, HOLE, HOLE_R, 0.0, 0.0, _night)
		"arrival":
			_draw_lid_arrival()
			if _t > 6.5 and _t < 8.4:
				_bubble(Vector2(2060, 450), _baron.position + Vector2(10, -200), "Добрый вечер, голубки!", 40)
		"kidnap":
			if _t < 9.1:
				StorySet.lid(_props, LID_REST, HOLE_R, 0.0, 0.0, _night)
			else:
				_draw_lid_flight(LID_REST, HOLE, 9.1, 9.6, 300.0)
			if _t > 4.0 and _t < 5.0:
				_bubble(BARON_SPOT + Vector2(-260, -420), BARON_SPOT + Vector2(-30, -250), "Ха-ха-ха!", 48, true)
			if _t > 3.3 and _t < 5.0:
				_cry(CAGE_AT + Vector2(0, -400), "Ой-ой-ой!", 36, 1.0)
		"aftermath":
			var rattle := Vector2(0, -absf(sin(_t * 30.0)) * 4.0) if _t > 3.4 and _t < 3.9 else Vector2.ZERO
			StorySet.lid(_props, HOLE + rattle, HOLE_R, 0.0, 0.0, _night)
			if _t > 3.9 and _t < 5.2:
				var k := _lin(3.9, 5.2)
				_cry(HOLE + Vector2(sin(_t * 9.0) * 8.0, -50.0 - k * 220.0), "Спаси-и-ите!", int(30 + k * 10),
						sin(k * PI))
			_draw_falling_card()
		"note":
			var turn := sin(_t * 1.3) * 0.025
			StorySet.calling_card(_props, Vector2(980, 540), turn, (_t - 0.4) / 0.5)
			# The older brother's glove holds it by the corner, his arm coming
			# up from below.
			var thumb := Vector2(980, 540) + Vector2(-292, 330).rotated(turn)
			Toon.hose(_props, Vector2(380, 1260), thumb + Vector2(-70, 70), -40.0, 70.0)
			Toon.hose(_props, Vector2(380, 1260), thumb + Vector2(-70, 70), -40.0, 58.0, Color("2a2420"))
			Toon.ball(_props, thumb + Vector2(-56, 56), Vector2(50, 32), BrotherLook.WHITE, _drawing, 5, 6.0, -0.75)
			Toon.blob(_props, thumb + Vector2(-6, 6), Vector2(58, 44), BrotherLook.WHITE, _drawing, 6, 6.0, -0.5)
			Toon.blob(_props, thumb + Vector2(36, -30), Vector2(20, 32), BrotherLook.WHITE, _drawing, 7, 5.5, 0.6)
			for k in 3:
				var at := thumb + Vector2(-26 + k * 16, -10 + k * 7)
				Toon.stroke(_props, PackedVector2Array([at, at + Vector2(-12, 18)]), 3.5)
		"chase":
			if _t > 0.2 and _t < 1.2:
				_bubble(_older.position + Vector2(-160, -560), _over_head(_older, 0.0), "За ними!", 48)
			for him: BrotherLook in [_older, _younger]:
				if him.moving:
					_speed_lines(him)
			if _t > 4.7 and _t < 6.4:
				_cry(HATCH + Vector2(0, -140 - _lin(4.7, 6.4) * 80.0), "Мы идём, девчонки!", 34,
						sin(_lin(4.7, 6.4) * PI))
		"reunion":
			if _t > 2.5:
				_pop_heart(Vector2(705, WALK - 300), _t - 2.5)
				_pop_heart(Vector2(1085, WALK - 290), _t - 2.6)
			if _t > 3.0:
				_hearts(Vector2(705, GROUND - 330), 0)
				_hearts(Vector2(1085, GROUND - 320), 1)
			if _t > 1.2:
				_confetti()
			for i in 3:
				var a := _clock * 3.0 + TAU * i / 3.0
				Toon.star(_props, Vector2(300, 960) + Vector2(cos(a) * 110.0, -150.0 + sin(a) * 24.0), 13.0, a,
						Color("f2c14e"))


## The cover: on the manhole, rattling, flying off and landing.
func _draw_lid_arrival() -> void:
	if _t < 3.0:
		var jitter := Vector2.ZERO
		if _t > 2.3:
			jitter = Vector2(Toon.hash01(_drawing, 4) - 0.5, -Toon.hash01(_drawing, 5)) * 10.0
		StorySet.lid(_props, HOLE + jitter, HOLE_R, 0.0, (Toon.hash01(_drawing, 6) - 0.5) * 0.1 if _t > 2.3 else 0.0,
				_night)
	else:
		_draw_lid_flight(HOLE, LID_REST, 3.0, 3.9, 420.0)


## The cover through the air from [param from] to [param to], tumbling,
## then settling like a coin.
func _draw_lid_flight(from: Vector2, to: Vector2, start: float, end: float, height: float) -> void:
	var k := _lin(start, end)
	if k < 1.0:
		var at := from.lerp(to, k) - Vector2(0, sin(k * PI) * height)
		StorySet.lid(_props, at, HOLE_R, k * TAU * 2.25, sin(k * 7.0) * 0.4, _night)
		return
	var settle := _lin(end, end + 0.7)
	var wobble := sin(settle * 26.0) * 0.35 * (1.0 - settle)
	StorySet.lid(_props, to, HOLE_R, wobble, 0.0, _night)


## The Baron's card: down out of the night sky, rocking like a leaf, onto
## the cover; then up into the older brother's hand.
func _draw_falling_card() -> void:
	if _t < 4.9:
		return
	var at := Vector2.ZERO
	var turn := 0.0
	var fall := _lin(4.9, 6.1)
	if _t < 6.1:
		var sway := sin(fall * TAU * 1.5)
		at = Vector2(lerpf(1960.0, 1780.0, fall) + sway * 90.0 * (1.0 - fall), lerpf(330.0, HOLE.y - 8.0, fall))
		turn = sway * 0.6 * (1.0 - fall) + 1.2 * fall
	elif _t < 6.4:
		at = Vector2(1780, HOLE.y - 8.0)
		turn = 1.2
	else:
		var k := _ease(6.4, 6.65)
		at = Vector2(1780, HOLE.y - 8.0).lerp(_older.position + Vector2(56, -130), k)
		turn = lerpf(1.2, 0.0, k)
	var flat := 0.45 if _t >= 6.1 and _t < 6.4 else 1.0
	_props.draw_set_transform(at, turn, Vector2(1.4, 1.4 * flat))
	Toon.box(_props, Vector2.ZERO, Vector2(22, 31), Color("f4ead2"), _drawing, 4, 3.0)
	_props.draw_rect(Rect2(-14, -22, 28, 44), Color("a83a2b"), false, 2.0)
	_props.draw_string(Ui.font(), Vector2(-12, -4), "К", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Toon.INK)
	_props.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Two eyes opening in the dark of the alley, yellow, half-lidded, one
## behind a monocle that catches the light; they blink, and narrow.
func _watching_eyes(at: Vector2, open: float, narrow: bool) -> void:
	open = clampf(open, 0.0, 1.0)
	if open <= 0.02:
		return
	var tall := 15.0 * open * (0.55 if narrow else 1.0)
	for sx: float in [-1.0, 1.0]:
		var e := at + Vector2(sx * 32.0, 0)
		var points := PackedVector2Array()
		for k in 20:
			var a := TAU * k / 20.0
			points.append(e + Vector2(cos(a) * 21.0, sin(a) * tall))
		Toon.glow(_props, e, Vector2(60, 44), Color(1, 0.85, 0.3, 0.2 * open), 2)
		_props.draw_colored_polygon(points, Color("e8d24a"))
		_props.draw_line(e + Vector2(0, -tall * 0.85), e + Vector2(0, tall * 0.85), Toon.INK, 5.0)
		# The lid comes down from above: a smug, sleepy look.
		_props.draw_line(e + Vector2(-23, -tall * 0.35 - 2.0), e + Vector2(23, -tall * 0.35 - 2.0), Color("0c090c"), 6.0)
	_props.draw_arc(at + Vector2(32, 0), 28.0, 0.0, TAU, 28, Color(GOLD, 0.85 * open), 4.0, true)
	if narrow:
		Toon.star(_props, at + Vector2(52, -20), 12.0, _clock * 4.0, Color("fff1a8"))


## A speech bubble at [param at], its tail pointing to [param mouth].
func _bubble(at: Vector2, mouth: Vector2, words: String, size := 44, shaky := false) -> void:
	var font := Ui.font()
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 80.0
	var center := at
	if shaky:
		center += Vector2(Toon.hash01(_drawing, 1) - 0.5, Toon.hash01(_drawing, 2) - 0.5) * 8.0
	var toward := mouth - center
	var across := toward.orthogonal().normalized() * 24.0
	var root := center + toward.normalized() * minf(size * 0.9, toward.length() * 0.5)
	Toon.shape(_props, PackedVector2Array([root + across, center + toward * 0.82, root - across]), CREAM, 5.0)
	Toon.blob(_props, center, Vector2(width * 0.5, size * 1.25), CREAM, _drawing, 9, 5.0)
	_props.draw_string(font, center + Vector2(-width * 0.5, size * 0.34), words, HORIZONTAL_ALIGNMENT_CENTER, width,
			size, Toon.INK)


## Words with no bubble: a cry from somewhere out of sight, fading in and
## out by [param alpha].
func _cry(at: Vector2, words: String, size: int, alpha: float) -> void:
	if alpha <= 0.02:
		return
	var font := Ui.font()
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var shake := Vector2(Toon.hash01(_drawing, 7) - 0.5, Toon.hash01(_drawing, 8) - 0.5) * 5.0
	var p := at + shake - Vector2(width * 0.5, 0)
	_props.draw_string_outline(font, p, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(Toon.INK, alpha))
	_props.draw_string(font, p, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(CREAM, alpha))


## Three dashes of ink trailing a runner.
func _speed_lines(him: BrotherLook) -> void:
	var back := -signf(him.facing.x) if him.facing.x != 0.0 else -1.0
	for k in 3:
		var y := him.position.y - (60.0 + k * 70.0) * him.scale.y * 0.55
		var x := him.position.x + back * (70.0 + Toon.hash01(_drawing, k) * 30.0)
		var length := 60.0 + Toon.hash01(k, _drawing) * 50.0
		Toon.stroke(_props, PackedVector2Array([Vector2(x, y), Vector2(x + back * length, y)]), 5.0, Color(Toon.INK, 0.7))


## A heart popping out over a smitten head: in with a boing, beating, then
## floating off.
func _pop_heart(at: Vector2, age: float) -> void:
	if age < 0.0 or age > 1.6:
		return
	var grow := minf(age / 0.16, 1.0)
	var boing := 0.35 * sin(minf(age / 0.4, 1.0) * PI)
	var size := 44.0 * (grow + boing) * (1.0 + 0.12 * sin(age * 20.0))
	var rise := maxf(age - 1.0, 0.0) / 0.6
	var p := at + Vector2(sin(age * 5.0) * 6.0, -rise * 140.0)
	var alpha := 1.0 - rise
	if size < 4.0 or alpha <= 0.02:
		return
	_props.draw_colored_polygon(Toon.heart_points(p, size + 10.0), Color(Toon.INK, alpha))
	_props.draw_colored_polygon(Toon.heart_points(p, size), Color(RED, alpha))
	Toon.spot(_props, p + Vector2(-size * 0.22, -size * 0.14), Vector2(size * 0.1, size * 0.07), Color(1, 1, 1, 0.75 * alpha),
			0, 0, -0.6)


## Hearts rising and swaying from between two heads, fading as they go.
func _hearts(at: Vector2, pair: int) -> void:
	for k in 3:
		var rise := fmod(_t * 0.45 + k / 3.0 + pair * 0.17, 1.0)
		var p := at + Vector2(sin(_t * 2.5 + k * 2.0) * 24.0, -rise * 190.0)
		var size := 22.0 + 10.0 * sin(rise * PI)
		var color := Color(RED, 1.0 - rise * rise)
		if color.a > 0.1:
			_props.draw_colored_polygon(Toon.heart_points(p, size + 8.0), Color(Toon.INK, color.a))
			_props.draw_colored_polygon(Toon.heart_points(p, size), color)


func _confetti() -> void:
	var colors := [GOLD, RED, CREAM, Color("3f6fb5")]
	for i in 34:
		var fall := fmod(_clock * (0.18 + Toon.hash01(i, 1) * 0.12) + Toon.hash01(i, 2), 1.0)
		var x := Toon.hash01(i, 3) * 1920.0 + sin(_clock * 2.0 + i) * 20.0
		var y := -60.0 + fall * 1140.0
		var color: Color = colors[i % colors.size()]
		if i % 3 == 0:
			Toon.star(_props, Vector2(x, y), 12.0, _clock * 2.0 + i, color)
		else:
			var a := _clock * 4.0 + i
			_props.draw_line(Vector2(x, y) + Vector2(cos(a), sin(a)) * 9.0, Vector2(x, y) - Vector2(cos(a), sin(a)) * 9.0,
					color, 6.0)


## On the screen, over everything: the iris, the splice, the hint.
func _draw_screen() -> void:
	var iris := _iris()
	if iris.z >= 0.0:
		_draw_iris(Vector2(iris.x, iris.y), iris.z)
	var hint := "Enter — дальше   ·   Esc — пропустить"
	var font := Ui.font()
	_screen.draw_string_outline(font, Vector2(0, 1046), hint, HORIZONTAL_ALIGNMENT_RIGHT, 1860, 24, 6, Toon.INK)
	_screen.draw_string(font, Vector2(0, 1046), hint, HORIZONTAL_ALIGNMENT_RIGHT, 1860, 24, Color(CREAM, 0.45))
	if _cut > 0.0:
		_screen.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.01, 0.01))


## Where the scene closes down to: the eyes in the alley, the manhole the
## Baron went down, the cellar door; the middle for the rest.
func _focus() -> Vector2:
	match _scene():
		"evening":
			return _world.transform * Vector2(2020, 560)
		"kidnap":
			return _world.transform * HOLE
		"chase":
			return _world.transform * HATCH
	return Vector2(960, 560)


## The circle the scene now shows through, as (x, y, radius): growing as it
## opens, shrinking down on its focus at its end; a radius of -1 when there
## is none.
## Cards are not irised, nor the ends of shots cut together.
func _iris() -> Vector3:
	if _scene() == "":
		return Vector3(0, 0, -1)
	var shot := shots[_index]
	var opens := str(shot.get("open", "")) != "cut"
	var closes := str(shot.get("close", "")) != "cut"
	var center := Vector2(960, 560)
	var k := 1.0
	if opens and _t < IRIS_OPEN:
		k = ease(_t / IRIS_OPEN, 0.4)
	elif closes and _t > _length - IRIS_CLOSE:
		k = ease(maxf(_length - _t, 0.0) / IRIS_CLOSE, 2.2)
		center = _focus()
	if k >= 1.0:
		return Vector3(0, 0, -1)
	var full := 0.0
	for corner: Vector2 in [Vector2.ZERO, Vector2(1920, 0), Vector2(0, 1080), Vector2(1920, 1080)]:
		full = maxf(full, center.distance_to(corner))
	return Vector3(center.x, center.y, full * k)


## Black round a circle of [param radius] at [param center].
func _draw_iris(center: Vector2, radius: float) -> void:
	var n := 72
	var far := 3000.0
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		_screen.draw_colored_polygon(PackedVector2Array([center + d0 * radius, center + d1 * radius,
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
