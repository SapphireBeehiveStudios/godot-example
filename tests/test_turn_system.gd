extends Node
## Test Module for TurnSystem
##
## Tests the core turn-based game loop including:
## - Player movement
## - Wait action
## - Pickup collection
## - Turn counting
## - Deterministic behavior

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_move_into_wall_fails()
	test_wait_increments_turn_count()
	test_pick_up_keycard_increments_inventory()
	test_move_succeeds_without_wall()
	test_turn_count_increments_on_any_action()
	test_pickup_removed_after_collection()
	test_multiple_pickups_stack_in_inventory()
	test_deterministic_outcomes_with_same_seed()
	test_position_unchanged_on_wall_collision()
	test_player_can_move_multiple_turns()
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

func assert_not_null(value, test_name: String) -> void:
	"""Assert that value is not null."""
	if value != null:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected non-null value, got null" % test_name)

## Test implementations

func test_move_into_wall_fails() -> void:
	"""Test that moving into a wall fails and position remains unchanged."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(5, 5))

	# Add a wall to the right
	turn_system.add_wall(Vector2i(6, 5))

	# Try to move right into the wall
	var result = turn_system.execute_turn("move", Vector2i(1, 0))

	assert_false(result.success, "Move into wall should fail")
	assert_false(result.position_changed, "Position should not change")
	assert_eq(turn_system.player_position, Vector2i(5, 5), "Player position unchanged after wall collision")
	assert_eq(turn_system.turn_count, 1, "Turn count increments even on failed move")

	turn_system.free()


func test_wait_increments_turn_count() -> void:
	"""Test that wait action increments turn count."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)

	assert_eq(turn_system.turn_count, 0, "Turn count starts at 0")

	# Execute wait action
	var result = turn_system.execute_turn("wait")

	assert_true(result.success, "Wait action succeeds")
	assert_eq(turn_system.turn_count, 1, "Turn count incremented to 1")

	# Execute another wait
	turn_system.execute_turn("wait")
	assert_eq(turn_system.turn_count, 2, "Turn count incremented to 2")

	turn_system.free()


func test_pick_up_keycard_increments_inventory() -> void:
	"""Test that picking up a keycard increments inventory count."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(3, 3))

	# Place a keycard at player's position
	turn_system.add_pickup(Vector2i(3, 3), "keycard")

	assert_eq(turn_system.get_inventory_count("keycard"), 0, "Keycard count starts at 0")

	# Execute a wait action to trigger pickup resolution
	turn_system.execute_turn("wait")

	assert_eq(turn_system.get_inventory_count("keycard"), 1, "Keycard count incremented to 1")
	assert_false(turn_system.has_pickup(Vector2i(3, 3)), "Pickup removed from map")

	turn_system.free()


func test_move_succeeds_without_wall() -> void:
	"""Test that moving to an empty tile succeeds."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(5, 5))

	# Move right (no wall)
	var result = turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(result.success, "Move to empty tile succeeds")
	assert_true(result.position_changed, "Position changed flag set")
	assert_eq(turn_system.player_position, Vector2i(6, 5), "Player moved to correct position")

	turn_system.free()


func test_turn_count_increments_on_any_action() -> void:
	"""Test that turn count increments on all action types."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(5, 5))

	# Turn 1: move
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.turn_count, 1, "Turn count is 1 after move")

	# Turn 2: wait
	turn_system.execute_turn("wait")
	assert_eq(turn_system.turn_count, 2, "Turn count is 2 after wait")

	# Turn 3: interact
	turn_system.execute_turn("interact")
	assert_eq(turn_system.turn_count, 3, "Turn count is 3 after interact")

	turn_system.free()


func test_pickup_removed_after_collection() -> void:
	"""Test that pickups are removed from map after collection."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(2, 2))

	# Place pickup at current position
	turn_system.add_pickup(Vector2i(2, 2), "coin")

	assert_true(turn_system.has_pickup(Vector2i(2, 2)), "Pickup exists before collection")

	# Execute action to trigger pickup
	turn_system.execute_turn("wait")

	assert_false(turn_system.has_pickup(Vector2i(2, 2)), "Pickup removed after collection")

	turn_system.free()


