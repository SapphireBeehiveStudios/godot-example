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
const AudioManager = preload("res://scripts/audio_manager.gd")

## Game systems
var turn_system: TurnSystem = null
var guard_system: GuardSystem = null
var renderer: Renderer = null
var message_log: MessageLog = null
var progression_manager: RunProgressionManager = null
var audio_manager: AudioManager = null

## HUD reference
@onready var hud = $HUD

## Help overlay reference
@onready var help_overlay = $HelpOverlay

## Menu reference
var menu: Control = null

## Current run seed
var current_seed: int = 0

## Game state tracking
var game_active: bool = false

func _ready() -> void:
	"""Initialize the game controller."""
	# Get menu reference
	menu = get_node("../MainMenu")

	# Initialize audio manager
	audio_manager = AudioManager.new()
	add_child(audio_manager)

	# Hide HUD initially
	if hud:
		hud.visible = false

func _on_start_run_requested(seed_value: Variant) -> void:
	"""Called when the player starts a run from the menu."""
	# Hide menu
	if menu:
		menu.visible = false

	# Start the game
	start_game(seed_value)

func _input(event: InputEvent) -> void:
	"""Handle game input."""
	# Help overlay can be toggled anytime during gameplay
	if event.is_action_pressed("help"):
		if help_overlay:
			help_overlay.toggle_visibility()
		get_viewport().set_input_as_handled()
		return

	# Sound toggle can be triggered anytime (Issue #89)
	if event.is_action_pressed("toggle_sound"):
		if audio_manager:
			audio_manager.toggle_sounds()
			var status = "ON" if audio_manager.is_sounds_enabled() else "OFF"
			if message_log:
				message_log.add_message("Sound effects: %s" % status, "info")
			if hud:
				hud.update_message_log()
		get_viewport().set_input_as_handled()
		return

	if not game_active:
		return

	# Don't process game input if help overlay is visible
	if help_overlay and help_overlay.is_visible_overlay():
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

func start_game(seed_value: Variant) -> void:
	"""Start a new game with the given seed."""
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

func start_floor() -> void:
	"""Start/restart the current floor."""
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

func restart_floor() -> void:
	"""Restart the current floor."""
	message_log.add_message("Restarting floor...", "info")
	start_floor()

func process_player_action(action: String, direction: Vector2i) -> void:
	"""Process a player action and update the game state."""
	if turn_system.is_game_over():
		return

	# Track previous state for sound effects
	var had_shard_before = turn_system.is_shard_collected()
	var keycard_count_before = turn_system.get_keycard_count()
	var player_pos_before = turn_system.get_player_position()

	# Execute the turn
	var action_succeeded = turn_system.execute_turn(action, direction)

	# Play appropriate sound effects (Issue #89)
	if audio_manager:
		match action:
			"move":
				if action_succeeded:
					# Player moved successfully
					audio_manager.play_movement()
					# Check for pickups
					if turn_system.is_shard_collected() and not had_shard_before:
						audio_manager.play_pickup()
					elif turn_system.get_keycard_count() > keycard_count_before:
						audio_manager.play_pickup()
			"interact":
				if action_succeeded:
					# Door was opened
					audio_manager.play_door()
			"wait":
				# No sound for waiting

	# Update display
	update_hud()

func update_hud() -> void:
	"""Update the HUD with current game state."""
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

func get_game_state_dict() -> Dictionary:
	"""Get a dictionary representing the current game state for the HUD."""
	return {
		"get_floor_number": func(): return progression_manager.get_current_floor() - 1,
		"get_turn_count": func(): return turn_system.get_turn_count(),
		"has_shard": func(): return turn_system.is_shard_collected(),
		"get_keycards": func(): return turn_system.get_keycard_count(),
		"get_score": func(): return 0  # TODO: Implement scoring
	}

func _on_turn_completed(turn_number: int) -> void:
	"""Called when a turn completes."""
	message_log.current_turn = turn_number
	update_hud()

func _on_floor_complete() -> void:
	"""Called when the floor is completed (shard collected, exit reached)."""
	var result = progression_manager.complete_floor()

	# Play win sound (Issue #89)
	if audio_manager:
		audio_manager.play_win()

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

func _on_game_lost() -> void:
	"""Called when the game is lost (caught by guard)."""
	# Play capture sound (Issue #89)
	if audio_manager:
		audio_manager.play_capture()

	# Flash screen red (Issue #90)
	if hud and hud.has_method("flash_red"):
		hud.flash_red()

	message_log.add_message("MISSION FAILED - Press R to restart", "failure")
	game_active = false
	# TODO: Show game over screen with restart option

func _on_message_generated(text: String, type: String) -> void:
	"""Called when the game generates a message."""
	message_log.add_message(text, type)
	if hud:
		hud.update_message_log()
