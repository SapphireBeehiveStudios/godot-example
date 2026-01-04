extends RefCounted
## GameState - Core game state data
##
## Holds all persistent game state including:
## - Progress tracking (floor_number, turn_count)
## - Collectibles (keycards, shard)
## - Scoring (score)
## - Determinism (run_seed)
##
## This class is designed to be serializable for save/load functionality.
## Part of EPIC 1 - Issue #18

## Current floor number (0-based)
var floor_number: int = 0

## Total turns taken in current run
var turn_count: int = 0

## Number of keycards collected
var keycards: int = 0

## Whether the shard has been collected
var shard_collected: bool = false

## Current score
var score: int = 0

## Seed for deterministic random generation (can be String or int)
var run_seed: Variant = 0

func _init(seed_value: Variant = 0) -> void:
	"""Initialize game state with optional seed."""
	run_seed = seed_value

func reset() -> void:
	"""Reset all state to defaults."""
	floor_number = 0
	turn_count = 0
	keycards = 0
	shard_collected = false
	score = 0
	run_seed = 0

func add_keycard(amount: int = 1) -> void:
	"""Add keycards to inventory."""
	keycards += amount

func collect_shard() -> void:
	"""Mark the shard as collected."""
	shard_collected = true

func increment_turn() -> void:
	"""Increment the turn counter."""
	turn_count += 1

func advance_floor() -> void:
	"""Advance to the next floor."""
	floor_number += 1

func add_score(points: int) -> void:
	"""Add points to the score."""
	score += points

func to_dict() -> Dictionary:
	"""
	Convert game state to a Dictionary for serialization.
	Returns a dictionary with all state variables.
	"""
	return {
		"floor_number": floor_number,
		"turn_count": turn_count,
		"keycards": keycards,
		"shard_collected": shard_collected,
		"score": score,
		"run_seed": run_seed
	}

func from_dict(data: Dictionary) -> void:
	"""
	Load game state from a Dictionary (for deserialization).
	Args:
		data: Dictionary containing state data
	"""
	floor_number = data.get("floor_number", 0)
	turn_count = data.get("turn_count", 0)
	keycards = data.get("keycards", 0)
	shard_collected = data.get("shard_collected", false)
	score = data.get("score", 0)
	run_seed = data.get("run_seed", 0)

func get_floor_number() -> int:
	"""Get the current floor number."""
	return floor_number

func get_turn_count() -> int:
	"""Get the total turn count."""
	return turn_count

func get_keycards() -> int:
	"""Get the number of keycards."""
	return keycards

func has_shard() -> bool:
	"""Check if the shard has been collected."""
	return shard_collected

func get_score() -> int:
	"""Get the current score."""
	return score

func get_run_seed() -> Variant:
	"""Get the run seed."""
	return run_seed
