# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2024-12-21

### Breaking Changes
- **BREAKING**: `EAGL.Shader.create_shader/2` now accepts atoms instead of raw OpenGL constants
  - **Before**: `create_shader(@gl_vertex_shader, source)`  
  - **After**: `create_shader(:vertex, source)`
  - **Supported types**: `:vertex`, `:fragment`, `:geometry`, `:tess_control`, `:tess_evaluation`, `:compute`
  - **Migration**: Replace GL constants with corresponding atoms in all `create_shader/2` calls
  - **Rationale**: Provides type safety and consistency with `EAGL.Texture` parameter style

### Added
- New typed shader system with `shader_type`, `shader_id`, and `program_id` types
- Internal `shader_type_to_gl/1` helper function for GL constant conversion
- Wings3D attribution added to core modules (`buffer.ex`, `texture.ex`, `error.ex`, `shader.ex`, `window.ex`)
- "Original Source" documentation sections crediting Wings3D's `wings_gl.erl` patterns

### Changed
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
  - **3.4 Exercise 1**: Vertex transformation in shader (`