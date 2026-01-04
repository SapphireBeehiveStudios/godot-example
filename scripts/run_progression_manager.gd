extends RefCounted
## RunProgressionManager - Manages infinite floor progression
##
## Handles floor transitions with infinite scaling difficulty.
## The run never ends - see how far you can get!

class_name RunProgressionManager

## Preload dependencies
const DifficultyConfig = preload("res://scripts/difficulty_config.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")

## Signals (note: RefCounted can't emit signals directly, use callbacks)
signal floor_advanced(new_floor: int)

## Current floor number (1-indexed, infinite)
var current_floor: int = 1

## Grid dimensions (configurable)
var grid_width: int = 20
var grid_height: int = 15

## RNG seed for run consistency
var run_seed: int = 0

## Floor complete callback
var on_floor_advanced: Callable = Callable()

func _init(seed_value: int = 0, width: int = 20, height: int = 15) -> void:
	run_seed = seed_value
	grid_width = width
	grid_height = height
	current_floor = 1

## Set callbacks for events
func set_callbacks(floor_callback: Callable, _win_callback: Callable = Callable()) -> void:
	on_floor_advanced = floor_callback
	# win_callback ignored - infinite mode never wins

## Reset to floor 1
func reset() -> void:
	current_floor = 1

## Get current floor number (1-indexed)
func get_current_floor() -> int:
	return current_floor

## Infinite mode - never a final floor
func is_final_floor() -> bool:
	return false

## Advance to next floor (always succeeds in infinite mode)
func advance_floor() -> bool:
	current_floor += 1

	# Call callback if set
	if on_floor_advanced.is_valid():
		on_floor_advanced.call(current_floor)

	return true

## Handle floor completion - always continues to next floor
func complete_floor() -> String:
	advance_floor()
	return "continue"

## Get difficulty parameters for current floor
func get_current_difficulty() -> DifficultyConfig.FloorParams:
	return DifficultyConfig.get_floor_params(current_floor)

## Get difficulty parameters for a specific floor
func get_floor_difficulty(floor_number: int) -> DifficultyConfig.FloorParams:
	return DifficultyConfig.get_floor_params(floor_number)

## Generate dungeon for current floor with appropriate difficulty
func generate_dungeon_for_current_floor() -> DungeonGenerator.GenerationResult:
	var params = get_current_difficulty()

	var result = DungeonGenerator.generate_dungeon(
		grid_width,
		grid_height,
		_get_floor_seed(),
		params.wall_density
	)

	return result

## Get seed for current floor (deterministic based on run_seed and floor)
func _get_floor_seed() -> int:
	return run_seed * 1000 + current_floor

## Get number of guards for current floor
func get_guard_count_for_current_floor() -> int:
	var params = get_current_difficulty()
	return params.guard_count

## Infinite mode - run is never complete
func is_run_complete() -> bool:
	return false
