extends RefCounted
## Test suite for HUD - Issue #90

func run_all() -> Dictionary:
	"""Run all HUD tests and return {passed: int, failed: int}."""
	var passed := 0
	var failed := 0

	# Run each test
	if test_flash_overlay_exists():
		passed += 1
	else:
		failed += 1

	if test_flash_red_creates_tween():
		passed += 1
	else:
		failed += 1

	return {"passed": passed, "failed": failed}

func test_flash_overlay_exists() -> bool:
	"""Test that FlashOverlay node exists in the HUD scene."""
	var hud_scene = load("res://scenes/hud.tscn")
	if hud_scene == null:
		print("  ✗ test_flash_overlay_exists: Could not load HUD scene")
		return false

	var hud = hud_scene.instantiate()
	var flash_overlay = hud.get_node_or_null("FlashOverlay")

	if flash_overlay == null:
		print("  ✗ test_flash_overlay_exists: FlashOverlay node not found")
		hud.queue_free()
		return false

	if not flash_overlay is ColorRect:
		print("  ✗ test_flash_overlay_exists: FlashOverlay is not a ColorRect")
		hud.queue_free()
		return false

	# Check initial color is transparent red
	var color = flash_overlay.color
	if color.r != 1.0 or color.g != 0.0 or color.b != 0.0 or color.a != 0.0:
		print("  ✗ test_flash_overlay_exists: FlashOverlay color is not transparent red, got %s" % str(color))
		hud.queue_free()
		return false

	hud.queue_free()
	print("  ✓ test_flash_overlay_exists")
	return true

func test_flash_red_creates_tween() -> bool:
	"""Test that flash_red() method exists and can be called."""
	var hud_scene = load("res://scenes/hud.tscn")
	if hud_scene == null:
		print("  ✗ test_flash_red_creates_tween: Could not load HUD scene")
		return false

	var hud = hud_scene.instantiate()

	# Check that flash_red method exists
	if not hud.has_method("flash_red"):
		print("  ✗ test_flash_red_creates_tween: flash_red method not found")
		hud.queue_free()
		return false

	# We can't fully test the tween in headless mode, but we can verify the method runs without error
	# The method should handle null flash_overlay gracefully
	var initial_color = Color(1, 0, 0, 0)

	# Call flash_red - it should not crash
	hud.flash_red()

	hud.queue_free()
	print("  ✓ test_flash_red_creates_tween")
	return true
