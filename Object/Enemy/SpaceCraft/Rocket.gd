extends RigidBody

const SCENE_EXPLOSION := preload("res://Object/Explosion/Explosion.tscn")

func get_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return null
	else:
		return players[0]

func _integrate_forces(forces: PhysicsDirectBodyState):
	var player = get_player()
	if player != null:
		var ppos := player.get_eyepos() as Vector3
		var pos := global_transform.origin
		var diff = (pos - ppos)
		var target_pos = ppos
		var force = 50.0
		var targetv = force * (target_pos - pos).normalized()
		forces.linear_velocity = forces.linear_velocity.move_toward(\
				targetv, forces.step * 8)
		var newtx = global_transform.looking_at(global_transform.origin + diff, Vector3.UP)
		var oldrot = Quat(global_transform.basis.get_euler())
		var newrot = Quat(newtx.basis.get_euler())
		var rotdiff = newrot * oldrot.inverse()
		forces.angular_velocity = forces.angular_velocity.move_toward(\
				rotdiff.get_euler() * 5, forces.step * 10)
	forces.integrate_forces()

func _physics_process(delta):
	var p = get_player()
	if p == null:
		add_central_force(global_transform.basis.z.normalized() * 4)

func _on_Area_body_entered(body):
	if not body.is_in_group("bee") and not get_collision_exceptions().has(body):
		var e = SCENE_EXPLOSION.instance()
		e.transform.origin = global_transform.origin
		get_parent().add_child(e)
		queue_free()
