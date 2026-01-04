extends Node
## Test Module for GuardSystem
##
## Tests guard entities and patrol behavior including:
## - Guards move once per turn during guard phase
## - Patrol does not move into walls/closed doors
## - Guard patrol step respects walkability
##
## Part of EPIC 4 - Issue #31

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_guard_creation()
	test_guard_patrol_movement()
	test_guard_respects_walls()
	test_guard_random_direction_on_blocked()
	test_guard_stays_if_surrounded()
	test_multiple_guards_move()
	test_guard_phase_integration()
	test_guard_capture_player()
	test_walkability_callback()
	test_guard_momentum_continues()
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

func assert_not_eq(actual, not_expected, test_name: String) -> void:
	"""Assert that actual does not equal not_expected."""
	if actual != not_expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: value should not be %s" % [test_name, not_expected])

## Test implementations

func test_guard_creation() -> void:
	"""Test that guards can be created and added to the system."""
	var guard_system = load("res://scripts/guard_system.gd").new()

	# Initially no guards
	assert_eq(guard_system.get_guard_count(), 0, "Initial guard count is 0")

	# Add a guard
	var guard = guard_system.add_guard(Vector2i(5, 5))
	assert_eq(guard_system.get_guard_count(), 1, "Guard count is 1 after adding")
	assert_eq(guard.position, Vector2i(5, 5), "Guard position is correct")

	# Add another guard
	guard_system.add_guard(Vector2i(10, 10))
	assert_eq(guard_system.get_guard_count(), 2, "Guard count is 2 after adding second")

	guard_system.free()

func test_guard_patrol_movement() -> void:
	"""Test that guard patrol behavior moves the guard."""
	var guard_system = load("res://scripts/guard_system.gd").new(12345)

	# Add a guard in an open area
	var guard = guard_system.add_guard(Vector2i(5, 5))
	var initial_pos = guard.position

	# Process guard phase (guard should move)
	var result = guard_system.process_guard_phase()
	assert_eq(result.guards_moved, 1, "One guard moved")

	# Guard should have moved from initial position
	assert_not_eq(guard.position, initial_pos, "Guard moved from initial position")

	guard_system.free()

func test_guard_respects_walls() -> void:
	"""Test that guards do not move into walls."""
	var guard_system = load("res://scripts/guard_system.gd").new(12345)
	var turn_system = load("res://scripts/turn_system.gd").new(12345)

	# Set up a corridor: guard at (5,5) with walls on all sides except right
	turn_system.set_grid_tile(Vector2i(4, 5), "wall")  # Left
	turn_system.set_grid_tile(Vector2i(5, 4), "wall")  # Up
	turn_system.set_grid_tile(Vector2i(5, 6), "wall")  # Down
	# Right side (6, 5) is open

	# Add guard and set walkability checker
	var guard = guard_system.add_guard(Vector2i(5, 5))
	guard_system.set_walkability_checker(turn_system.is_tile_walkable)

	# Set guard's initial direction to left (into wall)
	guard.patrol_direction = Vector2i(-1, 0)

	# Process guard phase
	guard_system.process_guard_phase()

	# Guard should have changed direction and moved right (only valid option)
	assert_eq(guard.position, Vector2i(6, 5), "Guard moved right to avoid walls")

	turn_system.free()
	guard_system.free()

func test_guard_random_direction_on_blocked() -> void:
	"""Test that guard picks a random valid direction when blocked."""
	var guard_system = load("res://scripts/guard_system.gd").new(54321)
	var turn_system = load("res://scripts/turn_system.gd").new(54321)

	# Set up: guard at (5,5) facing up (blocked), with left and right open
	turn_system.set_grid_tile(Vector2i(5, 4), "wall")  # Up (blocked)
	turn_system.set_grid_tile(Vector2i(5, 6), "wall")  # Down (blocked)
	# Left (4,5) and Right (6,5) are open

	var guard = guard_system.add_guard(Vector2i(5, 5))
	guard.patrol_direction = Vector2i(0, -1)  # Facing up (blocked)
	guard_system.set_walkability_checker(turn_system.is_tile_walkable)

	# Process guard phase
	guard_system.process_guard_phase()

	# Guard should have moved left or right
	var moved_horizontally = (guard.position == Vector2i(4, 5)) or (guard.position == Vector2i(6, 5))
	assert_true(moved_horizontally, "Guard moved to valid horizontal direction")

	turn_system.free()
	guard_system.free()

