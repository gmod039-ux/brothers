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


func hurt(damage: float, direction: Vector2) -> void:
	if dead:
		return
	hp -= damage
	_flash = 1.0 / Toon.FPS
	_squash = 2.0 / Toon.FPS
	_knock = direction * KNOCK_SPEED * knockback
	if hp <= 0.0:
		knock_out()


func knock_out() -> void:
	if dead:
		return
	dead = true
	room.enemies.erase(self)
	var puff := Puff.new()
	puff.radius = radius
	room.effects.add_child(puff)
	puff.global_position = global_position
	knocked_out.emit(self)
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
	Toon.spot(self, Vector2(0, 2), Vector2(shadow, shadow * 0.34) * grow, Color(Toon.INK, 0.25))
	var squash := 0.16 if _squash > 0.0 else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(grow * (1.0 + squash), grow * (1.0 - squash)))
	draw_body(boil, _flash > 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_body(_boil: int, _flash_now: bool) -> void:
	pass


## [param color], or white while flashing from a hit.
static func paint(color: Color, flash: bool) -> Color:
	return Toon.WHITE if flash else color


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
