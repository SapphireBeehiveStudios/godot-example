#!/bin/bash
# TERMINAL HEIST - GitHub Issues Creation Script
# Run this script in a terminal with `gh` CLI authenticated
# Usage: ./create_issues.sh

set -e

REPO="SapphireBeehiveStudios/godot-example"

echo "Creating TERMINAL HEIST issues for $REPO..."
echo "============================================="

# Helper function to create issue
create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"

    echo "Creating: $title"
    if [ -n "$labels" ]; then
        gh issue create --repo "$REPO" --title "$title" --body "$body" --label "$labels"
    else
        gh issue create --repo "$REPO" --title "$title" --body "$body"
    fi
    echo "---"
    sleep 1  # Rate limiting
}

# =============================================================================
# EPIC 0 — Project Skeleton
# =============================================================================

create_issue "EPIC 0: Project Skeleton (Scenes, Input Map, Headless Tests)" "$(cat <<'EOF'
## Goal
Establish a runnable Godot project skeleton with minimal scenes and a headless test harness.

## Dependencies
None

## Acceptance Criteria

- [ ] `scenes/`, `scripts/`, `tests/`, `resources/` folder structure exists
- [ ] `Main.tscn` (menu shell), `GameScreen.tscn` (play shell), `EndScreen.tscn` (results shell) exist and switchable
- [ ] Input actions defined in `project.godot`:
  - `move_up/down/left/right`, `wait`, `interact`, `restart_run`, `pause`
- [ ] `res://tests/test_runner.gd` exists and runs in headless mode
- [ ] CI/local command succeeds: `godot --headless -s res://tests/test_runner.gd`

## Tests

- [ ] Add a single "smoke test" that always passes (verifies runner wiring)
EOF
)" "epic"

create_issue "[P0] Add headless test runner + example passing test" "$(cat <<'EOF'
## Description
Implement `tests/test_runner.gd` to discover and run test modules. Add `tests/test_smoke.gd` with one basic assertion.

## Dependencies
Part of EPIC 0

## Acceptance Criteria

- [ ] Headless run prints summary + exits non-zero on failure
- [ ] Smoke test passes in headless
EOF
)" "P0"

create_issue "[P0] Define input actions in project settings" "$(cat <<'EOF'
## Description
Add the input map entries required by the pitch (WASD/arrows + space/E/R/Esc).

## Dependencies
Part of EPIC 0

## Acceptance Criteria

- [ ] All actions exist and are bound to keys
- [ ] GameScreen can read actions without runtime errors
EOF
)" "P0"

# =============================================================================
# EPIC 1 — Core Logic Foundation
# =============================================================================

create_issue "EPIC 1: Core Logic Foundation (GridMap + GameState)" "$(cat <<'EOF'
## Goal
Build the deterministic, testable "pure logic" layer (no rendering dependencies).

## Dependencies
EPIC 0

## Acceptance Criteria

- [ ] `scripts/grid_map.gd` supports tiles, bounds, walkability, neighbor queries
- [ ] `scripts/game_state.gd` tracks: floor index, turn counter, inventory (keycards), shard flag, score
- [ ] Basic unit tests cover grid utilities + initial state defaults
EOF
)" "epic"

create_issue "[P0] Implement GridMap (tiles, bounds, walkability, neighbors)" "$(cat <<'EOF'
## Description
Create `GridMap` as a pure logic class (`RefCounted` or similar).

Tile types: wall, floor, door, exit (per pitch).
Provide `is_in_bounds`, `is_walkable`, `get_neighbors_4dir`, `set_tile`, `get_tile`.

## Dependencies
Part of EPIC 1

## Acceptance Criteria

- [ ] Works for configurable grid size (default e.g., 24x14)
- [ ] Door walkability is configurable by "door open/closed" state (MVP: closed blocks)

## Tests

- [ ] Bounds checks
- [ ] Neighbor list correct on edges
- [ ] Walkability returns expected values for each tile type
EOF
)" "P0"

create_issue "[P0] Implement GameState (inventory, flags, score, counters)" "$(cat <<'EOF'
## Description
Create `GameState` holding:
- `floor_number`, `turn_count`
- `keycards` (int)
- `shard_collected` (bool)
- `score` (int)
- `run_seed` (string/int)

## Dependencies
Part of EPIC 1

## Acceptance Criteria

- [ ] Defaults are sane and covered by tests
- [ ] State is serializable-friendly (for later save/load)

## Tests

- [ ] Default values test
- [ ] Mutations (add keycard, collect shard) update correctly
EOF
)" "P0"

# =============================================================================
# EPIC 2 — Turn System (Player-Only)
# =============================================================================

