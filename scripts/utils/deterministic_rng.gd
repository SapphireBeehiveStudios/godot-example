## Deterministic RNG Utility
##
## Provides consistent random number generation based on a run seed and floor index.
## Ensures reproducibility across platforms and headless runs.
##
## Usage:
##   var rng = DeterministicRNG.new()
##   rng.seed_from_run_and_floor("my_run_seed", 5)
##   var random_value = rng.randf()
##
## Seed Format:
##   - String seeds are converted to integer hashes (FNV-1a algorithm)
##   - Integer seeds are used directly
##   - Floor index is XORed with the base seed to create unique per-floor RNG
##
## Thread Safety:
##   - Each instance maintains its own RNG state
##   - Safe to use multiple instances concurrently
##

class_name DeterministicRNG
extends RefCounted

## The internal RandomNumberGenerator instance
var _rng: RandomNumberGenerator

## The current run seed (as integer)
var _run_seed: int = 0

## The current floor index
var _floor_index: int = 0

## The combined seed (run_seed XOR floor_index)
var _combined_seed: int = 0


func _init() -> void:
	_rng = RandomNumberGenerator.new()


## Seeds the RNG from a run seed and floor index.
##
## This is the primary way to initialize deterministic RNG for a specific floor.
## The same run_seed and floor_index will always produce the same sequence.
##
## Parameters:
##   run_seed: String or int - the seed for this run
##   floor_index: int - the current floor number (0-based)
func seed_from_run_and_floor(run_seed: Variant, floor_index: int) -> void:
	_floor_index = floor_index

	# Convert string seeds to integers using hash
	if run_seed is String:
		_run_seed = _hash_string_to_int(run_seed)
	elif run_seed is int:
		_run_seed = run_seed
	else:
		push_error("DeterministicRNG: run_seed must be String or int, got %s" % typeof(run_seed))
		_run_seed = 0

	# Combine run seed and floor index for unique per-floor RNG
	# Using XOR allows floor 0 to use the base seed directly
	_combined_seed = _run_seed ^ floor_index

	# Seed the internal RNG
	# In Godot, setting seed also initializes state, but we recreate for safety
	_rng = RandomNumberGenerator.new()
	_rng.seed = _combined_seed
	# Explicitly set state to match seed for determinism
	_rng.state = _combined_seed


## Returns the current combined seed value.
func get_combined_seed() -> int:
	return _combined_seed


## Returns the current run seed value (as integer).
func get_run_seed() -> int:
	return _run_seed


## Returns the current floor index.
func get_floor_index() -> int:
	return _floor_index


## Returns a random float between 0.0 (inclusive) and 1.0 (exclusive).
func randf() -> float:
	return _rng.randf()


## Returns a random float in the range [from, to].
func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## Returns a random integer between 0 (inclusive) and to (exclusive).
func randi() -> int:
	return _rng.randi()


## Returns a random integer in the range [from, to].
func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Randomizes the array in-place using the current RNG state.
func shuffle_array(array: Array) -> void:
	# Fisher-Yates shuffle using our deterministic RNG
	for i in range(array.size() - 1, 0, -1):
		var j = randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp


## Returns a random element from the array, or null if empty.
func pick_random(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi_range(0, array.size() - 1)]


## Returns a random weighted element from the array.
##
## Each element should be a Dictionary with "item" and "weight" keys.
## Higher weights are more likely to be chosen.
##
## Example:
##   var items = [
##     {"item": "common", "weight": 10},
##     {"item": "rare", "weight": 2},
##     {"item": "legendary", "weight": 1}
##   ]
##   var result = rng.pick_weighted(items)
func pick_weighted(weighted_items: Array) -> Variant:
	if weighted_items.is_empty():
		return null

	# Calculate total weight
	var total_weight: float = 0.0
	for item in weighted_items:
		if item is Dictionary and item.has("weight"):
			total_weight += float(item.weight)

	if total_weight <= 0.0:
		return null

	# Pick a random value in the weight range
	var roll = randf() * total_weight

	# Find which item was selected
	var current_weight: float = 0.0
	for item in weighted_items:
		if item is Dictionary and item.has("weight") and item.has("item"):
			current_weight += float(item.weight)
			if roll < current_weight:
				return item.item

	# Fallback (should not happen with valid data)
	return weighted_items[-1].item if weighted_items[-1] is Dictionary and weighted_items[-1].has("item") else null


## Hash a string to an integer using FNV-1a algorithm.
## This provides consistent hashing across platforms.
##
## FNV-1a is chosen for:
##   - Simplicity and speed
##   - Good distribution for short strings
##   - Deterministic across platforms
func _hash_string_to_int(s: String) -> int:
	# FNV-1a constants for 64-bit
	const FNV_OFFSET_BASIS: int = -3750763034362895579  # 0xcbf29ce484222325 as signed int64
	const FNV_PRIME: int = 1099511628211  # 0x100000001b3

	var hash: int = FNV_OFFSET_BASIS

	for i in range(s.length()):
		var byte_value = s.unicode_at(i) & 0xFF
		hash = hash ^ byte_value
		hash = (hash * FNV_PRIME) & 0x7FFFFFFFFFFFFFFF  # Keep as positive 63-bit for consistency

	return hash


## Static helper to create and seed an RNG in one call.
static func create(run_seed: Variant, floor_index: int):
	var script = load("res://scripts/utils/deterministic_rng.gd")
	var rng = script.new()
	rng.seed_from_run_and_floor(run_seed, floor_index)
	return rng


## Static helper to generate a random run seed string.
## Useful for starting new runs with unique seeds.
static func generate_run_seed() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(12):
		result += chars[rng.randi_range(0, chars.length() - 1)]

	return result
