extends Node
## Tests for EndScreen (Issue #38 - EPIC 5)
##
## Tests:
## - Best score loading and saving
## - New best score detection
## - Score display logic
## - Victory vs caught display

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	print("\n=== EndScreen Tests ===")
	test_best_score_save_and_load()
	test_new_best_score_detection()
	test_best_score_comparison()
	test_victory_display()
	test_caught_display()
	test_seed_display()
	test_no_save_system_graceful_handling()
	test_detailed_statistics_display()
	test_guards_evaded_display()
	test_play_time_formatting()
	test_best_run_save_and_load()

	return {"passed": tests_passed, "failed": tests_failed}

func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])

func assert_true(condition: bool, test_name: String) -> void:
	assert_eq(condition, true, test_name)

func assert_false(condition: bool, test_name: String) -> void:
	assert_eq(condition, false, test_name)

func test_best_score_save_and_load() -> void:
	"""Test saving and loading best score."""
	var end_screen = load("res://scripts/end_screen.gd").new()
	end_screen._ready()  # Initialize save system

	# Use a unique test path to avoid conflicts
	const TEST_PATH = "user://test_best_score.json"

	# Clean up any existing test file
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

	# Test save
	var save_result = end_screen.save_system.save({"best_score": 100}, TEST_PATH)
	assert_true(save_result, "Best score save succeeds")

	# Test load
	var loaded_data = end_screen.save_system.load(TEST_PATH)
	assert_eq(loaded_data.get("best_score", 0), 100, "Best score loads correctly")

	# Clean up
	DirAccess.remove_absolute(TEST_PATH)
	end_screen.free()

func test_new_best_score_detection() -> void:
	"""Test detection of new best scores."""
	var end_screen = load("res://scripts/end_screen.gd").new()
	end_screen._ready()

	const TEST_PATH = "user://test_new_best.json"

	# Clean up
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

	# Set initial best score
	end_screen.save_system.save({"best_score": 50}, TEST_PATH)

	# Load and verify old best
	var old_best = end_screen.save_system.load(TEST_PATH).get("best_score", 0)
	assert_eq(old_best, 50, "Initial best score is 50")

	# Save new best
	end_screen.save_system.save({"best_score": 75}, TEST_PATH)

	# Verify new best
	var new_best = end_screen.save_system.load(TEST_PATH).get("best_score", 0)
	assert_eq(new_best, 75, "New best score is 75")

	# Clean up
	DirAccess.remove_absolute(TEST_PATH)
	end_screen.free()

func test_best_score_comparison() -> void:
	"""Test comparison logic for best scores."""
	var end_screen = load("res://scripts/end_screen.gd").new()
	end_screen._ready()

	const TEST_PATH = "user://test_comparison.json"

	# Clean up
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)

	# Save initial best
	end_screen.save_system.save({"best_score": 100}, TEST_PATH)

	# Test: score below best
	var current_score = 50
	var best_score = end_screen.save_system.load(TEST_PATH).get("best_score", 0)
	assert_true(current_score < best_score, "Score 50 is less than best 100")

	# Test: score above best
	current_score = 150
	assert_true(current_score > best_score, "Score 150 is greater than best 100")

	# Test: score equal to best
	current_score = 100
	assert_false(current_score > best_score, "Score 100 is not greater than best 100")

	# Clean up
	DirAccess.remove_absolute(TEST_PATH)
	end_screen.free()

func test_victory_display() -> void:
	"""Test victory result display."""
	var end_screen_scene = load("res://scenes/end_screen.tscn")
	var end_screen = end_screen_scene.instantiate()

	# Create mock game state
	var game_state = load("res://game_state.gd").new()
	game_state.score = 100
	game_state.run_seed = 12345

	# Clean up best score file to avoid interference
	const BEST_PATH = "user://best_score.json"
	if FileAccess.file_exists(BEST_PATH):
		DirAccess.remove_absolute(BEST_PATH)

	# Show results with victory
	end_screen.show_results(game_state, true)

	# Verify result text
	assert_eq(end_screen.result_label.text, "VICTORY!", "Victory text displayed")

	# Verify score displayed
	assert_eq(end_screen.score_label.text, "Score: 100", "Score displayed correctly")

	# Verify seed displayed
	assert_eq(end_screen.seed_label.text, "Seed: 12345", "Seed displayed correctly")

	# Clean up
	end_screen.queue_free()

func test_caught_display() -> void:
	"""Test caught result display."""
	var end_screen_scene = load("res://scenes/end_screen.tscn")
	var end_screen = end_screen_scene.instantiate()

	# Create mock game state
	var game_state = load("res://game_state.gd").new()
	game_state.score = 25
	game_state.run_seed = "abc123"

	# Clean up best score file
	const BEST_PATH = "user://best_score.json"
	if FileAccess.file_exists(BEST_PATH):
		DirAccess.remove_absolute(BEST_PATH)

	# Show results with loss
	end_screen.show_results(game_state, false)

	# Verify result text
	assert_eq(end_screen.result_label.text, "CAUGHT!", "Caught text displayed")

	# Verify score displayed
	assert_eq(end_screen.score_label.text, "Score: 25", "Score displayed correctly")

	# Clean up
	end_screen.queue_free()

func test_seed_display() -> void:
	"""Test seed display with different seed types."""
	var end_screen_scene = load("res://scenes/end_screen.tscn")
	var end_screen = end_screen_scene.instantiate()

	# Test with integer seed
	var game_state = load("res://game_state.gd").new()
	game_state.score = 50
	game_state.run_seed = 42

	# Clean up best score file
	const BEST_PATH = "user://best_score.json"
	if FileAccess.file_exists(BEST_PATH):
		DirAccess.remove_absolute(BEST_PATH)

	end_screen.show_results(game_state, true)
	assert_eq(end_screen.seed_label.text, "Seed: 42", "Integer seed displayed")

	# Test with string seed
	game_state.run_seed = "myseed"
	end_screen.show_results(game_state, true)
	assert_eq(end_screen.seed_label.text, "Seed: myseed", "String seed displayed")

	# Clean up
	end_screen.queue_free()

