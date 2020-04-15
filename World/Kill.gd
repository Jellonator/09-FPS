extends Area

func _ready():
	connect("body_entered", self, "_on_body_enter")

func _on_body_enter(body):
	print(body)
	if body.has_method("do_kill"):
		body.do_kill()
	else:
		body.queue_free()
