extends RefCounted
## RunProgressionManager - Manages 3-floor run progression
##
## Handles floor transitions, difficulty scaling, and run win conditions.
## Part of EPIC 7 - Issue #44

class_name RunProgressionManager

## Preload dependencies
const DifficultyConfig = preload("res://scripts/difficulty_config.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")

## Signals (note: RefCounted can't emit signals directly, use callbacks)
## Emitted when floor advances
signal floor_advanced(new_floor: int)

## Emitted when run is won (all floors complete)
signal run_won

## Current floor number (1-indexed, 1-3)
var current_floor: int = 1

## Total floors in a run
const TOTAL_FLOORS: int = 3

## Grid dimensions (configurable)
var grid_width: int = 20
var grid_height: int = 15

## RNG seed for run consistency
var run_seed: int = 0

## Floor complete callback
var on_floor_advanced: Callable = Callable()
var on_run_won: Callable = Callable()

func _init(seed_value: int = 0, width: int = 20, height: int = 15) -> void:
	run_seed = seed_value
	grid_width = width
	grid_height = height
	current_floor = 1

## Set callbacks for events (since RefCounted can't have signals)
func set_callbacks(floor_callback: Callable, win_callback: Callable) -> void:
	on_floor_advanced = floor_callback
	on_run_won = win_callback

## Reset to floor 1
func reset() -> void:
	current_floor = 1

## Get current floor number (1-indexed)
func get_current_floor() -> int:
	return current_floor

## Check if this is the final floor
func is_final_floor() -> bool:
	return current_floor >= TOTAL_FLOORS

## Advance to next floor
## Returns true if advanced, false if already on final floor
func advance_floor() -> bool:
	if current_floor >= TOTAL_FLOORS:
		return false

	current_floor += 1

	# Call callback if set
	if on_floor_advanced.is_valid():
		on_floor_advanced.call(current_floor)

	return true

## Handle floor completion
## Returns "continue" if advancing to next floor, "won" if run complete
func complete_floor() -> String:
	if is_final_floor():
		# Run complete - all floors done!
		if on_run_won.is_valid():
			on_run_won.call()
		return "won"
	else:
		# Advance to next floor
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

	# Generate dungeon with floor-specific difficulty
	# Note: We'll pass wall_density to generator; guard placement happens after
	var result = DungeonGenerator.generate_dungeon(
		grid_width,
		grid_height,
		_get_floor_seed(),
		params.wall_density
	)

	return result

## Get seed for current floor (deterministic based on run_seed and floor)
func _get_floor_seed() -> int:
	# Combine run seed with floor number for deterministic but different floors
	# Simple hash: run_seed * 1000 + floor_number
	return run_seed * 1000 + current_floor

## Get number of guards for current floor
func get_guard_count_for_current_floor() -> int:
	var params = get_current_difficulty()
	return params.guard_count

## Check if run is complete
func is_run_complete() -> bool:
	return current_floor > TOTAL_FLOORS
