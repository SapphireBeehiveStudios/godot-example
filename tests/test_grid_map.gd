extends RefCounted
## Test suite for GridMap
##
## Tests for grid-based tile management functionality (Issue #17)

const GridMapLogic = preload("res://grid_map.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests and return {passed: int, failed: int}."""
	# Bounds checking tests
	test_default_grid_size()
	test_custom_grid_size()
	test_is_in_bounds_center()
	test_is_in_bounds_corners()
	test_is_in_bounds_edges()
	test_is_in_bounds_out_of_bounds()
	test_is_in_bounds_negative()

	# Tile get/set tests
	test_get_tile_default()
	test_set_and_get_tile()
	test_set_tile_all_types()
	test_get_tile_out_of_bounds()
	test_set_tile_out_of_bounds()

	# Walkability tests
	test_walkability_floor()
	test_walkability_wall()
	test_walkability_door_closed()
	test_walkability_door_open()
	test_walkability_exit()
	test_walkability_out_of_bounds()

	# Neighbor tests
	test_neighbors_center_position()
	test_neighbors_top_left_corner()
	test_neighbors_top_right_corner()
	test_neighbors_bottom_left_corner()
	test_neighbors_bottom_right_corner()
	test_neighbors_top_edge()
	test_neighbors_bottom_edge()
	test_neighbors_left_edge()
	test_neighbors_right_edge()
	test_neighbors_count()

	# Utility tests
	test_clear_grid()

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

func assert_array_size(array: Array, expected_size: int, test_name: String) -> void:
	"""Assert that array has expected size."""
	assert_eq(array.size(), expected_size, test_name)

func assert_contains(array: Array, element, test_name: String) -> void:
	"""Assert that array contains element."""
	if array.has(element):
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: array does not contain %s" % [test_name, element])


## Test implementations - Grid initialization and bounds checking

func test_default_grid_size() -> void:
	"""Test that default grid size is 24x14."""
	var grid = GridMapLogic.new()
	assert_eq(grid.width, 24, "Default grid width is 24")
	assert_eq(grid.height, 14, "Default grid height is 14")

func test_custom_grid_size() -> void:
	"""Test that custom grid size works."""
	var grid = GridMapLogic.new(10, 8)
	assert_eq(grid.width, 10, "Custom grid width is 10")
	assert_eq(grid.height, 8, "Custom grid height is 8")

func test_is_in_bounds_center() -> void:
	"""Test bounds checking for center position."""
	var grid = GridMapLogic.new(10, 10)
	assert_true(grid.is_in_bounds(Vector2i(5, 5)), "Center position is in bounds")

func test_is_in_bounds_corners() -> void:
	"""Test bounds checking for all corner positions."""
	var grid = GridMapLogic.new(10, 10)
	assert_true(grid.is_in_bounds(Vector2i(0, 0)), "Top-left corner is in bounds")
	assert_true(grid.is_in_bounds(Vector2i(9, 0)), "Top-right corner is in bounds")
	assert_true(grid.is_in_bounds(Vector2i(0, 9)), "Bottom-left corner is in bounds")
	assert_true(grid.is_in_bounds(Vector2i(9, 9)), "Bottom-right corner is in bounds")

func test_is_in_bounds_edges() -> void:
	"""Test bounds checking for edge positions."""
	var grid = GridMapLogic.new(10, 10)
	assert_true(grid.is_in_bounds(Vector2i(5, 0)), "Top edge is in bounds")
	assert_true(grid.is_in_bounds(Vector2i(5, 9)), "Bottom edge is in bounds")
	assert_true(grid.is_in_bounds(Vector2i(0, 5)), "Left edge is in bounds")
	assert_true(grid.is_in_bounds(Vector2i(9, 5)), "Right edge is in bounds")

func test_is_in_bounds_out_of_bounds() -> void:
	"""Test bounds checking for out of bounds positions."""
	var grid = GridMapLogic.new(10, 10)
	assert_false(grid.is_in_bounds(Vector2i(10, 5)), "Beyond right edge is out of bounds")
	assert_false(grid.is_in_bounds(Vector2i(5, 10)), "Beyond bottom edge is out of bounds")
	assert_false(grid.is_in_bounds(Vector2i(10, 10)), "Beyond bottom-right corner is out of bounds")

func test_is_in_bounds_negative() -> void:
	"""Test bounds checking for negative positions."""
	var grid = GridMapLogic.new(10, 10)
	assert_false(grid.is_in_bounds(Vector2i(-1, 5)), "Negative x is out of bounds")
	assert_false(grid.is_in_bounds(Vector2i(5, -1)), "Negative y is out of bounds")
	assert_false(grid.is_in_bounds(Vector2i(-1, -1)), "Negative x and y is out of bounds")


## Test implementations - Tile get/set

func test_get_tile_default() -> void:
	"""Test that tiles default to FLOOR type."""
	var grid = GridMapLogic.new(5, 5)
	assert_eq(grid.get_tile(Vector2i(2, 2)), GridMapLogic.TileType.FLOOR, "Default tile is FLOOR")

func test_set_and_get_tile() -> void:
	"""Test setting and getting a tile."""
	var grid = GridMapLogic.new(5, 5)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.WALL)
	assert_eq(grid.get_tile(Vector2i(2, 2)), GridMapLogic.TileType.WALL, "Tile type is set correctly")

