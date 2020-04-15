extends Spatial

var score := 0

func update_score():
	$CanvasLayer/Label.text = "Score: " + str(score)

func add_score(amt: int):
	score += amt
	update_score()
