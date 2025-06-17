defmodule Mix.Tasks.Eagl.Test do
  @moduledoc """
  Runs EAGL unit tests for quick development feedback.

  This focuses on unit tests without the slower example integration tests.

  ## Examples

      mix eagl.test
      mix eagl.test --verbose
  """

  use Mix.Task

  @shortdoc "Run EAGL unit tests for quick development feedback"

  def run(args) do
    # Ensure we're in test environment
    Mix.env(:test)

    # Run unit tests only
    test_args = ["test/eagl/"] ++ args

    Mix.shell().info("🧪 Running EAGL unit tests (quick development feedback)")
    Mix.shell().info("📝 For all tests including examples: mix test")
    Mix.shell().info("📝 For interactive examples: ./priv/scripts/run_examples")
    Mix.shell().info("")

    # Run the test task with our arguments
    Mix.Task.run("test", test_args)
  end
end
