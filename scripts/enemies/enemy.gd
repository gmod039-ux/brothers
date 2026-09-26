class_name Enemy
extends CharacterBody2D
## What every enemy shares: health, flashing white and flying back when hit,
## hurting on touch, popping into the room and going "poof" out of it.
## A kind of enemy says how it moves ([method think]) and what it looks like
## ([method draw_body]); its numbers come from data/enemies.json.

signal knocked_out(enemy: Enemy)

const LAYER := 4
## Popping in takes this long; it cannot hurt anyone meanwhile, so an enemy
## never appears on top of a brother and hits him in the same instant.
const SPAWN_TIME := 0.5
## Speed a hit of knockback 1.0 sends it flying at.
const KNOCK_SPEED := 260.0
## Knocked out, it is not gone at once: it hops, spins and sees stars for
## this long, X for eyes, then goes poof.
const KO_TIME := 0.34

var kind := ""
var display_name := ""
var hp := 10.0
var max_hp := 10.0
var radius := 26.0
var speed := 100.0
var contact := 1
var flying := false
var knockback := 1.0
var def: Dictionary = {}
var room: Room
var rng: RandomNumberGenerator
var dead := false

var _knock := Vector2.ZERO
var _flash := 0.0
var _squash := 0.0
var _spawn := SPAWN_TIME
var _clock := 0.0
var _seed := 0
## Which floor it lives on -- 0 the basement, 1 the boiler room, 2 the
## catacombs. The same creature is sooty in the boiler room and deathly
## pale in the catacombs, and wears what they wear down there.
var floor_look := 0
## Seconds its eyes stay screwed shut after a hit.
var _wince := 0.0
## Seconds into being knocked out, or -1.
var _ko := -1.0
var _gone := false


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	kind = kind_
	def = GameData.enemies().get(kind_, {})
	display_name = str(def.get("name", kind_))
	max_hp = float(def.get("hp", max_hp))
	hp = max_hp
	radius = float(def.get("radius", radius))
	speed = float(def.get("speed", speed))
	contact = int(def.get("contact", contact))
	flying = bool(def.get("flying", flying))
	knockback = float(def.get("knockback", knockback))
	room = room_
	rng = rng_
	_seed = rng.randi() % 1000
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = LAYER
	# Fliers go over rocks; nothing goes through walls.
	collision_mask = Room.WALL_LAYER | (0 if flying else Room.ROCK_LAYER)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius * 0.75
	shape.shape = circle
	add_child(shape)


func can_touch() -> bool:
	return not dead and _spawn <= 0.0


func can_be_hit() -> bool:
	return not dead and _spawn <= SPAWN_TIME * 0.4