func test_no_save_system_graceful_handling() -> void:
	"""Test graceful handling when save system is not available."""
	var end_screen = load("res://scripts/end_screen.gd").new()
	# Don't call _ready(), so save_system remains null

	# Should not crash
	var best = end_screen.load_best_score()
	assert_eq(best, 0, "Returns 0 when save system unavailable")

	var save_result = end_screen.save_best_score(100)
	assert_false(save_result, "Returns false when save system unavailable")

	end_screen.free()

func test_detailed_statistics_display() -> void:
	"""Test display of detailed run statistics (Issue #95)."""
	var end_screen_scene = load("res://scenes/end_screen.tscn")
	var end_screen = end_screen_scene.instantiate()

	# Create mock game state with statistics
	var game_state = load("res://game_state.gd").new()
	game_state.score = 100
	game_state.run_seed = 12345
	game_state.turn_count = 50
	game_state.floor_number = 3
	game_state.keycards = 2
	game_state.guards_evaded = 5

	# Clean up best score file
	const BEST_PATH = "user://best_score.json"
	if FileAccess.file_exists(BEST_PATH):
		DirAccess.remove_absolute(BEST_PATH)

	# Show results
	end_screen.show_results(game_state, true)

	# Verify statistics displayed
	assert_eq(end_screen.turns_label.text, "Total Turns: 50", "Turns displayed correctly")
	assert_eq(end_screen.floors_label.text, "Floors Completed: 3", "Floors displayed correctly")
	assert_eq(end_screen.keycards_label.text, "Keycards Collected: 2", "Keycards displayed correctly")
	assert_eq(end_screen.guards_label.text, "Guards Evaded: 5", "Guards evaded displayed correctly")

	# Clean up
	end_screen.queue_free()

func test_guards_evaded_display() -> void:
	"""Test guards evaded display shows 'caught' when player was caught (Issue #95)."""
	var end_screen_scene = load("res://scenes/end_screen.tscn")
	var end_screen = end_screen_scene.instantiate()

	# Create game state where player was caught
	var game_state = load("res://game_state.gd").new()
	game_state.score = 50
	game_state.guards_evaded = 3
	game_state.caught_by_guard = true

	# Clean up best score file
	const BEST_PATH = "user://best_score.json"
	if FileAccess.file_exists(BEST_PATH):
		DirAccess.remove_absolute(BEST_PATH)

	# Show results (false = caught/lost)
	end_screen.show_results(game_state, false)

	# Verify guards label shows "(caught)"
	assert_eq(end_screen.guards_label.text, "Guards Evaded: 3 (caught)", "Guards label shows caught status")

	# Clean up
	end_screen.queue_free()

func test_play_time_formatting() -> void:
	"""Test play time formatting (Issue #95)."""
	var end_screen = load("res://scripts/end_screen.gd").new()

	# Test seconds only
	var formatted = end_screen.format_time(45)
	assert_eq(formatted, "Time Played: 45s", "Seconds only formatted correctly")

	# Test minutes and seconds
	formatted = end_screen.format_time(150)  # 2m 30s
	assert_eq(formatted, "Time Played: 2m 30s", "Minutes and seconds formatted correctly")

	# Test exactly 1 minute
	formatted = end_screen.format_time(60)
	assert_eq(formatted, "Time Played: 1m 0s", "Exactly 1 minute formatted correctly")

	# Test 0 seconds
	formatted = end_screen.format_time(0)
	assert_eq(formatted, "Time Played: 0s", "Zero seconds formatted correctly")

	end_screen.free()

func test_best_run_save_and_load() -> void:
	"""Test saving and loading best run statistics (Issue #95)."""
	var end_screen = load("res://scripts/end_screen.gd").new()
	end_screen._ready()  # Initialize save system

	const BEST_RUN_PATH = "user://best_run.json"

	# Clean up any existing file
	if FileAccess.file_exists(BEST_RUN_PATH):
		DirAccess.remove_absolute(BEST_RUN_PATH)

	# Create mock game state
	var game_state = load("res://game_state.gd").new()
	game_state.score = 200
	game_state.turn_count = 75
	game_state.floor_number = 5
	game_state.keycards = 3
	game_state.guards_evaded = 8
	game_state.caught_by_guard = false
	game_state.run_seed = "test-seed"
	game_state.start_time_msec = Time.get_ticks_msec() - 120000  # 2 minutes ago

	# Save best run
	var save_result = end_screen.save_best_run(game_state)
	assert_true(save_result, "Best run save succeeds")

	# Load and verify
	var loaded_run = end_screen.load_best_run()
	assert_eq(loaded_run.get("score", -1), 200, "Score loaded correctly")
	assert_eq(loaded_run.get("turns", -1), 75, "Turns loaded correctly")
	assert_eq(loaded_run.get("floors", -1), 5, "Floors loaded correctly")
	assert_eq(loaded_run.get("keycards", -1), 3, "Keycards loaded correctly")
	assert_eq(loaded_run.get("guards_evaded", -1), 8, "Guards evaded loaded correctly")
	assert_false(loaded_run.get("caught_by_guard", true), "Caught status loaded correctly")
	assert_eq(loaded_run.get("seed", ""), "test-seed", "Seed loaded correctly")
	assert_true(loaded_run.get("play_time_seconds", -1) >= 0, "Play time loaded correctly")

	# Clean up
	DirAccess.remove_absolute(BEST_RUN_PATH)
	end_screen.free()
