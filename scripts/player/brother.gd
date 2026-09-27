class_name Brother
extends CharacterBody2D
## A brother: walks in eight directions with a little slide, shoots in four,
## and has hearts counted in halves. What he wants to do comes from a
## [PlayerInput], so the same brother is played by a person, a bot or a test.

signal health_changed(hp: int, max_hp: int)
signal hurt_taken
signal died
## Back on his feet after being knocked out, with his brother still up.
signal revived
## Coins, bombs, keys or items changed.
signal inventory_changed
signal item_taken(id: String)
## The item in his hands was used, or charged up.
signal active_changed

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
## Held still, e.g. while the camera slides to the next room.
var frozen := false
## Coins, bombs and keys: in one pocket for both brothers, as in Isaac's
## co-op. Alone, the pocket is his own.
var purse := Purse.new()
var coins: int:
	get:
		return purse.coins
	set(value):
		purse.coins = value
var bombs: int:
	get:
		return purse.bombs
	set(value):
		purse.bombs = value
var keys: int:
	get:
		return purse.keys
	set(value):
		purse.keys = value
## 1 or 2: which player, for the second one's place on the HUD.
var player := 1
## Items taken, in order.
var items: Array[String] = []
## The item in his hands (Space, RB), "" for none, and how many beaten
## rooms of charge it has.
var active := ""
var charge := 0
## Seconds left of the fizz of a soda: quicker feet and hands.
var boost := 0.0

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
	if dead or frozen:
		return
	input.update(self, delta)
	boost = maxf(boost - delta, 0.0)
	var target := input.move.limit_length(1.0) * stats.walk_px() * (1.25 if boost > 0.0 else 1.0)
	var rate := ACCEL if input.move != Vector2.ZERO else FRICTION
	_walk = _walk.move_toward(target, rate * delta)
	velocity = _walk + _knock
	move_and_slide()
	_knock = _knock.move_toward(Vector2.ZERO, 2400.0 * delta)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_shoot(delta)
	if input.bomb and bombs > 0:
		place_bomb()
	if input.use:
		use_active()
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
	_cooldown += stats.fire_interval() / (1.6 if boost > 0.0 else 1.0)
	fire(input.shoot)


## Fires along [param aim] (one of the four axes): one shot, or three in a
## fan with the fork. Returns the middle one.
func fire(aim: Vector2) -> Shot:
	var side := aim.orthogonal() * (7.0 if _hand == 0 else -7.0)
	_hand = 1 - _hand
	var angles: Array[float] = [0.0]
	if stats.has("triple"):
		angles = [0.0, -0.17, 0.17]
	var middle: Shot = null
	for angle in angles:
		var shot := Shot.new()
		room.actors.add_child(shot)
		shot.launch(room, global_position + aim * 18.0 + side, SHOT_HEIGHT,
				aim.rotated(angle) * stats.shot_px() + _walk * CARRY, stats.range_px(), stats.damage,
				stats.shot_radius(), false)
		shot.homing = stats.has("homing")
		shot.pierce = stats.has("pierce")
		shot.spectral = stats.has("spectral")
		shot.knockback = stats.knockback
		if middle == null:
			middle = shot
	look.recoil(aim)
	shots_fired += 1
	Sfx.play("shot", -9.0)
	return middle


## Drops a lit bomb at his feet.
func place_bomb() -> Bomb:
	bombs -= 1
	inventory_changed.emit()
	Sfx.play("fuse", -8.0)
	var bomb := Bomb.new()
	bomb.room = room
	room.actors.add_child(bomb)
	bomb.global_position = global_position + Vector2(0, 6)
	return bomb


## Takes an item: its numbers go into his stats at once. One for his hands
## goes there, charged, and the one he had before is left on the floor.
func take_item(id: String) -> void:
	var item: Dictionary = GameData.items().get(id, {})
	if item.has("active"):
		var old := active
		active = id
		charge = int(item["active"])
		if old != "" and room != null:
			var left := Pickup.new()
			left.kind = "item"
			left.item = old
			left.room = room
			# Not picked straight back up by whoever is standing there.
			left.wait_clear = true
			room.actors.add_child(left)
			left.global_position = global_position + Vector2(0, -10)
		active_changed.emit()
		inventory_changed.emit()
		item_taken.emit(id)
		return
	var old_max := stats.max_hp()
	stats.apply(item)
	items.append(id)
	if stats.max_hp() > old_max:
		hp = mini(hp + stats.max_hp() - old_max, stats.max_hp())
	health_changed.emit(hp, stats.max_hp())
	inventory_changed.emit()
	item_taken.emit(id)


## Rooms of charge the item in his hands needs; 0 with none.
func max_charge() -> int:
	if active == "":
		return 0
	return int(GameData.items().get(active, {}).get("active", 1))


func is_charged() -> bool:
	return active != "" and charge >= max_charge()


## One more beaten room towards the item in his hands.
func add_charge(rooms := 1) -> void:
	if active == "" or charge >= max_charge():
		return
	charge = mini(charge + rooms, max_charge())
	if charge >= max_charge():
		Sfx.play("pickup", -6.0, 0.0)
	active_changed.emit()


## Uses the item in his hands if it is charged.
func use_active() -> bool:
	if not is_charged() or dead:
		return false
	if not ActiveItems.use(self, active):
		return false
	charge = 0
	active_changed.emit()
	return true


## Contact damage, the way it is in Isaac: touching an enemy hurts, and
## nothing pushes the brother and the enemy apart. Not a dazed one.
func _touch_enemies() -> void:
	if _invulnerable > 0.0:
		return
	for enemy in room.enemies:
		if enemy.can_touch() and not enemy.is_dazed() and global_position.distance_to(enemy.global_position) \
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
	Sfx.play("hurt", -2.0)
	if god:
		return true
	hp = maxi(hp - amount, 0)
	damage_taken += amount
	health_changed.emit(hp, stats.max_hp())
	if hp == 0:
		_die()
	return true


## Stops dead: no walk, no slide, no knockback left over.
func stop() -> void:
	_walk = Vector2.ZERO
	_knock = Vector2.ZERO
	velocity = Vector2.ZERO


## One more heart for good, and filled.
func add_heart() -> void:
	stats.hearts += 1
	hp = mini(hp + 2, stats.max_hp())
	health_changed.emit(hp, stats.max_hp())


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
	Sfx.play("sad", 0.0, 0.0)
	died.emit()


## Up again with [param amount] half hearts, blinking a while so that
## whatever knocked him down cannot do it again at once.
func revive(amount := 2) -> void:
	if not dead:
		return
	dead = false
	look.knocked = false
	hp = clampi(amount, 1, stats.max_hp())
	_invulnerable = INVULNERABLE * 2.0
	stop()
	health_changed.emit(hp, stats.max_hp())
	Sfx.play("whistle_up", -4.0, 0.0)
	revived.emit()


## What the brothers carry between them.
class Purse:
	extends RefCounted
	var coins := 0
	var bombs := 1
	var keys := 0


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
	if boost > 0.0 and int(boost * 4.0) != int((boost + get_physics_process_delta_time()) * 4.0):
		# Bubbles off him while the soda fizzes.
		Fx.burst(room, global_position + Vector2(0, -90), "steam", 2, 0.4)


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
