extends Node
## Tests for DungeonGenerator
##
## Validates dungeon generation with reachability requirements.

const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	print("Running DungeonGenerator tests...")

	test_generate_small_dungeon()
	test_generate_medium_dungeon()
	test_reachability_always_valid()
	test_reachability_multiple_seeds()
	test_invalid_dimensions()
	test_invalid_wall_density()
	test_high_wall_density_eventually_succeeds()
	test_special_tile_placement()
	test_deterministic_generation()
	test_check_reachability_utility()

	return {"passed": tests_passed, "failed": tests_failed}

func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])

func assert_true(condition: bool, test_name: String) -> void:
	assert_eq(condition, true, test_name)

func assert_false(condition: bool, test_name: String) -> void:
	assert_eq(condition, false, test_name)

func assert_greater(actual, minimum, test_name: String) -> void:
	if actual > minimum:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected > %s, got %s" % [test_name, minimum, actual])

func assert_greater_or_equal(actual, minimum, test_name: String) -> void:
	if actual >= minimum:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected >= %s, got %s" % [test_name, minimum, actual])

## Test generating a small dungeon
func test_generate_small_dungeon() -> void:
	var result = DungeonGenerator.generate_dungeon(5, 5, 12345, 0.2)

	assert_true(result.success, "Small dungeon generation succeeds")
	assert_eq(result.grid.size(), 5, "Grid has correct height")
	assert_eq(result.grid[0].size(), 5, "Grid has correct width")
	assert_greater_or_equal(result.attempts, 1, "At least one attempt made")

	# Validate positions are within bounds
	assert_true(result.start_pos.x >= 0 and result.start_pos.x < 5, "Start X in bounds")
	assert_true(result.start_pos.y >= 0 and result.start_pos.y < 5, "Start Y in bounds")
	assert_true(result.shard_pos.x >= 0 and result.shard_pos.x < 5, "Shard X in bounds")
	assert_true(result.shard_pos.y >= 0 and result.shard_pos.y < 5, "Shard Y in bounds")
	assert_true(result.exit_pos.x >= 0 and result.exit_pos.x < 5, "Exit X in bounds")
	assert_true(result.exit_pos.y >= 0 and result.exit_pos.y < 5, "Exit Y in bounds")

## Test generating a medium dungeon
func test_generate_medium_dungeon() -> void:
	var result = DungeonGenerator.generate_dungeon(10, 10, 54321, 0.3)

	assert_true(result.success, "Medium dungeon generation succeeds")
	assert_eq(result.grid.size(), 10, "Grid has correct height")
	assert_eq(result.grid[0].size(), 10, "Grid has correct width")

## Test that reachability is always valid in successful generations
func test_reachability_always_valid() -> void:
	var result = DungeonGenerator.generate_dungeon(8, 8, 99999, 0.25)

	if result.success:
		# Manually verify reachability
		var is_reachable = DungeonGenerator.check_reachability(result.grid, result.start_pos, result.shard_pos)
		assert_true(is_reachable, "Start to shard is reachable")

		is_reachable = DungeonGenerator.check_reachability(result.grid, result.shard_pos, result.exit_pos)
		assert_true(is_reachable, "Shard to exit is reachable")
	else:
		tests_failed += 1
		print("  ✗ Reachability test: dungeon generation failed")

## Test reachability with multiple random seeds
func test_reachability_multiple_seeds() -> void:
	var seeds = [1, 42, 1337, 9999, 55555]
	var all_valid = true

	for seed_value in seeds:
		var result = DungeonGenerator.generate_dungeon(7, 7, seed_value, 0.3)

		if not result.success:
			all_valid = false
			break

		# Verify start -> shard
		var path_exists = DungeonGenerator.check_reachability(result.grid, result.start_pos, result.shard_pos)
		if not path_exists:
			all_valid = false
			break

		# Verify shard -> exit
		path_exists = DungeonGenerator.check_reachability(result.grid, result.shard_pos, result.exit_pos)
		if not path_exists:
			all_valid = false
			break

	assert_true(all_valid, "All seeds produce valid reachability")

