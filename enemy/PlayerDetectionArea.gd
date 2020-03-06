extends Area2D

var player_detected = false

func _ready():
	connect("body_entered", self, "body_entered")
	connect("body_exited", self, "body_exited")

func body_entered(body):
	if !player_detected and body.name == "Player":
		player_detected = true

func body_exited(body):
	if player_detected and body.name == "Player":
		player_detected = false

func player_detected():
	return player_detected
