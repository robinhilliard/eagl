# EZGL

A simple example of using OpenGL shaders with Erlang's wx library in Elixir.

## Overview

This project demonstrates how to create and use OpenGL shaders in Elixir using Erlang's wx library. It includes examples:

1. `EZGL.SimpleShaderExample` - A simplified example focusing on shader creation and basic rendering

## Requirements

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- OpenGL support in your system
- wxWidgets development libraries

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ezgl.git
   cd ezgl
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

## Usage

### Simple Shader Example

Run the simple shader example:
```bash
mix run -e "EZGL.SimpleShaderExample.run()"
```

This will create a window with a colored point rendered using OpenGL shaders.

## Project Structure

- `lib/simple_shader_example.ex` - Contains the simplified shader example
- `lib/gl/` - Contains OpenGL-related modules
- `lib/wx/` - Contains wx-related modules

## Features

- OpenGL shader creation and compilation
- Basic vertex and fragment shaders
- Window management with wxWidgets
- Event handling for window resize and close
- Proper cleanup of OpenGL resources

## License

This project is licensed under the MIT License - see the LICENSE file for details.

