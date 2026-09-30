class_name ActiveItems
extends RefCounted
## What the items in a brother's hands do (Space, or RB on a gamepad). Each
## charges up room by room -- as many beaten rooms as its "active" number in
## data/items.json -- and empties when used, as in Isaac:
##   camera    a magnesium flash: everyone in the room blinded a moment and
##             singed
##   dynamite  a stick lobbed ahead that blows up bigger than a bomb, and
##             spares the brothers
##   soda      fizz: faster feet and a quicker hand for a few seconds
##   watch     time stands still for the enemies, and their spit drops
##   sandwich  a whole heart, for him or, if he is whole, for his brother
##   hat       three odds and ends out of a magician's topper: coins, a
##             bomb, a key, a heart

const EFFECTS := ["camera", "dynamite", "soda", "watch", "sandwich", "hat"]
## What comes out of the hat, a pick each time: coins most often.
const HAT_ODDS := ["coin", "coin", "coin", "coin", "bomb", "key", "half_heart", "heart"]
const FLASH_DAMAGE := 8.0
const FLASH_DAZE := 2.5
const WATCH_DAZE := 4.0
## Bosses are big: they get over it quicker.
const BOSS_DAZE := 0.4
const SODA_TIME := 7.0
const DYNAMITE_THROW := 280.0


## Uses [param id] for [param brother]. False if it did nothing (nothing
## is lost then).
static func use(brother: Brother, id: String) -> bool:
	var room := brother.room
	if room == null:
		return false
	match id:
		"camera":
			Fx.flash(Color(1, 1, 1), 0.35)
			Sfx.play("stars", 0.0, 0.0)
			Sfx.play("hit", -2.0, 0.0)
			for enemy in room.enemies.duplicate():
				if not is_instance_valid(enemy) or not enemy.can_be_hit():
					continue
				var boss := enemy is Boss
				enemy.daze(FLASH_DAZE * (BOSS_DAZE if boss else 1.0))
				enemy.hurt(FLASH_DAMAGE, (enemy.global_position - brother.global_position).normalized(), 0.3)
			return true
		"dynamite":
			var bomb := Bomb.new()
			bomb.room = room
			bomb.friendly = true
			bomb.reach = Bomb.REACH * 1.45
			bomb.damage = Bomb.DAMAGE * 1.6
			bomb.fuse = 0.55
			bomb.flight = 0.35
			bomb.from = brother.global_position + Vector2(0, -20)
			var ahead := brother.look.facing if brother.look.facing != Vector2.ZERO else Vector2.DOWN
			var floor_rect := room.floor_rect().grow(-40.0)
			var to := brother.global_position + ahead * DYNAMITE_THROW
			bomb.to = Vector2(clampf(to.x, floor_rect.position.x, floor_rect.end.x),
					clampf(to.y, floor_rect.position.y, floor_rect.end.y))
			room.actors.add_child(bomb)
			Sfx.play("fuse", -4.0)
			Sfx.play("whistle_up", -10.0, 0.1)
			return true
		"soda":
			brother.boost = SODA_TIME
			Sfx.play("whistle_up", -4.0, 0.0)
			Fx.burst(room, brother.global_position + Vector2(0, -70), "steam", 12, 1.0)
			return true
		"watch":
			Fx.flash(Color(0.95, 0.85, 0.55), 0.3)
			Sfx.play("stars", -2.0, 0.0)
			Sfx.play("whistle_down", -8.0, 0.0)
			for enemy in room.enemies:
				if is_instance_valid(enemy) and not enemy.dead:
					enemy.daze(WATCH_DAZE * (BOSS_DAZE if enemy is Boss else 1.0))
			for node in room.actors.get_children():
				var shot := node as Shot
				if shot != null and shot.hostile:
					shot.pop()
			return true
		"sandwich":
			var fed := brother
			if brother.hp >= brother.stats.max_hp():
				# Whole already: the other half goes to his brother.
				fed = null
				for other in room.brothers:
					if other != brother and not other.dead and other.hp < other.stats.max_hp():
						fed = other
			if fed == null:
				return false
			fed.heal(2)
			Sfx.play("heart", 0.0, 0.0)
			Fx.burst(room, fed.global_position + Vector2(0, -70), "confetti", 8, 0.6)
			return true
		"hat":
			if room.run == null:
				return false
			var here := room.tile_at(brother.global_position)
			var tiles := room.free_tiles()
			tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return Vector2(a - here).length() < Vector2(b - here).length())
			# The tiles round him, not the one he stands on.
			tiles.erase(here)
			for i in mini(3, tiles.size()):
				var at := room.tile_center(tiles[i])
				room.run.drop(HAT_ODDS[room.run.rng.randi() % HAT_ODDS.size()], at)
				Fx.burst(room, at, "stars", 5, 0.6)
			Fx.burst(room, brother.global_position + Vector2(0, -90), "confetti", 10, 0.8)
			Sfx.play("item", -4.0, 0.0)
			return true
	return false
