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

## Initialize the run progression manager
##
## Parameters:
##   seed_value: The seed for deterministic run generation
##   width: Grid width for dungeons (default 20)
##   height: Grid height for dungeons (default 15)
func _init(seed_value: int = 0, width: int = 20, height: int = 15) -> void:
	run_seed = seed_value
	grid_width = width
	grid_height = height
	current_floor = 1

## Set callbacks for events (since RefCounted can't have signals)
##
## Parameters:
##   floor_callback: Called when floor advances, receives new floor number
##   win_callback: Called when run is won (all floors complete)
func set_callbacks(floor_callback: Callable, win_callback: Callable) -> void:
	on_floor_advanced = floor_callback
	on_run_won = win_callback

## Reset to floor 1
func reset() -> void:
	current_floor = 1

## Get current floor number (1-indexed)
##
## Returns:
##   int: Current floor number (1-3)
func get_current_floor() -> int:
	return current_floor

## Check if this is the final floor
##
## Returns:
##   bool: true if on floor 3 or higher, false otherwise
func is_final_floor() -> bool:
	return current_floor >= TOTAL_FLOORS

## Advance to next floor
##
## Increments the floor counter and calls the floor_advanced callback.
##
## Returns:
##   bool: true if advanced successfully, false if already on final floor
func advance_floor() -> bool:
	if current_floor >= TOTAL_FLOORS:
		return false

	current_floor += 1

	# Call callback if set
	if on_floor_advanced.is_valid():
		on_floor_advanced.call(current_floor)

	return true

## Handle floor completion
##
## Advances to next floor or completes the run. Calls appropriate callbacks.
##
## Returns:
##   String: "continue" if advancing to next floor, "won" if run complete
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
##
## Returns:
##   DifficultyConfig.FloorParams: Difficulty settings for current floor
func get_current_difficulty() -> DifficultyConfig.FloorParams:
	return DifficultyConfig.get_floor_params(current_floor)

## Get difficulty parameters for a specific floor
##
## Parameters:
##   floor_number: The floor number to get difficulty for (1-3)
##
## Returns:
##   DifficultyConfig.FloorParams: Difficulty settings for specified floor
func get_floor_difficulty(floor_number: int) -> DifficultyConfig.FloorParams:
	return DifficultyConfig.get_floor_params(floor_number)

## Generate dungeon for current floor with appropriate difficulty
##
## Creates a dungeon using floor-specific difficulty parameters and
## a deterministic seed based on run seed and floor number.
##
## Returns:
##   DungeonGenerator.GenerationResult: Generated dungeon data
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
##
## Combines run seed with floor number to create deterministic but
## unique seeds for each floor.
##
## Returns:
##   int: Floor-specific seed value
func _get_floor_seed() -> int:
	# Combine run seed with floor number for deterministic but different floors
	# Simple hash: run_seed * 1000 + floor_number
	return run_seed * 1000 + current_floor

## Get number of guards for current floor
##
## Returns:
##   int: Number of guards for the current floor's difficulty
func get_guard_count_for_current_floor() -> int:
	var params = get_current_difficulty()
	return params.guard_count

## Check if run is complete
##
## Returns:
##   bool: true if current floor exceeds total floors (run finished)
func is_run_complete() -> bool:
	return current_floor > TOTAL_FLOORS
