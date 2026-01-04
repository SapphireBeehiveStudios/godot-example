extends Node
## Pathfinding Test Module
##
## Tests for the BFS pathfinding implementation.

const Pathfinding = preload("res://scripts/pathfinding.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_simple_straight_path()
	test_path_around_obstacle()
	test_no_path_exists()
	test_start_equals_goal()
	test_invalid_start_position()
	test_invalid_goal_position()
	test_start_on_obstacle()
	test_goal_on_obstacle()
	test_empty_grid()
	test_complex_maze()
	test_path_length_is_shortest()
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

func assert_array_eq(actual: Array, expected: Array, test_name: String) -> void:
	"""Assert that two arrays are equal."""
	if actual.size() != expected.size():
		tests_failed += 1
		print("  ✗ %s: array size mismatch - expected %d, got %d" % [test_name, expected.size(), actual.size()])
		return

	for i in range(actual.size()):
		if actual[i] != expected[i]:
			tests_failed += 1
			print("  ✗ %s: arrays differ at index %d - expected %s, got %s" % [test_name, i, expected[i], actual[i]])
			return

	tests_passed += 1
	print("  ✓ %s" % test_name)

## Test implementations

func test_simple_straight_path() -> void:
	"""Test a simple straight horizontal path."""
	var grid = [
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(4, 0)
	var path = Pathfinding.find_path(grid, start, goal)

	var expected = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(4, 0),
	]

	assert_array_eq(path, expected, "Simple straight horizontal path")

func test_path_around_obstacle() -> void:
	"""Test pathfinding around a simple obstacle."""
	var grid = [
		[0, 0, 0, 0, 0],
		[0, 1, 1, 1, 0],
		[0, 0, 0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(4, 0)
	var path = Pathfinding.find_path(grid, start, goal)

	# Path should go around the obstacle
	assert_true(path.size() > 0, "Path exists around obstacle")
	assert_eq(path[0], start, "Path starts at start position")
	assert_eq(path[path.size() - 1], goal, "Path ends at goal position")

	# Verify no path goes through obstacles
	for pos in path:
		assert_eq(grid[pos.y][pos.x], 0, "Path does not go through obstacles")

func test_no_path_exists() -> void:
	"""Test when no path exists due to complete blockage."""
	var grid = [
		[0, 0, 0, 0, 0],
		[1, 1, 1, 1, 1],
		[0, 0, 0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(0, 2)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_eq(path.size(), 0, "No path exists when blocked")

func test_start_equals_goal() -> void:
	"""Test when start position equals goal position."""
	var grid = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
	]
	var start = Vector2i(1, 1)
	var goal = Vector2i(1, 1)
	var path = Pathfinding.find_path(grid, start, goal)

	var expected = [Vector2i(1, 1)]
	assert_array_eq(path, expected, "Start equals goal returns single-element path")

func test_invalid_start_position() -> void:
	"""Test with start position out of bounds."""
	var grid = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
	]
	var start = Vector2i(-1, 0)
	var goal = Vector2i(2, 2)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_eq(path.size(), 0, "Invalid start position returns empty path")

func test_invalid_goal_position() -> void:
	"""Test with goal position out of bounds."""
	var grid = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(5, 5)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_eq(path.size(), 0, "Invalid goal position returns empty path")

func test_start_on_obstacle() -> void:
	"""Test when start position is on an obstacle."""
	var grid = [
		[1, 0, 0],
		[0, 0, 0],
		[0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(2, 2)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_eq(path.size(), 0, "Start on obstacle returns empty path")

func test_goal_on_obstacle() -> void:
	"""Test when goal position is on an obstacle."""
	var grid = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 1],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(2, 2)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_eq(path.size(), 0, "Goal on obstacle returns empty path")

func test_empty_grid() -> void:
	"""Test with an empty grid."""
	var grid = []
	var start = Vector2i(0, 0)
	var goal = Vector2i(1, 1)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_eq(path.size(), 0, "Empty grid returns empty path")

func test_complex_maze() -> void:
	"""Test pathfinding through a more complex maze."""
	var grid = [
		[0, 0, 1, 0, 0],
		[0, 1, 1, 0, 1],
		[0, 0, 0, 0, 0],
		[1, 1, 0, 1, 0],
		[0, 0, 0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(4, 4)
	var path = Pathfinding.find_path(grid, start, goal)

	assert_true(path.size() > 0, "Path exists through complex maze")
	assert_eq(path[0], start, "Path starts at start position")
	assert_eq(path[path.size() - 1], goal, "Path ends at goal position")

	# Verify path continuity (each step is adjacent)
	for i in range(1, path.size()):
		var prev = path[i - 1]
		var curr = path[i]
		var distance = abs(curr.x - prev.x) + abs(curr.y - prev.y)
		assert_eq(distance, 1, "Path steps are adjacent (4-directional)")

func test_path_length_is_shortest() -> void:
	"""Test that BFS returns the shortest path."""
	var grid = [
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0],
	]
	var start = Vector2i(0, 0)
	var goal = Vector2i(2, 2)
	var path = Pathfinding.find_path(grid, start, goal)

	# Shortest path from (0,0) to (2,2) has length 5 (Manhattan distance + 1)
	# Path: (0,0) -> (1,0) -> (2,0) -> (2,1) -> (2,2) or similar
	var manhattan_distance = abs(goal.x - start.x) + abs(goal.y - start.y)
	assert_eq(path.size(), manhattan_distance + 1, "BFS returns shortest path length")
