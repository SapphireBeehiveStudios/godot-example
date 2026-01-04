extends Node
## Game Manager
##
## Manages game state, including win/loss conditions and game phases.
## This handles the core game loop logic for the stealth game.

## Emitted when the game is over (player captured or wins)
signal game_over(reason: String)

## Current game state
var is_game_over: bool = false
var game_over_reason: String = ""

## Player and guard positions (Vector2i for grid-based positions)
var player_position: Vector2i = Vector2i(0, 0)
var guard_positions: Array[Vector2i] = []

## Initialize game state
func _ready() -> void:
	reset_game()

## Reset the game to initial state
func reset_game() -> void:
	is_game_over = false
	game_over_reason = ""
	player_position = Vector2i(0, 0)
	guard_positions.clear()

## Set the player's current position
func set_player_position(pos: Vector2i) -> void:
	player_position = pos
	# Check for capture after player moves
	check_capture()

## Set a guard's position (by index)
func set_guard_position(guard_index: int, pos: Vector2i) -> void:
	# Ensure array is large enough
	while guard_positions.size() <= guard_index:
		guard_positions.append(Vector2i(0, 0))

	guard_positions[guard_index] = pos
	# Check for capture after guard moves
	check_capture()

## Update all guard positions at once (for guard phase)
func update_guard_positions(new_positions: Array[Vector2i]) -> void:
	guard_positions = new_positions.duplicate()
	# Check for capture after guards move
	check_capture()

## Add a guard at a specific position
func add_guard(pos: Vector2i) -> int:
	guard_positions.append(pos)
	check_capture()
	return guard_positions.size() - 1

## Check if any guard is on the player's tile (capture condition)
func check_capture() -> bool:
	# Don't check if game is already over
	if is_game_over:
		return false

	# Check each guard position
	for guard_pos in guard_positions:
		if guard_pos == player_position:
			# Capture detected!
			trigger_game_over("Player captured by guard")
			return true

	return false

## Trigger game over state
func trigger_game_over(reason: String) -> void:
	if is_game_over:
		return  # Already game over

	is_game_over = true
	game_over_reason = reason
	game_over.emit(reason)
	print("Game Over: %s" % reason)

## Get the current game over status
func get_game_over_status() -> bool:
	return is_game_over

## Get the game over reason
func get_game_over_reason() -> String:
	return game_over_reason
