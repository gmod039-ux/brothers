extends Node2D
## Every enemy of the game on one card, with its name: the small ones on
## top, the bosses' helpers in the middle, the bosses below. Not part of the
## game:
##
##     godot --path . -- bestiary shot dev/out/bestiary.png 40
##
## `-- bestiary creeps` instead shows the three everyday enemies floor by
## floor, each at rest, in its warning pose, and knocked out;
## `-- bestiary deep` the boiler room's and the catacombs' own, at rest and
## in each of their moves; `-- bestiary bosses` the bosses: coming on,
## beaten up in phase 2, winding up in phase 3, and knocked out.

const SMALL := ["fly", "walker", "shooter", "pup", "ember", "kitten", "stoker", "valve", "ghost", "skeleton", "bat"]

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
	if OS.get_cmdline_user_args().has("creeps"):
		title.text = "Мелочь по этажам"
		_creeps(rng)
		return
	if OS.get_cmdline_user_args().has("deep"):
		title.text = "Котельная и катакомбы"
		_deep(rng)
		return
	if OS.get_cmdline_user_args().has("bosses"):
		title.text = "Боссы: выход, фаза 2, ярость, нокаут"
		title.label_settings.font_size = 56
		_bosses(rng)
		return
	for i in SMALL.size():
		var kind: String = SMALL[i]
		var enemy := _make(kind, room, rng)
		var row := 0 if i < 6 else 1
		var col := i if i < 6 else i - 6
		var x := 200 + col * 304.0 + row * 152.0
		enemy.scale = Vector2(1.45, 1.45)
		enemy.position = Vector2(x, 290 + row * 270.0)
		if kind in ["stoker", "valve", "skeleton"]:
			enemy.floor_look = 1 if kind != "skeleton" else 2
		_caption(str(GameData.enemies()[kind]["name"]), Vector2(x, 310 + row * 270.0), 28)
	var bosses: Array[Boss] = [Boss.new(), StoveBoss.new(), BaronBoss.new()]
	for i in bosses.size():
		var boss := bosses[i]
		boss.setup_boss(room, rng, 0)
		add_child(boss)
		boss.set_physics_process(false)
		boss.scale = Vector2(0.95, 0.95)
		boss.position = Vector2(400 + i * 560.0, 950)
		_caption(boss.title, Vector2(400 + i * 560.0, 975), 36)


## Rows: basement, boiler room, catacombs. Columns: each creep at rest and
## in its warning pose; the last column knocked out.
func _creeps(rng: RandomNumberGenerator) -> void:
	var floors := ["Подвал", "Котельная", "Катакомбы"]
	var columns := [["fly", ""], ["fly", "buzz"], ["walker", ""], ["walker", "leap"], ["shooter", ""],
			["shooter", "windup"], ["walker", "ko"]]
	for row in 3:
		_caption(floors[row], Vector2(110, 250 + row * 290.0), 30)
		for col in columns.size():
			var kind: String = columns[col][0]
			var pose: String = columns[col][1]
			var enemy := _make(kind, room, rng)
			enemy.floor_look = row
			enemy.scale = Vector2(1.6, 1.6)
			enemy.position = Vector2(330 + col * 235.0, 330 + row * 290.0)
			match pose:
				"buzz":
					(enemy as FlyEnemy).state = "buzz"
				"leap":
					(enemy as WalkerEnemy).state = "leap"
					(enemy as WalkerEnemy)._t = 0.18
				"windup":
					(enemy as ShooterEnemy)._windup = 0.1
				"ko":
					enemy._ko = 0.12
					enemy.set_process(false)
					enemy.queue_redraw()


## The deep floors' own: each in the moves it makes.
func _deep(rng: RandomNumberGenerator) -> void:
	var rows := [
		["Котельная", [["stoker", "walk"], ["stoker", "dig"], ["stoker", "heave"], ["valve", ""], ["valve", "windup"],
				["ember", ""]]],
		["Катакомбы", [["ghost", "drift"], ["ghost", "appear"], ["skeleton", "walk"], ["skeleton", "windup"],
				["skeleton", "pile"], ["bat", "flutter"], ["bat", "squeak"]]],
	]
	for row in rows.size():
		var line: Array = rows[row][1]
		_caption(str(rows[row][0]), Vector2(140, 330 + row * 400.0), 30)
		for col in line.size():
			var kind: String = line[col][0]
			var pose: String = line[col][1]
			var enemy := _make(kind, room, rng)
			enemy.floor_look = row + 1
			enemy.scale = Vector2(1.7, 1.7)
			enemy.position = Vector2(400 + col * 225.0, 450 + row * 400.0)
			if pose != "":
				enemy.set("state", pose)
			if pose == "windup" and enemy is ValveEnemy:
				enemy.set("_windup", 0.3)
			if pose == "pile" or pose == "appear":
				enemy.set("_t", 0.2)


func _bosses(rng: RandomNumberGenerator) -> void:
	var furious := ["charge_windup", "ring_windup", "ring_windup"]
	for row in 3:
		for col in 4:
			var boss: Boss
			match row:
				0:
					boss = Boss.new()
				1:
					boss = StoveBoss.new()
				_:
					boss = BaronBoss.new()
			boss.setup_boss(room, rng, row)
			add_child(boss)
			boss.set_physics_process(false)
			boss.scale = Vector2(0.72, 0.72)
			boss.position = Vector2(300 + col * 440.0, 330 + row * 305.0)
			match col:
				1:
					boss.phase = 2
					boss.state = "walk"
				2:
					boss.phase = 3
					boss.state = furious[row]
					boss._t = 0.5
				3:
					boss.phase = 3
					boss.state = "walk"
					boss._ko = Boss.SHAKE_TIME + Boss.FALL_TIME + 0.5
					boss.set_process(false)
					boss.queue_redraw()
		_caption(["Бруно", "Пыхтун", "Барон"][row], Vector2(90, 280 + row * 305.0), 30)


func _make(kind: String, room: Room, rng: RandomNumberGenerator) -> Enemy:
	var enemy := Waves.make(kind)
	enemy.setup(kind, room, rng)
	enemy._spawn = 0.0
	add_child(enemy)
	# After it is in: a node with _physics_process switches it on as it
	# enters the tree.
	enemy.set_physics_process(false)
	return enemy


func _caption(text: String, at: Vector2, size: int) -> void:
	var label := Ui.label(text, Ui.title(size, Color("f6e7c1"), false), 400)
	label.position = at - Vector2(200, 0)
	add_child(label)
