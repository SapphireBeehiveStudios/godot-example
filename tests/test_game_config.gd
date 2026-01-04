extends Node
## Tests for GameConfig resource
##
## Validates:
## - Default values match pitch expectations
## - Resource can be loaded from file
## - Singleton pattern works correctly
## - All configuration values are within valid ranges

# Preload the GameConfig class
const GameConfig = preload("res://resources/game_config.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	print("Running GameConfig Tests...")

	# Test default values
	test_default_grid_size()
	test_default_wall_density()
	test_default_progression()
	test_default_guard_ai()
	test_default_scoring()
	test_default_generation()

	# Test resource loading
	test_resource_loading()
	test_singleton_pattern()

	# Test value ranges
	test_wall_density_range()
	test_positive_values()

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

func assert_range(value: float, min_val: float, max_val: float, test_name: String) -> void:
	var in_range = value >= min_val and value <= max_val
	if in_range:
		tests_passed += 1
		print("  ✓ %s (value: %s)" % [test_name, value])
	else:
		tests_failed += 1
		print("  ✗ %s: expected value between %s and %s, got %s" % [test_name, min_val, max_val, value])

## Test default grid dimensions match pitch (24x14)
func test_default_grid_size() -> void:
	var config = GameConfig.new()
	assert_eq(config.grid_width, 24, "Default grid width is 24")
	assert_eq(config.grid_height, 14, "Default grid height is 14")

## Test default wall density is reasonable
func test_default_wall_density() -> void:
	var config = GameConfig.new()
	assert_eq(config.wall_density, 0.3, "Default wall density is 0.3")

## Test default progression values match pitch (3 floors)
func test_default_progression() -> void:
	var config = GameConfig.new()
	assert_eq(config.total_floors, 3, "Default total floors is 3")
	assert_eq(config.starting_floor, 0, "Default starting floor is 0")

## Test default guard AI parameters
func test_default_guard_ai() -> void:
	var config = GameConfig.new()
	assert_eq(config.max_chase_turns, 5, "Default max chase turns is 5")
	assert_eq(config.los_range, 8, "Default line of sight range is 8")

## Test default scoring parameters
func test_default_scoring() -> void:
	var config = GameConfig.new()
	assert_eq(config.shard_points, 100, "Default shard points is 100")
	assert_eq(config.floor_bonus, 50, "Default floor bonus is 50")
	assert_eq(config.turn_penalty, 1, "Default turn penalty is 1")

## Test default generation parameters
func test_default_generation() -> void:
	var config = GameConfig.new()
	assert_eq(config.max_generation_attempts, 100, "Default max generation attempts is 100")

## Test that resource can be loaded from file
func test_resource_loading() -> void:
	var config_path = "res://resources/game_config.tres"
	var resource_exists = ResourceLoader.exists(config_path)
	assert_true(resource_exists, "game_config.tres resource file exists")

	if resource_exists:
		var config = load(config_path) as GameConfig
		assert_true(config != null, "Config resource loads successfully")
		if config != null:
			# Verify loaded values match defaults
			assert_eq(config.grid_width, 24, "Loaded grid width is 24")
			assert_eq(config.grid_height, 14, "Loaded grid height is 14")
			assert_eq(config.total_floors, 3, "Loaded total floors is 3")

## Test load_config function
func test_singleton_pattern() -> void:
	var config = GameConfig.load_config()
	assert_true(config != null, "load_config returns valid instance")

	if config != null:
		assert_true(config is GameConfig, "Loaded config is GameConfig type")
		assert_eq(config.grid_width, 24, "Loaded config has correct grid_width")

## Test wall density is within valid range
func test_wall_density_range() -> void:
	var config = GameConfig.new()
	assert_range(config.wall_density, 0.0, 1.0, "Wall density is between 0.0 and 1.0")

## Test that all numeric values are positive
func test_positive_values() -> void:
	var config = GameConfig.new()
	assert_true(config.grid_width > 0, "Grid width is positive")
	assert_true(config.grid_height > 0, "Grid height is positive")
	assert_true(config.total_floors > 0, "Total floors is positive")
	assert_true(config.starting_floor >= 0, "Starting floor is non-negative")
	assert_true(config.max_chase_turns > 0, "Max chase turns is positive")
	assert_true(config.los_range > 0, "Line of sight range is positive")
	assert_true(config.shard_points > 0, "Shard points is positive")
	assert_true(config.floor_bonus > 0, "Floor bonus is positive")
	assert_true(config.turn_penalty >= 0, "Turn penalty is non-negative")
	assert_true(config.max_generation_attempts > 0, "Max generation attempts is positive")
