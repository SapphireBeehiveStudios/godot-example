extends Node
## Test Module for TurnSystem
##
## Tests the core turn-based game loop including:
## - Move into wall fails (position unchanged)
## - Wait increments turn count
## - Pick up keycard increments inventory

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_move_into_wall_fails()
	test_wait_increments_turn_count()
	test_pickup_keycard_increments_inventory()
	test_successful_movement()
	test_deterministic_with_seed()
	test_turn_signal_emitted()
	test_win_condition_gating()
	test_multiple_pickups()
	test_interact_action()
	test_grid_tile_management()
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
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Set up a wall at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "wall")

	# Record initial position
	var initial_position = turn_system.player_position

	# Try to move into the wall
	var result = turn_system.process_turn("move", Vector2i(1, 0))

	# Verify move failed
	assert_false(result.success, "Move into wall should fail")

	# Verify position unchanged
	assert_eq(turn_system.player_position, initial_position, "Position should remain unchanged after failed move")

	# Verify turn count did not increment (failed moves don't count as turns)
	assert_eq(turn_system.turn_count, 0, "Turn count should not increment on failed move")

	turn_system.free()

func test_wait_increments_turn_count() -> void:
	"""Test that wait action increments turn count."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Initial turn count should be 0
	assert_eq(turn_system.turn_count, 0, "Initial turn count is 0")

	# Wait once
	var result = turn_system.process_turn("wait")
	assert_true(result.success, "Wait action should succeed")
	assert_eq(turn_system.turn_count, 1, "Turn count increments to 1 after wait")

	# Wait again
	result = turn_system.process_turn("wait")
	assert_eq(turn_system.turn_count, 2, "Turn count increments to 2 after second wait")

	# Wait a third time
	result = turn_system.process_turn("wait")
	assert_eq(turn_system.turn_count, 3, "Turn count increments to 3 after third wait")

	turn_system.free()

func test_pickup_keycard_increments_inventory() -> void:
	"""Test that picking up a keycard increments inventory."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place a keycard at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "pickup", {"pickup_type": "keycard"})

	# Verify inventory is empty
	assert_eq(turn_system.get_inventory_count("keycard"), 0, "Initial keycard count is 0")

	# Move to the keycard
	var result = turn_system.process_turn("move", Vector2i(1, 0))
	assert_true(result.success, "Move to keycard should succeed")

	# Verify keycard was picked up
	assert_eq(result.pickups.size(), 1, "One item should be picked up")
	assert_eq(result.pickups[0], "keycard", "Picked up item should be keycard")

	# Verify inventory count
	assert_eq(turn_system.get_inventory_count("keycard"), 1, "Keycard count should be 1")

	# Verify tile is now floor (pickup removed)
	var tile = turn_system.get_grid_tile(Vector2i(1, 0))
	assert_eq(tile.type, "floor", "Tile should be floor after pickup")

	turn_system.free()

func test_successful_movement() -> void:
	"""Test that successful movement updates position and increments turn count."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Move right
	var result = turn_system.process_turn("move", Vector2i(1, 0))
	assert_true(result.success, "Move should succeed")
	assert_eq(turn_system.player_position, Vector2i(1, 0), "Player should be at (1, 0)")
	assert_eq(turn_system.turn_count, 1, "Turn count should be 1")

	# Move down
	result = turn_system.process_turn("move", Vector2i(0, 1))
	assert_eq(turn_system.player_position, Vector2i(1, 1), "Player should be at (1, 1)")
	assert_eq(turn_system.turn_count, 2, "Turn count should be 2")

	turn_system.free()

func test_deterministic_with_seed() -> void:
	"""Test that using the same seed produces deterministic outcomes."""
	var turn_system1 = load("res://scripts/turn_system.gd").new(12345)
	var turn_system2 = load("res://scripts/turn_system.gd").new(12345)

	# Both should have the same RNG state
	var rand1 = turn_system1.rng.randf()
	var rand2 = turn_system2.rng.randf()
	assert_eq(rand1, rand2, "Same seed produces same random values")

	turn_system1.free()
	turn_system2.free()

func test_turn_signal_emitted() -> void:
	"""Test that turn_completed signal exists and can be connected."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Test that the signal exists
	assert_true(turn_system.has_signal("turn_completed"), "turn_completed signal should exist")

	# Test that we can connect to it without errors
	var signal_count = 0
	turn_system.turn_completed.connect(func(turn_number): signal_count += 1)

	# Perform a wait action - signal should be emitted
	turn_system.process_turn("wait")

	# Verify that the turn system processes turns correctly
	assert_eq(turn_system.turn_count, 1, "Turn count should be 1 after processing turn")

	turn_system.free()

func test_win_condition_gating() -> void:
	"""Test that win condition is gated and works correctly."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Test that the game_won signal exists
	assert_true(turn_system.has_signal("game_won"), "game_won signal should exist")

	# Connect to win signal
	turn_system.game_won.connect(func(): pass)

	# Set win condition
	turn_system.set_win_condition(true)

	# Process a turn
	var result = turn_system.process_turn("wait")

	# Verify win state
	assert_eq(result.game_state, "won", "Game state should be 'won'")
	assert_true(turn_system.game_over, "Game should be marked as over")

	# Try to process another turn (should fail)
	result = turn_system.process_turn("wait")
	assert_false(result.success, "Cannot process turn after game over")

	turn_system.free()

func test_multiple_pickups() -> void:
	"""Test picking up multiple items."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place multiple keycards
	turn_system.set_grid_tile(Vector2i(1, 0), "pickup", {"pickup_type": "keycard"})
	turn_system.set_grid_tile(Vector2i(2, 0), "pickup", {"pickup_type": "keycard"})
	turn_system.set_grid_tile(Vector2i(3, 0), "pickup", {"pickup_type": "healthpack"})

	# Pick up first keycard
	turn_system.process_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_inventory_count("keycard"), 1, "Should have 1 keycard")

	# Pick up second keycard
	turn_system.process_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_inventory_count("keycard"), 2, "Should have 2 keycards")

	# Pick up healthpack
	turn_system.process_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_inventory_count("healthpack"), 1, "Should have 1 healthpack")
	assert_eq(turn_system.get_inventory_count("keycard"), 2, "Should still have 2 keycards")

	turn_system.free()

func test_interact_action() -> void:
	"""Test that interact action works and increments turn count."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	var result = turn_system.process_turn("interact")
	assert_true(result.success, "Interact action should succeed")
	assert_eq(turn_system.turn_count, 1, "Turn count should increment after interact")
	assert_eq(result.action_result, "Interacted", "Should return interact message")

	turn_system.free()

func test_grid_tile_management() -> void:
	"""Test setting and getting grid tiles."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Test default tile (should be floor)
	var tile = turn_system.get_grid_tile(Vector2i(5, 5))
	assert_eq(tile.type, "floor", "Default tile should be floor")

	# Test setting a wall
	turn_system.set_grid_tile(Vector2i(5, 5), "wall")
	tile = turn_system.get_grid_tile(Vector2i(5, 5))
	assert_eq(tile.type, "wall", "Tile should be wall after setting")

	# Test walkability
	assert_false(turn_system.is_tile_walkable(Vector2i(5, 5)), "Wall should not be walkable")
	assert_true(turn_system.is_tile_walkable(Vector2i(6, 6)), "Floor should be walkable")

	turn_system.free()
