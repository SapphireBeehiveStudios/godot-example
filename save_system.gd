extends RefCounted
## SaveSystem - JSON-based persistence for game state
##
## Handles saving and loading game state to/from JSON files.
## Features:
## - Graceful handling of missing files (returns defaults)
## - Corrupt file detection and fallback
## - Simple API: load() and save(data)
##
## Part of EPIC 6 - Issue #40

## Default save file path
const DEFAULT_SAVE_PATH: String = "user://savegame.json"

## Save game state to JSON file
##
## Args:
##   data: Dictionary containing the game state to save
##   path: Optional custom save file path (defaults to DEFAULT_SAVE_PATH)
##
## Returns:
##   true if save succeeded, false otherwise
func save(data: Dictionary, path: String = DEFAULT_SAVE_PATH) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: Failed to open file for writing: %s (Error: %d)" % [path, FileAccess.get_open_error()])
		return false

	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

	return true

## Load game state from JSON file
##
## Args:
##   path: Optional custom save file path (defaults to DEFAULT_SAVE_PATH)
##
## Returns:
##   Dictionary containing the loaded game state, or empty Dictionary if:
##   - File doesn't exist (graceful fallback - returns defaults)
##   - File is corrupt (fallback with warning message)
func load(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	# Check if file exists - if not, return empty dict (defaults)
	if not FileAccess.file_exists(path):
		push_warning("SaveSystem: Save file not found at %s - returning defaults" % path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: Failed to open file for reading: %s (Error: %d)" % [path, FileAccess.get_open_error()])
		return {}

	var json_string = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("SaveSystem: Corrupt save file detected at %s (JSON parse error at line %d) - returning defaults" % [path, json.get_error_line()])
		return {}

	var data = json.get_data()

	# Validate that we got a Dictionary
	if not data is Dictionary:
		push_error("SaveSystem: Corrupt save file at %s - expected Dictionary, got %s - returning defaults" % [path, type_string(typeof(data))])
		return {}

	return data

## Delete save file
##
## Args:
##   path: Optional custom save file path (defaults to DEFAULT_SAVE_PATH)
##
## Returns:
##   true if deletion succeeded or file didn't exist, false otherwise
func delete_save(path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true  # Already doesn't exist

	var err = DirAccess.remove_absolute(path)
	if err != OK:
		push_error("SaveSystem: Failed to delete save file: %s (Error: %d)" % [path, err])
		return false

	return true

## Check if save file exists
##
## Args:
##   path: Optional custom save file path (defaults to DEFAULT_SAVE_PATH)
##
## Returns:
##   true if save file exists, false otherwise
func save_exists(path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)
