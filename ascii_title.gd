extends Node
## ASCII Art Title Display
##
## This script displays a fancy ASCII art title for the SapphireBeehiveStudios Godot Example project.
## Can be used as an autoload or called directly from other scripts.

## Get the ASCII art title as a string
static func get_title() -> String:
	return """
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ███████╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗██████╗ ███████╗     ║
║   ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██║██╔══██╗██╔════╝     ║
║   ███████╗███████║██████╔╝██████╔╝███████║██║██████╔╝█████╗       ║
║   ╚════██║██╔══██║██╔═══╝ ██╔═══╝ ██╔══██║██║██╔══██╗██╔══╝       ║
║   ███████║██║  ██║██║     ██║     ██║  ██║██║██║  ██║███████╗     ║
║   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝     ║
║                                                                   ║
║          ██████╗ ███████╗███████╗██╗  ██╗██╗██╗   ██╗███████╗     ║
║          ██╔══██╗██╔════╝██╔════╝██║  ██║██║██║   ██║██╔════╝     ║
║          ██████╔╝█████╗  █████╗  ███████║██║██║   ██║█████╗       ║
║          ██╔══██╗██╔══╝  ██╔══╝  ██╔══██║██║╚██╗ ██╔╝██╔══╝       ║
║          ██████╔╝███████╗███████╗██║  ██║██║ ╚████╔╝ ███████╗     ║
║          ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝     ║
║                                                                   ║
║                   ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗   ║
║                   ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗  ║
║                   ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║  ║
║                   ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║  ║
║                   ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝  ║
║                   ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝   ║
║                                                                   ║
║                        Godot Example Project                      ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
"""

## Get a compact version of the title (smaller footprint)
static func get_title_compact() -> String:
	return """
╔══════════════════════════════════════════════════╗
║  ███████╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██████╗║
║  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔══██║
║  ███████╗███████║██████╔╝██████╔╝███████║██████╔║
║  ╚════██║██╔══██║██╔═══╝ ██╔═══╝ ██╔══██║██╔══██║
║  ███████║██║  ██║██║     ██║     ██║  ██║██║  ██║
║  ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═║
║                 Godot Example                    ║
╚══════════════════════════════════════════════════╝
"""

## Display the title to the console
static func print_title() -> void:
	print(get_title())

## Display the compact title to the console
static func print_title_compact() -> void:
	print(get_title_compact())

## Get the width of the title in characters
static func get_title_width() -> int:
	var lines = get_title().split("\n")
	var max_width = 0
	for line in lines:
		if line.length() > max_width:
			max_width = line.length()
	return max_width

## Get the height of the title in lines
static func get_title_height() -> int:
	var lines = get_title().split("\n")
	# Filter out empty lines at start/end
	var non_empty_lines = 0
	for line in lines:
		if line.strip_edges().length() > 0:
			non_empty_lines += 1
	return non_empty_lines

## Get the project name from the title
static func get_project_name() -> String:
	return "SapphireBeehive Studio - Godot Example"
