extends RefCounted
## Renderer - Convert grid state to BBCode for RichTextLabel
##
## Renders a text-based view of the game grid with entities.
## Legend:
##   @ = Player
##   G = Guard
##   # = Wall
##   . = Floor
##   D = Door (open/closed)
##   k = Keycard
##   $ = Shard
##   > = Exit
##   ^ = Trap
##
## Output is BBCode-formatted for use with RichTextLabel.
## Rendering is deterministic for snapshot testing.

## Color constants for BBCode formatting
const COLOR_PLAYER := "aqua"
const COLOR_GUARD := "red"
const COLOR_WALL := "gray"
const COLOR_FLOOR := "white"
const COLOR_DOOR_OPEN := "green"
const COLOR_DOOR_CLOSED := "yellow"
const COLOR_KEYCARD := "blue"
const COLOR_SHARD := "gold"
const COLOR_EXIT := "lime"
const COLOR_TRAP := "orange"

## Render the grid with all entities to a BBCode string
##
## @param grid: Dictionary mapping Vector2i to tile data
##              Tile data format: {"type": "wall"|"floor"|"pickup"|"exit", "pickup_type": "keycard"|"shard"}
## @param player_pos: Vector2i position of the player
## @param guard_positions: Array[Vector2i] positions of all guards
## @return BBCode-formatted string for RichTextLabel
func render_grid(grid: Dictionary, player_pos: Vector2i, guard_positions: Array[Vector2i]) -> String:
	if grid.is_empty():
		return ""

	# Determine grid bounds
	var bounds := _calculate_bounds(grid, player_pos, guard_positions)
	if bounds.is_empty():
		return ""

	var min_x: int = bounds["min_x"]
	var max_x: int = bounds["max_x"]
	var min_y: int = bounds["min_y"]
	var max_y: int = bounds["max_y"]

	# Convert guard positions to set for O(1) lookup
	var guard_set := {}
	for pos in guard_positions:
		guard_set[pos] = true

	# Build the grid string row by row
	var lines: Array[String] = []
	for y in range(min_y, max_y + 1):
		var row_chars: Array[String] = []
		for x in range(min_x, max_x + 1):
			var pos := Vector2i(x, y)
			var char_data := _get_character_at_position(pos, player_pos, guard_set, grid)
			row_chars.append(char_data)
		lines.append("".join(row_chars))

	return "\n".join(lines)


## Calculate the bounding box of the grid
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

	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y
	}


## Get the character and color for a specific position
func _get_character_at_position(pos: Vector2i, player_pos: Vector2i, guard_set: Dictionary, grid: Dictionary) -> String:
	# Priority: Player > Guards > Pickups/Exit > Tiles

	# Check for player
	if pos == player_pos:
		return _colorize("@", COLOR_PLAYER)

	# Check for guards
	if guard_set.has(pos):
		return _colorize("G", COLOR_GUARD)

	# Check for tile data
	if grid.has(pos):
		var tile_data: Dictionary = grid[pos]
		var tile_type: String = tile_data.get("type", "")

		match tile_type:
			"wall":
				return _colorize("#", COLOR_WALL)
			"floor":
				return _colorize(".", COLOR_FLOOR)
			"door_open":
				return _colorize("D", COLOR_DOOR_OPEN)
			"door_closed":
				return _colorize("D", COLOR_DOOR_CLOSED)
			"pickup":
				var pickup_type: String = tile_data.get("pickup_type", "")
				if pickup_type == "keycard":
					return _colorize("k", COLOR_KEYCARD)
				elif pickup_type == "shard":
					return _colorize("$", COLOR_SHARD)
				else:
					# Unknown pickup, render as floor
					return _colorize(".", COLOR_FLOOR)
			"exit":
				return _colorize(">", COLOR_EXIT)
			"trap":
				# Check if trap is armed or disarmed
				var is_armed: bool = tile_data.get("armed", true)
				if is_armed:
					return _colorize("^", COLOR_TRAP)
				else:
					# Disarmed traps render as floor
					return _colorize(".", COLOR_FLOOR)
			_:
				# Unknown type, render as floor
				return _colorize(".", COLOR_FLOOR)

	# Empty space (no tile data)
	return " "


## Wrap a character in BBCode color tags
func _colorize(character: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, character]
