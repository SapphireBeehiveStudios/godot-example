extends Node
class_name TurnSystem
## Core turn-based game loop
##
## Implements strict turn order:
## 1. Resolve player action (move/wait/interact)
## 2. Resolve pickups on tile
## 3. Check win/lose conditions
##
## Ensures deterministic outcomes given same seed + inputs

signal turn_completed(turn_number: int)
signal player_moved(old_pos: Vector2i, new_pos: Vector2i)
signal pickup_collected(pickup_type: String, position: Vector2i)
signal game_won()
signal game_lost()

## Current turn number
var turn_count: int = 0

## Player position
var player_position: Vector2i = Vector2i(0, 0)

## Player inventory (simple dictionary for now)
var inventory: Dictionary = {}

## Map boundaries (for collision detection)
var map_width: int = 10
var map_height: int = 10

## Walls (set of positions that are impassable)
var walls: Array[Vector2i] = []

## Pickups on the map (dictionary: position -> pickup_type)
var pickups: Dictionary = {}

## Win condition (for now, just a flag)
var win_condition_met: bool = false

## Lose condition (for now, always false - guards don't exist yet)
var lose_condition_met: bool = false

## Random number generator for deterministic behavior
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	"""Initialize the turn system."""
	# Initialize inventory
	inventory = {
		"keycard": 0,
		"coins": 0,
	}


func set_seed(seed_value: int) -> void:
	"""Set the random seed for deterministic behavior."""
	rng.seed = seed_value


func set_map_size(width: int, height: int) -> void:
	"""Set the map boundaries."""
	map_width = width
	map_height = height


func add_wall(position: Vector2i) -> void:
	"""Add a wall at the specified position."""
	if position not in walls:
		walls.append(position)


func remove_wall(position: Vector2i) -> void:
	"""Remove a wall at the specified position."""
	walls.erase(position)


func add_pickup(position: Vector2i, pickup_type: String) -> void:
	"""Place a pickup at the specified position."""
	pickups[position] = pickup_type


func remove_pickup(position: Vector2i) -> void:
	"""Remove a pickup from the specified position."""
	pickups.erase(position)


func is_position_valid(position: Vector2i) -> bool:
	"""Check if a position is within map bounds and not a wall."""
	# Check bounds
	if position.x < 0 or position.x >= map_width:
		return false
	if position.y < 0 or position.y >= map_height:
		return false

	# Check walls
	if position in walls:
		return false

	return true


func execute_turn(action: String, direction: Vector2i = Vector2i.ZERO) -> bool:
	"""
	Execute a complete turn with the specified action.

	Args:
		action: One of "move", "wait", "interact"
		direction: Direction vector for move action (ignored for wait/interact)

	Returns:
		bool: True if the turn was executed successfully
	"""
	# Step 1: Resolve player action
	var action_successful = _resolve_player_action(action, direction)

	# Step 2: Resolve pickups on current tile (only if action was successful or wait)
	if action_successful or action == "wait":
		_resolve_pickups()

	# Step 3: Check win/lose conditions
	_check_conditions()

	# Increment turn count
	turn_count += 1
	turn_completed.emit(turn_count)

	return action_successful


func _resolve_player_action(action: String, direction: Vector2i) -> bool:
	"""
	Resolve the player action.

	Returns:
		bool: True if action succeeded, False if it failed
	"""
	match action:
		"move":
			var target_position = player_position + direction
			if is_position_valid(target_position):
				var old_pos = player_position
				player_position = target_position
				player_moved.emit(old_pos, player_position)
				return true
			else:
				# Move failed (into wall or out of bounds)
				return false

		"wait":
			# Wait always succeeds
			return true

		"interact":
			# TODO: Implement interaction logic
			# For now, interact always succeeds but does nothing
			return true

		_:
			push_warning("Unknown action: %s" % action)
			return false


func _resolve_pickups() -> void:
	"""Check for and collect any pickups at the player's current position."""
	if player_position in pickups:
		var pickup_type = pickups[player_position]

		# Add to inventory
		if pickup_type in inventory:
			inventory[pickup_type] += 1
		else:
			inventory[pickup_type] = 1

		# Remove from map
		pickups.erase(player_position)

		# Emit signal
		pickup_collected.emit(pickup_type, player_position)


func _check_conditions() -> void:
	"""Check win/lose conditions."""
	# Check win condition
	if win_condition_met and not lose_condition_met:
		game_won.emit()

	# Check lose condition (guards don't exist yet, so always false for now)
	if lose_condition_met:
		game_lost.emit()


func reset() -> void:
	"""Reset the turn system to initial state."""
	turn_count = 0
	player_position = Vector2i(0, 0)
	inventory = {
		"keycard": 0,
		"coins": 0,
	}
	walls.clear()
	pickups.clear()
	win_condition_met = false
	lose_condition_met = false


func get_turn_count() -> int:
	"""Get the current turn count."""
	return turn_count


func get_player_position() -> Vector2i:
	"""Get the current player position."""
	return player_position


func set_player_position(position: Vector2i) -> void:
	"""Set the player position (for initialization)."""
	player_position = position


func get_inventory_count(item: String) -> int:
	"""Get the count of a specific item in inventory."""
	if item in inventory:
		return inventory[item]
	return 0
