extends CanvasLayer
## HUD - In-run heads-up display
##
## Displays:
## - Floor number, turn count, inventory, score
## - Message log with recent events
##
## Part of EPIC 5 - Issue #36

const MessageLog = preload("res://scripts/message_log.gd")

## Reference to the message log data (set externally)
var message_log: MessageLog = null

## Reference to game state (set externally)
var game_state = null

## UI node references
@onready var floor_label: Label = $MarginContainer/VBoxContainer/TopBar/FloorLabel
@onready var turn_label: Label = $MarginContainer/VBoxContainer/TopBar/TurnLabel
@onready var inventory_label: Label = $MarginContainer/VBoxContainer/TopBar/InventoryLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var grid_display: RichTextLabel = $MarginContainer/VBoxContainer/GridDisplay
@onready var message_log_display: RichTextLabel = $MarginContainer/VBoxContainer/MessageLog

func _ready() -> void:
	"""Initialize the HUD."""
	update_display()

func set_message_log(log: MessageLog) -> void:
	"""Set the message log reference."""
	message_log = log
	update_message_log()

func set_game_state(state) -> void:
	"""Set the game state reference."""
	game_state = state
	update_display()

func update_display() -> void:
	"""Update all HUD elements."""
	update_stats()
	update_message_log()

func update_stats() -> void:
	"""Update the stats bar (floor, turn, inventory, score)."""
	if game_state == null:
		floor_label.text = "Floor: ?"
		turn_label.text = "Turn: ?"
		inventory_label.text = "Keycards: ? | Shard: ?"
		score_label.text = "Score: ?"
		return

	floor_label.text = "Floor: %d" % game_state["get_floor_number"].call()
	turn_label.text = "Turn: %d" % game_state["get_turn_count"].call()

	var shard_text = "◆ SHARD" if game_state["has_shard"].call() else "No Shard"
	inventory_label.text = shard_text

	score_label.text = "Score: %d" % game_state["get_score"].call()

func update_message_log() -> void:
	"""Update the message log display."""
	if message_log == null:
		message_log_display.text = "[color=gray]No messages yet...[/color]"
		return

	var bbcode = message_log.to_bbcode(10)  # Show last 10 messages
	if bbcode.is_empty():
		message_log_display.text = "[color=gray]No messages yet...[/color]"
	else:
		message_log_display.text = bbcode

func add_message(text: String, type: String = "info") -> void:
	"""
	Add a message to the log and update display.

	Args:
		text: The message text
		type: Message type for color coding
	"""
	if message_log != null:
		message_log.add_message(text, type)
		update_message_log()

func on_turn_completed(turn_number: int) -> void:
	"""
	Called when a turn completes.

	Args:
		turn_number: The turn that just completed
	"""
	update_display()

func on_message_generated(text: String, type: String) -> void:
	"""
	Called when a game event generates a message.

	Args:
		text: The message text
		type: Message type for color coding
	"""
	add_message(text, type)

func update_grid_display(grid_text: String) -> void:
	"""
	Update the grid display area.

	Args:
		grid_text: BBCode-formatted grid text
	"""
	grid_display.text = grid_text
