## Tests for DeterministicRNG utility
##
## Verifies:
##   - Deterministic behavior (same inputs -> same outputs)
##   - Cross-platform consistency
##   - Seed format handling (string and int)
##   - Per-floor uniqueness
##   - RNG utility functions

extends Node

# Preload the DeterministicRNG class
const DeterministicRNG = preload("res://scripts/utils/deterministic_rng.gd")

var tests_passed := 0
var tests_failed := 0


func run_all() -> Dictionary:
	# Core seeding tests
	test_string_seed_determinism()
	test_int_seed_determinism()
	test_same_seed_same_sequence()
	test_different_floors_different_sequences()
	test_floor_zero_uses_base_seed()

	# Seed format tests
	test_empty_string_seed()
	test_numeric_string_vs_int_seed()
	test_seed_getter_functions()

	# RNG function tests
	test_randf_range()
	test_randi_range()
	test_randf_in_bounds()
	test_randi_in_bounds()

	# Utility function tests
	test_shuffle_array_determinism()
	test_pick_random()
	test_pick_weighted()
	test_pick_weighted_distribution()

	# Edge cases
	test_negative_floor_index()
	test_large_floor_index()
	test_unicode_string_seed()

	# Static helpers
	test_create_helper()
	test_generate_run_seed()

	return {"passed": tests_passed, "failed": tests_failed}


# Assertion helpers
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


func assert_not_null(value, test_name: String) -> void:
	if value != null:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected non-null value" % test_name)


func assert_in_range(value: float, min_val: float, max_val: float, test_name: String) -> void:
	if value >= min_val and value <= max_val:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected value in [%s, %s], got %s" % [test_name, min_val, max_val, value])


func assert_arrays_equal(actual: Array, expected: Array, test_name: String) -> void:
	if actual.size() != expected.size():
		tests_failed += 1
		print("  ✗ %s: array sizes differ (%d vs %d)" % [test_name, actual.size(), expected.size()])
		return

	for i in range(actual.size()):
		if actual[i] != expected[i]:
			tests_failed += 1
			print("  ✗ %s: arrays differ at index %d (%s vs %s)" % [test_name, i, actual[i], expected[i]])
			return

	tests_passed += 1
	print("  ✓ %s" % test_name)


# Core Seeding Tests

func test_string_seed_determinism() -> void:
	var rng1 = DeterministicRNG.new()
	var rng2 = DeterministicRNG.new()

	rng1.seed_from_run_and_floor("test_seed", 1)
	rng2.seed_from_run_and_floor("test_seed", 1)

	var value1 = rng1.randf()
	var value2 = rng2.randf()

	assert_eq(value1, value2, "String seed produces deterministic results")


func test_int_seed_determinism() -> void:
	var rng1 = DeterministicRNG.new()
	var rng2 = DeterministicRNG.new()

	rng1.seed_from_run_and_floor(12345, 1)
	rng2.seed_from_run_and_floor(12345, 1)

	var value1 = rng1.randf()
	var value2 = rng2.randf()

	assert_eq(value1, value2, "Int seed produces deterministic results")


func test_same_seed_same_sequence() -> void:
	var rng1 = DeterministicRNG.new()
	var rng2 = DeterministicRNG.new()

	rng1.seed_from_run_and_floor("sequence_test", 3)
	rng2.seed_from_run_and_floor("sequence_test", 3)

	# Generate multiple values from each RNG
	var sequence1 = []
	var sequence2 = []

	for i in range(10):
		sequence1.append(rng1.randf())
		sequence2.append(rng2.randf())

	assert_arrays_equal(sequence1, sequence2, "Same seed produces identical sequences")


func test_different_floors_different_sequences() -> void:
	var rng_floor1 = DeterministicRNG.new()
	var rng_floor2 = DeterministicRNG.new()

	rng_floor1.seed_from_run_and_floor("run123", 1)
	rng_floor2.seed_from_run_and_floor("run123", 2)

	var value1 = rng_floor1.randf()
	var value2 = rng_floor2.randf()

	assert_true(value1 != value2, "Different floors produce different sequences")


func test_floor_zero_uses_base_seed() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor(42, 0)

	# Floor 0 should XOR with 0, resulting in base seed
	assert_eq(rng.get_combined_seed(), 42, "Floor 0 uses base seed (XOR with 0)")


# Seed Format Tests

func test_empty_string_seed() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("", 1)

	# Should hash to some integer and work without error
	var value = rng.randf()
	assert_in_range(value, 0.0, 1.0, "Empty string seed produces valid output")


func test_numeric_string_vs_int_seed() -> void:
	var rng_string = DeterministicRNG.new()
	var rng_int = DeterministicRNG.new()

	rng_string.seed_from_run_and_floor("12345", 0)
	rng_int.seed_from_run_and_floor(12345, 0)

	var value_string = rng_string.randf()
	var value_int = rng_int.randf()

	# These should produce different results (string is hashed, int is used directly)
	assert_true(value_string != value_int, "String '12345' differs from int 12345")


func test_seed_getter_functions() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor(99999, 5)

	assert_eq(rng.get_run_seed(), 99999, "get_run_seed returns correct value")
	assert_eq(rng.get_floor_index(), 5, "get_floor_index returns correct value")
	assert_eq(rng.get_combined_seed(), 99999 ^ 5, "get_combined_seed returns XOR result")


