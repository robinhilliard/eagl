# EAGL Example Scripts

This directory contains convenient scripts for running EAGL examples.

## Available Scripts

### `./teapot`
Runs the 3D teapot rendering example with switchable shaders.
- Press '1' for simple red shading
- Press '2' for glossy Phong porcelain shading  
- Press '3' for normals debugging (shows normals as colors)
- Press ESC to quit

### `./simple_shader`
Runs the basic shader example that draws a blue point.

### `./all_examples`
Interactive script that runs all available examples in sequence.
Press Enter to proceed through each example.

## Usage

From the project root directory:

```bash
# Run the teapot example
./priv/scripts/teapot

# Run the simple shader example
./priv/scripts/simple_shader

# Run all examples interactively
./priv/scripts/all_examples
```

## Requirements

- Elixir installed
- OpenGL support 
- wxWidgets (for window management)
- X11 forwarding if running over SSH

## Troubleshooting

If a script fails to run:

1. Ensure you're in the project root directory
2. Try running `mix deps.get` and `mix compile` first
3. Check that your system supports OpenGL and wxWidgets
4. For WSL users, ensure X11 forwarding is set up

## Adding New Examples

To add a new example script:

1. Create a new executable script in this directory
2. Follow the pattern of existing scripts
3. Update this README
4. Add the example to the `all_examples` script 