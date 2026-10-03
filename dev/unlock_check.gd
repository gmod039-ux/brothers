extends SceneTree
## What is open and what is earned: the first lot of items is there from the
## start and the rest is not; a deed opens what it says, once, and is
## written down; only a real game counts deeds; the bot sees everything; a
## chain of three kegs and a jackpot are deeds the run reports.
##
##     godot --headless --fixed-fps 60 --path . --script res://dev/unlock_check.gd
##
## Writes its records to a file of its own and removes it after: a check
## run on someone's own machine never touches theirs.

const SCRATCH := "user://records_check.cfg"

var _failures := 0
var _checks := 0


func _initialize() -> void:
	Controls.setup()
	_run()


func _run() -> void:
	await process_frame
	Records.path = SCRATCH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	Records.deeds.clear()
	_data()
	await _deeds()
	await _pool()
	await _chain_and_jackpot()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	print("unlock: %d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if ok:
		print("   ok  " + what)
	else:
		_failures += 1
		printerr("FAILED: " + what)


## Every deed opens things that exist, and each thing has one deed.
func _data() -> void:
	var items := GameData.items()
	var seen := {}
	for deed: String in Unlocks.deeds():
		var d: Dictionary = Unlocks.deeds()[deed]
		_check(d.has("name") and d.has("hint") and not (d.get("opens", []) as Array).is_empty(),
				"deed %s has a name, a hint and something to open" % deed)
		for id: String in d.get("opens", []):
			_check(items.has(id) or id.begins_with("@"), "deed %s opens %s, which exists" % [deed, id])
			_check(not seen.has(id), "%s is opened by one deed only" % id)
			seen[id] = true
	_check(seen.has("@evil") and seen.has("@girls"), "a deed opens the evil mode and the girls")


func _deeds() -> void:
	Unlocks.everything = false
	Unlocks.recording = true
	var open_at_start := 0
	var trinkets_at_start := 0
	for id: String in GameData.items():
		if Unlocks.is_open(id):
			if GameData.items()[id].get("trinket", false):
				trinkets_at_start += 1
			else:
				open_at_start += 1
	_check(open_at_start == 21, "21 items are open from the start (%d)" % open_at_start)
	_check(trinkets_at_start == 6, "and 6 trinkets (%d)" % trinkets_at_start)
	_check(Unlocks.is_open("pepper") and not Unlocks.is_open("chick"), "the pepper is open, the chick is not")
	_check(not Unlocks.is_open("@evil"), "no evil mode before the Baron is beaten")
	var opened := Unlocks.achieve("miniboss")
	_check(opened == ["chick"], "beating a mini-boss opens the chick (%s)" % [opened])
	_check(Unlocks.is_open("chick") and Unlocks.this_run.has("miniboss"), "it is open now, and on this run's list")
	_check(Unlocks.achieve("miniboss").is_empty(), "a deed opens things once")
	_check(Unlocks.achieve("no_such_deed").is_empty(), "a deed that does not exist opens nothing")
	Records.deeds.clear()
	Records.load_file()
	_check(Records.deeds.has("miniboss"), "the deed is written down for next time")
	Unlocks.recording = false
	_check(Unlocks.achieve("secret").is_empty() and not Unlocks.is_open("glasses"), "outside a real game no deed counts")
	Unlocks.recording = true
	var named := Unlocks.names(["@evil", "pepper"])
	_check(named.size() == 2 and named[0] == "злой режим" and named[1] == "Жгучий перец", "what was opened has names")
	Unlocks.everything = true
	_check(Unlocks.is_open("glasses") and Unlocks.is_open("@girls"), "with everything open, everything is")
	Unlocks.everything = false
	await process_frame


## A run deals only what is open.
func _pool() -> void:
	var camera := Camera2D.new()
	root.add_child(camera)
	var run := Run.new()
	root.add_child(run)
	var brother := Brother.new()
	brother.setup("older", null, PlayerInput.new())
	brother.god = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	run.begin(rng, camera, [brother] as Array[Brother])
	await process_frame
	var locked := 0
	for id in run.pool:
		if not Unlocks.is_open(id):
			locked += 1
	_check(locked == 0 and run.pool.has("chick") and not run.pool.has("glasses"),
			"a run's items are the open ones only (%d in the pool)" % run.pool.size())
	run.queue_free()
	camera.queue_free()
	Unlocks.everything = true
	await process_frame


## Three kegs in one chain, and three alike on the reels, are deeds.
func _chain_and_jackpot() -> void:
	var room := Room.new()
	root.add_child(room)
	room.build(PackedStringArray([".............", ".............", ".............", "....xxx......",
			".............", ".............", "............."]), 1)
	var chained := [0]
	room.barrels_chained.connect(func() -> void: chained[0] += 1)
	await process_frame
	room.blow(Vector2i(4, 3))
	for i in 90:
		await physics_frame
	_check(chained[0] == 1, "three kegs going up one after another are a chain (%d)" % chained[0])
	var machine := SlotMachine.new()
	machine.room = room
	room.actors.add_child(machine)
	var jackpots := [0]
	machine.jackpot.connect(func() -> void: jackpots[0] += 1)
	machine._reels = [2, 2, 2]
	machine._pay()
	machine._reels = [2, 2, 3]
	machine._pay()
	_check(jackpots[0] == 1, "three alike is a jackpot, two alike is not")
	room.queue_free()
	await process_frame
