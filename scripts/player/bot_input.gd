class_name BotInput
extends PlayerInput
## The demo player: keeps away from enemies and their spit, lines up with the
## nearest enemy along an axis and shoots. Not clever -- it is there to show
## the fight on screenshots and to play the room through in tests.

const KEEP_AWAY := 240.0
const LINED_UP := 34.0


func update(brother: Brother, _delta: float) -> void:
	var room := brother.room
	var me := brother.global_position
	move = Vector2.ZERO
	shoot = Vector2.ZERO
	var away := Vector2.ZERO
	var nearest: Enemy = null
	var nearest_d := INF
	for enemy in room.enemies:
		var d := me - enemy.global_position
		if d.length() < KEEP_AWAY:
			away += d.normalized() * (KEEP_AWAY - d.length()) / KEEP_AWAY
		if enemy.can_be_hit() and d.length() < nearest_d:
			nearest_d = d.length()
			nearest = enemy
	for node in room.actors.get_children():
		var shot := node as Shot
		if shot != null and shot.hostile and shot.global_position.distance_to(me) < 180.0:
			var side := shot.velocity.orthogonal().normalized()
			away += side * signf(side.dot(me - shot.global_position) + 0.01) * 1.5
	var inside := room.floor_rect().grow(-80.0)
	if not inside.has_point(me):
		away += (inside.get_center() - me).normalized() * 0.8
	if nearest == null:
		var home := room.center() + Vector2(0, 120)
		move = ((home - me) / 200.0).limit_length(1.0) + away
		move = move.limit_length(1.0)
		return
	var to := nearest.global_position - me
	if absf(to.y) < LINED_UP:
		shoot = Vector2(signf(to.x), 0)
	elif absf(to.x) < LINED_UP:
		shoot = Vector2(0, signf(to.y))
	# Close the smaller gap to line up, and keep a distance along the other.
	var line_up := Vector2.ZERO
	if absf(to.x) < absf(to.y):
		line_up.x = clampf(to.x / 60.0, -1.0, 1.0)
		if absf(to.y) < 280.0:
			line_up.y = -signf(to.y)
	else:
		line_up.y = clampf(to.y / 60.0, -1.0, 1.0)
		if absf(to.x) < 280.0:
			line_up.x = -signf(to.x)
	move = (line_up + away * 2.0).limit_length(1.0)
