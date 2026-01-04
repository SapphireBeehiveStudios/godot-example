extends Node
## Door and Keycard Placement Validation Test Module
##
## Tests door and keycard placement rules (Issue #27).
## Ensures that:
## - If doors are placed, at least one keycard exists
## - At least one keycard is reachable without needing doors (no softlock)

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_no_doors_no_keycards_is_valid()
	test_no_doors_with_keycards_is_valid()
	test_doors_without_keycards_is_invalid()
	test_doors_with_reachable_keycard_is_valid()
	test_doors_with_unreachable_keycard_is_invalid()
	test_multiple_keycards_one_reachable_is_valid()
	test_keycard_behind_door_is_invalid()
	test_complex_layout_with_multiple_paths()
	test_door_blocks_movement_in_turn_system()
	test_keycard_placement_in_disconnected_area()
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

func test_no_doors_no_keycards_is_valid() -> void:
	"""Test that a layout without doors or keycards is valid."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "floor"},
		Vector2i(2, 0): {"type": "wall"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_true(result.valid, "Layout without doors/keycards is valid")
	assert_eq(result.errors.size(), 0, "No errors for valid layout")

func test_no_doors_with_keycards_is_valid() -> void:
	"""Test that a layout with keycards but no doors is valid."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "pickup", "pickup_type": "keycard"},
		Vector2i(2, 0): {"type": "floor"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_true(result.valid, "Layout with keycards but no doors is valid")

func test_doors_without_keycards_is_invalid() -> void:
	"""Test that doors without any keycards is invalid (softlock)."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "door"},
		Vector2i(2, 0): {"type": "floor"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_false(result.valid, "Doors without keycards is invalid")
	assert_true(result.errors.size() > 0, "Error reported for missing keycards")

	# Check error message
	var has_softlock_error = false
	for error in result.errors:
		if "softlocked" in error.to_lower():
			has_softlock_error = true
			break
	assert_true(has_softlock_error, "Error mentions softlock")

func test_doors_with_reachable_keycard_is_valid() -> void:
	"""Test that doors with at least one reachable keycard is valid."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	# Layout: Player at (0,0), keycard at (1,0), door at (2,0)
	# Keycard is reachable without going through door
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "pickup", "pickup_type": "keycard"},
		Vector2i(2, 0): {"type": "door"},
		Vector2i(3, 0): {"type": "floor"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_true(result.valid, "Doors with reachable keycard is valid")
	assert_eq(result.errors.size(), 0, "No errors when keycard is reachable")

func test_doors_with_unreachable_keycard_is_invalid() -> void:
	"""Test that doors with only unreachable keycards is invalid."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	# Layout: Player at (0,0), door at (1,0), keycard at (2,0)
	# Keycard is behind door - unreachable without door access
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "door"},
		Vector2i(2, 0): {"type": "pickup", "pickup_type": "keycard"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_false(result.valid, "Keycard behind door is invalid (softlock)")
	assert_true(result.errors.size() > 0, "Error reported for unreachable keycard")

func test_multiple_keycards_one_reachable_is_valid() -> void:
	"""Test that having multiple keycards with at least one reachable is valid."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	# Layout:
	#   Player at (0,0)
	#   Keycard at (1,0) - reachable
	#   Door at (0,1)
	#   Keycard at (0,2) - behind door
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "pickup", "pickup_type": "keycard"},
		Vector2i(0, 1): {"type": "door"},
		Vector2i(0, 2): {"type": "pickup", "pickup_type": "keycard"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_true(result.valid, "At least one reachable keycard makes layout valid")

func test_keycard_behind_door_is_invalid() -> void:
	"""Test that all keycards behind doors creates a deadlock."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	# Layout:
	#   (0,0) floor - player start
	#   (1,0) door
	#   (2,0) keycard - needs door to reach
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "door"},
		Vector2i(2, 0): {"type": "pickup", "pickup_type": "keycard"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_false(result.valid, "Keycard only accessible through door is invalid")

func test_complex_layout_with_multiple_paths() -> void:
	"""Test a more complex layout with multiple paths and validation."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	# Layout (simple room):
	#   W W W W W
	#   W P . k W
	#   W . D . W
	#   W . . . W
	#   W W W W W
	# P = player start (1,1)
	# k = keycard (3,1)
	# D = door (2,2)
	# . = floor
	# W = wall

	var grid = {
		# Walls (top row)
		Vector2i(0, 0): {"type": "wall"},
		Vector2i(1, 0): {"type": "wall"},
		Vector2i(2, 0): {"type": "wall"},
		Vector2i(3, 0): {"type": "wall"},
		Vector2i(4, 0): {"type": "wall"},
		# Row 1
		Vector2i(0, 1): {"type": "wall"},
		Vector2i(1, 1): {"type": "floor"},  # Player start
		Vector2i(2, 1): {"type": "floor"},
		Vector2i(3, 1): {"type": "pickup", "pickup_type": "keycard"},
		Vector2i(4, 1): {"type": "wall"},
		# Row 2
		Vector2i(0, 2): {"type": "wall"},
		Vector2i(1, 2): {"type": "floor"},
		Vector2i(2, 2): {"type": "door"},
		Vector2i(3, 2): {"type": "floor"},
		Vector2i(4, 2): {"type": "wall"},
		# Row 3
		Vector2i(0, 3): {"type": "wall"},
		Vector2i(1, 3): {"type": "floor"},
		Vector2i(2, 3): {"type": "floor"},
		Vector2i(3, 3): {"type": "floor"},
		Vector2i(4, 3): {"type": "wall"},
		# Walls (bottom row)
		Vector2i(0, 4): {"type": "wall"},
		Vector2i(1, 4): {"type": "wall"},
		Vector2i(2, 4): {"type": "wall"},
		Vector2i(3, 4): {"type": "wall"},
		Vector2i(4, 4): {"type": "wall"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(1, 1))
	assert_true(result.valid, "Complex layout with reachable keycard is valid")

func test_door_blocks_movement_in_turn_system() -> void:
	"""Test that doors block player movement in TurnSystem."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Setup: Player at (0,0), door at (1,0), floor at (2,0)
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_door(Vector2i(1, 0))
	turn_system.set_grid_tile(Vector2i(2, 0), "floor")

	# Verify door is not walkable
	assert_false(turn_system.is_tile_walkable(Vector2i(1, 0)), "Door is not walkable")

	# Try to move through door (should fail)
	var success = turn_system.execute_turn("move", Vector2i(1, 0))
	assert_false(success, "Cannot move through door")
	assert_eq(turn_system.get_player_position(), Vector2i(0, 0), "Player position unchanged")

	turn_system.free()

func test_keycard_placement_in_disconnected_area() -> void:
	"""Test that keycard in completely disconnected area is detected as unreachable."""
	var PlacementValidator = load("res://scripts/utils/placement_validator.gd")

	# Layout:
	#   (0,0) floor - player
	#   (1,0) wall
	#   (2,0) keycard - unreachable (walled off)
	#   (3,0) door - exists so keycard is required
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "wall"},
		Vector2i(2, 0): {"type": "pickup", "pickup_type": "keycard"},
		Vector2i(3, 0): {"type": "door"},
	}

	var result = PlacementValidator.validate_door_keycard_placement(grid, Vector2i(0, 0))
	assert_false(result.valid, "Keycard in disconnected area is invalid")
