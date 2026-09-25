class_name Ui
extends RefCounted
## Type for the interface. Until a proper 1930s face is chosen, a system
## serif in bold italic: Georgia is on every Mac and every Windows machine
## and has Cyrillic.

static var _font: Font


## Lets go of the font before quitting (see Main._exit_tree).
static func release() -> void:
	_font = null


static func font() -> Font:
	if _font == null:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Georgia", "Times New Roman", "DejaVu Serif", "serif"])
		system.font_weight = 800
		system.font_italic = true
		_font = system
	return _font


## Title lettering: cream letters, a thick ink edge and a drop shadow, the
## way the cards between cartoon scenes were lettered.
static func title(size: int, color := Color("f6e7c1")) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = font()
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
