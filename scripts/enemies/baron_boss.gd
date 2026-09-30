class_name BaronBoss
extends Boss
## Барон Когтев, the head of the gang and boss of the catacombs: a fat
## tabby cat in a purple tailcoat, top hat, monocle and spats, a cane in his
## glove and a gold tooth in his grin. A showman, so every trick is a
## performance with a flourish before it:
##   1  flicks a fan of playing cards at you; pulls things out of his hat --
##      a lit bomb lobbed your way, or a pair of flies
##   2  vanishes in a puff and turns up somewhere else; throws his money
##      about (sacks that fall where their shadows are, and burst into coins)
##   3  furious: sweeps the room with a confetti cannon, and vanishes more;
##      spins a ring of cards round himself and lets it fly, a gap in it
## His look goes as he loses: the monocle cracks in phase 2, and in phase 3
## his hat has a hole shot through it and his fur stands on end.

const FUR := Color("d9913f")
const FUR_DARK := Color("a2622a")
const MUZZLE := Color("f4dfc0")
const COAT := Color("5b3a7a")
const COAT_DARK := Color("3f2757")
const GOLD := Color("e8b83a")
const CONFETTI := [Color("d8412f"), Color("e8b83a"), Color("3f78c0"), Color("5f9a45"), Color("f7f0e1")]

var _sweep_from := 0.0
var _next_shot := 0.0
var _hidden := false


func setup_boss(room_: Room, rng_: RandomNumberGenerator, floor_index_: int) -> void:
	setup("baron", room_, rng_)
	title = "Барон Когтев"
	subtitle = "главарь банды"
	floor_index = floor_index_
	# Made for the third floor.
	max_hp *= 1.0 + 0.4 * maxi(floor_index - 2, 0)
	hp = max_hp
	contact = 1 if floor_index < 2 else 2
	_spawn = 0.0


func can_touch() -> bool:
	return not dead and state != "wait" and not _hidden


func can_be_hit() -> bool:
	return not dead and state != "wait" and not _hidden


func _physics_process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(_flash - delta, 0.0)
	_squash = maxf(_squash - delta, 0.0)
	if state == "wait":
		return
	_t += delta
	var t := target()
	if t != null:
		_aim = (t.global_position - global_position).normalized()
	var now := 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
	if now != phase and state in ["walk", "recover"]:
		phase = now
		phase_changed.emit(phase)
		Sfx.play("roar", 0.0, 0.0)
		Fx.flash(Color(1, 0.9, 0.5), 0.15)
		Fx.shake(0.25)
		Fx.burst(room, global_position + Vector2(0, -120), "confetti", 30, 1.4)
		_go("roar")
		return
	velocity = Vector2.ZERO
	match state:
		"walk":
			# He strolls, rather than chases: round the brother, at a distance.
			if t != null:
				var to := t.global_position - global_position
				var side := to.orthogonal().normalized()
				var closer := 1.0 if to.length() > 420.0 else -0.6
				velocity = (to.normalized() * closer + side * 0.8).normalized() * speed
			if _t > _walk_for:
				_choose()
		"cards_windup":
			if _t > 0.5:
				_cards()
				_go("recover")
		"hat_windup":
			if _t > 0.7:
				_hat_trick()
				_go("recover")
		"bags_windup":
			if _t > 0.6:
				_money_rain()
				_go("recover")
		"cardrain_windup":
			if _t > 0.6:
				_card_rain()
				_go("recover")
		"ring_windup":
			if _t > 0.9:
				_card_ring()
				_go("recover")
		"vanish":
			if _t > 0.2 and not _hidden:
				_hidden = true
			if _t > 0.9:
				_reappear()
				_go("recover")
		"sweep_windup":
			if _t > 0.6:
				_sweep_from = _aim.angle() - 1.1
				_next_shot = 0.0
				_go("sweep")
		"sweep":
			_next_shot -= delta
			if _next_shot <= 0.0:
				_next_shot = 0.06
				var k := minf(_t / 1.6, 1.0)
				var angle := _sweep_from + 2.2 * k
				var shot := _shoot(Vector2.from_angle(angle), 470.0, 10.0, 11.0, 60.0,
						CONFETTI[rng.randi() % CONFETTI.size()])
				shot.look = ""
			if _t > 1.6:
				_go("recover")
		"recover":
			if _t > 0.6:
				_go("walk")
		"roar":
			if _t > 0.8:
				_go("walk")
	move_and_slide()


