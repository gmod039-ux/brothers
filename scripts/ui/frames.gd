class_name Frames
extends RefCounted
## The furniture of the interface, in the manner of 1930s title cards and
## posters: cards with a double ink rule and corner ornaments, ribbons with
## folded ends for titles, a scroll for the name of an item.

const CREAM := Color("f3e6c8")
const CREAM_DARK := Color("d9c08f")
const RED := Color("b8322a")
const GOLD := Color("e0b23a")


## A card: a cream panel with an ink edge, a thin inner rule, and a little
## fan ornament in each corner.
static func card(ci: CanvasItem, rect: Rect2, fill := CREAM, alpha := 1.0) -> void:
	ci.draw_rect(rect.grow(5.0), Color(Toon.INK, alpha))
	ci.draw_rect(rect, Color(fill, alpha))
	var inner := rect.grow(-9.0)
	var ink := Color(Toon.INK, 0.8 * alpha)
	ci.draw_rect(inner, ink, false, 2.0)
	for corner: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end,
			Vector2(inner.position.x, inner.end.y)]:
		var inward := (inner.get_center() - corner).sign()
		for k in 3:
			var a := PI * 0.25 * (k - 1)
			var dir := Vector2(inward.x * cos(a + PI * 0.25) , inward.y * sin(a + PI * 0.25))
			ci.draw_line(corner, corner + dir.normalized() * 14.0, ink, 2.0, true)
		ci.draw_circle(corner, 3.5, ink)


## A ribbon behind a title: a red band with its ends folded back and cut in
## a notch, ink-edged, a gold rule along it.
static func ribbon(ci: CanvasItem, center: Vector2, width: float, height := 110.0, fill := RED) -> void:
	var half := Vector2(width * 0.5, height * 0.5)
	var tail := height * 0.8
	for side: float in [-1.0, 1.0]:
		# The folded-back ends, lower and darker.
		var x0 := center.x + side * (half.x - 10.0)
		var x1 := center.x + side * (half.x + tail)
		var y := center.y + height * 0.22
		var end := PackedVector2Array([Vector2(x0, y - half.y), Vector2(x1, y - half.y),
				Vector2(x1 - side * tail * 0.35, y), Vector2(x1, y + half.y), Vector2(x0, y + half.y)])
		Toon.polygon(ci, Toon.grown(end, 5.0), Toon.INK)
		Toon.polygon(ci, end, fill.darkened(0.3))
	var band := Rect2(center - half, half * 2.0)
	ci.draw_rect(band.grow(5.0), Toon.INK)
	ci.draw_rect(band, fill)
	ci.draw_line(band.position + Vector2(8, 9), Vector2(band.end.x - 8, band.position.y + 9), GOLD, 3.0)
	ci.draw_line(Vector2(band.position.x + 8, band.end.y - 9), band.end - Vector2(8, 9), GOLD, 3.0)


## A scroll: a cream sheet with rolled ends, for an item's name.
static func scroll(ci: CanvasItem, center: Vector2, width: float, height := 120.0) -> void:
	var rect := Rect2(center - Vector2(width, height) * 0.5, Vector2(width, height))
	ci.draw_rect(rect.grow(5.0), Toon.INK)
	ci.draw_rect(rect, CREAM)
	for side: float in [-1.0, 1.0]:
		var x := rect.position.x if side < 0.0 else rect.end.x
		var roll := Vector2(x, center.y)
		Toon.ball(ci, roll, Vector2(16, height * 0.56), CREAM_DARK, 0, 3 + int(side), 5.0)
		Toon.spot(ci, roll + Vector2(side * 4.0, 0), Vector2(5, height * 0.4), Color(0, 0, 0, 0.18))


## A frame of two ink rules round the whole screen, with a sunburst fan in
## the top corners: the border of a title card.
static func title_card(ci: CanvasItem, size := Vector2(1920, 1080), color := CREAM) -> void:
	for inset: float in [40.0, 56.0]:
		ci.draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), color, false,
				5.0 if inset < 50.0 else 2.0)
	for corner: Vector2 in [Vector2(56, 56), Vector2(size.x - 56, 56), Vector2(size.x - 56, size.y - 56),
			Vector2(56, size.y - 56)]:
		var inward := (size * 0.5 - corner).sign()
		for k in 7:
			var a := PI * 0.5 * k / 6.0
			var dir := Vector2(inward.x * cos(a), inward.y * sin(a))
			ci.draw_line(corner, corner + dir * (60.0 if k % 2 == 0 else 38.0), color, 2.5, true)
