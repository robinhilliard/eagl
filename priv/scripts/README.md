# EAGL Scripts

This directory contains utility scripts for the EAGL project.

## Available Scripts

### `examples.exs`
**Main Examples Runner** - Interactive menu system for running all EAGL examples.

```bash
# Via Mix alias (recommended)
mix examples

# Or directly
mix run priv/scripts/examples.exs

# List all available examples
mix examples --list

# Run a specific example by code
mix examples 01
```

**Features:**
- Hierarchical menu following the examples directory structure
- Human-readable formatting of LearnOpenGL section numbers (e.g., `2_4` → `2.4`)
- Colour-coded output for better readability
- Descriptions extracted from module documentation
- Interactive navigation with number selection
- Refresh capability to pick up new examples

**Menu Structure:**
- `01-02`: Top-level examples (Math, Teapot)
- `1XX`: LearnOpenGL Getting Started (Hello Window through Camera)
- `2XX`: LearnOpenGL Lighting (Colours, Basic Lighting, Materials)
- `3XX`: glTF support examples (GLB loading, scene rendering, animations)

**Usage:**
1. Run `mix examples` from the project root
2. Select an example by entering its number code
3. Press 'q' to quit or 'r' to refresh the menu
4. Examples run and return to the menu when finished

## Directory Structure

```
priv/scripts/
├── README.md          # This file
├── examples.exs       # Main examples runner (mix examples)
├── dev_test           # Development test helper
├── test_glb_loader    # GLB loader test script
└── update_examples_for_testing  # Test update helper
```