## Test invalid dimensions (too small)
func test_invalid_dimensions() -> void:
	var result = DungeonGenerator.generate_dungeon(2, 2, 123, 0.3)

	assert_false(result.success, "2x2 dungeon fails")
	assert_true(result.error_message.length() > 0, "Error message provided for small dungeon")

	result = DungeonGenerator.generate_dungeon(1, 10, 123, 0.3)
	assert_false(result.success, "1x10 dungeon fails")

	result = DungeonGenerator.generate_dungeon(10, 1, 123, 0.3)
	assert_false(result.success, "10x1 dungeon fails")

## Test invalid wall density
func test_invalid_wall_density() -> void:
	var result = DungeonGenerator.generate_dungeon(5, 5, 123, -0.1)
	assert_false(result.success, "Negative wall density fails")
	assert_true(result.error_message.length() > 0, "Error message for negative density")

	result = DungeonGenerator.generate_dungeon(5, 5, 123, 1.5)
	assert_false(result.success, "Wall density > 1.0 fails")

## Test that high wall density eventually succeeds (or fails gracefully)
func test_high_wall_density_eventually_succeeds() -> void:
	# With very high wall density, it should either succeed or fail after max attempts
	var result = DungeonGenerator.generate_dungeon(10, 10, 777, 0.7)

	# It should complete without hanging
	assert_true(result.attempts > 0, "Attempts were made")
	assert_true(result.attempts <= DungeonGenerator.MAX_GENERATION_ATTEMPTS, "Did not exceed max attempts")

	# If it failed, should have error message
	if not result.success:
		assert_true(result.error_message.length() > 0, "Error message on failure")
		assert_true(result.attempts == DungeonGenerator.MAX_GENERATION_ATTEMPTS, "Used all attempts before failing")

## Test that special tiles are placed on different positions
func test_special_tile_placement() -> void:
	var result = DungeonGenerator.generate_dungeon(6, 6, 555, 0.2)

	if result.success:
		# Start, shard, and exit should be at different positions
		assert_true(result.start_pos != result.shard_pos, "Start and shard are different")
		assert_true(result.start_pos != result.exit_pos, "Start and exit are different")
		assert_true(result.shard_pos != result.exit_pos, "Shard and exit are different")
	else:
		tests_failed += 1
		print("  ✗ Special tile placement test: dungeon generation failed")

## Test deterministic generation with same seed
func test_deterministic_generation() -> void:
	var seed_value = 424242

	var result1 = DungeonGenerator.generate_dungeon(8, 8, seed_value, 0.3)
	var result2 = DungeonGenerator.generate_dungeon(8, 8, seed_value, 0.3)

	if result1.success and result2.success:
		# Same seed should produce same positions
		assert_eq(result1.start_pos, result2.start_pos, "Deterministic start position")
		assert_eq(result1.shard_pos, result2.shard_pos, "Deterministic shard position")
		assert_eq(result1.exit_pos, result2.exit_pos, "Deterministic exit position")

		# Grid should be identical
		var grids_match = true
		for y in range(result1.grid.size()):
			for x in range(result1.grid[0].size()):
				if result1.grid[y][x] != result2.grid[y][x]:
					grids_match = false
					break
			if not grids_match:
				break

		assert_true(grids_match, "Deterministic grid generation")
	else:
		tests_failed += 1
		print("  ✗ Deterministic generation test: one or both generations failed")

## Test the check_reachability utility function
func test_check_reachability_utility() -> void:
	# Create a simple test grid with an isolated area
	var grid = [
		[0, 0, 0, 1, 0],
		[0, 1, 0, 1, 0],
		[0, 0, 0, 1, 0],
		[1, 1, 1, 1, 0],
		[0, 0, 0, 0, 0]
	]

	# Test reachable positions
	var is_reachable = DungeonGenerator.check_reachability(grid, Vector2i(0, 0), Vector2i(2, 2))
	assert_true(is_reachable, "Reachable positions return true")

	# Test unreachable positions (blocked by walls - position (4,0) is isolated)
	is_reachable = DungeonGenerator.check_reachability(grid, Vector2i(0, 0), Vector2i(4, 0))
	assert_false(is_reachable, "Unreachable positions return false")

	# Test same position
	is_reachable = DungeonGenerator.check_reachability(grid, Vector2i(2, 2), Vector2i(2, 2))
	assert_true(is_reachable, "Same position is reachable")
