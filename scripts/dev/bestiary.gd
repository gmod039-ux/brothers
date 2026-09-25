extends Node2D
## Every enemy of the game on one card, with its name: the small ones on
## top, the bosses' helpers in the middle, the bosses below. Not part of the
## game:
##
##     godot --path . -- bestiary shot dev/out/bestiary.png 40

const SMALL := ["fly", "walker", "shooter", "pup", "ember", "kitten"]

var room: Room


func _exit_tree() -> void:
	if room != null:
		room.free()


func _ready() -> void:
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
	var title := Ui.label("Злодеи и их банда", Ui.title(72))
	title.position = Vector2(0, 10)
	add_child(title)
	# A room that is never built: enemies want one to look for brothers in.
	room = Room.new()
	var rng := RandomNumberGenerator.new()
	for i in SMALL.size():
		var kind: String = SMALL[i]
		var enemy := _make(kind, room, rng)
		enemy.scale = Vector2(1.7, 1.7)
		enemy.position = Vector2(200 + i * 304.0, 400)
		_caption(str(GameData.enemies()[kind]["name"]), Vector2(200 + i * 304.0, 430), 30)
	var bosses: Array[Boss] = [Boss.new(), StoveBoss.new(), BaronBoss.new()]
	for i in bosses.size():
		var boss := bosses[i]
		boss.setup_boss(room, rng, 0)
		add_child(boss)
		boss.set_physics_process(false)
		boss.scale = Vector2(1.1, 1.1)
		boss.position = Vector2(400 + i * 560.0, 900)
		_caption(boss.title, Vector2(400 + i * 560.0, 930), 40)


func _make(kind: String, room: Room, rng: RandomNumberGenerator) -> Enemy:
	var enemy: Enemy
	match kind:
		"fly":
			enemy = FlyEnemy.new()
		"walker":
			enemy = WalkerEnemy.new()
		"shooter":
			enemy = ShooterEnemy.new()
		"pup":
			enemy = PupEnemy.new()
		"ember":
			enemy = EmberEnemy.new()
		_:
			enemy = KittenEnemy.new()
	enemy.setup(kind, room, rng)
	enemy._spawn = 0.0
	add_child(enemy)
	# After it is in: a node with _physics_process switches it on as it
	# enters the tree.
	enemy.set_physics_process(false)
	return enemy


func _caption(text: String, at: Vector2, size: int) -> void:
	var label := Ui.label(text, Ui.title(size), 400)
	label.position = at - Vector2(200, 0)
	add_child(label)
