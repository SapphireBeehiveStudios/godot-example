extends Node
## LevelGen - Centralized level generation for Terminal Heist
##
## Produces complete level data including:
## - Grid map with floors/walls
## - Entity spawn positions (player start, guards, items)
## - Enforces minimum distance constraints
## - Validates placement rules
##
## Part of Issue #25 (EPIC 3)

class_name LevelGen

# Preload dependencies
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")
const PlacementValidator = preload("res://scripts/utils/placement_validator.gd")

## Result of level generation
class GenerationResult:
	var success: bool = false
	var grid: Dictionary = {}  # Vector2i => {"type": "wall"|"floor"|"pickup"|"exit", ...}
	var player_start: Vector2i = Vector2i.ZERO
	var shard_pos: Vector2i = Vector2i.ZERO
	var exit_pos: Vector2i = Vector2i.ZERO
	var guard_spawn_positions: Array[Vector2i] = []
	var keycard_positions: Array[Vector2i] = []
	var attempts: int = 0
	var error_message: String = ""

## Generate a complete level with all entities and items
##
## Parameters:
##   width: Width of the dungeon grid
##   height: Height of the dungeon grid
##   rng_seed: Seed for deterministic generation
##   wall_density: Probability of wall placement (0.0 to 1.0)
##   guard_count: Number of guards to place (default 0)
##   place_keycard: Whether to place a keycard (default false)
##   place_door: Whether to place a door (default false)
##
## Returns:
##   GenerationResult with success status and level data
static func generate(
	width: int,
	height: int,
	rng_seed: int,
	wall_density: float = 0.3,
	guard_count: int = 0,
	place_keycard: bool = false,
	place_door: bool = false
) -> GenerationResult:
	var result = GenerationResult.new()

	# Initialize RNG for consistent generation
	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed

	# Step 1: Generate base dungeon layout using DungeonGenerator
	var dungeon_result = DungeonGenerator.generate_dungeon(width, height, rng_seed, wall_density)
	result.attempts = dungeon_result.attempts

	if not dungeon_result.success:
		result.error_message = dungeon_result.error_message
		return result

	# Step 2: Convert DungeonGenerator grid to our Dictionary format
	result.grid = _convert_dungeon_grid_to_dict(dungeon_result.grid)
	result.player_start = dungeon_result.start_pos
	result.shard_pos = dungeon_result.shard_pos
	result.exit_pos = dungeon_result.exit_pos

	# Step 3: Place special tiles (shard and exit)
	result.grid[result.shard_pos] = {"type": "pickup", "pickup_type": "shard"}
	result.grid[result.exit_pos] = {"type": "exit"}

	# Step 4: Place guards if requested
	if guard_count > 0:
		var guard_positions = _place_guards(
			result.grid,
			guard_count,
			result.player_start,
			result.shard_pos,
			result.exit_pos,
			rng
		)
		if guard_positions.is_empty() and guard_count > 0:
			result.error_message = "Failed to place all guards"
			return result
		result.guard_spawn_positions = guard_positions

	# Step 5: Place keycard if requested
	if place_keycard:
		var keycard_pos = _place_keycard(
			result.grid,
			result.player_start,
			result.shard_pos,
			result.exit_pos,
			result.guard_spawn_positions,
			rng
		)
		if keycard_pos != Vector2i(-1, -1):
			result.grid[keycard_pos] = {"type": "pickup", "pickup_type": "keycard"}
			result.keycard_positions.append(keycard_pos)

	# Step 6: Place door if requested (simplified for MVP)
	# For now, we skip door placement to keep the MVP simple
	# Doors can be added in future iterations with proper corridor detection

	# Step 7: Validate placement rules
	var validation = PlacementValidator.validate_door_keycard_placement(
		result.grid,
		result.player_start
	)
	if not validation.valid:
		result.error_message = "Placement validation failed: " + str(validation.errors)
		return result

	result.success = true
	return result

