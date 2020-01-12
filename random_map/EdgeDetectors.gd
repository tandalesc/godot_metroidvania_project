extends Node2D

const chunk_size = 80
const tile_size = 16
const detector_extent = 50

onready var random_map = get_parent()
onready var detector_bottom = $"WorldEdgeDetector-Bottom"
onready var detector_top = $"WorldEdgeDetector-Top"
onready var detector_left = $"WorldEdgeDetector-Left"
onready var detector_right = $"WorldEdgeDetector-Right"

func recalculate_positions():
	var chunk_offset = random_map.get_player_chunk()*(chunk_size*tile_size)
	detector_bottom.translate(Vector2(chunk_size/2*tile_size, chunk_size*tile_size-detector_extent) + chunk_offset - detector_bottom.position)
	detector_top.translate(Vector2(chunk_size/2*tile_size, detector_extent) + chunk_offset - detector_top.position)
	detector_left.translate(Vector2(50, chunk_size/2*tile_size) + chunk_offset - detector_left.position)
	detector_right.translate(Vector2(chunk_size*tile_size-detector_extent, chunk_size/2*tile_size) + chunk_offset - detector_right.position)