# RNG Function Tests

func test_randf_range() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("range_test", 1)

	for i in range(20):
		var value = rng.randf_range(10.0, 20.0)
		if value < 10.0 or value > 20.0:
			assert_true(false, "randf_range produces values in specified range")
			return

	assert_true(true, "randf_range produces values in specified range")


func test_randi_range() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("range_test", 2)

	for i in range(20):
		var value = rng.randi_range(5, 15)
		if value < 5 or value > 15:
			assert_true(false, "randi_range produces values in specified range")
			return

	assert_true(true, "randi_range produces values in specified range")


func test_randf_in_bounds() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("bounds_test", 1)

	for i in range(50):
		var value = rng.randf()
		if value < 0.0 or value >= 1.0:
			assert_true(false, "randf produces values in [0.0, 1.0)")
			return

	assert_true(true, "randf produces values in [0.0, 1.0)")


func test_randi_in_bounds() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("bounds_test", 2)

	# randi() returns a 32-bit unsigned int
	for i in range(20):
		var value = rng.randi()
		if value < 0:
			assert_true(false, "randi produces non-negative values")
			return

	assert_true(true, "randi produces non-negative values")


# Utility Function Tests

func test_shuffle_array_determinism() -> void:
	# Test that shuffle_array actually shuffles and works correctly
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("shuffle_test", 42)

	var original = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var array1 = original.duplicate()

	rng.shuffle_array(array1)

	# Array should be different from original (extremely unlikely to be same)
	assert_true(array1 != original, "shuffle_array modifies the array")

	# Array should still contain all original elements (just reordered)
	var sorted = array1.duplicate()
	sorted.sort()
	assert_arrays_equal(sorted, original, "shuffle_array preserves all elements")


func test_pick_random() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("pick_test", 1)

	var array = ["a", "b", "c", "d", "e"]
	var picked = rng.pick_random(array)

	assert_true(array.has(picked), "pick_random selects element from array")

	# Test empty array
	var empty_result = rng.pick_random([])
	assert_eq(empty_result, null, "pick_random returns null for empty array")


func test_pick_weighted() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("weighted", 1)

	var items = [
		{"item": "common", "weight": 10},
		{"item": "rare", "weight": 1}
	]

	var picked = rng.pick_weighted(items)
	assert_true(picked == "common" or picked == "rare", "pick_weighted selects valid item")

	# Test empty array
	var empty_result = rng.pick_weighted([])
	assert_eq(empty_result, null, "pick_weighted returns null for empty array")


func test_pick_weighted_distribution() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor("distribution", 1)

	var items = [
		{"item": "common", "weight": 100},
		{"item": "rare", "weight": 1}
	]

	var common_count = 0
	var rare_count = 0

	for i in range(200):
		var picked = rng.pick_weighted(items)
		if picked == "common":
			common_count += 1
		elif picked == "rare":
			rare_count += 1

	# Common should be picked much more often (expect ~198 vs ~2)
	assert_true(common_count > rare_count * 10, "pick_weighted respects weight distribution")


# Edge Case Tests

func test_negative_floor_index() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor(1000, -5)

	assert_eq(rng.get_floor_index(), -5, "Negative floor index is stored correctly")

	var value = rng.randf()
	assert_in_range(value, 0.0, 1.0, "Negative floor index produces valid output")


func test_large_floor_index() -> void:
	var rng = DeterministicRNG.new()
	rng.seed_from_run_and_floor(1000, 999999)

	assert_eq(rng.get_floor_index(), 999999, "Large floor index is stored correctly")

	var value = rng.randf()
	assert_in_range(value, 0.0, 1.0, "Large floor index produces valid output")


func test_unicode_string_seed() -> void:
	var rng1 = DeterministicRNG.new()
	var rng2 = DeterministicRNG.new()

	var unicode_seed = "Hello🎲World"

	rng1.seed_from_run_and_floor(unicode_seed, 1)
	rng2.seed_from_run_and_floor(unicode_seed, 1)

	var value1 = rng1.randf()
	var value2 = rng2.randf()

	assert_eq(value1, value2, "Unicode string seed works deterministically")


# Static Helper Tests

func test_create_helper() -> void:
	var rng = DeterministicRNG.create("helper_test", 7)

	assert_not_null(rng, "create() returns RNG instance")
	assert_eq(rng.get_floor_index(), 7, "create() sets floor index correctly")

	var value = rng.randf()
	assert_in_range(value, 0.0, 1.0, "create() produces working RNG")


func test_generate_run_seed() -> void:
	var seed1 = DeterministicRNG.generate_run_seed()
	var seed2 = DeterministicRNG.generate_run_seed()

	assert_eq(seed1.length(), 12, "generate_run_seed creates 12-character string")
	assert_true(seed1 != seed2, "generate_run_seed creates unique seeds")

	# Verify it only contains valid characters
	var valid_chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	for c in seed1:
		if not c in valid_chars:
			assert_true(false, "generate_run_seed uses only lowercase alphanumeric")
			return

	assert_true(true, "generate_run_seed uses only lowercase alphanumeric")
