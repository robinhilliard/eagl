defmodule GL.WindowBehaviour do
  @moduledoc """
  Behaviour for OpenGL window management.
  Handles window creation, OpenGL context setup, and event loop management.
  """

  @doc """
  Called when the OpenGL context is ready and shaders should be created.
  Should return {:ok, state} or {:error, reason}
  """
  @callback setup() :: {:ok, any()} | {:error, term()}

  @doc """
  Called when the window needs to be rendered.
  The OpenGL context is already current and the viewport is set.
  """
  @callback render(any()) :: :ok

  @doc """
  Called when the window is being closed.
  Should clean up resources in state.
  """
  @callback cleanup(any()) :: :ok
end
