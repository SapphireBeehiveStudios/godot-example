extends Node
## TurnSystem - Core turn-based game loop
##
## Handles strict turn order:
## 1. Resolve player action (move/wait/interact)
## 2. Resolve pickups on tile
## 3. Check win/lose conditions
##
## Deterministic outcomes given same seed + inputs

class_name TurnSystem

## Emitted when a turn completes
signal turn_completed(turn_number: int)

## Emitted when player wins
signal player_won

## Emitted when player loses
signal player_lost

## Current turn count
var turn_count: int = 0

## Player position (Vector2i)
var player_position: Vector2i = Vector2i(0, 0)

## Player inventory (dictionary with item counts)
var player_inventory: Dictionary = {}

## Map of walls (Vector2i -> bool)
var walls: Dictionary = {}

## Map of pickups (Vector2i -> item_type)
var pickups: Dictionary = {}

## Win condition state
var has_won: bool = false

## Lose condition state
var has_lost: bool = false

## Random number generator for deterministic gameplay
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	pass


## Initialize the turn system with a seed for deterministic gameplay
func initialize(seed_value: int = 0) -> void:
	rng.seed = seed_value
	turn_count = 0
	player_position = Vector2i(0, 0)
	player_inventory.clear()
	walls.clear()
	pickups.clear()
	has_won = false
	has_lost = false


## Set player starting position
func set_player_position(pos: Vector2i) -> void:
	player_position = pos


## Add a wall at the given position
func add_wall(pos: Vector2i) -> void:
	walls[pos] = true


## Add a pickup at the given position
func add_pickup(pos: Vector2i, item_type: String) -> void:
	pickups[pos] = item_type


## Check if a position has a wall
func is_wall(pos: Vector2i) -> bool:
	return walls.get(pos, false)


## Check if a position has a pickup
func has_pickup(pos: Vector2i) -> bool:
	return pickups.has(pos)


## Get the pickup at a position
func get_pickup(pos: Vector2i) -> String:
	return pickups.get(pos, "")


## Process a player move action
## Returns true if the move was successful, false if blocked
func process_move(direction: Vector2i) -> bool:
	var target_position = player_position + direction

	# Check if target position has a wall
	if is_wall(target_position):
		# Move fails - position unchanged
		return false

	# Move succeeds
	player_position = target_position
	return true


## Process a wait action
## Always succeeds and increments turn count
func process_wait() -> void:
	# Wait action does nothing except advance the turn
	pass


## Process an interact action
## Currently a placeholder for future implementation
func process_interact() -> bool:
	# Placeholder for interact logic
	return true


## Resolve pickups on the current player tile
func resolve_pickups() -> void:
	if has_pickup(player_position):
		var item_type = get_pickup(player_position)

		# Add item to inventory
		if player_inventory.has(item_type):
			player_inventory[item_type] += 1
		else:
			player_inventory[item_type] = 1

		# Remove pickup from map
		pickups.erase(player_position)


## Check win/lose conditions
func check_win_lose() -> void:
	# Win condition: placeholder (will be implemented based on game requirements)
	# For now, we just maintain the state without automatic win detection

	# Lose condition: only applies when guards exist (future implementation)
	# For now, we don't automatically trigger lose
	pass


## Execute a full turn with the given action
## Action types: "move", "wait", "interact"
## For "move" action, direction parameter is required (Vector2i)
func execute_turn(action: String, direction: Vector2i = Vector2i.ZERO) -> Dictionary:
	var result = {
		"success": true,
		"action": action,
		"turn_number": turn_count + 1,
		"position_changed": false
	}

	# Step 1: Resolve player action
	match action:
		"move":
			var old_position = player_position
			var move_success = process_move(direction)
			result.success = move_success
			result.position_changed = (player_position != old_position)
		"wait":
			process_wait()
		"interact":
			result.success = process_interact()
		_:
			result.success = false
			result.error = "Unknown action type"
			return result

	# Step 2: Resolve pickups on tile
	resolve_pickups()

	# Step 3: Check win/lose conditions
	check_win_lose()

	# Increment turn count (one input = one turn)
	turn_count += 1

	# Emit turn completed signal
	turn_completed.emit(turn_count)

	# Check if game is over
	if has_won:
		player_won.emit()
	elif has_lost:
		player_lost.emit()

	return result


## Get current player inventory count for an item type
func get_inventory_count(item_type: String) -> int:
	return player_inventory.get(item_type, 0)


## Manually set win condition (for testing or level completion)
func set_win_condition(won: bool) -> void:
	has_won = won
	if won:
		player_won.emit()


## Manually set lose condition (for testing or game over)
func set_lose_condition(lost: bool) -> void:
	has_lost = lost
	if lost:
		player_lost.emit()