func _physics_process(delta: float) -> void:
	if dead:
		# Knocked out: flies on a little with the blow that did it.
		position += _knock * delta * 0.6
		_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
		return
	_spawn = maxf(_spawn - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	_squash = maxf(_squash - delta, 0.0)
	var want := Vector2.ZERO
	if _spawn <= 0.0:
		want = think(delta)
	velocity = want + _separation() + _knock
	move_and_slide()
	_knock = _knock.move_toward(Vector2.ZERO, 1500.0 * delta)


## Where it wants to go this tick, as a velocity.
func think(_delta: float) -> Vector2:
	return Vector2.ZERO


## The nearest brother still standing, or null.
func target() -> Brother:
	var best: Brother = null
	var best_d := INF
	for brother in room.brothers:
		if brother.dead:
			continue
		var d := global_position.distance_squared_to(brother.global_position)
		if d < best_d:
			best_d = d
			best = brother
	return best


## Takes [param damage] from a hit going [param direction]; [param strength]
## scales the knockback (items make it hit harder).
func hurt(damage: float, direction: Vector2, strength := 1.0) -> void:
	if dead:
		return
	hp -= damage
	Sfx.play("hit", -10.0, 0.12)
	_flash = 1.0 / Toon.FPS
	_squash = 2.0 / Toon.FPS
	_wince = 3.0 / Toon.FPS
	_knock = direction * KNOCK_SPEED * knockback * strength
	if hp <= 0.0:
		knock_out()


func knock_out() -> void:
	if dead:
		return
	dead = true
	Sfx.play("poof", -4.0, 0.1)
	room.enemies.erase(self)
	knocked_out.emit(self)
	collision_layer = 0
	collision_mask = 0
	# Bosses draw themselves and have their own ends; the rest take a bow.
	if self is Boss or not is_inside_tree():
		_vanish()
		return
	_ko = 0.0
	_knock = _knock.normalized() * maxf(_knock.length(), 160.0) if _knock != Vector2.ZERO \
			else Vector2(0, -1) * 160.0
	Fx.burst(room, global_position + Vector2(0, -radius * 1.4), "stars", 3, 0.45)


## The poof at the end of it all, and the blot it leaves.
func _vanish() -> void:
	if _gone:
		return
	_gone = true
	var puff := Puff.new()
	puff.radius = radius
	room.effects.add_child(puff)
	puff.global_position = global_position
	if room.stains != null and not flying:
		room.stains.add(global_position + Vector2(0, 4), radius * 1.1, Stains.INK, true)
	elif room.stains != null:
		room.stains.add(global_position + Vector2(0, 30), radius * 0.8, Stains.INK, true)
	Fx.shake(0.08)
	queue_free()


## Enemies shoulder each other apart rather than stack into one.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in room.enemies:
		if other == self or other.flying != flying:
			continue
		var d := global_position - other.global_position
		var gap := (radius + other.radius) * 0.8
		var length := d.length()
		if length < gap and length > 0.01:
			push += d / length * (gap - length) * 5.0
	return push


func _process(delta: float) -> void:
	_clock += delta
	_wince = maxf(_wince - delta, 0.0)
	if _ko >= 0.0:
		_ko += delta
		if _ko >= KO_TIME:
			_vanish()
	queue_redraw()


func _draw() -> void:
	var boil := int(_clock * Toon.FPS)
	var grow := 1.0
	if _spawn > 0.0:
		# Pops in: small, too big, settles.
		var steps := [0.2, 0.55, 1.18, 0.94, 1.03, 1.0]
		var i := mini(int((1.0 - _spawn / SPAWN_TIME) * steps.size()), steps.size() - 1)
		grow = steps[i]
	var shadow := radius * (0.7 if flying else 1.0)
	if _ko >= 0.0:
		# The bow: up it goes, turning, flattening as it comes down.
		var t := clampf(_ko / KO_TIME, 0.0, 1.0)
		var hop := sin(t * PI) * 30.0
		var turn := (1.0 if _seed % 2 == 0 else -1.0) * t * 1.2
		Toon.spot(self, Vector2(0, 2), Vector2(shadow, shadow * 0.34) * (1.0 - t * 0.4), Color(Toon.INK, 0.25))
		draw_set_transform(Vector2(0, -hop), turn, Vector2(1.0 + 0.3 * t, 1.0 - 0.35 * t))
		draw_body(int(_ko * Toon.FPS) + boil, t < 0.2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	Toon.spot(self, Vector2(0, 2), Vector2(shadow, shadow * 0.34) * grow, Color(Toon.INK, 0.25))
	var squash := 0.16 if _squash > 0.0 else 0.0
	draw_set_transform(Vector2(0, -lift()), 0.0,
			Vector2(grow * (1.0 + squash), grow * (1.0 - squash)) * stretch())
	draw_body(boil, _flash > 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## How high off the floor it is drawn (its shadow stays down): a leap.
func lift() -> float:
	return 0.0


## How it is squashed or stretched as a whole: a crouch, a jump.
func stretch() -> Vector2:
	return Vector2.ONE


func draw_body(_boil: int, _flash_now: bool) -> void:
	pass


## [param color], or white while flashing from a hit.
static func paint(color: Color, flash: bool) -> Color:
	return Toon.WHITE if flash else color


## [param color] as it looks on this floor -- sooty in the boiler room,
## pale as a grub in the catacombs -- or white while flashing from a hit.
func skin(color: Color, flash: bool) -> Color:
	if flash:
		return Toon.WHITE
	match floor_look:
		1:
			return color.darkened(0.28).lerp(Color("3c3842"), 0.22)
		2:
			return color.lerp(Color("c8ccb4"), 0.58)
	return color


## An eye that feels things: the usual pie-cut eye, screwed shut for a
## moment after a hit, X'd out when knocked out.
func eye(center: Vector2, radii: Vector2, look: Vector2, boil: int, seed_: int, line := 3.0,
		pupil := 1.0) -> void:
	if _ko >= 0.0:
		Toon.blob(self, center, radii, Toon.WHITE, boil, seed_, line)
		var r := radii * 0.5
		Toon.stroke(self, PackedVector2Array([center - r, center + r]), line)
		Toon.stroke(self, PackedVector2Array([center + Vector2(-r.x, r.y), center + Vector2(r.x, -r.y)]), line)
	elif _wince > 0.0:
		# Squeezed shut: a zigzag where the eye was.
		var w := radii.x
		Toon.stroke(self, PackedVector2Array([center + Vector2(-w, -radii.y * 0.3), center + Vector2(0, radii.y * 0.15),
				center + Vector2(w, -radii.y * 0.3)]), line)
	else:
		Toon.pie_eye(self, center, radii, look, boil, seed_, line, pupil)


## True while it cannot see: squeezing its eyes shut or knocked out. What
## sits over the eyes (lids, brows) is left off then.
func eyes_shut() -> bool:
	return _ko >= 0.0 or _wince > 0.0


## Smudges of soot on the boiler room's lot.
func soot(center: Vector2, radii: Vector2, boil: int) -> void:
	if floor_look != 1:
		return
	for i in 3:
		var a := Toon.hash01(_seed, 40 + i) * TAU
		var at := center + Vector2(cos(a) * radii.x * 0.55, sin(a) * radii.y * 0.5)
		Toon.spot(self, at, Vector2(radii.x * 0.26, radii.y * 0.16), Color(0.06, 0.05, 0.06, 0.5), boil, _seed + i)


## Where the pupils should point: at the nearest brother.
func gaze() -> Vector2:
	var t := target()
	if t == null:
		return Vector2.ZERO
	return (t.global_position - global_position).normalized()


## An angry eyebrow over an eye at [param at]: slanting down towards the
## middle of the face.
func brow(at: Vector2, width: float, inner_right: bool, line := 4.0) -> void:
	var drop := width * 0.35
	var a := at + Vector2(-width * 0.5, -drop if inner_right else drop)
	var b := at + Vector2(width * 0.5, drop if inner_right else -drop)
	Toon.stroke(self, PackedVector2Array([a, b]), line)
