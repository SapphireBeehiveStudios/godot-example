extends Node
## Test Module for ASCII Art Title
##
## This module tests the ascii_title.gd functionality.

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_title_not_empty()
	test_title_is_string()
	test_title_contains_content()
	test_compact_title_not_empty()
	test_compact_title_is_string()
	test_compact_title_smaller_than_full()
	test_title_width_calculation()
	test_title_height_calculation()
	test_project_name_exists()
	test_print_functions_dont_crash()
	test_title_has_border_characters()
	test_title_multiline()
	test_title_lines_consistent_length()
	test_title_content_consistent_spacing()
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

func assert_greater_than(actual, threshold, test_name: String) -> void:
	"""Assert that actual is greater than threshold."""
	if actual > threshold:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected > %s, got %s" % [test_name, threshold, actual])

## Test implementations
func test_title_not_empty() -> void:
	"""Test that the title is not empty."""
	var title = load("res://ascii_title.gd").get_title()
	assert_true(title.length() > 0, "Title is not empty")

func test_title_is_string() -> void:
	"""Test that get_title returns a string."""
	var title = load("res://ascii_title.gd").get_title()
	assert_true(title is String, "Title is a String type")

func test_title_contains_content() -> void:
	"""Test that the title contains expected content."""
	var title = load("res://ascii_title.gd").get_title()
	assert_true(title.contains("SAPPHIRE") or title.contains("Sapphire") or title.contains("Godot"), "Title contains project-related text")

func test_compact_title_not_empty() -> void:
	"""Test that the compact title is not empty."""
	var compact = load("res://ascii_title.gd").get_title_compact()
	assert_true(compact.length() > 0, "Compact title is not empty")

func test_compact_title_is_string() -> void:
	"""Test that get_title_compact returns a string."""
	var compact = load("res://ascii_title.gd").get_title_compact()
	assert_true(compact is String, "Compact title is a String type")

func test_compact_title_smaller_than_full() -> void:
	"""Test that compact title is smaller than full title."""
	var title = load("res://ascii_title.gd").get_title()
	var compact = load("res://ascii_title.gd").get_title_compact()
	assert_true(compact.length() < title.length(), "Compact title is shorter than full title")

func test_title_width_calculation() -> void:
	"""Test that title width is calculated correctly."""
	var width = load("res://ascii_title.gd").get_title_width()
	assert_greater_than(width, 0, "Title width is greater than 0")
	assert_true(width > 50, "Title width is reasonable (> 50 chars)")

func test_title_height_calculation() -> void:
	"""Test that title height is calculated correctly."""
	var height = load("res://ascii_title.gd").get_title_height()
	assert_greater_than(height, 0, "Title height is greater than 0")
	assert_true(height > 5, "Title height is reasonable (> 5 lines)")

func test_project_name_exists() -> void:
	"""Test that project name function returns a value."""
	var name = load("res://ascii_title.gd").get_project_name()
	assert_not_null(name, "Project name is not null")
	assert_true(name.length() > 0, "Project name is not empty")

func test_print_functions_dont_crash() -> void:
	"""Test that print functions execute without crashing."""
	var script = load("res://ascii_title.gd")
	# These should not crash
	script.print_title()
	script.print_title_compact()
	tests_passed += 1
	print("  ✓ Print functions execute without crashing")

func test_title_has_border_characters() -> void:
	"""Test that title uses box-drawing characters for borders."""
	var title = load("res://ascii_title.gd").get_title()
	# Check for common box-drawing characters
	var has_borders = title.contains("╔") or title.contains("║") or title.contains("╗") or title.contains("╚") or title.contains("╝") or title.contains("═")
	assert_true(has_borders, "Title contains box-drawing border characters")

func test_title_multiline() -> void:
	"""Test that title spans multiple lines."""
	var title = load("res://ascii_title.gd").get_title()
	var lines = title.split("\n")
	assert_true(lines.size() > 1, "Title contains multiple lines")

func test_title_lines_consistent_length() -> void:
	"""Test that all non-empty lines have consistent length."""
	var title = load("res://ascii_title.gd").get_title()
	var lines = title.split("\n")
	var expected_length = -1

	for line in lines:
		if line.strip_edges().length() > 0:  # Skip empty lines
			if expected_length == -1:
				expected_length = line.length()
			else:
				assert_eq(line.length(), expected_length, "Line length is consistent (%d chars)" % expected_length)

	assert_true(expected_length > 0, "Found non-empty lines to test")

func test_title_content_consistent_spacing() -> void:
	"""Test that all content lines have consistent spacing between borders."""
	var title = load("res://ascii_title.gd").get_title()
	var lines = title.split("\n")
	var expected_content_length = -1

	for line in lines:
		if line.contains("║"):  # Lines with border characters
			var first_border = line.find("║")
			var last_border = line.rfind("║")
			if first_border != last_border:  # Has both left and right borders
				var content_length = last_border - first_border - 1
				if expected_content_length == -1:
					expected_content_length = content_length
				else:
					assert_eq(content_length, expected_content_length, "Content between borders is consistent (%d chars)" % expected_content_length)

	assert_true(expected_content_length > 0, "Found bordered lines to test")
