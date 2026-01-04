extends RefCounted
## Test suite for LevelGen
##
## Tests:
## - Basic generation succeeds
## - Determinism (same seed produces same layout)
## - Validity (correct counts of special tiles)
## - Guard placement constraints
## - Keycard placement constraints
##
## Part of Issue #25

const LevelGen = preload("res://scripts/level_gen.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests and return {passed: int, failed: int}."""
	test_basic_generation()
	test_determinism_same_seed()
	test_determinism_different_seeds()
	test_validity_tile_counts()
	test_validity_special_positions()
	test_guard_placement_minimum_distance()
	test_guard_placement_count()
	test_keycard_placement()
	test_grid_format()
	test_player_start_is_floor()

	return {"passed": tests_passed, "failed": tests_failed}

## Test that basic generation succeeds
func test_basic_generation() -> void:
	var result = LevelGen.generate(24, 14, 12345, 0.3)

	if not result.success:
		print("  ✗ test_basic_generation: generation failed - ", result.error_message)
		tests_failed += 1
		return

	if result.grid.is_empty():
		print("  ✗ test_basic_generation: grid is empty")
		tests_failed += 1
		return

	print("  ✓ test_basic_generation")
	tests_passed += 1

## Test determinism: same seed produces same layout
func test_determinism_same_seed() -> void:
	var seed_value = 42
	var result1 = LevelGen.generate(24, 14, seed_value, 0.3)
	var result2 = LevelGen.generate(24, 14, seed_value, 0.3)

	if not result1.success or not result2.success:
		print("  ✗ test_determinism_same_seed: generation failed")
		tests_failed += 1
		return

	# Compare grid layouts (hash)
	var hash1 = _hash_grid(result1.grid)
	var hash2 = _hash_grid(result2.grid)

	if hash1 != hash2:
		print("  ✗ test_determinism_same_seed: layouts differ - hash1=", hash1, " hash2=", hash2)
		tests_failed += 1
		return

	# Compare special positions
	if result1.player_start != result2.player_start:
		print("  ✗ test_determinism_same_seed: player_start differs")
		tests_failed += 1
		return

	if result1.shard_pos != result2.shard_pos:
		print("  ✗ test_determinism_same_seed: shard_pos differs")
		tests_failed += 1
		return

	if result1.exit_pos != result2.exit_pos:
		print("  ✗ test_determinism_same_seed: exit_pos differs")
		tests_failed += 1
		return

	print("  ✓ test_determinism_same_seed")
	tests_passed += 1

## Test that different seeds produce different layouts
func test_determinism_different_seeds() -> void:
	var result1 = LevelGen.generate(24, 14, 111, 0.3)
	var result2 = LevelGen.generate(24, 14, 222, 0.3)

	if not result1.success or not result2.success:
		print("  ✗ test_determinism_different_seeds: generation failed")
		tests_failed += 1
		return

	var hash1 = _hash_grid(result1.grid)
	var hash2 = _hash_grid(result2.grid)

	if hash1 == hash2:
		print("  ✗ test_determinism_different_seeds: layouts are identical (should differ)")
		tests_failed += 1
		return

	print("  ✓ test_determinism_different_seeds")
	tests_passed += 1

## Test validity: correct counts of special tiles
func test_validity_tile_counts() -> void:
	var result = LevelGen.generate(24, 14, 99999, 0.3)

	if not result.success:
		print("  ✗ test_validity_tile_counts: generation failed")
		tests_failed += 1
		return

	# Count special tiles
	var shard_count = 0
	var exit_count = 0
	var wall_count = 0
	var floor_count = 0

	for pos in result.grid:
		var tile = result.grid[pos]
		match tile.type:
			"wall":
				wall_count += 1
			"floor":
				floor_count += 1
			"pickup":
				if tile.get("pickup_type", "") == "shard":
					shard_count += 1
			"exit":
				exit_count += 1

	# Validate counts
	if shard_count != 1:
		print("  ✗ test_validity_tile_counts: expected 1 shard, got ", shard_count)
		tests_failed += 1
		return

	if exit_count != 1:
		print("  ✗ test_validity_tile_counts: expected 1 exit, got ", exit_count)
		tests_failed += 1
		return

	if wall_count == 0:
		print("  ✗ test_validity_tile_counts: expected some walls, got 0")
		tests_failed += 1
		return

	if floor_count == 0:
		print("  ✗ test_validity_tile_counts: expected some floors, got 0")
		tests_failed += 1
		return

	print("  ✓ test_validity_tile_counts")
	tests_passed += 1

## Test that special positions are on floor tiles
func test_validity_special_positions() -> void:
	var result = LevelGen.generate(24, 14, 77777, 0.3)

	if not result.success:
		print("  ✗ test_validity_special_positions: generation failed")
		tests_failed += 1
		return

	# Check player start is on a valid position
	if not result.grid.has(result.player_start):
		print("  ✗ test_validity_special_positions: player_start not in grid")
		tests_failed += 1
		return

	# Check shard is on a pickup tile
	if not result.grid.has(result.shard_pos):
		print("  ✗ test_validity_special_positions: shard_pos not in grid")
		tests_failed += 1
		return

	if result.grid[result.shard_pos].type != "pickup":
		print("  ✗ test_validity_special_positions: shard_pos is not a pickup tile")
		tests_failed += 1
		return

	# Check exit is on an exit tile
	if not result.grid.has(result.exit_pos):
		print("  ✗ test_validity_special_positions: exit_pos not in grid")
		tests_failed += 1
		return

	if result.grid[result.exit_pos].type != "exit":
		print("  ✗ test_validity_special_positions: exit_pos is not an exit tile")
		tests_failed += 1
		return

	print("  ✓ test_validity_special_positions")
	tests_passed += 1

## Test guard placement respects minimum distance constraints
func test_guard_placement_minimum_distance() -> void:
	var result = LevelGen.generate(24, 14, 55555, 0.25, 2)  # 2 guards

	if not result.success:
		print("  ✗ test_guard_placement_minimum_distance: generation failed")
		tests_failed += 1
		return

	const MIN_DISTANCE = 3

	# Check each guard's distance from special tiles
	for guard_pos in result.guard_spawn_positions:
		var dist_to_player = _manhattan_distance(guard_pos, result.player_start)
		if dist_to_player < MIN_DISTANCE:
			print("  ✗ test_guard_placement_minimum_distance: guard too close to player (", dist_to_player, ")")
			tests_failed += 1
			return

		var dist_to_shard = _manhattan_distance(guard_pos, result.shard_pos)
		if dist_to_shard < MIN_DISTANCE:
			print("  ✗ test_guard_placement_minimum_distance: guard too close to shard (", dist_to_shard, ")")
			tests_failed += 1
			return

		var dist_to_exit = _manhattan_distance(guard_pos, result.exit_pos)
		if dist_to_exit < MIN_DISTANCE:
			print("  ✗ test_guard_placement_minimum_distance: guard too close to exit (", dist_to_exit, ")")
			tests_failed += 1
			return

	print("  ✓ test_guard_placement_minimum_distance")
	tests_passed += 1

## Test guard placement produces correct count
func test_guard_placement_count() -> void:
	var result = LevelGen.generate(24, 14, 33333, 0.25, 3)  # 3 guards

	if not result.success:
		print("  ✗ test_guard_placement_count: generation failed")
		tests_failed += 1
		return

	if result.guard_spawn_positions.size() != 3:
		print("  ✗ test_guard_placement_count: expected 3 guards, got ", result.guard_spawn_positions.size())
		tests_failed += 1
		return

	# Check guards don't overlap
	var seen_positions: Dictionary = {}
	for guard_pos in result.guard_spawn_positions:
		if guard_pos in seen_positions:
			print("  ✗ test_guard_placement_count: duplicate guard position at ", guard_pos)
			tests_failed += 1
			return
		seen_positions[guard_pos] = true

	print("  ✓ test_guard_placement_count")
	tests_passed += 1

## Test keycard placement
func test_keycard_placement() -> void:
	var result = LevelGen.generate(24, 14, 88888, 0.25, 1, true)  # 1 guard, 1 keycard

	if not result.success:
		print("  ✗ test_keycard_placement: generation failed")
		tests_failed += 1
		return

	if result.keycard_positions.size() != 1:
		print("  ✗ test_keycard_placement: expected 1 keycard, got ", result.keycard_positions.size())
		tests_failed += 1
		return

	var keycard_pos = result.keycard_positions[0]

	# Check keycard is on a pickup tile
	if not result.grid.has(keycard_pos):
		print("  ✗ test_keycard_placement: keycard_pos not in grid")
		tests_failed += 1
		return

	if result.grid[keycard_pos].type != "pickup":
		print("  ✗ test_keycard_placement: keycard is not a pickup tile")
		tests_failed += 1
		return

	if result.grid[keycard_pos].get("pickup_type", "") != "keycard":
		print("  ✗ test_keycard_placement: pickup is not a keycard")
		tests_failed += 1
		return

	print("  ✓ test_keycard_placement")
	tests_passed += 1

## Test grid format is correct
func test_grid_format() -> void:
	var result = LevelGen.generate(10, 10, 11111, 0.3)

	if not result.success:
		print("  ✗ test_grid_format: generation failed")
		tests_failed += 1
		return

	# Grid should be a Dictionary
	if typeof(result.grid) != TYPE_DICTIONARY:
		print("  ✗ test_grid_format: grid is not a Dictionary")
		tests_failed += 1
		return

	# Check a few tiles have the correct structure
	var checked = 0
	for pos in result.grid:
		if checked >= 5:
			break

		var tile = result.grid[pos]
		if typeof(tile) != TYPE_DICTIONARY:
			print("  ✗ test_grid_format: tile at ", pos, " is not a Dictionary")
			tests_failed += 1
			return

		if not tile.has("type"):
			print("  ✗ test_grid_format: tile at ", pos, " has no 'type' field")
			tests_failed += 1
			return

		checked += 1

	print("  ✓ test_grid_format")
	tests_passed += 1

## Test that player start is on a floor (or floor-like) tile
func test_player_start_is_floor() -> void:
	var result = LevelGen.generate(15, 12, 66666, 0.3)

	if not result.success:
		print("  ✗ test_player_start_is_floor: generation failed")
		tests_failed += 1
		return

	# Player start should be in grid
	if not result.grid.has(result.player_start):
		print("  ✗ test_player_start_is_floor: player_start not in grid")
		tests_failed += 1
		return

	# Player start should be on a walkable tile (floor)
	var tile_type = result.grid[result.player_start].type
	if tile_type != "floor":
		print("  ✗ test_player_start_is_floor: player_start is on ", tile_type, " (expected floor)")
		tests_failed += 1
		return

	print("  ✓ test_player_start_is_floor")
	tests_passed += 1

## Helper: Hash a grid for determinism testing
func _hash_grid(grid: Dictionary) -> int:
	var hash_str = ""

	# Sort positions for consistent hashing
	var positions = grid.keys()
	positions.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))

	for pos in positions:
		var tile = grid[pos]
		hash_str += str(pos.x) + "," + str(pos.y) + ":" + tile.type + ";"

	return hash_str.hash()

## Helper: Calculate Manhattan distance
func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
