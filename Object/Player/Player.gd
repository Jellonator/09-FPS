extends KinematicBody

const GRAVITY := -30.0
const SPEED_MAX := 8.0
const SPEED_DASH := 16.0
const SPEED_ACCEL := 32.0
const SPEED_JUMP := 13
const NUM_JUMPS := 1
const BEES_PER_SECOND := 15.0

const scene_bee := preload("res://Object/Bee/Bee.tscn")

onready var node_minigunpos := $PivotY/PivotX/Camera/MinigunPos
onready var node_minigun := $DelayedPivot/beeminigun
onready var node_raycast := $PivotY/PivotX/Camera/RayCast
onready var node_barrel := $DelayedPivot/beeminigun/Barrel
onready var node_pivotx := $PivotY/PivotX
onready var node_pivoty := $PivotY
onready var node_camera := $PivotY/PivotX/Camera
onready var node_pivotdelay := $DelayedPivot
onready var node_shoot := $DelayedPivot/beeminigun/ShootPos

#var gravity := -30.0
#var max_speed := 8.0
var mouse_sensitivity := 0.002
var mouse_range := PI / 2.0 - 1e-4

var velocity := Vector3.ZERO
var jumps_left := NUM_JUMPS
var bee_timer := 0.0
var barrel_speed := 0.0

var health := 3

func update_health():
	$CanvasLayer/Label.text = "Health: " + str(health)

func do_damage(amt: int):
	health = clamp(health - amt, 0, 3)
	update_health()
	if health <= 0:
		get_tree().change_scene("res://Menu/GameOver.tscn")

func get_eyepos() -> Vector3:
	return node_pivotx.global_transform.origin

func rand_quat_uniform() -> Quat:
	# See: http://planning.cs.uiuc.edu/node198.html
	var u1 := rand_range(0.0, 1.0)
	var u2 := rand_range(0.0, 2 * PI)
	var u3 := rand_range(0.0, 2 * PI)
	return Quat(sqrt(1-u1)*sin(u2), sqrt(1-u1)*cos(u2), sqrt(u1)*sin(u3), sqrt(u1)*cos(u3))

func rand_quat(v: float) -> Quat:
	return Quat.IDENTITY.slerp(rand_quat_uniform(), v)

func get_input() -> Vector3:
	var input_dir := Vector3()
	if Input.is_action_pressed("move_forward"):
		input_dir += -node_pivoty.global_transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += node_pivoty.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir += -node_pivoty.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += node_pivoty.global_transform.basis.x
	return (input_dir * Vector3(1, 0, 1)).normalized()

func _ready():
	node_minigunpos.global_transform = node_minigun.global_transform
	node_minigun.transform = Transform.IDENTITY
	node_minigun.rotation.y = PI
	node_pivotdelay.global_transform = node_minigunpos.global_transform
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float):
	velocity += Vector3(0, GRAVITY, 0) * delta
	var vel_target := get_input() * SPEED_MAX
	var vel_up := velocity * Vector3(0, 1, 0)
	var vel_current := velocity - vel_up
	var accel := SPEED_ACCEL * delta
	var diff := vel_target - vel_current
	if diff.length() <= accel:
		vel_current = vel_target
	else:
		vel_current += diff.normalized() * accel
	velocity = vel_up + vel_current
	velocity = move_and_slide(velocity, Vector3.UP, true, 4, 0.7853, false)
	if is_on_floor():
		jumps_left = NUM_JUMPS
	else:
		jumps_left = min(jumps_left, NUM_JUMPS-1)
	handle_delayed_pivot(delta)
	bee_timer -= delta * BEES_PER_SECOND
	if Input.is_action_pressed("action_shoot"):
		barrel_speed = clamp(barrel_speed + delta, 0, 1)
	else:
		barrel_speed = clamp(barrel_speed - delta, 0, 1)
	var barrel_rot_speed = BEES_PER_SECOND * PI * 2.0 / 6.0
	node_barrel.rotation.z += barrel_rot_speed * delta * barrel_speed 
	if bee_timer <= 0 and barrel_speed >= 1.0:
		var bee = scene_bee.instance()
		bee.transform = node_shoot.global_transform
		bee.rotation += rand_quat(0.025).get_euler()
		bee.scale *= 0.1
		get_parent().add_child(bee)
		bee_timer = 1.0
	
func handle_delayed_pivot(delta: float):
	var lookpos
	if node_raycast.is_colliding():
		lookpos = node_raycast.get_collision_point()
	else:
		lookpos = node_raycast.global_transform.xform(node_raycast.cast_to)
	node_minigunpos.look_at(lookpos, node_camera.global_transform.basis.y.normalized())
	var target_tx = node_minigunpos.global_transform
	var tx = node_pivotdelay.global_transform
	tx = tx.interpolate_with(target_tx, delta * 20)
	node_pivotdelay.global_transform = tx

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		node_pivotx.rotate_x(-event.relative.y * mouse_sensitivity)
		node_pivoty.rotate_y(-event.relative.x * mouse_sensitivity)
		node_pivotx.rotation.x = clamp(node_pivotx.rotation.x, -mouse_range, mouse_range)
	elif event.is_action_pressed("action_jump") and jumps_left > 0:
		jumps_left -= 1
		velocity.y = SPEED_JUMP
