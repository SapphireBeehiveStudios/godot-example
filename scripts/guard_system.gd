extends Node
## GuardSystem - Smart guards with vision, alerts, and chase behavior
##
## Guards can:
## - Patrol randomly when calm
## - Spot the player within their vision range
## - Chase the player when alerted
## - Lose interest after chase timeout

signal message_generated(text: String, type: String)

## Guard state enumeration
enum GuardState {
	PATROL,   ## Random walk, unaware of player
	ALERT,    ## Spotted something, investigating
	CHASE     ## Actively pursuing player
}

## Guard entity
class Guard:
	var position: Vector2i
	var state: GuardState
	var patrol_direction: Vector2i
	var movement_cooldown: int = 0
	var alert_timer: int = 0        ## Turns remaining in alert/chase
	var last_seen_player: Vector2i  ## Where player was last spotted
	var vision_range: int = 5       ## How far guard can see

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		position = pos
		state = GuardState.PATROL
		patrol_direction = Vector2i(1, 0)
		last_seen_player = Vector2i(-99, -99)

var guards: Array[Guard] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Callbacks
var is_tile_walkable_callback: Callable
var get_movement_cost_callback: Callable
var has_line_of_sight_callback: Callable

## Player position (updated each turn)
var player_position: Vector2i = Vector2i.ZERO

## Chase duration before giving up
const CHASE_DURATION: int = 8
const ALERT_DURATION: int = 3

func _init(seed_value: int = 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func reset() -> void:
	guards.clear()

func add_guard(position: Vector2i) -> Guard:
	var guard = Guard.new(position)
	# Randomize initial direction
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	guard.patrol_direction = dirs[rng.randi_range(0, 3)]
	guards.append(guard)
	return guard

func set_walkability_checker(callback: Callable) -> void:
	is_tile_walkable_callback = callback

func set_movement_cost_checker(callback: Callable) -> void:
	get_movement_cost_callback = callback

func set_line_of_sight_checker(callback: Callable) -> void:
	has_line_of_sight_callback = callback

func update_player_position(pos: Vector2i) -> void:
	player_position = pos

func process_guard_phase() -> Dictionary:
	var result = {
		"guards_moved": 0,
		"guard_positions": [],
		"player_spotted": false
	}

	for guard in guards:
		# Check cooldown
		if guard.movement_cooldown > 0:
			guard.movement_cooldown -= 1
			result.guard_positions.append(guard.position)
			continue

		# Check if guard can see player
		var can_see_player = _can_see_player(guard)

		if can_see_player:
			if guard.state == GuardState.PATROL:
				guard.state = GuardState.ALERT
				guard.alert_timer = ALERT_DURATION
				message_generated.emit("Guard spotted you!", "danger")
				result.player_spotted = true
			elif guard.state == GuardState.ALERT:
				guard.state = GuardState.CHASE
				guard.alert_timer = CHASE_DURATION
				message_generated.emit("Guard is chasing you!", "danger")
			else:
				guard.alert_timer = CHASE_DURATION  # Reset chase timer
			guard.last_seen_player = player_position

		# Process based on state
		match guard.state:
			GuardState.PATROL:
				_process_patrol(guard)
			GuardState.ALERT:
				_process_alert(guard)
			GuardState.CHASE:
				_process_chase(guard)

		# Decay alert timer
		if guard.state != GuardState.PATROL:
			guard.alert_timer -= 1
			if guard.alert_timer <= 0:
				guard.state = GuardState.PATROL
				message_generated.emit("Guard lost interest.", "info")

		result.guards_moved += 1
		result.guard_positions.append(guard.position)

	return result

func _can_see_player(guard: Guard) -> bool:
	var dist = _manhattan_distance(guard.position, player_position)
	if dist > guard.vision_range:
		return false

	# Check line of sight
	if has_line_of_sight_callback.is_valid():
		return has_line_of_sight_callback.call(guard.position, player_position)

	# Fallback: simple distance check
	return dist <= guard.vision_range

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _process_patrol(guard: Guard) -> void:
	var directions = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]

	# Try current direction first (momentum)
	var next_pos = guard.position + guard.patrol_direction
	if _is_walkable(next_pos) and rng.randf() > 0.2:  # 80% continue, 20% random
		guard.position = next_pos
		_apply_movement_cost(guard, next_pos)
		return

	# Pick random direction
	var valid: Array[Vector2i] = []
	for dir in directions:
		if _is_walkable(guard.position + dir):
			valid.append(dir)

	if valid.size() > 0:
		guard.patrol_direction = valid[rng.randi_range(0, valid.size() - 1)]
		guard.position = guard.position + guard.patrol_direction
		_apply_movement_cost(guard, guard.position)

func _process_alert(guard: Guard) -> void:
	# Look around (don't move, just observe)
	# If player seen again, escalate to chase
	pass

func _process_chase(guard: Guard) -> void:
	# Move toward last known player position
	var target = guard.last_seen_player
	var best_dir = Vector2i.ZERO
	var best_dist = 9999

	var directions = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]

	for dir in directions:
		var next_pos = guard.position + dir
		if _is_walkable(next_pos):
			var dist = _manhattan_distance(next_pos, target)
			if dist < best_dist:
				best_dist = dist
				best_dir = dir

	if best_dir != Vector2i.ZERO:
		guard.position = guard.position + best_dir
		guard.patrol_direction = best_dir
		_apply_movement_cost(guard, guard.position)

func _is_walkable(pos: Vector2i) -> bool:
	if is_tile_walkable_callback.is_valid():
		return is_tile_walkable_callback.call(pos)
	return true

func _apply_movement_cost(guard: Guard, pos: Vector2i) -> void:
	if get_movement_cost_callback.is_valid():
		var cost = get_movement_cost_callback.call(pos)
		guard.movement_cooldown = cost - 1

func get_guard_at_position(pos: Vector2i) -> Guard:
	for guard in guards:
		if guard.position == pos:
			return guard
	return null

func get_guard_count() -> int:
	return guards.size()

func get_guard_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for guard in guards:
		positions.append(guard.position)
	return positions

func get_guard_states() -> Dictionary:
	"""Returns dict of position -> state for rendering"""
	var states = {}
	for guard in guards:
		states[guard.position] = guard.state
	return states
