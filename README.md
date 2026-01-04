```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ███████╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗██████╗ ███████╗   ║
║   ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██║██╔══██╗██╔════╝   ║
║   ███████╗███████║██████╔╝██████╔╝███████║██║██████╔╝█████╗     ║
║   ╚════██║██╔══██║██╔═══╝ ██╔═══╝ ██╔══██║██║██╔══██╗██╔══╝     ║
║   ███████║██║  ██║██║     ██║     ██║  ██║██║██║  ██║███████╗   ║
║   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝   ║
║                                                                   ║
║          ██████╗ ███████╗███████╗██╗  ██╗██╗██╗   ██╗███████╗   ║
║          ██╔══██╗██╔════╝██╔════╝██║  ██║██║██║   ██║██╔════╝   ║
║          ██████╔╝█████╗  █████╗  ███████║██║██║   ██║█████╗     ║
║          ██╔══██╗██╔══╝  ██╔══╝  ██╔══██║██║╚██╗ ██╔╝██╔══╝     ║
║          ██████╔╝███████╗███████╗██║  ██║██║ ╚████╔╝ ███████╗   ║
║          ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝   ║
║                                                                   ║
║                    ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗ ║
║                    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗║
║                    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║║
║                    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║║
║                    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝║
║                    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝ ║
║                                                                   ║
║                        TERMINAL HEIST                             ║
║                   ASCII Stealth Roguelite                         ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

# Terminal Heist

**A turn-based stealth roguelite rendered entirely in ASCII**

Infiltrate procedurally generated facility floors, steal Data Shards, and escape while avoiding patrolling guards. Every keypress is one turn. Every run is deterministic and replayable with seeds.

## High Concept

You are `@`, a data thief breaking into secure facilities presented as a terminal display (ASCII grid). Navigate through procedurally generated floors, collect the Data Shard (`$`), and reach the Exit (`>`) without being caught by patrolling Guards (`G`).

**Key Features:**
- **Turn-based stealth:** Every action matters. Plan your moves carefully.
- **Deterministic gameplay:** Same seed = same floor layout and outcomes
- **Pure ASCII presentation:** No external assets required - just colored text
- **Roguelite progression:** 3 floors per run with increasing difficulty
- **Fully testable:** Core gameplay is pure logic, highly unit-tested

## How to Play

### Objective
- **Per Floor:** Pick up the Data Shard (`$`), then reach the Exit (`>`)
- **Win Condition:** Complete all 3 floors
- **Lose Condition:** A guard moves onto your tile (you're caught)
- **Score:** Shards collected + floor bonuses - turn penalties

### ASCII Tile Legend

```
@  Player (you)
#  Wall
.  Floor
D  Closed door (blocks movement)
k  Keycard (unlock doors)
$  Data Shard (must collect to enable exit)
>  Exit (only usable after collecting shard)
G  Guard (avoid at all costs!)
?  Unknown/Fog (optional feature)
```

### Controls

| Action | Keys | Description |
|--------|------|-------------|
| **Move** | Arrow Keys or WASD | Move one tile in a direction |
| **Wait** | Space | Pass a turn without moving |
| **Interact** | E | Open door (if you have keycard) / Pick up item |
| **Restart Run** | R | Start a new run |
| **Pause** | Esc | Pause the game |

### Game Flow

1. **Start Run** - Optionally enter a seed for reproducible gameplay
2. **Floor Generation** - Layout, items, guards, and positions are placed
3. **Player Turn** - You move/act (one action per turn)
4. **Guard Turn** - All guards respond after your action
5. **Win/Lose Check** - Did you escape? Were you caught?
6. **Next Floor or Game Over** - Progress or see your final score

### Guard Behavior

Guards have two modes:

- **Patrol Mode:** Follow predefined paths or wander with wall avoidance
- **Chase Mode:** If you're in line-of-sight (same row/column with no walls/doors), guards will pathfind toward you

**Capture Rule:** If a guard moves onto your tile, you lose immediately.

## Getting Started

### Prerequisites

- [Godot Engine 4.6](https://godotengine.org/download) or later

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/SapphireBeehiveStudios/godot-example.git
   cd godot-example
   ```

2. Open the project in Godot:
   ```bash
   godot project.godot
   ```

   Or use the Godot editor's "Import" button and select the `project.godot` file.

### Running the Game

#### Using Godot Editor
- Open the project in Godot
- Press F5 or click the "Run Project" button

#### Using Command Line
```bash
# Run the game
godot

# Run in headless mode (for testing/automation)
godot --headless
```

## Project Structure

```
godot-example/
├── .git/                   # Git repository data
├── .githooks/              # Pre-commit hooks for testing
├── .gitignore              # Git ignore rules
├── scenes/                 # Game scenes (.tscn files)
│   ├── main.tscn          # Main menu and orchestration
│   ├── game_screen.tscn   # In-game display
│   └── end_screen.tscn    # Game over / victory screen
├── scripts/                # GDScript logic files (.gd)
│   ├── grid_map.gd        # Grid/tile system
│   ├── level_gen.gd       # Procedural generation
│   ├── turn_system.gd     # Turn-based gameplay logic
│   ├── pathfinding.gd     # Guard AI pathfinding
│   ├── game_state.gd      # Score, inventory, flags
│   ├── save_system.gd     # Save/load persistence
│   └── renderer.gd        # ASCII rendering with BBCode
├── tests/                  # Unit tests (headless-compatible)
│   ├── test_runner.gd     # Test suite runner
│   ├── test_level_gen.gd  # Generation tests
│   ├── test_pathfinding.gd # AI tests
│   └── test_turn_system.gd # Gameplay logic tests
├── resources/              # Game configuration resources
├── icon.svg                # Project icon
├── project.godot           # Godot project configuration
└── README.md               # This file
```

