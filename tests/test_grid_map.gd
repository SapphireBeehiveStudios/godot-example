extends Node
## Grid Map Test Module
##
## Tests for TileGrid class functionality

# Preload the TileGrid class
const TileGrid = preload("res://grid_map.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	# Test basic initialization and configuration
	test_default_grid_size()
	test_custom_grid_size()
	test_default_tile_type()

	# Test bounds checking
	test_is_in_bounds_valid()
	test_is_in_bounds_edges()
	test_is_in_bounds_out_of_bounds()

	# Test tile get/set operations
	test_set_and_get_tile()
	test_set_tile_out_of_bounds()
	test_get_tile_out_of_bounds()

	# Test walkability
	test_walkability_floor()
	test_walkability_wall()
	test_walkability_exit()
	test_walkability_door_open()
	test_walkability_door_closed()
	test_walkability_out_of_bounds()

	# Test door state management
	test_door_state_open()
	test_door_state_closed()
	test_door_state_toggle()

	# Test neighbor queries
	test_get_neighbors_4dir_center()
	test_get_neighbors_4dir_corner()
	test_get_neighbors_4dir_edge()

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

## Test: Default grid size is 24x14
func test_default_grid_size() -> void:
	var grid_map = TileGrid.new()
	assert_eq(grid_map.width, 24, "Default grid width is 24")
	assert_eq(grid_map.height, 14, "Default grid height is 14")

## Test: Custom grid size works
func test_custom_grid_size() -> void:
	var grid_map = TileGrid.new(10, 8)
	assert_eq(grid_map.width, 10, "Custom grid width is 10")
	assert_eq(grid_map.height, 8, "Custom grid height is 8")

## Test: Default tile type is FLOOR
func test_default_tile_type() -> void:
	var grid_map = TileGrid.new(5, 5)
	var tile = grid_map.get_tile(Vector2i(2, 2))
	assert_eq(tile, TileGrid.TileType.FLOOR, "Default tile type is FLOOR")

## Test: is_in_bounds returns true for valid positions
func test_is_in_bounds_valid() -> void:
	var grid_map = TileGrid.new(10, 8)
	assert_true(grid_map.is_in_bounds(Vector2i(0, 0)), "Top-left is in bounds")
	assert_true(grid_map.is_in_bounds(Vector2i(5, 4)), "Center is in bounds")
	assert_true(grid_map.is_in_bounds(Vector2i(9, 7)), "Bottom-right is in bounds")

## Test: is_in_bounds works correctly at edges
func test_is_in_bounds_edges() -> void:
	var grid_map = TileGrid.new(10, 8)
	assert_true(grid_map.is_in_bounds(Vector2i(0, 0)), "Top-left edge is in bounds")
	assert_true(grid_map.is_in_bounds(Vector2i(9, 0)), "Top-right edge is in bounds")
	assert_true(grid_map.is_in_bounds(Vector2i(0, 7)), "Bottom-left edge is in bounds")
	assert_true(grid_map.is_in_bounds(Vector2i(9, 7)), "Bottom-right edge is in bounds")

## Test: is_in_bounds returns false for out-of-bounds positions
func test_is_in_bounds_out_of_bounds() -> void:
	var grid_map = TileGrid.new(10, 8)
	assert_false(grid_map.is_in_bounds(Vector2i(-1, 0)), "Negative x is out of bounds")
	assert_false(grid_map.is_in_bounds(Vector2i(0, -1)), "Negative y is out of bounds")
	assert_false(grid_map.is_in_bounds(Vector2i(10, 0)), "x >= width is out of bounds")
	assert_false(grid_map.is_in_bounds(Vector2i(0, 8)), "y >= height is out of bounds")

## Test: set_tile and get_tile work correctly
func test_set_and_get_tile() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.WALL)
	assert_eq(grid_map.get_tile(Vector2i(5, 4)), TileGrid.TileType.WALL, "Set and get WALL tile")

	grid_map.set_tile(Vector2i(3, 2), TileGrid.TileType.EXIT)
	assert_eq(grid_map.get_tile(Vector2i(3, 2)), TileGrid.TileType.EXIT, "Set and get EXIT tile")

## Test: set_tile handles out-of-bounds gracefully
func test_set_tile_out_of_bounds() -> void:
	var grid_map = TileGrid.new(10, 8)
	# This should not crash, just print a warning
	grid_map.set_tile(Vector2i(100, 100), TileGrid.TileType.WALL)
	# Test passes if no crash occurs
	assert_true(true, "set_tile out of bounds doesn't crash")

## Test: get_tile returns -1 for out-of-bounds
func test_get_tile_out_of_bounds() -> void:
	var grid_map = TileGrid.new(10, 8)
	assert_eq(grid_map.get_tile(Vector2i(-1, 0)), -1, "get_tile out of bounds returns -1")
	assert_eq(grid_map.get_tile(Vector2i(100, 100)), -1, "get_tile far out of bounds returns -1")

## Test: FLOOR tiles are walkable
func test_walkability_floor() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.FLOOR)
	assert_true(grid_map.is_walkable(Vector2i(5, 4)), "FLOOR tile is walkable")

## Test: WALL tiles are not walkable
func test_walkability_wall() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.WALL)
	assert_false(grid_map.is_walkable(Vector2i(5, 4)), "WALL tile is not walkable")

