class_name BrotherLook
extends Node2D
## How a brother is drawn, in the manner of a 1930s cartoon: a rubber-hose
## body -- tube arms and legs, big shoes, white gloves -- under a head that
## can be one of several characters (a cat, a match, a light bulb, an
## inkwell, a plain boy), each with pie-cut eyes. Drawn from the feet up,
## with (0, 0) on the floor under him.
##
## Walking, recoil and the boil of the outlines change at [constant
## Toon.FPS] drawings a second; the brother himself moves every frame.

const FLAME := Color("f08a24")
const FLAME_CORE := Color("ffd84a")
const METAL := Color("a3a3a8")
const CORK := Color("a0703f")
const PINK := Color("e8908e")

## "cat", "match", "bulb", "inkwell" or "human".
var head := "human"
var size := 1.0
## The head itself: skin, fur, the match head, the glass of a bulb or bottle.
var head_color := Color("f3cfa2")
## A second colour on the head: a cat's face, a bottle's label.
var face_color := Color("f6e3c4")
var shirt := Color("c8392b")
var pants := Color("3d4a78")
var shoes := Color("3a2418")
## What he wears or carries up top: "cap", "tuft", "bow", "quill" or "none".
var hat := "none"
var hat_color := Color("6f4a2e")
var nose := Color("d9826a")

## One of the four directions: which way the head looks.
var facing := Vector2.DOWN
## Shooting direction, or zero.
var aim := Vector2.ZERO
var moving := false
## How fast the legs go, 1 at speed 1.0.
var walk_rate := 1.0
## Invisible for this drawing: the blinking after a hit.
var blink := false
## Down and seeing stars.
var knocked := false

var _clock := 0.0
var _walk_clock := 0.0
var _drawing := 0
var _recoil := 0.0
var _flinch := 0.0
var _seed := 0


func _ready() -> void:
	_seed = get_instance_id() % 997


func configure(look: Dictionary) -> void:
	head = str(look.get("head", head))
	size = float(look.get("size", size))
	head_color = _color(look, "head_color", _color(look, "skin", head_color))
	face_color = _color(look, "face_color", face_color)
	shirt = _color(look, "shirt", shirt)
	pants = _color(look, "pants", pants)
	shoes = _color(look, "shoes", shoes)
	hat = str(look.get("hat", hat))
	hat_color = _color(look, "hat_color", hat_color)
	nose = _color(look, "nose", nose)


static func _color(look: Dictionary, key: String, fallback: Color) -> Color:
	return Color(str(look[key])) if look.has(key) else fallback


func recoil(_direction: Vector2) -> void:
	_recoil = 1.5 / Toon.FPS


func flinch() -> void:
	_flinch = 3.0 / Toon.FPS


func _process(delta: float) -> void:
	_clock += delta
	if moving:
		_walk_clock += delta * walk_rate
	_recoil = maxf(_recoil - delta, 0.0)
	_flinch = maxf(_flinch - delta, 0.0)
	_drawing = int(_clock * Toon.FPS)
	queue_redraw()


func _draw() -> void:
	var s := size
	Toon.spot(self, Vector2(0, 2), Vector2(31, 10) * s, Color(Toon.INK, 0.25))
	if blink:
		return
	if knocked:
		_draw_knocked()
		return
	var squash := 0.0
	if _recoil > 0.0:
		squash = 0.07
	if _flinch > 0.0:
		squash = -0.1
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + squash, 1.0 - squash))
	_draw_body(facing, aim, moving)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The four-drawing walk cycle position, or -1 standing.
func _phase() -> int:
	return int(_walk_clock * Toon.FPS) % 4 if moving else -1


