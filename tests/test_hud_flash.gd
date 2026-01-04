extends RefCounted
## Test suite for HUD flash effect (Issue #90)

const HUD = preload("res://scripts/hud.gd")

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

func test_hud_has_flash_red_method() -> bool:
	"""Test that HUD class has flash_red method."""
	# Check if the script has the method defined
	var script = load("res://scripts/hud.gd")
	var methods = script.get_script_method_list()
	var has_flash_red = false

	for method in methods:
		if method.name == "flash_red":
			has_flash_red = true
			break

	if not has_flash_red:
		print("  ✗ test_hud_has_flash_red_method: HUD missing flash_red() method")
		return false

	print("  ✓ test_hud_has_flash_red_method")
	return true

func test_flash_implementation_exists() -> bool:
	"""Test that flash_red implementation is present in the script."""
	var script_path = "res://scripts/hud.gd"
	var file = FileAccess.open(script_path, FileAccess.READ)

	if not file:
		print("  ✗ test_flash_implementation_exists: Could not read hud.gd")
		return false

	var content = file.get_as_text()
	file.close()

	# Check for flash_red function and tween animation
	var has_function = "func flash_red()" in content
	var has_tween = "create_tween()" in content
	var has_flash_overlay = "flash_overlay" in content

	if not has_function or not has_tween or not has_flash_overlay:
		print("  ✗ test_flash_implementation_exists: Missing implementation components")
		return false

	print("  ✓ test_flash_implementation_exists")
	return true
