class_name BrotherLook
extends Node2D
## How a brother is drawn: a rubber-hose character of the early 1930s. A big
## black head with a white face mask peaked between the eyes, a snout with a
## shiny black nose, tall pie-cut eyes pressed together and a wide grin full
## of teeth; a pear of a body, hose arms and legs, flared gloves, big shoes.
## Mostly black and white, with a touch of colour to tell the brothers apart.
##
## Drawn from the feet up, with (0, 0) on the floor under him. Walking, the
## bounce and the boil of the outlines change at [constant Toon.FPS]
## drawings a second; the brother himself moves every frame.

const WHITE := Color("f7f0e1")
const TONGUE := Color("c24a3c")
const GREY := Color("6d6360")

## "lanky" (tall, narrow, long legs) or "chubby" (short, round, big head).
var build := "lanky"
## What sits on top of the head: "quiff" (a slicked-up curl of hair) or
## "ears" (round bear ears).
var top := "quiff"
var size := 1.0
var shirt := WHITE
var pants := Toon.INK
var shoes := Toon.INK
var accent := Color("c8392b")
## "bow" (a bow tie in the accent colour), "straps" (overall straps) or "none".
var wear := "bow"

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
## Held in the startled face a hit gives, for model sheets.
var pose_shocked := false

var _clock := 0.0
var _walk_clock := 0.0
var _drawing := 0
var _recoil := 0.0
var _flinch := 0.0
var _seed := 0

# Proportions, in pixels at size 1, set by [method configure].
var _head_r := 35.0
var _head_y := -122.0
var _body_y := -64.0
var _body_r := Vector2(19, 27)
var _egg := 0.22
var _hip_y := -40.0
var _shoulder_y := -84.0


func _ready() -> void:
	_seed = get_instance_id() % 997


func configure(look: Dictionary) -> void:
	build = str(look.get("build", build))
	top = str(look.get("top", top))
	size = float(look.get("size", size))
	shirt = _color(look, "shirt", shirt)
	pants = _color(look, "pants", pants)
	shoes = _color(look, "shoes", shoes)
	accent = _color(look, "accent", accent)
	wear = str(look.get("wear", wear))
	if build == "chubby":
		_head_r = 40.0
		_head_y = -104.0
		_body_y = -47.0
		_body_r = Vector2(25, 24)
		_egg = 0.38
		_hip_y = -28.0
		_shoulder_y = -62.0
	else:
		_head_r = 35.0
		_head_y = -122.0
		_body_y = -64.0
		_body_r = Vector2(19, 27)
		_egg = 0.22
		_hip_y = -40.0
		_shoulder_y = -84.0


