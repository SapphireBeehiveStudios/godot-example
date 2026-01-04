extends Node2D
## Guard AI with Chase Behavior
##
## This script implements guard AI with:
## - Line of Sight (LoS) detection
## - Chase behavior using BFS pathfinding
## - Chase timer (N turns)
## - State transitions (Patrol -> Chase -> Patrol)

## Emitted when a message should be logged (Issue #36)
signal message_generated(text: String, type: String)

enum State {
	PATROL,
	CHASE
}

## Maximum number of turns to chase before reverting to patrol
@export var max_chase_turns: int = 5

## Line of sight range in grid cells
@export var los_range: int = 8

## Current state
var current_state: State = State.PATROL

## Chase turns remaining
var chase_turns_remaining: int = 0

## Grid position (x, y)
var grid_position: Vector2i = Vector2i(0, 0)

## Player grid position (tracked)
var player_position: Vector2i = Vector2i(0, 0)

## Grid size for pathfinding
var grid_width: int = 20
var grid_height: int = 20

## Obstacles on the grid (for LoS and pathfinding)
var obstacles: Dictionary = {}  # Vector2i -> bool

func _ready() -> void:
	pass

## Check if guard has line of sight to player
func has_line_of_sight(player_pos: Vector2i) -> bool:
	var distance = grid_position.distance_to(player_pos)

	# Check if within range
	if distance > los_range:
		return false

	# Use Bresenham's line algorithm to check for obstacles
	var los_cells = get_line_cells(grid_position, player_pos)

	# Check each cell along the line (excluding start and end)
	for i in range(1, los_cells.size() - 1):
		var cell = los_cells[i]
		if obstacles.get(cell, false):
			return false

	return true

## Get all cells along a line using Bresenham's algorithm
func get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	while true:
		cells.append(Vector2i(x0, y0))

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return cells

## Update guard AI (call once per turn)
func update_ai(player_pos: Vector2i) -> void:
	player_position = player_pos

	# Check for line of sight
	if has_line_of_sight(player_pos):
		# Start or continue chase
		if current_state != State.CHASE:
			enter_chase_state()
		else:
			# Reset chase timer on continued LoS
			chase_turns_remaining = max_chase_turns
	else:
		# No line of sight
		if current_state == State.CHASE:
			# Decrement chase timer
			chase_turns_remaining -= 1
			if chase_turns_remaining <= 0:
				exit_chase_state()

## Enter chase state
func enter_chase_state() -> void:
	current_state = State.CHASE
	chase_turns_remaining = max_chase_turns
	message_generated.emit("Guard spotted you!", "guard")

## Exit chase state
func exit_chase_state() -> void:
	current_state = State.PATROL
	chase_turns_remaining = 0
	message_generated.emit("Guard lost sight of you.", "info")

## Get next move using BFS pathfinding
func get_next_move() -> Vector2i:
	if current_state != State.CHASE:
		return grid_position  # No movement in patrol state for now

	# Use BFS to find shortest path
	var path = bfs_pathfind(grid_position, player_position)

	if path.size() > 1:
		# Return the next step in the path (index 1, since 0 is current position)
		return path[1]
	else:
		# No valid path found
		return grid_position

## BFS pathfinding to find shortest path
func bfs_pathfind(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var queue: Array = [from]
	var visited: Dictionary = {from: true}
	var parent: Dictionary = {}

	# Directions: up, down, left, right
	var directions = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]

	while queue.size() > 0:
		var current = queue.pop_front()

		# Found the target
		if current == to:
			return reconstruct_path(parent, from, to)

		# Check all neighbors
		for dir in directions:
			var neighbor = current + dir

			# Check bounds
			if neighbor.x < 0 or neighbor.x >= grid_width:
				continue
			if neighbor.y < 0 or neighbor.y >= grid_height:
				continue

			# Check if already visited or is an obstacle
			if visited.get(neighbor, false):
				continue
			if obstacles.get(neighbor, false):
				continue

			# Add to queue
			visited[neighbor] = true
			parent[neighbor] = current
			queue.append(neighbor)

	# No path found
	return [from]

## Reconstruct path from BFS parent dictionary
func reconstruct_path(parent: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [to]
	var current = to

	while current != from:
		current = parent.get(current, from)
		path.push_front(current)

	return path

## Set obstacle at grid position
func set_obstacle(pos: Vector2i, is_obstacle: bool) -> void:
	if is_obstacle:
		obstacles[pos] = true
	else:
		obstacles.erase(pos)

## Clear all obstacles
func clear_obstacles() -> void:
	obstacles.clear()

## Get current state
func get_state() -> State:
	return current_state

## Check if currently chasing
func is_chasing() -> bool:
	return current_state == State.CHASE

## Get chase turns remaining
func get_chase_turns_remaining() -> int:
	return chase_turns_remaining
