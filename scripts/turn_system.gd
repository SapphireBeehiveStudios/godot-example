extends Node
class_name TurnSystem
## Turn-based game system with deterministic execution
##
## Executes turns in strict order:
## 1. Resolve player action (move/wait/interact)
## 2. Resolve pickups on tile
## 3. Check win/lose conditions
##
## One input == one turn (including wait)
## Deterministic outcomes given same seed + inputs

# Signals for external observers
signal turn_completed(turn_number: int)
signal player_moved(from_pos: Vector2i, to_pos: Vector2i)
signal player_waited()
signal pickup_collected(pickup_type: String, position: Vector2i)
signal win_condition_met()
signal lose_condition_met()

# Turn state
var turn_count: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Game state
var player_position: Vector2i = Vector2i.ZERO
var inventory: Dictionary = {
	"keycard": 0,
	"coins": 0,
}

# Map data (walls, pickups, etc.)
var walls: Array[Vector2i] = []
var pickups: Dictionary = {}  # Vector2i -> pickup_type String
var win_position: Vector2i = Vector2i(-999, -999)  # Invalid default
var win_requires_keycard: bool = false

## Initialize the turn system with a seed for deterministic behavior
func initialize(seed_value: int = 0) -> void:
	rng.seed = seed_value
	turn_count = 0
	player_position = Vector2i.ZERO
	inventory = {
		"keycard": 0,
		"coins": 0,
	}
	walls.clear()
	pickups.clear()
	win_position = Vector2i(-999, -999)
	win_requires_keycard = false

## Set up the map with walls
func set_walls(wall_positions: Array[Vector2i]) -> void:
	walls = wall_positions.duplicate()

## Add a pickup at a specific position
func add_pickup(position: Vector2i, pickup_type: String) -> void:
	pickups[position] = pickup_type

## Set the win condition position and requirements
func set_win_condition(position: Vector2i, requires_keycard: bool = false) -> void:
	win_position = position
	win_requires_keycard = requires_keycard

## Execute a player move action
## Returns true if the move was successful, false if blocked
func execute_move(direction: Vector2i) -> bool:
	var new_position = player_position + direction

	# Step 1: Resolve player action
	if _is_wall(new_position):
		# Move into wall fails - position unchanged
		turn_count += 1
		turn_completed.emit(turn_count)
		return false

	var old_position = player_position
	player_position = new_position
	player_moved.emit(old_position, new_position)

	# Step 2: Resolve pickups on tile
	_resolve_pickups()

	# Step 3: Check win/lose conditions
	_check_conditions()

	turn_count += 1
	turn_completed.emit(turn_count)
	return true

## Execute a wait action (does nothing but advances turn)
func execute_wait() -> void:
	# Step 1: Resolve player action (wait = no action)
	player_waited.emit()

	# Step 2: No pickups when waiting in place (already picked up)
	# (pickups only trigger on entering a tile)

	# Step 3: Check win/lose conditions
	_check_conditions()

	turn_count += 1
	turn_completed.emit(turn_count)

## Execute an interact action (placeholder for future use)
func execute_interact() -> void:
	# Step 1: Resolve player action (interact)
	# TODO: Define interaction behavior

	# Step 2: Resolve pickups (if interaction causes movement)
	# Currently no movement, so no pickup resolution

	# Step 3: Check win/lose conditions
	_check_conditions()

	turn_count += 1
	turn_completed.emit(turn_count)

## Check if a position contains a wall
func _is_wall(position: Vector2i) -> bool:
	return position in walls

## Resolve pickups at current player position
func _resolve_pickups() -> void:
	if player_position in pickups:
		var pickup_type = pickups[player_position]

		# Add to inventory based on type
		if pickup_type == "keycard":
			inventory["keycard"] += 1
		elif pickup_type == "coin":
			inventory["coins"] += 1

		pickup_collected.emit(pickup_type, player_position)

		# Remove pickup from map (it's been collected)
		pickups.erase(player_position)

## Check win/lose conditions
func _check_conditions() -> void:
	# Check win condition
	if player_position == win_position:
		if win_requires_keycard:
			if inventory["keycard"] > 0:
				win_condition_met.emit()
		else:
			win_condition_met.emit()

	# Lose condition: Only checked when guards exist (not implemented yet)
	# Will be added later when guard system is implemented

## Get current turn count
func get_turn_count() -> int:
	return turn_count

## Get current player position
func get_player_position() -> Vector2i:
	return player_position

## Get current inventory
func get_inventory() -> Dictionary:
	return inventory.duplicate()

## Check if player has a specific item
func has_item(item_name: String) -> bool:
	if item_name in inventory:
		return inventory[item_name] > 0
	return false

## Get item count
func get_item_count(item_name: String) -> int:
	if item_name in inventory:
		return inventory[item_name]
	return 0
