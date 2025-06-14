# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2024-12-20

### Added
- **EAGL.Texture Module**: New comprehensive texture management module focusing on meaningful abstractions
  - `load_texture_from_file()` with automatic fallback to checkerboard patterns
  - `create_texture()` and `create_textures()` with `{:ok, id}` error handling
  - `set_texture_parameters()` with atom-to-OpenGL-constant conversion
  - `load_texture_data()` with format/type handling and sensible defaults
  - `create_checkerboard_texture()` for procedural test pattern generation
  - **Optional stb_image integration**: Real image loading with graceful degradation
  - **Helpful error messages**: Clear guidance when dependencies aren't available
  - Philosophy: substantial helpers rather than thin wrappers around OpenGL calls
  - Users call `:gl` functions directly for binding, mipmaps, deletion, and texture units

- **LearnOpenGL 4.1 Textures Example**: First texture mapping tutorial demonstrating:
  - **Real image loading**: Uses EAGL logo (eagl_logo_black_on_white.jpg/png) via stb_image
  - **Automatic fallback**: Graceful degradation to checkerboard when stb_image unavailable
  - Basic texture concepts and coordinate mapping
  - Texture object creation and configuration
  - Fragment shader texture sampling with `sampler2D`
  - Interleaved vertex data with position, color, and texture coordinates

- **Optional stb_image Dependency**: Added for real image loading capabilities
  - Supports JPEG, PNG, BMP, TGA, and other common formats
  - Automatic Y-axis flipping for OpenGL convention
  - Graceful fallback when not available

- **Texture Unit Constants**: Added GL_TEXTURE0 through GL_TEXTURE15 constants to EAGL.Const
- **Pixel Alignment Constant**: Added GL_UNPACK_ALIGNMENT (3317) to EAGL.Const for proper texture loading

- **LearnOpenGL Shader Examples Complete**: Added remaining shader tutorial examples (3.2-3.6)
  - **3.2 Shaders Interpolation**: Vertex color interpolation with red, green, blue corners demonstrating rasterizer interpolation
  - **3.3 Shaders Class**: Same as 3.2 but emphasizes shader abstraction and clean code organization patterns
  - **3.4 Shaders Exercise 1**: Upside-down triangle using vertex shader transformations (negating y-coordinate)
  - **3.5 Shaders Exercise 2**: Horizontal offset via uniform variables for application-controlled positioning
  - **3.6 Shaders Exercise 3**: Position-as-color visualization showing coordinate-to-RGB mapping and interpolation effects

- **Comprehensive Test Suite**: 18 texture tests covering all functionality
  - Texture creation (single/multiple), parameter setting, data loading
  - Image loading (both JPG and PNG formats)
  - Y-flip functionality, fallback behavior, format detection
  - Pixel alignment handling, error handling, complete workflows

### Changed
- **Examples Runner**: Updated to include all new examples
  - Total examples now: 17 (was 10)
  - Complete shader tutorial series from basic uniforms to advanced exercises
  - First texture mapping example with real image loading
  - Comprehensive coverage of vertex attributes, uniforms, interpolation, transformations, and textures

### Fixed
- **Texture Loading Issues**: Resolved diagonal skewing and wrapping artifacts
  - **Pixel Alignment Fix**: Added `glPixelStorei(GL_UNPACK_ALIGNMENT, 1)` for non-4-byte-aligned image widths
  - **Y-Axis Correction**: Proper Y-flip handling to match OpenGL coordinate system (bottom-left origin)
  - **Format Detection**: Automatic RGB/RGBA format detection based on image channels

### Technical Details
- **Texture Loading Robustness**:
  - Handles arbitrary image dimensions (tested with 418x418 EAGL logo)
  - Proper pixel alignment for images where `width * channels` is not divisible by 4
  - Automatic format detection (1=red, 2=rg, 3=rgb, 4=rgba channels)
  - Y-axis flipping to match OpenGL's bottom-left origin convention
- **Shader Exercise Features**:
  - **3.2 Interpolation**: Multiple vertex attributes (position + color), demonstrates GPU rasterizer interpolation
  - **3.3 Class**: Emphasizes EAGL.Shader abstraction benefits and clean code organization
  - **3.4 Exercise 1**: Vertex transformation in shader (`gl_Position = vec4(aPos.x, -aPos.y, aPos.z, 1.0)`)
  - **3.5 Exercise 2**: Uniform-controlled transformations (`uniform float xOffset` applied to position)
  - **3.6 Exercise 3**: Position-to-color mapping showing why negative coordinates appear black in RGB space
- **Fallback Behavior**: Two-tier fallback system for maximum reliability
  - **stb_image unavailable**: Prints helpful installation instructions, falls back to checkerboard
  - **File loading failure**: Prints error message, falls back to checkerboard

