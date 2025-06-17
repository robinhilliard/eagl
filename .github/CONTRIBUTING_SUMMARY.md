# EAGL Contributing Guidelines Summary

This document summarises the key contributing guidelines from the main README to help maintain consistency across the project.

## Language Standards (Critical for AI Agents)

These language standards are fundamental to the project's consistency and MUST be followed by all contributors, especially AI agents generating content:

### Documentation Language: Australian/British English
- Use `behaviour`, `colour`, `centre`, `realise`, `organisation`, `optimise`, `analyse`  
- Apply to all docstrings, README content, example descriptions, and user-facing text
- This maintains consistency with the project's established documentation voice

### Code Language: US English  
- Use `behavior`, `color`, `center`, `realize`, `organization`, `optimize`, `analyze`
- Apply to variable names, function names, module names, and code comments
- This follows standard programming conventions and library compatibility

### Professional Tone Requirements
- **Calm and factual**: Avoid promotional or "sales" language
- **Concise**: Be direct and informative without unnecessary words
- **Educational focus**: Maintain instructional, tutorial-appropriate language
- **Minimal punctuation**: Avoid excessive exclamation marks
- **No emojis**: Keep all generated content professional and text-based (warning icons ⚠️, check marks ✅, and crosses ❌ acceptable)
- **Consistent voice**: Match the existing project documentation style

### Why These Standards Matter
- **Consistency**: Maintains the project's established voice across all content
- **Professionalism**: Ensures educational content feels authoritative and trustworthy  
- **International standards**: Respects the Australian/British English preference for user documentation
- **AI agent compliance**: Prevents AI-generated content from introducing inconsistent language patterns

## Code Style

- **Formatting**: Follow `mix format` with exceptions for matrices (use `# mix format: off|on`)
- **Sigils**: Use `~m`atrix, `~v`ertex, `~i`ndex for compile-time constants
- **Variables**: Descriptive names, especially for OpenGL state
- **Functions**: Include typespecs for public functions
- **Documentation**: Comprehensive docstrings with code examples
- **Multiline Output**: Use heredocs for multiline `IO.puts` statements instead of multiple calls

### Multiline IO Output Pattern

```elixir
# ✅ Preferred - Use heredoc for multiline output
IO.puts("""

=== Example Title ===
Multiple lines of explanatory text
that provide educational context.

Learning objectives and implementation details
Usage tips and control instructions
===============================
""")

# ❌ Avoid - Multiple individual IO.puts calls
IO.puts("=== Example Title ===")
IO.puts("Multiple lines...")
IO.puts("Learning objectives...")
```

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