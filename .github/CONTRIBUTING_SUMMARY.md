# EAGL Contributing Guidelines Summary

This document summarises the key contributing guidelines from the main README to help maintain consistency across the project.

## Language Standards

- **Documentation**: Australian/British English (`behaviour`, `colour`, `centre`, `realise`, `organisation`)
- **Code**: US English (`behavior`, `color`, `center`, `realize`, `organization`)
- **Tone**: Calm, concise, and factual - avoid 'sales' language and over-use of exclamation marks

## Code Style

- **Formatting**: Follow `mix format` with exceptions for matrices (use `# mix format: off|on`)
- **Sigils**: Use `~m`atrix, `~v`ertex, `~i`ndex for compile-time constants
- **Variables**: Descriptive names, especially for OpenGL state
- **Functions**: Include typespecs for public functions
- **Documentation**: Comprehensive docstrings with code examples

## Design Philosophy

### ✅ Provide Meaningful Abstractions
- Error handling with `{:ok, result}` tuples
- Type safety and clear parameter names
- Sensible defaults to reduce boilerplate
- Complex multi-step operations (shader compilation, buffer setup)
- Data transformations between Elixir and OpenGL

### ❌ Avoid Thin Wrappers
- Don't wrap simple OpenGL calls like `:gl.bindTexture()`
- Avoid one-line functions that only add `check()` calls
- Let users manage OpenGL state explicitly when appropriate

## Testing Requirements

- Add tests for new functionality
- Ensure `mix test` passes
- Update examples to accept `opts` parameter for timeout testing
- Mock OpenGL calls in unit tests where possible

## Documentation Standards

- Update README.md for new features
- Include practical code examples
- Document complex algorithms and OpenGL concepts
- Maintain consistent project structure documentation

## Key Project Patterns

- **Selective imports**: `import EAGL.Error` for explicit error checking
- **Direct OpenGL integration**: Mix EAGL helpers with direct OpenGL calls
- **Resource management**: Automatic cleanup of OpenGL resources
- **Error handling**: Comprehensive OpenGL error checking with context

## Examples and Tutorials

- Follow LearnOpenGL tutorial structure and naming conventions
- Include comprehensive documentation explaining concepts
- Provide both basic and advanced usage examples
- Maintain consistency with existing example patterns

## Common Conventions

- Camera systems use standard FPS controls (WASD, mouse look, scroll zoom)
- Shader examples include both vertex and fragment shaders
- Examples accept timeout options for automated testing
- Resource cleanup is always handled properly

This summary focuses on the most common points that come up during development and helps maintain the project's consistent style and philosophy. 