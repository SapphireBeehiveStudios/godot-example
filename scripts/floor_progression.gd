extends RefCounted
## FloorProgression - Manages 3-floor run progression with difficulty scaling
##
## Tracks floor progression (1..3), applies deterministic difficulty ramps,
## and determines run win/loss conditions.
##
## Part of EPIC 7 - Issue #44

## Total number of floors in a complete run
const MAX_FLOORS: int = 3

## Difficulty configuration per floor (1-indexed)
## Structure: { floor_number: { "guard_count": int, "door_chance": float } }
const DIFFICULTY_RAMP: Dictionary = {
	1: {"guard_count": 2, "door_chance": 0.1},
	2: {"guard_count": 3, "door_chance": 0.15},
	3: {"guard_count": 4, "door_chance": 0.2}
}

## Current floor number (1-based, range: 1..3)
var current_floor: int = 1

## Whether the current run is complete
var run_complete: bool = false

## Whether the current run was won
var run_won: bool = false

func _init() -> void:
	"""Initialize floor progression at floor 1."""
	reset()

func reset() -> void:
	"""Reset progression to the start of a new run."""
	current_floor = 1
	run_complete = false
	run_won = false

func get_current_floor() -> int:
	"""Get the current floor number (1..3)."""
	return current_floor

func is_final_floor() -> bool:
	"""Check if the current floor is the final floor."""
	return current_floor == MAX_FLOORS

func advance_floor() -> bool:
	"""
	Advance to the next floor.

	Returns:
		bool: true if floor advanced successfully, false if already at final floor
	"""
	if current_floor >= MAX_FLOORS:
		return false

	current_floor += 1
	return true

func complete_floor() -> void:
	"""
	Mark the current floor as complete and check run victory.

	If this is the final floor, marks the run as won.
	"""
	if is_final_floor():
		# Completing floor 3 wins the run
		run_complete = true
		run_won = true
	else:
		# Advance to next floor
		advance_floor()

func is_run_complete() -> bool:
	"""Check if the run is complete (all 3 floors finished)."""
	return run_complete

func is_run_won() -> bool:
	"""Check if the run was won (completed floor 3)."""
	return run_won

func get_guard_count_for_floor(floor_num: int = -1) -> int:
	"""
	Get the number of guards for a specific floor based on difficulty ramp.

	Args:
		floor_num: Floor number (1..3), or -1 to use current floor

	Returns:
		int: Number of guards for the floor
	"""
	var floor = floor_num if floor_num > 0 else current_floor

	if floor in DIFFICULTY_RAMP:
		return DIFFICULTY_RAMP[floor]["guard_count"]

	# Fallback for invalid floor numbers
	return 2

func get_door_chance_for_floor(floor_num: int = -1) -> float:
	"""
	Get the door spawn chance for a specific floor based on difficulty ramp.

	Args:
		floor_num: Floor number (1..3), or -1 to use current floor

	Returns:
		float: Door spawn probability (0.0 to 1.0)
	"""
	var floor = floor_num if floor_num > 0 else current_floor

	if floor in DIFFICULTY_RAMP:
		return DIFFICULTY_RAMP[floor]["door_chance"]

	# Fallback for invalid floor numbers
	return 0.1

func get_difficulty_params(floor_num: int = -1) -> Dictionary:
	"""
	Get all difficulty parameters for a floor.

	Args:
		floor_num: Floor number (1..3), or -1 to use current floor

	Returns:
		Dictionary: { "guard_count": int, "door_chance": float }
	"""
	var floor = floor_num if floor_num > 0 else current_floor

	if floor in DIFFICULTY_RAMP:
		return DIFFICULTY_RAMP[floor].duplicate()

	# Fallback
	return {"guard_count": 2, "door_chance": 0.1}

func to_dict() -> Dictionary:
	"""
	Serialize floor progression state to a dictionary.

	Returns:
		Dictionary: Serialized state
	"""
	return {
		"current_floor": current_floor,
		"run_complete": run_complete,
		"run_won": run_won
	}

func from_dict(data: Dictionary) -> void:
	"""
	Load floor progression state from a dictionary.

	Args:
		data: Dictionary containing serialized state
	"""
	current_floor = data.get("current_floor", 1)
	run_complete = data.get("run_complete", false)
	run_won = data.get("run_won", false)
