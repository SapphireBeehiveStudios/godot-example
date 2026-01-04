extends Node
## Grid Map Helper
##
## Provides utility functions for grid-based operations including
## line-of-sight calculations for tactical games.

## Enum for tile types
enum TileType {
	EMPTY = 0,      ## Empty/walkable tile
	WALL = 1,       ## Solid wall that blocks LoS
	DOOR_OPEN = 2,  ## Open door (does not block LoS)
	DOOR_CLOSED = 3 ## Closed door (blocks LoS)
}

## Check if there is a clear line of sight between two positions
##
## This function checks if two positions share the same row or column,
## and if so, checks all tiles between them for blockers (walls or closed doors).
##
## @param from_pos: Starting position as Vector2i (x=column, y=row)
## @param to_pos: Target position as Vector2i (x=column, y=row)
## @param grid_data: 2D array representing the grid, where grid_data[row][col] contains TileType
## @return: true if there is clear LoS, false otherwise
func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i, grid_data: Array) -> bool:
	# Check if positions are the same
	if from_pos == to_pos:
		return true

	# Check if positions share the same row (horizontal line)
	if from_pos.y == to_pos.y:
		return _check_horizontal_los(from_pos, to_pos, grid_data)

	# Check if positions share the same column (vertical line)
	if from_pos.x == to_pos.x:
		return _check_vertical_los(from_pos, to_pos, grid_data)

	# Diagonal or non-aligned positions don't have LoS in this implementation
	return false

## Check horizontal line of sight (same row)
func _check_horizontal_los(from_pos: Vector2i, to_pos: Vector2i, grid_data: Array) -> bool:
	var row = from_pos.y

	# Validate row is within grid bounds
	if row < 0 or row >= grid_data.size():
		return false

	var row_data = grid_data[row]

	# Get column range (start to end, exclusive of endpoints)
	var start_col = min(from_pos.x, to_pos.x)
	var end_col = max(from_pos.x, to_pos.x)

	# Check each tile between the positions (exclusive)
	for col in range(start_col + 1, end_col):
		if col < 0 or col >= row_data.size():
			return false

		var tile_type = row_data[col]
		if _is_blocker(tile_type):
			return false

	return true

## Check vertical line of sight (same column)
func _check_vertical_los(from_pos: Vector2i, to_pos: Vector2i, grid_data: Array) -> bool:
	var col = from_pos.x

	# Get row range (start to end, exclusive of endpoints)
	var start_row = min(from_pos.y, to_pos.y)
	var end_row = max(from_pos.y, to_pos.y)

	# Check each tile between the positions (exclusive)
	for row in range(start_row + 1, end_row):
		if row < 0 or row >= grid_data.size():
			return false

		var row_data = grid_data[row]
		if col < 0 or col >= row_data.size():
			return false

		var tile_type = row_data[col]
		if _is_blocker(tile_type):
			return false

	return true

## Check if a tile type blocks line of sight
func _is_blocker(tile_type: int) -> bool:
	return tile_type == TileType.WALL or tile_type == TileType.DOOR_CLOSED
