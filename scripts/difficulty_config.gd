extends RefCounted
## DifficultyConfig - Manages difficulty scaling across infinite floors
##
## Provides scaling difficulty parameters based on floor number.
## Difficulty increases infinitely with diminishing returns on wall density.

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

## Get difficulty parameters for a specific floor (1-indexed, infinite scaling)
static func get_floor_params(floor_number: int) -> FloorParams:
	var floor = maxi(floor_number, 1)

	# Guards scale: starts at 1, adds 1 every 2 floors, caps at 8
	var guards = mini(1 + (floor - 1) / 2, 8)

	# Wall density: starts at 0.2, increases by 0.02 per floor, caps at 0.45
	var density = minf(0.2 + (floor - 1) * 0.02, 0.45)

	return FloorParams.new(floor, guards, density)

## Check if a floor number is valid (any positive number is valid now)
static func is_valid_floor(floor_number: int) -> bool:
	return floor_number >= 1

## Infinite mode - never a final floor
static func is_final_floor(_floor_number: int) -> bool:
	return false
