extends SceneTree
## Test Runner for Godot Example Project
##
## This script runs all test modules and reports results.
## Usage: godot --headless -s res://tests/test_runner.gd

func _init() -> void:
	print("=" .repeat(60))
	print("Running Test Suite - Godot Example Project")
	print("=" .repeat(60))

	var total_passed := 0
	var total_failed := 0

	# Auto-discover test modules
	# Test files must follow the naming convention: test_*.gd
	# This prevents merge conflicts when multiple PRs add new tests
	var test_modules = _get_test_modules()

	# Run each test module
	for module_path in test_modules:
		if FileAccess.file_exists(module_path):
			print("\n[%s]" % module_path.get_file())
			var module = load(module_path).new()
			var results = module.run_all()
			total_passed += results.passed
			total_failed += results.failed
			module.free()
		else:
			print("\n[%s] - SKIPPED (file not found)" % module_path.get_file())

	# Print summary
	print("\n" + "=" .repeat(60))
	if total_failed == 0:
		print("✓ All tests passed! (%d tests)" % total_passed)
	else:
		print("✗ Some tests failed: %d passed, %d failed" % [total_passed, total_failed])
	print("=" .repeat(60))

	# Exit with appropriate code
	quit(0 if total_failed == 0 else 1)


## Auto-discover test files in the tests directory
## Returns an array of test module paths matching the pattern test_*.gd
func _get_test_modules() -> Array:
	var test_modules = []
	var dir = DirAccess.open("res://tests/")

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			# Include files that start with "test_" and end with ".gd"
			# Exclude test_runner.gd itself
			if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd":
				test_modules.append("res://tests/" + file_name)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("Failed to open tests directory for test discovery")

	# Sort alphabetically for deterministic ordering
	test_modules.sort()

	return test_modules
