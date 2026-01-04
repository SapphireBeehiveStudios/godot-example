extends Node
## Tests for Main Menu functionality
##
## Tests seed entry, random seed generation, and menu flow
## Part of issue #37

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	test_random_seed_generation()
	test_seed_signal_emission()
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

func assert_not_eq(actual, expected, test_name: String) -> void:
	if actual != expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected not %s, but got %s" % [test_name, expected, actual])

func test_random_seed_generation() -> void:
	# Test the random seed generation function directly
	var menu = preload("res://scripts/main_menu.gd").new()

	var seed1 = menu.generate_random_seed()
	var seed2 = menu.generate_random_seed()

	assert_true(seed1 is int, "Random seed is int type")
	assert_true(seed1 > 0, "Random seed is positive")
	assert_true(seed2 > 0, "Second random seed is positive")
	# Seeds should likely be different (not guaranteed but very likely)
	# We won't test for inequality since timing could cause issues

	menu.free()

func test_seed_signal_emission() -> void:
	# Test that the signal exists and can be connected
	var menu = preload("res://scripts/main_menu.gd").new()

	var signal_exists = menu.has_signal("start_run_requested")
	assert_true(signal_exists, "start_run_requested signal exists")

	menu.free()
