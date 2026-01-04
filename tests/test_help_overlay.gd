extends RefCounted
## Test suite for HelpOverlay
##
## Tests help overlay visibility toggling and content.
## Part of Issue #91

const HelpOverlay = preload("res://scripts/help_overlay.gd")

func run_all() -> Dictionary:
	"""Run all tests and return {passed: int, failed: int}."""
	var passed := 0
	var failed := 0

	# Run each test
	if test_help_overlay_starts_hidden():
		passed += 1
	else:
		failed += 1

	if test_toggle_visibility():
		passed += 1
	else:
		failed += 1

	if test_show_hide_methods():
		passed += 1
	else:
		failed += 1

	if test_is_visible_overlay():
		passed += 1
	else:
		failed += 1

	return {"passed": passed, "failed": failed}

func test_help_overlay_starts_hidden() -> bool:
	"""Test that help overlay is hidden on initialization."""
	# Load the scene
	var scene = load("res://scenes/help_overlay.tscn")
	var overlay = scene.instantiate()

	# Manually call _ready since we're not adding to tree
	overlay._ready()

	if overlay.visible != false:
		print("  ✗ test_help_overlay_starts_hidden: expected hidden, got visible")
		overlay.free()
		return false

	overlay.free()
	print("  ✓ test_help_overlay_starts_hidden")
	return true

func test_toggle_visibility() -> bool:
	"""Test toggling visibility."""
	var scene = load("res://scenes/help_overlay.tscn")
	var overlay = scene.instantiate()
	overlay._ready()

	var initial_state = overlay.visible
	overlay.toggle_visibility()
	var toggled_state = overlay.visible

	if initial_state == toggled_state:
		print("  ✗ test_toggle_visibility: state did not change after toggle")
		overlay.free()
		return false

	overlay.toggle_visibility()
	var toggled_back = overlay.visible

	if initial_state != toggled_back:
		print("  ✗ test_toggle_visibility: state did not return to initial after second toggle")
		overlay.free()
		return false

	overlay.free()
	print("  ✓ test_toggle_visibility")
	return true

func test_show_hide_methods() -> bool:
	"""Test show and hide methods."""
	var scene = load("res://scenes/help_overlay.tscn")
	var overlay = scene.instantiate()
	overlay._ready()

	overlay.show_help()
	if not overlay.visible:
		print("  ✗ test_show_hide_methods: show_help() did not make overlay visible")
		overlay.free()
		return false

	overlay.hide_help()
	if overlay.visible:
		print("  ✗ test_show_hide_methods: hide_help() did not hide overlay")
		overlay.free()
		return false

	overlay.free()
	print("  ✓ test_show_hide_methods")
	return true

func test_is_visible_overlay() -> bool:
	"""Test is_visible_overlay method."""
	var scene = load("res://scenes/help_overlay.tscn")
	var overlay = scene.instantiate()
	overlay._ready()

	overlay.hide_help()
	if overlay.is_visible_overlay():
		print("  ✗ test_is_visible_overlay: reported visible when hidden")
		overlay.free()
		return false

	overlay.show_help()
	if not overlay.is_visible_overlay():
		print("  ✗ test_is_visible_overlay: reported hidden when visible")
		overlay.free()
		return false

	overlay.free()
	print("  ✓ test_is_visible_overlay")
	return true
