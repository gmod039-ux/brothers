class_name Shopkeeper
extends Node2D
## The man behind the counter in a shop: an old walrus in a fez with a
## magnificent moustache, nodding along. He sells by the price tags, but
## has a word for it: thanks for a sale, a shake of the head for someone
## short of coins.

const FEZ := Color("b8322a")
const SKIN := Color("a8968a")
const WOOD := Color("8a5a36")

var _clock := 0.0
## What he is saying, and for how long more.
var _words := ""
var _say_for := 0.0
## Seconds left of shaking his head.
var _shake := 0.0


func say(words: String, seconds := 1.6, shake_head := false) -> void:
	_words = words
	_say_for = seconds
	if shake_head:
		_shake = 0.5


func _process(delta: float) -> void:
	_clock += delta
	_say_for = maxf(_say_for - delta, 0.0)
	_shake = maxf(_shake - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var d := int(_clock * Toon.FPS)
	var nod: float = [0.0, 2.0, 3.0, 2.0][(d / 3) % 4]
	var head := Vector2(sin(_shake * 40.0) * 6.0 * _shake / 0.5, -118 + nod)
	# Him, behind the counter.
	Toon.blob(self, Vector2(0, -70 + nod * 0.5), Vector2(46, 36), Color("3d4a78"), d, 1)
	Toon.blob(self, head, Vector2(44, 38), SKIN, d, 2)
	for sx: float in [-1.0, 1.0]:
		Toon.pie_eye(self, head + Vector2(sx * 13, -12), Vector2(8, 11), Vector2(0, 0.5), d, 3 + int(sx), 3.0)
	Toon.blob(self, head + Vector2(0, 4), Vector2(11, 8), Toon.INK, d, 6, 3.0)
	# The moustache: two big white sweeps and the tusks under them.
	for sx: float in [-1.0, 1.0]:
		Toon.blob(self, head + Vector2(sx * 17, 16), Vector2(20, 11), BrotherLook.WHITE, d, 7 + int(sx), 4.0, sx * 0.3)
		Toon.shape(self, PackedVector2Array([head + Vector2(sx * 8, 22), head + Vector2(sx * 16, 22),
				head + Vector2(sx * 12, 46)]), BrotherLook.WHITE, 3.0)
	Toon.box(self, head + Vector2(6, -40), Vector2(20, 15), FEZ, d, 10, 4.0, 0.1)
	Toon.stroke(self, Toon.bent(head + Vector2(10, -54), head + Vector2(30, -40), -6.0), 3.0)
	Toon.blob(self, head + Vector2(30, -38), Vector2(4, 5), Color("e0b23a"), d, 11, 2.5)
	# The counter across the front.
	Toon.box(self, Vector2(0, -30), Vector2(150, 30), WOOD, 0, 12, 5.0)
	for x: float in [-100.0, -50.0, 0.0, 50.0, 100.0]:
		Toon.stroke(self, PackedVector2Array([Vector2(x, -52), Vector2(x, -8)]), 2.5, Color(0, 0, 0, 0.35))
	Toon.box(self, Vector2(0, -60), Vector2(158, 6), WOOD.lightened(0.2), 0, 13, 4.0)
	if _say_for > 0.0:
		_bubble(head + Vector2(110, -70), d)


## A speech bubble up to the right of his head, its tail to his mouth.
func _bubble(at: Vector2, d: int) -> void:
	var font := Ui.font()
	var size := 30
	var width := font.get_string_size(_words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 44.0
	var center := at + Vector2(width * 0.5 - 20.0, 0)
	Toon.shape(self, PackedVector2Array([center + Vector2(-width * 0.3, 14), center + Vector2(-width * 0.18, 20),
			at + Vector2(-40, 40)]), BrotherLook.WHITE, 3.5)
	Toon.blob(self, center, Vector2(width * 0.5, 30), BrotherLook.WHITE, d, 20, 3.5)
	draw_string(font, center + Vector2(-width * 0.5, 10), _words, HORIZONTAL_ALIGNMENT_CENTER, width, size, Toon.INK)
