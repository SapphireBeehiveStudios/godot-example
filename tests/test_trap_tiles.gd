extends Node
## Test Module for Trap Tiles (Issue #94)
##
## Tests for trap tile functionality:
## - Trap tiles render as ^
## - Stepping on trap triggers alert
## - Guards within 5 tiles become alerted
## - One-time use (trap disarms after trigger)

# Load required classes
const TurnSystem = preload("res://scripts/turn_system.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const Renderer = preload("res://scripts/renderer.gd")

var tests_passed := 0
var tests_failed := 0


func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_trap_renders_correctly()
	test_trap_is_walkable()
	test_stepping_on_trap_triggers_alert()
	test_trap_disarms_after_trigger()
	test_guards_within_radius_alerted()
	test_guards_outside_radius_not_alerted()
	test_manhattan_distance_calculation()
	test_multiple_guards_alerted()
	test_trap_message_generated()
	return {"passed": tests_passed, "failed": tests_failed}


## Assertion helper methods
func assert_eq(actual, expected, test_name: String) -> void:
	"""Assert that actual equals expected."""
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])


func assert_true(condition: bool, test_name: String) -> void:
	"""Assert that condition is true."""
	assert_eq(condition, true, test_name)


func assert_false(condition: bool, test_name: String) -> void:
	"""Assert that condition is false."""
	assert_eq(condition, false, test_name)


func assert_contains(text: String, substring: String, test_name: String) -> void:
	"""Assert that text contains substring."""
	if substring in text:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected '%s' to contain '%s'" % [test_name, text, substring])


## Test implementations

func test_trap_renders_correctly() -> void:
	"""Test that trap tiles render as ^ with orange color."""
	var renderer = Renderer.new()
	var grid: Dictionary = {}

	# Place a trap tile at position (1, 1)
	grid[Vector2i(1, 1)] = {"type": "trap"}

	var output = renderer.render_grid(grid, Vector2i(0, 0), [])

	# Check that output contains the trap character
	assert_contains(output, "^", "Trap renders as ^")
	assert_contains(output, "orange", "Trap has orange color")

	renderer.free()


func test_trap_is_walkable() -> void:
	"""Test that trap tiles are walkable."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place a trap at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "trap")

	# Verify trap is walkable
	assert_true(turn_system.is_tile_walkable(Vector2i(1, 0)), "Trap is walkable")

	turn_system.free()


func test_stepping_on_trap_triggers_alert() -> void:
	"""Test that stepping on a trap triggers guard alert."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new()
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place a trap at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "trap")

	# Add a guard nearby
	guard_system.add_guard(Vector2i(3, 0))

	# Move onto the trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Check that guard was alerted (guard state should be ALERT)
	var guard = guard_system.guards[0]
	assert_eq(guard.state, GuardSystem.GuardState.ALERT, "Guard alerted after trap triggered")

	turn_system.free()
	guard_system.free()


