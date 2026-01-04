extends Node
## Test Module for TurnSystem
##
## Tests for issue #20 acceptance criteria:
## - Move into wall fails (position unchanged)
## - Wait increments turn count
## - Pick up keycard increments inventory
## - One input == one turn
## - Deterministic outcomes given same seed + inputs

# Load the TurnSystem class
const TurnSystem = preload("res://scripts/turn_system.gd")

var tests_passed := 0
var tests_failed := 0


func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_move_into_wall_fails()
	test_wait_increments_turn_count()
	test_pickup_keycard_increments_inventory()
	test_one_input_one_turn()
	test_deterministic_outcomes()
	test_move_success()
	test_pickup_removes_from_world()
	test_win_condition()
	test_multiple_keycards()
	test_invalid_action()
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


func test_move_into_wall_fails() -> void:
	"""Test that moving into a wall fails and position remains unchanged."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place wall to the right
	turn_system.add_wall(Vector2i(1, 0))

	# Try to move right into the wall
	var initial_pos = turn_system.get_player_position()
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	var final_pos = turn_system.get_player_position()

	assert_false(result, "Move into wall should return false")
	assert_eq(final_pos, initial_pos, "Position should remain unchanged when moving into wall")
	assert_eq(turn_system.get_turn_count(), 1, "Turn should still be consumed")

	turn_system.free()


func test_wait_increments_turn_count() -> void:
	"""Test that wait action increments turn count."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	assert_eq(turn_system.get_turn_count(), 0, "Turn count starts at 0")

	# Execute wait action
	var result = turn_system.execute_turn("wait")

	assert_true(result, "Wait should succeed")
	assert_eq(turn_system.get_turn_count(), 1, "Turn count should increment to 1")

	# Wait again
	turn_system.execute_turn("wait")
	assert_eq(turn_system.get_turn_count(), 2, "Turn count should increment to 2")

	turn_system.free()


func test_pickup_keycard_increments_inventory() -> void:
	"""Test that picking up a keycard increments inventory."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place keycard at (1, 0)
	turn_system.add_pickup(Vector2i(1, 0), "keycard")

	# Check initial inventory
	assert_eq(turn_system.get_keycard_count(), 0, "Initial keycard count is 0")

	# Move to keycard position
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Check inventory after pickup
	assert_eq(turn_system.get_keycard_count(), 1, "Keycard count should be 1 after pickup")

	turn_system.free()


func test_one_input_one_turn() -> void:
	"""Test that each input consumes exactly one turn."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Start at turn 0
	assert_eq(turn_system.get_turn_count(), 0, "Start at turn 0")

	# Each action should consume one turn
	turn_system.execute_turn("wait")
	assert_eq(turn_system.get_turn_count(), 1, "One wait = one turn")

	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_turn_count(), 2, "One move = one turn")

	turn_system.execute_turn("wait")
	assert_eq(turn_system.get_turn_count(), 3, "Another wait = another turn")

	turn_system.free()


func test_deterministic_outcomes() -> void:
	"""Test that same seed + inputs produce same results."""
	# First run
	var turn_system1 = TurnSystem.new()
	turn_system1.setup(42)  # Fixed seed

	turn_system1.execute_turn("move", Vector2i(1, 0))
	turn_system1.execute_turn("move", Vector2i(0, 1))
	turn_system1.execute_turn("wait")

	var pos1 = turn_system1.get_player_position()
	var turn1 = turn_system1.get_turn_count()

	# Second run with same seed and inputs
	var turn_system2 = TurnSystem.new()
	turn_system2.setup(42)  # Same seed

	turn_system2.execute_turn("move", Vector2i(1, 0))
	turn_system2.execute_turn("move", Vector2i(0, 1))
	turn_system2.execute_turn("wait")

	var pos2 = turn_system2.get_player_position()
	var turn2 = turn_system2.get_turn_count()

	assert_eq(pos1, pos2, "Same inputs should produce same position")
	assert_eq(turn1, turn2, "Same inputs should produce same turn count")

	turn_system1.free()
	turn_system2.free()


func test_move_success() -> void:
	"""Test that moving to an empty tile succeeds."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	turn_system.set_player_position(Vector2i(0, 0))

	# Move right (no wall)
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	var new_pos = turn_system.get_player_position()

	assert_true(result, "Move to empty tile should succeed")
	assert_eq(new_pos, Vector2i(1, 0), "Position should update correctly")

	turn_system.free()


func test_pickup_removes_from_world() -> void:
	"""Test that picking up an item removes it from the world."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place player and keycard at same location
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_pickup(Vector2i(0, 0), "keycard")

	# Verify pickup exists
	assert_eq(turn_system.get_pickup(Vector2i(0, 0)), "keycard", "Keycard should be at position")

	# Execute any turn to trigger pickup resolution
	turn_system.execute_turn("wait")

	# Verify pickup was removed
	assert_eq(turn_system.get_pickup(Vector2i(0, 0)), "", "Keycard should be removed from world")
	assert_eq(turn_system.get_keycard_count(), 1, "Keycard should be in inventory")

	turn_system.free()


func test_win_condition() -> void:
	"""Test that collecting required keycards triggers win condition."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set up win condition
	turn_system.keycards_required_to_win = 2

	# Place player and keycards
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_pickup(Vector2i(1, 0), "keycard")
	turn_system.add_pickup(Vector2i(2, 0), "keycard")

	# Collect first keycard
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_false(turn_system.is_game_over(), "Should not win with only 1 keycard")

	# Collect second keycard
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(turn_system.is_game_over(), "Should win after collecting 2 keycards")

	turn_system.free()


func test_multiple_keycards() -> void:
	"""Test collecting multiple keycards."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set win requirement higher so game doesn't end after first keycard
	turn_system.keycards_required_to_win = 3

	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_pickup(Vector2i(0, 0), "keycard")

	turn_system.execute_turn("wait")
	assert_eq(turn_system.get_keycard_count(), 1, "First keycard collected")

	# Add another keycard and move to it
	turn_system.add_pickup(Vector2i(1, 0), "keycard")
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_keycard_count(), 2, "Second keycard collected")

	turn_system.free()


func test_invalid_action() -> void:
	"""Test that invalid actions still consume a turn."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	var initial_turn = turn_system.get_turn_count()

	# Try an invalid action
	turn_system.execute_turn("invalid_action")

	# Turn should still increment
	assert_eq(turn_system.get_turn_count(), initial_turn + 1, "Invalid action should consume turn")

	turn_system.free()