func _draw_body(face: Vector2, shoot: Vector2, walking: bool) -> void:
	var s := size
	var boil := _drawing
	var phase := _phase() if walking else -1
	var stride := 0.0
	if phase >= 0:
		stride = [0.0, 1.0, 0.0, -1.0][phase]
	var bob := 0.0
	if phase >= 0:
		bob = -3.5 * s if phase % 2 == 0 else 0.0
	else:
		# Breathing: up and down once a second.
		bob = -1.5 * s if (_drawing / 6) % 2 == 0 else 0.0
	var side := face.x != 0.0
	var dx := signf(face.x) if side else 1.0
	var hip := Vector2(0, -32.0 * s + bob)
	var chest := Vector2(0, -56.0 * s + bob)
	var head_at := Vector2(0, -95.0 * s + bob)

	if head == "cat" and face.y >= 0.0:
		_tail(hip, side, dx)

	# Legs and shoes.
	var feet: Array[Vector2] = []
	var hips: Array[Vector2] = []
	if side:
		feet = [Vector2(-stride * 14.0 * dx * s, -absf(stride) * 3.0 * s),
				Vector2(stride * 14.0 * dx * s, 0.0)]
		hips = [hip + Vector2(-3.0 * s, 0), hip + Vector2(3.0 * s, 0)]
	else:
		feet = [Vector2(-12.0 * s, -6.0 * s if stride > 0.0 else 0.0),
				Vector2(12.0 * s, -6.0 * s if stride < 0.0 else 0.0)]
		hips = [hip + Vector2(-9.0 * s, 0), hip + Vector2(9.0 * s, 0)]
	for i in 2:
		var ankle := feet[i] + Vector2(0, -5.0 * s)
		var bend := (4.0 if i == 0 else -4.0) * s
		Toon.hose(self, hips[i], ankle, bend, 12.0 * s)
		Toon.hose(self, hips[i], ankle, bend, 7.0 * s, pants)
	for i in 2:
		var toe := Vector2(dx * 6.0 * s, 0) if side else Vector2(0, 1.0 * s)
		Toon.blob(self, feet[i] + toe, Vector2(14.0, 8.5) * s, shoes, boil, _seed + 10 + i, 4.0)

	# Arms: in profile the far one behind the body and the near one in
	# front; face on, both behind when shooting up and in front otherwise.
	var arms_behind := shoot.y < 0.0
	if side:
		_draw_arms(chest, shoot, stride, side, dx, boil, [0])
	elif arms_behind:
		_draw_arms(chest, shoot, stride, side, dx, boil, [0, 1])
	var width := 0.85 if side else 1.0
	Toon.blob(self, hip + Vector2(0, -6.0 * s), Vector2(21.0 * width, 13.0) * s, pants, boil, _seed + 1)
	Toon.blob(self, chest, Vector2(23.0 * width, 17.0) * s, shirt, boil, _seed + 2)
	if head == "cat" and not (face.y < 0.0 and not side):
		Toon.spot(self, chest + Vector2(dx * 4.0 * s if side else 0.0, 3.0 * s), Vector2(13.0, 10.0) * s * width,
				face_color, boil, _seed + 9)
	if side:
		_draw_arms(chest, shoot, stride, side, dx, boil, [1])
	elif not arms_behind:
		_draw_arms(chest, shoot, stride, side, dx, boil, [0, 1])

	var back := face.y < 0.0 and not side
	match head:
		"cat":
			_head_cat(head_at, face, shoot, side, dx, back, boil)
		"match":
			_head_match(head_at, face, shoot, back, boil)
		"bulb":
			_head_bulb(head_at, face, shoot, back, boil)
		"inkwell":
			_head_inkwell(head_at, face, shoot, back, boil)
		_:
			_head_human(head_at, face, shoot, side, dx, back, boil)
	if hat == "bow" and not back:
		_bow(chest + Vector2(dx * 3.0 * s if side else 0.0, -8.0 * s), boil)


