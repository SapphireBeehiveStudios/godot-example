extends Node
## Test Module for Trap Tiles (Issue #94)
##
## Tests for trap tile functionality:
## - Trap tiles render as ^
## - Trigger alert radius when stepped on
## - One-time use (trap disarms after triggering)

# Load the required classes
const TurnSystem = preload("res://scripts/turn_system.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const Renderer = preload("res://scripts/renderer.gd")

var tests_passed := 0
var tests_failed := 0


func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_add_trap_creates_trap_tile()
	test_trap_is_walkable()
	test_trap_renders_as_caret()
	test_stepping_on_trap_triggers_alert()
	test_trap_disarms_after_trigger()
	test_disarmed_trap_does_not_alert()
	test_trap_alerts_guards_within_radius()
	test_trap_does_not_alert_distant_guards()
	test_multiple_guards_can_be_alerted()
	test_trap_without_guards_does_not_crash()
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

func test_add_trap_creates_trap_tile() -> void:
	"""Test that add_trap creates a trap tile with armed state."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	var trap_pos = Vector2i(5, 5)
	turn_system.add_trap(trap_pos)

	var tile = turn_system.get_grid_tile(trap_pos)
	assert_eq(tile.type, "trap", "Tile type should be 'trap'")
	assert_true(tile.get("armed", false), "Trap should be armed by default")

	turn_system.free()


func test_trap_is_walkable() -> void:
	"""Test that traps are walkable (player can step on them)."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	var trap_pos = Vector2i(1, 0)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(0, 0))

	assert_true(turn_system.is_tile_walkable(trap_pos), "Trap tile should be walkable")

	# Try to move onto the trap
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	assert_true(result, "Should be able to move onto trap")
	assert_eq(turn_system.get_player_position(), trap_pos, "Player should be on trap position")

	turn_system.free()


func test_trap_renders_as_caret() -> void:
	"""Test that armed traps render as '^' character."""
	var renderer = Renderer.new()
	var grid: Dictionary = {}
	grid[Vector2i(0, 0)] = {"type": "trap", "armed": true}

	var output = renderer.render_grid(grid, Vector2i(5, 5), [])

	assert_contains(output, "^", "Rendered output should contain '^' for armed trap")

	renderer.free()


func test_stepping_on_trap_triggers_alert() -> void:
	"""Test that stepping on an armed trap triggers guard alert."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.set_guard_system(guard_system)
	turn_system.setup(12345)

	# Place a trap and a guard nearby
	var trap_pos = Vector2i(1, 0)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(0, 0))

	var guard = guard_system.add_guard(Vector2i(3, 0))  # Within 5 tiles
	var initial_state = guard.state

	# Step on the trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Guard should be alerted
	assert_eq(guard.state, GuardSystem.GuardState.ALERT, "Guard should be alerted after trap trigger")

	turn_system.free()
	guard_system.free()


func test_trap_disarms_after_trigger() -> void:
	"""Test that traps disarm (one-time use) after being triggered."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.set_guard_system(guard_system)
	turn_system.setup(12345)

	var trap_pos = Vector2i(1, 0)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(0, 0))

	# Verify trap is armed initially
	assert_true(turn_system.is_trap_armed(trap_pos), "Trap should be armed initially")

	# Step on the trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Trap should be disarmed
	assert_false(turn_system.is_trap_armed(trap_pos), "Trap should be disarmed after trigger")

	turn_system.free()
	guard_system.free()


func test_disarmed_trap_does_not_alert() -> void:
	"""Test that a disarmed trap does not alert guards when stepped on again."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.set_guard_system(guard_system)
	turn_system.setup(12345)

	var trap_pos = Vector2i(1, 0)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(0, 0))

	var guard = guard_system.add_guard(Vector2i(3, 0))

	# Trigger the trap once
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(guard.state, GuardSystem.GuardState.ALERT, "Guard should be alerted first time")

	# Reset guard state
	guard.state = GuardSystem.GuardState.PATROL

	# Move away and back onto the trap
	turn_system.execute_turn("move", Vector2i(-1, 0))  # Move back
	turn_system.execute_turn("move", Vector2i(1, 0))   # Step on trap again

	# Guard should still be in PATROL state (trap was disarmed)
	assert_eq(guard.state, GuardSystem.GuardState.PATROL, "Guard should not be alerted by disarmed trap")

	turn_system.free()
	guard_system.free()


func test_trap_alerts_guards_within_radius() -> void:
	"""Test that trap alerts guards within 5 tiles (Manhattan distance)."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.set_guard_system(guard_system)
	turn_system.setup(12345)

	var trap_pos = Vector2i(5, 5)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(4, 5))

	# Place guards at various distances
	var guard_close = guard_system.add_guard(Vector2i(7, 5))    # Distance 2
	var guard_edge = guard_system.add_guard(Vector2i(10, 5))    # Distance 5 (exactly on edge)
	var guard_diagonal = guard_system.add_guard(Vector2i(8, 8)) # Distance 3+3=6 (outside)

	# Step on trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Check alert states
	assert_eq(guard_close.state, GuardSystem.GuardState.ALERT, "Close guard should be alerted")
	assert_eq(guard_edge.state, GuardSystem.GuardState.ALERT, "Guard at exactly 5 tiles should be alerted")
	assert_eq(guard_diagonal.state, GuardSystem.GuardState.PATROL, "Guard outside radius should not be alerted")

	turn_system.free()
	guard_system.free()


func test_trap_does_not_alert_distant_guards() -> void:
	"""Test that traps do not alert guards beyond 5 tiles."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.set_guard_system(guard_system)
	turn_system.setup(12345)

	var trap_pos = Vector2i(0, 0)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(-1, 0))

	# Place guard far away (distance = 10)
	var guard_far = guard_system.add_guard(Vector2i(10, 0))

	# Step on trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Distant guard should not be alerted
	assert_eq(guard_far.state, GuardSystem.GuardState.PATROL, "Distant guard should not be alerted")

	turn_system.free()
	guard_system.free()


func test_multiple_guards_can_be_alerted() -> void:
	"""Test that multiple guards can be alerted simultaneously by one trap."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.set_guard_system(guard_system)
	turn_system.setup(12345)

	var trap_pos = Vector2i(5, 5)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(4, 5))

	# Place 3 guards within radius
	var guard1 = guard_system.add_guard(Vector2i(6, 5))
	var guard2 = guard_system.add_guard(Vector2i(5, 7))
	var guard3 = guard_system.add_guard(Vector2i(3, 5))

	# Step on trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# All guards should be alerted
	assert_eq(guard1.state, GuardSystem.GuardState.ALERT, "Guard 1 should be alerted")
	assert_eq(guard2.state, GuardSystem.GuardState.ALERT, "Guard 2 should be alerted")
	assert_eq(guard3.state, GuardSystem.GuardState.ALERT, "Guard 3 should be alerted")

	turn_system.free()
	guard_system.free()


func test_trap_without_guards_does_not_crash() -> void:
	"""Test that triggering a trap without guards doesn't crash (edge case)."""
	var turn_system = TurnSystem.new()
	# No guard system set
	turn_system.setup(12345)

	var trap_pos = Vector2i(1, 0)
	turn_system.add_trap(trap_pos)
	turn_system.set_player_position(Vector2i(0, 0))

	# This should not crash even without guard_system
	var result = turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(result, "Should be able to trigger trap without guards present")
	assert_false(turn_system.is_trap_armed(trap_pos), "Trap should still disarm")

	turn_system.free()