func test_set_tile_all_types() -> void:
	"""Test setting all tile types."""
	var grid = GridMapLogic.new(10, 10)

	grid.set_tile(Vector2i(0, 0), GridMapLogic.TileType.FLOOR)
	assert_eq(grid.get_tile(Vector2i(0, 0)), GridMapLogic.TileType.FLOOR, "Can set FLOOR tile")

	grid.set_tile(Vector2i(1, 0), GridMapLogic.TileType.WALL)
	assert_eq(grid.get_tile(Vector2i(1, 0)), GridMapLogic.TileType.WALL, "Can set WALL tile")

	grid.set_tile(Vector2i(2, 0), GridMapLogic.TileType.DOOR_CLOSED)
	assert_eq(grid.get_tile(Vector2i(2, 0)), GridMapLogic.TileType.DOOR_CLOSED, "Can set DOOR_CLOSED tile")

	grid.set_tile(Vector2i(3, 0), GridMapLogic.TileType.DOOR_OPEN)
	assert_eq(grid.get_tile(Vector2i(3, 0)), GridMapLogic.TileType.DOOR_OPEN, "Can set DOOR_OPEN tile")

	grid.set_tile(Vector2i(4, 0), GridMapLogic.TileType.EXIT)
	assert_eq(grid.get_tile(Vector2i(4, 0)), GridMapLogic.TileType.EXIT, "Can set EXIT tile")

func test_get_tile_out_of_bounds() -> void:
	"""Test getting tile from out of bounds position returns FLOOR."""
	var grid = GridMapLogic.new(5, 5)
	assert_eq(grid.get_tile(Vector2i(10, 10)), GridMapLogic.TileType.FLOOR, "Out of bounds returns FLOOR")
	assert_eq(grid.get_tile(Vector2i(-1, -1)), GridMapLogic.TileType.FLOOR, "Negative position returns FLOOR")

func test_set_tile_out_of_bounds() -> void:
	"""Test that setting tile out of bounds is handled gracefully."""
	var grid = GridMapLogic.new(5, 5)
	# Should not crash - just log a warning
	grid.set_tile(Vector2i(10, 10), GridMapLogic.TileType.WALL)
	# Verify it didn't actually set anything weird
	assert_eq(grid.get_tile(Vector2i(10, 10)), GridMapLogic.TileType.FLOOR, "Out of bounds set doesn't affect grid")


## Test implementations - Walkability

func test_walkability_floor() -> void:
	"""Test that FLOOR tiles are walkable."""
	var grid = GridMapLogic.new(5, 5)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.FLOOR)
	assert_true(grid.is_walkable(Vector2i(2, 2)), "FLOOR tile is walkable")

func test_walkability_wall() -> void:
	"""Test that WALL tiles are not walkable."""
	var grid = GridMapLogic.new(5, 5)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.WALL)
	assert_false(grid.is_walkable(Vector2i(2, 2)), "WALL tile is not walkable")

func test_walkability_door_closed() -> void:
	"""Test that DOOR_CLOSED tiles are not walkable."""
	var grid = GridMapLogic.new(5, 5)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.DOOR_CLOSED)
	assert_false(grid.is_walkable(Vector2i(2, 2)), "DOOR_CLOSED tile is not walkable")

func test_walkability_door_open() -> void:
	"""Test that DOOR_OPEN tiles are walkable."""
	var grid = GridMapLogic.new(5, 5)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.DOOR_OPEN)
	assert_true(grid.is_walkable(Vector2i(2, 2)), "DOOR_OPEN tile is walkable")

func test_walkability_exit() -> void:
	"""Test that EXIT tiles are walkable."""
	var grid = GridMapLogic.new(5, 5)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.EXIT)
	assert_true(grid.is_walkable(Vector2i(2, 2)), "EXIT tile is walkable")

func test_walkability_out_of_bounds() -> void:
	"""Test that out of bounds positions are not walkable."""
	var grid = GridMapLogic.new(5, 5)
	assert_false(grid.is_walkable(Vector2i(10, 10)), "Out of bounds is not walkable")
	assert_false(grid.is_walkable(Vector2i(-1, -1)), "Negative position is not walkable")


## Test implementations - Neighbors

