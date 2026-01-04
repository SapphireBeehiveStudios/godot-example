extends Node
## Tests for infinite floor progression and difficulty scaling
## Part of EPIC 7 - Issue #44

const DifficultyConfig = preload("res://scripts/difficulty_config.gd")
const RunProgressionManager = preload("res://scripts/run_progression_manager.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	print("Testing Floor Progression System (Infinite Mode)")

	# Difficulty config tests
	test_difficulty_params_floor_1()
	test_difficulty_params_floor_2()
	test_difficulty_params_floor_3()
	test_difficulty_ramp_guard_count()
	test_difficulty_ramp_wall_density()
	test_is_final_floor()

	# Run progression tests
	test_progression_initial_state()
	test_progression_advance_floor()
	test_progression_floor_1_to_2()
	test_progression_floor_2_to_3()
	test_progression_infinite_continues()
	test_progression_can_advance_indefinitely()
	test_progression_reset()

	# Dungeon generation with difficulty
	test_generate_dungeon_for_floor_1()
	test_generate_dungeon_for_floor_2()
	test_generate_dungeon_for_floor_3()
	test_floor_seed_determinism()

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

func assert_float_eq(actual: float, expected: float, test_name: String, epsilon: float = 0.001) -> void:
	if abs(actual - expected) < epsilon:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])

# ============================================================================
# Difficulty Config Tests
# ============================================================================

func test_difficulty_params_floor_1() -> void:
	var params = DifficultyConfig.get_floor_params(1)
	assert_eq(params.floor_number, 1, "Floor 1 number")
	assert_eq(params.guard_count, 1, "Floor 1 has 1 guard")
	assert_float_eq(params.wall_density, 0.2, "Floor 1 wall density")

func test_difficulty_params_floor_2() -> void:
	var params = DifficultyConfig.get_floor_params(2)
	assert_eq(params.floor_number, 2, "Floor 2 number")
	# Guards scale: 1 + (floor-1)/2 = 1 + 0 = 1
	assert_eq(params.guard_count, 1, "Floor 2 has 1 guard")
	assert_float_eq(params.wall_density, 0.22, "Floor 2 wall density")

func test_difficulty_params_floor_3() -> void:
	var params = DifficultyConfig.get_floor_params(3)
	assert_eq(params.floor_number, 3, "Floor 3 number")
	# Guards scale: 1 + (floor-1)/2 = 1 + 1 = 2
	assert_eq(params.guard_count, 2, "Floor 3 has 2 guards")
	assert_float_eq(params.wall_density, 0.24, "Floor 3 wall density")

func test_difficulty_ramp_guard_count() -> void:
	# Guards increase every 2 floors: floor 1-2 have 1, floor 3-4 have 2, etc.
	var floor1 = DifficultyConfig.get_floor_params(1)
	var floor3 = DifficultyConfig.get_floor_params(3)
	var floor5 = DifficultyConfig.get_floor_params(5)

	assert_true(floor1.guard_count < floor3.guard_count, "Guards increase from floor 1 to 3")
	assert_true(floor3.guard_count < floor5.guard_count, "Guards increase from floor 3 to 5")

func test_difficulty_ramp_wall_density() -> void:
	var floor1 = DifficultyConfig.get_floor_params(1)
	var floor2 = DifficultyConfig.get_floor_params(2)
	var floor3 = DifficultyConfig.get_floor_params(3)

	assert_true(floor1.wall_density < floor2.wall_density, "Wall density increases from floor 1 to 2")
	assert_true(floor2.wall_density < floor3.wall_density, "Wall density increases from floor 2 to 3")

func test_is_final_floor() -> void:
	# Infinite mode - no floor is ever final
	assert_false(DifficultyConfig.is_final_floor(1), "Floor 1 is not final")
	assert_false(DifficultyConfig.is_final_floor(3), "Floor 3 is not final")
	assert_false(DifficultyConfig.is_final_floor(10), "Floor 10 is not final")
	assert_false(DifficultyConfig.is_final_floor(100), "Floor 100 is not final")

# ============================================================================
# Run Progression Tests
# ============================================================================

func test_progression_initial_state() -> void:
	var manager = RunProgressionManager.new(12345)
	assert_eq(manager.get_current_floor(), 1, "Starts on floor 1")
	assert_false(manager.is_final_floor(), "Floor 1 is not final")
	assert_false(manager.is_run_complete(), "Run not complete at start")

func test_progression_advance_floor() -> void:
	var manager = RunProgressionManager.new(12345)
	var result = manager.advance_floor()

	assert_true(result, "Advance floor succeeds")
	assert_eq(manager.get_current_floor(), 2, "Advanced to floor 2")

