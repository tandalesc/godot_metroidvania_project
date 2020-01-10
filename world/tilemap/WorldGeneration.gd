extends TileMap

export (String) var ground_cell = 'region3_ground';
export (String) var air_cell = 'air';
export (float, 0.0, 1.0) var density = 0.5;
export (float, 1, 12) var starvation_limit = 2;
export (float, 1, 12) var birth_limit = 4;
export (float, 1, 12) var overpop_limit = 4;
export (int, 1, 10) var stages = 2;

var TILES = {
	'air': 0,
	'ground': 1,
	'detail': 2
};

const neighbor_tile_weight = 1.3;
const diag_tile_weight = 1.1;

const map_width = 200
const map_height = 400
const map_offset_x = -100
const map_offset_y = 0
const tile_width = 16
const tile_height = 16

func _ready():
	randomize()
	TILES['ground'] = tile_set.find_tile_by_name(ground_cell)
	TILES['air'] = -1;#tile_set.find_tile_by_name(air_cell)
	TILES['detail'] = tile_set.find_tile_by_name('region3_stalactite')
	simulate(stages)

#generate using cellular automata
#inspired by https://gamedevelopment.tutsplus.com/tutorials/generate-random-cave-levels-using-cellular-automata--gamedev-9664
func simulate(reps):
	var start = Vector2(map_offset_x, map_offset_y)
	var end = Vector2(map_width+map_offset_x, map_height+map_offset_y)
	var sim_tiles = []
	#create an in-memory representation
	for y in range(0, map_height):
		var row = []
		for x in range(0, map_width):
			if density > randf():
				row.append(TILES['ground'])
			else:
				row.append(TILES['air'])
		sim_tiles.append(row)
	#process repetitions of conway's game of life
	for r in range(reps):
		#maintain two copies so we keep our data input clean
		var sim_tiles_step = sim_tiles.duplicate(true)
		for x in range(0, map_width):
			for y in range(0, map_height):
				var cell = sim_tiles[y][x]
				#get list of neighboring ground cells
				var neighbors = 0.0
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						#(x+dx, y+dy) is within our array size constraints
						var is_valid_pos = (y+dy>0 and len(sim_tiles)>y+dy and x+dx>0 and len(sim_tiles[y+dy])>x+dx)
						if (dx != 0 or dy != 0) and is_valid_pos: #ignore center
							var neighbor_cell = sim_tiles[y+dy][x+dx]
							if neighbor_cell == TILES['ground']:
								neighbors += neighbor_tile_weight if dy!=dx else diag_tile_weight
				if cell == TILES['ground']:
					#die from overpopulation
					if neighbors < starvation_limit or neighbors > overpop_limit:
						sim_tiles_step[y][x] = TILES['air']
				elif cell == TILES['air']:
					#reproduce if at homeostatis
					if neighbors == birth_limit:
						sim_tiles_step[y][x] = TILES['ground']
		#apply changes to simulation step
		sim_tiles = sim_tiles_step
	#add details
	for x in range(0, map_width):
		for y in range(0, map_height):
			if sim_tiles[y][x] == TILES['ground'] and y+1<map_height and sim_tiles[y+1][x] == TILES['air']:
				if randf() < 0.5:
					sim_tiles[y+1][x] = TILES['detail']
	#apply simulated world to tilemap
	clear()
	for x in range(0, map_width):
		for y in range(0, map_height):
			set_cell(x+map_offset_x, y+map_offset_y, sim_tiles[y][x])
		for y in range(-50, 0):
			set_cell(x+map_offset_x, y+map_offset_y, TILES['air'])
	update_bitmask_region(start, end)
	