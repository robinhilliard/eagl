# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-06-13

### Added

#### Core Library
- **EAGL.Math** - Comprehensive 3D math library with GLM-inspired API
  - Vector operations (2D, 3D, 4D) with constructor macros
  - Matrix operations (2x2, 3x3, 4x4) with transformation functions
  - Quaternion operations with SLERP and conversion functions
  - Utility functions for trigonometry, interpolation, and clamping
  - All functions work with Erlang's OpenGL binding format

- **EAGL.Shader** - Shader compilation and management
  - Automatic shader compilation with comprehensive error reporting
  - Program linking with validation
  - Uniform helpers with automatic type detection for EAGL.Math types
  - Support for setting multiple uniforms at once

- **EAGL.Buffer** - Wings3D-inspired buffer management
  - `create_position_array/1` for simple position-only VAOs
  - `create_vertex_array/2` for custom vertex attribute configurations
  - `delete_vertex_array/2` for proper resource cleanup

- **EAGL.Error** - Comprehensive OpenGL error handling
  - `check/1` for error checking with context information
  - `error_string/1` for human-readable error messages
  - `check!/1` for error checking with exceptions (debugging)

- **EAGL.Model** - 3D model loading and management
  - Wavefront OBJ file loader with automatic normal generation
  - Direct VAO creation from model data
  - Support for vertices, normals, and texture coordinates

- **EAGL.Window** - Cross-platform window management
  - OpenGL context creation via Erlang's wx bindings
  - Event handling for resize, close, and paint events
  - Automatic resource cleanup

- **EAGL.Const** - OpenGL constants for Elixir
  - Complete set of OpenGL constants as module attributes
  - Easy import for use in applications

#### Examples
- **Math Example** - Terminal-based demonstration of all EAGL.Math functionality
- **Teapot Example** - 3D teapot rendering with Phong shading
- **LearnOpenGL Examples** - Direct ports of popular OpenGL tutorials:
  - Exercise 2.4: Hello Triangle with Element Buffer Objects (EBO)
  - Exercise 2.5: Hello Triangle with Multiple Shader Programs

#### Development Tools
- **Unified Examples Runner** - Interactive script for running all examples
- **Comprehensive Documentation** - Full API documentation with examples
- **Test Suite** - Complete test coverage for all modules

#### Project Infrastructure
- MIT License
- Comprehensive README with usage examples
- Hex.pm publishing metadata
- Documentation generation with ExDoc
- Test coverage reporting with ExCoveralls

### Technical Details

#### Dependencies
- **Elixir**: 1.14 or later
- **Erlang/OTP**: 25 or later (with wx support)
- **OpenGL**: 3.3 or later

#### Platform Support
- Linux (with OpenGL drivers)
- macOS (built-in OpenGL support)
- Windows (with graphics drivers)

#### Architecture
- Clean separation between core functionality and examples
- Wings3D-inspired helper functions for common OpenGL patterns
- GLM-compatible math library for easy tutorial translation
- Minimal abstraction over Erlang's wx OpenGL bindings

[0.1.0]: https://github.com/robinhilliard/eagl/releases/tag/v0.1.0 