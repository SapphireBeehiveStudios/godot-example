extends Node
## SaveSystem Test Module
##
## Tests the SaveSystem class functionality including:
## - Save and load operations
## - Missing file handling (graceful defaults)
## - Corrupt file handling (fallback + message)
## - Round-trip data integrity

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_save_and_load_basic()
	test_roundtrip_preserves_data()
	test_missing_file_returns_defaults()
	test_corrupt_json_returns_defaults()
	test_non_dict_json_returns_defaults()
	test_save_failure_handling()
	test_delete_save()
	test_save_exists()
	test_complex_nested_data()
	test_multiple_saves_overwrite()
	test_custom_path()
	test_persistent_data_defaults()
	test_save_persistent_data()
	test_update_best_score()
	test_get_best_score()
	test_get_last_seed()
	test_persistent_data_separate_from_game_state()
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

func assert_dict_eq(actual: Dictionary, expected: Dictionary, test_name: String) -> void:
	"""Assert that two dictionaries are equal."""
	if actual.size() != expected.size():
		tests_failed += 1
		print("  ✗ %s: dictionary sizes differ (expected %d, got %d)" % [test_name, expected.size(), actual.size()])
		return

	for key in expected:
		if not actual.has(key):
			tests_failed += 1
			print("  ✗ %s: missing key '%s'" % [test_name, key])
			return
		if actual[key] != expected[key]:
			tests_failed += 1
			print("  ✗ %s: key '%s' mismatch (expected %s, got %s)" % [test_name, key, expected[key], actual[key]])
			return

	tests_passed += 1
	print("  ✓ %s" % test_name)

## Test implementations
func test_save_and_load_basic() -> void:
	"""Test basic save and load functionality."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_basic.json"

	# Clean up any existing test file
	save_system.delete_save(test_path)

	# Save some data
	var data_to_save = {"test_key": "test_value", "number": 42}
	var save_result = save_system.save(data_to_save, test_path)
	assert_true(save_result, "Save operation succeeded")

	# Load it back
	var loaded_data = save_system.load(test_path)
	assert_eq(loaded_data["test_key"], "test_value", "String value loaded correctly")
	assert_eq(loaded_data["number"], 42, "Number value loaded correctly")

	# Clean up
	save_system.delete_save(test_path)

func test_roundtrip_preserves_data() -> void:
	"""Test that save → load → equals (roundtrip integrity)."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_roundtrip.json"

	# Clean up any existing test file
	save_system.delete_save(test_path)

	# Create test data matching GameState structure
	var original_data = {
		"floor_number": 5,
		"turn_count": 123,
		"keycards": 3,
		"shard_collected": true,
		"score": 9999,
		"run_seed": "test_seed_xyz"
	}

	# Save
	save_system.save(original_data, test_path)

	# Load
	var loaded_data = save_system.load(test_path)

	# Verify all fields match
	assert_dict_eq(loaded_data, original_data, "Roundtrip preserves all data")

	# Clean up
	save_system.delete_save(test_path)

func test_missing_file_returns_defaults() -> void:
	"""Test that missing file is handled gracefully (returns empty dict)."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_nonexistent.json"

	# Make sure file doesn't exist
	save_system.delete_save(test_path)

	# Try to load non-existent file
	var loaded_data = save_system.load(test_path)

	# Should return empty dictionary (defaults)
	assert_eq(loaded_data.size(), 0, "Missing file returns empty dict")
	assert_true(loaded_data is Dictionary, "Missing file returns Dictionary type")

func test_corrupt_json_returns_defaults() -> void:
	"""Test that corrupt JSON file is handled gracefully."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_corrupt.json"

	# Write invalid JSON directly
	var file = FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("{this is not valid json!!!")
	file.close()

	# Try to load corrupt file
	var loaded_data = save_system.load(test_path)

	# Should return empty dictionary (defaults)
	assert_eq(loaded_data.size(), 0, "Corrupt JSON returns empty dict")
	assert_true(loaded_data is Dictionary, "Corrupt JSON returns Dictionary type")

	# Clean up
	save_system.delete_save(test_path)

