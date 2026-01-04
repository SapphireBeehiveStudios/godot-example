extends RefCounted
## DifficultyConfig - Manages difficulty scaling across floors
##
## Provides deterministic difficulty parameters based on floor number.
## Part of EPIC 7 - Issue #44

class_name DifficultyConfig

## Difficulty parameters for a specific floor
class FloorParams:
	var floor_number: int = 1
	var guard_count: int = 0
	var wall_density: float = 0.3

	func _init(floor: int, guards: int, density: float) -> void:
		floor_number = floor
		guard_count = guards
		wall_density = density

## Get difficulty parameters for a specific floor (1-indexed)
static func get_floor_params(floor_number: int) -> FloorParams:
	# Clamp floor number to valid range (1-3)
	var floor = clampi(floor_number, 1, 3)

	# Scale difficulty based on floor
	match floor:
		1:
			# Floor 1: Easy - 1 guard, low wall density
			return FloorParams.new(1, 1, 0.25)
		2:
			# Floor 2: Medium - 2 guards, medium wall density
			return FloorParams.new(2, 2, 0.30)
		3:
			# Floor 3: Hard - 3 guards, higher wall density
			return FloorParams.new(3, 3, 0.35)
		_:
			# Fallback (should never reach here)
			return FloorParams.new(1, 1, 0.25)

## Maximum number of floors in a run
const MAX_FLOORS: int = 3

## Check if a floor number is valid
static func is_valid_floor(floor_number: int) -> bool:
	return floor_number >= 1 and floor_number <= MAX_FLOORS

## Check if this is the final floor
static func is_final_floor(floor_number: int) -> bool:
	return floor_number >= MAX_FLOORS
