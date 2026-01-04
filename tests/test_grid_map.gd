extends Node
## Grid Map Test Module
##
## Tests for line-of-sight functionality in grid_map.gd

var tests_passed := 0
var tests_failed := 0
var grid_map = null

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	# Load the grid_map script
	grid_map = load("res://grid_map.gd").new()

	test_same_position_has_los()
	test_horizontal_clear_corridor()
	test_vertical_clear_corridor()
	test_horizontal_wall_blocker()
	test_vertical_wall_blocker()
	test_horizontal_closed_door_blocker()
	test_vertical_closed_door_blocker()
	test_horizontal_open_door_no_block()
	test_vertical_open_door_no_block()
	test_diagonal_no_los()
	test_out_of_bounds()
	test_adjacent_positions()
	test_multiple_blockers()

	# Clean up
	grid_map.free()

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

## Test implementations
func test_same_position_has_los() -> void:
	"""Test that same position always has LoS."""
	var grid = [[0, 0], [0, 0]]
	var pos = Vector2i(0, 0)
	assert_true(
		grid_map.has_line_of_sight(pos, pos, grid),
		"Same position has LoS"
	)

func test_horizontal_clear_corridor() -> void:
	"""Test horizontal LoS with clear corridor (acceptance criteria)."""
	# Create a grid with a clear horizontal corridor
	# E E E E E  (row 0)
	# W W W W W  (row 1)
	var grid = [
		[0, 0, 0, 0, 0],  # All empty
		[1, 1, 1, 1, 1]   # All walls
	]

	# Test horizontal LoS in clear row
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(4, 0), grid),
		"Clear horizontal corridor has LoS"
	)

	# Test reverse direction
	assert_true(
		grid_map.has_line_of_sight(Vector2i(4, 0), Vector2i(0, 0), grid),
		"Clear horizontal corridor has LoS (reverse)"
	)

func test_vertical_clear_corridor() -> void:
	"""Test vertical LoS with clear corridor (acceptance criteria)."""
	# Create a grid with a clear vertical corridor
	# E W
	# E W
	# E W
	# E W
	var grid = [
		[0, 1],
		[0, 1],
		[0, 1],
		[0, 1]
	]

	# Test vertical LoS in clear column
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(0, 3), grid),
		"Clear vertical corridor has LoS"
	)

	# Test reverse direction
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 3), Vector2i(0, 0), grid),
		"Clear vertical corridor has LoS (reverse)"
	)

func test_horizontal_wall_blocker() -> void:
	"""Test horizontal LoS blocked by wall (acceptance criteria)."""
	# Create a grid with a wall blocker
	# E E W E E
	var grid = [
		[0, 0, 1, 0, 0]
	]

	# Test LoS blocked by wall
	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(4, 0), grid),
		"Wall blocks horizontal LoS"
	)

	# Test reverse direction
	assert_false(
		grid_map.has_line_of_sight(Vector2i(4, 0), Vector2i(0, 0), grid),
		"Wall blocks horizontal LoS (reverse)"
	)

func test_vertical_wall_blocker() -> void:
	"""Test vertical LoS blocked by wall (acceptance criteria)."""
	# Create a grid with a wall blocker
	# E
	# E
	# W
	# E
	# E
	var grid = [
		[0],
		[0],
		[1],
		[0],
		[0]
	]

	# Test LoS blocked by wall
	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(0, 4), grid),
		"Wall blocks vertical LoS"
	)

func test_horizontal_closed_door_blocker() -> void:
	"""Test horizontal LoS blocked by closed door (acceptance criteria)."""
	# Create a grid with a closed door blocker
	# E E DC E E
	var grid = [
		[0, 0, 3, 0, 0]  # 3 = DOOR_CLOSED
	]

	# Test LoS blocked by closed door
	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(4, 0), grid),
		"Closed door blocks horizontal LoS"
	)

func test_vertical_closed_door_blocker() -> void:
	"""Test vertical LoS blocked by closed door (acceptance criteria)."""
	# Create a grid with a closed door blocker
	# E
	# E
	# DC
	# E
	var grid = [
		[0],
		[0],
		[3],  # 3 = DOOR_CLOSED
		[0]
	]

	# Test LoS blocked by closed door
	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(0, 3), grid),
		"Closed door blocks vertical LoS"
	)

func test_horizontal_open_door_no_block() -> void:
	"""Test horizontal LoS not blocked by open door."""
	# Create a grid with an open door
	# E E DO E E
	var grid = [
		[0, 0, 2, 0, 0]  # 2 = DOOR_OPEN
	]

	# Test LoS not blocked by open door
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(4, 0), grid),
		"Open door does not block horizontal LoS"
	)

func test_vertical_open_door_no_block() -> void:
	"""Test vertical LoS not blocked by open door."""
	# Create a grid with an open door
	# E
	# E
	# DO
	# E
	var grid = [
		[0],
		[0],
		[2],  # 2 = DOOR_OPEN
		[0]
	]

	# Test LoS not blocked by open door
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(0, 3), grid),
		"Open door does not block vertical LoS"
	)

func test_diagonal_no_los() -> void:
	"""Test that diagonal positions don't have LoS."""
	var grid = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]
	]

	# Test diagonal positions
	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(2, 2), grid),
		"Diagonal positions have no LoS"
	)

	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 2), Vector2i(2, 0), grid),
		"Diagonal positions have no LoS (reverse diagonal)"
	)

func test_out_of_bounds() -> void:
	"""Test that out-of-bounds checks work properly."""
	var grid = [
		[0, 0],
		[0, 0]
	]

	# Test with out-of-bounds target
	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(5, 0), grid),
		"Out of bounds horizontal returns false"
	)

	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(0, 5), grid),
		"Out of bounds vertical returns false"
	)

func test_adjacent_positions() -> void:
	"""Test LoS for adjacent positions."""
	var grid = [
		[0, 0, 0],
		[0, 0, 0]
	]

	# Adjacent horizontal
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(1, 0), grid),
		"Adjacent horizontal positions have LoS"
	)

	# Adjacent vertical
	assert_true(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(0, 1), grid),
		"Adjacent vertical positions have LoS"
	)

func test_multiple_blockers() -> void:
	"""Test that first blocker is sufficient to block LoS."""
	# Create a grid with multiple blockers
	# E W W E
	var grid = [
		[0, 1, 1, 0]
	]

	assert_false(
		grid_map.has_line_of_sight(Vector2i(0, 0), Vector2i(3, 0), grid),
		"First blocker blocks LoS (multiple blockers)"
	)
