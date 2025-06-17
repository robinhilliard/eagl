# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2024-12-29

### Added
- **Complete LearnOpenGL Getting Started Series**: Added all remaining coordinate systems and camera examples (6.1-6.4, 7.1-7.3)
  - **6.1 Coordinate Systems**: Model/View/Projection matrices and 3D cube rendering
    - Full 3D rendering pipeline with model, view, and projection matrices
    - Multiple spinning cubes demonstrating MVP matrix transformations
    - Proper depth testing for 3D scene rendering
    - Educational focus on understanding coordinate space transformations
  - **6.2 Coordinate Systems Depth**: Enhanced depth testing and Z-buffer concepts  
    - Same scene as 6.1 but with detailed depth buffer explanations
    - Demonstrates importance of depth testing in 3D rendering
    - Shows artifacts that occur without proper depth testing
  - **6.3 Coordinate Systems Multiple**: Multiple cubes with unique transformations
    - Array of cubes positioned throughout 3D space
    - Each cube has different rotation and position transforms
    - Demonstrates rendering multiple objects with individual transformations
  - **6.4 Coordinate Systems Exercise**: Interactive perspective vs orthographic projection
    - Toggle between perspective and orthographic projection modes
    - Shows visual differences between projection types
    - Educational comparison of 3D projection techniques
  - **7.1 Camera Circle**: Automatic camera rotation around scene center
    - Camera moves in circular path using trigonometric functions
    - Demonstrates view matrix manipulation and camera positioning
    - Introduction to camera concepts before user interaction
  - **7.2 Camera Keyboard + Delta Time**: WASD keyboard camera controls with delta time
    - Full 6DOF camera movement with W/A/S/D keys
    - Delta time-based movement for frame-rate independent motion
    - Proper frame timing and smooth camera movement
    - Foundation for first-person camera controls
  - **7.3 Camera Mouse + Zoom**: Complete first-person camera with mouse look and scroll zoom
    - Mouse movement controls camera rotation (look around)
    - Scroll wheel controls field-of-view zoom (1-45 degrees)
    - Cursor hiding for immersive first-person experience
    - Complete FPS-style camera implementation

### Enhanced
- **Performance Optimizations**: Significant improvements to OBJ loader performance
  - Optimized face parsing and vertex normal generation
  - Better memory allocation patterns for large models
  - Improved async processing capabilities
- **Camera System**: Comprehensive first-person camera implementation
  - Mouse sensitivity controls and smooth movement
  - Proper field-of-view constraints and perspective updates
  - Clean separation of camera state from rendering logic
- **Window System**: Enhanced mouse and keyboard event handling
  - Better mouse motion tracking for camera controls
  - Scroll wheel support for zoom functionality
  - Improved event state management

### Fixed
- **Documentation Warnings**: Fixed `mix docs` warnings from malformed Markdown
  - Wrapped tuple syntax in backticks to prevent IAL (Inline Attribute List) warnings
  - Event types now properly formatted as inline code in documentation
- **Camera Controls**: Refined camera behavior for better user experience
  - Proper mouse sensitivity scaling for look controls
  - Correct field-of-view clamping for zoom functionality
  - Smooth camera movement with consistent delta time handling

### Milestone Achievement
- **Substantial Progress on LearnOpenGL Getting Started Series**: Added coordinate systems and camera examples
  - Hello Window (1.1-1.2): 2 examples - Basic window creation and clearing ✅
  - Hello Triangle (2.1-2.5): 5 examples - Basic geometry and vertex processing ✅  
  - Shaders (3.1-3.6): 6 examples - Shader fundamentals and uniforms ✅
  - Textures (4.1-4.6): 6 examples - Texture mapping and multi-texturing ✅
  - Transformations (5.1-5.2): 3 examples - Matrix transformations and animations ✅
  - Coordinate Systems (6.1-6.4): 4 examples - 3D rendering and MVP matrices ✅
  - Camera (7.1-7.6): 3 of 6 examples completed - Camera controls and first-person movement
    - ✅ 7.1 Camera Circle: Automatic camera rotation around scene center
    - ✅ 7.2 Camera Keyboard + Delta Time: WASD movement with frame-rate independence
    - ✅ 7.3 Camera Mouse + Zoom: Mouse look and scroll zoom
    - ❌ 7.4 Camera Class: Reusable camera object abstraction
    - ❌ 7.5 Camera Exercise 1: Exercise solution (FPS-style camera)
    - ❌ 7.6 Camera Exercise 2: Exercise solution (custom LookAt implementation)
- **Missing for Complete Getting Started Series**: 7.4, 7.5, 7.6 (3 camera examples)
- **Examples Statistics**: 26 of 29 LearnOpenGL Getting Started examples + 2 original examples = 28 total examples

## [0.6.0] - 2024-12-24

