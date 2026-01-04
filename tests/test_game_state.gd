extends Node
## GameState Test Module
##
## Tests the GameState class functionality including:
## - Default values
## - Mutations (add keycard, collect shard, etc.)
## - Serialization/deserialization

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_initial_state()
	test_constructor_with_seed()
	test_add_keycard_single()
	test_add_keycard_multiple()
	test_collect_shard()
	test_increment_turn()
	test_advance_floor()
	test_add_score()
	test_reset()
	test_to_dict()
	test_from_dict()
	test_serialization_round_trip()
	test_getter_methods()
	test_seed_as_string()
	test_seed_as_int()
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

## Test implementations
func test_initial_state() -> void:
	"""Test that GameState starts with correct default values."""
	var state = load("res://game_state.gd").new()
	assert_eq(state.floor_number, 0, "Floor number defaults to 0")
	assert_eq(state.turn_count, 0, "Turn count defaults to 0")
	assert_eq(state.keycards, 0, "Keycards default to 0")
	assert_false(state.shard_collected, "Shard not collected initially")
	assert_eq(state.score, 0, "Score defaults to 0")
	assert_eq(state.run_seed, 0, "Run seed defaults to 0")

func test_constructor_with_seed() -> void:
	"""Test that GameState can be initialized with a seed."""
	var state = load("res://game_state.gd").new(12345)
	assert_eq(state.run_seed, 12345, "Seed set correctly in constructor")

func test_add_keycard_single() -> void:
	"""Test adding a single keycard."""
	var state = load("res://game_state.gd").new()
	state.add_keycard()
	assert_eq(state.keycards, 1, "Single keycard added")

func test_add_keycard_multiple() -> void:
	"""Test adding multiple keycards at once."""
	var state = load("res://game_state.gd").new()
	state.add_keycard(3)
	assert_eq(state.keycards, 3, "Multiple keycards added")
	state.add_keycard(2)
	assert_eq(state.keycards, 5, "Keycards accumulate correctly")

func test_collect_shard() -> void:
	"""Test collecting the shard."""
	var state = load("res://game_state.gd").new()
	assert_false(state.shard_collected, "Shard not collected initially")
	state.collect_shard()
	assert_true(state.shard_collected, "Shard collected after collect_shard()")

func test_increment_turn() -> void:
	"""Test incrementing turn count."""
	var state = load("res://game_state.gd").new()
	assert_eq(state.turn_count, 0, "Turn count starts at 0")
	state.increment_turn()
	assert_eq(state.turn_count, 1, "Turn count incremented to 1")
	state.increment_turn()
	state.increment_turn()
	assert_eq(state.turn_count, 3, "Turn count incremented to 3")

func test_advance_floor() -> void:
	"""Test advancing to next floor."""
	var state = load("res://game_state.gd").new()
	assert_eq(state.floor_number, 0, "Floor starts at 0")
	state.advance_floor()
	assert_eq(state.floor_number, 1, "Floor advanced to 1")
	state.advance_floor()
	assert_eq(state.floor_number, 2, "Floor advanced to 2")

func test_add_score() -> void:
	"""Test adding score."""
	var state = load("res://game_state.gd").new()
	assert_eq(state.score, 0, "Score starts at 0")
	state.add_score(100)
	assert_eq(state.score, 100, "Score increased by 100")
	state.add_score(50)
	assert_eq(state.score, 150, "Score increased by 50 more")

func test_reset() -> void:
	"""Test that reset() clears all state."""
	var state = load("res://game_state.gd").new(9999)
	state.floor_number = 5
	state.turn_count = 42
	state.keycards = 3
	state.shard_collected = true
	state.score = 1000

	state.reset()

	assert_eq(state.floor_number, 0, "Floor reset to 0")
	assert_eq(state.turn_count, 0, "Turn count reset to 0")
	assert_eq(state.keycards, 0, "Keycards reset to 0")
	assert_false(state.shard_collected, "Shard reset to false")
	assert_eq(state.score, 0, "Score reset to 0")
	assert_eq(state.run_seed, 0, "Seed reset to 0")

func test_to_dict() -> void:
	"""Test converting state to dictionary."""
	var state = load("res://game_state.gd").new(777)
	state.floor_number = 3
	state.turn_count = 25
	state.keycards = 2
	state.shard_collected = true
	state.score = 500

	var dict = state.to_dict()

	assert_eq(dict["floor_number"], 3, "Floor number in dict")
	assert_eq(dict["turn_count"], 25, "Turn count in dict")
	assert_eq(dict["keycards"], 2, "Keycards in dict")
	assert_true(dict["shard_collected"], "Shard collected in dict")
	assert_eq(dict["score"], 500, "Score in dict")
	assert_eq(dict["run_seed"], 777, "Run seed in dict")

func test_from_dict() -> void:
	"""Test loading state from dictionary."""
	var state = load("res://game_state.gd").new()

	var data = {
		"floor_number": 7,
		"turn_count": 99,
		"keycards": 5,
		"shard_collected": true,
		"score": 2500,
		"run_seed": 12345
	}

	state.from_dict(data)

	assert_eq(state.floor_number, 7, "Floor number loaded from dict")
	assert_eq(state.turn_count, 99, "Turn count loaded from dict")
	assert_eq(state.keycards, 5, "Keycards loaded from dict")
	assert_true(state.shard_collected, "Shard collected loaded from dict")
	assert_eq(state.score, 2500, "Score loaded from dict")
	assert_eq(state.run_seed, 12345, "Run seed loaded from dict")

func test_serialization_round_trip() -> void:
	"""Test that serialization and deserialization preserves state."""
	var state1 = load("res://game_state.gd").new("test_seed_123")
	state1.floor_number = 4
	state1.turn_count = 66
	state1.keycards = 3
	state1.shard_collected = true
	state1.score = 1337

	var dict = state1.to_dict()

	var state2 = load("res://game_state.gd").new()
	state2.from_dict(dict)

	assert_eq(state2.floor_number, 4, "Floor number preserved")
	assert_eq(state2.turn_count, 66, "Turn count preserved")
	assert_eq(state2.keycards, 3, "Keycards preserved")
	assert_true(state2.shard_collected, "Shard collected preserved")
	assert_eq(state2.score, 1337, "Score preserved")
	assert_eq(state2.run_seed, "test_seed_123", "Run seed preserved")

func test_getter_methods() -> void:
	"""Test all getter methods return correct values."""
	var state = load("res://game_state.gd").new(555)
	state.floor_number = 2
	state.turn_count = 10
	state.keycards = 1
	state.shard_collected = true
	state.score = 250

	assert_eq(state.get_floor_number(), 2, "get_floor_number() returns correct value")
	assert_eq(state.get_turn_count(), 10, "get_turn_count() returns correct value")
	assert_eq(state.get_keycards(), 1, "get_keycards() returns correct value")
	assert_true(state.has_shard(), "has_shard() returns true")
	assert_eq(state.get_score(), 250, "get_score() returns correct value")
	assert_eq(state.get_run_seed(), 555, "get_run_seed() returns correct value")

func test_seed_as_string() -> void:
	"""Test that seed can be a string."""
	var state = load("res://game_state.gd").new("my_seed_abc")
	assert_eq(state.run_seed, "my_seed_abc", "String seed stored correctly")

func test_seed_as_int() -> void:
	"""Test that seed can be an integer."""
	var state = load("res://game_state.gd").new(42)
	assert_eq(state.run_seed, 42, "Integer seed stored correctly")
