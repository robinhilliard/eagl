# EAGL Scripts

This directory contains utility scripts for the EAGL project.

## Available Scripts

### `run_examples`
**Main Examples Runner** - Interactive menu system for running all EAGL examples.

```bash
./priv/scripts/run_examples
```

**Features:**
- Hierarchical menu following the `lib/examples/` directory structure
- Automatic discovery of all example modules
- Human-readable formatting of LearnOpenGL section numbers (e.g., `2_4` → `2.4`)
- Color-coded output for better readability
- Descriptions extracted from module documentation
- Interactive navigation with number selection
- Refresh capability to pick up new examples

**Menu Structure:**
- Root-level examples (e.g., `teapot_example`, `math_example`)
- LearnOpenGL examples organized by chapter:
  - **1. Getting Started:**
    - 2.4 Hello Triangle Exercise 2 (EBO/indexed drawing)
    - 2.5 Hello Triangle Exercise 3 (multiple shader programs)

**Usage:**
1. Run the script from the project root
2. Select an example by entering its number
3. Press 'q' to quit or 'r' to refresh the menu
4. Examples run and return to the menu when finished

## Adding New Examples

The script automatically discovers new examples by:
1. Scanning `lib/examples/` for `.ex` files
2. Reading the module name from `defmodule` declarations
3. Extracting descriptions from `@moduledoc` content
4. Formatting names according to LearnOpenGL conventions

To add a new example:
1. Create your `.ex` file in the appropriate directory under `lib/examples/`
2. Ensure it has a proper `defmodule` declaration
3. Add a descriptive `@moduledoc` with the first line being a brief description
4. Implement a `run_example/0` function
5. The script will automatically detect and include it in the menu

## Directory Structure

```
priv/scripts/
├── README.md          # This file
└── run_examples       # Main examples runner script
```