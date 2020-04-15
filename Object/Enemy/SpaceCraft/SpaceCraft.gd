extends RigidBody

const SCENE_ROCKET := preload("res://Object/Enemy/SpaceCraft/Rocket.tscn")
const STATE_IDLE := 0
const STATE_ATTACKING := 1
var state := STATE_IDLE

const TARGET_DISTANCE_MIN := 10.0
const TARGET_DISTANCE_MAX := 11.0
const MAX_PLAYER_DISTANCE := 50.0

var tangent_speed := 0.0
var next_tangent_timer := 0.0

var shoot_timer := 0.0

func get_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return null
	else:
		return players[0]

func spawn_rocket(o):
	var r = SCENE_ROCKET.instance()
	r.transform = o.global_transform
	r.add_collision_exception_with(self)
	get_parent().add_child(r)

func _integrate_forces(forces: PhysicsDirectBodyState):
	var player = get_player()
	if player != null and state == STATE_ATTACKING:
		var ppos := player.get_eyepos() as Vector3
		var pos := global_transform.origin
		var diff = (pos - ppos)
		var target_pos
		var force = 0.0
		if diff.length() < TARGET_DISTANCE_MIN:
			target_pos = ppos + diff.normalized() * TARGET_DISTANCE_MIN
			force = TARGET_DISTANCE_MIN -  diff.length()
		elif diff.length() > TARGET_DISTANCE_MAX:
			target_pos = ppos + diff.normalized() * TARGET_DISTANCE_MAX
			force = diff.length() - TARGET_DISTANCE_MAX
		if target_pos != null:
			target_pos.y = ppos.y + 1.0
			force = clamp(force * 30, 1, 25)
			var targetv = force * (target_pos - pos).normalized()
			forces.linear_velocity = forces.linear_velocity.move_toward(\
					targetv, forces.step * 5)
		var tangent = Vector3.UP.cross(diff.normalized())
		forces.linear_velocity += tangent_speed * tangent * forces.step
		var newtx = global_transform.looking_at(ppos, Vector3.UP)
		var oldrot = Quat(global_transform.basis.get_euler())
		var newrot = Quat(newtx.basis.get_euler())
		var rotdiff = newrot * oldrot.inverse()
		forces.angular_velocity = forces.angular_velocity.move_toward(\
				rotdiff.get_euler() * 5, forces.step * 5)
	forces.integrate_forces()

func _physics_process(delta):
	next_tangent_timer -= delta
	if next_tangent_timer <= 0.0:
		next_tangent_timer = rand_range(0.7, 2)
		tangent_speed = rand_range(-3, 3)
	if state == STATE_IDLE:
		gravity_scale = 1
	else:
		gravity_scale = 0
	if state == STATE_ATTACKING:
		var p = get_player()
		if p == null:
			state = STATE_IDLE
		else:
			var dis = p.get_eyepos().distance_to(global_transform.origin)
			if dis > MAX_PLAYER_DISTANCE:
				state = STATE_IDLE
			else:
				var p_shoot_timer := shoot_timer
				shoot_timer += delta
				if p_shoot_timer < 3.0 and shoot_timer >= 3.0:
					$RocketLeft.show()
				if p_shoot_timer < 5.0 and shoot_timer >= 5.0:
					$RocketLeft.hide()
					spawn_rocket($RocketLeft)
				if p_shoot_timer < 8.0 and shoot_timer >= 8.0:
					$RocketRight.show()
				if p_shoot_timer < 10.0 and shoot_timer >= 10.0:
					$RocketRight.hide()
					spawn_rocket($RocketRight)
					shoot_timer = 0.0

func _on_AreaActivate_body_entered(body):
	state = STATE_ATTACKING

func do_kill():
	get_owner().add_score(100)
	queue_free()
