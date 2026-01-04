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

	# List of test modules to run
	var test_modules = [
		"res://tests/test_smoke.gd",
		"res://tests/test_example.gd",
		"res://tests/test_ascii_title.gd",
		"res://tests/test_game_state.gd",
		"res://tests/test_save_system.gd",
		"res://tests/test_turn_system.gd",
		"res://tests/test_pathfinding.gd",
		"res://tests/test_grid_map.gd",
		"res://tests/test_guard.gd",
		"res://tests/test_guard_system.gd",
		"res://tests/test_game_manager.gd",
		"res://tests/test_deterministic_rng.gd",
		"res://tests/test_dungeon_generator.gd",
		"res://tests/test_shard_exit.gd",
		"res://tests/test_renderer.gd",
		"res://tests/test_end_screen.gd",
	]

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
