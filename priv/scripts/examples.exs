# Interactive examples runner for EAGL OpenGL examples.
#
# This is a development-only script for running EAGL examples.
# It's designed to work when you have the EAGL source code available.
#
# Usage:
#   mix run priv/scripts/examples.exs
#   mix run priv/scripts/examples.exs --list
#   mix run priv/scripts/examples.exs 01
#
# Or via Mix alias:
#   mix examples
#   mix examples --list
#   mix examples 01

defmodule EAGLExamplesRunner do
  @moduledoc """
  Standalone script for running EAGL OpenGL examples.

  This script provides a cross-platform replacement for the bash `run_examples` script,
  offering identical functionality while being completely platform-independent.

  ## Usage

      # Interactive mode (displays menu and prompts for input)
      mix examples

      # List all available examples
      mix examples --list

      # Run specific example by code
      mix examples 01
      mix examples 111
      mix examples 212

  ## Adding New Examples

  To add new examples to this script, modify the `@examples` module attribute below.
  Each example is defined as a map with the following structure:

      "code" => %{
        type: :example_type,           # :top_level, :learnopengl, or :standalone
        file: "path/to/example.ex",    # Relative to project root
        module: Module.Name,           # For :top_level and :learnopengl types
        name: "Display Name",          # Short descriptive name
        description: "Long description" # Optional, for top-level examples
      }

  ### Example Types

  - `:top_level`: Examples in the main examples/ directory (01-03)
    - Requires `file` and `module` keys
    - Should include `description` for menu display
    - Executed via `Code.require_file(file)` then `module.run_example()`

  - `:learnopengl`: Learn OpenGL tutorial examples (111-176, 211-218)
    - Requires `file` and `module` keys
    - Executed via `Code.require_file(file)` then `module.run_example()`
    - Organized by chapter/section numbering

  - `:standalone`: Standalone .exs scripts (like GLB web demo)
    - Requires only `file` key
    - Executed via `Code.eval_file(file)`
    - No module loading required

  ### Code Numbering Convention

  - `01-09`: Reserved for top-level examples
  - `1XX`: Learn OpenGL Getting Started (where XX = chapter.section * 10 + exercise)
  - `2XX`: Learn OpenGL Lighting
  - `3XX`: Learn OpenGL Model Loading (future)
  - `4XX`: Learn OpenGL Advanced OpenGL (future)
  - `5XX`: Learn OpenGL Advanced Lighting (future)
  - `6XX`: Learn OpenGL PBR (future)

  ### Cross-Platform Considerations

  This implementation is designed to work identically on Windows, macOS, Linux, and
  other platforms supported by Elixir. Key design decisions:

  - Uses `Code.require_file/1` and `Code.eval_file/1` instead of shell commands
  - Cross-platform screen clearing using `IO.ANSI.clear()` and `IO.ANSI.home()`
  - Automatic ANSI color support detection via `IO.ANSI.enabled?()`
  - IO functions for all user input/output

  ## Architecture Notes for AI Agents

  This module is structured for easy automated extension:

  1. **Data-Driven Design**: All examples are defined in the `@examples` map
  2. **Type-Based Execution**: The `execute_example/1` function pattern matches on type
  3. **Automatic Discovery**: `valid_codes/0` dynamically generates valid codes
  4. **Consistent Patterns**: All examples follow the same execution pattern
  5. **Error Handling**: Graceful fallbacks for missing files or modules

  When programmatically adding examples:
  1. Parse the examples directory structure
  2. Generate appropriate codes following the numbering convention
  3. Determine module names from file paths/content
  4. Add entries to the @examples map
  5. Update menu display if adding new categories
  """

    # No need for manual ANSI codes - we'll use IO.ANSI for cross-platform compatibility

  # Complete example definitions mapping codes to execution information
  @examples %{
    # Top-level examples
    "01" => %{
      type: :top_level,
      file: "examples/math_example.ex",
      module: EAGL.Examples.Math,
      name: "Math Example",
      description: "Comprehensive EAGL.Math functionality demo"
    },
    "02" => %{
      type: :top_level,
      file: "examples/teapot_example.ex",
      module: EAGL.Examples.Teapot,
      name: "Teapot Example",
      description: "3D teapot with Phong shading"
    },


    # Learn OpenGL Getting Started Examples
    "111" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/1_1_hello_window.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindow,
      name: "1.1 Window"
    },
    "112" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/1_2_hello_window_clear.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindowClear,
      name: "1.2 Clear Colors"
    },
    "121" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/2_1_hello_triangle.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle,
      name: "2.1 Triangle"
    },
    "122" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/2_2_hello_triangle_indexed.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed,
      name: "2.2 Indexed"
    },
    "123" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/2_3_hello_triangle_exercise_1.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1,
      name: "2.3 Exercise1"
    },
    "124" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/2_4_hello_triangle_exercise_2.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2,
      name: "2.4 Exercise2"
    },
    "125" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/2_5_hello_triangle_exercise_3.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3,
      name: "2.5 Exercise3"
    },
    "131" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/3_1_shaders_uniform.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.ShadersUniform,
      name: "3.1 Uniform"
    },
    "132" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/3_2_shaders_interpolation.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.ShadersInterpolation,
      name: "3.2 Interpolation"
    },
    "133" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/3_3_shaders_class.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.ShadersClass,
      name: "3.3 Class"
    },
    "134" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/3_4_shaders_exercise_1.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise1,
      name: "3.4 Exercise1"
    },
    "135" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/3_5_shaders_exercise_2.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise2,
      name: "3.5 Exercise2"
    },
    "136" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/3_6_shaders_exercise_3.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise3,
      name: "3.6 Exercise3"
    },
    "141" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/4_1_textures.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.Textures,
      name: "4.1 Basic"
    },
    "142" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/4_2_textures_combined.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TexturesCombined,
      name: "4.2 Combined"
    },
    "143" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/4_3_textures_exercise_1.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise1,
      name: "4.3 Exercise1"
    },
    "144" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/4_4_textures_exercise_2.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise2,
      name: "4.4 Exercise2"
    },
    "145" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/4_5_textures_exercise_3.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise3,
      name: "4.5 Exercise3"
    },
    "146" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/4_6_textures_exercise_4.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise4,
      name: "4.6 Exercise4"
    },
    "151" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/5_1_transformations.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.Transformations,
      name: "5.1 Basic"
    },
    "152" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/5_2_transformations_exercise_1.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise1,
      name: "5.2 Exercise1"
    },
    "153" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/5_2_transformations_exercise_2.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise2,
      name: "5.2 Exercise2"
    },
    "161" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/6_1_coordinate_systems.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystems,
      name: "6.1 Basic"
    },
    "162" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/6_2_coordinate_systems_depth.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsDepth,
      name: "6.2 Depth"
    },
    "163" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/6_3_coordinate_systems_multiple.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsMultiple,
      name: "6.3 Multiple"
    },
    "164" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/6_4_coordinate_systems_exercise.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsExercise,
      name: "6.4 Exercise"
    },
    "171" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/7_1_camera_circle.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CameraCircle,
      name: "7.1 Circle"
    },
    "172" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/7_2_camera_keyboard_dt.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CameraKeyboardDt,
      name: "7.2 Keyboard+DT"
    },
    "173" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/7_3_camera_mouse_zoom.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CameraMouseZoom,
      name: "7.3 Mouse+Zoom"
    },
    "174" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/7_4_camera_class.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CameraClass,
      name: "7.4 Camera Class"
    },
    "175" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/7_5_camera_exercise1.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CameraExercise1,
      name: "7.5 FPS Camera"
    },
    "176" => %{
      type: :learnopengl,
      file: "examples/learnopengl/1_getting_started/7_6_camera_exercise2.ex",
      module: EAGL.Examples.LearnOpenGL.GettingStarted.CameraExercise2,
      name: "7.6 Custom LookAt"
    },

    # Learn OpenGL Lighting Examples
    "211" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/1_1_colors.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.Colors,
      name: "1.1 Colors"
    },
    "212" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/2_1_basic_lighting_diffuse.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.BasicLightingDiffuse,
      name: "2.1 Diffuse"
    },
    "213" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/2_2_basic_lighting_specular.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.BasicLightingSpecular,
      name: "2.2 Specular"
    },
    "214" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/2_3_basic_lighting_exercise1.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise1,
      name: "2.3 Exercise1"
    },
    "215" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/2_4_basic_lighting_exercise2.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise2,
      name: "2.4 Exercise2"
    },
    "216" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/2_5_basic_lighting_exercise3.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.BasicLightingExercise3,
      name: "2.5 Exercise3"
    },
    "217" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/3_1_materials.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.Materials,
      name: "3.1 Materials"
    },
    "218" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/3_2_materials_exercise1.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.MaterialsExercise1,
      name: "3.2 Exercise1"
    },

    # ============================================================================
    # GLTF SUPPORT EXAMPLES (3XX)
    # GLTF/GLB loading and rendering demonstrations
    # ============================================================================

    "301" => %{
      type: :standalone,
      file: "examples/gltf/animation_example.exs",
      name: "Animation Example",
      description: "GLTF animation playback and control"
    },
    "302" => %{
      type: :standalone,
      file: "examples/gltf/glb_loader_example.exs",
      name: "GLB Loader Example",
      description: "Basic GLB file loading and rendering"
    },
    "303" => %{
      type: :standalone,
      file: "examples/gltf/glb_web_demo.exs",
      name: "GLB Web Demo",
      description: "Load and render GLB files from the web"
    },
    "304" => %{
      type: :standalone,
      file: "examples/gltf/gltf_scene_example.exs",
      name: "GLTF Scene Example",
      description: "Complete GLTF scene rendering"
    }
  }

  def main(args \\ []) do
    case args do
      ["--list"] ->
        list_examples()
      [code] when is_binary(code) ->
        run_example(code)
      [] ->
        interactive_mode()
      _ ->
        IO.puts("Invalid arguments. Usage: examples.exs [--list] [code]")
    end
  end

  # Interactive menu mode
  defp interactive_mode do
    loop = fn loop_fn ->
      clear_screen()
      show_menu()
      choice = get_user_input("Enter code (01, 02, 111-176, 211-218, 301-304), 'q' to quit, 'r' to refresh: ")

      case String.trim(choice) do
        choice when choice in ["q", "Q", "quit", "exit"] ->
          colorize("Goodbye!", :green) |> IO.puts()

        choice when choice in ["r", "R", "refresh"] ->
          loop_fn.(loop_fn)

        code when is_map_key(@examples, code) ->
          clear_screen()
          run_example(code)
          get_user_input("\nPress ENTER to return to menu...")
          loop_fn.(loop_fn)

        _ ->
          IO.puts(colorize("Invalid input.", :red))
          IO.puts(colorize("Valid codes: #{valid_codes()}", :yellow))
          get_user_input("Press ENTER to continue...")
          loop_fn.(loop_fn)
      end
    end

    loop.(loop)
  end

  # Display the main menu
  defp show_menu do
    IO.puts(colorize("════════════════════════════════════════════════════════════════════════════════════════════════════════════════════", :purple))
    IO.puts(colorize("                                                    EAGL Examples Menu                                                    ", :purple))
    IO.puts(colorize("════════════════════════════════════════════════════════════════════════════════════════════════════════════════════", :purple))
    IO.puts("")

    # Non-Learn OpenGL examples
    IO.puts(colorize("0. Non-Learn OpenGL Examples:", :blue))
    show_example_group(["01", "02"])
    IO.puts("")

    # Learn OpenGL Getting Started
    IO.puts(colorize("1. Learn OpenGL Getting Started Examples:", :blue))
    IO.puts("")

    IO.puts(colorize("  Hello Window:", :yellow) <> "       #{format_examples(["111", "112"])}")
    IO.puts("")
    IO.puts(colorize("  Hello Triangle:", :yellow) <> "     #{format_examples(["121", "122", "123"])}")
    IO.puts("                      #{format_examples(["124", "125"])}")
    IO.puts("")
    IO.puts(colorize("  Shaders:", :yellow) <> "            #{format_examples(["131", "132", "133"])}")
    IO.puts("                      #{format_examples(["134", "135", "136"])}")
    IO.puts("")
    IO.puts(colorize("  Textures:", :yellow) <> "           #{format_examples(["141", "142", "143"])}")
    IO.puts("                      #{format_examples(["144", "145", "146"])}")
    IO.puts("")
    IO.puts(colorize("  Transformations:", :yellow) <> "    #{format_examples(["151", "152", "153"])}")
    IO.puts("")
    IO.puts(colorize("  Coord Systems:", :yellow) <> "      #{format_examples(["161", "162", "163"])}")
    IO.puts("                      #{format_examples(["164"])}")
    IO.puts("")
    IO.puts(colorize("  Camera:", :yellow) <> "             #{format_examples(["171", "172", "173"])}")
    IO.puts("                      #{format_examples(["174", "175", "176"])}")
    IO.puts("")

    # Learn OpenGL Lighting
    IO.puts(colorize("2. Learn OpenGL Lighting Examples:", :blue))
    IO.puts("")
    IO.puts(colorize("  Colors:", :yellow) <> "             #{format_examples(["211"])}")
    IO.puts(colorize("  Basic Lighting:", :yellow) <> "     #{format_examples(["212", "213"])}")
    IO.puts(colorize("  Lighting Exercises:", :yellow) <> " #{format_examples(["214", "215", "216"])}")
    IO.puts(colorize("  Materials:", :yellow) <> "          #{format_examples(["217", "218"])}")
    IO.puts("")

    # GLTF Support
    IO.puts(colorize("3. GLTF Support Examples:", :blue))
    show_example_group(["301", "302", "303", "304"])
    IO.puts("")

    IO.puts(colorize("════════════════════════════════════════════════════════════════════════════════════════════════════════════════════", :purple))
  end

  # Show a group of examples (for non-Learn OpenGL section)
  defp show_example_group(codes) do
    Enum.each(codes, fn code ->
      example = @examples[code]
      formatted_code = colorize("#{code})", :cyan)
      formatted_name = colorize(example.name, :green)
      IO.puts("  #{formatted_code} #{formatted_name} - #{example.description}")
    end)
  end

  # Format examples for compact display
  defp format_examples(codes) do
    codes
    |> Enum.map(fn code ->
      example = @examples[code]
      code_part = colorize("#{code})", :cyan)
      name_part = example.name
      "#{code_part} #{name_part}"
    end)
    |> Enum.join("  ")
  end

  # Run a specific example by code
  defp run_example(code) do
    case Map.get(@examples, code) do
      nil ->
        IO.puts(colorize("Invalid example code: #{code}", :red))
        IO.puts(colorize("Available codes: #{valid_codes()}", :yellow))

      example ->
        execute_example(example)
    end
  end

  # Execute an example based on its type
  defp execute_example(%{type: :top_level, module: module} = example) do
    IO.puts(colorize("Running: #{inspect(module)}.run_example()", :green))
    IO.puts("")

    try do
      Code.require_file(example.file)
      apply(module, :run_example, [])

      IO.puts("")
      IO.puts(colorize("Example finished.", :green))
    rescue
      error ->
        IO.puts(colorize("Error running example: #{inspect(error)}", :red))
    end
  end

  defp execute_example(%{type: :learnopengl, module: module} = example) do
    IO.puts(colorize("Running: #{inspect(module)}.run_example()", :green))
    IO.puts("")

    try do
      Code.require_file(example.file)
      apply(module, :run_example, [])

      IO.puts("")
      IO.puts(colorize("Example finished.", :green))
    rescue
      error ->
        IO.puts(colorize("Error running example: #{inspect(error)}", :red))
    end
  end

  defp execute_example(%{type: :standalone} = example) do
    IO.puts(colorize("Running: #{example.name} (#{example.file})", :green))
    IO.puts("")

    try do
      case Code.eval_file(example.file) do
        {result, _binding} ->
          unless result in [nil, :ok] do
            IO.puts("Result: #{inspect(result)}")
          end
        _ ->
          :ok
      end

      IO.puts("")
      IO.puts(colorize("Example finished.", :green))
    rescue
      error ->
        IO.puts(colorize("Error running example: #{inspect(error)}", :red))
    end
  end

  # List all available examples
  defp list_examples do
    IO.puts("Available EAGL Examples:")
    IO.puts("")

    # Group by type for better organization
    non_learnopengl = Enum.filter(@examples, fn {_code, example} ->
      example.type in [:top_level, :standalone]
    end)

    learnopengl = Enum.filter(@examples, fn {_code, example} ->
      example.type == :learnopengl
    end)

    IO.puts("Non-Learn OpenGL Examples:")
    non_learnopengl
    |> Enum.sort_by(fn {code, _example} -> code end)
    |> Enum.each(fn {code, example} ->
      description = Map.get(example, :description, "")
      IO.puts("  #{code}: #{example.name}" <> if(description != "", do: " - #{description}", else: ""))
    end)

    IO.puts("")
    IO.puts("Learn OpenGL Examples:")
    learnopengl
    |> Enum.sort_by(fn {code, _example} -> code end)
    |> Enum.each(fn {code, example} ->
      IO.puts("  #{code}: #{example.name}")
    end)
  end

  # Cross-platform screen clearing using IO.ANSI
  defp clear_screen do
    if IO.ANSI.enabled?() do
      # Use IO.ANSI for reliable cross-platform clearing
      IO.write([IO.ANSI.clear(), IO.ANSI.home()])
    else
      # Fallback for terminals that don't support ANSI
      try do
        case :os.type() do
          {:win32, _} -> System.cmd("cmd", ["/c", "cls"])
          _ -> System.cmd("clear", [])
        end
      rescue
        _ -> IO.puts(String.duplicate("\n", 50))
      end
    end
  end

  # Cross-platform user input
  defp get_user_input(prompt) do
    IO.gets(prompt) |> String.trim()
  end

  # Apply ANSI colors using IO.ANSI with automatic graceful degradation
  defp colorize(text, color) do
    if IO.ANSI.enabled?() do
      color_code = case color do
        :red -> IO.ANSI.red()
        :green -> IO.ANSI.green()
        :yellow -> IO.ANSI.yellow()
        :blue -> IO.ANSI.blue()
        :purple -> IO.ANSI.magenta()
        :cyan -> IO.ANSI.cyan()
        _ -> ""
      end
      color_code <> text <> IO.ANSI.reset()
    else
      text
    end
  end

  # Get list of valid example codes
  defp valid_codes do
    @examples
    |> Map.keys()
    |> Enum.sort()
    |> Enum.join(", ")
  end
end

# Execute the script when run directly
EAGLExamplesRunner.main(System.argv())