func _draw_arms(chest: Vector2, shoot: Vector2, stride: float, side: bool, dx: float,
		boil: int, which_arms: Array) -> void:
	var s := size
	var swing := stride * 6.0 * s
	var shoulders := [chest + Vector2(-18.0 * s, -4.0 * s), chest + Vector2(18.0 * s, -4.0 * s)]
	var hands := [chest + Vector2(-30.0 * s, 16.0 * s + swing),
			chest + Vector2(30.0 * s, 16.0 * s - swing)]
	if side:
		shoulders = [chest + Vector2(-dx * 4.0 * s, -4.0 * s), chest + Vector2(dx * 4.0 * s, -4.0 * s)]
		hands = [chest + Vector2(dx * (0.0 + stride * 12.0) * s, 16.0 * s),
				chest + Vector2(dx * (9.0 - stride * 12.0) * s, 18.0 * s)]
	if shoot != Vector2.ZERO:
		# The hand nearer the shot points it, pulled back a little on recoil;
		# in profile, the near hand.
		var reach := 30.0 * s - (6.0 * s if _recoil > 0.0 else 0.0)
		var which := 1 if side or shoot.x >= 0.0 else 0
		hands[which] = (shoulders[which] as Vector2) + shoot * reach + Vector2(0, 4.0 * s)
	for i: int in which_arms:
		var bend := (-6.0 if i == 0 else 6.0) * s
		Toon.hose(self, shoulders[i], hands[i], bend, 6.0 * s)
		Toon.glove(self, hands[i], 9.5 * s, boil, _seed + 20 + i)


# --- faces -------------------------------------------------------------------


## Two pie eyes, a nose and a smile around [param at], turned the way he
## faces. [param gap] is half the distance between the eyes; the mouth
## [param mouth] wide sits [param drop] below the eyes.
func _face(at: Vector2, eye: Vector2, gap: float, mouth: float, drop: float, face: Vector2,
		shoot: Vector2, boil: int, nose_size := Vector2.ZERO, nose_color := Toon.INK) -> void:
	var s := size
	var look := shoot if shoot != Vector2.ZERO else face * 0.5
	# Now and then a blink: one drawing in about thirty.
	var shut := Toon.hash01(_drawing, _seed) < 0.035
	var turn := signf(face.x)
	var shift := turn * gap * 0.95
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var spread := gap * (0.62 if turn != 0.0 else 1.0)
		var r := eye * (0.8 if turn != 0.0 and sx != turn else 1.0)
		_eye(at + Vector2(sx * spread + shift, 0), r, look, shut, boil, 30 + i)
	if nose_size != Vector2.ZERO:
		Toon.blob(self, at + Vector2(shift * 1.7, drop * 0.5), nose_size, nose_color, boil, _seed + 32, 3.5 * s)
	var m := at + Vector2(shift * 1.25, drop)
	var half := mouth * (0.4 if turn != 0.0 else 0.5)
	Toon.stroke(self, Toon.bent(m - Vector2(half, 0), m + Vector2(half, 0), -mouth * 0.26), 3.5 * s)


func _eye(at: Vector2, radii: Vector2, look: Vector2, shut: bool, boil: int, seed: int) -> void:
	if shut:
		Toon.shut_eye(self, at + Vector2(0, radii.y * 0.2), radii.x * 2.2, 3.5 * size)
	else:
		Toon.pie_eye(self, at, radii, look, boil, _seed + seed, 3.5 * size)


# --- heads -------------------------------------------------------------------


