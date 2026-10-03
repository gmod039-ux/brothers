extends SceneTree
## The story's cartoon, played through with nobody watching: the opening,
## the scenes between the floors and the ending run shot by shot to their
## end, every scene of them shows,
## each is over when it should be, and the cast of one scene is gone before
## the next. Then the opening again, a key pressed in every shot, which must
## cut each one short -- and Esc, which must end it all at once.
##
##     godot --headless --fixed-fps 60 --path . --script res://dev/story_check.gd

var _failures := 0
var _checks := 0


func _initialize() -> void:
	Controls.setup()
	_run()


func _run() -> void:
	await process_frame
	await _plays_through(Story.OPENING, "opening")
	await _plays_through(Story.ENDING, "ending")
	await _plays_through(Story.interlude(0), "scene before the boiler room")
	await _plays_through(Story.interlude(1), "scene before the catacombs")
	_check(Story.interlude(2).is_empty(), "no scene after the last floor but the ending")
	_check(Story.so_far().size() == Story.OPENING.size() + Story.interlude(0).size()
			+ Story.interlude(1).size() + 2, "the story so far is the opening and both scenes, each after a card")
	# The girls' run: their cards, and the story turned about.
	await _plays_through(Story.GIRLS_TURN, "girls' cards")
	await _plays_through(Story.interlude(1), "girls' scene before the catacombs", true)
	await _plays_through(Story.ENDING, "girls' ending", true)
	await _turned_cast()
	await _skips_shot_by_shot()
	await _escapes()
	print("%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAILED: " + what)


func _start(shots: Array[Dictionary], turned := false) -> Story:
	var story := Story.new()
	story.shots = shots
	if turned:
		story.turn_about()
	root.add_child(story)
	return story


## Every scene shows and lasts its seconds; the whole takes about as long as
## its shots add up to.
func _plays_through(shots: Array[Dictionary], name: String, turned := false) -> void:
	var story := _start(shots, turned)
	var done := [false]
	story.finished.connect(func() -> void: done[0] = true)
	var seen := {}
	var most_cast := 0
	var frames := 0
	var longest := 0.0
	for shot in shots:
		longest += float(shot.get("seconds", 6.0))
	while not done[0] and frames < int(longest * 60.0) + 600:
		await process_frame
		frames += 1
		if is_instance_valid(story):
			seen[story.call("_kind")] = true
			most_cast = maxi(most_cast, (story.get("_cast") as Array).size())
	_check(done[0], "the %s comes to its end" % name)
	for shot in shots:
		var kind := str(shot.get("scene", "card" if shot.has("card") else "end"))
		_check(seen.has(kind), "the %s shows its %s" % [name, kind])
	var seconds := frames / 60.0
	_check(seconds > longest * 0.6, "the %s takes its time (%.1f s)" % [name, seconds])
	_check(most_cast <= 12, "the %s has at most a dozen on stage (%d)" % [name, most_cast])
	await process_frame
	_check(not is_instance_valid(story), "the %s is gone once over" % name)
	print("%s: %.1f s, %d shots" % [name, seconds, shots.size()])


## Turned about, the girls run in and the brothers are the ones in the cage.
func _turned_cast() -> void:
	var story := _start(Story.ENDING, true)
	var frames := 0
	while is_instance_valid(story) and story.call("_kind") != "reunion" and frames < 900:
		await process_frame
		frames += 1
	var rescuer: BrotherLook = story.get("_older") if is_instance_valid(story) else null
	var caged: Array = story.get("_girls") if is_instance_valid(story) else []
	_check(rescuer != null and rescuer.top == "bow" and caged.size() == 2 and (caged[0] as BrotherLook).top == "quiff",
			"in the girls' ending Роза runs in and the older brother is in the cage")
	if is_instance_valid(story):
		story.queue_free()
	await process_frame


## Enter in each shot cuts it short.
func _skips_shot_by_shot() -> void:
	var story := _start(Story.OPENING)
	var done := [false]
	story.finished.connect(func() -> void: done[0] = true)
	var frames := 0
	while not done[0] and frames < 60 * 30:
		for _i in 20:
			await process_frame
			frames += 1
		await _press("confirm")
	_check(done[0], "Enter in every shot gets through the opening")
	_check(frames < Story.OPENING.size() * 30, "each Enter cuts its shot short (%d frames)" % frames)


## Esc ends the lot.
func _escapes() -> void:
	var story := _start(Story.OPENING)
	var done := [0]
	story.finished.connect(func() -> void: done[0] += 1)
	for _i in 200:
		await process_frame
	await _press("menu_back")
	for _i in 10:
		await process_frame
	_check(done[0] == 1, "Esc ends the opening, once")


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
