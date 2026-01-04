extends Node
## Test Module for Trap Tiles (Issue #94)
##
## Tests for trap tile functionality:
## - Trap tiles render as ^
## - Stepping on trap triggers alert
## - Guards within 5 tiles become alerted
## - One-time use (trap disarms)

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
	test_trap_triggers_on_step()
	test_trap_alerts_guards_in_radius()
	test_trap_does_not_alert_guards_outside_radius()
	test_trap_disarms_after_trigger()
	test_trap_only_triggers_once()
	test_trap_emits_signal()
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
	"""Test that trap tiles render as ^ character."""
	var renderer = Renderer.new()
	var grid: Dictionary = {}
	grid[Vector2i(0, 0)] = {"type": "trap", "active": true}

	var output = renderer.render_grid(grid, Vector2i(1, 1), [])

	# Should contain ^ character with color tag
	assert_contains(output, "^", "Trap should render as ^ character")

	renderer.free()


func test_trap_is_walkable() -> void:
	"""Test that traps can be walked on."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place player and trap
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_trap(Vector2i(1, 0))

	# Should be able to walk onto trap
	assert_true(turn_system.is_tile_walkable(Vector2i(1, 0)), "Trap should be walkable")

	turn_system.free()


func test_trap_triggers_on_step() -> void:
	"""Test that stepping on a trap triggers it."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Place player and trap
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_trap(Vector2i(1, 0))

	var trap_triggered := false
	turn_system.trap_triggered.connect(func(_pos): trap_triggered = true)

	# Move onto trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(trap_triggered, "Trap should trigger when stepped on")

	turn_system.free()
	guard_system.free()


func test_trap_alerts_guards_in_radius() -> void:
	"""Test that guards within 5 tiles are alerted."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Place player and trap at (0, 0)
	turn_system.set_player_position(Vector2i(-1, 0))
	turn_system.add_trap(Vector2i(0, 0))

	# Place guards at various distances
	var guard_close = guard_system.add_guard(Vector2i(3, 0))  # Distance: 3 (within 5)
	var guard_edge = guard_system.add_guard(Vector2i(0, 5))   # Distance: 5 (exactly 5)

	# Move onto trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_eq(guard_close.state, GuardSystem.GuardState.ALERT, "Guard within radius should be alerted")
	assert_eq(guard_edge.state, GuardSystem.GuardState.ALERT, "Guard at exactly 5 tiles should be alerted")

	turn_system.free()
	guard_system.free()


func test_trap_does_not_alert_guards_outside_radius() -> void:
	"""Test that guards outside 5 tiles are not alerted."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Place player and trap at (0, 0)
	turn_system.set_player_position(Vector2i(-1, 0))
	turn_system.add_trap(Vector2i(0, 0))

	# Place guard outside radius
	var guard_far = guard_system.add_guard(Vector2i(6, 0))  # Distance: 6 (outside 5)

	# Move onto trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_eq(guard_far.state, GuardSystem.GuardState.PATROL, "Guard outside radius should not be alerted")

	turn_system.free()
	guard_system.free()


func test_trap_disarms_after_trigger() -> void:
	"""Test that trap becomes floor after triggering."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Place player and trap
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_trap(Vector2i(1, 0))

	# Move onto trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	# Check that trap is now floor
	var tile = turn_system.get_grid_tile(Vector2i(1, 0))
	assert_eq(tile.type, "floor", "Trap should become floor after triggering")

	turn_system.free()
	guard_system.free()


func test_trap_only_triggers_once() -> void:
	"""Test that trap only triggers once (one-time use)."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Place player and trap
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_trap(Vector2i(1, 0))

	# Place a guard
	var guard = guard_system.add_guard(Vector2i(3, 0))

	# Move onto trap (should trigger)
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(guard.state, GuardSystem.GuardState.ALERT, "Guard should be alerted on first trigger")

	# Reset guard state
	guard.state = GuardSystem.GuardState.PATROL

	# Move away and back onto the same tile (should not trigger again)
	turn_system.execute_turn("move", Vector2i(-1, 0))
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_eq(guard.state, GuardSystem.GuardState.PATROL, "Guard should not be alerted again - trap is disarmed")

	turn_system.free()
	guard_system.free()


func test_trap_emits_signal() -> void:
	"""Test that trap emits trap_triggered signal."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)
	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Place player and trap
	turn_system.set_player_position(Vector2i(0, 0))
	turn_system.add_trap(Vector2i(1, 0))

	var signal_emitted := false
	var signal_position := Vector2i.ZERO
	turn_system.trap_triggered.connect(func(pos):
		signal_emitted = true
		signal_position = pos
	)

	# Move onto trap
	turn_system.execute_turn("move", Vector2i(1, 0))

	assert_true(signal_emitted, "trap_triggered signal should be emitted")
	assert_eq(signal_position, Vector2i(1, 0), "Signal should include trap position")

	turn_system.free()
	guard_system.free()