## A cat of the period: black or ginger, a pale face mask, pointed ears,
## whiskers and a tail.
func _head_cat(at: Vector2, face: Vector2, shoot: Vector2, side: bool, dx: float, back: bool,
		boil: int) -> void:
	var s := size
	for sx: float in [-1.0, 1.0]:
		var x := sx * (0.62 if side else 1.0)
		var shift := -dx * 6.0 * s if side else 0.0
		var ear := PackedVector2Array([
			at + Vector2(x * 33.0 * s + shift, -6.0 * s),
			at + Vector2(x * 8.0 * s + shift, -27.0 * s),
			at + Vector2(x * 33.0 * s + shift, -50.0 * s),
		])
		Toon.shape(self, ear, head_color, 5.0 * s)
		if not back:
			var inner := PackedVector2Array()
			var middle := (ear[0] + ear[1] + ear[2]) / 3.0
			for p in ear:
				inner.append(middle + (p - middle) * 0.5 + Vector2(0, 2.0 * s))
			draw_colored_polygon(inner, PINK)
	Toon.blob(self, at, Vector2(36.0, 31.0) * s, head_color, boil, _seed + 5)
	if back:
		return
	var turn := dx if side else 0.0
	Toon.spot(self, at + Vector2(turn * 9.0 * s, 10.0 * s), Vector2(27.0, 18.0) * s, face_color, boil, _seed + 6)
	# Whiskers on the side he faces, or both.
	for sx: float in [-1.0, 1.0]:
		if side and sx != dx:
			continue
		for k in 3:
			var from := at + Vector2(turn * 14.0 * s + sx * 14.0 * s, (8.0 + k * 4.0) * s)
			var to := at + Vector2(turn * 14.0 * s + sx * 40.0 * s, (3.0 + k * 8.0) * s)
			Toon.stroke(self, PackedVector2Array([from, to]), 2.2 * s)
	_face(at + Vector2(0, -4.0 * s), Vector2(9.0, 13.0) * s, 12.5 * s, 20.0 * s, 18.0 * s, face,
			shoot, boil, Vector2(5.0, 3.5) * s, Toon.INK)
	if hat == "tuft":
		_cowlick(at + Vector2(2.0 * s, -30.0 * s), head_color)


func _tail(hip: Vector2, side: bool, dx: float) -> void:
	var s := size
	var swish := [1.0, 0.4, -0.4, -1.0, -0.4, 0.4][(_drawing / 2) % 6] as float
	var root := hip + Vector2(-dx * 16.0 * s if side else 12.0 * s, 2.0 * s)
	var tip := root + Vector2((-dx * 30.0 if side else 30.0) * s + swish * 8.0 * s, -34.0 * s)
	var bend := (18.0 + swish * 6.0) * s * (dx if side else 1.0)
	Toon.hose(self, root, tip, bend, 11.0 * s)
	Toon.hose(self, root, tip, bend, 6.0 * s, head_color)


## A match: the head is the match head, and its flame is his hair.
func _head_match(at: Vector2, face: Vector2, shoot: Vector2, back: bool, boil: int) -> void:
	var s := size
	var flicker := [Vector2(3, 1.0), Vector2(-2, 0.9), Vector2(4, 1.06), Vector2(-3, 0.95)]
	var f: Vector2 = flicker[_drawing % 4]
	var base := at + Vector2(0, -30.0 * s)
	var outer := _flame(base, 18.0 * s, 52.0 * s * f.y, f.x * s)
	Toon.shape(self, outer, FLAME, 4.5 * s)
	Toon.blob(self, at + Vector2(0, -2.0 * s), Vector2(31.0, 35.0) * s, head_color, boil, _seed + 5)
	draw_colored_polygon(_flame(base + Vector2(0, -2.0 * s), 9.0 * s, 26.0 * s * f.y, f.x * 0.7 * s),
			FLAME_CORE)
	# The rough sulphur of a match head.
	for k in 4:
		var p := at + Vector2((Toon.hash01(_seed, k) - 0.5) * 36.0 * s, (Toon.hash01(_seed, k + 9) - 0.2) * 34.0 * s)
		Toon.spot(self, p, Vector2(3.0, 2.2) * s, head_color.darkened(0.25))
	if back:
		return
	_face(at + Vector2(0, -2.0 * s), Vector2(8.0, 11.5) * s, 11.5 * s, 19.0 * s, 17.0 * s, face,
			shoot, boil)


