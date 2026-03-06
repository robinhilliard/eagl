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
  May return `:ok` or `{:ok, new_state}` to pass updated state to the next frame.
  """
  @callback render(width :: float(), height :: float(), state :: any()) :: :ok | {:ok, any()}

  @doc """
  Optional. Called when the window needs to be rendered, with frame timing.
  If implemented, this is called instead of `render/3` when timing is available (tick loop).

  `timing` contains:
  - `delta_time` - seconds since last frame
  - `elapsed_time` - seconds since start
  - `tick_alpha` - interpolation factor (0.0-1.0) between the last two ECSx ticks.
    Set via `Process.put(:eagl_last_ecs_tick, {timestamp, interval})` when a game
    tick occurs. Defaults to 1.0 when no ECSx tick data is available.
  """
  @callback render(width :: float(), height :: float(), state :: any(), timing :: map()) ::
              :ok | {:ok, any()}

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
  - `{:tick, time_delta}` - Per-frame update (adaptive rate, up to 60 FPS). `time_delta` is seconds since last tick.
  - `{:key, key_code}` - Keyboard key press
  - `{:mouse_motion, x, y}` - Mouse movement
  - `{:mouse_down, x, y}` - Left mouse button press
  - `{:mouse_up, x, y}` - Left mouse button release
  - `{:middle_down, x, y}` - Middle mouse button press
  - `{:middle_up, x, y}` - Middle mouse button release
  - `{:mouse_wheel, x, y, wheel_rotation, wheel_delta}` - Scroll wheel
  - `{:wx_event, event_data}` - Raw wx event not handled by EAGL (e.g. wxTreeCtrl selections)
  """
  @callback handle_event(event :: any(), state :: any()) :: {:ok, any()}

  @doc """
  Optional. Called during window creation to set up the frame layout.

  Receives the wxFrame and wxGLCanvas. Must return a wxSizer that has been
  populated with the gl_canvas (and any additional panels). The sizer will
  be set on the frame via `:wxFrame.setSizer/2`.

  If not implemented, a default vertical sizer is created with the GL canvas
  filling the entire frame.
  """
  @callback setup_layout(
              frame :: :wxFrame.wxFrame(),
              gl_canvas :: :wxGLCanvas.wxGLCanvas()
            ) :: :wxSizer.wxSizer()

  @optional_callbacks [handle_event: 2, render: 4, setup_layout: 2]
end
