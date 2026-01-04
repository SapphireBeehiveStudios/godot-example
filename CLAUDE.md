# CLAUDE.md - AI Agent Development Guide

This file provides context for AI agents (Claude Code, Cursor, etc.) working on this Godot project.

## Project Overview

**Terminal Heist** is a turn-based ASCII stealth roguelite built with Godot 4.x. The game uses pure GDScript with no external assets - everything is rendered as colored text in a RichTextLabel.

### Architecture

```
Terminal Heist
├── Core Systems (scripts/)
│   ├── turn_system.gd      # Turn-based game loop, player movement
│   ├── game_state.gd       # Persistent state (score, keycards, seed)
│   ├── game_manager.gd     # High-level game flow orchestration
│   ├── guard_system.gd     # Guard AI and patrol management
│   ├── dungeon_generator.gd # Procedural floor generation
│   └── renderer.gd         # ASCII grid → BBCode conversion
├── Utilities (scripts/utils/)
│   └── placement_validator.gd  # Entity placement rules
├── UI (scripts/)
│   └── main_menu.gd        # Menu and seed entry
├── Presentation
│   ├── ascii_title.gd      # ASCII art title screen
│   └── scenes/             # Godot scene files
└── Tests (tests/)
    └── test_*.gd           # GUT-style unit tests
```

## Development Conventions

### GDScript Style

```gdscript
extends RefCounted
## ClassName - Brief description
##
## Detailed documentation about what this class does.
## Reference issue numbers: Issue #XX

## Signal documentation
signal something_happened(param: Type)

## Constants at top
const SOME_VALUE: int = 42

## Typed variables with defaults
var my_var: int = 0
var my_dict: Dictionary = {}

## Functions with type hints and docstrings
func do_something(param: String) -> bool:
    """Brief description of what this function does."""
    return true
```

### File Naming

- **Scripts:** `snake_case.gd` (e.g., `turn_system.gd`, `game_state.gd`)
- **Tests:** `test_<module>.gd` (e.g., `test_turn_system.gd`)
- **Scenes:** `snake_case.tscn`

### Test Patterns

Tests use a custom GUT-compatible runner. Each test file follows this pattern:

```gdscript
extends RefCounted
## Test suite for ModuleName

const Module = preload("res://scripts/module.gd")

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

func test_something() -> bool:
    var module = Module.new()
    var result = module.do_thing()
    if result != expected:
        print("  ✗ test_something: expected %s, got %s" % [expected, result])
        return false
    print("  ✓ test_something")
    return true
```

## Common Pitfalls & Lessons Learned

### 1. Test Runner Merge Conflicts (CRITICAL)

**Problem:** The `tests/test_runner.gd` file has a hardcoded list of test modules. Every PR that adds tests modifies this file, causing constant merge conflicts.

**Current State:** Issue #79 tracks refactoring to auto-discovery.

**Workaround:** When adding new tests, be aware your PR will likely conflict with others. The test runner will be refactored to auto-discover `test_*.gd` files.

**Future Pattern (once #79 merges):**
```gdscript
# Auto-discovery - just create test_*.gd files, no registration needed
func _get_test_modules() -> Array:
    var modules = []
    var dir = DirAccess.open("res://tests/")
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.begins_with("test_") and file.ends_with(".gd") and file != "test_runner.gd":
            modules.append("res://tests/" + file)
        file = dir.get_next()
    modules.sort()
    return modules
```

### 2. Door Type Naming

The codebase uses different door type names in different places:
- `"door"` - generic door (newer code)
- `"door_closed"` / `"door_open"` - stateful doors (older code)

**Best Practice:** Use `"door_closed"` and `"door_open"` for stateful doors that can be interacted with. Check existing code for consistency.

### 3. Deterministic RNG

All randomness MUST use the seeded `RandomNumberGenerator`:

```gdscript
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
rng.seed = run_seed  # Set from game state

# Use rng methods, NOT global randf()/randi()
var value = rng.randf_range(0.0, 1.0)
var index = rng.randi_range(0, array.size() - 1)
```

### 4. Vector2i for Grid Positions

Always use `Vector2i` (not `Vector2`) for grid coordinates:

```gdscript
var pos: Vector2i = Vector2i(5, 3)
var grid: Dictionary = {}  # Keys are Vector2i
grid[pos] = {"type": "floor"}
```

### 5. BBCode Rendering

The renderer outputs BBCode for RichTextLabel. Color tags must be closed:

```gdscript
# Correct
"[color=#ff0000]@[/color]"

# Wrong - missing close tag
"[color=#ff0000]@"
```

### 6. Preload vs Load

Use `preload` for compile-time constants, `load` for runtime:

```gdscript
# Good - resolved at compile time
const GameState = preload("res://scripts/game_state.gd")

# Also fine - when path might vary
var script = load("res://scripts/" + script_name + ".gd")
```

## Running Tests

```bash
# Run all tests (from project root)
godot --headless -s res://tests/test_runner.gd

# Expected output:
# ============================================================
# Running Test Suite - Godot Example Project
# ============================================================
# [test_smoke.gd]
#   ✓ test_godot_version
# ...
# ============================================================
# ✓ All tests passed! (XXX tests)
# ============================================================
```

## Issue Labels

| Label | Meaning |
|-------|---------|
| `P0` | Critical - blocks other work |
| `P1` | High priority - core feature |
| `P2` | Medium priority |
| `agent-ready` | Ready for AI agent to pick up |
| `in-progress` | Currently being worked on |
| `agent-complete` | AI agent finished, PR created |
| `agent-failed` | AI agent encountered error |

## PR Workflow

1. **Branch naming:** `claude/issue-<number>-<timestamp>` or `feature/<description>`
2. **Commit messages:** Use conventional commits
   ```
   feat(turn-system): add door interaction logic
   
   - Doors block movement when closed
   - Keycards can open doors
   - Fixes #21
   ```
3. **PR titles:** `Fix: <Issue Title>` or `Feat: <Description>`
4. **Auto-merge:** PRs go through merge queue for CI checks

## Key Files Reference

| File | Purpose |
|------|---------|
| `project.godot` | Godot project config, input mappings |
| `game_state.gd` | Core state: floor, turns, score, seed |
| `turn_system.gd` | Player movement, pickups, win/lose |
| `guard_system.gd` | Guard AI, patrol routes, detection |
| `dungeon_generator.gd` | Procedural level generation |
| `renderer.gd` | Grid → ASCII BBCode conversion |
| `tests/test_runner.gd` | Test orchestration |

## Entity Types

| Character | Type | Description |
|-----------|------|-------------|
| `@` | player | The player character |
| `G` | guard | Patrolling enemy |
| `#` | wall | Impassable terrain |
| `.` | floor | Walkable space |
| `$` | shard | Data shard (collect to unlock exit) |
| `>` | exit | Level exit (requires shard) |
| `+` | door_closed | Closed door (requires keycard) |
| `/` | door_open | Open door (walkable) |
| `k` | keycard | Pickup to open doors |

## Quick Commands

```bash
# Run the game
godot --path . res://scenes/main.tscn

# Run tests
godot --headless -s res://tests/test_runner.gd

# Export (if configured)
godot --headless --export-release "Linux/X11" build/terminal-heist.x86_64
```

---

*Last updated: January 2026*
*Generated from lessons learned during AI-assisted development*
