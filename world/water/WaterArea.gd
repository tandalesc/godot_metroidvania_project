extends Area2D

export var character_bubbles = true

onready var water_body = $MeshInstance2D

func _ready():
	connect('body_entered', self, 'body_entered')
	connect('body_exited', self, 'body_exited')

func body_entered(body):
	if body.has_method('enter_water'):
		body.enter_water(character_bubbles)

func body_exited(body):
	if body.has_method('exit_water'):
		body.exit_water()
