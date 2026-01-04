extends Node
## GuardSystem - Guard entities with patrol behavior
##
## Manages guard entities that:
## - Move once per turn during "guard phase"
## - Patrol using random walk with wall avoidance
## - Respect walkability (walls, closed doors)
##
## Part of EPIC 4 - Issue #31

## Emitted when a message should be logged (Issue #36)
signal message_generated(text: String, type: String)

## Guard state enumeration
enum GuardState {
	PATROL,  ## Random walk patrol behavior
	CHASE    ## (Future) Pursuit of player
}

## Guard entity data structure
class Guard:
	var position: Vector2i
	var state: GuardState
	var patrol_direction: Vector2i  ## Current direction of patrol movement
	var movement_cooldown: int = 0  ## Turns remaining before next movement (for water tiles)

	func _init(pos: Vector2i = Vector2i(0, 0), initial_state: GuardState = GuardState.PATROL) -> void:
		position = pos
		state = initial_state
		patrol_direction = Vector2i(1, 0)  ## Default: moving right
		movement_cooldown = 0

## List of all active guards
var guards: Array[Guard] = []

## Random number generator (should be shared with TurnSystem for determinism)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Reference to grid walkability checker (function delegate)
## Expected signature: func(pos: Vector2i) -> bool
var is_tile_walkable_callback: Callable

## Reference to grid movement cost checker (function delegate)
## Expected signature: func(pos: Vector2i) -> int
var get_movement_cost_callback: Callable

func _init(seed_value: int = 0) -> void:
	"""Initialize the guard system with optional seed for deterministic behavior."""
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func reset() -> void:
	"""Reset all guard state."""
	guards.clear()

func add_guard(position: Vector2i) -> Guard:
	"""Add a new guard at the specified position."""
	var guard = Guard.new(position)
	guards.append(guard)
	return guard

func remove_guard(guard: Guard) -> void:
	"""Remove a guard from the system."""
	guards.erase(guard)

func set_walkability_checker(callback: Callable) -> void:
	"""Set the callback function to check if a tile is walkable."""
	is_tile_walkable_callback = callback

func set_movement_cost_checker(callback: Callable) -> void:
	"""Set the callback function to get movement cost for a tile."""
	get_movement_cost_callback = callback

func process_guard_phase() -> Dictionary:
	"""
	Process one guard phase - all guards move according to their behavior.

	Returns:
		Dictionary with phase results: {
			"guards_moved": int,
			"guard_positions": Array[Vector2i]
		}
	"""
	var result = {
		"guards_moved": 0,
		"guard_positions": []
	}

	for guard in guards:
		# Check if guard is on cooldown (from water movement)
		if guard.movement_cooldown > 0:
			guard.movement_cooldown -= 1
		else:
			# Guard can move this turn
			match guard.state:
				GuardState.PATROL:
					_process_patrol(guard)
					result.guards_moved += 1
				GuardState.CHASE:
					# Future: implement chase behavior
					pass

		result.guard_positions.append(guard.position)

	return result

func _process_patrol(guard: Guard) -> void:
	"""
	Process patrol behavior for a guard using random walk with wall avoidance.

	Strategy:
	1. Try to continue in current direction
	2. If blocked, pick a random valid direction
	3. If no valid directions, stay in place
	4. Apply movement cost cooldown for water tiles
	"""
	# Possible directions: up, down, left, right (4-directional movement)
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	# Try to continue in current direction first (momentum)
	var next_pos = guard.position + guard.patrol_direction
	if _is_walkable(next_pos):
		guard.position = next_pos
		_apply_movement_cost(guard, next_pos)
		return

	# Current direction blocked - find valid alternatives
	var valid_directions: Array[Vector2i] = []
	for direction in directions:
		var test_pos = guard.position + direction
		if _is_walkable(test_pos):
			valid_directions.append(direction)

	# If we have valid directions, pick one randomly
	if valid_directions.size() > 0:
		var chosen_idx = rng.randi_range(0, valid_directions.size() - 1)
		guard.patrol_direction = valid_directions[chosen_idx]
		next_pos = guard.position + guard.patrol_direction
		guard.position = next_pos
		_apply_movement_cost(guard, next_pos)

	# If no valid directions, stay in place (trapped or cornered)

func _is_walkable(pos: Vector2i) -> bool:
	"""Check if a position is walkable using the callback if available."""
	if is_tile_walkable_callback.is_valid():
		return is_tile_walkable_callback.call(pos)
	return true  # Default to walkable if no checker provided

func _apply_movement_cost(guard: Guard, pos: Vector2i) -> void:
	"""Apply movement cost cooldown based on tile type (e.g., water costs 2 turns)."""
	if get_movement_cost_callback.is_valid():
		var cost = get_movement_cost_callback.call(pos)
		# Cost of 2 means guard can't move next turn (cooldown = 1)
		# Cost of 1 means guard can move next turn (cooldown = 0)
		guard.movement_cooldown = cost - 1

func get_guard_at_position(pos: Vector2i) -> Guard:
	"""Get the guard at a specific position, or null if none."""
	for guard in guards:
		if guard.position == pos:
			return guard
	return null

func get_guard_count() -> int:
	"""Get the total number of guards."""
	return guards.size()

func get_guard_positions() -> Array[Vector2i]:
	"""Get an array of all guard positions."""
	var positions: Array[Vector2i] = []
	for guard in guards:
		positions.append(guard.position)
	return positions
