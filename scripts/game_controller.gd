extends Node
## GameController - Main game orchestrator
##
## Coordinates all game systems:
## - Menu -> Game transitions
## - Level generation
## - Turn system
## - Guard AI
## - HUD rendering
## - Win/loss flow
##
## Fixes Issue #87 - Make the game playable through UI

# System references
const GameState = preload("res://game_state.gd")
const TurnSystem = preload("res://scripts/turn_system.gd")
const LevelGen = preload("res://scripts/level_gen.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const Renderer = preload("res://scripts/renderer.gd")
const RunProgressionManager = preload("res://scripts/run_progression_manager.gd")
const GameConfig = preload("res://resources/game_config.gd")

# Scene references
@onready var main_menu: Control = $MainMenu
@onready var hud: CanvasLayer = $HUD
@onready var end_screen: Control = $EndScreen

# Game state
var game_state: GameState = null
var turn_system: TurnSystem = null
var guard_system: GuardSystem = null
var renderer: Renderer = Renderer.new()
var run_manager: RunProgressionManager = null

# Game flow state
var in_game: bool = false

func _ready() -> void:
	# Initial state: show menu, hide game
	main_menu.visible = true
	hud.visible = false
	if end_screen:
		end_screen.visible = false

	# Connect menu signal
	main_menu.start_run_requested.connect(_on_start_run_requested)

	# Connect end screen signals
	if end_screen:
		end_screen.restart_run.connect(_on_restart_run)
		end_screen.return_to_menu.connect(_on_return_to_menu)

func _on_start_run_requested(seed_value: Variant) -> void:
	"""Start a new game run with the given seed."""
	print("Starting new run with seed: %s" % str(seed_value))

	# Convert seed to int if needed
	var seed_int: int
	if seed_value is String:
		seed_int = hash(seed_value)
	else:
		seed_int = int(seed_value)

	# Initialize game state
	game_state = GameState.new(seed_int)
	game_state.set_run_seed(seed_int)

	# Initialize run manager
	var config = GameConfig.new()
	run_manager = RunProgressionManager.new(
		seed_int,
		config.grid_width,
		config.grid_height
	)

	# Start first floor
	start_floor()

	# Hide menu, show game
	main_menu.visible = false
	hud.visible = true
	in_game = true

func start_floor() -> void:
	"""Generate and start a new floor."""
	if not game_state or not run_manager:
		push_error("Cannot start floor - game state not initialized")
		return

	print("Starting floor %d" % (run_manager.get_current_floor()))

	# Get floor difficulty
	var difficulty = run_manager.get_current_difficulty()
	var floor_seed = game_state.get_run_seed() * 1000 + run_manager.get_current_floor()

	# Generate level
	var config = GameConfig.new()
	var level_result = LevelGen.generate(
		config.grid_width,
		config.grid_height,
		floor_seed,
		difficulty.wall_density,
		difficulty.guard_count,
		false,  # place_keycard - not used in current game
		false   # place_door - not used in current game
	)

	if not level_result.success:
		push_error("Failed to generate level: %s" % level_result.error_message)
		return

	# Initialize turn system
	turn_system = TurnSystem.new(floor_seed)
	turn_system.grid = level_result.grid
	turn_system.player_position = level_result.player_start

	# Initialize guard system
	guard_system = GuardSystem.new()
	guard_system.initialize(
		level_result.guard_spawn_positions,
		level_result.grid,
		floor_seed
	)

	# Link systems
	turn_system.guard_system = guard_system

	# Connect turn system signals
	turn_system.turn_completed.connect(_on_turn_completed)
	turn_system.game_won.connect(_on_game_won)
	turn_system.game_lost.connect(_on_game_lost)
	turn_system.message_generated.connect(_on_message_generated)

	# Initialize HUD
	hud.set_game_state(game_state)
	hud.set_message_log(game_state.get_message_log())

	# Initial render
	update_display()

	# Add start message
	game_state.add_message("Floor %d - Find the shard ($) and reach the exit (>)!" % run_manager.get_current_floor(), "system")
	hud.update_display()

func _input(event: InputEvent) -> void:
	"""Handle player input during gameplay."""
	if not in_game or not turn_system:
		return

	if turn_system.game_over:
		return

	var direction := Vector2i.ZERO
	var action_taken := false

	# Movement input
	if event.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
		action_taken = true
	elif event.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)
		action_taken = true
	elif event.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
		action_taken = true
	elif event.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)
		action_taken = true
	elif event.is_action_pressed("confirm"):
		# Wait/pass turn
		turn_system.process_turn(Vector2i.ZERO)
		action_taken = true
	elif event.is_action_pressed("reset"):
		# Quick restart with same seed
		if game_state:
			var seed = game_state.get_run_seed()
			_on_start_run_requested(seed)
		return

	if action_taken and direction != Vector2i.ZERO:
		turn_system.process_turn(direction)

func _on_turn_completed(turn_number: int) -> void:
	"""Called when a turn completes."""
	game_state.increment_turn()
	hud.on_turn_completed(turn_number)
	update_display()

func _on_message_generated(text: String, type: String) -> void:
	"""Called when game generates a message."""
	game_state.add_message(text, type)
	hud.on_message_generated(text, type)

func update_display() -> void:
	"""Update the visual display."""
	if not turn_system or not hud:
		return

	# Render grid
	var guard_positions: Array[Vector2i] = []
	if guard_system:
		guard_positions = guard_system.get_guard_positions()

	var grid_bbcode = renderer.render_grid(
		turn_system.grid,
		turn_system.player_position,
		guard_positions
	)

	hud.update_grid_display(grid_bbcode)
	hud.update_display()

func _on_game_won() -> void:
	"""Called when floor is completed."""
	print("Floor %d complete!" % run_manager.get_current_floor())

	# Award points
	var floor_bonus = 1000 * run_manager.get_current_floor()
	game_state.add_score(floor_bonus)

	# Check if run is complete
	var result = run_manager.complete_floor()

	if result == "won":
		# Won entire run!
		show_end_screen(true, "Victory! You completed all %d floors!\n\nFinal Score: %d" % [
			RunProgressionManager.TOTAL_FLOORS,
			game_state.get_score()
		])
	else:
		# Continue to next floor
		game_state.advance_floor()
		game_state.reset_floor()
		start_floor()

func _on_game_lost() -> void:
	"""Called when player is caught."""
	print("Game Over!")
	show_end_screen(false, "Captured by guards!\n\nReached Floor: %d\nFinal Score: %d" % [
		run_manager.get_current_floor(),
		game_state.get_score()
	])

func show_end_screen(victory: bool, message: String) -> void:
	"""Show the end screen with results."""
	in_game = false
	hud.visible = false

	if end_screen and game_state:
		end_screen.show_results(game_state, victory)
	else:
		# Fallback if no end screen - just show menu
		print(message)
		main_menu.visible = true

func _on_restart_run(seed_value: Variant) -> void:
	"""Restart with same seed (from end screen)."""
	_on_start_run_requested(seed_value)

func _on_return_to_menu() -> void:
	"""Return to main menu (from end screen)."""
	in_game = false
	hud.visible = false
	if end_screen:
		end_screen.visible = false
	main_menu.visible = true

	# Clean up
	game_state = null
	turn_system = null
	guard_system = null
	run_manager = null