### Educational Value
- **Complete Shader Learning Path**: From basic uniforms to advanced vertex transformations
- **Texture Mapping Fundamentals**: Real-world texture loading with proper error handling
- **Interpolation Understanding**: Visual demonstration of how GPU interpolates values across triangle surfaces
- **Coordinate System Concepts**: Shows relationship between coordinate spaces and color spaces
- **Production-Ready Patterns**: Demonstrates robust error handling and graceful degradation

## [0.2.0] - 2024-12-19

### Added
- **LearnOpenGL 3.1 Shaders Uniform Example**: Complete port demonstrating uniform variables, time-based animations, and dynamic color changes
- **Consistent Original Source Links**: Added "Original C++ Source" sections to all LearnOpenGL examples linking to the original tutorials
- **Robust OpenGL Context Error Handling**: Comprehensive error handling for OpenGL context cleanup during window shutdown
- **Enhanced Window API**: Refactored `EAGL.Window.run/3` to use clean options-based API with default window size
- **Improved Cleanup Procedures**: Added graceful handling of OpenGL resource cleanup when context is destroyed

### Changed
- **Window API Refactor**: Simplified `EAGL.Window.run` from confusing 4-signature API to clean 2-signature options-based API
  - Before: `run(module, title)`, `run(module, title, options)`, `run(module, title, size)`, `run(module, title, size, options)`
  - After: `run(module, title)`, `run(module, title, options)` where size is in options
  - Default window size: `{1024, 768}`
  - Options: `size: {width, height}`, `depth_testing: boolean`, `return_to_exit: boolean`
- **Updated README**: Comprehensive documentation updates with new API examples and clearer usage instructions
- **Examples Runner**: Updated to include 3.1 Shaders Uniform example (option 10)

### Fixed
- **OpenGL Context Errors on Exit**: Eliminated misleading "Error in window setup" messages during ENTER key exit
- **Resource Cleanup**: Fixed `no_gl_context` errors during cleanup by adding proper error handling for destroyed contexts
- **Window Shutdown**: Clean application exit with proper wx application termination

### Technical Details
- **3.1 Shaders Uniform Features**:
  - Demonstrates uniform variables with `EAGL.Shader.set_uniform()` automatic type detection
  - Time-based color animation using `sin(time)` for smooth green color cycling
  - EAGL's tick handler pattern vs original C++ approach (`handle_event(:tick)` vs `glfwGetTime` in render loop)
  - State management: `{program, vao, vbo, current_time}`
- **Error Handling Improvements**:
  - Added specific handling for `ErlangError` with `{:error, :no_gl_context, _}` pattern
  - Graceful cleanup when OpenGL context is already destroyed
  - Proper resource management during window destruction

### Documentation
- Added links to original LearnOpenGL C++ source code in all example moduledocs
- Updated API documentation with new window options
- Enhanced README with comprehensive usage examples

## [0.1.0] - 2024-12-18

### Added
- Initial release of EAGL (Easier OpenGL) library
- **Core Modules**:
  - `EAGL.Math`: GLM-inspired 3D math library with vectors, matrices, quaternions
  - `EAGL.Shader`: Shader compilation, linking, and uniform management
  - `EAGL.Buffer`: VAO/VBO helper functions inspired by Wings3D
  - `EAGL.Model`: 3D model loading with Wavefront OBJ support
  - `EAGL.Window`: Cross-platform window creation with wxWidgets
  - `EAGL.Error`: Comprehensive OpenGL error checking and reporting

- **LearnOpenGL Tutorial Ports** (8 examples):
  - 1.1 Hello Window - Basic window creation
  - 1.2 Hello Window Clear - Custom clear colors
  - 2.1 Hello Triangle - Basic VAO/VBO and shaders
  - 2.2 Hello Triangle Indexed - Element Buffer Objects (EBO)
  - 2.3 Hello Triangle Exercise 1 - Two triangles side by side
  - 2.4 Hello Triangle Exercise 2 - EBO rectangle with shared vertices
  - 2.5 Hello Triangle Exercise 3 - Multiple shader programs
  - 3.1 Shaders Uniform - Uniform variables and animations

- **Example Applications**:
  - Math Example: Comprehensive EAGL.Math functionality demonstration
  - Teapot Example: 3D teapot with Phong shading
  - Unified examples runner script

- **Features**:
  - Cross-platform OpenGL 3.3+ support
  - Automatic OpenGL error checking
  - GLM-compatible math operations
  - Wings3D-inspired helper functions
  - Comprehensive test suite (92 passing tests)
  - Full documentation with examples

### Technical Specifications
- **Requirements**: Elixir 1.14+, Erlang/OTP 25+, OpenGL 3.3+
- **Platform Support**: Linux, macOS, Windows
- **Dependencies**: Built-in wx module (no external GUI libraries required)
- **Testing**: Full test coverage with OpenGL context mocking

[0.3.0]: https://github.com/robinhilliard/eagl/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/robinhilliard/eagl/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/robinhilliard/eagl/releases/tag/v0.1.0 