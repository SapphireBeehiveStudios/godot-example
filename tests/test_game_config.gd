extends Node

## Test suite for GameConfig resource
##
## Tests default values, serialization, and system integration

var tests_passed := 0
var tests_failed := 0


func run_all() -> Dictionary:
	# Default value tests
	test_default_grid_dimensions()
	test_default_floor_count()
	test_default_guard_ai_settings()
	test_default_gameplay_balance()
	test_default_rendering_colors()

	# Serialization tests
	test_to_dict_serialization()
	test_from_dict_deserialization()
	test_serialization_round_trip()

	# Modification tests
	test_can_modify_grid_dimensions()
	test_can_modify_guard_settings()
	test_can_modify_balance_values()
	test_can_modify_colors()

	# Resource loading test
	test_load_default_tres_file()

	# Boundary/edge case tests
	test_handles_partial_dict()
	test_handles_empty_dict()

	return {"passed": tests_passed, "failed": tests_failed}


# ===== ASSERTION HELPERS =====

func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])


func assert_not_eq(actual, unexpected, test_name: String) -> void:
	if actual != unexpected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: value should not equal %s" % [test_name, unexpected])


func assert_true(condition: bool, test_name: String) -> void:
	assert_eq(condition, true, test_name)


func assert_false(condition: bool, test_name: String) -> void:
	assert_eq(condition, false, test_name)


# ===== DEFAULT VALUE TESTS =====

func test_default_grid_dimensions() -> void:
	var config = load("res://resources/game_config.gd").new()
	assert_eq(config.grid_width, 20, "Default grid width is 20")
	assert_eq(config.grid_height, 12, "Default grid height is 12")


func test_default_floor_count() -> void:
	var config = load("res://resources/game_config.gd").new()
	assert_eq(config.floor_count, 3, "Default floor count is 3")


func test_default_guard_ai_settings() -> void:
	var config = load("res://resources/game_config.gd").new()
	assert_eq(config.guard_max_chase_turns, 5, "Default max chase turns is 5")
	assert_eq(config.guard_los_range, 8, "Default LoS range is 8")
	assert_eq(config.guards_per_floor_base, 2, "Default base guards per floor is 2")


func test_default_gameplay_balance() -> void:
	var config = load("res://resources/game_config.gd").new()
	assert_eq(config.keycards_required_to_win, 1, "Default keycards required is 1")
	assert_eq(config.shard_score_bonus, 500, "Default shard bonus is 500")
	assert_eq(config.floor_completion_bonus, 100, "Default floor bonus is 100")
	assert_eq(config.turn_penalty, 1, "Default turn penalty is 1")


func test_default_rendering_colors() -> void:
	var config = load("res://resources/game_config.gd").new()
	assert_eq(config.color_player, "aqua", "Default player color is aqua")
	assert_eq(config.color_guard, "red", "Default guard color is red")
	assert_eq(config.color_wall, "gray", "Default wall color is gray")
	assert_eq(config.color_floor, "white", "Default floor color is white")
	assert_eq(config.color_door_open, "green", "Default open door color is green")
	assert_eq(config.color_door_closed, "yellow", "Default closed door color is yellow")
	assert_eq(config.color_keycard, "blue", "Default keycard color is blue")
	assert_eq(config.color_shard, "gold", "Default shard color is gold")
	assert_eq(config.color_exit, "lime", "Default exit color is lime")


# ===== SERIALIZATION TESTS =====

func test_to_dict_serialization() -> void:
	var config = load("res://resources/game_config.gd").new()
	config.grid_width = 24
	config.guard_max_chase_turns = 7
	config.color_player = "cyan"

	var dict = config.to_dict()

	assert_eq(dict["grid_width"], 24, "to_dict() serializes grid_width")
	assert_eq(dict["guard_max_chase_turns"], 7, "to_dict() serializes guard_max_chase_turns")
	assert_eq(dict["color_player"], "cyan", "to_dict() serializes color_player")
	assert_true(dict.has("grid_height"), "to_dict() includes all properties")
	assert_true(dict.has("color_exit"), "to_dict() includes color_exit")


func test_from_dict_deserialization() -> void:
	var data = {
		"grid_width": 16,
		"grid_height": 10,
		"guard_los_range": 6,
		"color_guard": "orange",
	}

	var config = load("res://resources/game_config.gd").new()
	config.from_dict(data)

	assert_eq(config.grid_width, 16, "from_dict() deserializes grid_width")
	assert_eq(config.grid_height, 10, "from_dict() deserializes grid_height")
	assert_eq(config.guard_los_range, 6, "from_dict() deserializes guard_los_range")
	assert_eq(config.color_guard, "orange", "from_dict() deserializes color_guard")


