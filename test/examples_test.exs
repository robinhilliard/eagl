defmodule ExamplesTest do
  @moduledoc """
  Automated testing of EAGL examples with timeouts.

  This test suite runs examples in parallel with short timeouts to verify
  they can initialize properly without hanging or crashing.
  """

  use ExUnit.Case
  import ExUnit.CaptureIO

  @timeout_duration 500

  # List of all testable examples - all examples from run_examples script that support timeout
  @interactive_examples [
    # Non-Learn OpenGL Interactive Examples
    {EAGL.Examples.Teapot, "Teapot Example"},

    # Learn OpenGL Getting Started Examples
    # Hello Window
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindow, "1.1 Hello Window"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindowClear, "1.2 Hello Window Clear"},

    # Hello Triangle
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle, "2.1 Hello Triangle"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed, "2.2 Hello Triangle Indexed"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1, "2.3 Hello Triangle Exercise 1"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2, "2.4 Hello Triangle Exercise 2"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3, "2.5 Hello Triangle Exercise 3"},

    # Shaders
    {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersUniform, "3.1 Shaders Uniform"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersInterpolation, "3.2 Shaders Interpolation"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersClass, "3.3 Shaders Class"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise1, "3.4 Shaders Exercise 1"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise2, "3.5 Shaders Exercise 2"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.ShadersExercise3, "3.6 Shaders Exercise 3"},

    # Textures
    {EAGL.Examples.LearnOpenGL.GettingStarted.Textures, "4.1 Textures"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TexturesCombined, "4.2 Textures Combined"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise1, "4.3 Textures Exercise 1"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise2, "4.4 Textures Exercise 2"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise3, "4.5 Textures Exercise 3"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TexturesExercise4, "4.6 Textures Exercise 4"},

    # Transformations
    {EAGL.Examples.LearnOpenGL.GettingStarted.Transformations, "5.1 Transformations"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise1, "5.2 Transformations Exercise 1"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.TransformationsExercise2, "5.2 Transformations Exercise 2"},

    # Coordinate Systems
    {EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystems, "6.1 Coordinate Systems"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsDepth, "6.2 Coordinate Systems Depth"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsMultiple, "6.3 Coordinate Systems Multiple"},
    {EAGL.Examples.LearnOpenGL.GettingStarted.CoordinateSystemsExercise, "6.4 Coordinate Systems Exercise"}
  ]

  # Non-interactive examples that complete immediately
  @non_interactive_examples [
    {EAGL.Examples.Math, "Math Example"}
  ]



  describe "example timeout tests" do
    @describetag timeout: 30_000  # Allow time for all examples to complete with their built-in timeouts
    test "examples run and timeout correctly" do
      # Run interactive examples with limited concurrency (8 at a time)
      # Each example uses its own timeout system that starts after first render
      interactive_results = @interactive_examples
      |> Task.async_stream(
        fn {module, name} ->
          {module, name, run_example_with_timeout(module, name), :interactive}
        end,
        max_concurrency: 4,
        timeout: :infinity  # Let examples handle their own timeouts after setup
      )
      |> Enum.to_list()
      |> Enum.map(fn {:ok, result} -> result end)

      # Run non-interactive examples (these complete immediately)
      non_interactive_results = @non_interactive_examples
      |> Task.async_stream(
        fn {module, name} ->
          {module, name, run_example_with_timeout(module, name), :non_interactive}
        end,
        max_concurrency: 4,
        timeout: :infinity  # These complete quickly anyway
      )
      |> Enum.to_list()
      |> Enum.map(fn {:ok, result} -> result end)

      # Combine all results
      results = interactive_results ++ non_interactive_results

      # Verify all examples behaved correctly
      Enum.each(results, fn {module, name, {output, result}, type} ->
        assert result == :ok, "Example #{name} (#{module}) failed: #{inspect(result)}"

        case type do
          :interactive ->
            assert String.contains?(output, "EAGL_TIMEOUT: Window timed out after #{@timeout_duration}ms"),
                   "Interactive example #{name} (#{module}) did not timeout correctly. Output: #{output}"
          :non_interactive ->
            # Non-interactive examples complete immediately
            refute String.contains?(output, "EAGL_TIMEOUT"),
                   "Non-interactive example #{name} (#{module}) should not timeout. Output: #{output}"
        end

        # Verify no error messages in output for all examples
        refute String.contains?(output, "Error"),
               "Example #{name} (#{module}) had errors: #{output}"
      end)
    end

    test "individual example - Math" do
      {output, result} = run_example_with_timeout(
        EAGL.Examples.Math,
        "Math"
      )

      assert result == :ok
      # Math example completes immediately, doesn't timeout
      assert String.contains?(output, "Math demo completed successfully!")
      refute String.contains?(output, "Error")
      # Math example doesn't use the window system, so no timeout message
      refute String.contains?(output, "EAGL_TIMEOUT")
    end
  end

  # Helper function to run an example with timeout and capture output
  defp run_example_with_timeout(module, name) do
    try do
      output = capture_io(fn ->
        # Let the example handle its own timeout - it will return when ready
        result = module.run_example(timeout: @timeout_duration)
        send(self(), {:result, result})
      end)

            result = receive do
        {:result, res} -> res
      after
        # Very generous timeout - examples control their own timing
        25_000 -> :timeout
      end

      {output, result}
    rescue
      e ->
        {"Error running #{name}: #{inspect(e)}", {:error, e}}
    catch
      :exit, reason ->
        {"Exit during #{name}: #{inspect(reason)}", {:error, {:exit, reason}}}
    end
  end
end
