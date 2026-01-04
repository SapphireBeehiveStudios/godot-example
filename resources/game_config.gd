extends Resource
class_name GameConfig
## Game Configuration
##
## Central configuration resource containing all game parameters.
## These defaults match the pitch expectations:
## - Grid size 24x14
## - 3 floors per run
## - Turn-based stealth mechanics
## - Guard AI parameters

## Grid/Level Configuration
@export_group("Grid")
## Width of the game grid
@export var grid_width: int = 24
## Height of the game grid
@export var grid_height: int = 14
## Wall density for procedural generation (0.0 to 1.0)
@export_range(0.0, 1.0) var wall_density: float = 0.3

## Game Progression
@export_group("Progression")
## Total number of floors in a run
@export var total_floors: int = 3
## Starting floor number (0-based)
@export var starting_floor: int = 0

## Guard AI Configuration
@export_group("Guard AI")
## Maximum number of turns a guard will chase after losing line of sight
@export var max_chase_turns: int = 5
## Line of sight range for guards (in grid cells)
@export var los_range: int = 8

## Scoring Configuration
@export_group("Scoring")
## Points awarded for collecting a shard
@export var shard_points: int = 100
## Points awarded for completing a floor
@export var floor_bonus: int = 50
## Points deducted per turn (encourages speed)
@export var turn_penalty: int = 1

## Dungeon Generation
@export_group("Generation")
## Maximum attempts to generate a valid dungeon before failing
@export var max_generation_attempts: int = 100

## Load the configuration from the resource file
## Returns the config resource, or null if not found
static func load_config() -> Resource:
	var config_path = "res://resources/game_config.tres"
	if ResourceLoader.exists(config_path):
		return load(config_path)
	return null
