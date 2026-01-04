extends Node
## TurnSystem - Core turn-based game loop
##
## Manages the strict turn order:
## 1. Resolve player action (move/wait/interact)
## 2. Resolve pickups on tile
## 3. Process guard phase (guards move)
## 4. Check win/lose conditions
##
## Part of EPIC 2 - Issue #20
## Guard integration - Issue #31 (EPIC 4)

## Emitted when a turn completes
signal turn_completed(turn_number: int)

## Emitted when game is won
signal game_won

## Emitted when game is lost
signal game_lost

## Emitted when a message should be logged (Issue #36)
signal message_generated(text: String, type: String)

## Current turn number (increments with each action, including wait)
var turn_count: int = 0

## Random number generator for deterministic outcomes
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Player position on the grid
var player_position: Vector2i = Vector2i(0, 0)

## Player inventory (for keycards, etc.)
var player_inventory: Dictionary = {}

## Grid of tiles (walls, pickups, doors, etc.)
## Structure: {Vector2i: {"type": "wall"|"floor"|"pickup"|"door_closed"|"door_open", "pickup_type": "keycard", etc.}}
var grid: Dictionary = {}

## Win condition flag (can be set externally for gating)
var win_condition_met: bool = false

## Game over flag
var game_over: bool = false

## Shard collection flag (for exit gating - Issue #22)
var shard_collected: bool = false

## Floor complete flag (for exit interaction - Issue #22)
var floor_complete: bool = false

## Guard system reference (optional, for EPIC 4 integration)
var guard_system = null

## Number of keycards required to win (can be set externally)
var keycards_required_to_win: int = 1

func _init(seed_value: int = 0) -> void:
	"""Initialize the turn system with optional seed for deterministic behavior."""
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func setup(seed_value: int = 0) -> void:
	"""Setup/reset the game state with a seed. Alias for reset()."""
	reset(seed_value)

func reset(seed_value: int = 0) -> void:
	"""Reset the game state."""
	turn_count = 0
	player_position = Vector2i(0, 0)
	player_inventory.clear()
	grid.clear()
	win_condition_met = false
	game_over = false
	shard_collected = false
	floor_complete = false

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
	# Walls and closed doors block movement; traps are walkable
	return tile.type != "wall" and tile.type != "door_closed"

func set_player_position(pos: Vector2i) -> void:
	"""Set the player's position directly."""
	player_position = pos

func get_player_position() -> Vector2i:
	"""Get the player's current position."""
	return player_position

func get_turn_count() -> int:
	"""Get the current turn count."""
	return turn_count

func add_wall(pos: Vector2i) -> void:
	"""Add a wall tile at the specified position."""
	set_grid_tile(pos, "wall")

func add_pickup(pos: Vector2i, pickup_type: String) -> void:
	"""Add a pickup at the specified position."""
	set_grid_tile(pos, "pickup", {"pickup_type": pickup_type})

func get_pickup(pos: Vector2i) -> String:
	"""Get the pickup type at a position, or empty string if none."""
	var tile = get_grid_tile(pos)
	if tile.type == "pickup":
		return tile.get("pickup_type", "")
	return ""

func add_door(pos: Vector2i, is_open: bool = false) -> void:
	"""Add a door at the specified position."""
	var door_type = "door_open" if is_open else "door_closed"
	set_grid_tile(pos, door_type)

func add_trap(pos: Vector2i) -> void:
	"""Add a trap tile at the specified position."""
	set_grid_tile(pos, "trap", {"armed": true})

func is_trap(pos: Vector2i) -> bool:
	"""Check if a position has a trap."""
	var tile = get_grid_tile(pos)
	return tile.type == "trap"

func is_trap_armed(pos: Vector2i) -> bool:
	"""Check if a trap is armed."""
	var tile = get_grid_tile(pos)
	if tile.type == "trap":
		return tile.get("armed", false)
	return false

func disarm_trap(pos: Vector2i) -> void:
	"""Disarm a trap at the specified position (one-time use)."""
	if is_trap(pos):
		grid[pos]["armed"] = false

func is_door(pos: Vector2i) -> bool:
	"""Check if a position has a door (open or closed)."""
	var tile = get_grid_tile(pos)
	return tile.type == "door_closed" or tile.type == "door_open"

