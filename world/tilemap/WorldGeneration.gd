extends TileMap

export (String) var ground_cell = 'region3_ground';
export (String) var air_cell = 'air';
export (int, 0, 100) var init_chance = 50;
export (int, 1, 8) var starvation_limit = 2;
export (int, 1, 8) var birth_limit = 4;
export (int, 1, 8) var overpop_limit = 4;
export (int, 1, 10) var reps = 2;

var TILES = {
	'air': 0,
	'ground': 1
};

const map_width = 500
const map_height = 500
const map_offset_x = -250
const map_offset_y = -250
const tile_width = 16
const tile_height = 16

func _ready():
	TILES['ground'] = tile_set.find_tile_by_name(ground_cell)
	TILES['air'] = tile_set.find_tile_by_name(air_cell)
	simulate(reps)

#generate using cellular automata
#inspired by https://gamedevelopment.tutsplus.com/tutorials/generate-random-cave-levels-using-cellular-automata--gamedev-9664
func simulate(life_reps):
	var start = Vector2(map_offset_x, map_offset_y)
	var end = Vector2(map_width+map_offset_x, map_height+map_offset_y)
	var sim_tiles = []
	#create an in-memory representation
	for y in range(0, map_height):
		var row = []
		for x in range(0, map_width):
			if init_chance > randi()%100:
				row.append(TILES['ground'])
			else:
				row.append(TILES['air'])
		sim_tiles.append(row)
	#process repetitions of conway's game of life
	for r in range(life_reps):
		#maintain two copies so we keep our data input clean
		var sim_tiles_step = sim_tiles.duplicate(true)
		for x in range(0, map_width):
			for y in range(0, map_height):
				var cell = sim_tiles[y][x]
				#get list of neighboring ground cells
				var neighbors = []
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						#(x+dx, y+dy) is within our array size constraints
						var is_valid_pos = (y+dy>0 and len(sim_tiles)>y+dy and x+dx>0 and len(sim_tiles[y+dy])>x+dx)
						if (dx != 0 or dy != 0) and is_valid_pos: #ignore center
							var neighbor_cell = sim_tiles[y+dy][x+dx]
							if neighbor_cell == TILES['ground']:
								neighbors.append(neighbor_cell)
				if cell == TILES['ground']:
					#die from overpopulation
					if len(neighbors) < starvation_limit or len(neighbors) > overpop_limit:
						sim_tiles_step[y][x] = TILES['air']
				elif cell == TILES['air']:
					#reproduce if at homeostatis
					if len(neighbors) == birth_limit:
						sim_tiles_step[y][x] = TILES['ground']
		#apply changes to simulation step
		sim_tiles = sim_tiles_step
	#apply simulated world to tilemap
	clear()
	for x in range(0, map_width):
		for y in range(0, map_height):
			set_cell(x+map_offset_x, y+map_offset_y, sim_tiles[y][x])
	update_bitmask_region(start, end)
	