create_issue "EPIC 2: Turn System (Player Actions + Win Gating)" "$(cat <<'EOF'
## Goal
Implement deterministic, turn-based sequencing for player actions (guards later).

## Dependencies
EPIC 1

## Acceptance Criteria

- [ ] Player can move/wait/interact deterministically
- [ ] Pickups resolve after player action
- [ ] Exit is locked until shard is collected
- [ ] Turn count increments correctly
EOF
)" "epic"

create_issue "[P0] Implement TurnSystem core loop (player action → pickups → checks)" "$(cat <<'EOF'
## Description
Create `scripts/turn_system.gd` with strict order:
1. Resolve player action (move/wait/interact)
2. Resolve pickups on tile
3. Check win/lose (lose only later when guards exist; win gating here)

## Dependencies
Part of EPIC 2

## Acceptance Criteria

- [ ] One input == one turn (including wait)
- [ ] Deterministic outcomes given same seed + inputs

## Tests

- [ ] Move into wall fails (position unchanged)
- [ ] Wait increments turn count
- [ ] Pick up keycard increments inventory
EOF
)" "P0"

create_issue "[P0] Implement door + keycard interaction rules" "$(cat <<'EOF'
## Description
Doors (`D`) block movement while closed.
Interact opens door if player has keycard (or consumes it—define in code + tests; MVP recommendation: consume 1 keycard per door).

## Dependencies
Part of EPIC 2

## Acceptance Criteria

- [ ] Door blocks movement when closed
- [ ] Interact with door changes it to floor (or "open door" tile)
- [ ] Inventory rule enforced

## Tests

- [ ] Cannot open door without keycard
- [ ] Can open door with keycard (and keycard decremented if consuming)
EOF
)" "P0"

create_issue "[P0] Implement shard + exit gating" "$(cat <<'EOF'
## Description
Shard (`$`) must be collected to enable exit (`>`).
Exit interaction ends floor only when shard is collected.

## Dependencies
Part of EPIC 2

## Acceptance Criteria

- [ ] Shard pickup sets `shard_collected = true`
- [ ] Attempting exit without shard does nothing (log message later)
- [ ] Exit with shard triggers "floor complete" flag/event in state

## Tests

- [ ] Exit blocked until shard collected
- [ ] Exit succeeds after shard collected
EOF
)" "P0"

# =============================================================================
# EPIC 3 — Procedural Level Generation
# =============================================================================

create_issue "EPIC 3: Deterministic Level Generation (Seeded + Reachable)" "$(cat <<'EOF'
## Goal
Generate reproducible floors with guaranteed start→shard→exit reachability.

## Dependencies
EPIC 1 (GridMap), EPIC 2 (basic state wiring)

## Acceptance Criteria

- [ ] Same (seed + floor index) ⇒ identical layout hash + placements
- [ ] Exactly 1 start, 1 shard, 1 exit
- [ ] Reachability guaranteed (start→shard and shard→exit)
EOF
)" "epic"

create_issue "[P0] Implement deterministic RNG utilities (seed + floor index)" "$(cat <<'EOF'
## Description
Build a consistent way to derive per-floor RNG from run seed + floor number.
Ensure tests can reproduce.

## Dependencies
Part of EPIC 3

## Acceptance Criteria

- [ ] Deterministic across platforms/headless runs
- [ ] Documented seed format (string/int)

## Tests

- [ ] Same inputs produce same RNG sequence
EOF
)" "P0"

create_issue "[P0] Implement LevelGen MVP algorithm (rooms/corridors OR random walk carve)" "$(cat <<'EOF'
## Description
Implement `scripts/level_gen.gd` to produce:
- `GridMap`
- entity spawn positions (player start, guards later)
- item placements (keycard, shard)
- exit placement

## Dependencies
Part of EPIC 3

## Acceptance Criteria

- [ ] Produces a valid floor with floors/walls
- [ ] Places start/shard/exit on floor tiles
- [ ] Enforces minimum distance constraints (lightweight)

## Tests

- [ ] Determinism test: layout hash stable
- [ ] Validity test: correct counts of special tiles
EOF
)" "P0"

create_issue "[P0] Add reachability validation + retry loop (start→shard→exit)" "$(cat <<'EOF'
## Description
Use BFS (simple) to validate connectivity; regenerate if invalid.

## Dependencies
Part of EPIC 3

## Acceptance Criteria

- [ ] Start to shard path exists
- [ ] Shard to exit path exists
- [ ] Generation does not hang (cap retries, fail with clear error)

## Tests

- [ ] Reachability always true for N sample seeds
EOF
)" "P0"

create_issue "[P1] Add doors + keycard placement rule (if doors exist, at least 1 keycard)" "$(cat <<'EOF'
## Description
Sprinkle doors and place keycards such that the run isn't softlocked.

