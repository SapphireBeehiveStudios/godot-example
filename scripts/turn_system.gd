extends Node
## TurnSystem - Core turn-based game loop
##
## Manages the strict turn order:
## 1. Resolve player action (move/wait/interact)
## 2. Resolve pickups on tile
## 3. Check win/lose conditions
##
## Part of EPIC 2 - Issue #20

## Emitted when a turn completes
signal turn_completed(turn_number: int)

## Emitted when game is won
signal game_won

## Emitted when game is lost
signal game_lost

## Current turn number (increments with each action, including wait)
var turn_count: int = 0

## Random number generator for deterministic outcomes
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Player position on the grid
var player_position: Vector2i = Vector2i(0, 0)

## Player inventory (for keycards, etc.)
var player_inventory: Dictionary = {}

## Grid of tiles (walls, pickups, etc.)
## Structure: {Vector2i: {"type": "wall"|"floor"|"pickup", "pickup_type": "keycard", etc.}}
var grid: Dictionary = {}

## Win condition flag (can be set externally for gating)
var win_condition_met: bool = false

## Game over flag
var game_over: bool = false

func _init(seed_value: int = 0) -> void:
	"""Initialize the turn system with optional seed for deterministic behavior."""
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func reset(seed_value: int = 0) -> void:
	"""Reset the game state."""
	turn_count = 0
	player_position = Vector2i(0, 0)
	player_inventory.clear()
	grid.clear()
	win_condition_met = false
	game_over = false

	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func set_grid_tile(pos: Vector2i, tile_type: String, properties: Dictionary = {}) -> void:
	"""Set a tile in the grid with optional properties."""
	grid[pos] = {"type": tile_type}
	for key in properties:
		grid[pos][key] = properties[key]

func get_grid_tile(pos: Vector2i) -> Dictionary:
	"""Get a tile from the grid, or return floor if not set."""
	if pos in grid:
		return grid[pos]
	return {"type": "floor"}

func is_tile_walkable(pos: Vector2i) -> bool:
	"""Check if a tile can be walked on."""
	var tile = get_grid_tile(pos)
	return tile.type != "wall"

func process_turn(action: String, direction: Vector2i = Vector2i.ZERO) -> Dictionary:
	"""
	Process one complete turn with strict ordering.

	Args:
		action: "move", "wait", or "interact"
		direction: Direction vector for movement (only used if action is "move")

	Returns:
		Dictionary with turn results: {
			"success": bool,
			"turn_number": int,
			"action_result": String,
			"pickups": Array,
			"game_state": String  # "playing", "won", "lost"
		}
	"""
	if game_over:
		return {
			"success": false,
			"turn_number": turn_count,
			"action_result": "Game is already over",
			"pickups": [],
			"game_state": "won" if win_condition_met else "lost"
		}

	var result = {
		"success": false,
		"turn_number": turn_count,
		"action_result": "",
		"pickups": [],
		"game_state": "playing"
	}

	# STEP 1: Resolve player action (move/wait/interact)
	match action:
		"move":
			var new_position = player_position + direction
			if is_tile_walkable(new_position):
				player_position = new_position
				result.success = true
				result.action_result = "Moved to %s" % str(new_position)
				turn_count += 1
			else:
				result.success = false
				result.action_result = "Cannot move - blocked by wall"
				# Turn count still increments for failed moves as it's still an action
				# Actually, based on acceptance criteria "Move into wall fails (position unchanged)"
				# and "One input == one turn", we should NOT increment on failed move
				# Let me reconsider: the issue says "one input == one turn" which suggests
				# every input increments the turn, but the test says position unchanged
				# I'll interpret this as: failed moves don't increment turn count
				return result

		"wait":
			result.success = true
			result.action_result = "Waited"
			turn_count += 1

		"interact":
			# Placeholder for future interaction logic
			result.success = true
			result.action_result = "Interacted"
			turn_count += 1

		_:
			result.success = false
			result.action_result = "Unknown action: %s" % action
			return result

	# STEP 2: Resolve pickups on tile
	var current_tile = get_grid_tile(player_position)
	if current_tile.type == "pickup":
		var pickup_type = current_tile.get("pickup_type", "unknown")

		# Add to inventory
		if pickup_type in player_inventory:
			player_inventory[pickup_type] += 1
		else:
			player_inventory[pickup_type] = 1

		# Remove pickup from grid
		grid[player_position] = {"type": "floor"}

		result.pickups.append(pickup_type)

	# STEP 3: Check win/lose conditions
	# Lose: Only when guards exist (not implemented yet)
	# Win: Check if win condition is met (gated here)
	if win_condition_met:
		game_over = true
		result.game_state = "won"
		game_won.emit()

	# Update result
	result.turn_number = turn_count

	# Emit turn completed signal
	turn_completed.emit(turn_count)

	return result

func get_inventory_count(item_type: String) -> int:
	"""Get the count of a specific item in inventory."""
	return player_inventory.get(item_type, 0)

func set_win_condition(met: bool) -> void:
	"""Set the win condition flag (for external gating)."""
	win_condition_met = met