func test_progression_floor_1_to_2() -> void:
	var manager = RunProgressionManager.new(12345)

	# Complete floor 1
	var result = manager.complete_floor()
	assert_eq(result, "continue", "Floor 1 complete continues to floor 2")
	assert_eq(manager.get_current_floor(), 2, "Now on floor 2")
	assert_false(manager.is_final_floor(), "Floor 2 is not final")

func test_progression_floor_2_to_3() -> void:
	var manager = RunProgressionManager.new(12345)

	# Complete floors 1 and 2
	manager.complete_floor()  # 1 -> 2
	var result = manager.complete_floor()  # 2 -> 3

	assert_eq(result, "continue", "Floor 2 complete continues to floor 3")
	assert_eq(manager.get_current_floor(), 3, "Now on floor 3")
	assert_false(manager.is_final_floor(), "Floor 3 is not final (infinite mode)")

func test_progression_infinite_continues() -> void:
	var manager = RunProgressionManager.new(12345)

	# Complete many floors - all should continue (infinite mode)
	for i in range(10):
		var result = manager.complete_floor()
		assert_eq(result, "continue", "Floor %d complete continues" % (i + 1))

	assert_eq(manager.get_current_floor(), 11, "Advanced to floor 11")
	assert_false(manager.is_run_complete(), "Infinite run is never complete")

func test_progression_can_advance_indefinitely() -> void:
	var manager = RunProgressionManager.new(12345)

	# Advance well past floor 3
	for i in range(20):
		var result = manager.advance_floor()
		assert_true(result, "Can always advance in infinite mode")

	assert_eq(manager.get_current_floor(), 21, "Advanced to floor 21")

func test_progression_reset() -> void:
	var manager = RunProgressionManager.new(12345)

	# Advance to floor 2
	manager.advance_floor()
	assert_eq(manager.get_current_floor(), 2, "On floor 2 before reset")

	# Reset
	manager.reset()
	assert_eq(manager.get_current_floor(), 1, "Back to floor 1 after reset")

# ============================================================================
# Dungeon Generation with Difficulty
# ============================================================================

func test_generate_dungeon_for_floor_1() -> void:
	var manager = RunProgressionManager.new(12345, 10, 8)

	var result = manager.generate_dungeon_for_current_floor()
	assert_true(result.success, "Floor 1 dungeon generated successfully")
	assert_eq(result.grid.size(), 8, "Floor 1 dungeon has correct height")
	assert_eq(result.grid[0].size(), 10, "Floor 1 dungeon has correct width")

	# Check guard count for floor 1
	var guard_count = manager.get_guard_count_for_current_floor()
	assert_eq(guard_count, 1, "Floor 1 should have 1 guard")

func test_generate_dungeon_for_floor_2() -> void:
	var manager = RunProgressionManager.new(12345, 10, 8)
	manager.advance_floor()  # -> floor 2

	var result = manager.generate_dungeon_for_current_floor()
	assert_true(result.success, "Floor 2 dungeon generated successfully")

	# Check guard count for floor 2 (guards scale: 1 + (floor-1)/2)
	var guard_count = manager.get_guard_count_for_current_floor()
	assert_eq(guard_count, 1, "Floor 2 should have 1 guard")

func test_generate_dungeon_for_floor_3() -> void:
	var manager = RunProgressionManager.new(12345, 10, 8)
	manager.advance_floor()  # -> floor 2
	manager.advance_floor()  # -> floor 3

	var result = manager.generate_dungeon_for_current_floor()
	assert_true(result.success, "Floor 3 dungeon generated successfully")

	# Check guard count for floor 3 (guards scale: 1 + (floor-1)/2 = 2)
	var guard_count = manager.get_guard_count_for_current_floor()
	assert_eq(guard_count, 2, "Floor 3 should have 2 guards")

func test_floor_seed_determinism() -> void:
	# Two managers with same seed should generate identical dungeons per floor
	var manager1 = RunProgressionManager.new(99999, 10, 8)
	var manager2 = RunProgressionManager.new(99999, 10, 8)

	var result1 = manager1.generate_dungeon_for_current_floor()
	var result2 = manager2.generate_dungeon_for_current_floor()

	# Compare start positions (deterministic placement)
	assert_eq(result1.start_pos, result2.start_pos, "Deterministic start position")
	assert_eq(result1.shard_pos, result2.shard_pos, "Deterministic shard position")
	assert_eq(result1.exit_pos, result2.exit_pos, "Deterministic exit position")

	# Different floors should have different seeds
	manager1.advance_floor()
	var floor2_result = manager1.generate_dungeon_for_current_floor()

	# Floor 2 should be different from floor 1 (high probability)
	var different = (floor2_result.start_pos != result1.start_pos or
					 floor2_result.shard_pos != result1.shard_pos or
					 floor2_result.exit_pos != result1.exit_pos)
	assert_true(different, "Different floors generate different dungeons")