## Dependencies
Part of EPIC 3

## Acceptance Criteria

- [ ] If any doors are placed, at least one keycard is placed
- [ ] Keycard is reachable from start without needing itself (avoid deadlock)

## Tests

- [ ] "No softlock" test for door/key layouts
EOF
)" "P1"

# =============================================================================
# EPIC 4 — Guards + AI
# =============================================================================

create_issue "EPIC 4: Guards (Patrol + LoS Chase + Capture)" "$(cat <<'EOF'
## Goal
Add guard entities that act after the player each turn.

## Dependencies
EPIC 2 (TurnSystem), EPIC 3 (gen placements), plus pathfinding

## Acceptance Criteria

- [ ] Guards act once per turn after player
- [ ] Patrol behavior exists
- [ ] Line-of-sight detection (row/col, blocked by walls/doors)
- [ ] Chase behavior for N turns using BFS/A*
- [ ] Capture triggers immediate game over
EOF
)" "epic"

create_issue "[P0] Implement pathfinding (BFS on grid, 4-dir)" "$(cat <<'EOF'
## Description
Create `scripts/pathfinding.gd` with BFS shortest path function.

## Dependencies
Part of EPIC 4

## Acceptance Criteria

- [ ] Returns shortest path on known grid
- [ ] Returns empty/null when no path exists

## Tests

- [ ] Known-grid shortest path tests
- [ ] No-path case test
EOF
)" "P0"

create_issue "[P0] Implement Line-of-Sight (row/col, blockers)" "$(cat <<'EOF'
## Description
Add `grid_map.gd` LoS helper: same row/col, iterate tiles until target, blocked by walls/doors.

## Dependencies
Part of EPIC 4

## Acceptance Criteria

- [ ] Works for row and column cases
- [ ] Doors block LoS when closed

## Tests

- [ ] LoS true with clear corridor
- [ ] LoS false with wall/door blocker
EOF
)" "P0"

create_issue "[P0] Add Guard entity + Patrol behavior" "$(cat <<'EOF'
## Description
Define guard data (position, state, patrol direction or waypoint list).
Patrol MVP: random walk with wall avoidance OR small loop.

## Dependencies
Part of EPIC 4

## Acceptance Criteria

- [ ] Guards move once per turn during "guard phase"
- [ ] Patrol does not move into walls/closed doors

## Tests

- [ ] Guard patrol step respects walkability
EOF
)" "P0"

create_issue "[P0] Implement Chase behavior (LoS triggers chase for N turns)" "$(cat <<'EOF'
## Description
If guard has LoS, switch to chase and follow BFS step toward player for N turns.
If LoS breaks, continue chase timer or revert (define clearly in tests).

## Dependencies
Part of EPIC 4

## Acceptance Criteria

- [ ] LoS triggers chase
- [ ] Chase moves along shortest path

## Tests

- [ ] Chase step moves closer to player on known grid
- [ ] State transitions behave as expected
EOF
)" "P0"

create_issue "[P0] Implement capture condition (guard enters player tile)" "$(cat <<'EOF'
## Description
If any guard moves onto player position during guard phase ⇒ game over.

## Dependencies
Part of EPIC 4

## Acceptance Criteria

- [ ] GameOver flag set immediately on capture
- [ ] End screen flow can be triggered later (EPIC 5)

## Tests

- [ ] Capture triggers game over deterministically
EOF
)" "P0"

# =============================================================================
# EPIC 5 — Renderer + UX
# =============================================================================

create_issue "EPIC 5: ASCII Renderer + HUD + Screens Flow" "$(cat <<'EOF'
## Goal
Thin scene layer that renders grid/entities via `RichTextLabel` BBCode.

## Dependencies
EPIC 2–4 (core gameplay)

## Acceptance Criteria

- [ ] Renderer converts state → BBCode string with colors
- [ ] In-run HUD displays floor, turns, inventory, shard status, score
- [ ] Main menu → run → end screen flow works
EOF
)" "epic"

create_issue "[P0] Implement Renderer.gd (grid + entities → BBCode RichTextLabel)" "$(cat <<'EOF'
## Description
Render legend:
- `@` player, `G` guards, `#` wall, `.` floor, `D` door, `k` keycard, `$` shard, `>` exit.

Color via BBCode.

## Dependencies
Part of EPIC 5

## Acceptance Criteria

- [ ] No external assets required
- [ ] Renderer output stable (helpful for snapshot tests later)

## Tests (optional for MVP)

- [ ] String snapshot test for a known layout (nice-to-have)
EOF
)" "P0"

create_issue "[P1] Implement in-run HUD + message log plumbing" "$(cat <<'EOF'
## Description
Add a message log array in state (or UI-only) and display recent messages:
- pickup events, door opened, exit locked, caught.

