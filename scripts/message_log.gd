extends RefCounted
## MessageLog - In-run message history
##
## Manages a rolling log of game events and messages:
## - Pickups, doors, exits, guards, etc.
## - Color-coded by message type
## - Serializable for save/load
##
## Part of EPIC 5 - Issue #36

## Maximum number of messages to retain in memory
const MAX_MESSAGES: int = 100

## Message type colors (for UI rendering)
const COLORS: Dictionary = {
	"pickup": "yellow",
	"exit": "cyan",
	"door": "blue",
	"guard": "red",
	"info": "white",
	"success": "green",
	"failure": "orange"
}

## Message data structure: Array of {text: String, type: String, turn: int}
var messages: Array[Dictionary] = []

## Current turn number (for timestamping messages)
var current_turn: int = 0

func add_message(text: String, type: String = "info", turn_override: int = -1) -> void:
	"""
	Add a message to the log.

	Args:
		text: The message text
		type: Message type for color coding (pickup, exit, door, guard, info, success, failure)
		turn_override: Optional turn number override (uses current_turn if -1)
	"""
	var turn = turn_override if turn_override >= 0 else current_turn

	messages.append({
		"text": text,
		"type": type,
		"turn": turn
	})

	# Limit message history to prevent unbounded growth
	if messages.size() > MAX_MESSAGES:
		messages.pop_front()

func get_recent_messages(count: int = 10) -> Array[Dictionary]:
	"""
	Get the N most recent messages.

	Args:
		count: Number of recent messages to retrieve

	Returns:
		Array of message dictionaries
	"""
	var start_index = max(0, messages.size() - count)
	return messages.slice(start_index)

func get_all_messages() -> Array[Dictionary]:
	"""Get all messages in the log."""
	return messages.duplicate()

func clear() -> void:
	"""Clear all messages from the log."""
	messages.clear()
	current_turn = 0

func set_turn(turn: int) -> void:
	"""Update the current turn number."""
	current_turn = turn

func to_bbcode(recent_count: int = 10) -> String:
	"""
	Convert recent messages to BBCode format for RichTextLabel.

	Args:
		recent_count: Number of recent messages to include

	Returns:
		BBCode-formatted string
	"""
	var recent = get_recent_messages(recent_count)
	var bbcode_lines: Array[String] = []

	for msg in recent:
		var color = COLORS.get(msg.type, "white")
		var turn_str = "[color=gray][T%d][/color] " % msg.turn
		var text_str = "[color=%s]%s[/color]" % [color, msg.text]
		bbcode_lines.append(turn_str + text_str)

	return "\n".join(bbcode_lines)

func to_plain_text(recent_count: int = 10) -> String:
	"""
	Convert recent messages to plain text.

	Args:
		recent_count: Number of recent messages to include

	Returns:
		Plain text string
	"""
	var recent = get_recent_messages(recent_count)
	var lines: Array[String] = []

	for msg in recent:
		lines.append("[T%d] %s" % [msg.turn, msg.text])

	return "\n".join(lines)

func to_dict() -> Dictionary:
	"""
	Convert message log to a Dictionary for serialization.

	Returns:
		Dictionary with messages and current_turn
	"""
	return {
		"messages": messages.duplicate(),
		"current_turn": current_turn
	}

func from_dict(data: Dictionary) -> void:
	"""
	Load message log from a Dictionary (for deserialization).

	Args:
		data: Dictionary containing message log data
	"""
	messages = data.get("messages", []).duplicate()
	current_turn = data.get("current_turn", 0)

func get_message_count() -> int:
	"""Get the total number of messages in the log."""
	return messages.size()