### Added
- **Complete LearnOpenGL Transformations Chapter**: Added all transformation examples (5.1-5.2)
  - **5.1 Basic Transformations**: Matrix transformation fundamentals with orbiting rectangle
    - Basic matrix operations (translate, rotate, scale) with time-based animation
    - Single textured rectangle demonstrating transformation order effects (T * R = orbiting)
    - Educational focus on understanding how transformation matrices combine
    - Shows why transformation order matters: translate-then-rotate vs rotate-then-translate
  - **5.2 Exercise 1**: Multiple containers with different transformation types
    - Two containers: one rotating, one scaling using sine wave animation
    - Demonstrates applying different transformations to same geometry
    - Shows matrix independence - each object has its own transformation matrix
    - Uses `abs(sin(time))` to prevent negative scaling that would flip textures
  - **5.2 Exercise 2**: Multiple containers with texture mixing
    - Two containers with same transformations as Exercise 1 but enhanced texture system
    - Demonstrates multiple texture units and texture mixing concepts from Chapter 4
    - Uses `mix(texture1, texture2, 0.2)` in fragment shader for blended textures
    - Includes negative scaling effects with `sin(time)` (no absolute value)
    - Primary texture (EAGL logo) mixed with checkerboard pattern for clear visual contrast

### Enhanced
- **EAGL.Math Integration**: All transformation examples utilize EAGL's GLM-compatible matrix functions
  - `mat4_identity()`, `mat4_translate()`, `mat4_rotate_z()`, `mat4_scale()` 
  - Automatic matrix uniform handling with `set_uniform()` type detection
  - Clean Elixir syntax matching original GLM/C++ concepts
- **Animation Framework**: Proper 60 FPS tick-based animation using EAGL.Window
  - State-based time management with `handle_event(:tick, state)` callbacks
  - Clean separation of animation logic from rendering logic
  - Consistent animation patterns across all transformation examples
- **Texture System Integration**: Building on Chapter 4 texture capabilities
  - Single texture loading with `load_texture_from_file()`
  - Multiple texture units with procedural texture mixing
  - Seamless integration of transformation and texture concepts

### Technical Improvements
- **Vertex Shader Attribute Locations**: Fixed vertex attribute layout consistency
  - Corrected texture coordinate attribute location from `layout (location = 2)` to `layout (location = 1)`
  - Proper alignment with EAGL's `vertex_attributes(:position, :texture_coordinate)` helper
  - Ensures texture coordinates are correctly passed to fragment shaders
- **Shader Management**: All examples use consistent `with` pattern for error handling
  - Unified error handling approach across transformation examples
  - Better error messages and graceful failure handling
  - Consistent with EAGL framework patterns established in previous chapters
- **Documentation Accuracy**: Fixed transformation behavior descriptions
  - Corrected documentation to accurately describe "orbiting" vs "rotating around center"
  - Clear explanation of transformation order effects (T*R vs R*T)
  - Educational notes about matrix multiplication order and visual results

### Examples Statistics
- **Total Examples**: 24 (was 21) - added 3 transformation examples
- **Transformation Series**: Complete 3-example series covering basic to advanced concepts
- **Getting Started Progress**: 5 of 7 chapters complete (missing only Coordinate Systems and Camera)
- **Code Coverage**: 151-153 transformation codes added to examples runner

## [0.5.0] - 2024-12-22

### Added
- **Sigil System for Clean Data Literals**: New compile-time sigils for OpenGL data with tabular formatting
  - **Matrix Sigil (`~m`)**: Clean matrix creation with automatic size detection and comment support
    - Supports 2x2, 3x3, and 4x4 matrices with compile-time validation
    - Automatic whitespace handling and comment stripping
    - Preserves tabular formatting for readability while working with `mix format`
  - **Vertex Sigil (`~v`)**: Raw vertex buffer data with structured formatting
    - Multi-column data layout with inline comments for attribute documentation
    - Automatic float conversion and validation
    - Clean tabular format for position, color, texture coordinate data
  - **Index Sigil (`~i`)**: Element indices with integer validation
    - Triangle and quad index definitions with comment support  
    - Compile-time integer validation
    - Clean formatting for complex geometry definitions
- **Mix Format Compatibility**: All sigils work seamlessly with Elixir's formatter
  - Preserves intentional tabular formatting within sigil strings
  - No need for `# credo:disable-for-next-line` or manual formatting exclusions
  - Maintains code readability while following Elixir formatting standards

### Enhanced
- **EAGL.Math Module**: Extended with comprehensive sigil support and documentation
  - Added extensive examples showing sigil usage patterns
  - Improved compile-time validation with clear error messages
  - Enhanced documentation with practical usage examples
- **Code Formatting Integration**: Updated `.formatter.exs` configuration
  - Better handling of mixed formatting requirements
  - Preservation of matrix and vertex data readability
  - Consistent formatting across the entire codebase

