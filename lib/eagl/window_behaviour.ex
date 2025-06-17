defmodule EAGL.WindowBehaviour do
  @moduledoc """
  Behaviour for OpenGL window applications.

  Defines callbacks for OpenGL window lifecycle management with
  automatic context setup and event handling.

  ## Usage

      defmodule MyApp do
        use EAGL.Window

        @impl true
        def setup do
          # Initialize shaders, load models, etc.
          {:ok, initial_state}
        end

        @impl true
        def render(width, height, state) do
          # Clear and render your scene
          :gl.clearColor(0.2, 0.3, 0.3, 1.0)
          :gl.clear(@gl_color_buffer_bit)
          # ... render content
          :ok
        end

        @impl true
        def cleanup(state) do
          # Clean up resources
          :ok
        end
      end

      # Run the application
      EAGL.Window.run(MyApp, "My OpenGL App")
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
  @callback render(width :: float(), height :: float(), state :: any()) :: :ok

  @doc """
  Called when the window is being closed.
  Should clean up resources in state.
  """
  @callback cleanup(any()) :: :ok

  @doc """
  Called when an event occurs (keyboard, mouse, etc.).
  This callback is optional. If not implemented, events are ignored.
  Should return {:ok, new_state} to continue with updated state.

  Event types:
  - `{:key, key_code}` - Keyboard key press
  - `{:mouse_motion, x, y}` - Mouse movement (for camera look around)
  - `{:mouse_wheel, x, y, wheel_rotation, wheel_delta}` - Scroll wheel (for zoom)
  - `:tick` - Animation frame tick (60 FPS)
  """
  @callback handle_event(event :: any(), state :: any()) :: {:ok, any()}

  @optional_callbacks handle_event: 2
end
