class_name BrotherSelect
extends Node2D
## Choosing a brother, on a title card: both of them side by side, the chosen
## one walking on the spot in a spotlight, his numbers under him.

signal chosen(id: String)

const IDS := ["older", "younger"]
const SPOTS := [Vector2(640, 690), Vector2(1280, 690)]
const CARD := Color("efe0bd")
const CARD_STAIN := Color("d9c08f")
const BAR := Color("c8392b")
## Each number against the most any brother will have, so a bar reads as
## "a lot" or "a little".
const BARS := [
	["Сердца", "hearts", 5.0],
	["Скорость", "speed", 1.4],
	["Урон", "damage", 6.0],
	["Выстрелы", "tears", 4.0],
	["Дальность", "range", 9.0],
]

var index := 0
var _looks: Array[BrotherLook] = []
var _names: Array[Label] = []
var _taken := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)])
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/paper.gdshader")
	material.set_shader_parameter("base", CARD)
	material.set_shader_parameter("stain", CARD_STAIN)
	material.set_shader_parameter("blotch", 320.0)
	material.set_shader_parameter("amount", 0.55)
	paper.material = material
	# Behind this node's own drawing -- the spotlight and the bars -- not
	# over it, as a child normally is.
	paper.show_behind_parent = true
	add_child(paper)
	var frame := _Frame.new()
	add_child(frame)
	var title := Ui.label("БРАТЬЯ", Ui.title(150))
	title.position = Vector2(0, 70)
	add_child(title)
	var sub := Ui.label("кого ведём в подвал?", Ui.text(40, Color("3a2418")), 1920)
	sub.label_settings.outline_size = 0
	sub.position = Vector2(0, 250)
	add_child(sub)
	for i in IDS.size():
		var character := GameData.character(IDS[i])
		var look := BrotherLook.new()
		look.configure(character.get("look", {}))
		look.position = SPOTS[i]
		look.scale = Vector2(2.3, 2.3)
		add_child(look)
		_looks.append(look)
		var name_label := Ui.label(str(character.get("name", IDS[i])), Ui.title(64), 640)
		name_label.position = Vector2((SPOTS[i] as Vector2).x - 320, 720)
		add_child(name_label)
		_names.append(name_label)
		var about := Ui.label(str(character.get("about", "")), Ui.text(30, Color("3a2418")), 640)
		about.label_settings.outline_size = 0
		about.position = Vector2((SPOTS[i] as Vector2).x - 320, 800)
		add_child(about)
	var hint := Ui.label("←  →  выбрать     ·     Пробел — в бой", Ui.text(34), 1920)
	hint.position = Vector2(0, 972)
	add_child(hint)
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if _taken:
		return
	if event.is_action_pressed("p1_left") or event.is_action_pressed("p1_shoot_left"):
		index = 0
		Sfx.play("select", -6.0, 0.0)
		_show()
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p1_shoot_right"):
		index = 1
		Sfx.play("select", -6.0, 0.0)
		_show()
	elif event.is_action_pressed("confirm"):
		pick()


func pick() -> void:
	if _taken:
		return
	_taken = true
	Sfx.play("confirm", -4.0, 0.0)
	chosen.emit(IDS[index])


func select(i: int) -> void:
	index = clampi(i, 0, IDS.size() - 1)
	_show()


func _show() -> void:
	for i in _looks.size():
		var on := i == index
		_looks[i].moving = on
		_looks[i].walk_rate = 0.8
		_looks[i].modulate = Color.WHITE if on else Color(0.62, 0.58, 0.54)
		_names[i].modulate = Color.WHITE if on else Color(1, 1, 1, 0.5)
	queue_redraw()


func _draw() -> void:
	var spot: Vector2 = SPOTS[index]
	# The spotlight on the floor under the chosen brother.
	Toon.spot(self, spot + Vector2(0, 8), Vector2(190, 46), Color(1, 0.96, 0.8, 0.55))
	for i in IDS.size():
		var character := GameData.character(IDS[i])
		var x: float = (SPOTS[i] as Vector2).x - 210
		for b in BARS.size():
			var row: Array = BARS[b]
			var value := float(character.get(row[1], 0.0)) / float(row[2])
			var y := 858.0 + b * 23.0
			draw_string(Ui.font(), Vector2(x, y + 9), str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, 150, 20,
					Color("3a2418"))
			var bar := Rect2(x + 160, y - 6, 250, 16)
			draw_rect(bar.grow(3), Toon.INK)
			draw_rect(bar, Color("e9d6ac"))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(value, 0.0, 1.0), bar.size.y)),
					BAR if i == index else Color("8d7a66"))


## A double ink border round the card, like the frame of an old title card.
class _Frame:
	extends Node2D

	func _draw() -> void:
		for inset: float in [34.0, 50.0]:
			var r := Rect2(inset, inset, 1920 - inset * 2, 1080 - inset * 2)
			var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
			for i in 4:
				Toon.hand_line(self, corners[i], corners[(i + 1) % 4], 6.0 if inset < 40.0 else 3.0,
						int(inset) * 10 + i)
