class_name Album
extends Node2D
## The album: what has been found, what has been done, and the numbers of
## every run so far, on three pages of a scrapbook. ← → turn the pages, Esc
## (Start, B) closes it.
##   Предметы   every item and trinket: found ones in colour with their
##              names; open but not yet found ones as an ink silhouette;
##              locked ones as a silhouette with a padlock and what opens
##              them
##   Подвиги    every deed, a gold star for the ones done, and what each
##              opens
##   Счёт       runs and ways out, brother by brother, the quickest time,
##              the deepest floor, knockouts, bosses, secret rooms...

signal closed

const PAGES := ["Предметы", "Подвиги", "Счёт"]
const COLS := 10
const INK_BROWN := Color("3a2418")
const SOFT := Color("6a4a30")
const RED := Color("9a2f24")
const GOLD := Color("e0b23a")

var page := 0

var _nav: MenuNav
var _page_root: Node2D
var _frame_node: Node2D
var _title: Label
var _clock := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_nav = MenuNav.new()
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)])
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/paper.gdshader")
	material.set_shader_parameter("base", BrotherSelect.CARD)
	material.set_shader_parameter("stain", BrotherSelect.CARD_STAIN)
	material.set_shader_parameter("blotch", 320.0)
	material.set_shader_parameter("amount", 0.5)
	paper.material = material
	add_child(paper)
	_frame_node = Node2D.new()
	_frame_node.draw.connect(func() -> void: _frame(_frame_node))
	add_child(_frame_node)
	_title = Ui.label("", Ui.title(64))
	_title.position = Vector2(0, 12)
	add_child(_title)
	_page_root = Node2D.new()
	add_child(_page_root)
	_show()


## The album has every key while it is open, but for the fullscreen one.
func _input(event: InputEvent) -> void:
	if event.is_action("fullscreen"):
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_clock += delta
	var step := _nav.step(delta)
	if step.x != 0:
		page = wrapi(page + step.x, 0, PAGES.size())
		Sfx.play("select", -6.0, 0.0)
		_show()
	if _nav.pressed("pause") or _nav.pressed("menu_back") or _nav.pressed("confirm"):
		Sfx.play("select", -6.0, 0.0)
		closed.emit()
		queue_free()


func _show() -> void:
	for child in _page_root.get_children():
		child.queue_free()
	_title.text = "Альбом · %s" % PAGES[page]
	match page:
		0:
			_items()
		1:
			_deeds()
		_:
			_numbers()
	_frame_node.queue_redraw()


## The page's border, the dots for the pages and the hint.
func _frame(ci: Node2D) -> void:
	Frames.double_rule(ci, Rect2(24, 96, 1872, 920), INK_BROWN)
	for i in PAGES.size():
		var at := Vector2(960 + (i - 1) * 40.0, 1042)
		if i == page:
			Toon.blob(ci, at, Vector2(10, 10), INK_BROWN, 0, i, 2.5)
		else:
			Toon.spot(ci, at, Vector2(8, 8), Color(INK_BROWN, 0.25))
	ci.draw_string(Ui.font(), Vector2(0, 1050), "← → листать   ·   Esc — назад", HORIZONTAL_ALIGNMENT_RIGHT, 1860, 22,
			SOFT)


## A small note under a picture, wrapped onto a second line if it must be.
func _note(text: String, size: int, color: Color, at: Vector2, width: float) -> Label:
	var style := Ui.text(size, color)
	style.outline_size = 0
	style.line_spacing = -4.0
	# Wrapping set before anything else: a label sized to one long line
	# first keeps that width.
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.label_settings = style
	label.custom_minimum_size = Vector2(width, 0)
	label.size = Vector2(width, size * 3.0)
	label.text = text
	label.position = at
	_page_root.add_child(label)
	return label


