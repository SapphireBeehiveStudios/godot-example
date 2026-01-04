extends Node
## TurnSystem - Core turn-based game loop
##
## Implements strict turn order for issue #20:
## 1. Resolve player action (move/wait/interact)
## 2. Resolve pickups on tile
## 3. Check win/lose conditions
##
## One input == one turn, with deterministic outcomes given same seed + inputs.

class_name TurnSystem

## Emitted when a turn completes
signal turn_completed(turn_number: int)

## Emitted when player position changes
signal player_moved(old_pos: Vector2i, new_pos: Vector2i)

## Emitted when player picks up an item
signal item_picked_up(item_type: String)

## Emitted when win condition is met
signal game_won()

## Emitted when lose condition is met (reserved for when guards exist)
signal game_lost()

## Current turn number
var turn_count: int = 0

## Player's current position on the grid
var player_position: Vector2i = Vector2i(0, 0)

## Inventory - tracks collected items
var inventory: Dictionary = {
	"keycards": 0,
	"items": 0
}

## Grid walls - set of wall positions (for collision detection)
var walls: Dictionary = {}

## Pickups on the map - Dictionary of position -> item_type
var pickups: Dictionary = {}

## Random number generator for deterministic gameplay
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Win condition - number of keycards required to win
var keycards_required_to_win: int = 1

## Win condition met flag
var has_won: bool = false

## Lose condition met flag (for future guard implementation)
var has_lost: bool = false


func _init() -> void:
	"""Initialize the turn system."""
	pass


func setup(seed_value: int = 0) -> void:
	"""
	Setup the turn system with a seed for deterministic behavior.

	Args:
		seed_value: Random seed for deterministic gameplay
	"""
	rng.seed = seed_value
	turn_count = 0
	player_position = Vector2i(0, 0)
	inventory = {"keycards": 0, "items": 0}
	walls = {}
	pickups = {}
	has_won = false
	has_lost = false


func add_wall(pos: Vector2i) -> void:
	"""Add a wall at the given position."""
	walls[pos] = true


func remove_wall(pos: Vector2i) -> void:
	"""Remove a wall at the given position."""
	walls.erase(pos)


func is_wall(pos: Vector2i) -> bool:
	"""Check if there's a wall at the given position."""
	return walls.has(pos)


func add_pickup(pos: Vector2i, item_type: String) -> void:
	"""
	Add a pickup item at the given position.

	Args:
		pos: Grid position
		item_type: Type of item (e.g., "keycard", "health", etc.)
	"""
	pickups[pos] = item_type


func remove_pickup(pos: Vector2i) -> void:
	"""Remove a pickup at the given position."""
	pickups.erase(pos)


func get_pickup(pos: Vector2i) -> String:
	"""Get the pickup type at the given position, or empty string if none."""
	return pickups.get(pos, "")


## === CORE TURN LOOP ===


func execute_turn(action: String, direction: Vector2i = Vector2i.ZERO) -> bool:
	"""
	Execute one turn with the given action.
	One input == one turn (including wait).

	Args:
		action: The action to perform ("move", "wait", "interact")
		direction: Direction vector for movement actions

	Returns:
		true if turn executed successfully, false if invalid action
	"""
	if has_won or has_lost:
		return false  # Game over, no more turns

	# Step 1: Resolve player action
	var action_result = _resolve_player_action(action, direction)

	if not action_result:
		# Invalid action (e.g., move into wall) - turn still consumed but no effect
		turn_count += 1
		turn_completed.emit(turn_count)
		return false

	# Step 2: Resolve pickups on current tile
	_resolve_pickups()

	# Step 3: Check win/lose conditions
	_check_win_lose()

	# Increment turn counter
	turn_count += 1
	turn_completed.emit(turn_count)

	return true


func _resolve_player_action(action: String, direction: Vector2i) -> bool:
	"""
	Resolve the player's action.

	Returns:
		true if action was valid and executed, false otherwise
	"""
	match action:
		"move":
			return _execute_move(direction)
		"wait":
			return _execute_wait()
		"interact":
			return _execute_interact(direction)
		_:
			push_warning("Unknown action: %s" % action)
			return false


func _execute_move(direction: Vector2i) -> bool:
	"""
	Execute a move action.

	Returns:
		true if move succeeded, false if blocked by wall
	"""
	var new_position = player_position + direction

	# Check for wall collision
	if is_wall(new_position):
		# Move into wall fails - position unchanged
		return false

	# Move succeeds
	var old_position = player_position
	player_position = new_position
	player_moved.emit(old_position, new_position)
	return true


func _execute_wait() -> bool:
	"""
	Execute a wait action (do nothing for one turn).

	Returns:
		Always returns true (wait is always valid)
	"""
	# Wait simply consumes a turn without changing position
	return true


func _execute_interact(direction: Vector2i) -> bool:
	"""
	Execute an interact action with an object in the given direction.

	Returns:
		true if interaction succeeded, false otherwise
	"""
	var interact_position = player_position + direction

	# For now, interaction just checks if there's something there
	# Future implementation would handle doors, terminals, etc.
	if pickups.has(interact_position):
		return true

	# No interaction target
	return false


func _resolve_pickups() -> void:
	"""
	Resolve pickups on the player's current tile.
	Automatically pick up items on the tile.
	"""
	if pickups.has(player_position):
		var item_type = pickups[player_position]

		# Add to inventory based on type
		match item_type:
			"keycard":
				inventory["keycards"] += 1
			_:
				inventory["items"] += 1

		# Remove from world
		pickups.erase(player_position)

		# Emit signal
		item_picked_up.emit(item_type)


func _check_win_lose() -> void:
	"""
	Check win/lose conditions.

	Win: Player has collected required number of keycards
	Lose: Reserved for future guard implementation
	"""
	# Check win condition
	if inventory["keycards"] >= keycards_required_to_win and not has_won:
		has_won = true
		game_won.emit()

	# Lose condition gated for now (only later when guards exist)
	# Future: Check if player caught by guards


## === UTILITY METHODS ===


func get_turn_count() -> int:
	"""Get the current turn count."""
	return turn_count


func get_player_position() -> Vector2i:
	"""Get the player's current position."""
	return player_position


func set_player_position(pos: Vector2i) -> void:
	"""Set the player's position (for testing/setup)."""
	player_position = pos


func get_inventory() -> Dictionary:
	"""Get a copy of the player's inventory."""
	return inventory.duplicate()


func get_keycard_count() -> int:
	"""Get the number of keycards in inventory."""
	return inventory["keycards"]


func is_game_over() -> bool:
	"""Check if the game is over (won or lost)."""
	return has_won or has_lost
