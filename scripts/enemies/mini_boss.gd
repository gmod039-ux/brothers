class_name MiniBoss
extends Boss
## What the mini-bosses share. On most floors one waits in a fight room: the
## floor boss's right hand. Like a boss it gets a title card (a short one),
## the health bar at the bottom, a roar into its second phase at half
## health, and the long knockout with the stars; unlike one, it guards no
## trapdoor -- it leaves a gold chest and some coins.
##
## A kind says how it fights in [method _fight] (setting [member velocity]
## and moving from state to state), which of its states a roar may cut
## into in [method _calm_states], and how it looks in [method _figure].

## Seconds of title card before it starts.
const INTRO := 1.2


## How many [param kind] are about in its room: minions are never let
## pile up.
func minions(kind: String) -> int:
	var n := 0
	for enemy in room.enemies:
		if enemy.kind == kind and not enemy.dead:
			n += 1
	return n


## Where the health bar marks the phases.
func phase_marks() -> Array[float]:
	return [0.5]


## The phase it should be in by now.
func _phase_now() -> int:
	return 2 if hp <= max_hp * 0.5 else 1


## States a change of phase may break into: not the middle of an attack.
func _calm_states() -> Array:
	return ["walk", "recover"]


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
	var now := _phase_now()
	if now > phase and state in _calm_states():
		phase = now
		phase_changed.emit(phase)
		Sfx.play("roar", -2.0, 0.0)
		Fx.flash(Color(1, 0.95, 0.85), 0.1)
		Fx.shake(0.25)
		_go("roar")
		return
	velocity = Vector2.ZERO
	if state == "roar":
		if _t > 0.7:
			_go("walk")
	else:
		_fight(delta, t)
	move_and_slide()
	_moved()


## One tick of its fighting, in whatever state it is in.
func _fight(_delta: float, _t_brother: Brother) -> void:
	pass


## After the tick's move: what running into something does.
func _moved() -> void:
	pass


## A minion of [param kind] at [param at], popping in with a puff of dust.
func _call(kind: String, at: Vector2) -> Enemy:
	var floor_box := room.floor_rect().grow(-50.0)
	var spot := at.clamp(floor_box.position, floor_box.end)
	var minion := Waves.spawn(kind, room, rng, spot)
	Fx.burst(room, spot, "dust", 4, 0.6)
	return minion