func _label(text: String, size: int, color: Color, at: Vector2, width: float,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var style := Ui.text(size, color)
	style.outline_size = 0
	var fitted := Ui.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if fitted > width - 4.0:
		style.font_size = maxi(int(size * (width - 4.0) / fitted), 10)
	var label := Ui.label(text, style, width)
	label.horizontal_alignment = align
	label.position = at
	_page_root.add_child(label)
	return label


# --- items -----------------------------------------------------------------------


## Ordered the way the item sheet is: by themselves, for the hands, trinkets.
static func ordered_items() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(GameData.items().keys())
	var rank := func(id: String) -> int:
		var item: Dictionary = GameData.items()[id]
		return 2 if item.get("trinket", false) else (1 if item.has("active") else 0)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra: int = rank.call(a)
		var rb: int = rank.call(b)
		return ra < rb if ra != rb else a < b)
	return ids


func _items() -> void:
	var ids := ordered_items()
	var found := 0
	for i in ids.size():
		var id: String = ids[i]
		var item: Dictionary = GameData.items()[id]
		var at := Vector2(100 + (i % COLS) * 191.0, 168 + (i / COLS) * 168.0)
		var seen := Records.found.has(id) or Unlocks.everything
		var open := Unlocks.is_open(id)
		if seen:
			found += 1
		var disc := Node2D.new()
		disc.position = at
		var tint := Color(1, 1, 1, 0.35) if seen else Color(INK_BROWN, 0.12)
		disc.draw.connect(func() -> void: Toon.blob(disc, Vector2.ZERO, Vector2(40, 40), tint, 0, i, 3.0))
		_page_root.add_child(disc)
		var icon := Node2D.new()
		icon.position = at
		icon.draw.connect(func() -> void: ItemIcon.draw(icon, id, Vector2.ZERO, 58.0, 0))
		if not seen:
			# A silhouette in ink.
			icon.modulate = Color(0.16, 0.1, 0.07, 0.85)
		_page_root.add_child(icon)
		if not open:
			var lock := Node2D.new()
			lock.position = at + Vector2(24, 22)
			lock.draw.connect(func() -> void:
				lock.draw_arc(Vector2(0, -9), 7.0, PI, TAU, 10, Toon.INK, 4.0, true)
				Toon.box(lock, Vector2.ZERO, Vector2(10, 8), GOLD, 0, 3, 3.0)
				Toon.spot(lock, Vector2(0, -1), Vector2(1.6, 2.4), Toon.INK))
			_page_root.add_child(lock)
		var name := str(item.get("name", id)) if seen else "?"
		_label(name, 20, INK_BROWN if seen else SOFT, at + Vector2(-92, 40), 184)
		var note := ""
		if seen:
			note = str(item.get("text", ""))
		elif not open:
			var deed := Unlocks.opener(id)
			note = str(Unlocks.deeds().get(deed, {}).get("hint", ""))
		else:
			note = "ещё не найден"
		_note(note, 15, RED if not open else SOFT, at + Vector2(-92, 62), 184)
	_label("найдено %d из %d" % [found, ids.size()], 26, INK_BROWN, Vector2(0, 950), 1920)


# --- deeds -----------------------------------------------------------------------


