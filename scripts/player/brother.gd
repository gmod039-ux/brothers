class_name Brother
extends CharacterBody2D
## A brother: walks in eight directions with a little slide, shoots in four,
## and has hearts counted in halves. What he wants to do comes from a
## [PlayerInput], so the same brother is played by a person, a bot or a test.

signal health_changed(hp: int, max_hp: int)
signal hurt_taken
signal died

## The body on the floor: feet, not the whole drawing. Heads may overlap
## walls and enemies' tops, as in Isaac; feet may not.
const RADIUS := 22.0
const ACCEL := 4200.0
## Slower than the acceleration: letting go of a key slides a little.
const FRICTION := 2600.0
const INVULNERABLE := 1.0
const KNOCKBACK := 560.0
## Height above the floor shots leave from: the hands, roughly.
const SHOT_HEIGHT := 46.0
## The share of the brother's own velocity a shot carries along. Shooting
## while strafing curves the stream a little, as it does in Isaac.
const CARRY := 0.35
const LAYER := 2

var id := ""
var display_name := ""
var stats: Stats
var input: PlayerInput
var room: Room
var hp := 6
var dead := false
## Hits still flash and knock back but cost nothing: for the demo and for
## screenshots.
var god := false
var look: BrotherLook
var shots_fired := 0
var damage_taken := 0

var _walk := Vector2.ZERO
var _knock := Vector2.ZERO
var _cooldown := 0.0
var _invulnerable := 0.0
## Shots alternate hands, a few pixels apart.
var _hand := 0


func setup(character_id: String, room_: Room, input_: PlayerInput) -> void:
	id = character_id
	var character := GameData.character(character_id)
	display_name = str(character.get("name", character_id))
	stats = Stats.from_character(character)
	hp = stats.max_hp()
	room = room_
	input = input_
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = LAYER
	collision_mask = Room.WALL_LAYER | Room.ROCK_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	look = BrotherLook.new()
	look.configure(character.get("look", {}))
	add_child(look)


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	input.update(self, delta)
	var target := input.move.limit_length(1.0) * stats.walk_px()
	var rate := ACCEL if input.move != Vector2.ZERO else FRICTION
	_walk = _walk.move_toward(target, rate * delta)
	velocity = _walk + _knock
	move_and_slide()
	_knock = _knock.move_toward(Vector2.ZERO, 2400.0 * delta)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_shoot(delta)
	_touch_enemies()
	_update_look()


func _shoot(delta: float) -> void:
	_cooldown -= delta
	if input.shoot == Vector2.ZERO:
		# Not a charge: the next press fires at once if the last shot is
		# long enough ago, never sooner.
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown > 0.0:
		return
	_cooldown += stats.fire_interval()
	fire(input.shoot)


## Fires one shot along [param aim] (one of the four axes).
func fire(aim: Vector2) -> Shot:
	var side := aim.orthogonal() * (7.0 if _hand == 0 else -7.0)
	_hand = 1 - _hand
	var shot := Shot.new()
	room.actors.add_child(shot)
	shot.launch(room, global_position + aim * 18.0 + side, SHOT_HEIGHT,
			aim * stats.shot_px() + _walk * CARRY, stats.range_px(), stats.damage,
			stats.shot_radius(), false)
	look.recoil(aim)
	shots_fired += 1
	return shot


## Contact damage, the way it is in Isaac: touching an enemy hurts, and
## nothing pushes the brother and the enemy apart.
func _touch_enemies() -> void:
	if _invulnerable > 0.0:
		return
	for enemy in room.enemies:
		if enemy.can_touch() and global_position.distance_to(enemy.global_position) \
				< RADIUS + enemy.radius - 6.0:
			hurt(enemy.contact, enemy.global_position)
			return


## Takes [param amount] half hearts from a hit coming from [param from].
## Returns false when the hit did not land: already down, or still blinking
## from the last one.
func hurt(amount: int, from: Vector2) -> bool:
	if dead or _invulnerable > 0.0:
		return false
	_invulnerable = INVULNERABLE
	_knock = (global_position - from).normalized() * KNOCKBACK
	look.flinch()
	hurt_taken.emit()
	if god:
		return true
	hp = maxi(hp - amount, 0)
	damage_taken += amount
	health_changed.emit(hp, stats.max_hp())
	if hp == 0:
		_die()
	return true


func heal(amount: int) -> void:
	if dead:
		return
	hp = mini(hp + amount, stats.max_hp())
	health_changed.emit(hp, stats.max_hp())


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	look.knocked = true
	look.blink = false
	died.emit()


func _update_look() -> void:
	var walking := _walk.length() > 40.0
	look.moving = walking
	look.walk_rate = clampf(_walk.length() / Stats.SPEED_PX, 0.6, 1.6)
	look.aim = input.shoot
	if input.shoot != Vector2.ZERO:
		# The head turns to where he shoots, whatever way he walks.
		look.facing = input.shoot
	elif walking:
		look.facing = _facing_for(_walk, look.facing)
	look.blink = _invulnerable > 0.0 and int(_invulnerable * Toon.FPS) % 2 == 1


## One of the four directions for a walk, keeping the current one while the
## walk is near diagonal so the head does not flicker between two.
static func _facing_for(walk: Vector2, current: Vector2) -> Vector2:
	var across := Vector2(signf(walk.x), 0.0)
	var along := Vector2(0.0, signf(walk.y))
	if absf(walk.x) > absf(walk.y) * 1.25:
		return across
	if absf(walk.y) > absf(walk.x) * 1.25:
		return along
	return current if current == across or current == along else along
