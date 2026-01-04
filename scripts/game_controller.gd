extends Node
## GameController - Main game orchestrator with scoring and smart guards

const TurnSystem = preload("res://scripts/turn_system.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const LevelGen = preload("res://scripts/level_gen.gd")
const Renderer = preload("res://scripts/renderer.gd")
const MessageLog = preload("res://scripts/message_log.gd")
const RunProgressionManager = preload("res://scripts/run_progression_manager.gd")

## Game systems
var turn_system: TurnSystem = null
var guard_system: GuardSystem = null
var renderer: Renderer = null
var message_log: MessageLog = null
var progression_manager: RunProgressionManager = null

## Score tracking
var score: int = 0
var floor_start_turns: int = 0

## Score constants
const FLOOR_COMPLETE_BONUS := 500
const SHARD_BONUS := 100
const TURN_PENALTY := 2
const STEALTH_BONUS := 50  ## Bonus for completing without being spotted

## Was player spotted this floor?
var was_spotted: bool = false

@onready var hud = $HUD
var menu: Control = null
var current_seed: int = 0
var game_active: bool = false

func _ready() -> void:
	menu = get_node("../MainMenu")
	if hud:
		hud.visible = false

func _on_start_run_requested(seed_value: Variant) -> void:
	if menu:
		menu.visible = false
	start_game(seed_value)

func _input(event: InputEvent) -> void:
	if not game_active:
		return

	if event.is_action_pressed("reset"):
		restart_floor()
		get_viewport().set_input_as_handled()
		return

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
	if seed_value is String:
		current_seed = hash(seed_value)
	else:
		current_seed = seed_value

	print("Starting game with seed: %d" % current_seed)

	renderer = Renderer.new()
	message_log = MessageLog.new()
	progression_manager = RunProgressionManager.new(current_seed)
	score = 0

	start_floor()

	if hud:
		hud.visible = true
		hud.set_message_log(message_log)

	game_active = true

func start_floor() -> void:
	var floor_num = progression_manager.get_current_floor()
	print("Starting floor %d" % floor_num)

	was_spotted = false
	floor_start_turns = 0 if turn_system == null else turn_system.get_turn_count()

	turn_system = TurnSystem.new(current_seed + floor_num)
	turn_system.turn_completed.connect(_on_turn_completed)
	turn_system.game_won.connect(_on_floor_complete)
	turn_system.game_lost.connect(_on_game_lost)
	turn_system.message_generated.connect(_on_message_generated)

	var params = progression_manager.get_current_difficulty()
	var result = LevelGen.generate(20, 15, current_seed + floor_num, params.wall_density, params.guard_count)

	if not result.success:
		push_error("Level generation failed: " + result.error_message)
		return

	for pos in result.grid.keys():
		var tile = result.grid[pos]
		turn_system.set_grid_tile(pos, tile.type, tile)

	turn_system.set_player_position(result.player_start)

	# Create guard system with vision
	guard_system = GuardSystem.new(current_seed + floor_num)
	guard_system.set_walkability_checker(turn_system.is_tile_walkable)
	guard_system.set_line_of_sight_checker(_check_line_of_sight)
	guard_system.message_generated.connect(_on_message_generated)

	for guard_pos in result.guard_spawn_positions:
		guard_system.add_guard(guard_pos)

	turn_system.set_guard_system(guard_system)

	update_hud()

	var guard_info = "guard" if params.guard_count == 1 else "guards"
	message_log.add_message("Floor %d - %d %s patrolling. Find the shard!" % [floor_num, params.guard_count, guard_info], "info")
	if hud:
		hud.update_message_log()

func _check_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	"""Bresenham line check - returns true if clear LOS"""
	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y

	var dx = absi(x1 - x0)
	var dy = absi(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	while true:
		# Skip start position
		if not (x0 == from.x and y0 == from.y):
			# Check if blocked
			var pos = Vector2i(x0, y0)
			if pos == to:
				return true  # Reached target
			var tile = turn_system.get_grid_tile(pos)
			if tile.type == "wall" or tile.type == "door_closed":
				return false  # Blocked

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return true

func restart_floor() -> void:
	message_log.add_message("Restarting floor...", "info")
	score = maxi(0, score - 100)  # Penalty for restart
	start_floor()

func process_player_action(action: String, direction: Vector2i) -> void:
	if turn_system.is_game_over():
		return

	# Update guard's knowledge of player position BEFORE they move
	guard_system.update_player_position(turn_system.get_player_position())

	turn_system.execute_turn(action, direction)

	# Check if player was spotted
	var guard_result = guard_system.process_guard_phase()
	if guard_result.get("player_spotted", false):
		was_spotted = true

	update_hud()

func update_hud() -> void:
	if not hud:
		return

	if hud.has_method("set_game_state"):
		hud.set_game_state(get_game_state_dict())
	hud.update_display()

	# Pass guard states to renderer for alert visualization
	if guard_system:
		renderer.set_guard_states(guard_system.get_guard_states())

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
	return {
		"get_floor_number": func(): return progression_manager.get_current_floor(),
		"get_turn_count": func(): return turn_system.get_turn_count(),
		"has_shard": func(): return turn_system.is_shard_collected(),
		"get_keycards": func(): return turn_system.get_keycard_count(),
		"get_score": func(): return score
	}

func _on_turn_completed(turn_number: int) -> void:
	message_log.current_turn = turn_number
	update_hud()

func _on_floor_complete() -> void:
	# Calculate floor score
	var turns_used = turn_system.get_turn_count()
	var floor_score = FLOOR_COMPLETE_BONUS + SHARD_BONUS - (turns_used * TURN_PENALTY)
	if not was_spotted:
		floor_score += STEALTH_BONUS
		message_log.add_message("STEALTH BONUS! +%d" % STEALTH_BONUS, "success")

	score += maxi(floor_score, 50)  # Minimum 50 points per floor

	var result = progression_manager.complete_floor()

	message_log.add_message("Floor complete! +%d points" % floor_score, "success")
	message_log.add_message("Advancing to floor %d..." % progression_manager.get_current_floor(), "info")

	# Quick transition
	await get_tree().create_timer(0.8).timeout
	start_floor()

func _on_game_lost() -> void:
	var floor_num = progression_manager.get_current_floor()
	message_log.add_message("CAUGHT! Floor %d - Score: %d - Press R to retry" % [floor_num, score], "failure")
	game_active = false

func _on_message_generated(text: String, type: String) -> void:
	message_log.add_message(text, type)
	if hud:
		hud.update_message_log()
