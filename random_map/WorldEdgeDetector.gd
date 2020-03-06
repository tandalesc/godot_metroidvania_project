extends Area2D

export (float, -1.0, 1.0) var expand_dir_x = 0.0
export (float, -1.0, 1.0) var expand_dir_y = 1.0

onready var tile_map = $"../../RandomizedTileMap"
onready var edge_detectors = $".."
onready var expand_dir = Vector2(expand_dir_x, expand_dir_y)

func _ready():
	connect('body_entered', self, 'body_entered')
	connect('body_exited', self, 'body_exited')

func body_entered(body):
	if body.name == 'Player':
		body.pause_movement=true
		tile_map.extend_if_needed(expand_dir)
		body.pause_movement=false

func body_exited(body):
	if body.name == 'Player':
		edge_detectors.recalculate_positions()
