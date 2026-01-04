extends Node
## Tests for FloorProgression - Issue #44
##
## Tests multi-floor run progression (1→2→3), difficulty ramping,
## and run win conditions.

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	print("\n=== FloorProgression Tests ===")

	# Basic floor tracking
	test_initial_state()
	test_advance_floor()
	test_floor_progression_sequence()
	test_cannot_advance_beyond_floor_3()

	# Difficulty ramp
	test_guard_count_ramp()
	test_door_chance_ramp()
	test_difficulty_params_all_floors()

	# Run completion
	test_complete_floor_1_advances()
	test_complete_floor_2_advances()
	test_complete_floor_3_wins_run()
	test_run_win_condition()

	# Edge cases
	test_is_final_floor()
	test_reset_clears_state()

	# Serialization
	test_serialization()

	print("FloorProgression: %d passed, %d failed" % [tests_passed, tests_failed])
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

func assert_float_eq(actual: float, expected: float, test_name: String) -> void:
	if abs(actual - expected) < 0.001:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])

# ===== Basic Floor Tracking =====

func test_initial_state() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()
	assert_eq(fp.get_current_floor(), 1, "Initial floor is 1")
	assert_false(fp.is_run_complete(), "Run not complete initially")
	assert_false(fp.is_run_won(), "Run not won initially")

func test_advance_floor() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()
	var result = fp.advance_floor()
	assert_true(result, "Advance floor 1→2 succeeds")
	assert_eq(fp.get_current_floor(), 2, "Floor advanced to 2")


func test_floor_progression_sequence() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	assert_eq(fp.get_current_floor(), 1, "Start at floor 1")

	fp.advance_floor()
	assert_eq(fp.get_current_floor(), 2, "Advance to floor 2")

	fp.advance_floor()
	assert_eq(fp.get_current_floor(), 3, "Advance to floor 3")



func test_cannot_advance_beyond_floor_3() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	fp.advance_floor()  # 1→2
	fp.advance_floor()  # 2→3

	var result = fp.advance_floor()  # Try 3→4
	assert_false(result, "Cannot advance beyond floor 3")
	assert_eq(fp.get_current_floor(), 3, "Still on floor 3")



# ===== Difficulty Ramp =====

func test_guard_count_ramp() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	# Floor 1: 2 guards
	assert_eq(fp.get_guard_count_for_floor(1), 2, "Floor 1 has 2 guards")

	# Floor 2: 3 guards
	assert_eq(fp.get_guard_count_for_floor(2), 3, "Floor 2 has 3 guards")

	# Floor 3: 4 guards
	assert_eq(fp.get_guard_count_for_floor(3), 4, "Floor 3 has 4 guards")



func test_door_chance_ramp() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	# Floor 1: 10% door chance
	assert_float_eq(fp.get_door_chance_for_floor(1), 0.1, "Floor 1 has 10% door chance")

	# Floor 2: 15% door chance
	assert_float_eq(fp.get_door_chance_for_floor(2), 0.15, "Floor 2 has 15% door chance")

	# Floor 3: 20% door chance
	assert_float_eq(fp.get_door_chance_for_floor(3), 0.2, "Floor 3 has 20% door chance")



func test_difficulty_params_all_floors() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	var floor1_params = fp.get_difficulty_params(1)
	assert_eq(floor1_params["guard_count"], 2, "Floor 1 params: guard_count=2")
	assert_float_eq(floor1_params["door_chance"], 0.1, "Floor 1 params: door_chance=0.1")

	var floor2_params = fp.get_difficulty_params(2)
	assert_eq(floor2_params["guard_count"], 3, "Floor 2 params: guard_count=3")
	assert_float_eq(floor2_params["door_chance"], 0.15, "Floor 2 params: door_chance=0.15")

	var floor3_params = fp.get_difficulty_params(3)
	assert_eq(floor3_params["guard_count"], 4, "Floor 3 params: guard_count=4")
	assert_float_eq(floor3_params["door_chance"], 0.2, "Floor 3 params: door_chance=0.2")



# ===== Run Completion =====

func test_complete_floor_1_advances() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	assert_eq(fp.get_current_floor(), 1, "Start on floor 1")
	fp.complete_floor()
	assert_eq(fp.get_current_floor(), 2, "Completing floor 1 advances to floor 2")
	assert_false(fp.is_run_complete(), "Run not complete after floor 1")
	assert_false(fp.is_run_won(), "Run not won after floor 1")



func test_complete_floor_2_advances() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	fp.advance_floor()  # Go to floor 2
	assert_eq(fp.get_current_floor(), 2, "On floor 2")

	fp.complete_floor()
	assert_eq(fp.get_current_floor(), 3, "Completing floor 2 advances to floor 3")
	assert_false(fp.is_run_complete(), "Run not complete after floor 2")
	assert_false(fp.is_run_won(), "Run not won after floor 2")



func test_complete_floor_3_wins_run() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	fp.advance_floor()  # 1→2
	fp.advance_floor()  # 2→3
	assert_eq(fp.get_current_floor(), 3, "On floor 3")

	fp.complete_floor()
	assert_eq(fp.get_current_floor(), 3, "Still on floor 3 after completion")
	assert_true(fp.is_run_complete(), "Run complete after floor 3")
	assert_true(fp.is_run_won(), "Run won after floor 3")



func test_run_win_condition() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	# Simulate full run: floor 1 → 2 → 3 → win
	fp.complete_floor()  # Floor 1 done
	assert_false(fp.is_run_won(), "Not won after floor 1")

	fp.complete_floor()  # Floor 2 done
	assert_false(fp.is_run_won(), "Not won after floor 2")

	fp.complete_floor()  # Floor 3 done
	assert_true(fp.is_run_won(), "Run won after floor 3 completion")



# ===== Edge Cases =====

func test_is_final_floor() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	assert_false(fp.is_final_floor(), "Floor 1 is not final")

	fp.advance_floor()
	assert_false(fp.is_final_floor(), "Floor 2 is not final")

	fp.advance_floor()
	assert_true(fp.is_final_floor(), "Floor 3 is final")



func test_reset_clears_state() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	# Advance to floor 3 and win
	fp.advance_floor()
	fp.advance_floor()
	fp.complete_floor()

	assert_eq(fp.get_current_floor(), 3, "On floor 3 before reset")
	assert_true(fp.is_run_won(), "Run won before reset")

	# Reset
	fp.reset()

	assert_eq(fp.get_current_floor(), 1, "Back to floor 1 after reset")
	assert_false(fp.is_run_complete(), "Run not complete after reset")
	assert_false(fp.is_run_won(), "Run not won after reset")



# ===== Serialization =====

func test_serialization() -> void:
	var fp = load("res://scripts/floor_progression.gd").new()

	# Set up state
	fp.advance_floor()  # Floor 2
	fp.advance_floor()  # Floor 3
	fp.complete_floor()  # Win

	# Serialize
	var data = fp.to_dict()
	assert_eq(data["current_floor"], 3, "Serialized floor is 3")
	assert_true(data["run_complete"], "Serialized run_complete is true")
	assert_true(data["run_won"], "Serialized run_won is true")

	# Create new instance and deserialize
	var fp2 = load("res://scripts/floor_progression.gd").new()
	fp2.from_dict(data)

	assert_eq(fp2.get_current_floor(), 3, "Deserialized floor is 3")
	assert_true(fp2.is_run_complete(), "Deserialized run_complete is true")
	assert_true(fp2.is_run_won(), "Deserialized run_won is true")
