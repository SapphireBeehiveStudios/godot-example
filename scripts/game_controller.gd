extends Node
## GameController - Main game orchestrator
##
## Connects all game systems together:
## - Menu -> Game flow
## - Turn system, dungeon generation, guards
## - Rendering and HUD updates
## - Win/lose state management
##
## Part of Issue #87 - Make the game playable through UI

## Preload dependencies
const TurnSystem = preload("res://scripts/turn_system.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")
const Renderer = preload("res://scripts/renderer.gd")
const MessageLog = preload("res://scripts/message_log.gd")
const RunProgressionManager = preload("res://scripts/run_progression_manager.gd")

## Game systems
var turn_system: TurnSystem = null
var guard_system: GuardSystem = null
var renderer: Renderer = null
var message_log: MessageLog = null
var progression_manager: RunProgressionManager = null

## HUD reference
@onready var hud = $HUD

## Menu reference
var menu: Control = null

## Current run seed
var current_seed: int = 0

## Game state tracking
var game_active: bool = false

## Initialize the game controller
##
## Sets up references to menu and HUD nodes. Hides the HUD initially
## until a game is started.
func _ready() -> void:
	# Get menu reference
	menu = get_node("../MainMenu")

	# Hide HUD initially
	if hud:
		hud.visible = false

## Called when the player starts a run from the menu
##
## Hides the menu and starts the game with the provided seed value.
##
## Parameters:
##   seed_value: The seed value (int or String) for the game run
func _on_start_run_requested(seed_value: Variant) -> void:
	# Hide menu
	if menu:
		menu.visible = false

	# Start the game
	start_game(seed_value)

## Handle game input
##
## Processes player input for movement, waiting, interaction, and reset.
## Only active when a game is in progress.
##
## Parameters:
##   event: The input event to process
func _input(event: InputEvent) -> void:
	if not game_active:
		return

	if event.is_action_pressed("reset"):
		restart_floor()
		get_viewport().set_input_as_handled()
		return

	# Movement
	var direction := Vector2i.ZERO
	var action := ""

	if event.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
		action = "move"
	elif event.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)
		action = "move"
	elif event.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
		action = "move"
	elif event.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)
		action = "move"
	elif event.is_action_pressed("confirm"):
		action = "wait"
	elif event.is_action_pressed("interact"):
		# For interact, we need a direction - use last movement or ask player
		# For now, let's check all 4 directions for a door
		var interact_dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		for dir in interact_dirs:
			if turn_system.is_door_closed(turn_system.get_player_position() + dir):
				action = "interact"
				direction = dir
				break

	if action != "":
		process_player_action(action, direction)
		get_viewport().set_input_as_handled()

## Start a new game with the given seed
##
## Initializes all game systems (renderer, message log, progression manager)
## and starts the first floor. Shows the HUD.
##
## Parameters:
##   seed_value: The seed value (int or String) to use for the run
func start_game(seed_value: Variant) -> void:
	# Convert seed to int
	if seed_value is String:
		current_seed = hash(seed_value)
	else:
		current_seed = seed_value

	print("Starting game with seed: %d" % current_seed)

	# Initialize game systems
	renderer = Renderer.new()
	message_log = MessageLog.new()
	progression_manager = RunProgressionManager.new(current_seed)

	# Start first floor
	start_floor()

	# Show HUD
	if hud:
		hud.visible = true
		hud.set_message_log(message_log)

	game_active = true

## Start or restart the current floor
##
## Creates a new turn system and guard system, generates the dungeon,
## places entities, and updates the HUD. Uses current progression manager
## to determine floor number and difficulty parameters.
func start_floor() -> void:
	var floor_num = progression_manager.get_current_floor()
	print("Starting floor %d" % floor_num)

	# Create new turn system
	turn_system = TurnSystem.new(current_seed + floor_num)

	# Connect signals
	turn_system.turn_completed.connect(_on_turn_completed)
	turn_system.game_won.connect(_on_floor_complete)
	turn_system.game_lost.connect(_on_game_lost)
	turn_system.message_generated.connect(_on_message_generated)

	# Generate dungeon
	var params = progression_manager.get_current_difficulty()
	var gen = DungeonGenerator.new()
	gen.rng.seed = current_seed + floor_num

	var result = gen.generate_dungeon(20, 15, params.wall_density)

	# Apply dungeon to turn system
	for pos in result.grid.keys():
		var tile = result.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	turn_system.set_player_position(result.player_spawn)

	# Add shard and exit
	if result.shard_position != Vector2i(-1, -1):
		turn_system.add_pickup(result.shard_position, "shard")
	if result.exit_position != Vector2i(-1, -1):
		turn_system.set_grid_tile(result.exit_position, "exit")

	# Create guard system
	guard_system = GuardSystem.new(current_seed + floor_num)
	guard_system.set_walkability_checker(turn_system.is_tile_walkable)

	# Add guards
	for i in range(params.guard_count):
		if i < result.guard_spawns.size():
			guard_system.add_guard(result.guard_spawns[i])

	turn_system.set_guard_system(guard_system)

	# Update HUD
	update_hud()

	# Add initial message
	message_log.add_message("Floor %d - Collect the Data Shard and reach the exit!" % floor_num, "info")
	if hud:
		hud.update_message_log()