## Test: EXIT tiles are walkable
func test_walkability_exit() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.EXIT)
	assert_true(grid_map.is_walkable(Vector2i(5, 4)), "EXIT tile is walkable")

## Test: DOOR_OPEN tiles are walkable
func test_walkability_door_open() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.DOOR_OPEN)
	assert_true(grid_map.is_walkable(Vector2i(5, 4)), "DOOR_OPEN tile is walkable")

## Test: DOOR_CLOSED tiles are not walkable by default
func test_walkability_door_closed() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.DOOR_CLOSED)
	assert_false(grid_map.is_walkable(Vector2i(5, 4)), "DOOR_CLOSED tile is not walkable")

## Test: Out-of-bounds positions are not walkable
func test_walkability_out_of_bounds() -> void:
	var grid_map = TileGrid.new(10, 8)
	assert_false(grid_map.is_walkable(Vector2i(-1, 0)), "Out of bounds is not walkable")
	assert_false(grid_map.is_walkable(Vector2i(100, 100)), "Far out of bounds is not walkable")

## Test: Door state can be set to open
func test_door_state_open() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.DOOR_CLOSED)
	grid_map.set_door_state(Vector2i(5, 4), true)
	assert_true(grid_map.get_door_state(Vector2i(5, 4)), "Door state is open")
	assert_true(grid_map.is_walkable(Vector2i(5, 4)), "Open door is walkable")
	assert_eq(grid_map.get_tile(Vector2i(5, 4)), TileGrid.TileType.DOOR_OPEN, "Door tile updated to DOOR_OPEN")

## Test: Door state can be set to closed
func test_door_state_closed() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.DOOR_OPEN)
	grid_map.set_door_state(Vector2i(5, 4), false)
	assert_false(grid_map.get_door_state(Vector2i(5, 4)), "Door state is closed")
	assert_false(grid_map.is_walkable(Vector2i(5, 4)), "Closed door is not walkable")
	assert_eq(grid_map.get_tile(Vector2i(5, 4)), TileGrid.TileType.DOOR_CLOSED, "Door tile updated to DOOR_CLOSED")

## Test: Door state can be toggled
func test_door_state_toggle() -> void:
	var grid_map = TileGrid.new(10, 8)
	grid_map.set_tile(Vector2i(5, 4), TileGrid.TileType.DOOR_CLOSED)

	# Open the door
	grid_map.set_door_state(Vector2i(5, 4), true)
	assert_true(grid_map.is_walkable(Vector2i(5, 4)), "Door is walkable when open")

	# Close the door
	grid_map.set_door_state(Vector2i(5, 4), false)
	assert_false(grid_map.is_walkable(Vector2i(5, 4)), "Door is not walkable when closed")

	# Open again
	grid_map.set_door_state(Vector2i(5, 4), true)
	assert_true(grid_map.is_walkable(Vector2i(5, 4)), "Door is walkable when opened again")

## Test: get_neighbors_4dir returns 4 neighbors for center positions
func test_get_neighbors_4dir_center() -> void:
	var grid_map = TileGrid.new(10, 8)
	var neighbors = grid_map.get_neighbors_4dir(Vector2i(5, 4))
	assert_eq(neighbors.size(), 4, "Center position has 4 neighbors")

	# Check that all expected neighbors are present
	var expected = [Vector2i(5, 3), Vector2i(6, 4), Vector2i(5, 5), Vector2i(4, 4)]
	for neighbor in expected:
		assert_true(neighbor in neighbors, "Neighbor %s is in list" % neighbor)

## Test: get_neighbors_4dir returns 2 neighbors for corner positions
func test_get_neighbors_4dir_corner() -> void:
	var grid_map = TileGrid.new(10, 8)

	# Top-left corner
	var neighbors_tl = grid_map.get_neighbors_4dir(Vector2i(0, 0))
	assert_eq(neighbors_tl.size(), 2, "Top-left corner has 2 neighbors")

	# Bottom-right corner
	var neighbors_br = grid_map.get_neighbors_4dir(Vector2i(9, 7))
	assert_eq(neighbors_br.size(), 2, "Bottom-right corner has 2 neighbors")

## Test: get_neighbors_4dir returns 3 neighbors for edge positions
func test_get_neighbors_4dir_edge() -> void:
	var grid_map = TileGrid.new(10, 8)

	# Top edge (not corner)
	var neighbors_top = grid_map.get_neighbors_4dir(Vector2i(5, 0))
	assert_eq(neighbors_top.size(), 3, "Top edge has 3 neighbors")

	# Left edge (not corner)
	var neighbors_left = grid_map.get_neighbors_4dir(Vector2i(0, 4))
	assert_eq(neighbors_left.size(), 3, "Left edge has 3 neighbors")

	# Right edge (not corner)
	var neighbors_right = grid_map.get_neighbors_4dir(Vector2i(9, 4))
	assert_eq(neighbors_right.size(), 3, "Right edge has 3 neighbors")

	# Bottom edge (not corner)
	var neighbors_bottom = grid_map.get_neighbors_4dir(Vector2i(5, 7))
	assert_eq(neighbors_bottom.size(), 3, "Bottom edge has 3 neighbors")
