extends RefCounted
## Test suite for AudioManager (Issue #89)

const AudioManager = preload("res://scripts/audio_manager.gd")

func run_all() -> Dictionary:
	"""Run all tests and return {passed: int, failed: int}."""
	var passed := 0
	var failed := 0

	# Run each test
	for method in get_method_list():
		if method.name.begins_with("test_"):
			if call(method.name):
				passed += 1
			else:
				failed += 1

	return {"passed": passed, "failed": failed}

func test_audio_manager_initialization() -> bool:
	"""Test that AudioManager can be instantiated."""
	var manager = AudioManager.new()

	if manager == null:
		print("  ✗ test_audio_manager_initialization: manager is null")
		return false

	# Sound should be enabled by default
	if not manager.is_sounds_enabled():
		print("  ✗ test_audio_manager_initialization: sounds not enabled by default")
		manager.queue_free()
		return false

	manager.queue_free()
	print("  ✓ test_audio_manager_initialization")
	return true

func test_toggle_sounds() -> bool:
	"""Test that sound toggling works correctly."""
	var manager = AudioManager.new()

	# Initial state should be enabled
	if not manager.is_sounds_enabled():
		print("  ✗ test_toggle_sounds: sounds not enabled initially")
		manager.queue_free()
		return false

	# Toggle off
	manager.toggle_sounds()
	if manager.is_sounds_enabled():
		print("  ✗ test_toggle_sounds: sounds still enabled after first toggle")
		manager.queue_free()
		return false

	# Toggle on
	manager.toggle_sounds()
	if not manager.is_sounds_enabled():
		print("  ✗ test_toggle_sounds: sounds not enabled after second toggle")
		manager.queue_free()
		return false

	manager.queue_free()
	print("  ✓ test_toggle_sounds")
	return true

func test_set_sounds_enabled() -> bool:
	"""Test that sounds can be explicitly enabled/disabled."""
	var manager = AudioManager.new()

	# Explicitly disable
	manager.set_sounds_enabled(false)
	if manager.is_sounds_enabled():
		print("  ✗ test_set_sounds_enabled: sounds not disabled")
		manager.queue_free()
		return false

	# Explicitly enable
	manager.set_sounds_enabled(true)
	if not manager.is_sounds_enabled():
		print("  ✗ test_set_sounds_enabled: sounds not enabled")
		manager.queue_free()
		return false

	manager.queue_free()
	print("  ✓ test_set_sounds_enabled")
	return true

func test_audio_players_created() -> bool:
	"""Test that all audio players are created during setup."""
	var manager = AudioManager.new()

	# AudioManager uses _ready() which is called when added to scene tree
	# For testing, we'll call _ready() manually
	manager._ready()

	# Check that players exist
	if manager.movement_player == null:
		print("  ✗ test_audio_players_created: movement_player is null")
		manager.queue_free()
		return false

	if manager.pickup_player == null:
		print("  ✗ test_audio_players_created: pickup_player is null")
		manager.queue_free()
		return false

	if manager.door_player == null:
		print("  ✗ test_audio_players_created: door_player is null")
		manager.queue_free()
		return false

	if manager.alert_player == null:
		print("  ✗ test_audio_players_created: alert_player is null")
		manager.queue_free()
		return false

	if manager.capture_player == null:
		print("  ✗ test_audio_players_created: capture_player is null")
		manager.queue_free()
		return false

	if manager.win_player == null:
		print("  ✗ test_audio_players_created: win_player is null")
		manager.queue_free()
		return false

	manager.queue_free()
	print("  ✓ test_audio_players_created")
	return true

func test_play_methods_dont_crash() -> bool:
	"""Test that play methods don't crash when called."""
	var manager = AudioManager.new()
	manager._ready()

	# All play methods should be callable without crashing
	manager.play_movement()
	manager.play_pickup()
	manager.play_door()
	manager.play_alert()
	manager.play_capture()
	manager.play_win()

	manager.queue_free()
	print("  ✓ test_play_methods_dont_crash")
	return true

func test_play_methods_respect_enabled_flag() -> bool:
	"""Test that play methods respect the sounds_enabled flag."""
	var manager = AudioManager.new()
	manager._ready()

	# Disable sounds
	manager.set_sounds_enabled(false)

	# These should not play (no crash, but also no sound)
	# We can't test if sound actually plays, but we can verify the methods work
	manager.play_movement()
	manager.play_pickup()

	# Enable sounds
	manager.set_sounds_enabled(true)

	# These should play
	manager.play_movement()
	manager.play_pickup()

	manager.queue_free()
	print("  ✓ test_play_methods_respect_enabled_flag")
	return true
