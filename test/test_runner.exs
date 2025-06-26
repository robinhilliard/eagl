#!/usr/bin/env elixir

# Test Runner for GLTF Module Tests
# Allows running tests by priority levels and generates coverage reports

defmodule TestRunner do
  @moduledoc """
  Test runner for GLTF modules with priority-based execution.

  Usage:
    # Run all tests
    elixir test/test_runner.exs

    # Run only critical tests (high priority)
    elixir test/test_runner.exs --critical

    # Run only integration tests
    elixir test/test_runner.exs --integration

    # Run with coverage report
    elixir test/test_runner.exs --coverage

    # Run specific priority level
    elixir test/test_runner.exs --priority high
    elixir test/test_runner.exs --priority medium
    elixir test/test_runner.exs --priority low
  """

  def main(args \\ []) do
    {opts, _remaining_args, _invalid} =
      OptionParser.parse(args,
        switches: [
          critical: :boolean,
          integration: :boolean,
          coverage: :boolean,
          priority: :string,
          help: :boolean
        ],
        aliases: [h: :help, c: :coverage, i: :integration]
      )

    if opts[:help] do
      print_help()
    else
      run_tests(opts)
    end
  end

  defp print_help do
    IO.puts("""
    GLTF Test Runner

    Usage: elixir test/test_runner.exs [options]

    Options:
      --critical        Run only critical tests (GLB loader, data store, integration)
      --integration     Run only integration tests
      --priority LEVEL  Run tests of specific priority (high|medium|low)
      --coverage        Generate coverage report
      --help, -h        Show this help message

    Examples:
      elixir test/test_runner.exs                    # Run all tests
      elixir test/test_runner.exs --critical         # Critical tests only
      elixir test/test_runner.exs --priority high    # High priority tests
      elixir test/test_runner.exs --coverage         # All tests with coverage
    """)
  end

  defp run_tests(opts) do
    # Determine which tests to run
    test_files = select_test_files(opts)

    if Enum.empty?(test_files) do
      IO.puts("No tests selected to run.")
      exit({:shutdown, 1})
    end

    IO.puts("Running #{length(test_files)} test file(s)...")
    Enum.each(test_files, &IO.puts("  - #{&1}"))
    IO.puts("")

    # Build ExUnit command
    mix_cmd = build_mix_command(test_files, opts[:coverage] || false)

    # Run the tests
    {output, exit_status} =
      System.cmd("mix", mix_cmd,
        stderr_to_stdout: true,
        env: [{"MIX_ENV", "test"}]
      )

    IO.puts(output)

    if exit_status == 0 do
      IO.puts("\n✅ All tests passed!")

      if opts[:coverage] do
        print_coverage_summary()
      end
    else
      IO.puts("\n❌ Some tests failed!")
      exit({:shutdown, exit_status})
    end
  end

  defp select_test_files(opts) do
    all_test_files = %{
      # Critical priority (85-95% coverage recommended)
      critical: [
        "test/gltf_integration_test.exs",
        "test/gltf/glb_loader_test.exs",
        "test/gltf/data_store_test.exs"
      ],

      # High priority (60-80% coverage recommended)
      high: [
        "test/gltf/accessor_test.exs",
        "test/gltf/mesh_test.exs",
        "test/gltf/buffer_test.exs",
        "test/gltf/material_test.exs"
      ],

      # Medium priority (40-60% coverage recommended)
      medium: [
        "test/gltf/camera_test.exs",
        "test/gltf/animation_test.exs",
        "test/gltf/node_test.exs",
        "test/gltf/texture_test.exs",
        "test/gltf/image_test.exs"
      ],

      # Low priority (30-50% coverage recommended)
      low: [
        "test/gltf/asset_test.exs",
        "test/gltf/scene_test.exs",
        "test/gltf/buffer_view_test.exs",
        "test/gltf/sampler_test.exs",
        "test/gltf/skin_test.exs"
      ]
    }

    cond do
      opts[:critical] ->
        all_test_files[:critical]

      opts[:integration] ->
        ["test/gltf_integration_test.exs"]

      opts[:priority] == "high" ->
        all_test_files[:critical] ++ all_test_files[:high]

      opts[:priority] == "medium" ->
        all_test_files[:medium]

      opts[:priority] == "low" ->
        all_test_files[:low]

      opts[:priority] == "critical" ->
        all_test_files[:critical]

      true ->
        # Run all existing test files
        all_test_files
        |> Map.values()
        |> List.flatten()
        |> Enum.filter(&File.exists?/1)
    end
    |> Enum.filter(&File.exists?/1)
  end

  defp build_mix_command(test_files, with_coverage) do
    base_cmd = ["test"]

    coverage_opts =
      if with_coverage do
        ["--cover"]
      else
        []
      end

    # Add test files
    file_opts = test_files

    base_cmd ++ coverage_opts ++ file_opts
  end

  defp print_coverage_summary do
    IO.puts("""

    📊 Test Coverage Summary
    ========================

    Priority Recommendations:

    🔴 Critical (85-95%):  GLB Loader, Data Store, Integration Tests
       - These modules handle file I/O and binary parsing
       - Failures here break the entire loading pipeline

    🟡 High (60-80%):     Accessor, Mesh, Buffer, Material
       - Core data structures with validation logic
       - Complex parsing and transformation logic

    🟢 Medium (40-60%):   Camera, Animation, Node, Texture, Image
       - Important but less complex modules
       - Some validation but mostly data containers

    🔵 Low (30-50%):      Asset, Scene, BufferView, Sampler, Skin
       - Simple data containers
       - Minimal validation logic

    To generate detailed coverage reports:
      mix test --cover
      open cover/excoveralls.html
    """)
  end
end

# Run if called directly
if System.argv() |> length() >= 0 do
  TestRunner.main(System.argv())
end
