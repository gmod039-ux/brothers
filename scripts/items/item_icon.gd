class_name ItemIcon
extends RefCounted
## Pictures of the items and of the small things on the floor (coins, bombs,
## keys), in the same ink as everything else. Each is drawn about
## [param size] pixels across around [param at].

const GOLD := Color("e8b83a")
const RED := Color("d23a2c")
const SILVER := Color("c9c6c0")
const BROWN := Color("7a4a2a")
const GREEN := Color("5f9a45")
const CREAM := Color("f7f0e1")


static func draw(ci: CanvasItem, id: String, at: Vector2, size: float, boil: int) -> void:
	var k := size / 60.0
	match id:
		"pepper":
			Toon.blob(ci, at + Vector2(2, 4) * k, Vector2(24, 11) * k, RED, boil, 1, 4.0, 0.7)
			Toon.spot(ci, at + Vector2(-4, -3) * k, Vector2(9, 3) * k, Color(1, 1, 1, 0.6), 0, 0, 0.7)
			Toon.hose(ci, at + Vector2(-13, -14) * k, at + Vector2(-20, -26) * k, 4.0 * k, 9.0 * k)
			Toon.hose(ci, at + Vector2(-13, -14) * k, at + Vector2(-20, -26) * k, 4.0 * k, 5.0 * k, GREEN)
		"spring":
			var coil := PackedVector2Array()
			for i in 13:
				coil.append(at + Vector2((12.0 if i % 2 == 0 else -12.0) * k, (-22.0 + i * 3.6) * k))
			Toon.stroke(ci, coil, 7.0 * k)
			Toon.stroke(ci, coil, 3.5 * k, SILVER)
			Toon.box(ci, at + Vector2(0, -25) * k, Vector2(16, 4) * k, SILVER, boil, 2, 3.0)
			Toon.box(ci, at + Vector2(0, 25) * k, Vector2(16, 4) * k, SILVER, boil, 3, 3.0)
		"metronome":
			Toon.shape(ci, PackedVector2Array([at + Vector2(0, -28) * k, at + Vector2(20, 24) * k,
					at + Vector2(-20, 24) * k]), BROWN, 4.0)
			Toon.shape(ci, PackedVector2Array([at + Vector2(0, -16) * k, at + Vector2(11, 16) * k,
					at + Vector2(-11, 16) * k]), CREAM, 2.0)
			var swing := (6.0 if boil % 2 == 0 else -6.0) * k
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 16) * k, at + Vector2(swing, -18.0 * k)]), 3.0 * k)
			Toon.blob(ci, at + Vector2(swing * 0.6, -6.0 * k), Vector2(4, 4) * k, SILVER, boil, 4, 2.5)
		"spyglass":
			for i in 3:
				var c := at + Vector2(-16 + i * 14, 10 - i * 8) * k
				Toon.box(ci, c, Vector2(10 - i * 1.5, 7 - i) * k, GOLD if i != 1 else BROWN, boil, 5 + i, 3.5, -0.5)
			Toon.blob(ci, at + Vector2(24, -16) * k, Vector2(6, 8) * k, Color("9fd0e8"), boil, 8, 3.0, -0.5)
		"weight":
			var handle := PackedVector2Array()
			for i in 11:
				var a := PI + PI * i / 10.0
				handle.append(at + Vector2(cos(a) * 13.0, -8.0 + sin(a) * 16.0) * k)
			Toon.stroke(ci, handle, 8.0 * k)
			Toon.blob(ci, at + Vector2(0, 8) * k, Vector2(23, 19) * k, Toon.INK, boil, 9, 3.0)
			Toon.spot(ci, at + Vector2(-8, 0) * k, Vector2(5, 7) * k, Color(1, 1, 1, 0.5))
		"pie":
			Toon.shape(ci, PackedVector2Array([at + Vector2(-24, 16) * k, at + Vector2(24, 16) * k,
					at + Vector2(6, -22) * k]), Color("e3a85a"), 4.0)
			Toon.shape(ci, PackedVector2Array([at + Vector2(-18, 8) * k, at + Vector2(20, 8) * k,
					at + Vector2(5, -14) * k]), RED, 1.0)
			Toon.blob(ci, at + Vector2(4, -20) * k, Vector2(10, 7) * k, CREAM, boil, 10, 3.0)
		"horseshoe":
			var arc := PackedVector2Array()
			for i in 15:
				var a := PI * 0.1 + PI * 1.8 * i / 14.0 + PI * 0.5
				arc.append(at + Vector2(cos(a) * 20.0, -sin(a) * 20.0 + 4.0) * k)
			Toon.stroke(ci, arc, 13.0 * k)
			Toon.stroke(ci, arc, 7.0 * k, SILVER)
		"fork":
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 28) * k, at + Vector2(0, -4) * k]), 8.0 * k)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 28) * k, at + Vector2(0, -4) * k]), 4.0 * k, SILVER)
			Toon.box(ci, at + Vector2(0, -6) * k, Vector2(13, 4) * k, SILVER, boil, 11, 3.0)
			for x: float in [-10.0, 0.0, 10.0]:
				Toon.stroke(ci, PackedVector2Array([at + Vector2(x, -8) * k, at + Vector2(x, -28) * k]), 6.0 * k)
				Toon.stroke(ci, PackedVector2Array([at + Vector2(x, -8) * k, at + Vector2(x, -28) * k]), 2.5 * k, SILVER)
		"magnet":
			var arc := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				arc.append(at + Vector2(cos(a) * 16.0, 4.0 + sin(a) * 16.0) * k)
			arc.insert(0, at + Vector2(16, -18) * k)
			arc.append(at + Vector2(-16, -18) * k)
			Toon.stroke(ci, arc, 15.0 * k)
			Toon.stroke(ci, arc, 9.0 * k, RED)
			Toon.box(ci, at + Vector2(16, -20) * k, Vector2(5.5, 4) * k, SILVER, boil, 12, 2.5)
			Toon.box(ci, at + Vector2(-16, -20) * k, Vector2(5.5, 4) * k, SILVER, boil, 13, 2.5)
		"needle":
			Toon.blob(ci, at, Vector2(28, 4) * k, SILVER, boil, 14, 3.0, -0.8)
			Toon.blob(ci, at + Vector2(-17, 20) * k, Vector2(4, 2) * k, Toon.INK, boil, 15, 0.0, -0.8)
			Toon.stroke(ci, Toon.bent(at + Vector2(-17, 20) * k, at + Vector2(18, 22) * k, 14.0 * k), 2.5 * k, RED)
		"ghost":
			var body := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				body.append(at + Vector2(cos(a) * 20.0, -6.0 + sin(a) * 22.0) * k)
			for i in 7:
				var x := 20.0 - i * 40.0 / 6.0
				body.append(at + Vector2(x, (20.0 if i % 2 == 0 else 13.0) + (boil % 2) * 2.0) * k)
			Toon.shape(ci, body, CREAM, 4.0)
			Toon.pie_eye(ci, at + Vector2(-7, -8) * k, Vector2(5, 7) * k, Vector2(0, 0.3), boil, 16, 2.5)
			Toon.pie_eye(ci, at + Vector2(7, -8) * k, Vector2(5, 7) * k, Vector2(0, 0.3), boil, 17, 2.5)
		"balloon":
			Toon.stroke(ci, Toon.bent(at + Vector2(0, 14) * k, at + Vector2(4, 32) * k, 6.0 * k), 2.0 * k)
			Toon.blob(ci, at + Vector2(0, -8) * k, Vector2(19, 23) * k, RED, boil, 18)
			Toon.shape(ci, PackedVector2Array([at + Vector2(-4, 18) * k, at + Vector2(4, 18) * k,
					at + Vector2(0, 13) * k]), RED, 2.5)
			Toon.spot(ci, at + Vector2(-7, -18) * k, Vector2(4, 8) * k, Color(1, 1, 1, 0.7), 0, 0, 0.4)
		"beans":
			for i in 2:
				var c := at + Vector2(-10 + i * 20, -4 + i * 8) * k
				var rot := -0.5 + i * 0.9
				Toon.blob(ci, c, Vector2(12, 16) * k, Color("6b3e22"), boil, 19 + i, 4.0, rot)
				Toon.stroke(ci, Toon.bent(c + Vector2(0, -12).rotated(rot) * k, c + Vector2(0, 12).rotated(rot) * k,
						4.0 * k), 2.5 * k)
		"alarm":
			for sx: float in [-1.0, 1.0]:
				Toon.blob(ci, at + Vector2(sx * 15, -22) * k, Vector2(9, 7) * k, SILVER, boil, 21 + int(sx), 3.0, sx * 0.6)
			Toon.blob(ci, at + Vector2(0, 2) * k, Vector2(22, 22) * k, CREAM, boil, 23)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 2) * k, at + Vector2(0, -12) * k]), 3.0 * k)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 2) * k, at + Vector2(10, 6) * k]), 3.0 * k)
			for sx: float in [-1.0, 1.0]:
				Toon.stroke(ci, PackedVector2Array([at + Vector2(sx * 12, 22) * k, at + Vector2(sx * 17, 30) * k]), 4.0 * k)
		"boxing":
			Toon.box(ci, at + Vector2(-6, 18) * k, Vector2(12, 9) * k, CREAM, boil, 24, 4.0)
			Toon.blob(ci, at + Vector2(2, -4) * k, Vector2(22, 19) * k, RED, boil, 25)
			Toon.blob(ci, at + Vector2(-17, 4) * k, Vector2(8, 10) * k, RED, boil, 26, 4.0, 0.4)
			Toon.spot(ci, at + Vector2(4, -14) * k, Vector2(9, 4) * k, Color(1, 1, 1, 0.55))
		"coin":
			# Spins: its width goes in and out drawing by drawing.
			var turn: float = [1.0, 0.7, 0.3, 0.7][boil % 4]
			Toon.blob(ci, at, Vector2(15 * turn + 2, 16) * k, GOLD, boil, 27, 3.5)
			if turn > 0.5:
				Toon.blob(ci, at, Vector2(9 * turn, 10) * k, GOLD.lightened(0.2), boil, 28, 2.0)
			Toon.spot(ci, at + Vector2(-4 * turn, -6) * k, Vector2(2.5, 4) * k, Color(1, 1, 1, 0.8))
		"bomb":
			Toon.blob(ci, at + Vector2(0, 4) * k, Vector2(19, 18) * k, Toon.INK, boil, 29, 3.0)
			Toon.box(ci, at + Vector2(6, -15) * k, Vector2(6, 4) * k, SILVER, boil, 30, 2.5, 0.5)
			Toon.stroke(ci, Toon.bent(at + Vector2(9, -19) * k, at + Vector2(17, -28) * k, 4.0 * k), 3.0 * k, BROWN)
			Toon.star(ci, at + Vector2(18, -30) * k, 6.0 * k, boil * 0.8, GOLD)
			Toon.spot(ci, at + Vector2(-7, -2) * k, Vector2(4, 6) * k, Color(1, 1, 1, 0.45))
		"key":
			Toon.blob(ci, at + Vector2(-12, -10) * k, Vector2(10, 10) * k, GOLD, boil, 31, 4.0)
			Toon.spot(ci, at + Vector2(-12, -10) * k, Vector2(4, 4) * k, Toon.INK)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-5, -3) * k, at + Vector2(18, 20) * k]), 9.0 * k)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-5, -3) * k, at + Vector2(18, 20) * k]), 4.0 * k, GOLD)
			for t: float in [0.6, 0.85]:
				var p := (at + Vector2(-5, -3) * k).lerp(at + Vector2(18, 20) * k, t)
				Toon.stroke(ci, PackedVector2Array([p, p + Vector2(7, -7) * k]), 7.0 * k)
				Toon.stroke(ci, PackedVector2Array([p, p + Vector2(7, -7) * k]), 3.0 * k, GOLD)
		_:
			Toon.blob(ci, at, Vector2(18, 18) * k, SILVER, boil, 32)