func test_multiple_pickups_stack_in_inventory() -> void:
	"""Test that multiple pickups of the same type stack in inventory."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(0, 0))

	# Move to position with first keycard
	turn_system.add_pickup(Vector2i(1, 0), "keycard")
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_inventory_count("keycard"), 1, "First keycard collected")

	# Move to position with second keycard
	turn_system.add_pickup(Vector2i(2, 0), "keycard")
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_inventory_count("keycard"), 2, "Second keycard stacked")

	turn_system.free()


func test_deterministic_outcomes_with_same_seed() -> void:
	"""Test that same seed and inputs produce identical results."""
	# First run
	var turn_system1 = load("res://scripts/turn_system.gd").new()
	turn_system1.initialize(12345)
	turn_system1.set_player_position(Vector2i(0, 0))
	turn_system1.add_pickup(Vector2i(1, 0), "key")
	turn_system1.execute_turn("move", Vector2i(1, 0))
	turn_system1.execute_turn("wait")
	var final_pos1 = turn_system1.player_position
	var final_turn1 = turn_system1.turn_count
	var final_key1 = turn_system1.get_inventory_count("key")

	# Second run with same seed
	var turn_system2 = load("res://scripts/turn_system.gd").new()
	turn_system2.initialize(12345)
	turn_system2.set_player_position(Vector2i(0, 0))
	turn_system2.add_pickup(Vector2i(1, 0), "key")
	turn_system2.execute_turn("move", Vector2i(1, 0))
	turn_system2.execute_turn("wait")
	var final_pos2 = turn_system2.player_position
	var final_turn2 = turn_system2.turn_count
	var final_key2 = turn_system2.get_inventory_count("key")

	assert_eq(final_pos1, final_pos2, "Same position with same seed")
	assert_eq(final_turn1, final_turn2, "Same turn count with same seed")
	assert_eq(final_key1, final_key2, "Same inventory with same seed")

	turn_system1.free()
	turn_system2.free()


func test_position_unchanged_on_wall_collision() -> void:
	"""Test that position remains exactly unchanged when hitting a wall."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(10, 10))

	# Add walls in all directions
	turn_system.add_wall(Vector2i(11, 10))  # Right
	turn_system.add_wall(Vector2i(9, 10))   # Left
	turn_system.add_wall(Vector2i(10, 11))  # Down
	turn_system.add_wall(Vector2i(10, 9))   # Up

	# Try moving in each direction
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.player_position, Vector2i(10, 10), "Position unchanged moving right")

	turn_system.execute_turn("move", Vector2i(-1, 0))
	assert_eq(turn_system.player_position, Vector2i(10, 10), "Position unchanged moving left")

	turn_system.execute_turn("move", Vector2i(0, 1))
	assert_eq(turn_system.player_position, Vector2i(10, 10), "Position unchanged moving down")

	turn_system.execute_turn("move", Vector2i(0, -1))
	assert_eq(turn_system.player_position, Vector2i(10, 10), "Position unchanged moving up")

	assert_eq(turn_system.turn_count, 4, "All four move attempts counted as turns")

	turn_system.free()


func test_player_can_move_multiple_turns() -> void:
	"""Test that player can move successfully over multiple turns."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.initialize(42)
	turn_system.set_player_position(Vector2i(0, 0))

	# Move right
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.player_position, Vector2i(1, 0), "Moved to (1,0)")

	# Move down
	turn_system.execute_turn("move", Vector2i(0, 1))
	assert_eq(turn_system.player_position, Vector2i(1, 1), "Moved to (1,1)")

	# Move left
	turn_system.execute_turn("move", Vector2i(-1, 0))
	assert_eq(turn_system.player_position, Vector2i(0, 1), "Moved to (0,1)")

	# Move up
	turn_system.execute_turn("move", Vector2i(0, -1))
	assert_eq(turn_system.player_position, Vector2i(0, 0), "Moved back to (0,0)")

	assert_eq(turn_system.turn_count, 4, "Four turns executed")

	turn_system.free()
