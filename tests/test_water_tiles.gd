extends Node
## Test Module for Water Tiles (Issue #93)
##
## Tests for water tile acceptance criteria:
## - Water tiles render as blue ~
## - Movement into water costs 2 turns
## - Guards are affected equally by water

# Load required classes
const TurnSystem = preload("res://scripts/turn_system.gd")
const GuardSystem = preload("res://scripts/guard_system.gd")
const Renderer = preload("res://scripts/renderer.gd")

var tests_passed := 0
var tests_failed := 0


func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_water_tile_renders_correctly()
	test_water_movement_costs_two_turns()
	test_normal_movement_costs_one_turn()
	test_guards_slowed_by_water()
	test_water_is_walkable()
	test_multiple_water_crossings()
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


func assert_contains(haystack: String, needle: String, test_name: String) -> void:
	"""Assert that haystack contains needle."""
	if needle in haystack:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: '%s' not found in string" % [test_name, needle])


## Test implementations


func test_water_tile_renders_correctly() -> void:
	"""Test that water tiles render as cyan ~ character."""
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "water"}
	}
	var player_pos = Vector2i(5, 5)  # Player far away
	var guards: Array[Vector2i] = []

	var output = renderer.render_grid(grid, player_pos, guards)

	# Check that water is rendered with ~ character
	assert_contains(output, "~", "Water should render as ~ character")
	# Check that it uses cyan color (COLOR_WATER)
	assert_contains(output, "[color=cyan]~[/color]", "Water should be rendered in cyan")

	renderer.free()


func test_water_movement_costs_two_turns() -> void:
	"""Test that moving into water costs 2 turns."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place water tile to the right
	turn_system.set_grid_tile(Vector2i(1, 0), "water")

	# Move into water
	var initial_turn = turn_system.get_turn_count()
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	var final_turn = turn_system.get_turn_count()

	assert_true(result, "Move into water should succeed")
	assert_eq(turn_system.get_player_position(), Vector2i(1, 0), "Player should be on water tile")
	assert_eq(final_turn - initial_turn, 2, "Moving into water should cost 2 turns")

	turn_system.free()


func test_normal_movement_costs_one_turn() -> void:
	"""Test that moving into normal floor costs only 1 turn."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Place floor tile to the right (default is floor)
	turn_system.set_grid_tile(Vector2i(1, 0), "floor")

	# Move into floor
	var initial_turn = turn_system.get_turn_count()
	var result = turn_system.execute_turn("move", Vector2i(1, 0))
	var final_turn = turn_system.get_turn_count()

	assert_true(result, "Move into floor should succeed")
	assert_eq(turn_system.get_player_position(), Vector2i(1, 0), "Player should be on floor tile")
	assert_eq(final_turn - initial_turn, 1, "Moving into floor should cost 1 turn")

	turn_system.free()


func test_guards_slowed_by_water() -> void:
	"""Test that guards take 2 turns to cross water tiles."""
	var turn_system = TurnSystem.new()
	var guard_system = GuardSystem.new(12345)

	turn_system.setup(12345)
	turn_system.set_guard_system(guard_system)

	# Set player far away
	turn_system.set_player_position(Vector2i(10, 10))

	# Create a guard at (0, 0) with patrol direction right
	var guard = guard_system.add_guard(Vector2i(0, 0))
	guard.patrol_direction = Vector2i(1, 0)

	# Place water at (1, 0) and floor at (2, 0)
	turn_system.set_grid_tile(Vector2i(1, 0), "water")
	turn_system.set_grid_tile(Vector2i(2, 0), "floor")

	# Process first guard phase - guard moves into water
	guard_system.process_guard_phase()
	assert_eq(guard.position, Vector2i(1, 0), "Guard should move into water")
	assert_eq(guard.movement_cooldown, 1, "Guard should have cooldown of 1 after water")

	# Process second guard phase - guard is on cooldown
	guard_system.process_guard_phase()
	assert_eq(guard.position, Vector2i(1, 0), "Guard should stay in place during cooldown")
	assert_eq(guard.movement_cooldown, 0, "Guard cooldown should decrement to 0")

	# Process third guard phase - guard can move again
	guard_system.process_guard_phase()
	assert_eq(guard.position, Vector2i(2, 0), "Guard should move again after cooldown")

	turn_system.free()
	guard_system.free()


func test_water_is_walkable() -> void:
	"""Test that water tiles are walkable (not blocked like walls)."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Place water tile
	turn_system.set_grid_tile(Vector2i(0, 0), "water")

	# Check that water is walkable
	assert_true(turn_system.is_tile_walkable(Vector2i(0, 0)), "Water should be walkable")

	# Check movement cost
	assert_eq(turn_system.get_movement_cost(Vector2i(0, 0)), 2, "Water should have movement cost of 2")

	turn_system.free()


func test_multiple_water_crossings() -> void:
	"""Test that multiple water crossings accumulate turn costs correctly."""
	var turn_system = TurnSystem.new()
	turn_system.setup(12345)

	# Set player at origin
	turn_system.set_player_position(Vector2i(0, 0))

	# Create a path: floor, water, water, floor
	turn_system.set_grid_tile(Vector2i(0, 0), "floor")
	turn_system.set_grid_tile(Vector2i(1, 0), "water")
	turn_system.set_grid_tile(Vector2i(2, 0), "water")
	turn_system.set_grid_tile(Vector2i(3, 0), "floor")

	var initial_turn = turn_system.get_turn_count()

	# Move into first water (costs 2 turns)
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_turn_count(), initial_turn + 2, "First water crossing costs 2 turns")

	# Move into second water (costs 2 more turns)
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_turn_count(), initial_turn + 4, "Second water crossing costs 2 more turns")

	# Move into floor (costs 1 turn)
	turn_system.execute_turn("move", Vector2i(1, 0))
	assert_eq(turn_system.get_turn_count(), initial_turn + 5, "Floor crossing costs 1 turn")

	turn_system.free()
