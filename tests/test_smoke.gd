extends Node
## Smoke Test Module
##
## Basic smoke test to verify the test framework is working.

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_smoke()
	return {"passed": tests_passed, "failed": tests_failed}

## Assertion helper methods
func assert_true(condition: bool, test_name: String) -> void:
	"""Assert that condition is true."""
	if condition:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected true, got false" % test_name)

## Test implementation
func test_smoke() -> void:
	"""Basic smoke test - verifies test framework is functional."""
	assert_true(true, "Smoke test passes")
