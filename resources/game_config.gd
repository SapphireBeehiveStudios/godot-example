extends Resource
class_name GameConfig

## GameConfig: Central configuration for Terminal Heist gameplay parameters
##
## This resource defines all tunable game balance and presentation settings.
## Default values are balanced for a challenging but fair stealth experience.

# ===== GRID & LEVEL SETTINGS =====

## Grid width in cells
@export var grid_width: int = 20

## Grid height in cells
@export var grid_height: int = 12

## Number of floors per run
@export var floor_count: int = 3


# ===== GUARD AI SETTINGS =====

## How many turns guards chase before returning to patrol
@export var guard_max_chase_turns: int = 5

## Guard line-of-sight range in grid cells
@export var guard_los_range: int = 8

## Number of guards on floor 1 (scales up on higher floors)
@export var guards_per_floor_base: int = 2


# ===== GAMEPLAY BALANCE =====

## Keycards required to unlock the exit
@export var keycards_required_to_win: int = 1

## Score awarded for collecting the optional shard
@export var shard_score_bonus: int = 500

## Score bonus for completing a floor
@export var floor_completion_bonus: int = 100

## Score penalty per turn taken
@export var turn_penalty: int = 1


# ===== RENDERING COLORS =====

## Player character color
@export var color_player: String = "aqua"

## Guard character color
@export var color_guard: String = "red"

## Wall tile color
@export var color_wall: String = "gray"

## Floor tile color
@export var color_floor: String = "white"

## Open door color
@export var color_door_open: String = "green"

## Closed door color
@export var color_door_closed: String = "yellow"

## Keycard item color
@export var color_keycard: String = "blue"

## Shard item color
@export var color_shard: String = "gold"

## Exit tile color
@export var color_exit: String = "lime"


# ===== SERIALIZATION =====

## Serialize config to dictionary
func to_dict() -> Dictionary:
	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"floor_count": floor_count,
		"guard_max_chase_turns": guard_max_chase_turns,
		"guard_los_range": guard_los_range,
		"guards_per_floor_base": guards_per_floor_base,
		"keycards_required_to_win": keycards_required_to_win,
		"shard_score_bonus": shard_score_bonus,
		"floor_completion_bonus": floor_completion_bonus,
		"turn_penalty": turn_penalty,
		"color_player": color_player,
		"color_guard": color_guard,
		"color_wall": color_wall,
		"color_floor": color_floor,
		"color_door_open": color_door_open,
		"color_door_closed": color_door_closed,
		"color_keycard": color_keycard,
		"color_shard": color_shard,
		"color_exit": color_exit,
	}


## Deserialize config from dictionary
func from_dict(data: Dictionary) -> void:
	grid_width = data.get("grid_width", grid_width)
	grid_height = data.get("grid_height", grid_height)
	floor_count = data.get("floor_count", floor_count)
	guard_max_chase_turns = data.get("guard_max_chase_turns", guard_max_chase_turns)
	guard_los_range = data.get("guard_los_range", guard_los_range)
	guards_per_floor_base = data.get("guards_per_floor_base", guards_per_floor_base)
	keycards_required_to_win = data.get("keycards_required_to_win", keycards_required_to_win)
	shard_score_bonus = data.get("shard_score_bonus", shard_score_bonus)
	floor_completion_bonus = data.get("floor_completion_bonus", floor_completion_bonus)
	turn_penalty = data.get("turn_penalty", turn_penalty)
	color_player = data.get("color_player", color_player)
	color_guard = data.get("color_guard", color_guard)
	color_wall = data.get("color_wall", color_wall)
	color_floor = data.get("color_floor", color_floor)
	color_door_open = data.get("color_door_open", color_door_open)
	color_door_closed = data.get("color_door_closed", color_door_closed)
	color_keycard = data.get("color_keycard", color_keycard)
	color_shard = data.get("color_shard", color_shard)
	color_exit = data.get("color_exit", color_exit)