func test_serialization_round_trip() -> void:
	var original = load("res://resources/game_config.gd").new()
	original.grid_width = 30
	original.floor_count = 5
	original.shard_score_bonus = 1000
	original.color_player = "magenta"

	var dict = original.to_dict()
	var restored = load("res://resources/game_config.gd").new()
	restored.from_dict(dict)

	assert_eq(restored.grid_width, 30, "Round trip preserves grid_width")
	assert_eq(restored.floor_count, 5, "Round trip preserves floor_count")
	assert_eq(restored.shard_score_bonus, 1000, "Round trip preserves shard_score_bonus")
	assert_eq(restored.color_player, "magenta", "Round trip preserves color_player")


# ===== MODIFICATION TESTS =====

func test_can_modify_grid_dimensions() -> void:
	var config = load("res://resources/game_config.gd").new()
	var original_width = config.grid_width

	config.grid_width = 32
	config.grid_height = 16

	assert_eq(config.grid_width, 32, "Can modify grid_width")
	assert_eq(config.grid_height, 16, "Can modify grid_height")
	assert_not_eq(config.grid_width, original_width, "Modified value differs from default")


func test_can_modify_guard_settings() -> void:
	var config = load("res://resources/game_config.gd").new()

	config.guard_max_chase_turns = 10
	config.guard_los_range = 12
	config.guards_per_floor_base = 3

	assert_eq(config.guard_max_chase_turns, 10, "Can modify guard_max_chase_turns")
	assert_eq(config.guard_los_range, 12, "Can modify guard_los_range")
	assert_eq(config.guards_per_floor_base, 3, "Can modify guards_per_floor_base")


func test_can_modify_balance_values() -> void:
	var config = load("res://resources/game_config.gd").new()

	config.keycards_required_to_win = 3
	config.shard_score_bonus = 2000
	config.floor_completion_bonus = 250
	config.turn_penalty = 5

	assert_eq(config.keycards_required_to_win, 3, "Can modify keycards_required_to_win")
	assert_eq(config.shard_score_bonus, 2000, "Can modify shard_score_bonus")
	assert_eq(config.floor_completion_bonus, 250, "Can modify floor_completion_bonus")
	assert_eq(config.turn_penalty, 5, "Can modify turn_penalty")


func test_can_modify_colors() -> void:
	var config = load("res://resources/game_config.gd").new()

	config.color_player = "purple"
	config.color_guard = "crimson"
	config.color_exit = "green"

	assert_eq(config.color_player, "purple", "Can modify color_player")
	assert_eq(config.color_guard, "crimson", "Can modify color_guard")
	assert_eq(config.color_exit, "green", "Can modify color_exit")


# ===== RESOURCE LOADING TEST =====

func test_load_default_tres_file() -> void:
	var config = load("res://resources/game_config.tres")

	assert_true(config != null, "Can load default game_config.tres")
	assert_eq(config.grid_width, 20, "Loaded config has correct grid_width")
	assert_eq(config.floor_count, 3, "Loaded config has correct floor_count")
	assert_eq(config.guard_max_chase_turns, 5, "Loaded config has correct guard_max_chase_turns")
	assert_eq(config.color_player, "aqua", "Loaded config has correct color_player")


# ===== EDGE CASE TESTS =====

func test_handles_partial_dict() -> void:
	var data = {
		"grid_width": 25,
		"color_player": "teal",
	}

	var config = load("res://resources/game_config.gd").new()
	config.from_dict(data)

	assert_eq(config.grid_width, 25, "Partial dict sets provided values")
	assert_eq(config.color_player, "teal", "Partial dict sets color values")
	assert_eq(config.grid_height, 12, "Partial dict keeps defaults for missing values")
	assert_eq(config.guard_max_chase_turns, 5, "Partial dict keeps guard defaults")


func test_handles_empty_dict() -> void:
	var data = {}
	var config = load("res://resources/game_config.gd").new()
	config.from_dict(data)

	assert_eq(config.grid_width, 20, "Empty dict uses default grid_width")
	assert_eq(config.grid_height, 12, "Empty dict uses default grid_height")
	assert_eq(config.floor_count, 3, "Empty dict uses default floor_count")
	assert_eq(config.color_player, "aqua", "Empty dict uses default color_player")