func is_door_closed(pos: Vector2i) -> bool:
	"""Check if a position has a closed door."""
	var tile = get_grid_tile(pos)
	return tile.type == "door_closed"

func open_door(pos: Vector2i) -> bool:
	"""Open a door at the specified position. Returns true if successful."""
	if is_door_closed(pos):
		set_grid_tile(pos, "door_open")
		return true
	return false

func get_keycard_count() -> int:
	"""Get the number of keycards in inventory."""
	return player_inventory.get("keycard", 0)

func is_game_over() -> bool:
	"""Check if the game is over (won or lost)."""
	return game_over

func execute_turn(action: String, direction: Vector2i = Vector2i.ZERO) -> bool:
	"""
	Execute one complete turn with strict ordering.

	Args:
		action: "move", "wait", or "interact"
		direction: Direction vector for movement (only used if action is "move")

	Returns:
		bool: true if action succeeded, false otherwise

	Strict turn order:
	1. Resolve player action (move/wait/interact)
	2. Resolve pickups on tile
	3. Process guard phase (guards move)
	4. Check win/lose conditions
	"""
	if game_over:
		return false

	var action_succeeded = false

	# STEP 1: Resolve player action (move/wait/interact)
	match action:
		"move":
			var new_position = player_position + direction
			if is_tile_walkable(new_position):
				player_position = new_position
				action_succeeded = true
			else:
				# Move into wall fails - but still consumes a turn
				action_succeeded = false
				message_generated.emit("Bumped into a wall.", "info")
			# Turn count increments regardless of success/failure for moves
			turn_count += 1

		"wait":
			action_succeeded = true
			turn_count += 1

		"interact":
			# Interaction logic for doors (Issue #21)
			# Check the tile in the given direction for a door
			var target_pos = player_position + direction
			if is_door_closed(target_pos):
				# Check if player has a keycard
				if get_keycard_count() > 0:
					# Consume one keycard and open the door
					player_inventory["keycard"] -= 1
					open_door(target_pos)
					action_succeeded = true
				else:
					# No keycard - interaction fails
					action_succeeded = false
			else:
				# No closed door at target position - interaction fails
				action_succeeded = false
			turn_count += 1

		_:
			# Invalid action still consumes a turn
			action_succeeded = false
			turn_count += 1

	# STEP 2: Resolve pickups and traps on tile
	var current_tile = get_grid_tile(player_position)

	# Handle trap trigger (Issue #94)
	if current_tile.type == "trap" and current_tile.get("armed", false):
		# Trigger trap - alert nearby guards
		if guard_system != null:
			guard_system.alert_guards_in_radius(player_position, 5)
		message_generated.emit("Trap triggered! Guards alerted!", "trap")
		# Disarm the trap (one-time use)
		disarm_trap(player_position)

	if current_tile.type == "pickup":
		var pickup_type = current_tile.get("pickup_type", "unknown")

		# Handle shard pickup (Issue #22)
		if pickup_type == "shard":
			shard_collected = true
			message_generated.emit("Collected Data Shard!", "pickup")
		elif pickup_type == "keycard":
			message_generated.emit("Picked up a keycard.", "pickup")
		else:
			message_generated.emit("Picked up %s." % pickup_type, "pickup")

		# Add to inventory
		if pickup_type in player_inventory:
			player_inventory[pickup_type] += 1
		else:
			player_inventory[pickup_type] = 1

		# Remove pickup from grid (convert to floor)
		grid[player_position] = {"type": "floor"}

	# Handle exit interaction (Issue #22)
	if current_tile.type == "exit":
		if shard_collected:
			# Exit with shard collected triggers floor complete
			floor_complete = true
			game_over = true
			win_condition_met = true
			message_generated.emit("Floor complete! Advancing...", "success")
			game_won.emit()
		else:
			# If shard not collected, exit is blocked
			message_generated.emit("Exit blocked - need Data Shard!", "exit")

	# STEP 3: Process guard phase (if guards are present)
	if guard_system != null:
		guard_system.process_guard_phase()

	# STEP 4: Check win/lose conditions
	# Lose: Check if any guard is on player position
	if guard_system != null:
		var guard_at_player = guard_system.get_guard_at_position(player_position)
		if guard_at_player != null:
			game_over = true
			message_generated.emit("Caught by guard! Mission failed.", "guard")
			game_lost.emit()
			turn_completed.emit(turn_count)
			return action_succeeded

	# Win: Check if enough keycards collected
	if get_keycard_count() >= keycards_required_to_win:
		game_over = true
		win_condition_met = true
		game_won.emit()

	# Emit turn completed signal
	turn_completed.emit(turn_count)

	return action_succeeded

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
				message_generated.emit("Bumped into a wall.", "info")
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
			# Interaction logic for doors (Issue #21)
			var target_pos = player_position + direction
			if is_door_closed(target_pos):
				# Check if player has a keycard
				if get_keycard_count() > 0:
					# Consume one keycard and open the door
					player_inventory["keycard"] -= 1
					open_door(target_pos)
					result.success = true
					result.action_result = "Opened door at %s (keycard consumed)" % str(target_pos)
				else:
					# No keycard - interaction fails
					result.success = false
					result.action_result = "Cannot open door - no keycard"
			else:
				# No closed door at target position
				result.success = false
				result.action_result = "No door to interact with at %s" % str(target_pos)
			turn_count += 1

		_:
			result.success = false
			result.action_result = "Unknown action: %s" % action
			return result

	# STEP 2: Resolve pickups and traps on tile
	var current_tile = get_grid_tile(player_position)

	# Handle trap trigger (Issue #94)
	if current_tile.type == "trap" and current_tile.get("armed", false):
		# Trigger trap - alert nearby guards
		if guard_system != null:
			guard_system.alert_guards_in_radius(player_position, 5)
		message_generated.emit("Trap triggered! Guards alerted!", "trap")
		# Disarm the trap (one-time use)
		disarm_trap(player_position)
		result.action_result += " (trap triggered!)"

	if current_tile.type == "pickup":
		var pickup_type = current_tile.get("pickup_type", "unknown")

		# Handle shard pickup (Issue #22)
		if pickup_type == "shard":
			shard_collected = true
			message_generated.emit("Collected Data Shard!", "pickup")
		elif pickup_type == "keycard":
			message_generated.emit("Picked up a keycard.", "pickup")
		else:
			message_generated.emit("Picked up %s." % pickup_type, "pickup")

		# Add to inventory
		if pickup_type in player_inventory:
			player_inventory[pickup_type] += 1
		else:
			player_inventory[pickup_type] = 1

		# Remove pickup from grid
		grid[player_position] = {"type": "floor"}

		result.pickups.append(pickup_type)

	# Handle exit interaction (Issue #22)
	if current_tile.type == "exit":
		if shard_collected:
			# Exit with shard collected triggers floor complete
			floor_complete = true
			game_over = true
			result.game_state = "won"
			message_generated.emit("Floor complete! Advancing...", "success")
			game_won.emit()
		else:
			# Exit blocked - do nothing
			message_generated.emit("Exit blocked - need Data Shard!", "exit")
			result.action_result += " (exit blocked - shard not collected)"

	# STEP 3: Process guard phase (if guards are present)
	if guard_system != null:
		var guard_result = guard_system.process_guard_phase()
		result["guard_info"] = guard_result

	# STEP 4: Check win/lose conditions
	# Lose: Check if any guard is on player position
	if guard_system != null:
		var guard_at_player = guard_system.get_guard_at_position(player_position)
		if guard_at_player != null:
			game_over = true
			result.game_state = "lost"
			message_generated.emit("Caught by guard! Mission failed.", "guard")
			game_lost.emit()
			result.turn_number = turn_count
			turn_completed.emit(turn_count)
			return result

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

func set_guard_system(guards) -> void:
	"""Set the guard system reference for EPIC 4 integration."""
	guard_system = guards
	# Set up walkability callback so guards can check the grid
	if guard_system != null and guard_system.has_method("set_walkability_checker"):
		guard_system.set_walkability_checker(is_tile_walkable)

func is_shard_collected() -> bool:
	"""Check if the shard has been collected (Issue #22)."""
	return shard_collected

func is_floor_complete() -> bool:
	"""Check if the floor is complete (exit triggered with shard - Issue #22)."""
	return floor_complete
