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
║                         Godot Example Project                    ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

# Godot Example Project

A minimal Godot 4.6 project by SapphireBeehiveStudios for testing and demonstration purposes.

## Overview

This is a test project for SapphireBeehiveStudios to verify MCP tools functionality and demonstrate Godot project structure. It serves as a reference implementation for GitHub integration, automated workflows, and Godot development practices.

## Project Information

- **Engine Version:** Godot 4.6
- **Rendering:** Forward Plus
- **Project Name:** SapphireBeehiveStudios - Godot Example

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

### Running the Project

#### Using Godot Editor
- Open the project in Godot
- Press F5 or click the "Run Project" button

#### Using Command Line
```bash
# Run the project
godot --headless

# Validate the project
godot --headless --validate-project
```

## Project Structure

```
godot-example/
├── .git/                  # Git repository data
├── .gitignore            # Git ignore rules
├── icon.svg              # Project icon
├── project.godot         # Godot project configuration
└── README.md             # This file
```

## Development

### Testing

This project includes a comprehensive test suite that can be run in headless mode:

```bash
# Run all unit tests
godot --headless -s res://tests/test_runner.gd

# Validate project scripts and scenes
godot --headless --validate-project

# Check syntax without running
godot --headless --check-only
```

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
4. Commit your changes (`git commit -m 'feat: add amazing feature'`)
   - Tests will run automatically before the commit
   - Commit will be blocked if tests fail
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Branch Protection

- Direct pushes to `main` are blocked
- All changes must go through pull requests
- Feature branches should follow the naming convention: `claude/issue-N-description` or `feature/description`

## Purpose

This project serves multiple purposes:

1. **MCP Tools Verification** - Testing GitHub MCP integration and automated pull request creation
2. **CI/CD Testing** - Validating automated workflows for Godot projects
3. **Reference Implementation** - Demonstrating Godot project structure and best practices
4. **Development Template** - Serving as a starting point for new Godot projects

## Technical Details

### Configuration

The project uses Godot's default configuration with the following customizations:

- **Canvas Texture Filter:** Nearest neighbor (pixel art friendly)
- **Feature Profile:** Forward Plus rendering

### Rendering Settings

- Default texture filter set to nearest neighbor (value: 2)
- Optimized for pixel art and retro-style graphics

## License

This is a test/example project. Please check with SapphireBeehiveStudios for licensing information.

## Support

For issues, questions, or contributions, please use the GitHub issue tracker:
https://github.com/SapphireBeehiveStudios/godot-example/issues

## Acknowledgments

- Built with [Godot Engine](https://godotengine.org/)
- Part of the SapphireBeehiveStudios development workflow
