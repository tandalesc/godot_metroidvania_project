extends Area2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	connect('body_entered', self, 'body_entered')

func body_entered(body):
	if body.has_method('accept_power_up'):
		body.accept_power_up('double_jump')
		queue_free()