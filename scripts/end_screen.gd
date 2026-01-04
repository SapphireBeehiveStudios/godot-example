extends Control
## EndScreen - Display run results and statistics
##
## Shows:
## - Run result (VICTORY! or CAUGHT!)
## - Final score and best score comparison
## - Seed used for the run
## - Buttons to restart or return to menu
##
## Part of EPIC 5 - Issue #38

## Emitted when player chooses to restart with the same seed
signal restart_run(seed: Variant)

## Emitted when player chooses to return to main menu
signal return_to_menu

## Reference to labels for updating
@onready var result_label: Label = get_node_or_null("%ResultLabel")
@onready var score_label: Label = get_node_or_null("%ScoreLabel")
@onready var best_score_label: Label = get_node_or_null("%BestScoreLabel")
@onready var new_best_label: Label = get_node_or_null("%NewBestLabel")
@onready var seed_label: Label = get_node_or_null("%SeedLabel")
@onready var turns_label: Label = get_node_or_null("%TurnsLabel")
@onready var floors_label: Label = get_node_or_null("%FloorsLabel")
@onready var keycards_label: Label = get_node_or_null("%KeycardsLabel")
@onready var guards_label: Label = get_node_or_null("%GuardsLabel")
@onready var play_time_label: Label = get_node_or_null("%PlayTimeLabel")

## Current run seed (for restart functionality)
var current_seed: Variant = 0

## SaveSystem instance for best score persistence
var save_system: RefCounted = null

## Best score file path
const BEST_SCORE_PATH: String = "user://best_score.json"

## Best run file path (Issue #95)
const BEST_RUN_PATH: String = "user://best_run.json"

func _ready() -> void:
	"""Initialize save system."""
	# Load SaveSystem dynamically
	var save_system_script = load("res://save_system.gd")
	if save_system_script:
		save_system = save_system_script.new()

func show_results(game_state: RefCounted, victory: bool) -> void:
	"""
	Display end screen with game results.

	Args:
		game_state: GameState object with run data
		victory: Whether player won (true) or was caught (false)
	"""
	# Set result text and color
	if result_label:
		if victory:
			result_label.text = "VICTORY!"
			result_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
		else:
			result_label.text = "CAUGHT!"
			result_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

	# Get final score
	var final_score: int = game_state.get_score()
	if score_label:
		score_label.text = "Score: %d" % final_score

	# Load and compare best score
	var best_score: int = load_best_score()
	var is_new_best: bool = final_score > best_score

	if is_new_best and final_score > 0:
		# New best score!
		best_score = final_score
		save_best_score(best_score)
		if new_best_label:
			new_best_label.visible = true
		if best_score_label:
			best_score_label.text = "Best: %d" % best_score
	else:
		# Show previous best
		if new_best_label:
			new_best_label.visible = false
		if best_score_label:
			best_score_label.text = "Best: %d" % best_score

	# Show seed
	current_seed = game_state.get_run_seed()
	if seed_label:
		seed_label.text = "Seed: %s" % str(current_seed)

	# Display detailed run statistics (Issue #95)
	if turns_label:
		turns_label.text = "Total Turns: %d" % game_state.get_turn_count()
	if floors_label:
		floors_label.text = "Floors Completed: %d" % game_state.get_floor_number()
	if keycards_label:
		keycards_label.text = "Keycards Collected: %d" % game_state.get_keycards()

	# Format guards statistic based on outcome
	if guards_label:
		if game_state.was_caught_by_guard():
			guards_label.text = "Guards Evaded: %d (caught)" % game_state.get_guards_evaded()
		else:
			guards_label.text = "Guards Evaded: %d" % game_state.get_guards_evaded()

	# Format play time
	var play_time_seconds = game_state.get_play_time_seconds()
	if play_time_label:
		play_time_label.text = format_time(play_time_seconds)

	# Save best run if this is a new best score (Issue #95)
	if is_new_best and final_score > 0:
		save_best_run(game_state)

	# Make screen visible
	visible = true

func load_best_score() -> int:
	"""
	Load best score from save file.

	Returns:
		Best score (0 if no save file exists)
	"""
	if save_system == null:
		push_warning("EndScreen: SaveSystem not loaded, cannot load best score")
		return 0

	var data: Dictionary = save_system.load(BEST_SCORE_PATH)
	return data.get("best_score", 0)

func save_best_score(score: int) -> bool:
	"""
	Save new best score to file.

	Args:
		score: New best score to save

	Returns:
		true if save succeeded, false otherwise
	"""
	if save_system == null:
		push_warning("EndScreen: SaveSystem not loaded, cannot save best score")
		return false

	var data: Dictionary = {"best_score": score}
	return save_system.save(data, BEST_SCORE_PATH)

func get_best_score() -> int:
	"""
	Get current best score.

	Returns:
		Best score (0 if no save file exists)
	"""
	return load_best_score()

func _on_restart_button_pressed() -> void:
	"""Handle restart button press - restart run with same seed."""
	restart_run.emit(current_seed)

func _on_menu_button_pressed() -> void:
	"""Handle menu button press - return to main menu."""
	return_to_menu.emit()

func format_time(seconds: int) -> String:
	"""
	Format time in seconds to readable format.

	Args:
		seconds: Time in seconds

	Returns:
		Formatted string (e.g., "2m 30s" or "45s")
	"""
	if seconds < 60:
		return "Time Played: %ds" % seconds
	else:
		var minutes = seconds / 60
		var remaining_seconds = seconds % 60
		return "Time Played: %dm %ds" % [minutes, remaining_seconds]

func save_best_run(game_state: RefCounted) -> bool:
	"""
	Save the best run statistics to file (Issue #95).

	Args:
		game_state: GameState object with run data

	Returns:
		true if save succeeded, false otherwise
	"""
	if save_system == null:
		push_warning("EndScreen: SaveSystem not loaded, cannot save best run")
		return false

	var run_data: Dictionary = {
		"score": game_state.get_score(),
		"turns": game_state.get_turn_count(),
		"floors": game_state.get_floor_number(),
		"keycards": game_state.get_keycards(),
		"guards_evaded": game_state.get_guards_evaded(),
		"caught_by_guard": game_state.was_caught_by_guard(),
		"play_time_seconds": game_state.get_play_time_seconds(),
		"seed": game_state.get_run_seed()
	}

	return save_system.save(run_data, BEST_RUN_PATH)

func load_best_run() -> Dictionary:
	"""
	Load the best run statistics from file (Issue #95).

	Returns:
		Dictionary with best run data, or empty Dictionary if no save exists
	"""
	if save_system == null:
		push_warning("EndScreen: SaveSystem not loaded, cannot load best run")
		return {}

	return save_system.load(BEST_RUN_PATH)
