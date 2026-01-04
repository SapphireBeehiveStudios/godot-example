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
	test_door_blocks_movement()
	test_cannot_open_door_without_keycard()
	test_can_open_door_with_keycard()
	test_keycard_consumed_when_opening_door()
	test_opened_door_becomes_walkable()
	test_interact_requires_direction()
	test_interact_fails_with_no_door()
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


## Door Interaction Tests (Issue #21)


func test_door_blocks_movement() -> void:
	"""Test that closed doors block movement."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place closed door to the right
	turn_system.add_door(Vector2i(1, 0), false)

	# Try to move through the closed door
	var initial_pos = turn_system.get_player_position()
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	var final_pos = turn_system.get_player_position()

	assert_false(result, "Move through closed door should fail")
	assert_eq(final_pos, initial_pos, "Position should remain unchanged when moving into closed door")
	assert_true(turn_system.is_door_closed(Vector2i(1, 0)), "Door should still be closed")

	turn_system.free()


func test_cannot_open_door_without_keycard() -> void:
	"""Test that doors cannot be opened without a keycard."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place closed door to the right
	turn_system.add_door(Vector2i(1, 0), false)

	# Verify no keycards in inventory
	assert_eq(turn_system.get_keycard_count(), 0, "Should start with no keycards")

	# Try to interact with door (without keycard)
	var result = turn_system.execute_turn("interact", Vector2i(1, 0))

	assert_false(result, "Interaction should fail without keycard")
	assert_true(turn_system.is_door_closed(Vector2i(1, 0)), "Door should remain closed")

	turn_system.free()


func test_can_open_door_with_keycard() -> void:
	"""Test that doors can be opened when player has a keycard."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set win requirement high so game doesn't end
	turn_system.keycards_required_to_win = 10

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Give player a keycard
	turn_system.add_pickup(Vector2i(0, 0), "keycard")
	turn_system.execute_turn("wait")  # Pick up keycard
	assert_eq(turn_system.get_keycard_count(), 1, "Should have 1 keycard")

	# Place closed door to the right
	turn_system.add_door(Vector2i(1, 0), false)

	# Interact with door (with keycard)
	var result = turn_system.execute_turn("interact", Vector2i(1, 0))

	assert_true(result, "Interaction should succeed with keycard")
	assert_false(turn_system.is_door_closed(Vector2i(1, 0)), "Door should be open")

	turn_system.free()


func test_keycard_consumed_when_opening_door() -> void:
	"""Test that opening a door consumes one keycard from inventory."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set win requirement high so game doesn't end
	turn_system.keycards_required_to_win = 10

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Give player 2 keycards
	turn_system.add_pickup(Vector2i(0, 0), "keycard")
	turn_system.execute_turn("wait")
	turn_system.add_pickup(Vector2i(0, 0), "keycard")
	turn_system.execute_turn("wait")
	assert_eq(turn_system.get_keycard_count(), 2, "Should have 2 keycards")

	# Place closed door to the right
	turn_system.add_door(Vector2i(1, 0), false)

	# Open door
	turn_system.execute_turn("interact", Vector2i(1, 0))

	assert_eq(turn_system.get_keycard_count(), 1, "Should have 1 keycard left after opening door")
	assert_false(turn_system.is_door_closed(Vector2i(1, 0)), "Door should be open")

	turn_system.free()


func test_opened_door_becomes_walkable() -> void:
	"""Test that opened doors become walkable."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set win requirement high so game doesn't end
	turn_system.keycards_required_to_win = 10

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Give player a keycard
	turn_system.add_pickup(Vector2i(0, 0), "keycard")
	turn_system.execute_turn("wait")

	# Place closed door to the right
	turn_system.add_door(Vector2i(1, 0), false)

	# Verify door blocks movement initially
	assert_false(turn_system.is_tile_walkable(Vector2i(1, 0)), "Closed door should not be walkable")

	# Open the door
	turn_system.execute_turn("interact", Vector2i(1, 0))

	# Now door should be walkable
	assert_true(turn_system.is_tile_walkable(Vector2i(1, 0)), "Open door should be walkable")

	# Move through the opened door
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(result, "Should be able to move through open door")
	assert_eq(turn_system.get_player_position(), Vector2i(1, 0), "Player should be on door tile")

	turn_system.free()


func test_interact_requires_direction() -> void:
	"""Test that interact action checks the tile in the specified direction."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set win requirement high so game doesn't end
	turn_system.keycards_required_to_win = 10

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Give player a keycard
	turn_system.add_pickup(Vector2i(0, 0), "keycard")
	turn_system.execute_turn("wait")

	# Place doors in different directions
	turn_system.add_door(Vector2i(1, 0), false)   # Right
	turn_system.add_door(Vector2i(0, 1), false)   # Down

	# Interact to the right
	var result = turn_system.execute_turn("interact", Vector2i(1, 0))
	assert_true(result, "Should open door to the right")
	assert_false(turn_system.is_door_closed(Vector2i(1, 0)), "Right door should be open")
	assert_true(turn_system.is_door_closed(Vector2i(0, 1)), "Down door should still be closed")

	turn_system.free()


func test_interact_fails_with_no_door() -> void:
	"""Test that interact action fails when there's no door at target position."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set win requirement high so game doesn't end
	turn_system.keycards_required_to_win = 10

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Give player a keycard
	turn_system.add_pickup(Vector2i(0, 0), "keycard")
	turn_system.execute_turn("wait")

	# Try to interact with empty space (no door)
	var result = turn_system.execute_turn("interact", Vector2i(1, 0))

	assert_false(result, "Interaction should fail when there's no door")
	assert_eq(turn_system.get_keycard_count(), 1, "Keycard should not be consumed")

	turn_system.free()
