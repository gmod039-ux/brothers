extends Node
## Prints where the demo bot is and what is left in its room every few
## seconds: for finding out why a run got stuck. Add with `-- watch`.

func _ready() -> void:
	_loop()


func _loop() -> void:
	while true:
		await get_tree().create_timer(10.0, false).timeout
		var main := get_parent()
		var brother := main.get("brother") as Brother
		if brother == null or brother.room == null:
			continue
		var room := brother.room
		var left := []
		for enemy in room.enemies:
			left.append("%s@%s%s" % [enemy.kind, room.tile_at(enemy.global_position),
					"" if enemy.can_be_hit() else "(air)"])
		print("   watch: bot at %s hp %d, room %s, enemies %s" % [room.tile_at(brother.global_position),
				brother.hp, room.cell, left])