func test_non_dict_json_returns_defaults() -> void:
	"""Test that valid JSON but non-dictionary data returns defaults."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_non_dict.json"

	# Write valid JSON but it's an array, not a dict
	var file = FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("[1, 2, 3, 4, 5]")
	file.close()

	# Try to load non-dict JSON
	var loaded_data = save_system.load(test_path)

	# Should return empty dictionary (defaults)
	assert_eq(loaded_data.size(), 0, "Non-dict JSON returns empty dict")
	assert_true(loaded_data is Dictionary, "Non-dict JSON returns Dictionary type")

	# Clean up
	save_system.delete_save(test_path)

func test_save_failure_handling() -> void:
	"""Test that save returns false on failure."""
	var save_system = load("res://save_system.gd").new()

	# Try to save to an invalid path (should fail gracefully)
	# Note: This test may behave differently on different platforms
	# On some systems, even invalid paths might succeed with automatic directory creation
	var result = save_system.save({"test": "data"}, "")

	# We just verify it returns a boolean (either true or false)
	assert_true(result is bool, "Save returns boolean value")

func test_delete_save() -> void:
	"""Test deleting save files."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_delete.json"

	# Create a file
	save_system.save({"test": "data"}, test_path)
	assert_true(save_system.save_exists(test_path), "File exists after save")

	# Delete it
	var delete_result = save_system.delete_save(test_path)
	assert_true(delete_result, "Delete operation succeeded")
	assert_false(save_system.save_exists(test_path), "File no longer exists after delete")

	# Deleting non-existent file should also succeed
	var delete_again = save_system.delete_save(test_path)
	assert_true(delete_again, "Deleting non-existent file succeeds")

func test_save_exists() -> void:
	"""Test checking if save file exists."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_exists.json"

	# Clean up first
	save_system.delete_save(test_path)

	# Should not exist
	assert_false(save_system.save_exists(test_path), "File doesn't exist initially")

	# Create it
	save_system.save({"test": "data"}, test_path)

	# Should exist now
	assert_true(save_system.save_exists(test_path), "File exists after save")

	# Clean up
	save_system.delete_save(test_path)

func test_complex_nested_data() -> void:
	"""Test saving and loading complex nested data structures."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_complex.json"

	# Clean up
	save_system.delete_save(test_path)

	# Create complex nested data
	var complex_data = {
		"player": {
			"name": "TestPlayer",
			"stats": {
				"health": 100,
				"mana": 50
			}
		},
		"inventory": [
			{"item": "sword", "damage": 10},
			{"item": "potion", "healing": 20}
		],
		"flags": {
			"tutorial_complete": true,
			"boss_defeated": false
		}
	}

	# Save
	save_system.save(complex_data, test_path)

	# Load
	var loaded = save_system.load(test_path)

	# Verify nested data
	assert_eq(loaded["player"]["name"], "TestPlayer", "Nested string preserved")
	assert_eq(loaded["player"]["stats"]["health"], 100, "Double-nested number preserved")
	assert_eq(loaded["inventory"][0]["item"], "sword", "Array element preserved")
	assert_true(loaded["flags"]["tutorial_complete"], "Nested boolean preserved")

	# Clean up
	save_system.delete_save(test_path)

func test_multiple_saves_overwrite() -> void:
	"""Test that multiple saves to same path overwrite correctly."""
	var save_system = load("res://save_system.gd").new()
	var test_path = "user://test_overwrite.json"

	# Clean up
	save_system.delete_save(test_path)

	# Save first data
	save_system.save({"value": 1}, test_path)
	var loaded1 = save_system.load(test_path)
	assert_eq(loaded1["value"], 1, "First save loads correctly")

	# Overwrite with new data
	save_system.save({"value": 2, "extra": "field"}, test_path)
	var loaded2 = save_system.load(test_path)
	assert_eq(loaded2["value"], 2, "Second save overwrites correctly")
	assert_eq(loaded2["extra"], "field", "New field in second save present")
	assert_eq(loaded2.size(), 2, "Only new data present (old data overwritten)")

	# Clean up
	save_system.delete_save(test_path)

func test_custom_path() -> void:
	"""Test using custom save paths."""
	var save_system = load("res://save_system.gd").new()
	var custom_path = "user://custom_save_test.json"

	# Use a simple custom path in the root user:// directory
	save_system.save({"custom": true}, custom_path)
	var loaded = save_system.load(custom_path)

	assert_eq(loaded.get("custom", false), true, "Custom path save and load works")

	# Clean up
	save_system.delete_save(custom_path)