func test_neighbors_center_position() -> void:
	"""Test getting neighbors from center position returns 4 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(2, 2))
	assert_array_size(neighbors, 4, "Center position has 4 neighbors")
	assert_contains(neighbors, Vector2i(2, 1), "Contains up neighbor")
	assert_contains(neighbors, Vector2i(2, 3), "Contains down neighbor")
	assert_contains(neighbors, Vector2i(1, 2), "Contains left neighbor")
	assert_contains(neighbors, Vector2i(3, 2), "Contains right neighbor")

func test_neighbors_top_left_corner() -> void:
	"""Test getting neighbors from top-left corner returns 2 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(0, 0))
	assert_array_size(neighbors, 2, "Top-left corner has 2 neighbors")
	assert_contains(neighbors, Vector2i(1, 0), "Contains right neighbor")
	assert_contains(neighbors, Vector2i(0, 1), "Contains down neighbor")

func test_neighbors_top_right_corner() -> void:
	"""Test getting neighbors from top-right corner returns 2 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(4, 0))
	assert_array_size(neighbors, 2, "Top-right corner has 2 neighbors")
	assert_contains(neighbors, Vector2i(3, 0), "Contains left neighbor")
	assert_contains(neighbors, Vector2i(4, 1), "Contains down neighbor")

func test_neighbors_bottom_left_corner() -> void:
	"""Test getting neighbors from bottom-left corner returns 2 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(0, 4))
	assert_array_size(neighbors, 2, "Bottom-left corner has 2 neighbors")
	assert_contains(neighbors, Vector2i(1, 4), "Contains right neighbor")
	assert_contains(neighbors, Vector2i(0, 3), "Contains up neighbor")

func test_neighbors_bottom_right_corner() -> void:
	"""Test getting neighbors from bottom-right corner returns 2 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(4, 4))
	assert_array_size(neighbors, 2, "Bottom-right corner has 2 neighbors")
	assert_contains(neighbors, Vector2i(3, 4), "Contains left neighbor")
	assert_contains(neighbors, Vector2i(4, 3), "Contains up neighbor")

func test_neighbors_top_edge() -> void:
	"""Test getting neighbors from top edge returns 3 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(2, 0))
	assert_array_size(neighbors, 3, "Top edge has 3 neighbors")
	assert_contains(neighbors, Vector2i(1, 0), "Contains left neighbor")
	assert_contains(neighbors, Vector2i(3, 0), "Contains right neighbor")
	assert_contains(neighbors, Vector2i(2, 1), "Contains down neighbor")

func test_neighbors_bottom_edge() -> void:
	"""Test getting neighbors from bottom edge returns 3 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(2, 4))
	assert_array_size(neighbors, 3, "Bottom edge has 3 neighbors")
	assert_contains(neighbors, Vector2i(1, 4), "Contains left neighbor")
	assert_contains(neighbors, Vector2i(3, 4), "Contains right neighbor")
	assert_contains(neighbors, Vector2i(2, 3), "Contains up neighbor")

func test_neighbors_left_edge() -> void:
	"""Test getting neighbors from left edge returns 3 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(0, 2))
	assert_array_size(neighbors, 3, "Left edge has 3 neighbors")
	assert_contains(neighbors, Vector2i(0, 1), "Contains up neighbor")
	assert_contains(neighbors, Vector2i(0, 3), "Contains down neighbor")
	assert_contains(neighbors, Vector2i(1, 2), "Contains right neighbor")

func test_neighbors_right_edge() -> void:
	"""Test getting neighbors from right edge returns 3 neighbors."""
	var grid = GridMapLogic.new(5, 5)
	var neighbors = grid.get_neighbors_4dir(Vector2i(4, 2))
	assert_array_size(neighbors, 3, "Right edge has 3 neighbors")
	assert_contains(neighbors, Vector2i(4, 1), "Contains up neighbor")
	assert_contains(neighbors, Vector2i(4, 3), "Contains down neighbor")
	assert_contains(neighbors, Vector2i(3, 2), "Contains left neighbor")

func test_neighbors_count() -> void:
	"""Test that neighbor count is always <= 4."""
	var grid = GridMapLogic.new(10, 10)
	# Test several random positions
	for y in range(10):
		for x in range(10):
			var neighbors = grid.get_neighbors_4dir(Vector2i(x, y))
			assert_true(neighbors.size() <= 4, "Position (%d,%d) has <= 4 neighbors" % [x, y])


## Test implementations - Utilities

func test_clear_grid() -> void:
	"""Test that clear() resets all tiles to FLOOR."""
	var grid = GridMapLogic.new(3, 3)

	# Set some tiles to different types
	grid.set_tile(Vector2i(0, 0), GridMapLogic.TileType.WALL)
	grid.set_tile(Vector2i(1, 1), GridMapLogic.TileType.DOOR_CLOSED)
	grid.set_tile(Vector2i(2, 2), GridMapLogic.TileType.EXIT)

	# Clear the grid
	grid.clear()

	# Verify all tiles are now FLOOR
	for y in range(3):
		for x in range(3):
			assert_eq(
				grid.get_tile(Vector2i(x, y)),
				GridMapLogic.TileType.FLOOR,
				"Tile (%d,%d) is FLOOR after clear" % [x, y]
			)
