class_name BoneCount
extends MiniBoss
## Граф Костяшкин of the catacombs, the Baron's oldest friend: a tall
## skeleton in an opera cape -- black outside, red inside -- a top hat and
## a red bow at his neck bone. He stalks after you throwing bones, three in
## a fan (five once he is angry); or throws his cape wide and two bats fly
## out of it (never more than three about). Twice he falls to pieces when
## beaten and lies there a moment -- nothing touches him then -- before he
## pulls himself together, the worse for wear and quicker with it; the
## third time he stays down.

const BONE := Color("efe6cf")
const CAPE := Color("1e1a22")
const LINING := Color("a8262c")
## Beaten this many times, he gets up again.
const LIVES := 2
const PILE_TIME := 2.2
const RISE_TIME := 0.6
const MOST_BATS := 3

## Times he has fallen apart so far.
var collapses := 0


func setup_boss(room_: Room, rng_: RandomNumberGenerator, floor_index_: int) -> void:
	setup("bone_count", room_, rng_)
	title = "Граф Костяшкин"
	subtitle = "старый друг Барона"
	floor_index = floor_index_
	hp = max_hp
	contact = 1
	_spawn = 0.0


## No marks: the bar fills part way up again each time he gets up.
func phase_marks() -> Array[float]:
	return []


func _phase_now() -> int:
	return 1 + collapses


func _calm_states() -> Array:
	return ["walk", "recover"]


func can_touch() -> bool:
	return super.can_touch() and not state in ["pile", "rise"]


func can_be_hit() -> bool:
	return super.can_be_hit() and not state in ["pile", "rise"]


func blink_now() -> bool:
	return false


## The blow that would end him the first two times only scatters him.
func hurt(damage: float, direction: Vector2, strength := 1.0) -> void:
	if dead or state in ["pile", "rise"]:
		return
	if collapses < LIVES and hp - damage <= 0.0:
		collapses += 1
		hp = max_hp * 0.4
		_flash = 1.0 / Toon.FPS
		Sfx.play("hit", -4.0, 0.15)
		Sfx.play("poof", -8.0, 0.2)
		Fx.burst(room, global_position + Vector2(0, -60), "dust", 10, 1.0)
		Fx.shake(0.2)
		_go("pile")
		return
	super.hurt(damage, direction, strength)


func _fight(_delta: float, t: Brother) -> void:
	match state:
		"walk":
			if t != null:
				var d := global_position.distance_to(t.global_position)
				velocity = _aim * speed * (1.0 if d > 300.0 else -0.4) * (1.0 + 0.2 * collapses)
			if _t > _walk_for / (1.0 + 0.3 * collapses):
				_choose()
		"throw_windup":
			if _t > 0.5:
				var n := 3 if phase == 1 else 5
				for i in n:
					var shot := _shoot(_aim.rotated((i - (n - 1) * 0.5) * 0.24), 420.0, 8.0, 15.0, 90.0, BONE)
					shot.look = "bone"
				Sfx.play("spit", -6.0, 0.2)
				_go("recover")
		"summon":
			if _t > 0.8:
				for i in mini(2, MOST_BATS - minions("bat")):
					_call("bat", global_position + Vector2(-70.0 + i * 140.0, -40.0))
				Sfx.play("select", -10.0, 0.4)
				_go("recover")
		"pile":
			if _t > PILE_TIME:
				_go("rise")
				Sfx.play("whistle_up", -8.0, 0.1)
		"rise":
			if _t > RISE_TIME:
				_go("walk")
		"recover":
			if _t > 0.5:
				_go("walk")


func _choose() -> void:
	var options := ["throw", "throw", "summon"]
	if minions("bat") >= MOST_BATS:
		options.erase("summon")
	if str(options[rng.randi() % options.size()]) == "summon":
		_go("summon")
		Sfx.play("whistle_down", -10.0, 0.1)
	else:
		_go("throw_windup")


func _shadow_size() -> Vector2:
	return Vector2(54, 16)


func _height_of_head() -> float:
	return 170.0


func _pose(boil: int) -> Array:
	var squash := 0.0
	match state:
		"throw_windup", "summon":
			squash = 0.06
		"roar":
			squash = -0.08 if boil % 2 == 0 else 0.04
		"wait":
			# Tipping his hat.
			squash = 0.05 if (boil / 3) % 2 == 0 else 0.0
	if _squash > 0.0:
		squash = 0.12
	return [Vector2.ZERO, 0.0, Vector2(1.0 + squash, 1.0 - squash)]


