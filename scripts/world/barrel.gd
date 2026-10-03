class_name Barrel
extends Node2D
## A keg of gunpowder with a skull on it: solid as a rock, until a few
## shots (anyone's) or a blast set it off -- and then it goes up like a
## bomb, hurting everyone near, breaking the rocks round it and setting off
## the next keg along. Each hit leaves it cracked and smoking worse.
##
## Its look follows the floor: a plain keg in the basement, a sooty one in
## the boiler room, a pale one hung with cobweb in the catacombs.

const HITS := 3
const REACH := 150.0
const DAMAGE := 20.0
## A keg set off by another goes a moment later: a chain, not one bang.
const CHAIN_DELAY := 0.14

var room: Room
var cell := Vector2i.ZERO
var style := 0
var hits := 0
var lit := false

var _flash := 0.0
var _clock := 0.0
var _wobble := 0.0


func _process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	_wobble = maxf(_wobble - delta, 0.0)
	if hits > 0 or _flash > 0.0 or _wobble > 0.0:
		queue_redraw()


## A shot hit it.
func hit() -> void:
	if lit:
		return
	hits += 1
	_flash = 1.0 / Toon.FPS
	_wobble = 0.25
	Sfx.play("hit", -8.0, 0.2)
	if hits >= HITS:
		detonate(0.0)
	queue_redraw()


## Goes off after [param delay] seconds.
func detonate(delay: float) -> void:
	if lit:
		return
	lit = true
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(room):
		return
	room.barrel_gone(cell)
	var bang := Bomb.new()
	bang.room = room
	bang.fuse = 0.0
	bang.reach = REACH
	bang.damage = DAMAGE
	bang.source = "бочка с порохом"
	bang.visible = false
	room.effects.add_child(bang)
	bang.global_position = global_position
	Fx.burst(room, global_position + Vector2(0, -30), "embers", 10, 1.2)
	queue_free()


func _draw() -> void:
	var boil := int(_clock * Toon.FPS)
	var shake := Vector2.ZERO
	if _wobble > 0.0:
		shake = Vector2(sin(_clock * 60.0) * 4.0 * _wobble / 0.25, 0)
	var flash := _flash > 0.0
	var wood: Color = [Color("9a6234"), Color("6f4a32"), Color("a89878")][clampi(style, 0, 2)]
	if flash:
		wood = Toon.WHITE
	Toon.spot(self, Vector2(0, 30), Vector2(40, 12), Color(0, 0, 0, 0.3))
	draw_set_transform(shake, 0.0, Vector2.ONE)
	# The keg: bulging staves, two iron hoops, a lid seen from a bit above.
	var keg := PackedVector2Array([Vector2(-31, -34), Vector2(31, -34), Vector2(37, -14), Vector2(37, 6), Vector2(31, 26),
			Vector2(-31, 26), Vector2(-37, 6), Vector2(-37, -14)])
	Toon.shape(self, keg, wood, Toon.LINE)
	for k in 4:
		var x := -21.0 + k * 14.0
		draw_line(Vector2(x, -32), Vector2(x * 1.08, 24), Color(0, 0, 0, 0.3), 2.0)
	Toon.shade(self, Vector2(0, -4), Vector2(34, 28), wood, boil, 3, 0.0, 0.18)
	for y: float in [-24.0, 16.0]:
		draw_rect(Rect2(-37, y - 4, 74, 8), Toon.INK)
		draw_rect(Rect2(-35, y - 2, 70, 4), Color("5d5c64"))
	# The label: a skull and crossbones on a red band.
	draw_rect(Rect2(-24, -16, 48, 26), Toon.INK)
	draw_rect(Rect2(-22, -14, 44, 22), Color("b8322a") if not flash else Toon.WHITE)
	var skull := Vector2(0, -4)
	for d: float in [-1.0, 1.0]:
		draw_line(skull + Vector2(-10, -7 * d), skull + Vector2(10, 7 * d), Color("efe6cf"), 3.0)
	Toon.blob(self, skull + Vector2(0, -1), Vector2(6.5, 6), Color("efe6cf"), 0, 1, 2.0)
	for sx: float in [-1.0, 1.0]:
		draw_circle(skull + Vector2(sx * 2.5, -1.5), 1.6, Toon.INK)
	# The lid.
	Toon.ball(self, Vector2(0, -34), Vector2(31, 9), wood.lightened(0.08), 0, 2, 4.0)
	draw_line(Vector2(-18, -36), Vector2(18, -33), Color(0, 0, 0, 0.3), 2.0)
	if style == 2:
		# Cobweb over a corner.
		for k in 4:
			var a := PI * 0.5 + PI * 0.5 * k / 3.0
			draw_line(Vector2(36, -34), Vector2(36, -34) + Vector2(cos(a), sin(a)) * 22.0, Color(1, 1, 1, 0.5), 1.0)
		draw_arc(Vector2(36, -34), 12.0, PI * 0.5, PI, 6, Color(1, 1, 1, 0.5), 1.0)
	# Cracks for each hit taken, and smoke from them.
	if hits >= 1:
		Toon.stroke(self, PackedVector2Array([Vector2(-30, -8), Vector2(-22, -2), Vector2(-26, 8)]), 2.5)
	if hits >= 2:
		Toon.stroke(self, PackedVector2Array([Vector2(28, -20), Vector2(20, -12), Vector2(26, 0), Vector2(20, 10)]), 2.5)
		for k in 2:
			var rise := fmod(_clock * 0.9 + k * 0.5, 1.0)
			Toon.spot(self, Vector2(-26 + k * 50 + sin(_clock * 3.0 + k) * 6.0, -40 - rise * 50.0),
					Vector2(9, 8) * (0.6 + rise), Color(0.7, 0.7, 0.7, 0.6 * (1.0 - rise)), boil, k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
