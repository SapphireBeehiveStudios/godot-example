extends Node
## Test Module for Guard Chase Behavior
##
## Tests for guard AI including:
## - Line of Sight detection
## - Chase state transitions
## - BFS pathfinding
## - Chase timer behavior

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_guard_initial_state()
	test_los_triggers_chase()
	test_los_blocked_by_obstacle()
	test_los_range_limit()
	test_chase_moves_closer_to_player()
	test_chase_follows_shortest_path()
	test_chase_timer_decrements()
	test_chase_reverts_after_timer()
	test_los_resets_chase_timer()
	test_pathfinding_around_obstacles()
	test_pathfinding_no_path_available()
	test_bresenham_line_algorithm()
	return {"passed": tests_passed, "failed": tests_failed}

## Assertion helper methods
func assert_eq(actual, expected, test_name: String) -> void:
	"""Assert that actual equals expected."""
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])

func assert_true(condition: bool, test_name: String) -> void:
	"""Assert that condition is true."""
	assert_eq(condition, true, test_name)

func assert_false(condition: bool, test_name: String) -> void:
	"""Assert that condition is false."""
	assert_eq(condition, false, test_name)

func assert_not_eq(actual, expected, test_name: String) -> void:
	"""Assert that actual does not equal expected."""
	if actual != expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: values should not be equal but both are %s" % [test_name, actual])

## Test implementations

func test_guard_initial_state() -> void:
	"""Test that guard starts in patrol state."""
	var guard = load("res://scripts/guard.gd").new()
	assert_eq(guard.current_state, guard.State.PATROL, "Guard starts in PATROL state")
	assert_false(guard.is_chasing(), "Guard not chasing initially")
	assert_eq(guard.get_chase_turns_remaining(), 0, "No chase turns initially")
	guard.free()

func test_los_triggers_chase() -> void:
	"""Test that LoS triggers chase state."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)
	guard.max_chase_turns = 3

	# Player in direct line of sight
	var player_pos = Vector2i(8, 5)

	# Update AI - should trigger chase
	guard.update_ai(player_pos)

	assert_eq(guard.current_state, guard.State.CHASE, "LoS triggers CHASE state")
	assert_true(guard.is_chasing(), "Guard is chasing")
	assert_eq(guard.get_chase_turns_remaining(), 3, "Chase timer set to max")
	guard.free()

func test_los_blocked_by_obstacle() -> void:
	"""Test that obstacles block LoS."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)

	# Add obstacle between guard and player
	guard.set_obstacle(Vector2i(6, 5), true)

	var player_pos = Vector2i(8, 5)

	assert_false(guard.has_line_of_sight(player_pos), "Obstacle blocks LoS")
	guard.free()

func test_los_range_limit() -> void:
	"""Test that LoS has a range limit."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)
	guard.los_range = 3

	# Player just within range
	var player_near = Vector2i(8, 5)
	assert_true(guard.has_line_of_sight(player_near), "Player within LoS range")

	# Player beyond range
	var player_far = Vector2i(15, 5)
	assert_false(guard.has_line_of_sight(player_far), "Player beyond LoS range")
	guard.free()

func test_chase_moves_closer_to_player() -> void:
	"""Test that chase step moves closer to player on known grid."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)
	guard.grid_width = 20
	guard.grid_height = 20

	var player_pos = Vector2i(10, 5)

	# Trigger chase
	guard.update_ai(player_pos)

	# Get next move
	var next_pos = guard.get_next_move()

	# Should move right (toward player)
	assert_eq(next_pos, Vector2i(6, 5), "Guard moves closer to player (right)")

	# Test vertical movement
	guard.grid_position = Vector2i(5, 5)
	player_pos = Vector2i(5, 10)
	guard.update_ai(player_pos)
	next_pos = guard.get_next_move()
	assert_eq(next_pos, Vector2i(5, 6), "Guard moves closer to player (down)")

	guard.free()

func test_chase_follows_shortest_path() -> void:
	"""Test that guard follows shortest path around obstacles."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(0, 0)
	guard.grid_width = 10
	guard.grid_height = 10

	# Create a wall blocking direct path
	guard.set_obstacle(Vector2i(1, 0), true)
	guard.set_obstacle(Vector2i(1, 1), true)
	guard.set_obstacle(Vector2i(1, 2), true)

	var player_pos = Vector2i(3, 1)

	# Trigger chase
	guard.update_ai(player_pos)

	# Get the full path
	var path = guard.bfs_pathfind(guard.grid_position, player_pos)

	# Path should exist and be longer than direct path due to obstacle
	assert_true(path.size() > 1, "Path found around obstacle")
	assert_eq(path[0], Vector2i(0, 0), "Path starts at guard position")
	assert_eq(path[path.size() - 1], Vector2i(3, 1), "Path ends at player position")

	guard.free()

func test_chase_timer_decrements() -> void:
	"""Test that chase timer decrements when LoS is lost."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)
	guard.max_chase_turns = 3

	var player_pos = Vector2i(8, 5)

	# Start chase
	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 3, "Chase timer starts at max")

	# Lose LoS (add obstacle)
	guard.set_obstacle(Vector2i(6, 5), true)
	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 2, "Chase timer decrements")

	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 1, "Chase timer continues decrementing")

	guard.free()

