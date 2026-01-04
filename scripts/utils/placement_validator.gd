extends Node
## PlacementValidator - Validates item placement rules for procedural generation
##
## Ensures that door and keycard placement follows game rules:
## - If any doors are placed, at least one keycard must be placed
## - Keycards must be reachable from start without requiring themselves (avoid deadlock)
##
## Part of Issue #27 (EPIC 3)

class_name PlacementValidator

## Validate that door/keycard placement rules are satisfied
##
## Rules:
## 1. If doors exist, at least one keycard must exist
## 2. At least one keycard must be reachable from start without needing any doors
##    (to avoid softlock where player can't get any keycard)
##
## Parameters:
##   grid: Dictionary mapping Vector2i -> {"type": "wall"|"floor"|"pickup"|"door", ...}
##   player_start: Vector2i starting position
##
## Returns:
##   Dictionary: {
##     "valid": bool,
##     "errors": Array[String]  # List of validation errors
##   }
static func validate_door_keycard_placement(grid: Dictionary, player_start: Vector2i) -> Dictionary:
	var errors: Array[String] = []

	# Count doors and keycards
	var door_count := 0
	var keycard_count := 0
	var keycard_positions: Array[Vector2i] = []

	for pos in grid:
		var tile = grid[pos]
		if tile.type == "door":
			door_count += 1
		elif tile.type == "pickup" and tile.get("pickup_type", "") == "keycard":
			keycard_count += 1
			keycard_positions.append(pos)

	# Rule 1: If doors exist, at least one keycard must exist
	if door_count > 0 and keycard_count == 0:
		errors.append("Doors placed but no keycards available - player would be softlocked")

	# Rule 2: At least one keycard must be reachable without doors
	if door_count > 0 and keycard_count > 0:
		var any_keycard_reachable := false

		for keycard_pos in keycard_positions:
			if is_reachable_without_doors(grid, player_start, keycard_pos):
				any_keycard_reachable = true
				break

		if not any_keycard_reachable:
			errors.append("No keycard is reachable without doors - player would be softlocked")

	return {
		"valid": errors.is_empty(),
		"errors": errors
	}

## Check if target position is reachable from start without passing through doors
##
## Uses BFS pathfinding treating doors as walls (obstacles).
##
## Parameters:
##   grid: Dictionary mapping Vector2i -> tile data
##   start: Vector2i starting position
##   target: Vector2i target position
##
## Returns:
##   bool: true if target is reachable without doors, false otherwise
static func is_reachable_without_doors(grid: Dictionary, start: Vector2i, target: Vector2i) -> bool:
	# Build walkability grid treating doors as obstacles
	# We need to find grid bounds first
	var min_x := 999999
	var max_x := -999999
	var min_y := 999999
	var max_y := -999999

	for pos in grid:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	# Check if start and target are in grid
	if start.x < min_x or start.x > max_x or start.y < min_y or start.y > max_y:
		return false
	if target.x < min_x or target.x > max_x or target.y < min_y or target.y > max_y:
		return false

	# BFS to check reachability
	var queue: Array = [start]
	var visited: Dictionary = {start: true}

	# 4-directional movement
	var directions = [
		Vector2i(0, -1),  # up
		Vector2i(1, 0),   # right
		Vector2i(0, 1),   # down
		Vector2i(-1, 0)   # left
	]

	while not queue.is_empty():
		var current = queue.pop_front()

		# Check if we reached the target
		if current == target:
			return true

		# Explore neighbors
		for direction in directions:
			var neighbor = current + direction

			# Skip if already visited
			if neighbor in visited:
				continue

			# Check if tile is walkable (not wall, not door)
			if not is_tile_walkable_without_doors(grid, neighbor):
				continue

			# Mark as visited and add to queue
			visited[neighbor] = true
			queue.push_back(neighbor)

	# Target not reachable
	return false

## Check if a tile is walkable, treating doors as obstacles
##
## Parameters:
##   grid: Dictionary mapping Vector2i -> tile data
##   pos: Vector2i position to check
##
## Returns:
##   bool: true if walkable (not wall, not door), false otherwise
static func is_tile_walkable_without_doors(grid: Dictionary, pos: Vector2i) -> bool:
	# For placement validation, only explicitly defined tiles can be walked on
	# Undefined positions are treated as non-walkable (prevents pathfinding through empty space)
	if pos not in grid:
		return false

	var tile = grid[pos]
	var tile_type = tile.get("type", "floor")

	# Walls and doors are not walkable for this check
	# Floor, pickups, exits, etc. are walkable
	if tile_type == "wall" or tile_type == "door":
		return false

	return true
