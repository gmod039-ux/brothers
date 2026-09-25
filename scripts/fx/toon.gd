class_name Toon
extends RefCounted
## The drawing kit of a 1930s cartoon, so that even the placeholders move
## like one: every shape has an ink outline, and every outline "boils".
##
## Boil: a hand-animated cartoon is redrawn for every frame, and no two
## tracings of a line are quite the same, so outlines shimmer even on a
## character standing still. Here a shape takes a drawing number and bends
## its outline by it: the same number is the same wobble (a still frame stays
## still), the next number a slightly different one.
##
## Outlines are a black shape drawn a line-width larger under the fill, not a
## stroke on top. Thick strokes get notched joints on curves, and overlapping
## parts drawn this way keep their own ink edge, the way painted cels do.

## Drawings a second. Old cartoons were shot "on twos": 24 fps film, a new
## drawing every other frame. Things still move at 60; only their drawings
## change at this rate.
const FPS := 12.0

const INK := Color("1b1410")
const PAPER := Color("f3e6c8")
const WHITE := Color("fbf6ea")
const LINE := 5.0


## A number in 0..1 that depends only on [param a] and [param b].
static func hash01(a: int, b: int) -> float:
	var h := (a * 374761393 + b * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	h = h ^ (h >> 16)
	return float(h & 0xffff) / 65535.0


## Points around an ellipse whose outline is bent a little for drawing number
## [param boil]. [param seed] tells shapes apart, so that two eyes on the same
## drawing do not wobble in step. [param grow] moves the whole outline out
## (or in, when negative) by that many pixels.
##
## [param power] above 2 squares the ellipse off towards a rounded box
## (a superellipse): 4 is a bottle, a tile, a sign.
##
## [param egg] widens the lower half and narrows the upper one: 0.3 is a
## pear, the body shape of every rubber-hose character.
static func ellipse_points(center: Vector2, radii: Vector2, boil: int, seed: int,
		grow := 0.0, rot := 0.0, wobble := 1.2, power := 2.0, egg := 0.0) -> PackedVector2Array:
	# A smooth bend, not a jitter per point: two waves around the rim whose
	# phases change from drawing to drawing.
	var p1 := hash01(boil, seed) * TAU
	var p2 := hash01(seed + 101, boil) * TAU
	var segments := clampi(int(maxf(radii.x, radii.y) * 0.9), 16, 56)
	var points := PackedVector2Array()
	points.resize(segments)
	for i in segments:
		var a := TAU * i / segments
		var w := wobble * (0.6 * sin(2.0 * a + p1) + 0.4 * sin(3.0 * a + p2))
		var c := cos(a)
		var sn := sin(a)
		if power != 2.0:
			c = signf(c) * pow(absf(c), 2.0 / power)
			sn = signf(sn) * pow(absf(sn), 2.0 / power)
		var p := Vector2(c * maxf(radii.x * (1.0 + egg * sn) + grow + w, 0.5),
				sn * maxf(radii.y + grow + w, 0.5))
		points[i] = center + p.rotated(rot)
	return points


## A filled ellipse with an ink outline.
static func blob(ci: CanvasItem, center: Vector2, radii: Vector2, fill: Color, boil: int,
		seed := 0, line := LINE, rot := 0.0) -> void:
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, line * 0.5, rot), INK)
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, -line * 0.5, rot), fill)


## A pear with an ink outline: wider at the bottom by [param egg].
static func pear(ci: CanvasItem, center: Vector2, radii: Vector2, egg: float, fill: Color,
		boil: int, seed := 0, line := LINE) -> void:
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, line * 0.5, 0.0, 1.2, 2.0, egg), INK)
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, -line * 0.5, 0.0, 1.2, 2.0, egg), fill)


## Several ellipses filled as one shape with one outline round the lot: all
## the ink first, then all the fill. Each part is [center, radii].
static func union(ci: CanvasItem, parts: Array, fill: Color, boil: int, seed := 0,
		line := LINE) -> void:
	for i in parts.size():
		var part: Array = parts[i]
		ci.draw_colored_polygon(ellipse_points(part[0], part[1], boil, seed + i, line * 0.5), INK)
	for i in parts.size():
		var part: Array = parts[i]
		ci.draw_colored_polygon(ellipse_points(part[0], part[1], boil, seed + i, -line * 0.5), fill)


