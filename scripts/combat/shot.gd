class_name Shot
extends Node2D
## A shot: a drop of ink from a brother, or a spit from an enemy. It flies at
## a height over the floor with its shadow under it, goes straight until its
## range is nearly used up, then drops and splashes where it lands -- the
## way Isaac's tears fall short.
##
## Its node sits on the floor at the shadow; the drop is drawn [member height]
## above. Hits are worked out on the floor, between shadow and feet.

## Sent just before the shot goes, with what stopped it.
signal finished(how: String)

const GRAVITY := 1800.0
## Past this share of the range the shot starts to fall.
const FALL_AT := 0.8
const INK_BLUE := Color("2d4f8a")
const SPIT := Color("9a2f24")

var room: Room
var velocity := Vector2.ZERO
var height := 40.0
var damage := 3.5
var radius := 13.0
var hostile := false
## Whose spit it is, for the card at the end.
var source := ""
var reach := 700.0
var travelled := 0.0
var falling := false
## What stopped it: "" still flying, "floor", "wall", "enemy", "brother".
var ended := ""
## Item powers: turns towards the nearest enemy; goes on through enemies;
## flies over rocks; how hard it knocks enemies back.
var homing := false
var pierce := false
var spectral := false
var knockback := 1.0
## A colour of its own (a fireball), or clear for the usual ink or spit.
var tint := Color(0, 0, 0, 0)
## How it is drawn: "" a drop, "card" a spinning playing card.
var look := ""

var _hit := {}

var _vz := 0.0
var _clock := 0.0


func launch(room_: Room, at: Vector2, height_: float, velocity_: Vector2, reach_: float,
		damage_: float, radius_: float, hostile_: bool) -> void:
	room = room_
	global_position = at
	height = height_
	velocity = velocity_
	reach = reach_
	damage = damage_
	radius = radius_
	hostile = hostile_


func _physics_process(delta: float) -> void:
	if ended != "":
		return
	if homing and not hostile:
		_home(delta)
	var step := velocity * delta
	global_position += step
	travelled += step.length()
	if not falling and travelled >= reach * FALL_AT:
		falling = true
	if falling:
		_vz += GRAVITY * delta
		height -= _vz * delta
		if height <= 0.0:
			height = 0.0
			_end("floor")
			return
	if room.blocks_shot(global_position, spectral):
		room.hit_tile(global_position)
		_end("wall")
		return
	if hostile:
		for brother in room.brothers:
			# The body is taller than the feet: a spit at head height
			# still hits.
			if not brother.dead and global_position.distance_to(brother.global_position) \
					< radius + Brother.RADIUS + 6.0:
				brother.hurt(1, global_position - velocity.normalized() * 10.0, source)
				_end("brother")
				return
	else:
		for enemy in room.enemies:
			if _hit.has(enemy):
				continue
			if enemy.can_be_hit() and global_position.distance_to(enemy.global_position) \
					< radius + enemy.radius:
				enemy.hurt(damage, velocity.normalized(), knockback)
				if pierce:
					# On through, but never twice into the same one.
					_hit[enemy] = true
					continue
				_end("enemy")
				return


## Bends the flight a little towards the nearest enemy ahead, keeping the
## speed.
func _home(delta: float) -> void:
	var best: Enemy = null
	var best_d := 420.0
	for enemy in room.enemies:
		if not enemy.can_be_hit() or _hit.has(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	if best == null:
		return
	var want := (best.global_position - global_position).angle()
	var now := velocity.angle()
	var turn := clampf(wrapf(want - now, -PI, PI), -4.0 * delta, 4.0 * delta)
	velocity = velocity.rotated(turn)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _fill() -> Color:
	if tint.a > 0.0:
		return tint
	return SPIT if hostile else INK_BLUE


## Gone in a splash where it is: time stopped under it.
func pop() -> void:
	if ended == "":
		_end("pop")


func _end(how: String) -> void:
	ended = how
	finished.emit(how)
	var splat := Splat.new()
	splat.color = _fill()
	splat.radius = radius
	# Against a wall the splash is where the drop was, up in the air; on the
	# floor, where it landed.
	var at := global_position + (Vector2(0, -height) if how != "floor" else Vector2.ZERO)
	room.effects.add_child(splat)
	splat.global_position = at
	if how == "floor" and room.stains != null and randf() < 0.5:
		room.stains.add(global_position, radius * 0.7, Color(_fill(), 0.32))
	queue_free()


func _draw() -> void:
	var r := radius
	var shade := clampf(1.0 - height / 160.0, 0.5, 1.0)
	Toon.spot(self, Vector2.ZERO, Vector2(r * 0.95, r * 0.36) * shade, Color(Toon.INK, 0.22))
	var at := Vector2(0, -height)
	var angle := velocity.angle()
	var fill := _fill()
	var boil := int(_clock * Toon.FPS)
	if look == "card":
		# A playing card, spinning end over end, a red suit on it.
		var spin := _clock * 9.0
		Toon.box(self, at, Vector2(r * 0.8, r * 1.1), BrotherLook.WHITE, boil, 3, 3.5, spin)
		Toon.heart(self, at, r * 0.9, 2, Color("c8392b"), Color("c8392b"))
		return
	if look == "bone":
		# A bone, end over end.
		var turn := Vector2.from_angle(_clock * 13.0) * r * 0.95
		var across := turn.orthogonal().normalized() * r * 0.32
		Toon.stroke(self, PackedVector2Array([at - turn, at + turn]), r * 0.55 + 5.0)
		for end: Vector2 in [at - turn, at + turn]:
			Toon.blob(self, end + across, Vector2(r * 0.34, r * 0.34), fill, boil, 4, 2.5)
			Toon.blob(self, end - across, Vector2(r * 0.34, r * 0.34), fill, boil, 5, 2.5)
		Toon.stroke(self, PackedVector2Array([at - turn, at + turn]), r * 0.55, fill)
		return
	if look == "steam":
		# A puff of steam, swelling as it goes, wisps trailing.
		var grow := 1.0 + clampf(travelled / reach, 0.0, 1.0) * 0.5
		var behind := -velocity.normalized()
		for k in 2:
			Toon.spot(self, at + behind * r * (1.4 + k * 1.1), Vector2(r, r * 0.8) * (0.7 - k * 0.2) * grow,
					Color(1, 1, 1, 0.35 - k * 0.12), boil, k)
		Toon.blob(self, at, Vector2(r * 1.15, r) * grow, fill, boil, get_instance_id() % 89, 3.5)
		Toon.spot(self, at + Vector2(-r * 0.3, -r * 0.3), Vector2(r * 0.4, r * 0.3), Color(1, 1, 1, 0.8), 0, 0)
		return
	# A trail of smaller drops behind, the way a fast thing is drawn.
	var back := -velocity.normalized()
	for k in 3:
		var t := (k + 1) / 4.0
		var trail := at + back * r * (1.1 + k * 0.9)
		Toon.spot(self, trail, Vector2(r, r * 0.8) * (0.62 - t * 0.35), Color(fill, 0.55 - t * 0.4), 0, k)
	Toon.blob(self, at, Vector2(r * 1.1, r * 0.92), fill, boil, get_instance_id() % 89, 4.0, angle)
	Toon.spot(self, at + Vector2(-r * 0.32, -r * 0.34), Vector2(r * 0.3, r * 0.2),
			Color(1, 1, 1, 0.85), 0, 0, -0.6)
