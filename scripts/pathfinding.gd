extends Node
## Pathfinding Module
##
## Implements BFS (Breadth-First Search) pathfinding on a grid with 4-directional movement.

class_name Pathfinding

## Find the shortest path from start to goal using BFS on a grid.
##
## Parameters:
##   grid: 2D array where 0 = walkable, 1 = obstacle
##   start: Vector2i starting position (x, y)
##   goal: Vector2i goal position (x, y)
##
## Returns:
##   Array of Vector2i positions representing the path from start to goal (inclusive),
##   or an empty array if no path exists.
static func find_path(grid: Array, start: Vector2i, goal: Vector2i) -> Array:
	# Validate inputs
	if grid.is_empty():
		return []

	var height = grid.size()
	var width = grid[0].size() if height > 0 else 0

	# Check if start and goal are within bounds
	if not _is_valid_position(start, width, height):
		return []
	if not _is_valid_position(goal, width, height):
		return []

	# Check if start or goal are obstacles
	if grid[start.y][start.x] != 0:
		return []
	if grid[goal.y][goal.x] != 0:
		return []

	# If start equals goal, return single-element path
	if start == goal:
		return [start]

	# BFS setup
	var queue: Array = [start]
	var visited: Dictionary = {start: true}
	var parent: Dictionary = {}

	# 4-directional movement (up, right, down, left)
	var directions = [
		Vector2i(0, -1),  # up
		Vector2i(1, 0),   # right
		Vector2i(0, 1),   # down
		Vector2i(-1, 0)   # left
	]

	# BFS main loop
	while not queue.is_empty():
		var current = queue.pop_front()

		# Check if we reached the goal
		if current == goal:
			return _reconstruct_path(parent, start, goal)

		# Explore neighbors
		for direction in directions:
			var neighbor = current + direction

			# Skip if out of bounds
			if not _is_valid_position(neighbor, width, height):
				continue

			# Skip if obstacle
			if grid[neighbor.y][neighbor.x] != 0:
				continue

			# Skip if already visited
			if neighbor in visited:
				continue

			# Mark as visited and add to queue
			visited[neighbor] = true
			parent[neighbor] = current
			queue.push_back(neighbor)

	# No path found
	return []

## Check if a position is within grid bounds
static func _is_valid_position(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

## Reconstruct the path from start to goal using the parent dictionary
static func _reconstruct_path(parent: Dictionary, start: Vector2i, goal: Vector2i) -> Array:
	var path: Array = []
	var current = goal

	# Backtrack from goal to start
	while current != start:
		path.push_front(current)
		current = parent[current]

	# Add the start position
	path.push_front(start)

	return path
