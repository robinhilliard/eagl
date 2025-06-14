defmodule Mix.Tasks.Eagl.Test do
  @moduledoc """
  Runs EAGL tests excluding interactive examples that require user input.

  This prevents tests from hanging while waiting for ESC key presses.

  ## Examples

      mix eagl.test
      mix eagl.test --verbose
  """

  use Mix.Task

  @shortdoc "Run EAGL tests excluding interactive examples"

  def run(args) do
    # Ensure we're in test environment
    Mix.env(:test)

    # Add --exclude interactive to the arguments
    test_args = ["test/eagl/", "--exclude", "interactive"] ++ args

    Mix.shell().info("🧪 Running EAGL tests (excluding interactive examples)")
    Mix.shell().info("📝 Interactive examples can be run with: ./priv/scripts/run_examples")
    Mix.shell().info("")

    # Run the test task with our arguments
    Mix.Task.run("test", test_args)
  end
end