func _choose() -> void:
	var options: Array[String] = []
	match phase:
		1:
			options = ["cards", "cards", "hat"]
		2:
			options = ["cards", "hat", "bags", "vanish", "ring"]
		_:
			options = ["sweep", "sweep", "vanish", "hat", "cardrain", "ring"]
	var pick := options[rng.randi() % options.size()]
	if pick == "vanish":
		Fx.burst(room, global_position + Vector2(0, -100), "confetti", 16, 1.0)
		var puff := Puff.new()
		puff.radius = radius * 1.2
		room.effects.add_child(puff)
		puff.global_position = global_position
		Sfx.play("poof", 0.0, 0.0)
		_go("vanish")
	else:
		_go(pick + "_windup")


func _cards() -> void:
	var n := 5 if phase == 1 else 7
	for i in n:
		var spread := (i - (n - 1) * 0.5) * 0.16
		var shot := _shoot(_aim.rotated(spread), 500.0, 10.0, 15.0, 70.0, BrotherLook.WHITE)
		shot.look = "card"
	Sfx.play("select", 0.0, 0.2)
	Sfx.play("spit", -6.0)


## The ring of cards he has been spinning round himself flies outward, all
## at once, but for a gap of four on a random side.
func _card_ring() -> void:
	var n := 22
	var gap := rng.randi() % n
	for i in n:
		if (i - gap + n) % n < 4:
			continue
		var shot := _shoot(Vector2.from_angle(TAU * i / n + _clock), 320.0, 10.0, 14.0, 70.0, BrotherLook.WHITE)
		shot.look = "card"
	Sfx.play("select", 0.0, 0.2)
	Sfx.play("spit", -4.0)
	Fx.burst(room, global_position + Vector2(0, -100), "confetti", 16, 1.0)


## Kittens out of the hat, two or three, in a burst of confetti.
func _summon() -> void:
	var kittens := 0
	for enemy in room.enemies:
		if enemy is KittenEnemy:
			kittens += 1
	var hat := global_position + Vector2(-40, -40)
	for i in maxi(0, mini(2 + (1 if phase == 3 else 0), 4 - kittens)):
		var kitten := Waves.spawn("kitten", room, rng, hat + Vector2((i - 1) * 60.0, 50.0))
		if kitten != null:
			kitten.max_hp *= 1.0 + 0.3 * maxi(floor_index - 2, 0)
			kitten.hp = kitten.max_hp
	Fx.burst(room, hat + Vector2(0, -60), "confetti", 20, 1.0)


## A shower of playing cards from above, each falling where its shadow is.
func _card_rain() -> void:
	var floor_box := room.floor_rect().grow(-60.0)
	var t := target()
	for i in 10:
		var at := Vector2(rng.randf_range(floor_box.position.x, floor_box.end.x),
				rng.randf_range(floor_box.position.y, floor_box.end.y))
		if i % 3 == 0 and t != null:
			at = t.global_position + Vector2(rng.randf_range(-40, 40), rng.randf_range(-30, 30))
		var card := Falling.new()
		card.room = room
		card.look = "card"
		card.delay = i * 0.1
		room.effects.add_child(card)
		card.global_position = at
	Sfx.play("select", 0.0, 0.3)


## Out of the hat: a lit bomb lobbed at the brother, or kittens.
func _hat_trick() -> void:
	var t := target()
	if t == null or rng.randf() < 0.35:
		_summon()
		Sfx.play("poof", -4.0)
		return
	for i in (1 if phase == 1 else 2):
		var bomb := Bomb.new()
		bomb.room = room
		bomb.thrower = self
		bomb.source = title
		bomb.flight = 0.7
		bomb.fuse = 1.0
		bomb.from = global_position + Vector2(0, -150)
		var land := t.global_position + Vector2(rng.randf_range(-90, 90), rng.randf_range(-60, 60)) * i
		var inside := room.floor_rect().grow(-40.0)
		bomb.to = Vector2(clampf(land.x, inside.position.x, inside.end.x),
				clampf(land.y, inside.position.y, inside.end.y))
		room.actors.add_child(bomb)
	Sfx.play("whistle_up", -4.0)


func _money_rain() -> void:
	var n := 4 + phase
	var floor_box := room.floor_rect().grow(-60.0)
	var t := target()
	for i in n:
		var at := Vector2(rng.randf_range(floor_box.position.x, floor_box.end.x),
				rng.randf_range(floor_box.position.y, floor_box.end.y))
		if i == 0 and t != null:
			at = t.global_position
		var bag := Falling.new()
		bag.room = room
		bag.look = "bag"
		bag.delay = i * 0.16
		room.effects.add_child(bag)
		bag.global_position = at
	Sfx.play("coin", -2.0)


