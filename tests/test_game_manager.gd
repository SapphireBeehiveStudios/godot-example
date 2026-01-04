extends Node
## Game Manager Test Module
##
## Tests the game over capture condition logic.

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	"""Run all tests in this module and return results."""
	test_initial_state()
	test_player_position_setting()
	test_guard_position_setting()
	test_capture_on_same_tile()
	test_capture_when_guard_moves_to_player()
	test_capture_when_player_moves_to_guard()
	test_no_capture_on_different_tiles()
	test_multiple_guards_one_captures()
	test_game_over_flag_persists()
	test_game_over_reason()
	test_reset_game()
	test_capture_is_deterministic()
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

## Test implementations
func test_initial_state() -> void:
	"""Test that game manager starts in correct initial state."""
	var gm = load("res://game_manager.gd").new()
	assert_false(gm.is_game_over, "Game starts not over")
	assert_eq(gm.game_over_reason, "", "Game over reason starts empty")
	assert_eq(gm.player_position, Vector2i(0, 0), "Player starts at origin")
	assert_eq(gm.guard_positions.size(), 0, "No guards initially")
	gm.free()

func test_player_position_setting() -> void:
	"""Test setting player position."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(5, 3))
	assert_eq(gm.player_position, Vector2i(5, 3), "Player position updated correctly")
	gm.free()

func test_guard_position_setting() -> void:
	"""Test setting guard positions."""
	var gm = load("res://game_manager.gd").new()
	gm.set_guard_position(0, Vector2i(2, 2))
	assert_eq(gm.guard_positions[0], Vector2i(2, 2), "Guard 0 position set correctly")

	gm.set_guard_position(1, Vector2i(4, 4))
	assert_eq(gm.guard_positions[1], Vector2i(4, 4), "Guard 1 position set correctly")
	assert_eq(gm.guard_positions.size(), 2, "Two guards tracked")
	gm.free()

func test_capture_on_same_tile() -> void:
	"""Test that capture is detected when guard is on player tile."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(3, 3))
	gm.set_guard_position(0, Vector2i(3, 3))

	assert_true(gm.is_game_over, "Game over triggered on capture")
	assert_true(gm.game_over_reason.contains("captured"), "Reason mentions capture")
	gm.free()

func test_capture_when_guard_moves_to_player() -> void:
	"""Test capture when guard moves onto player's tile."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(5, 5))
	gm.set_guard_position(0, Vector2i(4, 5))

	assert_false(gm.is_game_over, "Game not over when guard is adjacent")

	# Guard moves to player position
	gm.set_guard_position(0, Vector2i(5, 5))
	assert_true(gm.is_game_over, "Game over when guard moves to player tile")
	gm.free()

func test_capture_when_player_moves_to_guard() -> void:
	"""Test capture when player moves onto guard's tile."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(2, 2))
	gm.set_guard_position(0, Vector2i(3, 2))

	assert_false(gm.is_game_over, "Game not over when player is adjacent to guard")

	# Player moves to guard position
	gm.set_player_position(Vector2i(3, 2))
	assert_true(gm.is_game_over, "Game over when player moves to guard tile")
	gm.free()

func test_no_capture_on_different_tiles() -> void:
	"""Test that no capture occurs when positions are different."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(1, 1))
	gm.set_guard_position(0, Vector2i(1, 2))
	gm.set_guard_position(1, Vector2i(2, 1))
	gm.set_guard_position(2, Vector2i(0, 0))

	assert_false(gm.is_game_over, "No capture when all guards on different tiles")
	gm.free()

func test_multiple_guards_one_captures() -> void:
	"""Test capture with multiple guards where one captures player."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(3, 3))
	gm.set_guard_position(0, Vector2i(1, 1))
	gm.set_guard_position(1, Vector2i(2, 2))
	gm.set_guard_position(2, Vector2i(3, 3))  # This one captures

	assert_true(gm.is_game_over, "Game over when one of multiple guards captures")
	gm.free()

func test_game_over_flag_persists() -> void:
	"""Test that game over flag persists and doesn't reset."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(5, 5))
	gm.set_guard_position(0, Vector2i(5, 5))

	assert_true(gm.is_game_over, "Game over after capture")

	# Move guard away
	gm.set_guard_position(0, Vector2i(4, 4))
	assert_true(gm.is_game_over, "Game over flag persists after guard moves away")
	gm.free()

func test_game_over_reason() -> void:
	"""Test that game over reason is set correctly."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(2, 2))
	gm.set_guard_position(0, Vector2i(2, 2))

	assert_eq(gm.get_game_over_status(), true, "get_game_over_status returns true")
	var reason = gm.get_game_over_reason()
	assert_true(reason.length() > 0, "Game over reason is not empty")
	assert_true(reason.contains("captured") or reason.contains("guard"), "Reason contains relevant info")
	gm.free()

func test_reset_game() -> void:
	"""Test that reset_game clears game over state."""
	var gm = load("res://game_manager.gd").new()
	gm.set_player_position(Vector2i(3, 3))
	gm.set_guard_position(0, Vector2i(3, 3))

	assert_true(gm.is_game_over, "Game over after capture")

	gm.reset_game()
	assert_false(gm.is_game_over, "Game over cleared after reset")
	assert_eq(gm.game_over_reason, "", "Game over reason cleared after reset")
	assert_eq(gm.guard_positions.size(), 0, "Guards cleared after reset")
	gm.free()

func test_capture_is_deterministic() -> void:
	"""Test that capture detection is deterministic (same input = same output)."""
	# Test 1: Run same scenario 5 times
	for i in range(5):
		var gm = load("res://game_manager.gd").new()
		gm.set_player_position(Vector2i(7, 7))
		gm.set_guard_position(0, Vector2i(7, 7))
		assert_true(gm.is_game_over, "Capture detected deterministically (iteration %d)" % i)
		gm.free()

	# Test 2: Verify non-capture is also deterministic
	for i in range(5):
		var gm = load("res://game_manager.gd").new()
		gm.set_player_position(Vector2i(1, 1))
		gm.set_guard_position(0, Vector2i(2, 2))
		assert_false(gm.is_game_over, "Non-capture deterministic (iteration %d)" % i)
		gm.free()
