extends Node
## Test Module for TurnSystem
##
## Tests the core turn loop functionality including:
## - Move into wall fails (position unchanged)
## - Wait increments turn count
## - Pick up keycard increments inventory

const TurnSystem = preload("res://scripts/turn_system.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_move_into_wall_fails()
	test_wait_increments_turn_count()
	test_pickup_keycard_increments_inventory()
	test_move_valid_position()
	test_move_out_of_bounds()
	test_pickup_multiple_items()
	test_deterministic_seed()
	test_turn_signals()
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
	var turn_system = TurnSystem.new()
	turn_system.set_map_size(5, 5)
	turn_system.set_player_position(Vector2i(2, 2))

	# Add a wall to the right of player
	turn_system.add_wall(Vector2i(3, 2))

	var initial_position = turn_system.get_player_position()

	# Try to move into the wall
	var success = turn_system.execute_turn("move", Vector2i(1, 0))

	# Action should fail
	assert_false(success, "Moving into wall should fail")

	# Position should be unchanged
	assert_eq(turn_system.get_player_position(), initial_position, "Position unchanged after failed move")

	# Turn count should still increment (turn was attempted)
	assert_eq(turn_system.get_turn_count(), 1, "Turn count increments even on failed move")

	turn_system.free()


func test_wait_increments_turn_count() -> void:
	"""Test that waiting increments the turn count."""
	var turn_system = TurnSystem.new()

	assert_eq(turn_system.get_turn_count(), 0, "Initial turn count is 0")

	# Execute wait action
	var success = turn_system.execute_turn("wait")

	assert_true(success, "Wait action succeeds")
	assert_eq(turn_system.get_turn_count(), 1, "Turn count incremented to 1")

	# Wait again
	turn_system.execute_turn("wait")
	assert_eq(turn_system.get_turn_count(), 2, "Turn count incremented to 2")

	turn_system.free()


func test_pickup_keycard_increments_inventory() -> void:
	"""Test that picking up a keycard increments the inventory."""
	var turn_system = TurnSystem.new()
	turn_system.set_map_size(5, 5)
	turn_system.set_player_position(Vector2i(2, 2))

	# Place a keycard at player's position
	turn_system.add_pickup(Vector2i(2, 2), "keycard")

	# Initial inventory should be 0
	assert_eq(turn_system.get_inventory_count("keycard"), 0, "Initial keycard count is 0")

	# Execute a wait action (which triggers pickup resolution)
	turn_system.execute_turn("wait")

	# Keycard should be in inventory
	assert_eq(turn_system.get_inventory_count("keycard"), 1, "Keycard count is 1 after pickup")

	turn_system.free()


func test_move_valid_position() -> void:
	"""Test that moving to a valid position succeeds."""
	var turn_system = TurnSystem.new()
	turn_system.set_map_size(5, 5)
	turn_system.set_player_position(Vector2i(2, 2))

	# Move right
	var success = turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(success, "Moving to valid position succeeds")
	assert_eq(turn_system.get_player_position(), Vector2i(3, 2), "Player moved to correct position")

	turn_system.free()


func test_move_out_of_bounds() -> void:
	"""Test that moving out of bounds fails."""
	var turn_system = TurnSystem.new()
	turn_system.set_map_size(5, 5)
	turn_system.set_player_position(Vector2i(0, 0))

	# Try to move left (out of bounds)
	var success = turn_system.execute_turn("move", Vector2i(-1, 0))

	assert_false(success, "Moving out of bounds fails")
	assert_eq(turn_system.get_player_position(), Vector2i(0, 0), "Position unchanged")

	turn_system.free()


func test_pickup_multiple_items() -> void:
	"""Test that moving onto a tile with a pickup collects it."""
	var turn_system = TurnSystem.new()
	turn_system.set_map_size(5, 5)
	turn_system.set_player_position(Vector2i(2, 2))

	# Place a keycard at an adjacent position
	turn_system.add_pickup(Vector2i(3, 2), "keycard")

	# Move onto the keycard
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Keycard should be collected
	assert_eq(turn_system.get_inventory_count("keycard"), 1, "Keycard collected after moving onto it")

	# Place another keycard
	turn_system.add_pickup(Vector2i(3, 2), "keycard")

	# Wait to collect it
	turn_system.execute_turn("wait")

	# Should have 2 keycards now
	assert_eq(turn_system.get_inventory_count("keycard"), 2, "Second keycard collected")

	turn_system.free()


func test_deterministic_seed() -> void:
	"""Test that the same seed produces deterministic results."""
	var turn_system1 = TurnSystem.new()
	var turn_system2 = TurnSystem.new()

	# Set same seed for both
	turn_system1.set_seed(12345)
	turn_system2.set_seed(12345)

	# For now, just verify that RNG instances are set
	# (actual deterministic behavior would be tested with RNG-dependent features)
	assert_not_null(turn_system1.rng, "RNG initialized in turn_system1")
	assert_not_null(turn_system2.rng, "RNG initialized in turn_system2")

	turn_system1.free()
	turn_system2.free()


func test_turn_signals() -> void:
	"""Test that turn system emits correct signals."""
	var turn_system = TurnSystem.new()
	turn_system.set_map_size(5, 5)
	turn_system.set_player_position(Vector2i(2, 2))

	# Use a class to track signal firing (workaround for lambda variable capture)
	var signal_tracker = SignalTracker.new()

	# Connect to signals
	turn_system.turn_completed.connect(signal_tracker.on_turn_completed)
	turn_system.player_moved.connect(signal_tracker.on_player_moved)
	turn_system.pickup_collected.connect(signal_tracker.on_pickup_collected)

	# Execute a move
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(signal_tracker.turn_completed_fired, "turn_completed signal fired")
	assert_true(signal_tracker.player_moved_fired, "player_moved signal fired")

	# Reset flags
	signal_tracker.turn_completed_fired = false

	# Place a pickup and collect it
	turn_system.add_pickup(turn_system.get_player_position(), "keycard")
	turn_system.execute_turn("wait")

	assert_true(signal_tracker.turn_completed_fired, "turn_completed signal fired on wait")
	assert_true(signal_tracker.pickup_collected_fired, "pickup_collected signal fired")

	# SignalTracker is RefCounted, no need to free
	turn_system.free()


## Helper class for signal testing
class SignalTracker:
	var turn_completed_fired = false
	var player_moved_fired = false
	var pickup_collected_fired = false

	func on_turn_completed(_turn: int) -> void:
		turn_completed_fired = true

	func on_player_moved(_old: Vector2i, _new: Vector2i) -> void:
		player_moved_fired = true

	func on_pickup_collected(_type: String, _pos: Vector2i) -> void:
		pickup_collected_fired = true
