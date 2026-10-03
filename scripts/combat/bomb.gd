class_name Bomb
extends Node2D
## A lit bomb: sits fizzing for a moment, swells and flashes red, then goes
## off -- hurting every enemy near it, the brothers too if they did not get
## clear, and blowing up any rocks in reach.

signal exploded(at: Vector2)

const FUSE := 1.6
const REACH := 160.0
const DAMAGE := 25.0

var room: Room
## Seconds from landing to the bang.
var fuse := FUSE
## A thrown bomb flies from [member from] to its own position over this many
## seconds before the fuse starts; 0 for one simply put down.
var flight := 0.0
var from := Vector2.ZERO
## Where a thrown bomb lands.
var to := Vector2.ZERO
## Whoever threw it is not hurt by it.
var thrower: Enemy
## His name, kept apart: he may be gone by the time it goes off.
var source := ""
## How far it reaches and how hard it hits: a stick of dynamite more.
var reach := REACH
var damage := DAMAGE
## Spares the brothers: theirs, not a boss's, and thrown well clear.
var friendly := false

var _clock := 0.0
var _air := 0.0
var _to := Vector2.ZERO
var _done := false


func _ready() -> void:
	if flight > 0.0:
		_to = to
		global_position = from


func _physics_process(delta: float) -> void:
	if _air < flight:
		_air += delta
		var k := minf(_air / flight, 1.0)
		global_position = from.lerp(_to, k)
		if k >= 1.0:
			Sfx.play("hit", -8.0)
		return
	_clock += delta
	if _done or _clock < fuse:
		return
	_done = true
	_explode()


func _explode() -> void:
	var at := global_position
	for enemy in room.enemies.duplicate():
		if enemy != thrower and enemy.can_be_hit() and enemy.global_position.distance_to(at) < reach + enemy.radius * 0.5:
			enemy.hurt(damage, (enemy.global_position - at).normalized(), 2.0)
	for brother in room.brothers:
		if not friendly and not brother.dead and not brother.stats.has("helmet") \
				and brother.global_position.distance_to(at) < reach * 0.8:
			brother.hurt(2, at, source if source != "" else "своя же бомба")
	for row in Room.ROWS:
		for col in Room.COLS:
			var cell := Vector2i(col, row)
			if room.is_rock(cell) and room.tile_center(cell).distance_to(at) < reach + 30.0:
				room.blow(cell)
	room.blast(at, reach)
	Sfx.play("blast", 0.0)
	if friendly:
		Fx.shake(0.3)
	var blast := Blast.new()
	blast.radius = reach
	room.effects.add_child(blast)
	blast.global_position = at
	exploded.emit(at)
	queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var drawing := int((_clock + _air) * Toon.FPS)
	var left := 1.0 - _clock / fuse
	if _air < flight:
		# In the air: an arc over the floor, its shadow underneath.
		var k := _air / flight
		var up := sin(k * PI) * 160.0
		Toon.spot(self, Vector2(0, 2), Vector2(20, 7), Color(Toon.INK, 0.25))
		draw_set_transform(Vector2(0, -up), k * 8.0, Vector2.ONE)
		if friendly:
			_stick(drawing, 1.0)
		else:
			Toon.blob(self, Vector2(0, -22), Vector2(24, 22), Toon.INK, drawing, 3, 3.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if friendly:
		Toon.spot(self, Vector2(0, 2), Vector2(26, 8), Color(Toon.INK, 0.3))
		_stick(drawing, 1.0 + (0.08 if drawing % 2 == 0 else 0.0))
		return
	# Swells as the fuse burns down, and flashes red in the last half second.
	var swell := 1.0 + (1.0 - left) * 0.25 + (0.06 if drawing % 2 == 0 else 0.0)
	var hot := left < 0.33 and drawing % 2 == 0
	Toon.spot(self, Vector2(0, 2), Vector2(24, 8), Color(Toon.INK, 0.3))
	Toon.blob(self, Vector2(0, -22), Vector2(24, 22) * swell, Color("b8322a") if hot else Toon.INK, drawing, 3, 3.5)
	Toon.spot(self, Vector2(-9, -30) * swell, Vector2(5, 8), Color(1, 1, 1, 0.45))
	var fuse_end := Vector2(14, -48) * swell + Vector2(0, 10) * (1.0 - left)
	Toon.stroke(self, Toon.bent(Vector2(8, -42) * swell, fuse_end, 4.0), 3.5, ItemIcon.BROWN)
	Toon.star(self, fuse_end, 8.0 + (drawing % 2) * 3.0, drawing * 0.9, ItemIcon.GOLD)


## A stick of dynamite on its side, fuse sparking at one end.
func _stick(drawing: int, swell: float) -> void:
	draw_set_transform(Vector2(0, -16), -0.3, Vector2(swell, swell))
	Toon.box(self, Vector2.ZERO, Vector2(30, 11), Color("c8392b"), drawing, 5, 4.0)
	draw_rect(Rect2(-12, -11, 6, 22), Color("e8dcc0"))
	draw_rect(Rect2(8, -11, 6, 22), Color("e8dcc0"))
	Toon.stroke(self, Toon.bent(Vector2(30, -2), Vector2(44, -16), 5.0), 3.0, ItemIcon.BROWN)
	Toon.star(self, Vector2(45, -18), 7.0 + (drawing % 2) * 3.0, drawing * 0.9, ItemIcon.GOLD)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The explosion itself: a flash, a ring of smoke, stars, and the word for
## it, all in a few drawings.
class Blast:
	extends Node2D

	var radius := 160.0
	var _clock := 0.0

	func _process(delta: float) -> void:
		_clock += delta
		if _clock * Toon.FPS >= 7.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var d := int(_clock * Toon.FPS)
		var t := d / 7.0
		if d < 2:
			Toon.blob(self, Vector2(0, -20), Vector2(radius, radius * 0.7) * (0.6 + 0.2 * d), Color("fff1a8"), d, 1, 6.0)
		for i in 9:
			var a := TAU * i / 9.0
			var at := Vector2(cos(a), sin(a) * 0.65) * radius * (0.45 + 0.55 * t) + Vector2(0, -20)
			var r := radius * 0.28 * (1.0 - t * 0.7)
			Toon.blob(self, at, Vector2(r, r * 0.85), Color("d9cdb8").lerp(Color("6d6360"), t), d, 10 + i, 4.0)
		for i in 5:
			var a := TAU * i / 5.0 + 0.4
			Toon.star(self, Vector2(cos(a), sin(a) * 0.7) * radius * (0.3 + 0.9 * t) + Vector2(0, -30),
					14.0 * (1.0 - t * 0.5), a + d, ItemIcon.GOLD)
		if d >= 1 and d <= 5:
			draw_string(Ui.font(), Vector2(-120, -radius * 0.55), "БАХ!", HORIZONTAL_ALIGNMENT_CENTER, 240,
					72, Toon.INK)
