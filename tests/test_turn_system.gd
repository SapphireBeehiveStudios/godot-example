extends Node
## Test Module for TurnSystem
##
## Tests the core turn-based game loop including:
## - Player movement and collision
## - Wait action
## - Pickup collection
## - Win condition checks
## - Deterministic behavior

const TurnSystem = preload("res://scripts/turn_system.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_initialization()
	test_move_into_wall_fails()
	test_wait_increments_turn_count()
	test_pickup_keycard_increments_inventory()
	test_successful_move()
	test_turn_order_is_deterministic()
	test_win_condition_without_keycard()
	test_win_condition_with_keycard_requirement()
	test_multiple_pickups()
	test_pickup_removed_after_collection()
	test_move_direction_vectors()
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

func test_initialization() -> void:
	"""Test that TurnSystem initializes correctly."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	assert_eq(turn_system.get_turn_count(), 0, "Turn count starts at 0")
	assert_eq(turn_system.get_player_position(), Vector2i.ZERO, "Player starts at origin")
	assert_eq(turn_system.get_item_count("keycard"), 0, "Keycard count starts at 0")
	assert_eq(turn_system.get_item_count("coins"), 0, "Coin count starts at 0")

	turn_system.free()

func test_move_into_wall_fails() -> void:
	"""Test that moving into a wall fails and position remains unchanged."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	# Set up a wall to the right
	turn_system.set_walls([Vector2i(1, 0)])

	var initial_position = turn_system.get_player_position()
	var result = turn_system.execute_move(Vector2i(1, 0))  # Try to move right into wall

	assert_false(result, "Move into wall returns false")
	assert_eq(turn_system.get_player_position(), initial_position, "Position unchanged after wall collision")
	assert_eq(turn_system.get_turn_count(), 1, "Turn count incremented even when move fails")

	turn_system.free()

func test_wait_increments_turn_count() -> void:
	"""Test that wait action increments turn count."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	assert_eq(turn_system.get_turn_count(), 0, "Turn count starts at 0")

	turn_system.execute_wait()
	assert_eq(turn_system.get_turn_count(), 1, "Turn count incremented after wait")

	turn_system.execute_wait()
	assert_eq(turn_system.get_turn_count(), 2, "Turn count incremented again after second wait")

	turn_system.free()

func test_pickup_keycard_increments_inventory() -> void:
	"""Test that picking up a keycard increments inventory."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	# Place keycard at position (1, 0)
	turn_system.add_pickup(Vector2i(1, 0), "keycard")

	assert_eq(turn_system.get_item_count("keycard"), 0, "No keycard initially")

	# Move to the keycard position
	turn_system.execute_move(Vector2i(1, 0))

	assert_eq(turn_system.get_item_count("keycard"), 1, "Keycard collected after move")
	assert_true(turn_system.has_item("keycard"), "has_item returns true for keycard")

	turn_system.free()

func test_successful_move() -> void:
	"""Test that a successful move changes position and increments turn."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	var initial_position = turn_system.get_player_position()
	var result = turn_system.execute_move(Vector2i(1, 0))

	assert_true(result, "Move returns true on success")
	assert_eq(turn_system.get_player_position(), Vector2i(1, 0), "Position updated after move")
	assert_eq(turn_system.get_turn_count(), 1, "Turn count incremented after move")

	turn_system.free()

func test_turn_order_is_deterministic() -> void:
	"""Test that same seed and inputs produce same results."""
	# Create two turn systems with same seed
	var turn_system1 = TurnSystem.new()
	turn_system1.initialize(42)
	turn_system1.add_pickup(Vector2i(1, 0), "keycard")

	var turn_system2 = TurnSystem.new()
	turn_system2.initialize(42)
	turn_system2.add_pickup(Vector2i(1, 0), "keycard")

	# Execute same moves
	turn_system1.execute_move(Vector2i(1, 0))
	turn_system2.execute_move(Vector2i(1, 0))

	assert_eq(turn_system1.get_player_position(), turn_system2.get_player_position(),
		"Same moves produce same position")
	assert_eq(turn_system1.get_turn_count(), turn_system2.get_turn_count(),
		"Same moves produce same turn count")
	assert_eq(turn_system1.get_item_count("keycard"), turn_system2.get_item_count("keycard"),
		"Same moves produce same inventory")

	turn_system1.free()
	turn_system2.free()

func test_win_condition_without_keycard() -> void:
	"""Test win condition that doesn't require a keycard."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	var win_triggered = [false]  # Use array to work around closure limitation
	turn_system.win_condition_met.connect(func(): win_triggered[0] = true)

	# Set win position without keycard requirement
	turn_system.set_win_condition(Vector2i(1, 0), false)

	# Move to win position
	turn_system.execute_move(Vector2i(1, 0))

	assert_true(win_triggered[0], "Win condition triggered when reaching position")

	turn_system.free()

func test_win_condition_with_keycard_requirement() -> void:
	"""Test win condition that requires a keycard."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	var win_triggered = [false]  # Use array to work around closure limitation
	turn_system.win_condition_met.connect(func(): win_triggered[0] = true)

	# Set win position with keycard requirement
	turn_system.set_win_condition(Vector2i(2, 0), true)

	# Move to win position without keycard - should not win
	turn_system.execute_move(Vector2i(1, 0))
	turn_system.execute_move(Vector2i(1, 0))
	assert_false(win_triggered[0], "Win not triggered without keycard")

	# Reset and try with keycard
	turn_system.initialize(42)
	win_triggered[0] = false
	turn_system.win_condition_met.connect(func(): win_triggered[0] = true)
	turn_system.set_win_condition(Vector2i(2, 0), true)
	turn_system.add_pickup(Vector2i(1, 0), "keycard")

	# Pick up keycard then move to win position
	turn_system.execute_move(Vector2i(1, 0))  # Pick up keycard
	assert_eq(turn_system.get_item_count("keycard"), 1, "Keycard collected")

	turn_system.execute_move(Vector2i(1, 0))  # Move to win position
	assert_true(win_triggered[0], "Win triggered with keycard")

	turn_system.free()

func test_multiple_pickups() -> void:
	"""Test collecting multiple different pickups."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	# Place multiple pickups
	turn_system.add_pickup(Vector2i(1, 0), "coin")
	turn_system.add_pickup(Vector2i(2, 0), "keycard")
	turn_system.add_pickup(Vector2i(3, 0), "coin")

	# Collect them
	turn_system.execute_move(Vector2i(1, 0))  # Coin 1
	assert_eq(turn_system.get_item_count("coins"), 1, "First coin collected")

	turn_system.execute_move(Vector2i(1, 0))  # Keycard
	assert_eq(turn_system.get_item_count("keycard"), 1, "Keycard collected")

	turn_system.execute_move(Vector2i(1, 0))  # Coin 2
	assert_eq(turn_system.get_item_count("coins"), 2, "Second coin collected")

	turn_system.free()

func test_pickup_removed_after_collection() -> void:
	"""Test that pickups are removed from the map after collection."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	turn_system.add_pickup(Vector2i(1, 0), "keycard")

	# Move to pickup
	turn_system.execute_move(Vector2i(1, 0))
	assert_eq(turn_system.get_item_count("keycard"), 1, "Keycard collected")

	# Move away and back - should not collect again
	turn_system.execute_move(Vector2i(-1, 0))
	turn_system.execute_move(Vector2i(1, 0))
	assert_eq(turn_system.get_item_count("keycard"), 1, "Keycard not collected twice")

	turn_system.free()

func test_move_direction_vectors() -> void:
	"""Test movement in all four cardinal directions."""
	var turn_system = TurnSystem.new()
	turn_system.initialize(42)

	# Right
	turn_system.execute_move(Vector2i(1, 0))
	assert_eq(turn_system.get_player_position(), Vector2i(1, 0), "Move right works")

	# Down
	turn_system.execute_move(Vector2i(0, 1))
	assert_eq(turn_system.get_player_position(), Vector2i(1, 1), "Move down works")

	# Left
	turn_system.execute_move(Vector2i(-1, 0))
	assert_eq(turn_system.get_player_position(), Vector2i(0, 1), "Move left works")

	# Up
	turn_system.execute_move(Vector2i(0, -1))
	assert_eq(turn_system.get_player_position(), Vector2i(0, 0), "Move up works")

	turn_system.free()
