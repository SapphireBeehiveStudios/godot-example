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
@onready var result_label: Label = %ResultLabel
@onready var score_label: Label = %ScoreLabel
@onready var best_score_label: Label = %BestScoreLabel
@onready var new_best_label: Label = %NewBestLabel
@onready var seed_label: Label = %SeedLabel

## Current run seed (for restart functionality)
var current_seed: Variant = 0

## SaveSystem instance for best score persistence
var save_system: RefCounted = null

## Best score file path
const BEST_SCORE_PATH: String = "user://best_score.json"

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
	if victory:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	else:
		result_label.text = "CAUGHT!"
		result_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

	# Get final score
	var final_score: int = game_state.get_score()
	score_label.text = "Score: %d" % final_score

	# Load and compare best score
	var best_score: int = load_best_score()
	var is_new_best: bool = final_score > best_score

	if is_new_best and final_score > 0:
		# New best score!
		best_score = final_score
		save_best_score(best_score)
		new_best_label.visible = true
		best_score_label.text = "Best: %d" % best_score
	else:
		# Show previous best
		new_best_label.visible = false
		best_score_label.text = "Best: %d" % best_score

	# Show seed
	current_seed = game_state.get_run_seed()
	seed_label.text = "Seed: %s" % str(current_seed)

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
