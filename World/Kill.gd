extends Area

func _ready():
	connect("body_entered", self, "_on_body_enter")

func _on_body_enter(body):
	body.queue_free()