### Technical Benefits
- **Compile-Time Safety**: All sigils validate data structure and types at compile time
- **Performance**: No runtime parsing overhead - all conversions happen at compile time
- **Maintainability**: Clean, readable data definitions that don't conflict with code formatting
- **Consistency**: Unified approach to OpenGL data creation across the library

## [0.4.0] - 2024-12-21

### Breaking Changes
- **BREAKING**: `EAGL.Shader.create_shader/2` now accepts atoms instead of raw OpenGL constants
  - **Before**: `create_shader(@gl_vertex_shader, source)`  
  - **After**: `create_shader(:vertex, source)`
  - **Supported types**: `:vertex`, `:fragment`, `:geometry`, `:tess_control`, `:tess_evaluation`, `:compute`
  - **Migration**: Replace GL constants with corresponding atoms in all `create_shader/2` calls
  - **Rationale**: Provides type safety and consistency with `EAGL.Texture` parameter style

### Added
- **Complete LearnOpenGL Texture Examples Series**: Added all remaining texture examples (4.2-4.6)
  - **4.2 Textures Combined**: Multiple texture units - mixing two textures with GLSL blend factors
  - **4.3 Textures Exercise 1**: Texture coordinate manipulation - center cropping with scaled coordinates
  - **4.4 Textures Exercise 2**: Texture wrapping modes - demonstrating repeat, clamp, and mirror wrapping
  - **4.5 Textures Exercise 3**: Texture coordinate flipping - horizontal mirroring with inverted S coordinates
  - **4.6 Textures Exercise 4**: Dynamic texture mixing - time-based animation using sine wave interpolation
- New typed shader system with `shader_type`, `shader_id`, and `program_id` types
- Internal `shader_type_to_gl/1` helper function for GL constant conversion
- **Enhanced EAGL.Buffer Module**: Type-safe vertex attribute helpers with improved specifications
- **Enhanced EAGL.Shader Module**: Improved error handling and comprehensive type specifications
- **Enhanced EAGL.Window Module**: Better key handling for examples and applications
- Wings3D attribution added to core modules (`buffer.ex`, `texture.ex`, `error.ex`, `shader.ex`, `window.ex`)
- "Original Source" documentation sections crediting Wings3D's `wings_gl.erl` patterns

### Changed
- **Examples Runner Numbering System**: Redesigned intuitive numbering aligned with LearnOpenGL structure
  - Non-LearnOpenGL examples: `01` (Math), `02` (Teapot)
  - LearnOpenGL examples: `[chapter][section][example]` format (e.g., `125` = 1.Getting Started 2.5 Hello Triangle Exercise 3)
  - Future-proof design accommodates multiple LearnOpenGL chapters without ambiguity
  - Missing examples clearly marked with their future codes: `151`, `161`, `171`
- **Vertex Attribute Setup Refactored**: All LearnOpenGL examples now use consistent vertex attribute patterns
- **Animation Time Handling**: Improved time handling for animation in ShadersUniform example
- All LearnOpenGL examples updated to use new typed shader parameters
- Teapot example updated to use new typed shader parameters  
- Test files updated to use new typed shader parameters
- Documentation style improvements across all modules:
  - More concise and practical explanations
  - Removed excessive exclamation marks and sales language
  - Added clear usage examples showing integration with direct OpenGL calls
  - Aligned with Australian English style guidelines

### Fixed
- **Texture Rendering Bug**: Fixed LearnOpenGL 4.1 example showing white triangle instead of textured triangle
  - Corrected vertex attribute layout to match 8-float vertex data structure `[x, y, z, r, g, b, s, t]`
  - Fixed stride calculation and attribute offsets for position, color, and texture coordinates
- **FunctionClauseError**: Fixed remaining GL constants in multiline shader creation calls across examples

### Removed
- **EAGL.Examples.Test Module**: Removed duplicate test module to clean up codebase
- Removed verbose console output and status symbols (✓ ✗) from examples and core modules
- Eliminated excessive logging that didn't align with "meaningful abstractions" philosophy

---

**Migration Guide for 0.4.0**

The primary breaking change affects shader creation. Update your code as follows:

```elixir
# Before (0.3.x)
{:ok, vertex_shader} = EAGL.Shader.create_shader(@gl_vertex_shader, vertex_source)
{:ok, fragment_shader} = EAGL.Shader.create_shader(@gl_fragment_shader, fragment_source)

# After (0.4.0)  
{:ok, vertex_shader} = EAGL.Shader.create_shader(:vertex, vertex_source)
{:ok, fragment_shader} = EAGL.Shader.create_shader(:fragment, fragment_source)
```

All other APIs remain backwards compatible. The new typed system provides better error messages and IDE support while maintaining the same performance characteristics.

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
  - Total examples now: 21 (was 10)
  - Complete shader tutorial series from basic uniforms to advanced exercises
  - Complete texture mapping series from basic textures to advanced mixing
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
  - **3.4 Exercise 1**: Vertex transformation in shader (`