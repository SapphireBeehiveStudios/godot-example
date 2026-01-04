extends RefCounted
class_name TileGrid
## TileGrid - Pure logic class for grid-based map management
##
## Manages a 2D grid of tiles with different types (wall, floor, door, exit).
## Provides utilities for bounds checking, walkability, and neighbor queries.

## Enum for tile types
enum TileType {
	WALL = 0,       ## Solid wall that blocks movement and LoS
	FLOOR = 1,      ## Walkable floor tile
	DOOR_OPEN = 2,  ## Open door (walkable, does not block LoS)
	DOOR_CLOSED = 3, ## Closed door (not walkable, blocks LoS)
	EXIT = 4        ## Exit tile (walkable)
}

## The 2D grid data structure
## grid[y][x] or grid[row][column]
var _grid: Array = []

## Grid dimensions
var width: int = 0
var height: int = 0

## Door states - tracks whether doors are open or closed
## Key: Vector2i position, Value: bool (true = open, false = closed)
var _door_states: Dictionary = {}

## Initialize the GridMap with specified dimensions
##
## @param grid_width: Width of the grid (number of columns)
## @param grid_height: Height of the grid (number of rows)
## @param default_tile: Default tile type to fill the grid with
func _init(grid_width: int = 24, grid_height: int = 14, default_tile: TileType = TileType.FLOOR) -> void:
	width = grid_width
	height = grid_height
	_grid = []

	# Initialize grid with default tiles
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(default_tile)
		_grid.append(row)

## Check if a position is within grid bounds
##
## @param pos: Position to check as Vector2i (x=column, y=row)
## @return: true if position is within bounds, false otherwise
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

## Check if a tile at the given position is walkable
##
## @param pos: Position to check as Vector2i (x=column, y=row)
## @return: true if the tile is walkable, false otherwise
func is_walkable(pos: Vector2i) -> bool:
	# Out of bounds is not walkable
	if not is_in_bounds(pos):
		return false

	var tile = _grid[pos.y][pos.x]

	# Check walkability based on tile type
	match tile:
		TileType.WALL:
			return false
		TileType.FLOOR:
			return true
		TileType.EXIT:
			return true
		TileType.DOOR_OPEN:
			return true
		TileType.DOOR_CLOSED:
			# Check door state - if tracked and open, it's walkable
			if _door_states.has(pos) and _door_states[pos]:
				return true
			return false
		_:
			# Unknown tile type, assume not walkable
			return false

## Get all valid neighbors in 4 directions (up, right, down, left)
##
## @param pos: Position to get neighbors for as Vector2i (x=column, y=row)
## @return: Array of Vector2i positions representing valid neighbors
func get_neighbors_4dir(pos: Vector2i) -> Array:
	var neighbors: Array = []

	# 4-directional movement (up, right, down, left)
	var directions = [
		Vector2i(0, -1),  # up
		Vector2i(1, 0),   # right
		Vector2i(0, 1),   # down
		Vector2i(-1, 0)   # left
	]

	for direction in directions:
		var neighbor = pos + direction
		if is_in_bounds(neighbor):
			neighbors.append(neighbor)

	return neighbors

## Set the tile type at a given position
##
## @param pos: Position to set as Vector2i (x=column, y=row)
## @param tile_type: The TileType to set
func set_tile(pos: Vector2i, tile_type: TileType) -> void:
	if not is_in_bounds(pos):
		push_warning("GridMap.set_tile: Position %s is out of bounds" % pos)
		return

	_grid[pos.y][pos.x] = tile_type

	# Initialize door state if setting a door tile
	if tile_type == TileType.DOOR_OPEN:
		_door_states[pos] = true
	elif tile_type == TileType.DOOR_CLOSED:
		_door_states[pos] = false

## Get the tile type at a given position
##
## @param pos: Position to get as Vector2i (x=column, y=row)
## @return: The TileType at that position, or -1 if out of bounds
func get_tile(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return -1

	return _grid[pos.y][pos.x]

## Set the door state at a given position
##
## @param pos: Position of the door as Vector2i (x=column, y=row)
## @param is_open: true if door is open, false if closed
func set_door_state(pos: Vector2i, is_open: bool) -> void:
	if not is_in_bounds(pos):
		push_warning("GridMap.set_door_state: Position %s is out of bounds" % pos)
		return

	var tile = _grid[pos.y][pos.x]
	if tile != TileType.DOOR_OPEN and tile != TileType.DOOR_CLOSED:
		push_warning("GridMap.set_door_state: Tile at %s is not a door" % pos)
		return

	_door_states[pos] = is_open

	# Update the tile type to match the state
	if is_open:
		_grid[pos.y][pos.x] = TileType.DOOR_OPEN
	else:
		_grid[pos.y][pos.x] = TileType.DOOR_CLOSED

## Get the door state at a given position
##
## @param pos: Position of the door as Vector2i (x=column, y=row)
## @return: true if door is open, false if closed or not a door
func get_door_state(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false

	return _door_states.get(pos, false)

## Get the raw grid data for compatibility with pathfinding/LoS functions
##
## @return: 2D array representing the grid
func get_grid_data() -> Array:
	return _grid