func _figure(boil: int, flash: bool) -> void:
	var bone := paint(BONE, flash)
	if state == "pile" or (state == "rise" and _t < RISE_TIME * 0.4):
		_heap(boil, bone)
		return
	var rise := clampf(_t / RISE_TIME, 0.0, 1.0) if state == "rise" else 1.0
	var sink := (1.0 - rise) * 60.0
	var walking := velocity.length() > 20.0 and state == "walk"
	var step := boil % 2 if walking else -1
	var side := -1.0 if _aim.x < 0.0 else 1.0
	var hip := Vector2(0, -64.0 + sink)
	var chest := hip + Vector2(0, -50.0)
	var wide := state == "summon"
	# The cape, behind everything: black, its red lining showing at the
	# edges -- thrown wide open to let the bats out.
	var spread := 80.0 if wide else 40.0
	var cape := PackedVector2Array([chest + Vector2(-26, -22), chest + Vector2(26, -22),
			chest + Vector2(spread, 40), hip + Vector2(spread + 6.0, 60), hip + Vector2(-spread - 6.0, 60),
			chest + Vector2(-spread, 40)])
	Toon.shape(self, cape, paint(LINING, flash), 4.0)
	var outside := PackedVector2Array()
	for p in cape:
		outside.append(p.lerp(chest + Vector2(0, 30), 0.12))
	Toon.polygon(self, outside, paint(CAPE, flash))
	# Legs: long thigh bones, bony feet.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var up := -12.0 if step == i else 0.0
		var foot := Vector2(sx * 20.0, -6.0 + up)
		SkeletonEnemy.draw_bone(self, hip + Vector2(sx * 10.0, 8.0), foot, 9.0, bone, boil, _seed + i * 3)
		Toon.blob(self, foot + Vector2(sx * 9.0, 2.0), Vector2(14.0, 7.0), bone, boil, _seed + 10 + i, 3.0)
	# Pelvis, spine, ribs.
	Toon.blob(self, hip, Vector2(24.0, 12.0), bone, boil, _seed + 12, 4.0)
	Toon.stroke(self, PackedVector2Array([hip, chest + Vector2(0, -20)]), 14.0)
	Toon.stroke(self, PackedVector2Array([hip, chest + Vector2(0, -20)]), 7.0, bone)
	for k in 4:
		var y := chest.y - 12.0 + k * 13.0
		for sx: float in [-1.0, 1.0]:
			var rib := Toon.bent(Vector2(chest.x, y), Vector2(chest.x + sx * (28.0 - k * 3.0), y + 12.0), -sx * 9.0, 6)
			Toon.stroke(self, rib, 10.0)
			Toon.stroke(self, rib, 5.0, bone)
	# Arms: throwing, or up holding the cape open.
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		var shoulder := chest + Vector2(sx * 24.0, -16.0)
		var hand := shoulder + Vector2(sx * 14.0, 48.0 + (10.0 if step == i else 0.0))
		if wide:
			hand = shoulder + Vector2(sx * 60.0, -30.0)
		elif state == "throw_windup" and sx == side:
			hand = shoulder + Vector2(-side * 26.0, -46.0)
		SkeletonEnemy.draw_bone(self, shoulder, hand, 7.0, bone, boil, _seed + 20 + i * 3)
		Toon.blob(self, hand, Vector2(9.0, 9.0), bone, boil, _seed + 26 + i, 3.0)
		if state == "throw_windup" and sx == side:
			SkeletonEnemy.draw_bone(self, hand + Vector2(-14, -10), hand + Vector2(14, 10), 7.0, bone, boil, _seed + 30)
	# A red bow at the neck bone.
	var neck := chest + Vector2(0, -26)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([neck, neck + Vector2(sx * 18.0, -9.0), neck + Vector2(sx * 18.0, 9.0)]),
				paint(LINING, flash), 3.0)
	Toon.blob(self, neck, Vector2(5, 5), paint(LINING.darkened(0.2), flash), boil, _seed + 50, 2.5)
	# The skull, a top hat on it; eyes glowing once he has been beaten.
	var skull := chest + Vector2(0, -58)
	var eyes := "fire" if collapses > 0 else ("shut" if eyes_shut() else "open")
	SkeletonEnemy.draw_skull(self, skull, 1.9, bone, boil, _seed, gaze(), eyes, _clock)
	var lift := 10.0 if state == "wait" and (boil / 3) % 2 == 0 else 0.0
	var hat := skull + Vector2(4, -42 - lift)
	Toon.box(self, hat + Vector2(0, 22), Vector2(40, 7), paint(Toon.INK, flash), boil, _seed + 60, 3.0, -0.12)
	Toon.box(self, hat, Vector2(25, 26), paint(Toon.INK, flash), boil, _seed + 61, 3.0, -0.12)
	Toon.box(self, hat + Vector2(0, 14), Vector2(25, 5), paint(LINING, flash), boil, _seed + 62, 0.0, -0.12)
	Toon.stroke(self, PackedVector2Array([hat + Vector2(-16, -18), hat + Vector2(-16, 10)]), 3.0, Color(1, 1, 1, 0.22))


## Fallen apart: a heap of bones, the cape over it, the skull on top seeing
## stars, the hat rolled off -- and, as he gets up, shaking.
func _heap(boil: int, bone: Color) -> void:
	var shake := 0.0
	if state == "pile" and _t > PILE_TIME - 0.6:
		shake = (Toon.hash01(boil, 3) - 0.5) * 10.0
	Toon.blob(self, Vector2(shake, -14), Vector2(70, 20), CAPE, boil, _seed + 70, 4.0)
	for k in 7:
		var a := Toon.hash01(_seed, k) * PI
		var c := Vector2(-48.0 + k * 16.0 + shake, -18.0 - (k % 2) * 10.0)
		var half := Vector2(cos(a), sin(a) * 0.4) * 22.0
		SkeletonEnemy.draw_bone(self, c - half, c + half, 8.0, bone, boil, _seed + 80 + k)
	SkeletonEnemy.draw_skull(self, Vector2(10.0 + shake, -56.0), 1.7, bone, boil, _seed, Vector2.ZERO, "dazed", _clock)
	Toon.box(self, Vector2(-70, -12), Vector2(22, 20), Toon.INK, boil, _seed + 61, 3.0, 1.2)