## The part of a convex shape below the line y = [param y]: trousers on a
## body, a mouth under a snout.
static func clip_below(points: PackedVector2Array, y: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		if a.y >= y:
			out.append(a)
		if (a.y >= y) != (b.y >= y):
			var t := (y - a.y) / (b.y - a.y)
			out.append(a.lerp(b, t))
	return out


## The part of a convex shape above the line y = [param y].
static func clip_above(points: PackedVector2Array, y: float) -> PackedVector2Array:
	var flipped := PackedVector2Array()
	for p in points:
		flipped.append(Vector2(p.x, -p.y))
	var kept := clip_below(flipped, -y)
	var out := PackedVector2Array()
	for p in kept:
		out.append(Vector2(p.x, -p.y))
	return out


## A rounded box with an ink outline: a bottle, a label.
static func box(ci: CanvasItem, center: Vector2, radii: Vector2, fill: Color, boil: int,
		seed := 0, line := LINE, rot := 0.0) -> void:
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, line * 0.5, rot, 1.0, 4.0), INK)
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, -line * 0.5, rot, 1.0, 4.0), fill)


## Any shape with an ink outline: the points pushed out from their middle
## for the ink under it. Good for shapes that are roughly round or convex:
## ears, flames, feathers.
static func shape(ci: CanvasItem, points: PackedVector2Array, fill: Color, line := 4.0) -> void:
	ci.draw_colored_polygon(grown(points, line), INK)
	ci.draw_colored_polygon(points, fill)


## [param points] pushed out from their middle by [param by] pixels.
static func grown(points: PackedVector2Array, by: float) -> PackedVector2Array:
	var middle := Vector2.ZERO
	for p in points:
		middle += p
	middle /= maxi(points.size(), 1)
	var out := PackedVector2Array()
	for p in points:
		out.append(p + (p - middle).normalized() * by)
	return out


## A filled ellipse without an outline: shadows, cheeks, highlights.
static func spot(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color,
		boil := 0, seed := 0, rot := 0.0) -> void:
	ci.draw_colored_polygon(ellipse_points(center, radii, boil, seed, 0.0, rot, 0.6), color)


## An ellipse with a wedge cut out of it: a pac-man, pointing the missing
## wedge at angle [param cut_at].
static func pie(ci: CanvasItem, center: Vector2, radii: Vector2, cut_at: float, cut: float,
		color: Color) -> void:
	var points := PackedVector2Array([center])
	var n := 22
	for i in n + 1:
		var a := cut_at + cut * 0.5 + (TAU - cut) * i / n
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(points, color)


## The eye of the period: a white with a black pupil that has a wedge cut out
## of it, the "pie cut" that stood in for a highlight. [param look] (-1..1 on
## each axis) slides the pupil towards the edge of the white.
static func pie_eye(ci: CanvasItem, center: Vector2, radii: Vector2, look: Vector2, boil: int,
		seed := 0, line := 3.5, pupil_size := 1.0) -> void:
	blob(ci, center, radii, WHITE, boil, seed, line)
	var pupil := radii * Vector2(0.64, 0.7) * pupil_size
	var at := center + look.limit_length(1.0) * (radii - pupil - Vector2(line, line) * 0.4)
	pie(ci, at, pupil, -PI * 0.3, 0.95, INK)


## A closed eye: a short arc, bowed down like a smile.
static func shut_eye(ci: CanvasItem, center: Vector2, width: float, line := 3.5) -> void:
	var points := PackedVector2Array()
	for i in 7:
		var t := i / 6.0
		points.append(center + Vector2((t - 0.5) * width, sin(t * PI) * width * 0.22))
	stroke(ci, points, line)


