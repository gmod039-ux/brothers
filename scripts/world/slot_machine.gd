class_name SlotMachine
extends Node2D
## «Однорукий бандит»: a cast-iron slot machine of the arcades, a gilt
## crest on top, three reels behind glass and a lever with a red knob. A
## brother who steps up to it with a coin drops it in: the lever goes down,
## the reels spin and stop one by one, and the tray pays out --
##   three alike      five coins, a heart and a half, two bombs, two keys,
##                    or for three stars an item
##   two alike        one of that (two coins for coins; a chest for stars)
##   nothing alike    nothing, and a raspberry
## It stands on its tile like a rock and pays out in front of it.

signal paid(what: String)
## Three alike.
signal jackpot

const SYMBOLS := ["coin", "heart", "bomb", "key", "star"]
const WEIGHTS := [32, 20, 18, 18, 12]
const SPIN := 1.4
## The reels stop this long apart.
const STAGGER := 0.32
const REACH := 96.0
const IRON := Color("3a3438")
const GOLD := Color("d9a838")

var room: Room
var rng: RandomNumberGenerator
var spins := 0

var _reels: Array[int] = [0, 1, 4]
var _spinning := -1.0
var _result: Array[int] = []
var _clock := 0.0
var _flash := 0.0
var _ready_for := ""


func _ready() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	if _spinning >= 0.0:
		_spinning += delta
		for i in 3:
			if _spinning >= SPIN + i * STAGGER and _reels[i] != _result[i]:
				_reels[i] = _result[i]
				Sfx.play("hit", -10.0, 0.0)
		if _spinning >= SPIN + 2 * STAGGER + 0.2:
			_spinning = -1.0
			_pay()
		return
	# A brother at the front with a coin: in it goes. Only once each time
	# he steps up.
	var front := global_position + Vector2(0, 70)
	var here := ""
	for brother in room.brothers:
		if not brother.dead and brother.global_position.distance_to(front) < REACH:
			here = brother.name
			if _ready_for != here and brother.coins > 0:
				brother.coins -= 1
				brother.inventory_changed.emit()
				pull()
			break
	_ready_for = here


## Pulls the lever: the reels go round and stop on what fate says.
func pull() -> void:
	spins += 1
	_result = [_roll(), _roll(), _roll()]
	_spinning = 0.0
	Sfx.play("coin", -2.0, 0.0)
	Sfx.play("whistle_up", -12.0, 0.1)


func _roll() -> int:
	var total := 0
	for w: int in WEIGHTS:
		total += w
	var pick := rng.randi() % total
	for i in WEIGHTS.size():
		pick -= WEIGHTS[i]
		if pick < 0:
			return i
	return 0


