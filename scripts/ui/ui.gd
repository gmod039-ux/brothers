class_name Ui
extends RefCounted
## Type for the interface: Oi for titles, fat and round like the lettering
## on the title cards of 1930s cartoons, and Yeseva One for everything
## smaller, a serif that reads at any size. Both from Google Fonts, under
## the Open Font License (fonts/LICENSE.txt).

static var _font: Font
static var _title_font: Font


## Lets go of the fonts before quitting (see Main._exit_tree).
static func release() -> void:
	_font = null
	_title_font = null


## The text face: numbers, hints, lines under titles.
static func font() -> Font:
	if _font == null:
		_font = load("res://fonts/YesevaOne-Regular.ttf")
	return _font


## The title face.
static func title_font() -> Font:
	if _title_font == null:
		_title_font = load("res://fonts/Oi-Regular.ttf")
	return _title_font


## The size, at most [param size], at which [param text] in the title face
## fits in [param width] pixels.
static func fit(text: String, size: int, width: float) -> int:
	var at := title_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if at <= width or at <= 0.0:
		return size
	return maxi(int(size * width / at), 12)


## Title lettering: cream letters, a thick ink edge and a drop shadow, the
## way the cards between cartoon scenes were lettered.
## [param display] false letters it in the text face instead: for names
## that must read at a glance, where the title face's letters are too
## fanciful.
static func title(size: int, color := Color("f6e7c1"), display := true) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = title_font() if display else font()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = maxi(int(size * 0.16), 6)
	settings.outline_color = Toon.INK
	settings.shadow_size = maxi(int(size * 0.1), 4)
	settings.shadow_color = Color(Toon.INK, 0.55)
	settings.shadow_offset = Vector2(size * 0.05, size * 0.06)
	return settings


## Smaller text with a thin edge, for hints and numbers.
static func text(size: int, color := Color("f6e7c1")) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = font()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = maxi(int(size * 0.2), 4)
	settings.outline_color = Toon.INK
	return settings


## A label centred on a line [param width] pixels wide.
static func label(content: String, settings: LabelSettings, width := 1920.0) -> Label:
	var l := Label.new()
	l.text = content
	l.label_settings = settings
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(width, settings.font_size * 1.6)
	l.pivot_offset = l.size * 0.5
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
