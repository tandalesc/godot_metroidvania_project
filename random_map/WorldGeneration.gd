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

var prefabs = {}
var explored_chunks = {}
var generated_chunks = {}
const tile_width = 16
const tile_height = 16
var map_width = chunk_size
var map_height = chunk_size

func _ready():
	randomize()
	TILES['ground'] = tile_set.find_tile_by_name(ground_cell)
	TILES['detail'] = tile_set.find_tile_by_name('region3_stalactite')
	#read tilemap to get prefabs
	_update_prefabs(Vector2.ZERO, 'center')
	_update_prefabs(Vector2.RIGHT, 'tee right')
	_update_prefabs(Vector2.LEFT, 'tee left')
	_update_prefabs(Vector2.UP, 'tee up')
	_update_prefabs(Vector2.UP+Vector2.RIGHT, 'up right')
	_update_prefabs(Vector2.UP+Vector2.LEFT, 'up left')
	#generate new maps
	clear()
	_place_prefab('tee up', Vector2.ZERO)

func extend_if_needed(expand_dir, recursive=true):
	var prospective_chunk = random_map.get_player_chunk() + expand_dir
	if !explored_chunks.has(prospective_chunk):
		if !generated_chunks.has(prospective_chunk):
			_generate_cellular_automata_region(prospective_chunk)
		explored_chunks[prospective_chunk] = true
	if recursive:
		#check neighboring tiles
		for dy in range(-1,2):
			for dx in range(-1,2):
				var neighbor_chunk = prospective_chunk + Vector2(dx, dy)
				if !generated_chunks.has(neighbor_chunk):
					if randi()%3==0:
						var random_prefab = prefabs.keys()[randi()%len(prefabs.keys())]
						_place_prefab(random_prefab, neighbor_chunk)
					else:
						_generate_cellular_automata_region(neighbor_chunk)

func _generate_cellular_automata_region(chunk):
	#stagger chunks every other row to break up inevitable grid
	var start = _stagger_chunk(chunk)*chunk_size
	var end = start+Vector2.ONE*chunk_size
	var buffer = _create_tile_buffer(end-start)
	_randomly_populate_region(buffer, start, end)
	buffer = _simulate_cellular_automata(buffer, start, end)
	_add_details(buffer, start, end)
	_apply_simulation(buffer, start, end)
	if !generated_chunks.has(chunk):
		generated_chunks[chunk] = true

func _randomly_populate_region(buffer, start, end):
	var m_w = end.x - start.x;
	var m_h = end.y - start.y;
	for y in range(0, m_h):
		for x in range(0, m_w):
			if randf()<density:
				buffer[y][x] = TILES['ground']
			else:
				buffer[y][x] = TILES['air']

#generate using cellular automata
#inspired by https://gamedevelopment.tutsplus.com/tutorials/generate-random-cave-levels-using-cellular-automata--gamedev-9664
func _simulate_cellular_automata(buffer, start, end, repititions=stages):
	var m_w = end.x - start.x;
	var m_h = end.y - start.y;
	var tile_buffer = [buffer, []]
	var selected_buffer = 0
	#process repetitions of conway's game of life
	for r in range(repititions):
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
	var simulated_tiles = tile_buffer[(selected_buffer+1)%2]
	#copy data back to original buffer if necessary
	return simulated_tiles

func _place_prefab(prefab_name, map_chunk):
	var start = _stagger_chunk(map_chunk)*chunk_size
	var end = start+Vector2.ONE*chunk_size
	var prefab = prefabs[prefab_name].duplicate(true)
	_add_details(prefab, start, end)
	_apply_simulation(prefab, start, end)
	if !generated_chunks.has(map_chunk):
		generated_chunks[map_chunk] = true

func _update_prefabs(prefab_chunk, prefab_name):
	var start = prefab_chunk*chunk_size
	var end = start+Vector2.ONE*chunk_size
	var tile_buffer = []
	for y in range(start.y, end.y):
		var row = []
		for x in range(start.x, end.x):
			row.append(get_cell(x, y))
		tile_buffer.append(row)
	prefabs[prefab_name] = tile_buffer

func _add_details(buffer, start, end):
	var m_w = end.x - start.x;
	var m_h = end.y - start.y;
	for y in range(0, m_h):
		for x in range(0, m_w):
			if buffer[y][x] == TILES['ground'] and y+1<m_h and buffer[y+1][x] == TILES['air']:
				if randf() < 0.5:
					buffer[y+1][x] = TILES['detail']

func _stagger_chunk(map_chunk):
	var staggered_chunk = map_chunk if int(map_chunk.y)%2==0 else map_chunk-Vector2.RIGHT*0.5
	return staggered_chunk

func _create_tile_buffer(size):
	var buffer = []
	for y in range(0, size.y):
		var row = []
		for x in range(0, size.x):
			row.append(TILES['air'])
		buffer.append(row)
	return buffer

func _apply_simulation(sim_tiles, start, end):
	var m_w = end.x - start.x;
	var m_h = end.y - start.y;
	#apply simulated world to tilemap
	for y in range(0, m_h):
		for x in range(0, m_w):
			set_cell(x+start.x, y+start.y, sim_tiles[y][x])
	update_bitmask_region(start, end)
	call_deferred('update_dirty_quadrants')