func test_chase_reverts_after_timer() -> void:
	"""Test that guard reverts to patrol after chase timer expires."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)
	guard.max_chase_turns = 2

	var player_pos = Vector2i(8, 5)

	# Start chase
	guard.update_ai(player_pos)
	assert_eq(guard.current_state, guard.State.CHASE, "Chase started")

	# Lose LoS
	guard.set_obstacle(Vector2i(6, 5), true)

	# Decrement timer
	guard.update_ai(player_pos)
	assert_eq(guard.current_state, guard.State.CHASE, "Still chasing (timer = 1)")

	guard.update_ai(player_pos)
	assert_eq(guard.current_state, guard.State.PATROL, "Reverted to patrol after timer expired")
	assert_false(guard.is_chasing(), "No longer chasing")

	guard.free()

func test_los_resets_chase_timer() -> void:
	"""Test that regaining LoS resets the chase timer."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(5, 5)
	guard.max_chase_turns = 5

	var player_pos = Vector2i(8, 5)

	# Start chase
	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 5, "Chase timer at max")

	# Lose LoS
	guard.set_obstacle(Vector2i(6, 5), true)
	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 4, "Timer decremented")

	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 3, "Timer decremented again")

	# Regain LoS
	guard.set_obstacle(Vector2i(6, 5), false)
	guard.update_ai(player_pos)
	assert_eq(guard.get_chase_turns_remaining(), 5, "LoS resets chase timer")

	guard.free()

func test_pathfinding_around_obstacles() -> void:
	"""Test BFS pathfinding navigates around obstacles."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(0, 0)
	guard.grid_width = 5
	guard.grid_height = 5

	# Create an L-shaped obstacle
	guard.set_obstacle(Vector2i(1, 0), true)
	guard.set_obstacle(Vector2i(1, 1), true)

	var target = Vector2i(2, 0)
	var path = guard.bfs_pathfind(guard.grid_position, target)

	# Path should go around the obstacle
	assert_true(path.size() > 0, "Path found")
	assert_eq(path[0], guard.grid_position, "Path starts at origin")
	assert_eq(path[path.size() - 1], target, "Path ends at target")

	# Check that path doesn't go through obstacles
	for pos in path:
		assert_false(guard.obstacles.get(pos, false), "Path avoids obstacles")

	guard.free()

func test_pathfinding_no_path_available() -> void:
	"""Test pathfinding when target is unreachable."""
	var guard = load("res://scripts/guard.gd").new()
	guard.grid_position = Vector2i(0, 0)
	guard.grid_width = 5
	guard.grid_height = 5

	# Surround target with obstacles
	var target = Vector2i(2, 2)
	guard.set_obstacle(Vector2i(1, 2), true)
	guard.set_obstacle(Vector2i(3, 2), true)
	guard.set_obstacle(Vector2i(2, 1), true)
	guard.set_obstacle(Vector2i(2, 3), true)

	var path = guard.bfs_pathfind(guard.grid_position, target)

	# Should return just the starting position when no path exists
	assert_eq(path.size(), 1, "No path returns start position only")
	assert_eq(path[0], guard.grid_position, "Returns current position")

	guard.free()

func test_bresenham_line_algorithm() -> void:
	"""Test that Bresenham's line algorithm works correctly."""
	var guard = load("res://scripts/guard.gd").new()

	# Test horizontal line
	var line = guard.get_line_cells(Vector2i(0, 0), Vector2i(3, 0))
	assert_eq(line.size(), 4, "Horizontal line has correct length")
	assert_eq(line[0], Vector2i(0, 0), "Line starts correctly")
	assert_eq(line[3], Vector2i(3, 0), "Line ends correctly")

	# Test vertical line
	line = guard.get_line_cells(Vector2i(0, 0), Vector2i(0, 3))
	assert_eq(line.size(), 4, "Vertical line has correct length")

	# Test diagonal line
	line = guard.get_line_cells(Vector2i(0, 0), Vector2i(2, 2))
	assert_eq(line.size(), 3, "Diagonal line has correct length")
	assert_eq(line[1], Vector2i(1, 1), "Diagonal line passes through middle")

	guard.free()
