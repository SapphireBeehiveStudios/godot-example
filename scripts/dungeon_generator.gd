extends Node
## Dungeon Generator
##
## Generates dungeon layouts with guaranteed reachability between
## start, shard, and exit positions using BFS validation.

class_name DungeonGenerator

# Preload the Pathfinding class
const Pathfinding = preload("res://scripts/pathfinding.gd")

## Result of dungeon generation
class GenerationResult:
	var success: bool = false
	var grid: Array = []
	var start_pos: Vector2i = Vector2i.ZERO
	var shard_pos: Vector2i = Vector2i.ZERO
	var exit_pos: Vector2i = Vector2i.ZERO
	var attempts: int = 0
	var error_message: String = ""

## Maximum number of generation attempts before giving up
const MAX_GENERATION_ATTEMPTS = 100

## Tile types for dungeon generation
enum Tile {
	FLOOR = 0,
	WALL = 1,
	START = 2,
	SHARD = 3,
	EXIT = 4
}

## Generate a dungeon with guaranteed reachability
##
## Parameters:
##   width: Width of the dungeon grid
##   height: Height of the dungeon grid
##   rng_seed: Seed for deterministic generation (optional)
##   wall_density: Probability of wall placement (0.0 to 1.0), default 0.3
##
## Returns:
##   GenerationResult with success status and dungeon data
static func generate_dungeon(width: int, height: int, rng_seed: int = -1, wall_density: float = 0.3) -> GenerationResult:
	var result = GenerationResult.new()

	# Validate input parameters
	if width < 3 or height < 3:
		result.error_message = "Dungeon dimensions must be at least 3x3"
		return result

	if wall_density < 0.0 or wall_density > 1.0:
		result.error_message = "Wall density must be between 0.0 and 1.0"
		return result

	# Initialize RNG
	var rng = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	# Attempt generation with retry loop
	for attempt in range(MAX_GENERATION_ATTEMPTS):
		result.attempts = attempt + 1

		# Generate random dungeon layout
		var grid = _generate_random_grid(width, height, rng, wall_density)

		# Place start, shard, and exit on random floor tiles
		var positions = _place_special_tiles(grid, rng)
		if positions.is_empty():
			continue  # Failed to place tiles, retry

		var start_pos = positions["start"]
		var shard_pos = positions["shard"]
		var exit_pos = positions["exit"]

		# Validate reachability: start -> shard -> exit
		if _validate_reachability(grid, start_pos, shard_pos, exit_pos):
			# Success! Dungeon is valid
			result.success = true
			result.grid = grid
			result.start_pos = start_pos
			result.shard_pos = shard_pos
			result.exit_pos = exit_pos
			return result

	# Failed to generate valid dungeon after max attempts
	result.error_message = "Failed to generate valid dungeon after %d attempts" % MAX_GENERATION_ATTEMPTS
	return result

## Generate a random grid with walls and floors
static func _generate_random_grid(width: int, height: int, rng: RandomNumberGenerator, wall_density: float) -> Array:
	var grid: Array = []

	for y in range(height):
		var row: Array = []
		for x in range(width):
			# Always place walls on the boundary
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				row.append(Tile.WALL)
			# Place walls with given probability for interior
			elif rng.randf() < wall_density:
				row.append(Tile.WALL)
			else:
				row.append(Tile.FLOOR)
		grid.append(row)

	return grid

## Place start, shard, and exit on random floor tiles
## Returns a dictionary with "start", "shard", "exit" keys, or empty dict if failed
static func _place_special_tiles(grid: Array, rng: RandomNumberGenerator) -> Dictionary:
	# Find all floor tiles
	var floor_tiles: Array[Vector2i] = []
	var height = grid.size()
	var width = grid[0].size()

	for y in range(height):
		for x in range(width):
			if grid[y][x] == Tile.FLOOR:
				floor_tiles.append(Vector2i(x, y))

	# Need at least 3 floor tiles for start, shard, and exit
	if floor_tiles.size() < 3:
		return {}

	# Shuffle using the provided RNG for deterministic placement
	# Manually shuffle using the RNG (GDScript Array.shuffle() doesn't take RNG parameter)
	for i in range(floor_tiles.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = floor_tiles[i]
		floor_tiles[i] = floor_tiles[j]
		floor_tiles[j] = temp

	var start_pos = floor_tiles[0]
	var shard_pos = floor_tiles[1]
	var exit_pos = floor_tiles[2]

	# Mark special tiles (optional, for visualization)
	# We keep them as FLOOR for pathfinding purposes

	return {
		"start": start_pos,
		"shard": shard_pos,
		"exit": exit_pos
	}

## Validate that paths exist: start -> shard and shard -> exit
static func _validate_reachability(grid: Array, start_pos: Vector2i, shard_pos: Vector2i, exit_pos: Vector2i) -> bool:
	# Convert grid to pathfinding format (0 = walkable, 1 = obstacle)
	var pathfinding_grid = _convert_to_pathfinding_grid(grid)

	# Check start -> shard path exists
	var path_to_shard = Pathfinding.find_path(pathfinding_grid, start_pos, shard_pos)
	if path_to_shard.is_empty():
		return false

	# Check shard -> exit path exists
	var path_to_exit = Pathfinding.find_path(pathfinding_grid, shard_pos, exit_pos)
	if path_to_exit.is_empty():
		return false

	return true

## Convert dungeon grid to pathfinding grid format
static func _convert_to_pathfinding_grid(grid: Array) -> Array:
	var pathfinding_grid: Array = []

	for row in grid:
		var new_row: Array = []
		for tile in row:
			# Wall = 1 (obstacle), everything else = 0 (walkable)
			if tile == Tile.WALL:
				new_row.append(1)
			else:
				new_row.append(0)
		pathfinding_grid.append(new_row)

	return pathfinding_grid

## Check if a path exists between two positions (utility function)
static func check_reachability(grid: Array, from_pos: Vector2i, to_pos: Vector2i) -> bool:
	var pathfinding_grid = _convert_to_pathfinding_grid(grid)
	var path = Pathfinding.find_path(pathfinding_grid, from_pos, to_pos)
	return not path.is_empty()