## A line with round ends.
static func stroke(ci: CanvasItem, points: PackedVector2Array, width: float,
		color := INK) -> void:
	if points.size() < 2:
		return
	ci.draw_polyline(points, color, width, true)
	ci.draw_circle(points[0], width * 0.5, color, true, -1.0, true)
	ci.draw_circle(points[points.size() - 1], width * 0.5, color, true, -1.0, true)


## The points of a quadratic curve from [param from] to [param to], its middle
## pushed [param bend] pixels sideways.
static func bent(from: Vector2, to: Vector2, bend: float, steps := 10) -> PackedVector2Array:
	var control := (from + to) * 0.5 + (to - from).orthogonal().normalized() * bend
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		points.append(from.lerp(control, t).lerp(control.lerp(to, t), t))
	return points


## A rubber-hose limb: a tube with no elbow or knee, just a bend.
static func hose(ci: CanvasItem, from: Vector2, to: Vector2, bend: float, width: float,
		color := INK) -> void:
	stroke(ci, bent(from, to, bend), width, color)


## A white cartoon glove seen from the back: three stitches and a rolled cuff.
static func glove(ci: CanvasItem, center: Vector2, r: float, boil: int, seed := 0,
		fill := WHITE) -> void:
	blob(ci, center, Vector2(r, r * 0.92), fill, boil, seed, 3.5)
	for i in 3:
		var x := (i - 1) * r * 0.34
		stroke(ci, PackedVector2Array([center + Vector2(x, -r * 0.42),
				center + Vector2(x, -r * 0.02)]), 1.8)


## A five-pointed star with an ink edge.
static func star(ci: CanvasItem, center: Vector2, r: float, rot: float, fill: Color) -> void:
	ci.draw_colored_polygon(_star_points(center, r + 3.0, r * 0.46 + 2.5, rot), INK)
	ci.draw_colored_polygon(_star_points(center, r - 1.0, r * 0.46 - 0.8, rot), fill)


static func _star_points(center: Vector2, outer: float, inner: float,
		rot: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var a := rot - PI * 0.5 + PI * i / 5.0
		var r := outer if i % 2 == 0 else inner
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points


## A heart about [param size] pixels across. [param half] draws only its left
## half, which is how a half heart of health looks.
static func heart_points(center: Vector2, size: float, half := false) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 40
	var k := size / 34.0
	# The whole heart goes once round without repeating its first point (a
	# polygon with a doubled point may fail to triangulate); the half runs
	# from the bottom tip up to the notch, and closing it is the midline.
	for i in (n + 1 if half else n):
		var t := (PI + PI * i / n) if half else (TAU * i / n)
		var s := sin(t)
		var x := 16.0 * s * s * s
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y - 2.5) * k)
	return points


## A heart of health: [param fill] 0 empty, 1 half, 2 full.
static func heart(ci: CanvasItem, center: Vector2, size: float, fill: int, red: Color,
		empty: Color) -> void:
	ci.draw_colored_polygon(heart_points(center, size + 9.0), INK)
	ci.draw_colored_polygon(heart_points(center, size), empty)
	if fill >= 2:
		ci.draw_colored_polygon(heart_points(center, size), red)
	elif fill == 1:
		ci.draw_colored_polygon(heart_points(center, size, true), red)
	if fill > 0:
		spot(ci, center + Vector2(-size * 0.22, -size * 0.12), Vector2(size * 0.1, size * 0.07),
				Color(1, 1, 1, 0.75), 0, 0, -0.6)


## A straight line drawn by hand: it wanders a pixel or two off true.
## Deterministic in [param seed], so a background drawn with it is the same
## on every frame.
static func hand_line(ci: CanvasItem, from: Vector2, to: Vector2, width: float, seed: int,
		color := INK, wander := 1.6) -> void:
	var length := from.distance_to(to)
	var steps := maxi(int(length / 24.0), 2)
	var side := (to - from).orthogonal().normalized()
	var p1 := hash01(seed, 3) * TAU
	var p2 := hash01(seed, 7) * TAU
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var w := wander * (0.7 * sin(t * 5.0 + p1) + 0.5 * sin(t * 11.0 + p2)) * sin(t * PI)
		points.append(from.lerp(to, t) + side * w)
	stroke(ci, points, width, color)
