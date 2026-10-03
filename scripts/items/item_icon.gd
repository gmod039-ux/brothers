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
			# A wedge of cherry pie seen from the side and a little above:
			# the crust on top with a fluted edge and steam vents, the
			# filling showing at the cut, a dollop of cream on the point.
			var crust := Color("e3a85a")
			var base := [at + Vector2(-26, 18) * k, at + Vector2(24, 18) * k, at + Vector2(24, 4) * k,
					at + Vector2(-26, 4) * k]
			Toon.shape(ci, PackedVector2Array(base), crust.darkened(0.15), 4.0)
			Toon.shape(ci, PackedVector2Array([at + Vector2(-22, 6) * k, at + Vector2(22, 6) * k,
					at + Vector2(22, 14) * k, at + Vector2(-22, 14) * k]), RED, 0.0)
			for i in 4:
				Toon.spot(ci, at + Vector2(-16 + i * 11, 10) * k, Vector2(3, 2.5) * k, RED.darkened(0.35))
			var top := PackedVector2Array([at + Vector2(-26, 4) * k, at + Vector2(24, 4) * k,
					at + Vector2(6, -22) * k])
			Toon.shape(ci, top, crust, 4.0)
			for i in 5:
				var p := (at + Vector2(-26, 4) * k).lerp(at + Vector2(6, -22) * k, (i + 0.5) / 5.0)
				Toon.spot(ci, p + Vector2(2, 2) * k, Vector2(3, 2) * k, crust.darkened(0.25))
			for i in 2:
				Toon.stroke(ci, PackedVector2Array([at + Vector2(-4 + i * 10, -4) * k, at + Vector2(i * 10, -10) * k]),
						2.5 * k, crust.darkened(0.4))
			Toon.blob(ci, at + Vector2(6, -22) * k, Vector2(9, 6) * k, CREAM, boil, 10, 3.0)
		"horseshoe":
			# Open end up, for luck: a U with its heels flared and a row of
			# nail holes round it.
			var arc := PackedVector2Array()
			for i in 17:
				var a := lerpf(-PI * 0.22, PI * 1.22, i / 16.0)
				arc.append(at + Vector2(cos(a) * 19.0, sin(a) * 21.0 + 2.0) * k)
			Toon.stroke(ci, arc, 14.0 * k)
			Toon.stroke(ci, arc, 8.0 * k, SILVER)
			for end: Vector2 in [arc[0], arc[arc.size() - 1]]:
				Toon.box(ci, end + Vector2(0, -2) * k, Vector2(6, 3.5) * k, SILVER, boil, 61, 2.5)
			for i in [3, 5, 7, 9, 11, 13]:
				Toon.spot(ci, arc[i], Vector2(1.4, 1.4) * k, Toon.INK)
			Toon.stroke(ci, arc.slice(2, 8), 2.0 * k, Color(1, 1, 1, 0.55))
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
		"camera":
			# A box camera on its side, a flash pan up on a stick.
			Toon.box(ci, at + Vector2(0, 8) * k, Vector2(22, 15) * k, Toon.INK, boil, 40, 3.0)
			Toon.blob(ci, at + Vector2(2, 9) * k, Vector2(10, 10) * k, SILVER, boil, 41, 3.0)
			Toon.blob(ci, at + Vector2(2, 9) * k, Vector2(5, 5) * k, Color("3a4a5a"), boil, 42, 0.0)
			Toon.spot(ci, at + Vector2(-1, 6) * k, Vector2(2, 2) * k, Color(1, 1, 1, 0.9))
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-16, -6) * k, at + Vector2(-16, -20) * k]), 3.0 * k)
			Toon.box(ci, at + Vector2(-16, -22) * k, Vector2(11, 3) * k, SILVER, boil, 43, 2.5)
			if boil % 3 == 0:
				Toon.star(ci, at + Vector2(-16, -30) * k, 9.0 * k, boil * 0.5, Color("fff1a8"))
		"dynamite":
			for i in 3:
				var c := at + Vector2(-12 + i * 12, 6) * k
				Toon.box(ci, c, Vector2(6, 18) * k, Color("c8392b"), boil, 44 + i, 3.0)
				draw_band(ci, c + Vector2(0, -6) * k, k)
			Toon.stroke(ci, Toon.bent(at + Vector2(0, -12) * k, at + Vector2(10, -26) * k, 4.0 * k), 2.5 * k, BROWN)
			Toon.star(ci, at + Vector2(11, -28) * k, 6.0 * k, boil * 0.8, GOLD)
		"soda":
			var bottle := PackedVector2Array([at + Vector2(-5, -28) * k, at + Vector2(5, -28) * k,
					at + Vector2(6, -14) * k, at + Vector2(13, -4) * k, at + Vector2(13, 26) * k,
					at + Vector2(-13, 26) * k, at + Vector2(-13, -4) * k, at + Vector2(-6, -14) * k])
			Toon.shape(ci, bottle, Color("7fb0a0"), 3.5)
			Toon.box(ci, at + Vector2(0, 8) * k, Vector2(12, 7) * k, CREAM, boil, 48, 2.0)
			Toon.box(ci, at + Vector2(0, -29) * k, Vector2(7, 3) * k, RED, boil, 49, 2.0)
			for i in 3:
				var rise := fmod(boil * 0.3 + i * 0.33, 1.0)
				Toon.spot(ci, at + Vector2(-4 + i * 4, 20 - rise * 36) * k, Vector2(2, 2) * k, Color(1, 1, 1, 0.8))
		"watch":
			Toon.stroke(ci, Toon.bent(at + Vector2(0, -22) * k, at + Vector2(14, -32) * k, -6.0 * k), 3.0 * k, GOLD)
			Toon.blob(ci, at + Vector2(0, -21) * k, Vector2(5, 4) * k, GOLD, boil, 50, 3.0)
			Toon.blob(ci, at + Vector2(0, 2) * k, Vector2(22, 22) * k, GOLD, boil, 51, 4.0)
			Toon.blob(ci, at + Vector2(0, 2) * k, Vector2(17, 17) * k, CREAM, boil, 52, 2.0)
			for h in 4:
				var a := TAU * h / 4.0
				Toon.spot(ci, at + Vector2(0, 2) * k + Vector2(cos(a), sin(a)) * 13.0 * k, Vector2(1.6, 1.6) * k, Toon.INK)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 2) * k, at + Vector2(0, -9) * k]), 2.5 * k)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 2) * k, at + Vector2(8, 4) * k]), 2.5 * k)
		"sandwich":
			# Bread, a lettuce frill, ham, cheese, bread.
			Toon.box(ci, at + Vector2(0, 14) * k, Vector2(24, 6) * k, Color("e3a85a"), boil, 53, 3.5)
			Toon.box(ci, at + Vector2(0, 5) * k, Vector2(25, 4) * k, Color("f0c43a"), boil, 54, 3.0, 0.05)
			Toon.box(ci, at + Vector2(0, -2) * k, Vector2(23, 4) * k, Color("e07a86"), boil, 55, 3.0, -0.04)
			Toon.blob(ci, at + Vector2(0, -8) * k, Vector2(26, 4) * k, GREEN, boil, 56, 3.0)
			Toon.blob(ci, at + Vector2(0, -16) * k, Vector2(24, 10) * k, Color("e3a85a"), boil, 57, 3.5)
			Toon.spot(ci, at + Vector2(-8, -20) * k, Vector2(7, 2.5) * k, Color(1, 1, 1, 0.45))
		"hat":
			# A magician's topper, a star coming out of it.
			Toon.blob(ci, at + Vector2(0, 20) * k, Vector2(28, 7) * k, Toon.INK, boil, 58, 3.0)
			Toon.box(ci, at + Vector2(0, 2) * k, Vector2(17, 17) * k, Toon.INK, boil, 59, 3.0)
			Toon.box(ci, at + Vector2(0, 12) * k, Vector2(17, 4) * k, RED, boil, 60, 2.5)
			Toon.spot(ci, at + Vector2(-9, -2) * k, Vector2(3, 10) * k, Color(1, 1, 1, 0.3))
			Toon.star(ci, at + Vector2(10, -24) * k, 9.0 * k, boil * 0.5, GOLD)
		"rubber_ball":
			# A red and blue ball, a bounce line under it.
			Toon.ball(ci, at + Vector2(0, -6) * k, Vector2(20, 20) * k, RED, boil, 70)
			Toon.stroke(ci, Toon.bent(at + Vector2(-18, -10) * k, at + Vector2(16, -2) * k, -8.0 * k), 6.0 * k, Color("3f6fb5"))
			Toon.spot(ci, at + Vector2(-7, -14) * k, Vector2(5, 3) * k, Color(1, 1, 1, 0.7))
			for sx: float in [-1.0, 1.0]:
				Toon.stroke(ci, Toon.bent(at + Vector2(sx * 10, 22) * k, at + Vector2(sx * 20, 28) * k, 2.0 * k), 3.0 * k)
		"firecracker":
			# A red tube with a gold band, a sparking fuse.
			Toon.box(ci, at + Vector2(0, 4) * k, Vector2(9, 22) * k, RED, boil, 71, 3.5, 0.25)
			draw_band(ci, at + Vector2(1, -6) * k, k)
			draw_band(ci, at + Vector2(-2, 12) * k, k)
			Toon.stroke(ci, Toon.bent(at + Vector2(5, -18) * k, at + Vector2(14, -30) * k, 5.0 * k), 2.5 * k, BROWN)
			for i in 3:
				Toon.star(ci, at + Vector2(15 + i * 3, -32 - i * 4) * k, (4.0 + (boil + i) % 3 * 2.0) * k, boil * 0.7 + i,
						Color("fff1a8") if i % 2 == 0 else GOLD)
		"icecream":
			# An eskimo on a stick, a bite out of it, frost on it.
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 14) * k, at + Vector2(0, 30) * k]), 6.0 * k, Color("d9b878"))
			Toon.box(ci, at + Vector2(0, -6) * k, Vector2(14, 22) * k, Color("6b3a24"), boil, 72, 3.5)
			Toon.blob(ci, at + Vector2(12, -22) * k, Vector2(7, 7) * k, Color("7fb8d8"), boil, 73, 0.0)
			Toon.box(ci, at + Vector2(0, -8) * k, Vector2(9, 16) * k, Color("efe6cf"), boil, 74, 0.0)
			for i in 3:
				Toon.star(ci, at + Vector2(-16 + i * 16, -30 + (i % 2) * 8) * k, 5.0 * k, i * 0.7, Color("cfe8f4"))
		"scissors":
			# Open blades, two finger loops.
			for sx: float in [-1.0, 1.0]:
				var tip := at + Vector2(sx * 14, -28) * k
				Toon.shape(ci, PackedVector2Array([at + Vector2(0, 2) * k, tip, at + Vector2(sx * 6, 0) * k]), SILVER, 3.0)
				Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 2) * k, at + Vector2(sx * 12, 16) * k]), 5.0 * k)
				Toon.blob(ci, at + Vector2(sx * 14, 20) * k, Vector2(8, 8) * k, RED, boil, 75 + int(sx), 3.5)
				Toon.blob(ci, at + Vector2(sx * 14, 20) * k, Vector2(3.5, 3.5) * k, CREAM, boil, 77 + int(sx), 0.0)
			Toon.blob(ci, at + Vector2(0, 2) * k, Vector2(3, 3) * k, Toon.INK, boil, 79, 0.0)
		"harmonica":
			# A mouth organ: a silver cover, a row of holes, notes coming off.
			Toon.box(ci, at + Vector2(-4, 6) * k, Vector2(24, 9) * k, SILVER, boil, 80, 3.5, -0.15)
			Toon.box(ci, at + Vector2(-4, 6) * k, Vector2(22, 3) * k, Color("8a5a36"), boil, 81, 0.0, -0.15)
			for i in 6:
				Toon.spot(ci, at + Vector2(-20 + i * 7, 9 - i * 1.0) * k, Vector2(1.6, 1.4) * k, Toon.INK)
			for i in 2:
				var note := at + Vector2(10 + i * 12, -14 - i * 10) * k
				Toon.blob(ci, note, Vector2(5, 4) * k, Toon.INK, boil, 82 + i, 0.0, -0.4)
				Toon.stroke(ci, PackedVector2Array([note + Vector2(4, 0) * k, note + Vector2(4, -14) * k]), 2.0 * k)
		"chick":
			Toon.ball(ci, at + Vector2(-2, 8) * k, Vector2(18, 15) * k, Color("f2c84a"), boil, 84)
			Toon.ball(ci, at + Vector2(8, -12) * k, Vector2(13, 12) * k, Color("f2c84a"), boil, 85)
			Toon.shape(ci, PackedVector2Array([at + Vector2(19, -13) * k, at + Vector2(29, -9) * k, at + Vector2(19, -6) * k]),
					Color("e0782a"), 2.0)
			Toon.spot(ci, at + Vector2(12, -15) * k, Vector2(2.5, 3.2) * k, Toon.INK)
			Toon.box(ci, at + Vector2(5, -24) * k, Vector2(12, 3) * k, CREAM, boil, 86, 2.0)
			Toon.ball(ci, at + Vector2(5, -28) * k, Vector2(10, 5) * k, CREAM, boil, 87, 2.0)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-6, -25) * k, at + Vector2(-12, -18) * k]), 2.5 * k, Color("3f6fb5"))
		"umbrella":
			var canopy := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				canopy.append(at + Vector2(cos(a) * 28.0, sin(a) * 20.0 - 4.0) * k)
			for i in 4:
				var u := 1.0 - (i + 0.5) / 4.0
				canopy.append(at + Vector2(-28.0 + 56.0 * u, -1.0) * k)
			Toon.shape(ci, canopy, RED, 3.5)
			for i in 3:
				var x := -14.0 + i * 14.0
				Toon.stroke(ci, PackedVector2Array([at + Vector2(0, -24) * k, at + Vector2(x, -2) * k]), 2.0 * k, RED.darkened(0.3))
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, -26) * k, at + Vector2(0, 22) * k]), 3.5 * k)
			Toon.stroke(ci, Toon.bent(at + Vector2(0, 22) * k, at + Vector2(-10, 22) * k, -6.0 * k), 3.5 * k, BROWN)
		"galoshes":
			for i in 2:
				var c := at + Vector2(-10 + i * 18, 6 - i * 4) * k
				Toon.box(ci, c + Vector2(0, -8) * k, Vector2(8, 14) * k, Color("2a2a30"), boil, 88 + i, 3.0)
				Toon.blob(ci, c + Vector2(6, 8) * k, Vector2(14, 7) * k, Color("2a2a30"), boil, 90 + i, 3.0)
				Toon.box(ci, c + Vector2(0, -21) * k, Vector2(9, 3) * k, RED, boil, 92 + i, 2.0)
				Toon.spot(ci, c + Vector2(-3, -6) * k, Vector2(2, 6) * k, Color(1, 1, 1, 0.4))
		"helmet":
			# A tin hat, dented, with a strap.
			var dome := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				dome.append(at + Vector2(cos(a) * 22.0, sin(a) * 22.0 + 6.0) * k)
			Toon.shape(ci, dome, Color("7a8a5a"), 3.5)
			Toon.box(ci, at + Vector2(0, 8) * k, Vector2(30, 4) * k, Color("6a7a4a"), boil, 94, 3.0)
			Toon.stroke(ci, Toon.bent(at + Vector2(-16, 10) * k, at + Vector2(16, 10) * k, 14.0 * k), 2.5 * k, BROWN)
			Toon.spot(ci, at + Vector2(-8, -8) * k, Vector2(4, 7) * k, Color(1, 1, 1, 0.35), 0, 0, -0.4)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(6, -10) * k, at + Vector2(10, -4) * k]), 2.0 * k)
		"glasses":
			for sx: float in [-1.0, 1.0]:
				Toon.blob(ci, at + Vector2(sx * 14, 0) * k, Vector2(11, 11) * k, Color(0.8, 0.9, 1.0, 0.5), boil, 95 + int(sx), 4.0)
				Toon.spot(ci, at + Vector2(sx * 14 - 4, -4) * k, Vector2(3, 2) * k, Color(1, 1, 1, 0.8))
				Toon.stroke(ci, PackedVector2Array([at + Vector2(sx * 25, -2) * k, at + Vector2(sx * 30, -12) * k]), 2.5 * k)
			Toon.stroke(ci, Toon.bent(at + Vector2(-3, -2) * k, at + Vector2(3, -2) * k, -3.0 * k), 2.5 * k)
		"piggy":
			Toon.ball(ci, at + Vector2(0, 4) * k, Vector2(24, 18) * k, Color("e8a0a8"), boil, 97)
			Toon.blob(ci, at + Vector2(22, 2) * k, Vector2(6, 7) * k, Color("d88890"), boil, 98, 3.0)
			for i in 2:
				Toon.spot(ci, at + Vector2(21 + i * 3, 2) * k, Vector2(1.2, 2) * k, Toon.INK)
			Toon.shape(ci, PackedVector2Array([at + Vector2(6, -12) * k, at + Vector2(12, -22) * k, at + Vector2(16, -12) * k]),
					Color("e8a0a8"), 2.5)
			Toon.spot(ci, at + Vector2(10, -4) * k, Vector2(2, 2.5) * k, Toon.INK)
			for sx: float in [-1.0, 1.0]:
				Toon.box(ci, at + Vector2(sx * 12, 22) * k, Vector2(4, 4) * k, Color("d88890"), boil, 99, 2.0)
			ci.draw_rect(Rect2(at + Vector2(-6, -15) * k, Vector2(12, 3) * k), Toon.INK)
			draw(ci, "coin", at + Vector2(0, -24) * k, 26.0 * k, boil)
		"bomb_bag":
			Toon.ball(ci, at + Vector2(0, 8) * k, Vector2(22, 20) * k, Color("b89a6a"), boil, 100)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-10, -10) * k, at + Vector2(10, -10) * k]), 3.0 * k, BROWN)
			for i in 3:
				var c := at + Vector2(-12 + i * 12, -16 - (i % 2) * 6) * k
				Toon.blob(ci, c, Vector2(8, 8) * k, Toon.INK, boil, 101 + i, 2.5)
			Toon.star(ci, at + Vector2(12, -30) * k, 5.0 * k, boil * 0.8, GOLD)
			ci.draw_string(Ui.font(), at + Vector2(-8, 18) * k, "5", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * k), Toon.INK)
		"keyring":
			Toon.stroke(ci, _ring(at + Vector2(0, -20) * k, 11.0 * k), 3.5 * k, SILVER)
			for i in 3:
				draw(ci, "key", at + Vector2(-14 + i * 14, 8 + (i % 2) * 6) * k, 34.0 * k, boil + i)
		"locket":
			Toon.stroke(ci, Toon.bent(at + Vector2(-16, -26) * k, at + Vector2(16, -26) * k, -10.0 * k), 2.0 * k, GOLD)
			ci.draw_colored_polygon(Toon.heart_points(at + Vector2(0, 4) * k, 46.0 * k), Toon.INK)
			ci.draw_colored_polygon(Toon.heart_points(at + Vector2(0, 4) * k, 38.0 * k), GOLD)
			ci.draw_colored_polygon(Toon.heart_points(at + Vector2(0, 4) * k, 22.0 * k), RED)
			Toon.spot(ci, at + Vector2(-8, -4) * k, Vector2(3, 2) * k, Color(1, 1, 1, 0.8))
		"chocolate":
			# A bar half out of its wrapper.
			Toon.box(ci, at + Vector2(0, -6) * k, Vector2(16, 24) * k, Color("5a3020"), boil, 104, 3.5)
			for r in 3:
				ci.draw_line(at + Vector2(-14, -22 + r * 10) * k, at + Vector2(14, -22 + r * 10) * k, Color(0, 0, 0, 0.35), 2.0 * k)
			ci.draw_line(at + Vector2(0, -28) * k, at + Vector2(0, 14) * k, Color(0, 0, 0, 0.35), 2.0 * k)
			Toon.box(ci, at + Vector2(0, 14) * k, Vector2(18, 13) * k, RED, boil, 105, 3.0)
			Toon.box(ci, at + Vector2(0, 14) * k, Vector2(10, 5) * k, CREAM, boil, 106, 0.0)
		"monocle":
			Toon.stroke(ci, _ring(at + Vector2(-2, -4) * k, 18.0 * k), 6.0 * k, GOLD)
			Toon.spot(ci, at + Vector2(-2, -4) * k, Vector2(15, 15) * k, Color(0.8, 0.9, 1.0, 0.35))
			Toon.spot(ci, at + Vector2(-8, -10) * k, Vector2(4, 3) * k, Color(1, 1, 1, 0.8))
			Toon.stroke(ci, Toon.bent(at + Vector2(12, 8) * k, at + Vector2(20, 30) * k, -6.0 * k), 2.0 * k, GOLD)
		"rabbit_foot":
			# A white rabbit's foot on a gold cap and ring.
			Toon.stroke(ci, _ring(at + Vector2(0, -26) * k, 6.0 * k), 2.5 * k, GOLD)
			Toon.box(ci, at + Vector2(0, -16) * k, Vector2(9, 6) * k, GOLD, boil, 120, 3.0)
			Toon.blob(ci, at + Vector2(0, 6) * k, Vector2(14, 20) * k, Color("efe8de"), boil, 121, 4.0)
			for j in 3:
				Toon.blob(ci, at + Vector2(-8 + j * 8, 24) * k, Vector2(5, 5) * k, Color("efe8de"), boil, 122 + j, 3.0)
			Toon.spot(ci, at + Vector2(-5, 0) * k, Vector2(3, 7) * k, Color(1, 1, 1, 0.6))
		"lucky_button":
			Toon.ball(ci, at, Vector2(24, 24) * k, RED, boil, 125)
			Toon.blob(ci, at, Vector2(17, 17) * k, RED.darkened(0.12), boil, 126, 2.0)
			for j in 4:
				var hole := at + Vector2(-5 + (j % 2) * 10, -5 + (j / 2) * 10) * k
				Toon.spot(ci, hole, Vector2(2.6, 2.6) * k, Toon.INK)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-5, -5) * k, at + Vector2(5, 5) * k]), 1.6 * k, CREAM)
		"thimble":
			var cup := PackedVector2Array([at + Vector2(-16, 20) * k, at + Vector2(-13, -12) * k, at + Vector2(-6, -22) * k,
					at + Vector2(6, -22) * k, at + Vector2(13, -12) * k, at + Vector2(16, 20) * k])
			Toon.shape(ci, cup, SILVER, 3.5)
			for r in 4:
				for j in 4:
					Toon.spot(ci, at + Vector2(-9 + j * 6, -12 + r * 7) * k, Vector2(1.6, 1.4) * k, Color(0, 0, 0, 0.35))
			Toon.box(ci, at + Vector2(0, 20) * k, Vector2(17, 3) * k, SILVER.darkened(0.15), boil, 127, 2.5)
			Toon.spot(ci, at + Vector2(-8, -6) * k, Vector2(2.5, 9) * k, Color(1, 1, 1, 0.6))
		"rusty_nail":
			var rust := Color("b0603a")
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-14, -20) * k, at + Vector2(4, 4) * k, at + Vector2(16, 24) * k]),
					8.0 * k)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-14, -20) * k, at + Vector2(4, 4) * k, at + Vector2(16, 24) * k]),
					4.0 * k, rust)
			Toon.box(ci, at + Vector2(-15, -22) * k, Vector2(9, 3) * k, rust.darkened(0.2), boil, 128, 3.0, 0.9)
			for j in 3:
				Toon.spot(ci, at + Vector2(-8 + j * 8, -10 + j * 12) * k, Vector2(2.4, 1.8) * k, Color("6a3218"))
		"compass":
			Toon.ball(ci, at, Vector2(24, 24) * k, GOLD, boil, 129)
			Toon.blob(ci, at, Vector2(18, 18) * k, CREAM, boil, 130, 2.5)
			ci.draw_string(Ui.font(), at + Vector2(-6, -9) * k, "С", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * k), Toon.INK)
			Toon.shape(ci, PackedVector2Array([at + Vector2(-3, 0) * k, at + Vector2(0, -14) * k, at + Vector2(3, 0) * k]), RED, 1.5)
			Toon.shape(ci, PackedVector2Array([at + Vector2(-3, 0) * k, at + Vector2(0, 14) * k, at + Vector2(3, 0) * k]),
					SILVER, 1.5)
			Toon.blob(ci, at + Vector2(0, -26) * k, Vector2(5, 4) * k, GOLD, boil, 131, 2.5)
		"matchbox":
			Toon.box(ci, at + Vector2(0, 6) * k, Vector2(24, 15) * k, Color("3f6fb5"), boil, 132, 3.5)
			Toon.box(ci, at + Vector2(0, 6) * k, Vector2(14, 9) * k, CREAM, boil, 133, 0.0)
			Toon.star(ci, at + Vector2(0, 6) * k, 6.0 * k, 0.0, RED)
			ci.draw_rect(Rect2(at + Vector2(-24, 18) * k, Vector2(48, 4) * k), Color("6a3a24"))
			Toon.stroke(ci, PackedVector2Array([at + Vector2(10, -8) * k, at + Vector2(22, -26) * k]), 3.5 * k, Color("e3c47a"))
			Toon.blob(ci, at + Vector2(23, -28) * k, Vector2(4, 5) * k, RED, boil, 134, 2.0)
		"tuning_fork":
			for sx: float in [-1.0, 1.0]:
				Toon.stroke(ci, PackedVector2Array([at + Vector2(sx * 7, -26) * k, at + Vector2(sx * 7, 0) * k]), 7.0 * k)
				Toon.stroke(ci, PackedVector2Array([at + Vector2(sx * 7, -26) * k, at + Vector2(sx * 7, 0) * k]), 3.5 * k, SILVER)
			Toon.stroke(ci, Toon.bent(at + Vector2(-7, 0) * k, at + Vector2(7, 0) * k, -6.0 * k), 7.0 * k)
			Toon.stroke(ci, Toon.bent(at + Vector2(-7, 0) * k, at + Vector2(7, 0) * k, -6.0 * k), 3.5 * k, SILVER)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 4) * k, at + Vector2(0, 26) * k]), 7.0 * k)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(0, 4) * k, at + Vector2(0, 26) * k]), 3.5 * k, SILVER)
			for sx: float in [-1.0, 1.0]:
				ci.draw_arc(at + Vector2(0, -14) * k, 18.0 * k, PI * (0.5 - sx * 0.5) - 0.4, PI * (0.5 - sx * 0.5) + 0.4, 6,
						Toon.INK, 2.0 * k)
		"whistle":
			Toon.ball(ci, at + Vector2(4, 4) * k, Vector2(16, 14) * k, GOLD, boil, 135)
			Toon.box(ci, at + Vector2(-14, -2) * k, Vector2(12, 6) * k, GOLD, boil, 136, 3.0)
			Toon.spot(ci, at + Vector2(8, 0) * k, Vector2(4, 3) * k, Toon.INK)
			Toon.stroke(ci, _ring(at + Vector2(16, -12) * k, 6.0 * k), 2.5 * k, SILVER)
			Toon.stroke(ci, Toon.bent(at + Vector2(16, -18) * k, at + Vector2(-4, -28) * k, 4.0 * k), 2.0 * k, RED)
		"pouch":
			Toon.ball(ci, at + Vector2(0, 6) * k, Vector2(20, 18) * k, Color("9a6a40"), boil, 137)
			Toon.shape(ci, PackedVector2Array([at + Vector2(-10, -10) * k, at + Vector2(10, -10) * k, at + Vector2(14, -22) * k,
					at + Vector2(-14, -22) * k]), Color("9a6a40"), 3.0)
			Toon.stroke(ci, Toon.bent(at + Vector2(-11, -10) * k, at + Vector2(11, -10) * k, 3.0 * k), 3.0 * k, RED)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(6, -10) * k, at + Vector2(14, 0) * k]), 2.5 * k, RED)
			Toon.spot(ci, at + Vector2(-7, 2) * k, Vector2(4, 6) * k, Color(1, 1, 1, 0.3))
		"feather":
			var vane := PackedVector2Array()
			for j in 9:
				var u := j / 8.0
				vane.append(at + Vector2(-16 + 30 * u, 22 - 46 * u) * k + Vector2(-sin(u * PI) * 10.0, -sin(u * PI) * 6.0) * k)
			for j in 9:
				var u := 1.0 - j / 8.0
				vane.append(at + Vector2(-16 + 30 * u, 22 - 46 * u) * k + Vector2(sin(u * PI) * 8.0, sin(u * PI) * 8.0) * k)
			Toon.shape(ci, vane, CREAM, 3.0)
			Toon.stroke(ci, PackedVector2Array([at + Vector2(-20, 28) * k, at + Vector2(14, -24) * k]), 2.5 * k)
			for j in 4:
				var p := (at + Vector2(-12, 16) * k).lerp(at + Vector2(10, -16) * k, j / 3.0)
				Toon.stroke(ci, PackedVector2Array([p, p + Vector2(-8, -2) * k]), 1.4 * k, Color(Toon.INK, 0.4))
		"chest", "gold_chest":
			var gold := id == "gold_chest"
			var wood := Color("c9a03a") if gold else Color("8a5a36")
			var trim := Color("e8d488") if gold else Color("5d5c64")
			Toon.box(ci, at + Vector2(0, 8) * k, Vector2(28, 16) * k, wood, boil, 107, 4.0)
			var lid := PackedVector2Array()
			for i in 9:
				var a := PI + PI * i / 8.0
				lid.append(at + Vector2(cos(a) * 28.0, sin(a) * 12.0 - 8.0) * k)
			Toon.shape(ci, lid, wood.lightened(0.08), 4.0)
			for x: float in [-18.0, 18.0]:
				Toon.stroke(ci, PackedVector2Array([at + Vector2(x, -20) * k, at + Vector2(x, 24) * k]), 5.0 * k, trim)
			Toon.box(ci, at + Vector2(0, -6) * k, Vector2(6, 7) * k, trim, boil, 108, 2.5)
			Toon.spot(ci, at + Vector2(0, -5) * k, Vector2(1.5, 2.5) * k, Toon.INK)
			if gold:
				Toon.star(ci, at + Vector2(-20, -20) * k, (4.0 + boil % 3) * k, boil * 0.4, Color("fffbe8"))
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


static func _ring(center: Vector2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points


## The paper band round a stick of dynamite.
static func draw_band(ci: CanvasItem, at: Vector2, k: float) -> void:
	ci.draw_rect(Rect2(at - Vector2(6, 2.5) * k, Vector2(12, 5) * k), Color("e8dcc0"))