## A flame: round at the bottom, a point at the top that leans with the
## flicker.
static func _flame(base: Vector2, width: float, height: float, lean: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 20
	for i in n:
		var t := TAU * i / n
		var y := -cos(t)
		var x := sin(t) * sin(t * 0.5)
		var up := (1.0 - y) * 0.5
		points.append(base + Vector2(x * width + lean * up * up * 3.0, -(1.0 - y) * 0.5 * height + width * 0.5))
	return points


## A light bulb: a glass head that glows, a filament inside, a screw base
## for a neck.
func _head_bulb(at: Vector2, face: Vector2, shoot: Vector2, back: bool, boil: int) -> void:
	var s := size
	var glow := 0.2 + 0.07 * float(_drawing % 2)
	Toon.spot(self, at + Vector2(0, -8.0 * s), Vector2(64.0, 60.0) * s, Color(1.0, 0.92, 0.55, glow))
	Toon.box(self, at + Vector2(0, 29.0 * s), Vector2(15.0, 9.0) * s, METAL, boil, _seed + 3, 4.0 * s)
	for k in 2:
		var y := (25.0 + k * 6.0) * s
		Toon.stroke(self, PackedVector2Array([at + Vector2(-13.0 * s, y), at + Vector2(13.0 * s, y + 2.0 * s)]), 2.0 * s)
	Toon.blob(self, at + Vector2(0, 16.0 * s), Vector2(18.0, 13.0) * s, head_color, boil, _seed + 4)
	Toon.blob(self, at + Vector2(0, -8.0 * s), Vector2(34.0, 34.0) * s, head_color, boil, _seed + 5)
	# The filament, a zigzag over his eyes.
	var zig := PackedVector2Array()
	for k in 7:
		zig.append(at + Vector2((k - 3) * 4.5 * s, (-27.0 + (3.0 if k % 2 == 0 else -3.0)) * s))
	Toon.stroke(self, zig, 2.6 * s, Color("e36b2c"))
	Toon.spot(self, at + Vector2(-18.0 * s, -24.0 * s), Vector2(5.0, 10.0) * s, Color(1, 1, 1, 0.8), 0, 0, 0.5)
	if back:
		return
	_face(at + Vector2(0, -5.0 * s), Vector2(8.0, 11.5) * s, 12.0 * s, 20.0 * s, 15.0 * s, face,
			shoot, boil)


## An inkwell: a squat glass bottle of ink with a cork, his face on the
## label. His shots are drops of his own ink.
func _head_inkwell(at: Vector2, face: Vector2, shoot: Vector2, back: bool, boil: int) -> void:
	var s := size
	Toon.blob(self, at + Vector2(0, -31.0 * s), Vector2(14.0, 9.0) * s, head_color, boil, _seed + 3, 4.0 * s)
	Toon.box(self, at + Vector2(0, -41.0 * s), Vector2(11.0, 8.0) * s, CORK, boil, _seed + 4, 4.0 * s)
	if hat == "quill":
		var root := at + Vector2(3.0 * s, -46.0 * s)
		var tip := root + Vector2(26.0 * s, -46.0 * s)
		var middle := root.lerp(tip, 0.6)
		var angle := (tip - root).angle()
		Toon.blob(self, middle, Vector2(26.0, 8.0) * s, Toon.WHITE, boil, _seed + 7, 3.5 * s, angle)
		Toon.stroke(self, PackedVector2Array([root, tip]), 2.2 * s)
	Toon.box(self, at + Vector2(0, 2.0 * s), Vector2(36.0, 31.0) * s, head_color, boil, _seed + 5)
	# A drip running down from the neck.
	Toon.blob(self, at + Vector2(20.0 * s, -24.0 * s), Vector2(4.0, 6.0) * s, head_color, boil, _seed + 8, 3.0 * s)
	Toon.spot(self, at + Vector2(-26.0 * s, -6.0 * s), Vector2(4.0, 12.0) * s, Color(1, 1, 1, 0.45))
	if back:
		return
	Toon.box(self, at + Vector2(0, 6.0 * s), Vector2(28.0, 20.0) * s, face_color, boil, _seed + 6, 3.5 * s)
	_face(at + Vector2(0, 2.0 * s), Vector2(7.5, 10.0) * s, 11.0 * s, 15.0 * s, 13.0 * s, face,
			shoot, boil)


## A plain cartoon boy: round head, ears, a nose, and a cap or a mop of hair.
func _head_human(at: Vector2, face: Vector2, shoot: Vector2, side: bool, dx: float, back: bool,
		boil: int) -> void:
	var s := size
	var ear := Vector2(8.0, 10.0) * s
	if not side:
		Toon.blob(self, at + Vector2(-31.0 * s, 2.0 * s), ear, head_color, boil, _seed + 3, 4.0)
		Toon.blob(self, at + Vector2(31.0 * s, 2.0 * s), ear, head_color, boil, _seed + 4, 4.0)
	Toon.blob(self, at, Vector2(34.0, 32.0) * s, head_color, boil, _seed + 5)
	if side:
		Toon.blob(self, at + Vector2(-dx * 5.0 * s, 3.0 * s), ear * 0.9, head_color, boil, _seed + 6, 4.0)
	if not back:
		if not side:
			for sx: float in [-1.0, 1.0]:
				Toon.spot(self, at + Vector2(sx * 21.0 * s, 12.0 * s), Vector2(6.0, 4.0) * s,
						Color(0.9, 0.35, 0.3, 0.35))
		_face(at + Vector2(0, -2.0 * s), Vector2(8.0, 11.5) * s, 11.5 * s, 26.0 * s, 19.0 * s, face,
				shoot, boil, Vector2(7.5, 6.5) * s, nose)
	var dark := hat_color.darkened(0.25)
	if hat == "cap":
		Toon.blob(self, at + Vector2(0, -28.0 * s), Vector2(37.0, 15.0) * s, hat_color, boil, _seed + 40)
		if back:
			return
		if side:
			Toon.blob(self, at + Vector2(dx * 30.0 * s, -18.0 * s), Vector2(19.0, 6.0) * s, dark, boil, _seed + 41, 4.0)
		else:
			Toon.blob(self, at + Vector2(0, -16.0 * s), Vector2(28.0, 6.5) * s, dark, boil, _seed + 41, 4.0)
	elif hat == "tuft":
		Toon.blob(self, at + Vector2(0, -22.0 * s), Vector2(31.0, 13.0) * s, hat_color, boil, _seed + 40)
		_cowlick(at + Vector2(3.0 * s, -33.0 * s), hat_color)


## A cowlick springing up out of the top of the head, swaying.
func _cowlick(root: Vector2, color: Color) -> void:
	var s := size
	var sway := (1.0 if (_drawing / 3) % 2 == 0 else -1.0) * s
	var tip := root + Vector2(10.0 * s + sway, -18.0 * s)
	Toon.hose(self, root, tip, -7.0 * s, 9.0 * s)
	Toon.hose(self, root, tip, -7.0 * s, 4.5 * s, color)


## A bow tie at the collar.
func _bow(at: Vector2, boil: int) -> void:
	var s := size
	for sx: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([at, at + Vector2(sx * 15.0 * s, -8.0 * s),
				at + Vector2(sx * 15.0 * s, 8.0 * s)])
		Toon.shape(self, wing, hat_color, 3.5 * s)
	Toon.blob(self, at, Vector2(5.0, 5.0) * s, hat_color.darkened(0.2), boil, _seed + 50, 3.0 * s)


## Flattened on the floor with stars going round his head.
func _draw_knocked() -> void:
	var s := size
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.3, 0.55))
	_draw_body(Vector2.DOWN, Vector2.ZERO, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var over := Vector2(0, -95.0 * s * 0.55 - 36.0 * s)
	for i in 3:
		var a := _drawing * 0.7 + TAU * i / 3.0
		var at := over + Vector2(cos(a) * 34.0 * s, sin(a) * 10.0 * s)
		Toon.star(self, at, 9.0 * s, a, Color("f2c14e"))
