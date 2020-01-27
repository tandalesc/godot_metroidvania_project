extends TileMap

export (String) var ground_cell = 'region3_ground';
export (String) var air_cell = 'air';
export (float, 0.0, 1.0) var density = 0.5;
export (float, 1, 12) var starvation_limit = 2;
export (float, 1, 12) var birth_limit = 4;
export (float, 1, 12) var overpop_limit = 4;
export (int, 1, 10) var stages = 2;

var TILES = {
	'air': -1,
	'ground': 1,
	'detail': 2
};

const neighbor_tile_weight = 1.3;
const diag_tile_weight = 1.1;

onready var random_map = $".."
onready var chunk_size = random_map.chunk_size

var explored_chunks = {}
var generated_chunks = {}
const tile_width = 16
const tile_height = 16
var map_width = chunk_size
var map_height = chunk_size

func _ready():
	TILES['ground'] = tile_set.find_tile_by_name(ground_cell)
	#TILES['air'] = -1;#tile_set.find_tile_by_name(air_cell)
	TILES['detail'] = tile_set.find_tile_by_name('region3_stalactite')
	
	randomize()
	clear()
	#loads current position and all neighboring positions
	extend_if_needed(Vector2.ZERO, true)

func extend_if_needed(expand_dir, recursive=true):
	var prospective_chunk = random_map.get_player_chunk() + expand_dir
	if !explored_chunks.has(prospective_chunk):
		if !generated_chunks.has(prospective_chunk):
			_generate_region(prospective_chunk)
		explored_chunks[prospective_chunk] = true
	if recursive:
		#check neighboring tiles
		for dy in range(-1,2):
			for dx in range(-1,2):
				var neighbor_chunk = prospective_chunk + Vector2(dx, dy)
				if !generated_chunks.has(neighbor_chunk):
					_generate_region(neighbor_chunk)

func _generate_region(chunk):
	#stagger chunks every other row to break up inevitable grid
	var start = Vector2(chunk.x if int(chunk.y)%2==0 else chunk.x-0.5, chunk.y)*chunk_size;
	var end = Vector2(((chunk.x if int(chunk.y)%2==0 else chunk.x-0.5)+1), (chunk.y+1))*chunk_size;
	var new_tiles = _simulate(start, end)
	_apply_simulation(new_tiles, start, end)
	if !generated_chunks.has(chunk):
		generated_chunks[chunk] = true

#generate using cellular automata
#inspired by https://gamedevelopment.tutsplus.com/tutorials/generate-random-cave-levels-using-cellular-automata--gamedev-9664
func _simulate(start, end):
	var m_w = end.x - start.x
	var m_h = end.y - start.y
	var tile_buffer = [[], []]
	#fill in buffer 0
	for y in range(0, m_h):
		var row = []
		for x in range(0, m_w):
			if density > randf():
				row.append(TILES['ground'])
			else:
				row.append(TILES['air'])
		tile_buffer[0].append(row)
	var selected_buffer = 0
	#process repetitions of conway's game of life
	for r in range(stages):
		#maintain two copies so we keep our data input clean
		tile_buffer[(r+1)%2] = tile_buffer[r%2].duplicate(true)
		for y in range(0, m_h):
			for x in range(0, m_w):
				var cell = tile_buffer[r%2][y][x]
				#get list of neighboring ground cells
				var neighbors = 0.0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						#(x+dx, y+dy) is within our array size constraints
						var is_valid_pos = (y+dy>0 and m_h>y+dy and x+dx>0 and m_w>x+dx)
						if (dx != 0 or dy != 0) and is_valid_pos: #ignore center
							var neighbor_cell = tile_buffer[r%2][y+dy][x+dx]
							if neighbor_cell == TILES['ground']:
								neighbors += neighbor_tile_weight if dy!=dx else diag_tile_weight
				if cell == TILES['ground']:
					#die from overpopulation
					if neighbors < starvation_limit or neighbors > overpop_limit:
						tile_buffer[(r+1)%2][y][x] = TILES['air']
				elif cell == TILES['air']:
					#reproduce if at homeostatis
					if neighbors == birth_limit:
						tile_buffer[(r+1)%2][y][x] = TILES['ground']
		#apply changes to simulation step
		selected_buffer = (r+1)%2
	#add details
	for y in range(0, m_h):
		for x in range(0, m_w):
			if tile_buffer[selected_buffer][y][x] == TILES['ground'] and y+1<m_h and tile_buffer[selected_buffer][y+1][x] == TILES['air']:
				if randf() < 0.5:
					tile_buffer[selected_buffer][y+1][x] = TILES['detail']
	return tile_buffer[selected_buffer]

func _apply_simulation(sim_tiles, start, end):
	var m_w = end.x - start.x;
	var m_h = end.y - start.y;
	#apply simulated world to tilemap
	for y in range(0, m_h):
		for x in range(0, m_w):
			set_cell(x+start.x, y+start.y, sim_tiles[y][x])
	update_bitmask_region(start, end)
	call_deferred('update_dirty_quadrants')