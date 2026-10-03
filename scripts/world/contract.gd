class_name Contract
extends Node2D
## The Baron's notary, after a boss is beaten: a black cat in a waistcoat
## and sleeve garters at a little desk, a contract on it with a quill and a
## pot of red ink. His wares are on the floor in front -- items that cost
## not coins but a heart, for good. "Подпишите здесь!"

const VEST := Color("8f1f22")

var _clock := 0.0
var _words := "Подпишите здесь!"
var _say_for := 3.0


func say(words: String, seconds := 1.8) -> void:
	_words = words
	_say_for = seconds


func _process(delta: float) -> void:
	_clock += delta
	_say_for = maxf(_say_for - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var d := int(_clock * Toon.FPS)
	var tail_wave := sin(_clock * 3.0) * 8.0
	# The cat: behind the desk, so drawn first.
	var body := Vector2(-30, -64)
	Toon.hose(self, body + Vector2(-30, 30), body + Vector2(-64 + tail_wave, -40), 16.0, 10.0)
	Toon.pear(self, body, Vector2(30, 34), 0.2, Color("231e22"), d, 1)
	Toon.shape(self, PackedVector2Array([body + Vector2(-18, -24), body + Vector2(18, -24), body + Vector2(22, 20),
			body + Vector2(-22, 20)]), VEST, 3.0)
	for k in 3:
		Toon.spot(self, body + Vector2(0, -14 + k * 11), Vector2(2.5, 2.5), Color("e0b23a"))
	var head := body + Vector2(0, -50)
	for sx: float in [-1.0, 1.0]:
		Toon.shape(self, PackedVector2Array([head + Vector2(sx * 24, -6), head + Vector2(sx * 10, -26),
				head + Vector2(sx * 26, -32)]), Color("231e22"), 3.5)
	Toon.ball(self, head, Vector2(28, 24), Color("231e22"), d, 2)
	Toon.union(self, [[head + Vector2(0, 8), Vector2(16, 10)], [head + Vector2(-8, -2), Vector2(9, 9)],
			[head + Vector2(8, -2), Vector2(9, 9)]], BrotherLook.WHITE, d, 3, 2.5)
	for sx: float in [-1.0, 1.0]:
		Toon.pie_eye(self, head + Vector2(sx * 8, -3), Vector2(5.5, 7.5), Vector2(0.4, 0.6), d, 4 + int(sx), 2.5)
		for k in 2:
			Toon.stroke(self, PackedVector2Array([head + Vector2(sx * 14, 8 + k * 4), head + Vector2(sx * 34, 4 + k * 8)]), 1.6)
	Toon.spot(self, head + Vector2(0, 5), Vector2(3.5, 2.5), Color("c86a6a"))
	Toon.stroke(self, Toon.bent(head + Vector2(-8, 11), head + Vector2(8, 11), -4.0), 2.5)
	# A green eyeshade, as clerks wear.
	Toon.shape(self, PackedVector2Array([head + Vector2(-26, -14), head + Vector2(26, -14), head + Vector2(30, -6),
			head + Vector2(-30, -6)]), Color("4f8a5a"), 3.0)
	# The desk, the contract, the quill in its ink.
	var desk := Rect2(-80, -40, 160, 40)
	Toon.shape(self, PackedVector2Array([desk.position, Vector2(desk.end.x, desk.position.y), desk.end + Vector2(-8, 0),
			Vector2(desk.position.x + 8, desk.end.y)]), Color("6b3a24"), 4.0)
	for x: float in [-66.0, 58.0]:
		draw_rect(Rect2(x, 0, 8, 30), Toon.INK)
	var paper := PackedVector2Array([Vector2(-34, -56), Vector2(30, -60), Vector2(36, -38), Vector2(-30, -34)])
	Toon.shape(self, paper, Color("f4ead2"), 3.0)
	for k in 3:
		draw_line(Vector2(-26, -50 + k * 5), Vector2(20, -53 + k * 5), Color(0, 0, 0, 0.4), 1.5)
	Toon.spot(self, Vector2(18, -42), Vector2(6, 4), Color("c8392b"))
	Toon.blob(self, Vector2(52, -48), Vector2(10, 9), Toon.INK, d, 8, 2.5)
	var quill := Vector2(56, -54)
	Toon.shape(self, PackedVector2Array([quill, quill + Vector2(20, -46), quill + Vector2(8, -40)]), BrotherLook.WHITE, 2.0)
	# The cat's hand on the paper, tapping where to sign.
	var tap := 3.0 if (d / 3) % 2 == 0 else 0.0
	Toon.hose(self, body + Vector2(20, -10), Vector2(-4, -48 - tap), -8.0, 7.0)
	Toon.ball(self, Vector2(-4, -50 - tap), Vector2(8, 7), BrotherLook.WHITE, d, 9, 2.5)
	if _say_for > 0.0:
		var font := Ui.font()
		var at := Vector2(-30, -200)
		var width := font.get_string_size(_words, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 50.0
		Toon.shape(self, PackedVector2Array([at + Vector2(-10, 20), at + Vector2(10, 20), at + Vector2(0, 50)]), Toon.PAPER, 3.0)
		Toon.blob(self, at, Vector2(width * 0.5, 30), Toon.PAPER, d, 11, 4.0)
		draw_string(font, at + Vector2(-width * 0.5, 10), _words, HORIZONTAL_ALIGNMENT_CENTER, width, 28, Toon.INK)
