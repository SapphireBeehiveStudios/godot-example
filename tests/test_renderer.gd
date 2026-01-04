extends Node
## Tests for Renderer.gd
##
## Tests include:
## - Empty grid handling
## - Character mapping for all tile types
## - Entity rendering (player, guards)
## - BBCode color formatting
## - Grid bounds calculation
## - Snapshot test for known layout

var tests_passed := 0
var tests_failed := 0

const Renderer = preload("res://scripts/renderer.gd")


func run_all() -> Dictionary:
	print("\n=== Renderer Tests ===")

	test_empty_grid()
	test_single_tile()
	test_player_rendering()
	test_guard_rendering()
	test_wall_rendering()
	test_floor_rendering()
	test_keycard_rendering()
	test_shard_rendering()
	test_exit_rendering()
	test_door_rendering()
	test_multiple_guards()
	test_entity_priority()
	test_grid_bounds()
	test_bbcode_formatting()
	test_snapshot_known_layout()

	return {"passed": tests_passed, "failed": tests_failed}


func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s" % test_name)
		print("    Expected: %s" % expected)
		print("    Got:      %s" % actual)


func assert_true(condition: bool, test_name: String) -> void:
	assert_eq(condition, true, test_name)


func assert_contains(haystack: String, needle: String, test_name: String) -> void:
	if needle in haystack:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: '%s' not found in '%s'" % [test_name, needle, haystack])


func test_empty_grid() -> void:
	var renderer = Renderer.new()
	var result = renderer.render_grid({}, Vector2i(0, 0), [])
	assert_eq(result, "", "Empty grid returns empty string")


func test_single_tile() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "floor"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	# Floor at (0,0), empty space elsewhere
	assert_true(result.length() > 0, "Single tile produces output")


func test_player_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "floor"}
	}
	var result = renderer.render_grid(grid, Vector2i(0, 0), [])
	assert_contains(result, "@", "Player character @ appears in output")
	assert_contains(result, "color=aqua", "Player has aqua color")


func test_guard_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "floor"}
	}
	var guards: Array[Vector2i] = [Vector2i(1, 0)]
	var result = renderer.render_grid(grid, Vector2i(0, 0), guards)
	assert_contains(result, "G", "Guard character G appears in output")
	assert_contains(result, "color=red", "Guard has red color")


func test_wall_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "wall"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	assert_contains(result, "#", "Wall character # appears in output")
	assert_contains(result, "color=gray", "Wall has gray color")


func test_floor_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "floor"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	assert_contains(result, ".", "Floor character . appears in output")
	assert_contains(result, "color=white", "Floor has white color")


func test_keycard_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "pickup", "pickup_type": "keycard"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	assert_contains(result, "k", "Keycard character k appears in output")
	assert_contains(result, "color=blue", "Keycard has blue color")


func test_shard_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "pickup", "pickup_type": "shard"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	assert_contains(result, "$", "Shard character $ appears in output")
	assert_contains(result, "color=gold", "Shard has gold color")


func test_exit_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "exit"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	assert_contains(result, ">", "Exit character > appears in output")
	assert_contains(result, "color=lime", "Exit has lime color")


func test_door_rendering() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "door_open"},
		Vector2i(1, 0): {"type": "door_closed"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])
	assert_contains(result, "D", "Door character D appears in output")
	assert_contains(result, "color=green", "Open door has green color")
	assert_contains(result, "color=yellow", "Closed door has yellow color")


func test_multiple_guards() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "floor"},
		Vector2i(1, 0): {"type": "floor"},
		Vector2i(2, 0): {"type": "floor"}
	}
	var guards: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	var result = renderer.render_grid(grid, Vector2i(0, 0), guards)

	# Count occurrences of 'G' in the result
	var g_count = 0
	for c in result:
		if c == "G":
			g_count += 1

	assert_eq(g_count, 2, "Multiple guards all rendered")


func test_entity_priority() -> void:
	var renderer = Renderer.new()
	# Player should override floor tile
	var grid = {
		Vector2i(0, 0): {"type": "floor"}
	}
	var result = renderer.render_grid(grid, Vector2i(0, 0), [])
	assert_contains(result, "@", "Player overrides floor tile")

	# Guard should override floor tile
	grid = {
		Vector2i(0, 0): {"type": "floor"}
	}
	var guards: Array[Vector2i] = [Vector2i(0, 0)]
	result = renderer.render_grid(grid, Vector2i(5, 5), guards)
	assert_contains(result, "G", "Guard overrides floor tile")


func test_grid_bounds() -> void:
	var renderer = Renderer.new()
	# Grid spanning from (-2, -2) to (2, 2)
	var grid = {
		Vector2i(-2, -2): {"type": "wall"},
		Vector2i(2, 2): {"type": "wall"}
	}
	var result = renderer.render_grid(grid, Vector2i(0, 0), [])

	# Should have 5 rows (y from -2 to 2)
	var lines = result.split("\n")
	assert_eq(lines.size(), 5, "Grid bounds calculated correctly (rows)")


func test_bbcode_formatting() -> void:
	var renderer = Renderer.new()
	var grid = {
		Vector2i(0, 0): {"type": "wall"}
	}
	var result = renderer.render_grid(grid, Vector2i(5, 5), [])

	# Check that BBCode tags are properly formatted
	assert_contains(result, "[color=", "BBCode color tag opening present")
	assert_contains(result, "[/color]", "BBCode color tag closing present")
	assert_true(result.count("[color=") == result.count("[/color]"), "BBCode tags balanced")


func test_snapshot_known_layout() -> void:
	var renderer = Renderer.new()

	# Create a known 3x3 layout:
	# # # #
	# # @ #
	# # # #
	var grid = {
		Vector2i(0, 0): {"type": "wall"},
		Vector2i(1, 0): {"type": "wall"},
		Vector2i(2, 0): {"type": "wall"},
		Vector2i(0, 1): {"type": "wall"},
		Vector2i(1, 1): {"type": "floor"},
		Vector2i(2, 1): {"type": "wall"},
		Vector2i(0, 2): {"type": "wall"},
		Vector2i(1, 2): {"type": "wall"},
		Vector2i(2, 2): {"type": "wall"}
	}

	var result = renderer.render_grid(grid, Vector2i(1, 1), [])

	# Expected output (with BBCode):
	var expected_pattern := [
		"#", "#", "#",  # Row 0
		"#", "@", "#",  # Row 1
		"#", "#", "#"   # Row 2
	]

	# Verify all expected characters are present
	for pattern in expected_pattern:
		assert_contains(result, pattern, "Snapshot contains expected character: %s" % pattern)

	# Verify structure: should have 3 lines
	var lines = result.split("\n")
	assert_eq(lines.size(), 3, "Snapshot has correct number of rows")

	# Test determinism: rendering twice should produce identical output
	var result2 = renderer.render_grid(grid, Vector2i(1, 1), [])
	assert_eq(result, result2, "Renderer output is deterministic")
