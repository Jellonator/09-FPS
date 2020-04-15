extends Spatial

var life := 0.0

func _physics_process(delta):
	life += delta
	if life > 0.5:
		queue_free()

func _on_Area_body_entered(body):
	if life < 0.1 and body.has_method("do_damage"):
		body.do_damage(1)
