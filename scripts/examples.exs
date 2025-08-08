#!/usr/bin/env elixir

# Interactive examples runner for EAGL OpenGL examples.
#
# This is a development-only script for running EAGL examples.
# It's designed to work when you have the EAGL source code available.
#
# Usage:
#   ./scripts/examples.exs
#   ./scripts/examples.exs --list
#   ./scripts/examples.exs 01

defmodule EAGLExamplesRunner do
  @moduledoc """
  Standalone script for running EAGL OpenGL examples.

  This Mix task provides a cross-platform replacement for the bash `run_examples` script,
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

  To add new examples to this task, modify the `@examples` module attribute below.
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

  ### Menu Display Customization

  The `show_menu/0` function controls the interactive menu layout. When adding new
  categories or reorganizing examples:

  1. Update the menu sections in `show_menu/0`
  2. Add appropriate color-coded groupings
  3. Update the `format_examples/1` helper for compact display
  4. Ensure `valid_codes/0` automatically includes new codes

  ### Cross-Platform Considerations

  This implementation is designed to work identically on Windows, macOS, Linux, and
  other platforms supported by Elixir. Key design decisions:

  - Uses `Code.require_file/1` and `Code.eval_file/1` instead of shell commands
  - Cross-platform screen clearing with fallbacks
  - ANSI color detection and graceful degradation
  - Mix.shell() abstraction for all user I/O

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



  # ANSI color codes for cross-platform terminal colors
  # These gracefully degrade on systems that don't support ANSI colors
  @colors %{
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    blue: "\e[34m",
    purple: "\e[35m",
    cyan: "\e[36m",
    reset: "\e[0m"
  }

  # Complete example definitions mapping codes to execution information
  # This is the primary data structure that defines all available examples
  #
  # EXTENSION POINT: Add new examples here following the documented patterns
  @examples %{
    # ============================================================================
    # TOP-LEVEL EXAMPLES (01-09)
    # These are examples in the main examples/ directory
    # ============================================================================
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
    "03" => %{
      type: :standalone,
      file: "examples/gltf/glb_web_demo.exs",
      name: "GLB Web Demo",
      description: "Load and render GLB files from the web"
    },

    # ============================================================================
    # LEARN OPENGL GETTING STARTED EXAMPLES (1XX)
    # Chapter 1: Getting Started
    # Numbering: 1 + chapter*10 + section*10 + exercise
    # ============================================================================

    # Chapter 1.1: Hello Window
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

    # Chapter 1.2: Hello Triangle
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

    # Chapter 1.3: Shaders
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

    # Chapter 1.4: Textures
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

    # Chapter 1.5: Transformations
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

    # Chapter 1.6: Coordinate Systems
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

    # Chapter 1.7: Camera
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

    # ============================================================================
    # LEARN OPENGL LIGHTING EXAMPLES (2XX)
    # Chapter 2: Lighting
    # Numbering: 2 + chapter*10 + section*10 + exercise
    # ============================================================================

    # Chapter 2.1: Colors
    "211" => %{
      type: :learnopengl,
      file: "examples/learnopengl/2_lighting/1_1_colors.ex",
      module: EAGL.Examples.LearnOpenGL.Lighting.Colors,
      name: "1.1 Colors"
    },

    # Chapter 2.2: Basic Lighting
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

    # Chapter 2.3: Materials
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
    }

    # ============================================================================
    # FUTURE EXTENSION POINTS
    # ============================================================================
    # Add new example categories here following the numbering convention:
    # 3XX: Learn OpenGL Model Loading
    # 4XX: Learn OpenGL Advanced OpenGL
    # 5XX: Learn OpenGL Advanced Lighting
    # 6XX: Learn OpenGL PBR
    # 7XX: Learn OpenGL In Practice
    # 8XX-9XX: Custom EAGL examples
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

  # ============================================================================
  # INTERACTIVE MODE
  # ============================================================================

  # Interactive menu mode - main entry point for user interaction
  defp interactive_mode do
    clear_screen()

    # Recursive loop function for continuous interaction
    # This pattern allows for clean state management and easy extension
    loop = fn loop_fn ->
      show_menu()

      choice =
        get_user_input("Enter code (01, 02, 03, 111-176, 211-218), 'q' to quit, 'r' to refresh: ")

      case String.trim(choice) do
        choice when choice in ["q", "Q", "quit", "exit"] ->
          colorize("Goodbye!", :green) |> IO.puts()

        choice when choice in ["r", "R", "refresh"] ->
          clear_screen()
          loop_fn.(loop_fn)

        code when is_map_key(@examples, code) ->
          clear_screen()
          run_example(code)
          get_user_input("\nPress ENTER to return to menu...")
          clear_screen()
          loop_fn.(loop_fn)

        _ ->
          Mix.shell().error(colorize("Invalid input.", :red))
          Mix.shell().info(colorize("Valid codes: #{valid_codes()}", :yellow))
          get_user_input("Press ENTER to continue...")
          clear_screen()
          loop_fn.(loop_fn)
      end
    end

    loop.(loop)
  end

  # ============================================================================
  # MENU DISPLAY SYSTEM
  # ============================================================================

  # Display the main interactive menu
  # EXTENSION POINT: Modify this function when adding new example categories
  defp show_menu do
    Mix.shell().info(
      colorize("════════════════════════════════════════════════════════════════", :purple)
    )

    Mix.shell().info(
      colorize("                         EAGL Examples Menu                        ", :purple)
    )

    Mix.shell().info(
      colorize("════════════════════════════════════════════════════════════════", :purple)
    )

    Mix.shell().info("")

    # Non-Learn OpenGL examples
    Mix.shell().info(colorize("0. Non-Learn OpenGL Examples:", :blue))
    show_example_group(["01", "02", "03"])
    Mix.shell().info("")

    # Learn OpenGL Getting Started
    Mix.shell().info(colorize("1. Learn OpenGL Getting Started Examples:", :blue))
    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Hello Window:", :yellow) <> "     #{format_examples(["111", "112"])}"
    )

    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Hello Triangle:", :yellow) <> "   #{format_examples(["121", "122", "123"])}"
    )

    Mix.shell().info("                    #{format_examples(["124", "125"])}")
    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Shaders:", :yellow) <> "          #{format_examples(["131", "132", "133"])}"
    )

    Mix.shell().info("                    #{format_examples(["134", "135", "136"])}")
    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Textures:", :yellow) <> "         #{format_examples(["141", "142", "143"])}"
    )

    Mix.shell().info("                    #{format_examples(["144", "145", "146"])}")
    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Transformations:", :yellow) <> "  #{format_examples(["151", "152", "153"])}"
    )

    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Coord Systems:", :yellow) <> "    #{format_examples(["161", "162", "163"])}"
    )

    Mix.shell().info("                    #{format_examples(["164"])}")
    Mix.shell().info("")

    Mix.shell().info(
      colorize("  Camera:", :yellow) <> "           #{format_examples(["171", "172", "173"])}"
    )

    Mix.shell().info("                    #{format_examples(["174", "175", "176"])}")
    Mix.shell().info("")

    # Learn OpenGL Lighting
    Mix.shell().info(colorize("2. Learn OpenGL Lighting Examples:", :blue))
    Mix.shell().info("")
    Mix.shell().info(colorize("  Colors:", :yellow) <> "           #{format_examples(["211"])}")

    Mix.shell().info(
      colorize("  Basic Lighting:", :yellow) <> "   #{format_examples(["212", "213"])}"
    )

    Mix.shell().info(
      colorize("  Lighting Exercises:", :yellow) <> " #{format_examples(["214", "215", "216"])}"
    )

    Mix.shell().info(
      colorize("  Materials:", :yellow) <> "        #{format_examples(["217", "218"])}"
    )

    Mix.shell().info("")

    Mix.shell().info(
      colorize("════════════════════════════════════════════════════════════════", :purple)
    )
  end

  # Show a group of examples (for non-Learn OpenGL section)
  # Used for top-level examples that have descriptions
  defp show_example_group(codes) do
    Enum.each(codes, fn code ->
      example = @examples[code]
      formatted_code = colorize("#{code})", :cyan)
      formatted_name = colorize(example.name, :green)
      Mix.shell().info("  #{formatted_code} #{formatted_name} - #{example.description}")
    end)
  end

  # Format examples for compact display in the menu
  # This creates the compact layout used for Learn OpenGL examples
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

  # ============================================================================
  # EXAMPLE EXECUTION SYSTEM
  # ============================================================================

  # Run a specific example by code
  # ENTRY POINT: This function handles all example execution
  defp run_example(code) do
    case Map.get(@examples, code) do
      nil ->
        Mix.shell().error(colorize("Invalid example code: #{code}", :red))
        Mix.shell().info(colorize("Available codes: #{valid_codes()}", :yellow))

      example ->
        execute_example(example)
    end
  end

  # Execute an example based on its type
  # EXTENSION POINT: Add new execution types here if needed
  # Pattern matches on the :type field to determine execution strategy

  # Top-level examples (Math, Teapot, etc.)
  defp execute_example(%{type: :top_level, module: module} = example) do
    Mix.shell().info(colorize("Running: #{inspect(module)}.run_example()", :green))
    Mix.shell().info("")

    try do
      # Load the file and run the module
      Code.require_file(example.file)
      apply(module, :run_example, [])

      Mix.shell().info("")
      Mix.shell().info(colorize("Example finished.", :green))
    rescue
      error ->
        Mix.shell().error(colorize("Error running example: #{inspect(error)}", :red))
    end
  end

  # Learn OpenGL examples (structured tutorials)
  defp execute_example(%{type: :learnopengl, module: module} = example) do
    Mix.shell().info(colorize("Running: #{inspect(module)}.run_example()", :green))
    Mix.shell().info("")

    try do
      # Load the file and run the module
      Code.require_file(example.file)
      apply(module, :run_example, [])

      Mix.shell().info("")
      Mix.shell().info(colorize("Example finished.", :green))
    rescue
      error ->
        Mix.shell().error(colorize("Error running example: #{inspect(error)}", :red))
    end
  end

  # Standalone scripts (like GLB web demo)
  defp execute_example(%{type: :standalone} = example) do
    Mix.shell().info(colorize("Running: #{example.name} (#{example.file})", :green))
    Mix.shell().info("")

    try do
      # For standalone scripts, we execute them directly
      case Code.eval_file(example.file) do
        {result, _binding} ->
          # Only show result if it's not nil/ok (to avoid noise)
          unless result in [nil, :ok] do
            Mix.shell().info("Result: #{inspect(result)}")
          end

        _ ->
          :ok
      end

      Mix.shell().info("")
      Mix.shell().info(colorize("Example finished.", :green))
    rescue
      error ->
        Mix.shell().error(colorize("Error running example: #{inspect(error)}", :red))
    end
  end

  # ============================================================================
  # LISTING AND DISCOVERY
  # ============================================================================

  # List all available examples in organized format
  # This provides a non-interactive way to see all examples
  defp list_examples do
    Mix.shell().info("Available EAGL Examples:")
    Mix.shell().info("")

    # Group by type for better organization
    non_learnopengl =
      Enum.filter(@examples, fn {_code, example} ->
        example.type in [:top_level, :standalone]
      end)

    learnopengl =
      Enum.filter(@examples, fn {_code, example} ->
        example.type == :learnopengl
      end)

    # Show non-Learn OpenGL examples with descriptions
    Mix.shell().info("Non-Learn OpenGL Examples:")

    non_learnopengl
    |> Enum.sort_by(fn {code, _example} -> code end)
    |> Enum.each(fn {code, example} ->
      description = Map.get(example, :description, "")

      Mix.shell().info(
        "  #{code}: #{example.name}" <> if(description != "", do: " - #{description}", else: "")
      )
    end)

    Mix.shell().info("")
    Mix.shell().info("Learn OpenGL Examples:")

    learnopengl
    |> Enum.sort_by(fn {code, _example} -> code end)
    |> Enum.each(fn {code, example} ->
      Mix.shell().info("  #{code}: #{example.name}")
    end)
  end

  # Get list of valid example codes (automatically generated from @examples)
  # This ensures the help text is always accurate
  defp valid_codes do
    @examples
    |> Map.keys()
    |> Enum.sort()
    |> Enum.join(", ")
  end

  # ============================================================================
  # CROSS-PLATFORM UTILITIES
  # ============================================================================

  # Cross-platform screen clearing with graceful fallbacks
  # Detects platform and uses appropriate clear command
  defp clear_screen do
    case :os.type() do
      {:win32, _} ->
        # Windows command prompt
        System.cmd("cmd", ["/c", "cls"])

      _ ->
        # Unix-like systems (Linux, macOS, FreeBSD, etc.)
        System.cmd("clear", [])
    end

    :ok
  rescue
    _ ->
      # If system commands fail (rare), just print newlines
      # This ensures the task works even in restricted environments
      Mix.shell().info(String.duplicate("\n", 50))
  end

  # Cross-platform user input using Mix's shell abstraction
  # This ensures consistent behavior across all platforms
  defp get_user_input(prompt) do
    Mix.shell().prompt(prompt)
  end

  # Apply ANSI colors with graceful degradation
  # Automatically detects if colors are supported and falls back to plain text
  defp colorize(text, color) do
    if ansi_supported?() do
      @colors[color] <> text <> @colors[:reset]
    else
      text
    end
  end

  # Check if ANSI colors are supported in the current terminal
  # This prevents ugly escape sequences on terminals that don't support colors
  defp ansi_supported? do
    case System.get_env("TERM") do
      nil -> false
      term -> not String.contains?(term, "dumb")
    end
  end
end
