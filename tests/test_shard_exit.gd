extends Node
## Shard and Exit Gating Test Module
##
## Tests shard collection and exit gating functionality (Issue #22).

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_shard_pickup_sets_flag()
	test_exit_blocked_without_shard()
	test_exit_succeeds_with_shard()
	test_exit_triggers_floor_complete()
	test_multiple_shard_pickups()
	test_exit_before_shard_doesnt_end_game()
	test_shard_and_exit_reset_on_game_reset()
	test_exit_only_once()
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
func test_shard_pickup_sets_flag() -> void:
	"""Test that collecting a shard sets shard_collected to true."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place shard at (1, 0)
	turn_system.add_pickup(Vector2i(1, 0), "shard")

	# Verify shard not collected initially
	assert_false(turn_system.is_shard_collected(), "Shard not collected initially")

	# Move to shard
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Verify shard collected
	assert_true(turn_system.is_shard_collected(), "Shard collected after pickup")
	assert_eq(turn_system.get_inventory_count("shard"), 1, "Shard added to inventory")

	turn_system.free()

func test_exit_blocked_without_shard() -> void:
	"""Test that attempting exit without shard does nothing."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place exit at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "exit")

	# Move to exit without collecting shard
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Verify game is NOT over
	assert_false(turn_system.is_game_over(), "Game not over without shard")
	assert_false(turn_system.is_floor_complete(), "Floor not complete without shard")

	turn_system.free()

func test_exit_succeeds_with_shard() -> void:
	"""Test that exit with shard triggers floor complete."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place shard at (1, 0) and exit at (2, 0)
	turn_system.add_pickup(Vector2i(1, 0), "shard")
	turn_system.set_grid_tile(Vector2i(2, 0), "exit")

	# Move to shard
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(turn_system.is_shard_collected(), "Shard collected")
	assert_false(turn_system.is_game_over(), "Game not over after collecting shard")

	# Move to exit
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Verify floor complete
	assert_true(turn_system.is_floor_complete(), "Floor complete after exit with shard")
	assert_true(turn_system.is_game_over(), "Game over after exit with shard")

	turn_system.free()

func test_exit_triggers_floor_complete() -> void:
	"""Test that exit with shard triggers floor_complete flag."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Setup: shard at (0, 0), exit at (1, 0)
	turn_system.add_pickup(Vector2i(0, 0), "shard")
	turn_system.set_grid_tile(Vector2i(1, 0), "exit")

	# Collect shard (player starts at 0,0)
	turn_system.execute_turn("wait")
	assert_true(turn_system.is_shard_collected(), "Shard collected")

	# Move to exit
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Verify floor complete flag is set
	assert_true(turn_system.is_floor_complete(), "Floor complete flag set")

	turn_system.free()

func test_multiple_shard_pickups() -> void:
	"""Test that multiple shards can be collected (edge case)."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place two shards
	turn_system.add_pickup(Vector2i(1, 0), "shard")
	turn_system.add_pickup(Vector2i(2, 0), "shard")

	# Collect first shard
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(turn_system.is_shard_collected(), "Shard collected after first pickup")
	assert_eq(turn_system.get_inventory_count("shard"), 1, "One shard in inventory")

	# Collect second shard
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(turn_system.is_shard_collected(), "Shard still collected after second pickup")
	assert_eq(turn_system.get_inventory_count("shard"), 2, "Two shards in inventory")

	turn_system.free()

func test_exit_before_shard_doesnt_end_game() -> void:
	"""Test that walking over exit before collecting shard doesn't end the game."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Place player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place exit at (1, 0), shard at (2, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "exit")
	turn_system.add_pickup(Vector2i(2, 0), "shard")

	# Move to exit first (without shard)
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_false(turn_system.is_game_over(), "Game not over when stepping on exit without shard")

	# Collect shard
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(turn_system.is_shard_collected(), "Shard collected")
	assert_false(turn_system.is_game_over(), "Game not over after collecting shard")

	# Return to exit
	turn_system.execute_turn("move", Vector2i(-1, 0))
	assert_true(turn_system.is_game_over(), "Game over when returning to exit with shard")
	assert_true(turn_system.is_floor_complete(), "Floor complete")

	turn_system.free()

func test_shard_and_exit_reset_on_game_reset() -> void:
	"""Test that shard_collected and floor_complete reset on game reset."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Setup and complete a floor
	turn_system.add_pickup(Vector2i(0, 0), "shard")
	turn_system.set_grid_tile(Vector2i(1, 0), "exit")

	turn_system.execute_turn("wait")  # Collect shard
	turn_system.execute_turn("move", Vector2i(1, 0))  # Exit

	assert_true(turn_system.is_shard_collected(), "Shard collected before reset")
	assert_true(turn_system.is_floor_complete(), "Floor complete before reset")

	# Reset the game
	turn_system.reset()

	# Verify flags are reset
	assert_false(turn_system.is_shard_collected(), "Shard flag reset")
	assert_false(turn_system.is_floor_complete(), "Floor complete flag reset")
	assert_false(turn_system.is_game_over(), "Game over flag reset")

	turn_system.free()

func test_exit_only_once() -> void:
	"""Test that exit only triggers once (game_over prevents multiple triggers)."""
	var turn_system = load("res://scripts/turn_system.gd").new()
	turn_system.reset()

	# Setup
	turn_system.add_pickup(Vector2i(0, 0), "shard")
	turn_system.set_grid_tile(Vector2i(1, 0), "exit")

	# Collect shard and exit
	turn_system.execute_turn("wait")
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(turn_system.is_game_over(), "Game over after first exit")
	var turn_count_after_exit = turn_system.get_turn_count()

	# Try to execute another turn (should fail since game is over)
	var result = turn_system.execute_turn("wait")
	assert_false(result, "Cannot execute turn after game over")
	assert_eq(turn_system.get_turn_count(), turn_count_after_exit, "Turn count unchanged after game over")

	turn_system.free()