## Convert DungeonGenerator's Array grid to Dictionary format
static func _convert_dungeon_grid_to_dict(grid: Array) -> Dictionary:
	var dict_grid: Dictionary = {}
	var height = grid.size()
	var width = grid[0].size() if height > 0 else 0

	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var tile = grid[y][x]

			# Convert Tile enum to Dictionary format
			match tile:
				DungeonGenerator.Tile.WALL:
					dict_grid[pos] = {"type": "wall"}
				DungeonGenerator.Tile.FLOOR, \
				DungeonGenerator.Tile.START, \
				DungeonGenerator.Tile.SHARD, \
				DungeonGenerator.Tile.EXIT:
					dict_grid[pos] = {"type": "floor"}

	return dict_grid

## Place guards on the map with minimum distance constraints
##
## Guards must be:
## - At least MIN_GUARD_DISTANCE from player start
## - At least MIN_GUARD_DISTANCE from shard
## - At least MIN_GUARD_DISTANCE from exit
## - At least MIN_GUARD_SPACING from each other
## - On floor tiles only
static func _place_guards(
	grid: Dictionary,
	guard_count: int,
	player_start: Vector2i,
	shard_pos: Vector2i,
	exit_pos: Vector2i,
	rng: RandomNumberGenerator
) -> Array[Vector2i]:
	const MIN_GUARD_DISTANCE = 3  # Minimum distance from special tiles
	const MIN_GUARD_SPACING = 2   # Minimum distance between guards

	var guard_positions: Array[Vector2i] = []
	var floor_tiles: Array[Vector2i] = []

	# Collect all valid floor tiles
	for pos in grid:
		if grid[pos].type == "floor":
			floor_tiles.append(pos)

	# Shuffle floor tiles for randomness
	for i in range(floor_tiles.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = floor_tiles[i]
		floor_tiles[i] = floor_tiles[j]
		floor_tiles[j] = temp

	# Try to place guards
	for tile in floor_tiles:
		if guard_positions.size() >= guard_count:
			break

		# Check distance from player start
		if _manhattan_distance(tile, player_start) < MIN_GUARD_DISTANCE:
			continue

		# Check distance from shard
		if _manhattan_distance(tile, shard_pos) < MIN_GUARD_DISTANCE:
			continue

		# Check distance from exit
		if _manhattan_distance(tile, exit_pos) < MIN_GUARD_DISTANCE:
			continue

		# Check distance from other guards
		var too_close = false
		for other_guard in guard_positions:
			if _manhattan_distance(tile, other_guard) < MIN_GUARD_SPACING:
				too_close = true
				break

		if too_close:
			continue

		# Valid position, add guard
		guard_positions.append(tile)

	return guard_positions

## Place a keycard on the map with minimum distance constraints
##
## Keycard must be:
## - At least MIN_ITEM_DISTANCE from player start
## - At least MIN_ITEM_DISTANCE from shard
## - At least MIN_ITEM_DISTANCE from exit
## - At least MIN_ITEM_DISTANCE from guards
## - On a floor tile
static func _place_keycard(
	grid: Dictionary,
	player_start: Vector2i,
	shard_pos: Vector2i,
	exit_pos: Vector2i,
	guard_positions: Array[Vector2i],
	rng: RandomNumberGenerator
) -> Vector2i:
	const MIN_ITEM_DISTANCE = 2  # Minimum distance from special tiles

	var floor_tiles: Array[Vector2i] = []

	# Collect all valid floor tiles
	for pos in grid:
		if grid[pos].type == "floor":
			floor_tiles.append(pos)

	# Shuffle floor tiles for randomness
	for i in range(floor_tiles.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = floor_tiles[i]
		floor_tiles[i] = floor_tiles[j]
		floor_tiles[j] = temp

	# Try to place keycard
	for tile in floor_tiles:
		# Check distance from player start
		if _manhattan_distance(tile, player_start) < MIN_ITEM_DISTANCE:
			continue

		# Check distance from shard
		if _manhattan_distance(tile, shard_pos) < MIN_ITEM_DISTANCE:
			continue

		# Check distance from exit
		if _manhattan_distance(tile, exit_pos) < MIN_ITEM_DISTANCE:
			continue

		# Check distance from guards
		var too_close = false
		for guard_pos in guard_positions:
			if _manhattan_distance(tile, guard_pos) < MIN_ITEM_DISTANCE:
				too_close = true
				break

		if too_close:
			continue

		# Valid position, place keycard
		return tile

	# Failed to find valid position
	return Vector2i(-1, -1)

## Calculate Manhattan distance between two positions
static func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