## Dependencies
Part of EPIC 5

## Acceptance Criteria

- [ ] HUD updates each turn
- [ ] Messages appended on key events
EOF
)" "P1"

create_issue "[P1] Implement main menu + seed entry + start run flow" "$(cat <<'EOF'
## Description
Menu has Start Run, seed entry (optional), controls view, quit.

## Dependencies
Part of EPIC 5

## Acceptance Criteria

- [ ] Blank seed generates random but stores the used seed
- [ ] Seed used is displayed in-run and on end screen
EOF
)" "P1"

create_issue "[P1] Implement end screen summary (caught/win, score, best score, seed)" "$(cat <<'EOF'
## Description
Show run result + stats.
Buttons: restart run, back to menu.

## Dependencies
Part of EPIC 5

## Acceptance Criteria

- [ ] Correct result displayed
- [ ] Score shown and best score comparison present
EOF
)" "P1"

# =============================================================================
# EPIC 6 — Save/Load (Local Persistence)
# =============================================================================

create_issue "EPIC 6: Persistence (user://save.json)" "$(cat <<'EOF'
## Goal
Save best score + last seed (and optional stats) locally.

## Dependencies
EPIC 1 (state), EPIC 5 (end screen uses best score)

## Acceptance Criteria

- [ ] `scripts/save_system.gd` saves/loads JSON at `user://save.json`
- [ ] Stores: `best_score`, `last_seed`, optional `runs_played`, `best_floor`
- [ ] Save/load roundtrip tested headlessly
EOF
)" "epic"

create_issue "[P0] Implement SaveSystem JSON persistence + tests" "$(cat <<'EOF'
## Description
Create `save_system.gd` with `load()` and `save(data)`.

## Dependencies
Part of EPIC 6

## Acceptance Criteria

- [ ] Missing file handled gracefully (defaults)
- [ ] Corrupt file handled (fallback + message)

## Tests

- [ ] Roundtrip: write → read → equals
- [ ] Missing file returns defaults
EOF
)" "P0"

create_issue "[P1] Wire best score + last seed into end screen + main menu defaults" "$(cat <<'EOF'
## Description
End screen saves on run end; main menu pre-fills last seed.

## Dependencies
Part of EPIC 6

## Acceptance Criteria

- [ ] Best score persists across restarts
- [ ] Last seed shown/available on menu
EOF
)" "P1"

# =============================================================================
# EPIC 7 — Balancing + Config
# =============================================================================

create_issue "EPIC 7: Config + Difficulty Ramp (3-floor run)" "$(cat <<'EOF'
## Goal
Configurable parameters and 3-floor run structure with ramp.

## Dependencies
EPIC 3–5

## Acceptance Criteria

- [ ] Config resource defines grid size, guard count per floor, door chance, etc.
- [ ] Run is exactly 3 floors; difficulty ramps each floor
- [ ] Regression tests cover config defaults
EOF
)" "epic"

create_issue "[P1] Add Config resource + defaults + regression tests" "$(cat <<'EOF'
## Description
Create `resources/game_config.tres` (or scriptable resource) and load it.

## Dependencies
Part of EPIC 7

## Acceptance Criteria

- [ ] Defaults match pitch expectations (reasonable values)
- [ ] Tests assert default values and that systems use them
EOF
)" "P1"

create_issue "[P1] Implement 3-floor run progression + difficulty ramp" "$(cat <<'EOF'
## Description
Track floor index 1..3.
Increase guard count and/or door chance per floor (simple ramp).

## Dependencies
Part of EPIC 7

## Acceptance Criteria

- [ ] Completing floor advances until floor 3 end
- [ ] Game ends on floor 3 completion with "run win"
- [ ] Ramp applied deterministically based on floor number

## Tests

- [ ] Progression from floor 1 → 2 → 3
- [ ] Ramp parameter changes across floors
EOF
)" "P1"

# =============================================================================
echo ""
echo "============================================="
echo "All TERMINAL HEIST issues created successfully!"
echo "============================================="
echo ""
echo "Summary:"
echo "  - EPIC 0: Project Skeleton (3 issues)"
echo "  - EPIC 1: Core Logic Foundation (3 issues)"
echo "  - EPIC 2: Turn System (4 issues)"
echo "  - EPIC 3: Procedural Level Generation (5 issues)"
echo "  - EPIC 4: Guards + AI (6 issues)"
echo "  - EPIC 5: Renderer + UX (5 issues)"
echo "  - EPIC 6: Save/Load (3 issues)"
echo "  - EPIC 7: Balancing + Config (3 issues)"
echo ""
echo "Total: 32 issues"
