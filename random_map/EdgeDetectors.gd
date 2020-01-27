extends Node2D

const tile_size = 16

onready var random_map = get_parent()
onready var chunk_size = random_map.chunk_size

onready var detector_bottom = $"WorldEdgeDetector-Bottom"
onready var detector_bottom_shape = $"WorldEdgeDetector-Bottom/CollisionShape2D".shape
onready var detector_top = $"WorldEdgeDetector-Top"
onready var detector_top_shape = $"WorldEdgeDetector-Top/CollisionShape2D".shape
onready var detector_left = $"WorldEdgeDetector-Left"
onready var detector_left_shape = $"WorldEdgeDetector-Left/CollisionShape2D".shape
onready var detector_right = $"WorldEdgeDetector-Right"
onready var detector_right_shape = $"WorldEdgeDetector-Right/CollisionShape2D".shape

func _ready():
	recalculate_positions()

func recalculate_positions():
	var chunk_offset = random_map.get_player_chunk()*(chunk_size*tile_size)
	var detector_extent = detector_bottom_shape.extents.y
	
	detector_bottom_shape.set_deferred('extents', Vector2((chunk_size*tile_size)/2, detector_extent))
	detector_top_shape.set_deferred('extents', Vector2((chunk_size*tile_size)/2, detector_extent))
	detector_left_shape.set_deferred('extents', Vector2(detector_extent, (chunk_size*tile_size)/2))
	detector_right_shape.set_deferred('extents', Vector2(detector_extent, (chunk_size*tile_size)/2))
	
	detector_bottom.global_position = Vector2(chunk_size/2*tile_size, chunk_size*tile_size-detector_extent) + chunk_offset
	detector_top.global_position = Vector2(chunk_size/2*tile_size, detector_extent) + chunk_offset
	detector_left.global_position =  Vector2(detector_extent, chunk_size/2*tile_size) + chunk_offset
	detector_right.global_position = Vector2(chunk_size*tile_size-detector_extent, chunk_size/2*tile_size) + chunk_offset