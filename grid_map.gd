extends RefCounted
## GridMap - Pure logic class for grid-based tile management
##
## Provides core grid operations including bounds checking, walkability,
## neighbor queries, and tile management for the turn-based game.
## Issue #17

## Tile types supported by the grid
enum TileType {
	FLOOR = 0,          ## Walkable floor tile
	WALL = 1,           ## Impassable wall
	DOOR_CLOSED = 2,    ## Closed door (blocks movement)
	DOOR_OPEN = 3,      ## Open door (walkable)
	EXIT = 4            ## Level exit
}

## Grid dimensions
var width: int
var height: int

## Internal grid storage - Dictionary with Vector2i keys
## Each tile stores: {"type": TileType, ...}
var _tiles: Dictionary = {}

## Initialize grid with specified dimensions
func _init(grid_width: int = 24, grid_height: int = 14) -> void:
	"""Initialize the grid with given dimensions (default 24x14)."""
	width = grid_width
	height = grid_height
	_tiles = {}

	# Initialize all tiles as floor by default
	for y in range(height):
		for x in range(width):
			_tiles[Vector2i(x, y)] = {"type": TileType.FLOOR}


## Check if a position is within grid bounds
func is_in_bounds(pos: Vector2i) -> bool:
	"""Check if position is within grid boundaries.

	Args:
		pos: Position to check

	Returns:
		true if position is within [0, width) x [0, height), false otherwise
	"""
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


## Check if a position is walkable
func is_walkable(pos: Vector2i) -> bool:
	"""Check if a position can be walked on.

	Args:
		pos: Position to check

	Returns:
		true if position is in bounds and tile type is walkable, false otherwise
	"""
	if not is_in_bounds(pos):
		return false

	var tile = _tiles.get(pos, {"type": TileType.FLOOR})
	var tile_type = tile.get("type", TileType.FLOOR)

	# Walkable types: floor, door_open, exit
	# Non-walkable types: wall, door_closed
	match tile_type:
		TileType.FLOOR:
			return true
		TileType.WALL:
			return false
		TileType.DOOR_CLOSED:
			return false
		TileType.DOOR_OPEN:
			return true
		TileType.EXIT:
			return true
		_:
			return false


## Get 4-directional neighbors (up, down, left, right)
func get_neighbors_4dir(pos: Vector2i) -> Array[Vector2i]:
	"""Get all valid 4-directional neighbors of a position.

	Args:
		pos: Center position

	Returns:
		Array of neighboring positions that are within bounds
	"""
	var neighbors: Array[Vector2i] = []

	# Four cardinal directions: up, down, left, right
	var directions = [
		Vector2i(0, -1),   # Up
		Vector2i(0, 1),    # Down
		Vector2i(-1, 0),   # Left
		Vector2i(1, 0)     # Right
	]

	for direction in directions:
		var neighbor_pos = pos + direction
		if is_in_bounds(neighbor_pos):
			neighbors.append(neighbor_pos)

	return neighbors


## Set tile at position
func set_tile(pos: Vector2i, tile_type: TileType) -> void:
	"""Set the tile type at a position.

	Args:
		pos: Position to set
		tile_type: Type of tile to set
	"""
	if not is_in_bounds(pos):
		push_warning("Attempted to set tile outside bounds: %s" % pos)
		return

	_tiles[pos] = {"type": tile_type}


## Get tile type at position
func get_tile(pos: Vector2i) -> TileType:
	"""Get the tile type at a position.

	Args:
		pos: Position to query

	Returns:
		TileType at the position, or FLOOR if out of bounds
	"""
	if not is_in_bounds(pos):
		return TileType.FLOOR

	var tile = _tiles.get(pos, {"type": TileType.FLOOR})
	return tile.get("type", TileType.FLOOR)


## Clear the entire grid to floor tiles
func clear() -> void:
	"""Reset all tiles to floor type."""
	for y in range(height):
		for x in range(width):
			_tiles[Vector2i(x, y)] = {"type": TileType.FLOOR}
