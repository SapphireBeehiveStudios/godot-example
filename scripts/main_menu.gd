extends Control
## Main Menu
##
## Handles the main menu UI with:
## - Start Run button
## - Seed entry (optional, blank generates random)
## - Controls view
## - Quit button
##
## Part of issue #37 - EPIC 5

signal start_run_requested(seed_value: Variant)

@onready var seed_input: LineEdit = $VBoxContainer/SeedInput
@onready var controls_panel: Panel = $ControlsPanel

## Initialize the main menu
##
## Hides the controls panel on startup.
func _ready() -> void:
	# Hide controls panel initially
	controls_panel.visible = false

## Handle start button press
##
## Processes the seed input and emits start_run_requested signal.
## If seed input is empty, generates a random seed. Otherwise, parses
## the input as an integer or uses it as a string seed.
func _on_start_button_pressed() -> void:
	var seed_text = seed_input.text.strip_edges()
	var seed_value: Variant

	if seed_text.is_empty():
		# Generate random seed
		seed_value = generate_random_seed()
		print("Generated random seed: %s" % str(seed_value))
	else:
		# Try to parse as integer, otherwise use as string
		if seed_text.is_valid_int():
			seed_value = seed_text.to_int()
		else:
			seed_value = seed_text
		print("Using provided seed: %s" % str(seed_value))

	# Emit signal with the seed
	start_run_requested.emit(seed_value)

## Handle controls button press
##
## Shows the controls panel overlay.
func _on_controls_button_pressed() -> void:
	controls_panel.visible = true

## Handle close button press
##
## Hides the controls panel overlay.
func _on_close_button_pressed() -> void:
	controls_panel.visible = false

## Handle quit button press
##
## Exits the application.
func _on_quit_button_pressed() -> void:
	get_tree().quit()

## Generate a random seed value
##
## Creates a unique seed by combining current system time components
## (year, month, day, hour, minute, second) with additional randomness.
##
## Returns:
##   int: A unique seed value based on current timestamp
func generate_random_seed() -> int:
	# Use OS time to generate a unique seed
	var time_dict = Time.get_datetime_dict_from_system()
	# Combine date/time components into a seed
	var seed_val = time_dict.year * 10000000000
	seed_val += time_dict.month * 100000000
	seed_val += time_dict.day * 1000000
	seed_val += time_dict.hour * 10000
	seed_val += time_dict.minute * 100
	seed_val += time_dict.second

	# Add some randomness from random number generator
	randomize()
	seed_val += randi() % 1000

	return seed_val

## Get the current seed input value (for testing)
##
## Returns:
##   String: The current text in the seed input field
func get_seed_input() -> String:
	return seed_input.text

## Set the seed input value (for testing)
##
## Parameters:
##   value: The text to set in the seed input field
func set_seed_input(value: String) -> void:
	seed_input.text = value
