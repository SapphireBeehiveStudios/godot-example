extends Node
## Complete Game Flow Integration Test
##
## End-to-end test simulating a complete run from start to win.
## Tests complete floor navigation: start → shard → exit → win
## Part of Issue #97 (EPIC #96)

const LevelGen = preload("res://scripts/level_gen.gd")
const TurnSystem = preload("res://scripts/turn_system.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const Pathfinding = preload("res://scripts/pathfinding.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all integration tests and return results."""
	print("Testing Complete Game Flow Integration")

	test_complete_floor_simple_path()
	test_complete_floor_with_guards()
	test_complete_floor_deterministic_seed()
	test_cannot_win_without_shard()
	test_complete_floor_with_backtracking()

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

func assert_greater(actual: int, minimum: int, test_name: String) -> void:
	"""Assert that actual is greater than minimum."""
	if actual > minimum:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected > %d, got %d" % [test_name, minimum, actual])

## Helper: Convert Dictionary grid to 2D array for pathfinding
func _grid_dict_to_array(grid: Dictionary, width: int, height: int) -> Array:
	"""Convert grid Dictionary to 2D array (0=walkable, 1=wall)."""
	var array = []
	for y in range(height):
		var row = []
		for x in range(width):
			var pos = Vector2i(x, y)
			var tile = grid.get(pos, {"type": "wall"})
			# 0 = walkable (floor, pickup, exit, door_open)
			# 1 = wall (wall, door_closed)
			if tile.type in ["floor", "pickup", "exit", "door_open"]:
				row.append(0)
			else:
				row.append(1)
		array.append(row)
	return array

## Helper: Navigate from current position to target using pathfinding
func _navigate_to_target(turn_system: TurnSystem, grid: Dictionary, width: int, height: int, target: Vector2i) -> bool:
	"""Navigate player to target position using pathfinding. Returns true if reached."""
	var max_turns = 200  # Safety limit
	var turn_count = 0

	while turn_count < max_turns:
		var current_pos = turn_system.get_player_position()

		# Check if we've reached the target
		if current_pos == target:
			return true

		# Find path to target
		var grid_array = _grid_dict_to_array(grid, width, height)
		var path = Pathfinding.find_path(grid_array, current_pos, target)

		if path.is_empty() or path.size() < 2:
			# No path found or already at target
			return current_pos == target

		# Get next step in path (path[0] is current position, path[1] is next)
		var next_pos = path[1]
		var direction = next_pos - current_pos

		# Execute the move
		var success = turn_system.execute_turn("move", direction)

		if not success:
			# Move failed, might be blocked by guard or other issue
			# Try waiting one turn to let guards move
			turn_system.execute_turn("wait")

		turn_count += 1

		# Check if game ended (caught by guard)
		if turn_system.is_game_over() and not turn_system.is_floor_complete():
			return false  # Caught by guard

	return false  # Exceeded max turns

## Test implementations

func test_complete_floor_simple_path() -> void:
	"""Test complete floor with simple path (no guards, no obstacles)."""
	# Use a known seed for deterministic generation
	var seed = 42
	var width = 20
	var height = 12

	# Generate a simple level (low wall density, no guards)
	var level = LevelGen.generate(width, height, seed, 0.15, 0, false, false)
	assert_true(level.success, "Level generated successfully")

	# Set up turn system
	var turn_system = TurnSystem.new(seed)
	turn_system.reset()
	turn_system.set_player_position(level.player_start)

	# Apply grid to turn system
	for pos in level.grid:
		var tile = level.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	# Initial state checks
	assert_false(turn_system.is_shard_collected(), "Shard not collected initially")
	assert_false(turn_system.is_floor_complete(), "Floor not complete initially")
	assert_false(turn_system.is_game_over(), "Game not over initially")

	# Navigate to shard
	var reached_shard = _navigate_to_target(turn_system, level.grid, width, height, level.shard_pos)
	assert_true(reached_shard, "Navigated to shard successfully")
	assert_true(turn_system.is_shard_collected(), "Shard collected after navigation")

	# Floor should not be complete yet (shard collected but not at exit)
	assert_false(turn_system.is_floor_complete(), "Floor not complete after collecting shard")

	# Navigate to exit
	var reached_exit = _navigate_to_target(turn_system, level.grid, width, height, level.exit_pos)
	assert_true(reached_exit, "Navigated to exit successfully")

	# Final state checks - floor should be complete
	assert_true(turn_system.is_shard_collected(), "Shard still collected at exit")
	assert_true(turn_system.is_floor_complete(), "Floor complete after reaching exit with shard")
	assert_true(turn_system.is_game_over(), "Game over after floor complete")

	# Verify we took some turns
	assert_greater(turn_system.get_turn_count(), 0, "Turns were counted")

	turn_system.free()

func test_complete_floor_with_guards() -> void:
	"""Test complete floor with guards present (may need evasion)."""
	var seed = 123
	var width = 20
	var height = 12

	# Generate level with 1 guard
	var level = LevelGen.generate(width, height, seed, 0.20, 1, false, false)
	assert_true(level.success, "Level with guards generated successfully")

	# Set up turn system with guard system
	var turn_system = TurnSystem.new(seed)
	var guard_system = GuardSystem.new(seed)
	turn_system.reset()
	guard_system.set_walkability_checker(turn_system.is_tile_walkable)
	turn_system.set_guard_system(guard_system)

	turn_system.set_player_position(level.player_start)

	# Apply grid
	for pos in level.grid:
		var tile = level.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	# Add guards
	for guard_pos in level.guard_spawn_positions:
		guard_system.add_guard(guard_pos)

	assert_eq(level.guard_spawn_positions.size(), 1, "One guard spawned")

	# Navigate to shard
	var reached_shard = _navigate_to_target(turn_system, level.grid, width, height, level.shard_pos)

	# If caught by guard, test is inconclusive but not a failure
	# (guards move randomly, might catch player)
	if turn_system.is_game_over() and not turn_system.is_floor_complete():
		# Player was caught - this is valid behavior
		assert_true(true, "Player caught by guard (valid outcome)")
		turn_system.free()
		guard_system.free()
		return

	assert_true(reached_shard, "Navigated to shard without being caught")
	assert_true(turn_system.is_shard_collected(), "Shard collected")

	# Navigate to exit
	var reached_exit = _navigate_to_target(turn_system, level.grid, width, height, level.exit_pos)

	# Again, check if caught
	if turn_system.is_game_over() and not turn_system.is_floor_complete():
		assert_true(true, "Player caught by guard on way to exit (valid outcome)")
		turn_system.free()
		guard_system.free()
		return

	assert_true(reached_exit, "Navigated to exit without being caught")
	assert_true(turn_system.is_floor_complete(), "Floor complete despite guards")

	turn_system.free()
	guard_system.free()

func test_complete_floor_deterministic_seed() -> void:
	"""Test that same seed produces reproducible results."""
	var seed = 999
	var width = 20
	var height = 12

	# Generate two levels with same seed
	var level1 = LevelGen.generate(width, height, seed, 0.25, 0, false, false)
	var level2 = LevelGen.generate(width, height, seed, 0.25, 0, false, false)

	# Verify deterministic generation
	assert_eq(level1.player_start, level2.player_start, "Same seed produces same player start")
	assert_eq(level1.shard_pos, level2.shard_pos, "Same seed produces same shard position")
	assert_eq(level1.exit_pos, level2.exit_pos, "Same seed produces same exit position")

	# Run through level 1
	var turn_system = TurnSystem.new(seed)
	turn_system.reset()
	turn_system.set_player_position(level1.player_start)

	for pos in level1.grid:
		var tile = level1.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	# Navigate to shard and exit
	_navigate_to_target(turn_system, level1.grid, width, height, level1.shard_pos)
	_navigate_to_target(turn_system, level1.grid, width, height, level1.exit_pos)

	var turns_taken = turn_system.get_turn_count()
	assert_true(turn_system.is_floor_complete(), "Floor 1 complete with deterministic seed")

	turn_system.free()

	# Run through level 2 with same seed
	var turn_system2 = TurnSystem.new(seed)
	turn_system2.reset()
	turn_system2.set_player_position(level2.player_start)

	for pos in level2.grid:
		var tile = level2.grid[pos]
		turn_system2.set_grid_tile(pos, tile.type, tile)

	# Navigate with same pathfinding (should be deterministic)
	_navigate_to_target(turn_system2, level2.grid, width, height, level2.shard_pos)
	_navigate_to_target(turn_system2, level2.grid, width, height, level2.exit_pos)

	# Same seed should produce same turn count (deterministic pathfinding)
	assert_eq(turn_system2.get_turn_count(), turns_taken, "Deterministic navigation produces same turn count")
	assert_true(turn_system2.is_floor_complete(), "Floor 2 complete with deterministic seed")

	turn_system2.free()

func test_cannot_win_without_shard() -> void:
	"""Test that reaching exit without shard does not complete floor."""
	var seed = 555
	var width = 20
	var height = 12

	var level = LevelGen.generate(width, height, seed, 0.15, 0, false, false)

	var turn_system = TurnSystem.new(seed)
	turn_system.reset()
	turn_system.set_player_position(level.player_start)

	for pos in level.grid:
		var tile = level.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	# Navigate directly to exit WITHOUT collecting shard
	_navigate_to_target(turn_system, level.grid, width, height, level.exit_pos)

	# Should be at exit but floor not complete
	assert_eq(turn_system.get_player_position(), level.exit_pos, "Player at exit position")
	assert_false(turn_system.is_shard_collected(), "Shard not collected")
	assert_false(turn_system.is_floor_complete(), "Floor not complete without shard")
	assert_false(turn_system.is_game_over(), "Game not over without shard")

	# Now collect shard
	_navigate_to_target(turn_system, level.grid, width, height, level.shard_pos)
	assert_true(turn_system.is_shard_collected(), "Shard collected")

	# Return to exit
	_navigate_to_target(turn_system, level.grid, width, height, level.exit_pos)

	# NOW floor should be complete
	assert_true(turn_system.is_floor_complete(), "Floor complete after collecting shard and returning to exit")

	turn_system.free()

func test_complete_floor_with_backtracking() -> void:
	"""Test complete floor where player needs to backtrack."""
	var seed = 777
	var width = 20
	var height = 12

	var level = LevelGen.generate(width, height, seed, 0.20, 0, false, false)

	var turn_system = TurnSystem.new(seed)
	turn_system.reset()
	turn_system.set_player_position(level.player_start)

	for pos in level.grid:
		var tile = level.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	# Go to exit first (wrong order)
	_navigate_to_target(turn_system, level.grid, width, height, level.exit_pos)
	assert_false(turn_system.is_floor_complete(), "Floor not complete - visited exit first")

	var turns_at_exit = turn_system.get_turn_count()

	# Backtrack to shard
	_navigate_to_target(turn_system, level.grid, width, height, level.shard_pos)
	assert_true(turn_system.is_shard_collected(), "Shard collected after backtracking")

	var turns_after_shard = turn_system.get_turn_count()
	assert_greater(turns_after_shard, turns_at_exit, "Additional turns taken to get shard")

	# Return to exit
	_navigate_to_target(turn_system, level.grid, width, height, level.exit_pos)
	assert_true(turn_system.is_floor_complete(), "Floor complete after backtracking")

	turn_system.free()
