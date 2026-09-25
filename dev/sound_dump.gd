extends SceneTree
## Writes every sound of the game to dev/out/sounds/*.wav, to listen to
## outside the game, and says how long making them took.
##
##     godot --headless --path . --script res://dev/sound_dump.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var started := Time.get_ticks_usec()
	var sfx := Sfx.new()
	root.add_child(sfx)
	var took := (Time.get_ticks_usec() - started) / 1000.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://dev/out/sounds"))
	for sound: String in sfx._sounds:
		var wav: AudioStreamWAV = sfx._sounds[sound]
		wav.save_to_wav(ProjectSettings.globalize_path("res://dev/out/sounds/%s.wav" % sound))
		print("   %-12s %.2f s" % [sound, wav.get_length()])
	print("sounds: %d made in %.0f ms" % [sfx._sounds.size(), took])
	quit()
