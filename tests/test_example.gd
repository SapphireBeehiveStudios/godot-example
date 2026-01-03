extends Node
## Example Test Module
##
## This module demonstrates the test framework structure.
## Add your own test methods following the same pattern.

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_basic_assertions()
	test_math_operations()
	test_string_operations()
	test_godot_version()
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
func test_basic_assertions() -> void:
	"""Test that assertion helpers work correctly."""
	assert_true(true, "assert_true works with true")
	assert_false(false, "assert_false works with false")
	assert_eq(1, 1, "assert_eq works with equal values")
	assert_not_null("test", "assert_not_null works with non-null value")

func test_math_operations() -> void:
	"""Test basic math operations."""
	assert_eq(2 + 2, 4, "Addition: 2 + 2 = 4")
	assert_eq(5 - 3, 2, "Subtraction: 5 - 3 = 2")
	assert_eq(3 * 4, 12, "Multiplication: 3 * 4 = 12")
	assert_eq(10 / 2, 5, "Division: 10 / 2 = 5")
	assert_true(abs(-5) == 5, "Absolute value: abs(-5) = 5")

func test_string_operations() -> void:
	"""Test string operations."""
	var test_string = "Godot"
	assert_eq(test_string.length(), 5, "String length is correct")
	assert_eq(test_string.to_lower(), "godot", "to_lower() works")
	assert_eq(test_string.to_upper(), "GODOT", "to_upper() works")
	assert_true(test_string.begins_with("God"), "begins_with() works")

func test_godot_version() -> void:
	"""Test that we're running on the expected Godot version."""
	var version_info = Engine.get_version_info()
	assert_not_null(version_info, "Version info is available")
	assert_eq(version_info.major, 4, "Running on Godot 4.x")
	print("  ℹ Running on Godot %d.%d.%d" % [version_info.major, version_info.minor, version_info.patch])