## Restart the current floor
##
## Resets the current floor without changing progression. Useful for
## when the player presses the reset key.
func restart_floor() -> void:
	message_log.add_message("Restarting floor...", "info")
	start_floor()

## Process a player action and update the game state
##
## Executes the player's turn through the turn system and updates
## the HUD to reflect the new game state.
##
## Parameters:
##   action: The action to perform ("move", "wait", or "interact")
##   direction: Direction vector for movement or interaction
func process_player_action(action: String, direction: Vector2i) -> void:
	if turn_system.is_game_over():
		return

	# Execute the turn
	turn_system.execute_turn(action, direction)

	# Update display
	update_hud()

## Update the HUD with current game state
##
## Refreshes the HUD display with current stats (floor, turns, items)
## and renders the game grid with player and guard positions.
func update_hud() -> void:
	if not hud:
		return

	# Update stats
	if hud.has_method("set_game_state"):
		hud.set_game_state(get_game_state_dict())
	hud.update_display()

	# Render grid
	var guard_positions: Array[Vector2i] = []
	if guard_system:
		for guard in guard_system.guards:
			guard_positions.append(guard.position)

	var grid_bbcode = renderer.render_grid(
		turn_system.grid,
		turn_system.get_player_position(),
		guard_positions
	)

	hud.update_grid_display(grid_bbcode)

## Get a dictionary representing the current game state for the HUD
##
## Returns a dictionary of callable functions that the HUD can use
## to query current game state without direct coupling.
##
## Returns:
##   Dictionary: Game state accessor functions
func get_game_state_dict() -> Dictionary:
	return {
		"get_floor_number": func(): return progression_manager.get_current_floor() - 1,
		"get_turn_count": func(): return turn_system.get_turn_count(),
		"has_shard": func(): return turn_system.is_shard_collected(),
		"get_keycards": func(): return turn_system.get_keycard_count(),
		"get_score": func(): return 0  # TODO: Implement scoring
	}

## Called when a turn completes
##
## Updates the message log turn counter and refreshes the HUD.
##
## Parameters:
##   turn_number: The current turn number
func _on_turn_completed(turn_number: int) -> void:
	message_log.current_turn = turn_number
	update_hud()

## Called when the floor is completed (shard collected, exit reached)
##
## Advances floor progression or completes the run. Displays appropriate
## messages and either starts next floor or ends the game.
func _on_floor_complete() -> void:
	var result = progression_manager.complete_floor()

	if result == "won":
		# Run complete!
		message_log.add_message("RUN COMPLETE! You escaped with the data!", "success")
		game_active = false
		# TODO: Show victory screen
	else:
		# Advance to next floor
		message_log.add_message("Floor complete! Advancing to floor %d..." % progression_manager.get_current_floor(), "success")
		# Small delay then start next floor
		await get_tree().create_timer(2.0).timeout
		start_floor()

## Called when the game is lost (caught by guard)
##
## Displays failure message and deactivates the game. Player can
## press R to restart the floor.
func _on_game_lost() -> void:
	message_log.add_message("MISSION FAILED - Press R to restart", "failure")
	game_active = false
	# TODO: Show game over screen with restart option

## Called when the game generates a message
##
## Adds the message to the message log and updates the HUD display.
##
## Parameters:
##   text: The message text to display
##   type: The message type (for formatting/color)
func _on_message_generated(text: String, type: String) -> void:
	message_log.add_message(text, type)
	if hud:
		hud.update_message_log()
