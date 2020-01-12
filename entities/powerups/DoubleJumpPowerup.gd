extends Area2D

export (String) var power_up_key = 'super_strength'

# Called when the node enters the scene tree for the first time.
func _ready():
	connect('body_entered', self, 'body_entered')

func body_entered(body):
	if body.has_method('accept_power_up'):
		body.accept_power_up(power_up_key)
		queue_free()