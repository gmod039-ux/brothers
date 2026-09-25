class_name Fx
extends RefCounted
## Special effects, in the same ink as everything else: bursts of little
## bits (dust, sparks, embers, confetti, sweat, steam), shockwave rings,
## flashes of the whole screen and shakes of the camera. Called from
## anywhere; the screen-wide ones need Main to have hooked them up, and are
## quietly nothing in the checks.

## Set by Main: flash(color, seconds) and shake(seconds).
static var on_flash: Callable
static var on_shake: Callable


static func flash(color: Color, seconds := 0.15) -> void:
	if on_flash.is_valid():
		on_flash.call(color, seconds)


static func shake(seconds := 0.25) -> void:
	if on_shake.is_valid():
		on_shake.call(seconds)


## A burst of [param count] bits of [param kind] from [param at]:
## "dust", "sparks", "embers", "confetti", "sweat", "steam", "stars".
static func burst(room: Room, at: Vector2, kind: String, count := 8, power := 1.0) -> Bits:
	if room == null or room.effects == null:
		return null
	var bits := Bits.new()
	bits.kind = kind
	bits.count = count
	bits.power = power
	room.effects.add_child(bits)
	bits.global_position = at
	return bits


## A ring along the floor, growing to [param radius] over [param seconds].
static func ring(room: Room, at: Vector2, radius: float, color := Toon.INK, seconds := 0.45,
		width := 10.0) -> void:
	if room == null or room.effects == null:
		return
	var r := Ring.new()
	r.radius = radius
	r.color = color
	r.seconds = seconds
	r.width = width
	room.decals.add_child(r)
	r.global_position = at


## Little bits flying out and falling: each a toon shape with its own
## speed, spin and life.
class Bits:
	extends Node2D

	var kind := "dust"
	var count := 8
	var power := 1.0
	var _bits: Array = []
	var _clock := 0.0

	func _ready() -> void:
		for i in count:
			var a := randf() * TAU
			var speed := randf_range(80.0, 260.0) * power
			var up := randf_range(120.0, 320.0) * power
			var life := randf_range(0.35, 0.8)
			match kind:
				"steam", "dust":
					up = randf_range(20.0, 90.0)
					speed *= 0.6
					life += 0.3
				"embers":
					up = randf_range(160.0, 380.0) * power
				"stars":
					life = randf_range(0.4, 0.6)
			# [floor position, floor velocity, height, vertical speed, life, size, spin]
			_bits.append([Vector2.ZERO, Vector2(cos(a), sin(a) * 0.6) * speed, 0.0, up, life,
					randf_range(0.7, 1.3), randf_range(-8.0, 8.0), randi() % 5])

	func _process(delta: float) -> void:
		_clock += delta
		var alive := false
		for bit: Array in _bits:
			if _clock > float(bit[4]):
				continue
			alive = true
			bit[0] = (bit[0] as Vector2) + (bit[1] as Vector2) * delta
			bit[1] = (bit[1] as Vector2) * (1.0 - 2.0 * delta)
			var falls := kind in ["sparks", "confetti", "sweat", "embers", "stars"]
			bit[3] = float(bit[3]) - (900.0 if falls else -40.0) * delta
			bit[2] = maxf(float(bit[2]) + float(bit[3]) * delta, 0.0)
		if not alive:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var d := int(_clock * Toon.FPS)
		for bit: Array in _bits:
			var life := float(bit[4])
			if _clock > life:
				continue
			var t := _clock / life
			var at: Vector2 = (bit[0] as Vector2) + Vector2(0, -float(bit[2]))
			var s: float = bit[5]
			var spin := float(bit[6]) * _clock
			match kind:
				"dust":
					# Puffs swell, then shrink away rather than fade: ink does
					# not go see-through.
					Toon.blob(self, at, Vector2(16, 13) * s * (0.6 + t) * (1.0 - t * t), Color("d9cdb8"), d,
							int(s * 10), 3.0)
				"steam":
					Toon.spot(self, at + Vector2(0, -30 * t), Vector2(18, 15) * s * (0.5 + t),
							Color(0.96, 0.95, 0.92, 0.8 * (1.0 - t)), d, int(s * 10))
				"sparks":
					Toon.star(self, at, 7.0 * s * (1.0 - t * 0.6), spin, Color("fff1a8"))
				"stars":
					Toon.star(self, at, 10.0 * s * (1.0 - t * 0.5), spin, Color("f2c14e"))
				"embers":
					Toon.blob(self, at, Vector2(6, 6) * s * (1.0 - t * 0.5), Color("f08a24").lerp(Color("5a2a14"), t), d,
							int(s * 10), 2.0)
				"confetti":
					var colors := [Color("d8412f"), Color("e8b83a"), Color("3f78c0"), Color("5f9a45"), Color("f7f0e1")]
					Toon.box(self, at, Vector2(6, 3.5) * s, colors[int(bit[7])], d, int(s * 10), 1.5, spin)
				"sweat":
					Toon.blob(self, at, Vector2(5, 8) * s, Color("9fd0e8"), d, int(s * 10), 2.5)


## A shockwave: an ellipse on the floor growing out and thinning away.
class Ring:
	extends Node2D

	var radius := 200.0
	var color := Toon.INK
	var seconds := 0.45
	var width := 10.0
	var _clock := 0.0

	func _process(delta: float) -> void:
		_clock += delta
		if _clock >= seconds:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := _clock / seconds
		var r := radius * sqrt(t)
		var points := PackedVector2Array()
		for k in 41:
			var a := TAU * k / 40.0
			points.append(Vector2(cos(a) * r, sin(a) * r * 0.5))
		draw_polyline(points, Color(color, 1.0 - t), width * (1.0 - t * 0.7), true)
