defmodule EAGL.Examples.Test do
  use ExUnit.Case, async: false

  test "math example" do
    EAGL.Examples.Math.run_example()
    assert true
  end

  @tag :interactive
  @tag timeout: 10000
  test "teapot example" do
    if System.get_env("CI") do
      # Skip interactive examples in CI - they would hang waiting for user input
      IO.puts("Skipping interactive teapot example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.Teapot.run_example()
      assert true
    end
  end

  # Add tests for LearnOpenGL examples with proper interactive tagging
  @tag :interactive
  @tag timeout: 10000
  test "hello triangle" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangle.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "hello triangle indexed" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleIndexed.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "hello triangle exercise 1" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise1.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "hello triangle exercise 2" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise2.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "hello triangle exercise 3" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloTriangleExercise3.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "shaders uniform" do
    if System.get_env("CI") do
      IO.puts("Skipping interactive LearnOpenGL example in CI environment")
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.ShadersUniform.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "1.1 Hello Window example" do
    if System.get_env("CI") do
      # Skip interactive tests in CI
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindow.run_example()
      assert true
    end
  end

  @tag :interactive
  @tag timeout: 10000
  test "1.2 Hello Window Clear example" do
    if System.get_env("CI") do
      # Skip interactive tests in CI
      assert true
    else
      # This test will timeout after 5 seconds, which is expected for interactive examples
      EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindowClear.run_example()
      assert true
    end
  end

  @tag :interactive
end