## A colour from the look: a hex code, or "ink" and "white" for the two the
## whole style is drawn in.
static func _color(look: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = look.get(key)
	if value == null:
		return fallback
	var name := str(value)
	if name == "ink":
		return Toon.INK
	if name == "white":
		return WHITE
	return Color(name)


func recoil(_direction: Vector2) -> void:
	_recoil = 1.5 / Toon.FPS


func flinch() -> void:
	_flinch = 4.0 / Toon.FPS


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
	Toon.spot(self, Vector2(0, 2), Vector2(32, 10) * s, Color(Toon.INK, 0.28))
	if blink:
		return
	var wobble := Toon.wobble_scale
	Toon.wobble_scale = 0.2
	if knocked:
		_draw_knocked()
	else:
		var shocked := _flinch > 0.0 or pose_shocked
		_draw_figure(facing, aim, moving, shocked, -0.12 if shocked else _squash(moving))
	Toon.wobble_scale = wobble


## The four-drawing walk cycle position, or -1 standing.
func _phase() -> int:
	return int(_walk_clock * Toon.FPS) % 4 if moving else -1


## How much to squash him about the feet (negative stretches): for recoil,
## for a flinch, for each footfall, and the idle bounce of a character
## keeping time to the music.
func _squash(walking: bool) -> float:
	if _flinch > 0.0:
		return -0.12
	if _recoil > 0.0:
		return 0.08
	if walking:
		return 0.05 if _phase() % 2 == 1 else -0.02
	var bounce := [0.0, 0.025, 0.045, 0.025, 0.0, -0.015]
	return bounce[(_drawing / 2) % bounce.size()]


func _draw_figure(face: Vector2, shoot: Vector2, walking: bool, shocked: bool, squash: float,
		root := Transform2D.IDENTITY) -> void:
	var s := size
	var boil := _drawing
	var phase := _phase() if walking else -1
	var stride := 0.0
	if phase >= 0:
		stride = [0.0, 1.0, 0.0, -1.0][phase]
	var lift := 0.0
	if phase >= 0:
		lift = 5.0 * s if phase % 2 == 0 else 0.0
	var base := root * Transform2D(0.0, Vector2(1.0 + squash, 1.0 - squash), 0.0, Vector2.ZERO)
	draw_set_transform_matrix(base)
	var side := face.x != 0.0
	var dx := signf(face.x) if side else 1.0
	var back := face.y < 0.0 and not side
	# The swagger: the body rocks from side to side on each step.
	var sway := stride * 3.0 * s if not side else 0.0
	var hip := Vector2(sway * 0.3, _hip_y * s - lift)
	var body := Vector2(sway * 0.6, _body_y * s - lift)
	var head := Vector2(sway, _head_y * s - lift)
	var shoulder_y := _shoulder_y * s - lift

	# Arms behind the body: the far one in profile; both from behind or
	# when shooting up.
	var arms_behind := shoot.y < 0.0 or back
	if side:
		_arm(1, body, shoulder_y, shoot, stride, side, dx, boil)
	elif arms_behind:
		_arm(0, body, shoulder_y, shoot, stride, side, dx, boil)
		_arm(1, body, shoulder_y, shoot, stride, side, dx, boil)

	_legs(hip, stride, side, dx, boil)
	_body(body, side, dx, back, boil)
	if wear == "bow" and not back:
		_bow(Vector2(body.x + (dx * 3.0 * s if side else 0.0), body.y - _body_r.y * s * 0.9), boil)

	if side:
		_arm(0, body, shoulder_y, shoot, stride, side, dx, boil)
	elif not arms_behind:
		_arm(0, body, shoulder_y, shoot, stride, side, dx, boil)
		_arm(1, body, shoulder_y, shoot, stride, side, dx, boil)

	# The head nods with the walk, tipping a little each step.
	var tilt := 0.0
	if walking:
		tilt = stride * 0.07 if not side else 0.05 * dx * absf(stride)
	var turn := Transform2D(0.0, head) * Transform2D(tilt, Vector2.ZERO) * Transform2D(0.0, -head)
	draw_set_transform_matrix(base * turn)
	_head(head, face, shoot, side, dx, back, shocked, boil)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _legs(hip: Vector2, stride: float, side: bool, dx: float, boil: int) -> void:
	var s := size
	var feet: Array[Vector2] = []
	var hips: Array[Vector2] = []
	if side:
		feet = [Vector2(stride * 15.0 * dx * s, -(9.0 * s if stride < 0.0 else 0.0)),
				Vector2(-stride * 15.0 * dx * s, -(9.0 * s if stride > 0.0 else 0.0))]
		hips = [hip + Vector2(2.0 * dx * s, 0), hip + Vector2(-2.0 * dx * s, 0)]
	else:
		feet = [Vector2(-11.0 * s, -(9.0 * s if stride > 0.0 else 0.0)),
				Vector2(11.0 * s, -(9.0 * s if stride < 0.0 else 0.0))]
		hips = [hip + Vector2(-8.0 * s, 0), hip + Vector2(8.0 * s, 0)]
	# In profile the far leg goes first, so the near one is drawn over it.
	var order := [1, 0] if side else [0, 1]
	for i: int in order:
		var ankle := feet[i] + Vector2(0, -6.0 * s)
		var raised := feet[i].y < 0.0
		# A lifted leg bends like a rubber hose, not at a knee.
		var bend := (10.0 if raised else 3.0) * s * (dx if side else (-1.0 if i == 0 else 1.0))
		Toon.hose(self, hips[i], ankle, bend, 7.5 * s)
		var toe := Vector2(dx * 8.0 * s, 0) if side else Vector2.ZERO
		var radii := Vector2(19.0, 9.5) * s if side else Vector2(15.5, 10.5) * s
		var shoe := feet[i] + toe + Vector2(0, -2.0 * s)
		Toon.ball(self, shoe, radii, shoes, boil, _seed + 10 + i, 4.5 * s, 0.0, 0.16)
		if shoes != Toon.INK:
			# The line of the sole and a lace on a white one.
			Toon.stroke(self, Toon.bent(shoe + Vector2(-radii.x * 0.8, 4.0 * s),
					shoe + Vector2(radii.x * 0.8, 4.0 * s), 2.0 * s), 2.6 * s)
			var lace := shoe + Vector2(0, -radii.y * 0.45)
			Toon.stroke(self, PackedVector2Array([lace + Vector2(-4, -2) * s, lace + Vector2(4, 2) * s]), 1.8 * s)
			Toon.stroke(self, PackedVector2Array([lace + Vector2(-4, 2) * s, lace + Vector2(4, -2) * s]), 1.8 * s)
		else:
			# A welt round the toe of a black one.
			Toon.stroke(self, Toon.bent(shoe + Vector2(-radii.x * 0.55, radii.y * 0.1),
					shoe + Vector2(radii.x * 0.55, radii.y * 0.1), -radii.y * 0.5), 1.6 * s, Color(1, 1, 1, 0.25))


func _body(at: Vector2, side: bool, dx: float, back: bool, boil: int) -> void:
	var s := size
	var r := _body_r * s * Vector2(0.86 if side else 1.0, 1.0)
	var outline := Toon.ellipse_points(at, r, boil, _seed + 1, 2.5 * s, 0.0, 1.2, 2.0, _egg)
	var fill := Toon.ellipse_points(at, r, boil, _seed + 1, -2.5 * s, 0.0, 1.2, 2.0, _egg)
	draw_colored_polygon(outline, Toon.INK)
	draw_colored_polygon(fill, shirt)
	# Trousers: everything below the waist.
	var waist := at.y + r.y * 0.12
	var legs := Toon.clip_below(fill, waist)
	if legs.size() >= 3:
		draw_colored_polygon(legs, pants)
	# The shadow side, in the darker shade of whichever cloth it falls on;
	# black needs none.
	var shadow := Toon.crescent(at, r, boil, _seed + 1, 5.0 * s, 0.0, _egg)
	if shirt.v > 0.2:
		Toon.polygon(self, Toon.clip_above(shadow, waist), shirt.darkened(0.22))
		Toon.shine(self, at + Vector2(0, -r.y * 0.35), r * 0.6, 0.5)
	if pants.v > 0.2:
		Toon.polygon(self, Toon.clip_below(shadow, waist), pants.darkened(0.22))
	if legs.size() >= 3:
		var ends := _span(legs, waist)
		Toon.stroke(self, PackedVector2Array([Vector2(ends.x, waist), Vector2(ends.y, waist)]), 3.0 * s)
		if not back and wear == "bow":
			# A belt buckle.
			Toon.box(self, Vector2(at.x + (dx * 4.0 * s if side else 0.0), waist), Vector2(5.0, 3.5) * s,
					Color("e8b83a"), boil, _seed + 61, 2.0 * s)
		if not back and wear == "straps" and not side:
			# A pocket on the shorts.
			Toon.stroke(self, Toon.bent(Vector2(at.x + r.x * 0.15, waist + r.y * 0.35),
					Vector2(at.x + r.x * 0.62, waist + r.y * 0.3), -3.0 * s), 2.0 * s)
	if wear == "straps":
		# Overall straps up over the shoulders, a button where each meets
		# the trousers.
		for sx: float in [-1.0, 1.0]:
			if side and sx != dx:
				continue
			var x := sx * r.x * 0.42 + (dx * 3.0 * s if side else 0.0)
			var from := Vector2(at.x + x, waist + 1.0 * s)
			var to := Vector2(at.x + x * 1.12, at.y - r.y * 0.86)
			Toon.stroke(self, PackedVector2Array([from, to]), 7.5 * s)
			Toon.stroke(self, PackedVector2Array([from, to]), 3.5 * s, pants)
			if not back:
				Toon.blob(self, from + Vector2(0, 4.0 * s), Vector2(3.8, 3.8) * s, accent, boil, _seed + 60, 2.5 * s)
	elif not back and wear == "bow":
		# Shirt buttons, and the points of the collar either side of the bow.
		for k in 2:
			var y := at.y - r.y * 0.4 + k * r.y * 0.26
			Toon.spot(self, Vector2(at.x + (dx * 4.0 * s if side else 0.0), y), Vector2(2.6, 2.6) * s, Toon.INK)
		if not side:
			for sx: float in [-1.0, 1.0]:
				var neck := Vector2(at.x + sx * 5.0 * s, at.y - r.y * 0.92)
				Toon.shape(self, PackedVector2Array([neck, neck + Vector2(sx * 11.0, -2.0) * s,
						neck + Vector2(sx * 5.0, 8.0) * s]), shirt, 2.4 * s)


## The leftmost and rightmost x of [param points] on the line y = [param y].
static func _span(points: PackedVector2Array, y: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for p in points:
		if absf(p.y - y) < 0.01:
			lo = minf(lo, p.x)
			hi = maxf(hi, p.x)
	if lo == INF:
		for p in points:
			lo = minf(lo, p.x)
			hi = maxf(hi, p.x)
	return Vector2(lo, hi)


## A bow tie at the collar, in the accent colour.
func _bow(at: Vector2, boil: int) -> void:
	var s := size
	for sx: float in [-1.0, 1.0]:
		var wing := PackedVector2Array([at + Vector2(sx * 2.0 * s, 0), at + Vector2(sx * 15.0 * s, -8.0 * s),
				at + Vector2(sx * 17.0 * s, 0), at + Vector2(sx * 15.0 * s, 8.0 * s)])
		Toon.shape(self, wing, accent, 3.5 * s)
	Toon.blob(self, at, Vector2(5.0, 5.5) * s, accent.darkened(0.2), boil, _seed + 50, 3.0 * s)


## One arm: [param i] 0 is the one on the left of the screen when he faces
## us, and the near one in profile.
func _arm(i: int, body: Vector2, shoulder_y: float, shoot: Vector2, stride: float, side: bool,
		dx: float, boil: int) -> void:
	var s := size
	var sx := -1.0 if i == 0 else 1.0
	var shoulder := Vector2(body.x + sx * _body_r.x * 0.72 * s, shoulder_y)
	var swing := stride * 8.0 * s * (-sx)
	var hand := Vector2(body.x + sx * (_body_r.x + 13.0) * s + swing * 0.4, _hip_y * s + 2.0 * s + swing * 0.3)
	if side:
		# In profile both shoulders are about the middle of the body, and
		# each arm swings against the leg on its side.
		var fore := stride * 15.0 * s * (1.0 if i == 0 else -1.0)
		shoulder = Vector2(body.x + dx * 2.0 * s, shoulder_y)
		hand = Vector2(body.x + dx * 4.0 * s - fore * dx, _hip_y * s - 2.0 * s)
	var pointing := false
	if shoot != Vector2.ZERO:
		var which := 0 if side or shoot.y != 0.0 else (1 if shoot.x > 0.0 else 0)
		if i == which:
			pointing = true
			var reach := 34.0 * s - (7.0 * s if _recoil > 0.0 else 0.0)
			hand = shoulder + shoot * reach + Vector2(0, 6.0 * s if shoot.y == 0.0 else 0.0)
	var toward := (hand - shoulder).normalized()
	var wrist := hand - toward * 9.0 * s
	var bend := (7.0 if i == 0 else -7.0) * s
	Toon.hose(self, shoulder, wrist, bend, 6.5 * s)
	_glove(hand, toward, pointing, shoot, boil, i)


## A white glove with a flared cuff; [param pointing] makes it a finger gun.
func _glove(at: Vector2, toward: Vector2, pointing: bool, shoot: Vector2, boil: int, i: int) -> void:
	var s := size
	var angle := toward.angle()
	Toon.ball(self, at - toward * 10.0 * s, Vector2(5.0, 8.5) * s, WHITE, boil, _seed + 20 + i, 3.5 * s, angle, 0.14)
	if pointing:
		Toon.blob(self, at + shoot * 13.0 * s, Vector2(9.0, 4.2) * s, WHITE, boil, _seed + 24 + i, 3.5 * s,
				shoot.angle())
	Toon.ball(self, at, Vector2(11.0, 10.0) * s, WHITE, boil, _seed + 22 + i, 3.5 * s, angle, 0.14)
	var thumb := at + toward.orthogonal() * (7.0 if i == 0 else -7.0) * s - toward * 2.0 * s
	Toon.blob(self, thumb, Vector2(4.5, 6.0) * s, WHITE, boil, _seed + 26 + i, 3.0 * s, angle)
	for k in 3:
		var across := toward.orthogonal() * (k - 1) * 3.4 * s
		Toon.stroke(self, PackedVector2Array([at + across - toward * 5.0 * s,
				at + across - toward * 1.0 * s]), 1.8 * s)


func _head(at: Vector2, face: Vector2, shoot: Vector2, side: bool, dx: float, back: bool,
		shocked: bool, boil: int) -> void:
	var s := size
	var r := _head_r * s
	var turn := dx if side else 0.0

	if top == "ears":
		var spots: Array = [Vector2(-0.3 * dx, -0.92)] if side else [Vector2(-0.8, -0.72), Vector2(0.8, -0.72)]
		for e: Vector2 in spots:
			var c := at + e * r
			Toon.blob(self, c, Vector2(0.38, 0.36) * r, Toon.INK, boil, _seed + 40, 4.0 * s)
			if not back:
				Toon.spot(self, c + Vector2(0, 0.04 * r), Vector2(0.2, 0.18) * r, GREY, boil, _seed + 41)

	Toon.blob(self, at, Vector2(1.04, 1.0) * r, Toon.INK, boil, _seed + 5)
	# A glint on the black of the head.
	var glint := PackedVector2Array()
	for k in 6:
		var a := deg_to_rad(200.0 + k * 9.0)
		glint.append(at + Vector2(cos(a), sin(a)) * r * 0.78 + Vector2(-turn * 0.1 * r, 0))
	Toon.stroke(self, glint, 3.2 * s, Color(1, 1, 1, 0.75))

	if top == "quiff":
		var sway := 1.0 if (_drawing / 3) % 2 == 0 else 0.6
		var lean := (-turn - 0.35 * sway) * r * 0.25
		var root := at + Vector2(turn * 0.12 * r + 0.1 * r, -0.62 * r)
		Toon.shape(self, _curl(root, 0.44 * r, 0.9 * r, lean * 1.4), Toon.INK, 3.0 * s)
		var shine := root + Vector2(-0.06 * r, -0.36 * r)
		Toon.stroke(self, Toon.bent(shine, shine + Vector2(0.12 * r, 0.22 * r), -0.05 * r), 2.6 * s,
				Color(1, 1, 1, 0.6))
	if back:
		return

	# The face mask: the lower face and a round patch round each eye, one
	# white shape with a peak between the eyes.
	var eye_y := -0.36 * r
	var parts: Array = []
	if side:
		parts = [[at + Vector2(dx * 0.32 * r, 0.3 * r), Vector2(0.72, 0.56) * r],
				[at + Vector2(dx * 0.36 * r, eye_y), Vector2(0.44, 0.5) * r]]
	else:
		parts = [[at + Vector2(0, 0.32 * r), Vector2(0.93, 0.6) * r],
				[at + Vector2(-0.27 * r, eye_y + 0.04 * r), Vector2(0.36, 0.46) * r],
				[at + Vector2(0.27 * r, eye_y + 0.04 * r), Vector2(0.36, 0.46) * r]]
	Toon.union(self, parts, WHITE, boil, _seed + 6, 4.0 * s)
	var jaw: Array = parts[0]
	Toon.shade(self, jaw[0], jaw[1], WHITE, boil, _seed + 6, 4.0 * s, 0.1)

	# Mouth under the snout.
	if shocked:
		var o := at + Vector2(turn * 0.62 * r, 0.56 * r)
		Toon.blob(self, o, Vector2(0.15, 0.2) * r, Toon.INK, boil, _seed + 7, 3.0 * s)
		Toon.spot(self, o + Vector2(0, 0.08 * r), Vector2(0.09, 0.07) * r, TONGUE)
	elif side:
		_mouth(at + Vector2(dx * 0.22 * r, 0.4 * r), at + Vector2(dx * 1.02 * r, 0.3 * r), 0.4 * r, boil)
	else:
		_mouth(at + Vector2(-0.54 * r, 0.36 * r), at + Vector2(0.54 * r, 0.36 * r), 0.46 * r, boil)

	# Eyes: tall, pressed together, looking where he shoots.
	var look := shoot if shoot != Vector2.ZERO else Vector2(turn * 0.8, 0.3)
	var shut := not shocked and Toon.hash01(_drawing, _seed) < 0.03
	var eyes: Array = []
	if side:
		eyes = [[at + Vector2(dx * 0.2 * r, eye_y), Vector2(0.2, 0.35) * r],
				[at + Vector2(dx * 0.46 * r, eye_y), Vector2(0.24, 0.38) * r]]
	else:
		eyes = [[at + Vector2(-0.245 * r, eye_y), Vector2(0.245, 0.38) * r],
				[at + Vector2(0.245 * r, eye_y), Vector2(0.245, 0.38) * r]]
	for k in eyes.size():
		var eye: Array = eyes[k]
		var center: Vector2 = eye[0]
		var radii: Vector2 = eye[1]
		if shut:
			Toon.shut_eye(self, center + Vector2(0, radii.y * 0.25), radii.x * 2.1, 3.5 * s)
		else:
			Toon.pie_eye(self, center, radii, look, boil, _seed + 30 + k, 3.5 * s, 0.55 if shocked else 1.0)

	# Snout and nose, over the bottom of the eyes: the nose is the nearest
	# thing on the face.
	var snout := at + (Vector2(dx * 0.8 * r, 0.14 * r) if side else Vector2(0, 0.2 * r))
	var snout_r := (Vector2(0.5, 0.24) if side else Vector2(0.3, 0.2)) * r
	Toon.ball(self, snout, snout_r, WHITE, boil, _seed + 8, 4.0 * s, 0.0, 0.12)
	var nose := at + (Vector2(dx * 1.24 * r, 0.05 * r) if side else Vector2(0, 0.08 * r))
	var nose_r := (Vector2(0.21, 0.17) if side else Vector2(0.26, 0.18)) * r
	Toon.blob(self, nose, nose_r, Toon.INK, boil, _seed + 9, 3.0 * s)
	Toon.spot(self, nose + Vector2(-0.3, -0.35) * nose_r, Vector2(0.32, 0.26) * nose_r, Color(1, 1, 1, 0.8))


## A wide open grin from corner [param a] to corner [param b], hanging
## [param depth] below them: dark inside, a row of teeth along the top, a
## tongue at the bottom, a crease at each corner.
func _mouth(a: Vector2, b: Vector2, depth: float, boil: int) -> void:
	var s := size
	var n := 14
	var top_edge := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t)
		top_edge.append(p + Vector2(0, -depth * 0.08 * sin(PI * t)))
		bottom.append(p + Vector2(0, depth * pow(sin(PI * t), 0.8)))
	var shape := PackedVector2Array(top_edge)
	for i in range(n - 1, 0, -1):
		shape.append(bottom[i])
	draw_colored_polygon(Toon.grown(shape, 2.5 * s), Toon.INK)
	draw_colored_polygon(shape, Color("2a1712"))
	var width := (b - a).length()
	Toon.spot(self, a.lerp(b, 0.56) + Vector2(0, depth * 0.7), Vector2(0.17, 0.12) * width, TONGUE, boil, _seed + 12)
	var teeth := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in range(2, n - 1):
		var t := float(i) / n
		teeth.append(top_edge[i])
		inner.append(top_edge[i] + Vector2(0, depth * 0.2 * minf(1.0, sin(PI * t) * 2.2)))
	for i in range(inner.size() - 1, -1, -1):
		teeth.append(inner[i])
	draw_colored_polygon(teeth, WHITE)
	for p: Vector2 in [a, b]:
		var out := signf(p.x - (a.x + b.x) * 0.5)
		Toon.stroke(self, Toon.bent(p + Vector2(out * 2.0 * s, -6.0 * s), p + Vector2(out * 5.0 * s, 6.0 * s),
				out * 3.0 * s), 2.6 * s)


## A slicked-up curl of hair: round at the root, a point at the top leaning
## by [param lean] pixels.
static func _curl(root: Vector2, width: float, height: float, lean: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 20
	for i in n:
		var t := TAU * i / n
		var y := -cos(t)
		var x := sin(t) * sin(t * 0.5)
		var up := (1.0 - y) * 0.5
		points.append(root + Vector2(x * width + lean * up * up * 3.0, -up * height + width * 0.5))
	return points


## Flattened on the floor with stars going round his head.
func _draw_knocked() -> void:
	var s := size
	var flat := Transform2D(0.0, Vector2(1.3, 0.55), 0.0, Vector2.ZERO)
	_draw_figure(Vector2.DOWN, Vector2.ZERO, false, true, 0.0, flat)
	var over := Vector2(0, (_head_y - _head_r - 12.0) * s * 0.55)
	for i in 3:
		var a := _drawing * 0.7 + TAU * i / 3.0
		var at := over + Vector2(cos(a) * 38.0 * s, sin(a) * 11.0 * s)
		Toon.star(self, at, 9.0 * s, a, Color("f2c14e"))