## Back out of thin air, somewhere across the room from the brother.
func _reappear() -> void:
	var t := target()
	var best := global_position
	var best_d := -1.0
	for i in 12:
		var cell := Vector2i(rng.randi_range(1, Room.COLS - 2), rng.randi_range(1, Room.ROWS - 2))
		if room.is_rock(cell):
			continue
		var at := room.tile_center(cell)
		var d := at.distance_to(t.global_position) if t != null else 0.0
		if d > best_d:
			best_d = d
			best = at
	global_position = best
	_hidden = false
	var puff := Puff.new()
	puff.radius = radius * 1.2
	room.effects.add_child(puff)
	puff.global_position = global_position
	Sfx.play("poof", 0.0, 0.0)


func _shown() -> bool:
	return not _hidden


func _shadow_size() -> Vector2:
	return Vector2(74, 20)


func _height_of_head() -> float:
	return 170.0


func _pose(boil: int) -> Array:
	var squash := 0.0
	match state:
		"cards_windup", "hat_windup", "bags_windup", "sweep_windup", "cardrain_windup", "ring_windup":
			squash = 0.08
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
		"vanish":
			squash = -0.3
		"wait":
			# A bow to the audience.
			squash = 0.06 if (boil / 3) % 2 == 0 else 0.0
	if _squash > 0.0:
		squash = 0.14
	return [Vector2.ZERO, 0.0, Vector2(1.0 + squash, 1.0 - squash)]


func _figure(boil: int, flash: bool) -> void:
	_draw_baron(boil, flash)


## The ring of cards he spins up before letting it fly: round him on the
## floor, drawn over him where it passes in front.
func _over(boil: int) -> void:
	super._over(boil)
	if state != "ring_windup":
		return
	var n := 12
	var k := minf(_t / 0.9, 1.0)
	for i in n:
		var a := TAU * i / n + _clock * 5.0
		var at := Vector2(cos(a) * 110.0 * (0.4 + 0.6 * k), -90.0 + sin(a) * 40.0 * (0.4 + 0.6 * k))
		Toon.box(self, at, Vector2(8, 11), BrotherLook.WHITE, boil, i, 2.5, a)
		Toon.heart(self, at, 8.0, 2, Color("c8392b"), Color("c8392b"))


