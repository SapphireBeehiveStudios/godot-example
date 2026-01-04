extends CanvasLayer
## HelpOverlay - In-game help and controls display
##
## Shows:
## - Movement controls (WASD/Arrow keys)
## - Action controls (Space, E, R, H, Esc)
## - Game rules and objectives
## - Entity legend
##
## Toggle with H key, dismissible
## Part of Issue #91

@onready var panel: Panel = $Panel
@onready var help_text: RichTextLabel = $Panel/MarginContainer/HelpText

func _ready() -> void:
	"""Initialize the help overlay."""
	visible = false
	setup_help_text()

func setup_help_text() -> void:
	"""Set up the help text content with BBCode formatting."""
	var text = """[center][b][color=#00ff00]TERMINAL HEIST - HELP[/color][/b][/center]

[b][color=#ffff00]OBJECTIVE:[/color][/b]
• Collect the Data Shard ([color=#00ffff]$[/color])
• Reach the Exit ([color=#00ff00]>[/color])
• Avoid or evade Guards ([color=#ff0000]G[/color])

[b][color=#ffff00]CONTROLS:[/color][/b]
[color=#aaaaaa]Movement:[/color]
  W / ↑    - Move up
  A / ←    - Move left
  S / ↓    - Move down
  D / →    - Move right
  Space    - Wait (skip turn)

[color=#aaaaaa]Actions:[/color]
  E        - Interact (open doors with keycards)
  R        - Restart current floor
  H        - Toggle this help screen
  M        - Toggle sound effects
  Esc      - Pause game

[b][color=#ffff00]ENTITIES:[/color][/b]
  [color=#00ff00]@[/color]  - You (the player)
  [color=#ff0000]G[/color]  - Guard (avoid detection!)
  [color=#808080]#[/color]  - Wall (impassable)
  [color=#666666].[/color]  - Floor (walkable)
  [color=#00ffff]$[/color]  - Data Shard (collect to unlock exit)
  [color=#00ff00]>[/color]  - Exit (reach after collecting shard)
  [color=#ffaa00]+[/color]  - Door (closed, needs keycard)
  [color=#ffaa00]/[/color]  - Door (open)
  [color=#ffff00]k[/color]  - Keycard (collect to open doors)

[b][color=#ffff00]GAMEPLAY TIPS:[/color][/b]
• This is a turn-based game - enemies move when you do
• Guards patrol in patterns - observe and time your moves
• Use doors strategically to block guard lines of sight
• Each floor gets progressively harder
• Your score is based on speed and efficiency

[center][color=#888888]Press H to close this help screen[/color][/center]"""

	help_text.text = text

func toggle_visibility() -> void:
	"""Toggle the help overlay on/off."""
	visible = not visible

func show_help() -> void:
	"""Show the help overlay."""
	visible = true

func hide_help() -> void:
	"""Hide the help overlay."""
	visible = false

func is_visible_overlay() -> bool:
	"""Check if the overlay is currently visible."""
	return visible
