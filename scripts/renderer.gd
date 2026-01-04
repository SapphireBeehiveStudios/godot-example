extends RefCounted
## Renderer - Convert grid state to BBCode with fancy ASCII art sprites
##
## Renders the game with large ASCII art tiles and guard alert states.

## Preload guard system for state enum
const GuardSystem = preload("res://scripts/guard_system.gd")

## Colors
const COLOR_PLAYER := "#00ffff"
const COLOR_GUARD_PATROL := "#888888"
const COLOR_GUARD_ALERT := "#ffaa00"
const COLOR_GUARD_CHASE := "#ff0000"
const COLOR_WALL := "#444455"
const COLOR_FLOOR := "#222233"
const COLOR_WATER := "#4488ff"
const COLOR_DOOR_OPEN := "#44ff44"
const COLOR_DOOR_CLOSED := "#ff8800"
const COLOR_KEYCARD := "#ffff00"
const COLOR_SHARD := "#ff44ff"
const COLOR_EXIT := "#00ff88"
const COLOR_HIDE := "#335533"

const SPRITE_WIDTH := 3
const SPRITE_HEIGHT := 3

## ASCII art sprites
const SPRITES := {
	"player": [
		" ◉ ",
		"▄█▄",
		"▀ ▀"
	],
	"guard_patrol": [
		" ● ",
		"▄█▄",
		"▀ ▀"
	],
	"guard_alert": [
		"!▼!",
		"▄█▄",
		"▀ ▀"
	],
	"guard_chase": [
		"»█«",
		"▄█▄",
		"▀▀▀"
	],
	"wall": [
		"▓▓▓",
		"▓▓▓",
		"▓▓▓"
	],
	"floor": [
		"   ",
		" · ",
		"   "
	],
	"water": [
		"≈≈≈",
		"≈≈≈",
		"≈≈≈"
	],
	"door_open": [
		"┌ ┐",
		"   ",
		"└ ┘"
	],
	"door_closed": [
		"╔═╗",
		"║█║",
		"╚═╝"
	],
	"keycard": [
		" ◆ ",
		"═╬═",
		" ║ "
	],
	"shard": [
		" ◆ ",
		"◆◆◆",
		" ◆ "
	],
	"exit": [
		"╔▲╗",
		"║ ║",
		"╚═╝"
	],
	"hide": [
		"###",
		"# #",
		"###"
	],
	"empty": [
		"   ",
		"   ",
		"   "
	]
}

## Guard states for rendering
var guard_states: Dictionary = {}

func set_guard_states(states: Dictionary) -> void:
	guard_states = states

func render_grid(grid: Dictionary, player_pos: Vector2i, guard_positions: Array[Vector2i]) -> String:
	if grid.is_empty():
		return ""

	var bounds := _calculate_bounds(grid, player_pos, guard_positions)
	if bounds.is_empty():
		return ""

	var min_x: int = bounds["min_x"]
	var max_x: int = bounds["max_x"]
	var min_y: int = bounds["min_y"]
	var max_y: int = bounds["max_y"]

	var guard_set := {}
	for pos in guard_positions:
		guard_set[pos] = true

	var output_lines: Array[String] = []

	for y in range(min_y, max_y + 1):
		var sprite_rows: Array[Array] = []
		for i in range(SPRITE_HEIGHT):
			sprite_rows.append([])

		for x in range(min_x, max_x + 1):
			var pos := Vector2i(x, y)
			var sprite_data := _get_sprite_at_position(pos, player_pos, guard_set, grid)
			var sprite: Array = sprite_data["sprite"]
			var color: String = sprite_data["color"]

			for row_idx in range(SPRITE_HEIGHT):
				sprite_rows[row_idx].append(_colorize(sprite[row_idx], color))

		for row in sprite_rows:
			output_lines.append("".join(row))

	return "\n".join(output_lines)


func _calculate_bounds(grid: Dictionary, player_pos: Vector2i, guard_positions: Array[Vector2i]) -> Dictionary:
	if grid.is_empty():
		return {}

	var positions: Array[Vector2i] = []
	positions.append_array(grid.keys())
	positions.append(player_pos)
	positions.append_array(guard_positions)

	if positions.is_empty():
		return {}

	var min_x := positions[0].x
	var max_x := positions[0].x
	var min_y := positions[0].y
	var max_y := positions[0].y

	for pos in positions:
		min_x = mini(min_x, pos.x)
		max_x = maxi(max_x, pos.x)
		min_y = mini(min_y, pos.y)
		max_y = maxi(max_y, pos.y)

	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}


func _get_sprite_at_position(pos: Vector2i, player_pos: Vector2i, guard_set: Dictionary, grid: Dictionary) -> Dictionary:
	# Player
	if pos == player_pos:
		return {"sprite": SPRITES["player"], "color": COLOR_PLAYER}

	# Guards with state-based appearance
	if guard_set.has(pos):
		if guard_states.has(pos):
			var state = guard_states[pos]
			match state:
				GuardSystem.GuardState.ALERT:
					return {"sprite": SPRITES["guard_alert"], "color": COLOR_GUARD_ALERT}
				GuardSystem.GuardState.CHASE:
					return {"sprite": SPRITES["guard_chase"], "color": COLOR_GUARD_CHASE}
				_:
					return {"sprite": SPRITES["guard_patrol"], "color": COLOR_GUARD_PATROL}
		return {"sprite": SPRITES["guard_patrol"], "color": COLOR_GUARD_PATROL}

	# Tiles
	if grid.has(pos):
		var tile_data: Dictionary = grid[pos]
		var tile_type: String = tile_data.get("type", "")

		match tile_type:
			"wall":
				return {"sprite": SPRITES["wall"], "color": COLOR_WALL}
			"floor":
				return {"sprite": SPRITES["floor"], "color": COLOR_FLOOR}
			"water":
				return {"sprite": SPRITES["water"], "color": COLOR_WATER}
			"door_open":
				return {"sprite": SPRITES["door_open"], "color": COLOR_DOOR_OPEN}
			"door_closed":
				return {"sprite": SPRITES["door_closed"], "color": COLOR_DOOR_CLOSED}
			"hide":
				return {"sprite": SPRITES["hide"], "color": COLOR_HIDE}
			"pickup":
				var pickup_type: String = tile_data.get("pickup_type", "")
				if pickup_type == "keycard":
					return {"sprite": SPRITES["keycard"], "color": COLOR_KEYCARD}
				elif pickup_type == "shard":
					return {"sprite": SPRITES["shard"], "color": COLOR_SHARD}
				return {"sprite": SPRITES["floor"], "color": COLOR_FLOOR}
			"exit":
				return {"sprite": SPRITES["exit"], "color": COLOR_EXIT}
			_:
				return {"sprite": SPRITES["floor"], "color": COLOR_FLOOR}

	return {"sprite": SPRITES["empty"], "color": COLOR_FLOOR}


func _colorize(text: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, text]
