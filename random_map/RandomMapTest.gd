extends Node2D

export (int, 16, 512) var chunk_size = 80

onready var tile_map = $RandomizedTileMap
onready var edge_detectors = $EdgeDetectors

const tile_size = 16

func _ready():
	tile_map.chunk_size = chunk_size
	edge_detectors.chunk_size = chunk_size

func get_player_chunk():
	var pos = $Player.position
	var chunk_x = floor(pos.x/(chunk_size*tile_size))
	var chunk_y = floor(pos.y/(chunk_size*tile_size))
	return Vector2(chunk_x, chunk_y)