func _draw_baron(boil: int, flash: bool) -> void:
	var angry := phase == 3 and _ko < 0.0
	var fur := paint(FUR.lerp(Color("c8452c"), 0.3) if angry else FUR, flash)
	var dark := paint(FUR_DARK, flash)
	var coat := paint(COAT, flash)
	var white := paint(BrotherLook.WHITE, flash)
	var ink := Toon.INK
	# Legs in black trousers, and spats.
	var step := 0.0
	if state == "walk" and _ko < 0.0:
		step = [1.0, 0.0, -1.0, 0.0][boil % 4]
	for sx: float in [-1.0, 1.0]:
		var foot := Vector2(sx * 26.0, -(8.0 if step * sx > 0.0 else 0.0))
		Toon.hose(self, Vector2(sx * 18.0, -46.0), foot + Vector2(0, -8), sx * 4.0, 15.0)
		Toon.blob(self, foot + Vector2(sx * 5.0, -4.0), Vector2(22, 11), ink, boil, 2 + int(sx), 4.0)
		Toon.blob(self, foot + Vector2(sx * 2.0, -9.0), Vector2(13, 7), white, boil, 4 + int(sx), 3.0)
	# Coat tails behind.
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([Vector2(sx * 20, -70), Vector2(sx * 52, -60),
				Vector2(sx * 46, -18), Vector2(sx * 30, -30)]), paint(COAT_DARK, flash), 4.0)
	# The body: a round belly in a tailcoat over a white shirt front.
	var body := Vector2(0, -92)
	Toon.pear(self, body, Vector2(56, 50), 0.25, coat, boil, 6)
	Toon.shade(self, body, Vector2(56, 50), coat, boil, 6, Toon.LINE, 0.25, 0.0, 0.25)
	Toon.shape(self, PackedVector2Array([body + Vector2(-20, -44), body + Vector2(20, -44),
			body + Vector2(0, 36)]), white, 3.0)
	for k in 3:
		Toon.spot(self, body + Vector2(0, -20 + k * 16), Vector2(3.5, 3.5), ink)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([body + Vector2(0, -44), body + Vector2(sx * 20, -54),
				body + Vector2(sx * 20, -36)]), paint(Color("c8392b"), flash), 3.0)
	# Arms: the cane in his right, the left free for tricks.
	var cane_hand := Vector2(74, -60)
	var free_hand := Vector2(-74, -70)
	match state:
		"cards_windup":
			free_hand = Vector2(-60, -150)
		"hat_windup":
			free_hand = Vector2(-20, -235)
		"bags_windup", "cardrain_windup":
			free_hand = Vector2(-90, -170)
			cane_hand = Vector2(90, -170)
		"sweep_windup", "sweep":
			free_hand = Vector2(-30, -80) + _aim * 50.0
			cane_hand = Vector2(30, -80) + _aim * 50.0
		"ring_windup":
			# Twirling the cane over his head.
			cane_hand = Vector2(40, -220)
			free_hand = Vector2(-80, -120)
		"wait":
			# Hat raised to the audience.
			free_hand = Vector2(-40, -250)
	if _ko >= 0.0:
		free_hand = Vector2(-90, -200) if _ko < SHAKE_TIME else Vector2(-80, -20)
		cane_hand = Vector2(90, -200) if _ko < SHAKE_TIME else Vector2(84, -24)
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := Vector2(sx * 44.0, -120.0)
		var hand: Vector2 = free_hand if i == 0 else cane_hand
		Toon.hose(self, shoulder, hand + (shoulder - hand).normalized() * 14.0, sx * -10.0, 11.0)
	# The cane, knob up -- spinning like a baton while he winds up the ring.
	var cane_turn := _clock * 14.0 if state == "ring_windup" else 0.0
	var cane_a := cane_hand + Vector2(4, -30).rotated(cane_turn)
	var cane_b := cane_hand + Vector2(10, 60).rotated(cane_turn)
	Toon.stroke(self, PackedVector2Array([cane_a, cane_b]), 7.0)
	Toon.blob(self, cane_a + (cane_a - cane_b).normalized() * 4.0, Vector2(8, 8), paint(GOLD, flash), boil, 8, 3.0)
	if state == "cards_windup":
		# A fan of cards in his free hand: what is coming.
		var count := 5 if phase == 1 else 7
		for i in count:
			var a := -PI * 0.5 + (i - (count - 1) * 0.5) * 0.22
			var at := free_hand + Vector2(cos(a), sin(a)) * 26.0
			Toon.box(self, at, Vector2(9, 13), BrotherLook.WHITE, boil, 30 + i, 2.5, a + PI * 0.5)
			Toon.spot(self, at, Vector2(3, 3), Color("c8392b"))
	for hand: Vector2 in [free_hand, cane_hand]:
		Toon.ball(self, hand, Vector2(15, 14), white, boil, 9 + int(hand.x), 4.0, 0.0, 0.14)
	if state == "sweep_windup" or state == "sweep":
		# The confetti cannon: a striped barrel held in both hands.
		var mouth := Vector2(0, -80) + _aim * 110.0
		Toon.box(self, Vector2(0, -80) + _aim * 70.0, Vector2(40, 16), paint(Color("d8412f"), flash), boil, 10, 4.0,
				_aim.angle())
		Toon.blob(self, mouth, Vector2(12, 18), ink, boil, 11, 3.0, _aim.angle())
	# Head: a fat tabby with a smug look.
	var head := Vector2(0, -168)
	for sx: float in [-1.0, 1.0]:
		var ear := PackedVector2Array([head + Vector2(sx * 50, -2), head + Vector2(sx * 18, -34),
				head + Vector2(sx * 50, -58 + (14.0 if angry else 0.0))])
		Toon.shape(self, ear, fur, 5.0)
	Toon.ball(self, head, Vector2(54, 44), fur, boil, 12)
	if angry:
		# Fur on end: tufts all round the head.
		for k in 9:
			var a := PI * 0.1 + PI * 0.8 * k / 8.0
			var root := head + Vector2(cos(a + PI) * 50.0, sin(a + PI) * 40.0)
			var tip := head + Vector2(cos(a + PI) * 64.0, sin(a + PI) * 54.0)
			Toon.shape(self, PackedVector2Array([root + (tip - root).orthogonal().normalized() * 6.0, tip,
					root - (tip - root).orthogonal().normalized() * 6.0]), fur, 3.0)
	for k in 3:
		Toon.stroke(self, Toon.bent(head + Vector2(-14 + k * 14, -44), head + Vector2(-12 + k * 12, -28), 3.0),
				5.0, dark)
	Toon.blob(self, head + Vector2(0, 16), Vector2(34, 22), paint(MUZZLE, flash), boil, 13, 4.0)
	# Whiskers.
	for sx: float in [-1.0, 1.0]:
		for k in 3:
			Toon.stroke(self, PackedVector2Array([head + Vector2(sx * 22, 12 + k * 6),
					head + Vector2(sx * 62, 4 + k * 10)]), 2.2)
	Toon.blob(self, head + Vector2(0, 4), Vector2(10, 7), paint(Color("c86a6a"), flash), boil, 14, 3.0)
	# The grin, one gold tooth in it.
	var grin := PackedVector2Array()
	for k in 9:
		var u := k / 8.0
		grin.append(head + Vector2(-24 + 48 * u, 20 + sin(u * PI) * 12.0))
	Toon.stroke(self, grin, 4.0)
	Toon.box(self, head + Vector2(8, 27), Vector2(4.5, 5), paint(GOLD, flash), boil, 15, 2.0)
	# Eyes: half shut, pleased with himself; the monocle over the right.
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var e := head + Vector2(sx * 20.0, -14.0)
		eye(e, Vector2(10, 12), look, boil, 16 + int(sx), 3.0)
		if eyes_shut():
			continue
		var lid := PackedVector2Array()
		for k in 9:
			var a := PI + PI * k / 8.0
			lid.append(e + Vector2(cos(a) * 12.0, sin(a) * 14.0 + (4.0 if not angry else -2.0)))
		draw_colored_polygon(lid, fur)
		Toon.stroke(self, PackedVector2Array([lid[0], lid[lid.size() - 1]]), 3.5)
	# The monocle: on its chain, cracked from phase 2, dangling when he is
	# out.
	var monocle := head + Vector2(20.0, -14.0)
	if _ko >= SHAKE_TIME:
		monocle = head + Vector2(40.0, 36.0)
	Toon.spot(self, monocle, Vector2(13, 13), Color(0.8, 0.9, 1.0, 0.2))
	Toon.stroke(self, _ring(monocle, 15.0), 4.0, paint(GOLD, flash))
	if phase >= 2:
		Toon.stroke(self, PackedVector2Array([monocle + Vector2(-9, -10), monocle + Vector2(-1, -2),
				monocle + Vector2(-4, 4), monocle + Vector2(8, 11)]), 1.6, Color(1, 1, 1, 0.8))
	Toon.stroke(self, Toon.bent(monocle + Vector2(12, 10), head + Vector2(46, 40), -10.0), 2.0, paint(GOLD, flash))
	# The top hat: in his hand for the hat trick, on his head otherwise.
	var hat := head + Vector2(6, -58)
	var tilt := -0.15
	if state == "hat_windup":
		hat = free_hand + Vector2(0, -42)
		tilt = PI
	elif state == "wait":
		hat = free_hand + Vector2(0, -30)
		tilt = -0.4
	if _ko >= SHAKE_TIME:
		hat = head + Vector2(-40, -105)
		tilt = -1.0
	Toon.box(self, hat + Vector2(0, 30).rotated(tilt), Vector2(46, 8), ink, boil, 18, 3.0, tilt)
	Toon.box(self, hat, Vector2(30, 34), ink, boil, 19, 3.0, tilt)
	Toon.box(self, hat + Vector2(0, 20).rotated(tilt), Vector2(31, 6), paint(Color("c8392b"), flash), boil, 20, 0.0, tilt)
	Toon.stroke(self, PackedVector2Array([hat + Vector2(-20, -28).rotated(tilt), hat + Vector2(-20, 14).rotated(tilt)]),
			3.0, Color(1, 1, 1, 0.22))
	if phase >= 3:
		# A hole shot clean through it, light showing.
		var hole := hat + Vector2(10, -8).rotated(tilt)
		Toon.blob(self, hole, Vector2(6, 5), Color("f3e6c8"), boil, 21, 2.5)
		for k in 5:
			var a := TAU * k / 5.0
			Toon.stroke(self, PackedVector2Array([hole + Vector2(cos(a), sin(a)) * 6.0,
					hole + Vector2(cos(a), sin(a)) * 10.0]), 2.0, Color("3a3438"))


static func _ring(center: Vector2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in 25:
		var a := TAU * k / 24.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points
