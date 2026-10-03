class_name GhostEnemy
extends Enemy
## Привидение of the catacombs: a sheet with nobody in it, two black holes
## for eyes and a mouth going "ooo", little arms held out in front. It
## drifts at you through rocks and all; then it fades away -- while it is
## gone nothing touches it -- turns up again a few steps from you, hangs
## there a moment (the warning), and swoops.

const SHEET := Color("e9eef0")

## "drift", "fade", "gone", "appear" or "swoop".
var state := "drift"
var _t := 0.0
var _drift_for := 2.8
var _swoop := Vector2.ZERO
var _bob := 0.0


func setup(kind_: String, room_: Room, rng_: RandomNumberGenerator) -> void:
	super.setup(kind_, room_, rng_)
	_drift_for = rng.randf_range(2.2, 3.4)
	_bob = rng.randf() * TAU


func _switch(to: String) -> void:
	state = to
	_t = 0.0


func can_touch() -> bool:
	return super.can_touch() and state in ["drift", "swoop"]


func can_be_hit() -> bool:
	return super.can_be_hit() and state in ["drift", "swoop", "appear"]


func think(delta: float) -> Vector2:
	_t += delta
	var t := target()
	match state:
		"fade":
			if _t > 0.45:
				_switch("gone")
			return Vector2.ZERO
		"gone":
			if _t > 1.0 and t != null:
				_reappear(t)
			return Vector2.ZERO
		"appear":
			if t != null:
				_swoop = (t.global_position - global_position).normalized()
			if _t > 0.5:
				_switch("swoop")
				Sfx.play("whistle_down", -12.0, 0.2)
			return Vector2.ZERO
		"swoop":
			if _t > 0.5:
				_switch("drift")
				_drift_for = rng.randf_range(2.2, 3.4) - floor_look * 0.3
			return _swoop * speed * 3.6
	if t == null:
		return Vector2.ZERO
	if _t > _drift_for:
		_switch("fade")
		Sfx.play("poof", -16.0, 0.3)
		return Vector2.ZERO
	return (t.global_position - global_position).normalized() * speed


## Somewhere a few steps from the brother, on the floor, and in view.
func _reappear(t: Brother) -> void:
	var floor_rect := room.floor_rect().grow(-60.0)
	var best := global_position
	for i in 8:
		var at := t.global_position + Vector2.from_angle(rng.randf() * TAU) * 260.0
		if floor_rect.has_point(at):
			best = at
			break
	global_position = best.clamp(floor_rect.position, floor_rect.end)
	_switch("appear")


func _process(delta: float) -> void:
	super._process(delta)
	var alpha := 0.88
	match state:
		"fade":
			alpha = 0.88 * (1.0 - clampf(_t / 0.45, 0.0, 1.0))
		"gone":
			alpha = 0.0
		"appear":
			alpha = 0.88 * clampf(_t / 0.3, 0.0, 1.0)
	if dead:
		alpha = 0.88
	modulate.a = alpha


func lift() -> float:
	return 26.0 + sin(_clock * 3.0 + _bob) * 8.0


func draw_body(boil: int, flash: bool) -> void:
	var sheet := paint(SHEET, flash)
	var at := Vector2(0, -44)
	var lean := 0.0
	if state == "swoop":
		lean = signf(_swoop.x) * 8.0
	# The sheet: a dome, falling to a wavy hem that flutters.
	var outline := PackedVector2Array()
	for k in 13:
		var a := PI + PI * k / 12.0
		outline.append(at + Vector2(cos(a) * 26.0 + lean * 0.5, sin(a) * 30.0))
	var hem := 4
	for k in hem * 4 + 1:
		var u := 1.0 - float(k) / (hem * 4)
		var x := -30.0 + 60.0 * (1.0 - u)
		var wave := sin(u * PI * hem * 2.0 + _clock * 8.0) * 5.0
		outline.append(at + Vector2(x * -1.0 - lean, 34.0 + wave + absf(x) * 0.12))
	Toon.shape(self, Toon.grown(outline, 0.0), sheet, 4.5)
	Toon.spot(self, at + Vector2(-12, -14), Vector2(6, 9), Color(1, 1, 1, 0.55), boil, _seed)
	Toon.spot(self, at + Vector2(10, 22), Vector2(14, 6), Color(0.6, 0.7, 0.75, 0.3), boil, _seed + 1)
	# Little arms out in front, the sleeves hanging.
	for sx: float in [-1.0, 1.0]:
		var hand := at + Vector2(sx * 30.0 + lean, 6.0 + sin(_clock * 4.0 + sx) * 3.0)
		Toon.hose(self, at + Vector2(sx * 18.0, -2.0), hand, -sx * 5.0, 9.0, Toon.INK)
		Toon.hose(self, at + Vector2(sx * 18.0, -2.0), hand, -sx * 5.0, 5.0, sheet)
		Toon.blob(self, hand, Vector2(6, 5), sheet, boil, _seed + 2 + int(sx), 3.0)
	# Hollow eyes with a glint in them, and the "ooo".
	var look := gaze()
	for sx: float in [-1.0, 1.0]:
		var e := at + Vector2(sx * 9.0 + lean * 0.3, -6.0)
		if eyes_shut():
			eye(e, Vector2(6, 8), look, boil, _seed + 4 + int(sx), 3.0)
		else:
			Toon.blob(self, e, Vector2(6.0, 8.5), Toon.INK, boil, _seed + 4 + int(sx), 0.0)
			Toon.spot(self, e + look * 2.0 + Vector2(-1.5, -2.5), Vector2(2.0, 2.4), Color(1, 1, 1, 0.9))
	var oo := 1.3 if state in ["appear", "swoop"] else 1.0
	Toon.blob(self, at + Vector2(lean * 0.3, 13.0), Vector2(5.0, 6.5) * oo, Toon.INK, boil, _seed + 6, 0.0)