func test_guard_stays_if_surrounded() -> void:
	"""Test that guard stays in place if completely surrounded by walls."""
	var guard_system = load("res://scripts/guard_system.gd").new(12345)
	var turn_system = load("res://scripts/turn_system.gd").new(12345)

	# Surround guard with walls
	turn_system.set_grid_tile(Vector2i(4, 5), "wall")  # Left
	turn_system.set_grid_tile(Vector2i(6, 5), "wall")  # Right
	turn_system.set_grid_tile(Vector2i(5, 4), "wall")  # Up
	turn_system.set_grid_tile(Vector2i(5, 6), "wall")  # Down

	var guard = guard_system.add_guard(Vector2i(5, 5))
	guard_system.set_walkability_checker(turn_system.is_tile_walkable)

	# Process guard phase
	guard_system.process_guard_phase()

	# Guard should not have moved
	assert_eq(guard.position, Vector2i(5, 5), "Guard stays in place when surrounded")

	turn_system.free()
	guard_system.free()

func test_multiple_guards_move() -> void:
	"""Test that multiple guards all move during guard phase."""
	var guard_system = load("res://scripts/guard_system.gd").new(12345)

	# Add three guards
	guard_system.add_guard(Vector2i(0, 0))
	guard_system.add_guard(Vector2i(10, 10))
	guard_system.add_guard(Vector2i(20, 20))

	# Process guard phase
	var result = guard_system.process_guard_phase()

	# All three guards should have moved
	assert_eq(result.guards_moved, 3, "All three guards moved")
	assert_eq(result.guard_positions.size(), 3, "Three guard positions returned")

	guard_system.free()

func test_guard_phase_integration() -> void:
	"""Test that guard phase integrates with turn system."""
	var turn_system = load("res://scripts/turn_system.gd").new(12345)
	var guard_system = load("res://scripts/guard_system.gd").new(12345)

	# Set up guard system
	turn_system.set_guard_system(guard_system)

	# Add a guard
	guard_system.add_guard(Vector2i(10, 10))

	# Process a player turn
	var result = turn_system.process_turn("wait")

	# Result should include guard info
	assert_true("guard_info" in result, "Turn result includes guard info")
	assert_eq(result.guard_info.guards_moved, 1, "Guard moved during turn")

	turn_system.free()
	guard_system.free()

func test_guard_capture_player() -> void:
	"""Test that game ends when guard reaches player position."""
	var turn_system = load("res://scripts/turn_system.gd").new(12345)
	var guard_system = load("res://scripts/guard_system.gd").new(12345)

	turn_system.set_guard_system(guard_system)
	turn_system.player_position = Vector2i(5, 5)

	# Add guard next to player, moving toward player
	var guard = guard_system.add_guard(Vector2i(4, 5))
	guard.patrol_direction = Vector2i(1, 0)  # Moving right toward player

	# Process turn - guard should move onto player
	var result = turn_system.process_turn("wait")

	# Game should be lost
	assert_eq(result.game_state, "lost", "Game state is 'lost' when guard captures player")
	assert_true(turn_system.game_over, "Game over flag is set")

	turn_system.free()
	guard_system.free()

func test_walkability_callback() -> void:
	"""Test that guards correctly use walkability callback."""
	var guard_system = load("res://scripts/guard_system.gd").new(12345)

	# Create a simple walkability function: only (1,0) is walkable
	var walkable_checker = func(pos: Vector2i) -> bool:
		return pos == Vector2i(1, 0)

	guard_system.set_walkability_checker(walkable_checker)

	# Add guard at (0,0)
	var guard = guard_system.add_guard(Vector2i(0, 0))
	guard.patrol_direction = Vector2i(1, 0)  # Moving right to (1,0) - walkable

	# Process guard phase
	guard_system.process_guard_phase()

	# Guard should have moved to (1,0)
	assert_eq(guard.position, Vector2i(1, 0), "Guard moved to walkable tile")

	# Now try to move again - (2,0) is not walkable, guard should stay or change direction
	var prev_pos = guard.position
	guard_system.process_guard_phase()

	# Guard should either stay at (1,0) or move to another valid position
	# Since only (1,0) is valid, guard must stay at (1,0)
	assert_eq(guard.position, Vector2i(1, 0), "Guard stays when no valid moves available")

	guard_system.free()

func test_guard_momentum_continues() -> void:
	"""Test that guards continue in same direction when path is clear."""
	var guard_system = load("res://scripts/guard_system.gd").new(12345)

	# No walls - guard should continue in initial direction
	var guard = guard_system.add_guard(Vector2i(5, 5))
	guard.patrol_direction = Vector2i(1, 0)  # Moving right

	# Process guard phase multiple times
	guard_system.process_guard_phase()
	assert_eq(guard.position, Vector2i(6, 5), "Guard moved right")

	guard_system.process_guard_phase()
	assert_eq(guard.position, Vector2i(7, 5), "Guard continued right")

	guard_system.process_guard_phase()
	assert_eq(guard.position, Vector2i(8, 5), "Guard continued right again")

	guard_system.free()
