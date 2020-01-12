extends Node2D

const chunk_size = 80
const tile_size = 16

func get_player_chunk():
	var pos = $Player.position
	var chunk_x = floor(pos.x/(chunk_size*tile_size))
	var chunk_y = floor(pos.y/(chunk_size*tile_size))
	return Vector2(chunk_x, chunk_y)