func test_trap_disarms_after_trigger() -> void:
	"""Test that trap becomes floor after being triggered (one-time use)."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new()
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place a trap at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "trap")

	# Verify trap exists
	var tile_before = turn_system.get_grid_tile(Vector2i(1, 0))
	assert_eq(tile_before.type, "trap", "Trap exists before trigger")

	# Move onto the trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Verify trap is now floor
	var tile_after = turn_system.get_grid_tile(Vector2i(1, 0))
	assert_eq(tile_after.type, "floor", "Trap becomes floor after trigger")

	turn_system.free()
	guard_system.free()


func test_guards_within_radius_alerted() -> void:
	"""Test that guards within 5 tiles are alerted."""
	var guard_system = GuardSystem.new()

	# Add guards at various distances
	var guard1 = guard_system.add_guard(Vector2i(0, 0))  # Distance 0 (at center)
	var guard2 = guard_system.add_guard(Vector2i(3, 0))  # Distance 3
	var guard3 = guard_system.add_guard(Vector2i(2, 2))  # Distance 4 (Manhattan)
	var guard4 = guard_system.add_guard(Vector2i(5, 0))  # Distance 5 (exactly at radius)

	# Alert guards within radius 5 of origin
	var alerted = guard_system.alert_guards_in_radius(Vector2i(0, 0), 5)

	assert_eq(alerted, 4, "All 4 guards within radius 5 alerted")
	assert_eq(guard1.state, GuardSystem.GuardState.ALERT, "Guard at distance 0 alerted")
	assert_eq(guard2.state, GuardSystem.GuardState.ALERT, "Guard at distance 3 alerted")
	assert_eq(guard3.state, GuardSystem.GuardState.ALERT, "Guard at distance 4 alerted")
	assert_eq(guard4.state, GuardSystem.GuardState.ALERT, "Guard at distance 5 alerted")

	guard_system.free()


func test_guards_outside_radius_not_alerted() -> void:
	"""Test that guards outside 5 tiles are NOT alerted."""
	var guard_system = GuardSystem.new()

	# Add guards outside the radius
	var guard1 = guard_system.add_guard(Vector2i(6, 0))  # Distance 6
	var guard2 = guard_system.add_guard(Vector2i(3, 3))  # Distance 6 (Manhattan)
	var guard3 = guard_system.add_guard(Vector2i(10, 10))  # Distance 20

	# Alert guards within radius 5 of origin
	var alerted = guard_system.alert_guards_in_radius(Vector2i(0, 0), 5)

	assert_eq(alerted, 0, "No guards alerted outside radius")
	assert_eq(guard1.state, GuardSystem.GuardState.PATROL, "Guard at distance 6 not alerted")
	assert_eq(guard2.state, GuardSystem.GuardState.PATROL, "Guard at distance 6 not alerted")
	assert_eq(guard3.state, GuardSystem.GuardState.PATROL, "Guard at distance 20 not alerted")

	guard_system.free()


func test_manhattan_distance_calculation() -> void:
	"""Test that Manhattan distance is used for alert radius."""
	var guard_system = GuardSystem.new()

	# Test diagonal distance
	# Guard at (3, 4) from (0, 0) is distance 7 (not 5 by Euclidean)
	var guard = guard_system.add_guard(Vector2i(3, 4))

	var alerted = guard_system.alert_guards_in_radius(Vector2i(0, 0), 5)

	assert_eq(alerted, 0, "Guard at Manhattan distance 7 not alerted with radius 5")
	assert_eq(guard.state, GuardSystem.GuardState.PATROL, "Guard remains in patrol state")

	guard_system.free()


func test_multiple_guards_alerted() -> void:
	"""Test that multiple guards can be alerted at once."""
	var guard_system = GuardSystem.new()

	# Add 5 guards within radius
	for i in range(5):
		guard_system.add_guard(Vector2i(i, 0))

	var alerted = guard_system.alert_guards_in_radius(Vector2i(0, 0), 5)

	assert_eq(alerted, 5, "All 5 guards alerted")
	assert_eq(guard_system.guards.size(), 5, "5 guards in system")

	# Verify all are in ALERT state
	for guard in guard_system.guards:
		assert_eq(guard.state, GuardSystem.GuardState.ALERT, "Guard in alert state")

	guard_system.free()


func test_trap_message_generated() -> void:
	"""Test that trap generates a message when triggered."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new()
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	var message_received := false
	var message_text := ""
	var message_type := ""

	# Connect to message signal
	turn_system.message_generated.connect(func(text: String, type: String):
		message_received = true
		message_text = text
		message_type = type
	)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place a trap at (1, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "trap")

	# Move onto the trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(message_received, "Message generated when trap triggered")
	assert_contains(message_text, "Trap triggered", "Message mentions trap")
	assert_eq(message_type, "trap", "Message type is 'trap'")

	turn_system.free()
	guard_system.free()
