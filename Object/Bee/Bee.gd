extends RigidBody

const LIFE_FLYING := 10.0
const LIFE_STUCK := 60.0
const SPEED := 10.0

const STATE_FLYING := 0
const STATE_STUCK := 1
const STATE_GRABBING := 2

var life := 0.0
var state = STATE_FLYING

var grab_obj = null
var grab_obj_localpos := Vector3.ZERO

onready var node_rope := $Rope

func _ready():
	apply_central_impulse(global_transform.basis.z * SPEED )

func set_state(new_state):
	state = new_state
	if state == STATE_FLYING:
		mode = RigidBody.MODE_RIGID
	else:
		mode = RigidBody.MODE_STATIC

func get_forward() -> Vector3:
	return global_transform.basis.z.normalized()

func _physics_process(delta):
	life += delta
	if state == STATE_STUCK:
		if life > LIFE_STUCK:
			queue_free()
	elif state == STATE_FLYING:
		if life > LIFE_FLYING:
			queue_free()
	elif state == STATE_GRABBING:
		global_transform.origin += Vector3.UP * delta * 10.0
		var grab_obj_globalpos = grab_obj.to_global(grab_obj_localpos)
		var pos = global_transform.origin
		var diff = (grab_obj_globalpos - pos)
		var is_taught := false
		if diff.length() > 1.5:
			is_taught = true
			global_transform.origin = grab_obj_globalpos + -diff.normalized() * 1.5
			grab_obj_globalpos = grab_obj.to_global(grab_obj_localpos)
			pos = global_transform.origin
			diff = (grab_obj_globalpos - pos)
		var tx := Transform()
		node_rope.scale.z = 0.5 * diff.length() / scale.z
		node_rope.look_at(grab_obj_globalpos, get_viewport().get_camera().global_transform.basis.z)
		var robj := grab_obj as RigidBody
		robj.add_force(-diff.normalized() * 0.5, grab_obj_globalpos - robj.global_transform.origin)

func _on_Area_body_entered(body: PhysicsBody):
	if state == STATE_GRABBING:
		return
	if body is RigidBody:
		node_rope.show()
		set_state(STATE_GRABBING)
		grab_obj = body
		var pos = global_transform.origin
		var body_pos = body.global_transform.origin
		var diff = (body_pos - pos)
		pos += diff.normalized() * diff.length() * 0.05
		grab_obj_localpos = body.to_local(pos)
		body.connect("tree_exited", self, "_on_obj_exit_tree")
	else:
		set_state(STATE_STUCK)
	$CollisionShape.disabled = true
	$Area/CollisionShape.disabled = true

func _on_obj_exit_tree():
	queue_free()
