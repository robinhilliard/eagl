defmodule EAGL.Examples.Test do
  use ExUnit.Case, async: false

  test "math example" do
    EAGL.Examples.Math.run_example()
    assert true
  end

  @tag :skip_in_ci
  test "teapot example" do
    if System.get_env("CI") do
      # Skip interactive examples in CI - they would hang waiting for user input
      IO.puts("Skipping interactive teapot example in CI environment")
      assert true
    else
      EAGL.Examples.Teapot.run_example()
      assert true
    end
  end

  # Add tests for LearnOpenGL examples with CI detection
  @tag :skip_in_ci
  test "hello triangle exercise 1" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1.run_example()
      assert true
    end
  end

  @tag :skip_in_ci
  test "hello triangle exercise 2" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2.run_example()
      assert true
    end
  end

  @tag :skip_in_ci
  test "hello triangle exercise 3" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3.run_example()
      assert true
    end
  end
end