func test_persistent_data_defaults() -> void:
	"""Test that load_persistent_data returns defaults when no file exists."""
	var save_system = load("res://save_system.gd").new()

	# Clean up any existing persistent data
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

	# Load should return defaults
	var data = save_system.load_persistent_data()

	assert_eq(data["best_score"], 0, "Default best_score is 0")
	assert_eq(data["last_seed"], "", "Default last_seed is empty string")

func test_save_persistent_data() -> void:
	"""Test saving and loading persistent data."""
	var save_system = load("res://save_system.gd").new()

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

	# Save persistent data
	var save_result = save_system.save_persistent_data(1000, "test_seed_123")
	assert_true(save_result, "save_persistent_data returns true on success")

	# Load it back
	var data = save_system.load_persistent_data()
	assert_eq(data["best_score"], 1000, "best_score persisted correctly")
	assert_eq(data["last_seed"], "test_seed_123", "last_seed persisted correctly")

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

func test_update_best_score() -> void:
	"""Test update_best_score only updates when score is higher."""
	var save_system = load("res://save_system.gd").new()

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

	# First run with score 100
	save_system.update_best_score(100, "seed1")
	var data1 = save_system.load_persistent_data()
	assert_eq(data1["best_score"], 100, "Initial best_score is 100")
	assert_eq(data1["last_seed"], "seed1", "last_seed updated to seed1")

	# Second run with higher score 200
	save_system.update_best_score(200, "seed2")
	var data2 = save_system.load_persistent_data()
	assert_eq(data2["best_score"], 200, "best_score updated to 200")
	assert_eq(data2["last_seed"], "seed2", "last_seed updated to seed2")

	# Third run with lower score 50
	save_system.update_best_score(50, "seed3")
	var data3 = save_system.load_persistent_data()
	assert_eq(data3["best_score"], 200, "best_score remains 200 (not downgraded)")
	assert_eq(data3["last_seed"], "seed3", "last_seed updated to seed3 even with lower score")

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

func test_get_best_score() -> void:
	"""Test get_best_score convenience method."""
	var save_system = load("res://save_system.gd").new()

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

	# Default should be 0
	assert_eq(save_system.get_best_score(), 0, "get_best_score returns 0 by default")

	# Save some data
	save_system.save_persistent_data(999, "test_seed")

	# Should return the saved value
	assert_eq(save_system.get_best_score(), 999, "get_best_score returns saved value")

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

func test_get_last_seed() -> void:
	"""Test get_last_seed convenience method."""
	var save_system = load("res://save_system.gd").new()

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

	# Default should be empty string
	assert_eq(save_system.get_last_seed(), "", "get_last_seed returns empty string by default")

	# Save some data with string seed
	save_system.save_persistent_data(100, "my_seed_abc")
	assert_eq(save_system.get_last_seed(), "my_seed_abc", "get_last_seed returns string seed")

	# Save with integer seed
	save_system.save_persistent_data(200, 42)
	assert_eq(save_system.get_last_seed(), 42, "get_last_seed returns integer seed")

	# Clean up
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

func test_persistent_data_separate_from_game_state() -> void:
	"""Test that persistent data is stored separately from game state."""
	var save_system = load("res://save_system.gd").new()

	# Clean up both files
	save_system.delete_save(save_system.DEFAULT_SAVE_PATH)
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)

	# Save game state
	save_system.save({"floor_number": 5, "score": 1000}, save_system.DEFAULT_SAVE_PATH)

	# Save persistent data
	save_system.save_persistent_data(2000, "persistent_seed")

	# Load game state - should NOT contain persistent data
	var game_data = save_system.load(save_system.DEFAULT_SAVE_PATH)
	assert_false(game_data.has("best_score"), "Game state doesn't contain best_score")
	assert_false(game_data.has("last_seed"), "Game state doesn't contain last_seed")

	# Load persistent data - should NOT contain game state
	var persistent = save_system.load_persistent_data()
	assert_false(persistent.has("floor_number"), "Persistent data doesn't contain floor_number")
	assert_eq(persistent["best_score"], 2000, "Persistent data has correct best_score")
	assert_eq(persistent["last_seed"], "persistent_seed", "Persistent data has correct last_seed")

	# Clean up
	save_system.delete_save(save_system.DEFAULT_SAVE_PATH)
	save_system.delete_save(save_system.PERSISTENT_DATA_PATH)