func _deeds() -> void:
	var all := Unlocks.deeds()
	var ids: Array = all.keys()
	var done := 0
	for i in ids.size():
		var deed: String = ids[i]
		var d: Dictionary = all[deed]
		var col := i % 2
		var row := i / 2
		var at := Vector2(110 + col * 900.0, 150 + row * 100.0)
		var is_done := Unlocks.is_done(deed)
		if is_done:
			done += 1
		var star := Node2D.new()
		star.position = at + Vector2(0, 30)
		star.draw.connect(func() -> void:
			if is_done:
				Toon.star(star, Vector2.ZERO, 22.0, 0.0, GOLD)
			else:
				Toon.blob(star, Vector2.ZERO, Vector2(18, 18), Color(INK_BROWN, 0.12), 0, i, 3.0))
		_page_root.add_child(star)
		_label(str(d.get("name", deed)), 28, INK_BROWN if is_done else SOFT, at + Vector2(40, 2), 520,
				HORIZONTAL_ALIGNMENT_LEFT)
		_label(str(d.get("hint", "")), 18, SOFT, at + Vector2(40, 38), 520, HORIZONTAL_ALIGNMENT_LEFT)
		# What it opens, small pictures in a row.
		var opens: Array = d.get("opens", [])
		for k in opens.size():
			var id: String = opens[k]
			var pic := Node2D.new()
			pic.position = at + Vector2(600 + k * 70.0, 30)
			if id.begins_with("@"):
				# The evil mode a skull, the girls a heart.
				pic.draw.connect(func() -> void:
					if id == "@evil":
						Toon.blob(pic, Vector2.ZERO, Vector2(30, 30), Color(RED, 0.9), 0, k, 3.0)
						Toon.ball(pic, Vector2(0, -3), Vector2(13, 12), Color("efe6cf"), 0, k + 1, 2.5)
						for sx: float in [-1.0, 1.0]:
							Toon.spot(pic, Vector2(sx * 5.0, -4.0), Vector2(3, 3.5), Toon.INK)
						Toon.box(pic, Vector2(0, 8), Vector2(7, 4), Color("efe6cf"), 0, k + 2, 2.0)
					else:
						Toon.blob(pic, Vector2.ZERO, Vector2(30, 30), Color("f3d6dc"), 0, k, 3.0)
						Toon.heart(pic, Vector2(0, 2), 30.0, 2, Color("c8392b"), Color("c8392b")))
				if not is_done:
					pic.modulate = Color(1, 1, 1, 0.45)
			else:
				pic.draw.connect(func() -> void: ItemIcon.draw(pic, id, Vector2.ZERO, 44.0, 0))
				if not is_done:
					pic.modulate = Color(0.16, 0.1, 0.07, 0.6)
			_page_root.add_child(pic)
	_label("подвигов: %d из %d" % [done, ids.size()], 26, INK_BROWN, Vector2(0, 950), 1920)


# --- the numbers -----------------------------------------------------------------


func _numbers() -> void:
	var rows: Array = [
		["забегов", str(Records.runs)],
		["выбрались", str(Records.wins)],
		["быстрее всех", Records.clock(Records.best_time) if Records.best_time > 0.0 else "—"],
		["дальше всех", "этаж %d" % maxi(Records.deepest, 1) if Records.runs > 0 else "—"],
		["нокаутов", str(Records.knockouts)],
		["боссов побито", str(Records.bosses)],
		["мини-боссов", str(Records.count("minibosses"))],
		["тайников найдено", str(Records.count("secrets"))],
		["джекпотов", str(Records.count("jackpots"))],
		["предметов найдено", "%d из %d" % [Records.found.size(), GameData.items().size()]],
		["подвигов", "%d из %d" % [Records.deeds.size(), Unlocks.deeds().size()]],
	]
	for i in rows.size():
		var y := 150.0 + i * 66.0
		_label(str(rows[i][0]), 32, SOFT, Vector2(260, y), 600, HORIZONTAL_ALIGNMENT_RIGHT)
		_label(str(rows[i][1]), 36, INK_BROWN, Vector2(900, y - 2), 400, HORIZONTAL_ALIGNMENT_LEFT)
	# Brother by brother, each with his figure.
	var who: Array = GameData.characters().keys()
	for i in who.size():
		var id: String = who[i]
		var at := Vector2(1440 + (i % 2) * 260.0, 470 + (i / 2) * 380.0)
		var figure := BrotherLook.new()
		figure.configure(GameData.character(id).get("look", {}))
		figure.scale = Vector2(1.3, 1.3)
		figure.position = at
		_page_root.add_child(figure)
		_label(str(GameData.character(id).get("name", id)), 30, INK_BROWN, at + Vector2(-120, 16), 240)
		_label("забегов %d · побед %d" % [Records.count("runs_" + id), Records.count("wins_" + id)], 20, SOFT,
				at + Vector2(-120, 56), 240)