## Development

### Testing

This project is built with testability as a core principle. All game logic is pure and deterministic, making it perfect for headless testing:

```bash
# Run all unit tests
godot --headless -s res://tests/test_runner.gd

# Validate project scripts and scenes
godot --headless --validate-project

# Check syntax without running
godot --headless --check-only
```

#### Test Coverage

The test suite covers:

- **Level Generation:** Determinism, reachability, valid placement
- **Pathfinding:** BFS/A* correctness, no-path handling
- **Turn System:** Movement, interactions, guard AI, win/lose conditions
- **Save/Load:** Persistence, best score tracking, seed storage

#### Pre-commit Hooks

The project includes pre-commit hooks that automatically run the test suite before allowing commits:

**Installation:**
```bash
git config core.hooksPath .githooks
```

**What it does:**
- Runs the full test suite before each commit
- Blocks the commit if any tests fail
- Ensures all committed code passes tests

**Bypassing the hook (not recommended):**
```bash
git commit --no-verify
```

Only bypass the hook if you have a good reason and understand the implications.

### Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. **Install pre-commit hooks** (recommended):
   ```bash
   git config core.hooksPath .githooks
   ```
   This will automatically run tests before each commit to ensure code quality.
3. Make your changes
4. Write/update tests for your changes
5. Commit your changes (`git commit -m 'feat: add amazing feature'`)
   - Tests will run automatically before the commit
   - Commit will be blocked if tests fail
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Branch Protection

- Direct pushes to `main` are blocked
- All changes must go through pull requests
- Feature branches should follow the naming convention: `claude/issue-N-description` or `feature/description`

## Architecture

### Design Philosophy

**Agent-Friendly Architecture:** This game is designed to be developed and tested in a headless sandbox environment:

- **No external assets:** ASCII rendering uses only built-in fonts and BBCode colors
- **Pure logic core:** Game systems are `RefCounted` classes with no scene dependencies
- **Highly testable:** Deterministic gameplay enables comprehensive unit testing
- **Thin presentation layer:** Rendering is a simple grid-to-BBCode conversion

### Core Systems

#### 1. Deterministic Grid World
- Grid-based tile system (e.g., 24×14)
- Seed-driven generation ensures reproducibility
- Given the same seed, floor number, and inputs → same outcome

#### 2. Turn Manager
Strict turn sequence:
1. Player action resolves (move/wait/interact)
2. Pickups resolve (keycard/shard collection)
3. Guards act (each guard moves once)
4. Win/lose conditions checked

#### 3. Procedural Level Generation
- Guarantees: Start → Shard → Exit all reachable
- Carve rooms + corridors or random walk approach
- Place start, shard, exit with distance constraints
- Add doors + keys (at least 1 key if doors exist)

#### 4. Guard AI
- **Patrol State:** Follow loops or random walk with wall avoidance
- **Chase State:** If player in line-of-sight, pathfind toward player
- **Pathfinding:** BFS/A* on grid (no diagonals)
- **Capture:** Guard on player tile = immediate game over

#### 5. UI Screens
- **Main Menu:** Start run, seed input, controls, quit
- **In-Game HUD:** Floor number, turns, inventory, score, message log
- **End Screen:** Result, final score, best score, seed used

#### 6. Persistence
- Save file: `user://save.json`
- Stores: Best score, last seed, run statistics

## Technical Details

### Configuration

The project uses Godot 4.6 with:

- **Engine Version:** Godot 4.6
- **Rendering:** Forward Plus
- **Canvas Texture Filter:** Nearest neighbor (pixel art friendly)
- **Input Map:** Custom actions defined in `project.godot`

### Rendering

The entire game is rendered using a single `RichTextLabel` with BBCode for colors:

- Player: Cyan (`@`)
- Guards: Red (`G`)
- Shard: Yellow (`$`)
- Walls: Gray (`#`)
- Floor: Dark gray (`.`)

No sprites, textures, or external assets required.

### Deterministic Gameplay

Every run is reproducible:
- Enter a seed (string or integer) to replay the exact same floors
- Same inputs on same seed = same outcome
- Perfect for debugging, sharing challenging runs, or competitive play

## Stretch Goals

Potential future enhancements:

- **Fog of War:** Only reveal tiles within vision radius
- **Multiple Guard Types:**
  - Sentry (stationary, long line-of-sight)
  - Wanderer (pure random movement)
- **Gadgets:**
  - Noise Ping to distract guards for N turns
- **Daily Seed Mode:** Seed derived from date for daily challenges
- **Accessibility:** Colorblind-friendly palette, high contrast mode

## License

This is a test/example project. Please check with SapphireBeehiveStudios for licensing information.

## Support

For issues, questions, or contributions, please use the GitHub issue tracker:
https://github.com/SapphireBeehiveStudios/godot-example/issues

## Acknowledgments

- Built with [Godot Engine](https://godotengine.org/)
- Inspired by classic roguelikes and ASCII stealth games
- Part of the SapphireBeehiveStudios development workflow