## What the reels came to, out of the tray.
func _pay() -> void:
	var counts := {}
	for r: int in _reels:
		counts[r] = int(counts.get(r, 0)) + 1
	var best := -1
	for r: int in counts:
		if best < 0 or int(counts[r]) > int(counts[best]):
			best = r
	var many := int(counts[best])
	var out: Array = []
	if many == 3:
		match SYMBOLS[best]:
			"coin":
				out = ["coin", "coin", "coin", "coin", "coin"]
			"heart":
				out = ["heart", "half_heart"]
			"bomb":
				out = ["bomb", "bomb"]
			"key":
				out = ["key", "key"]
			"star":
				out = ["item"]
	elif many == 2:
		match SYMBOLS[best]:
			"coin":
				out = ["coin", "coin"]
			"heart":
				out = ["half_heart"]
			"star":
				out = ["chest"]
			_:
				out = [SYMBOLS[best]]
	if out.is_empty():
		Sfx.play("nope", -4.0, 0.0)
		paid.emit("")
		return
	_flash = 0.8 if many == 3 else 0.35
	if many == 3:
		jackpot.emit()
	Sfx.play("clear" if many == 3 else "pickup", -2.0, 0.0)
	Fx.burst(room, global_position + Vector2(0, -150), "stars" if many == 3 else "sparks", 8, 0.9)
	for i in out.size():
		var kind: String = out[i]
		var item := ""
		if kind == "item":
			item = room.run.draw_item() if room.run != null else ""
			if item == "":
				kind = "chest"
		var a := PI * 0.5 + (i - (out.size() - 1) * 0.5) * 0.45
		var at := global_position + Vector2(cos(a) * 90.0, 70.0 + sin(a) * 50.0)
		var thing := Pickup.new()
		thing.kind = kind
		thing.item = item
		thing.room = room
		room.actors.add_child(thing)
		thing.global_position = at
		thing.wait_clear = kind == "item"
	paid.emit(out[0])


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var d := int(_clock * Toon.FPS)
	Toon.spot(self, Vector2(0, 40), Vector2(70, 16), Color(0, 0, 0, 0.35))
	# The cabinet: a cast-iron box on a pedestal, rounded crest on top.
	Toon.box(self, Vector2(0, 24), Vector2(54, 18), IRON.lightened(0.05), 0, 1, 5.0)
	Toon.box(self, Vector2(0, -60), Vector2(62, 70), IRON, 0, 2, 5.0)
	draw_rect(Rect2(40, -124, 18, 128), IRON.darkened(0.3))
	Toon.ball(self, Vector2(0, -138), Vector2(56, 30), GOLD, 0, 3, 5.0)
	draw_string(Ui.font(), Vector2(-50, -130), "ДЖЕКПОТ", HORIZONTAL_ALIGNMENT_CENTER, 100, 18, Toon.INK)
	# Lights round the crest, chasing while it spins or pays.
	var busy := _spinning >= 0.0 or _flash > 0.0
	for i in 7:
		var a := PI + PI * (i + 0.5) / 7.0
		var on := busy and (i + d) % 2 == 0
		Toon.blob(self, Vector2(cos(a) * 58.0, -134.0 + sin(a) * 34.0), Vector2(5, 5),
				Color("fff1a8") if on else Color("8a6a2a"), 0, 10 + i, 2.0)
	# The window and its three reels.
	var window := Rect2(-48, -96, 96, 46)
	draw_rect(window.grow(6), GOLD)
	draw_rect(window.grow(3), Toon.INK)
	for i in 3:
		var cell := Rect2(window.position + Vector2(i * 32 + 1, 0), Vector2(30, 46))
		draw_rect(cell, Color("f4ead2"))
		var showing := _reels[i]
		var blur := _spinning >= 0.0 and _spinning < SPIN + i * STAGGER
		if blur:
			showing = (d + i * 2) % SYMBOLS.size()
		_symbol(SYMBOLS[showing], cell.get_center() + (Vector2(0, (d % 2) * 8.0 - 4.0) if blur else Vector2.ZERO), d)
		if blur:
			for k in 3:
				draw_line(cell.position + Vector2(3, 8 + k * 14), cell.position + Vector2(27, 8 + k * 14), Color(0, 0, 0, 0.2), 2.0)
	draw_rect(Rect2(window.position + Vector2(0, 2), Vector2(window.size.x, 6)), Color(1, 1, 1, 0.3))
	if _flash > 0.0 and d % 2 == 0:
		draw_rect(window.grow(10), Color(1, 0.95, 0.6, 0.4), false, 6.0)
	# The coin slot, the tray, and a plate with the odds.
	Toon.box(self, Vector2(0, -32), Vector2(16, 4), Toon.INK, 0, 20, 2.0)
	Toon.box(self, Vector2(0, 2), Vector2(34, 10), GOLD.darkened(0.2), 0, 21, 3.0)
	draw_rect(Rect2(-26, -2, 52, 6), Toon.INK)
	# The lever, down while it spins.
	var pulled := _spinning >= 0.0 and _spinning < 0.4
	var top := Vector2(84, -40 if pulled else -118)
	Toon.box(self, Vector2(66, -54), Vector2(8, 16), GOLD, 0, 22, 3.0)
	Toon.stroke(self, PackedVector2Array([Vector2(70, -54), top]), 9.0)
	Toon.stroke(self, PackedVector2Array([Vector2(70, -54), top]), 4.0, Color("c9c6c0"))
	Toon.ball(self, top, Vector2(13, 13), Color("c8392b"), 0, 23, 4.0)


## One reel's picture.
func _symbol(id: String, at: Vector2, _d: int) -> void:
	match id:
		"heart":
			Toon.heart(self, at, 20.0, 2, Color("d8412f"), Color("4a2c22"))
		"star":
			Toon.star(self, at, 12.0, 0.0, Color("e0b23a"))
		_:
			ItemIcon.draw(self, id, at, 26.0, 0)
