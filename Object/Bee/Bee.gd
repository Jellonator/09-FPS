extends KinematicBody

const LIFE_FLYING := 10.0
const LIFE_STUCK := 60.0
const SPEED := 100.0

var life := 0.0
var is_stuck = false

func _ready():
	move_and_collide(get_forward() * rand_range(0.0, 1.0/60.0) * SPEED)

func get_forward() -> Vector3:
	return global_transform.basis.z.normalized()

func _physics_process(delta):
	life += delta
	if is_stuck:
		if life > LIFE_STUCK:
			queue_free()
	else:
		if life > LIFE_FLYING:
			queue_free()
		if move_and_collide(get_forward() * delta * SPEED) != null:
			is_stuck = true
