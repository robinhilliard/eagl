defmodule EAGL.Window do
  @moduledoc """
  OpenGL window management and application lifecycle.

  Correct window creation with cross-platform OpenGL context setup
  and automated event handling based on wings_gl.erl patterns.

  ## Original Source

  Window creation timing, context setup, and event handling patterns are
  based on Wings3D's `wings_gl.erl` module:
  <https://github.com/dgud/wings/blob/master/src/wings_gl.erl>

  ## Usage

      defmodule MyApp do
        use EAGL.Window

        def run_example do
          # 2D rendering (default)
          EAGL.Window.run(__MODULE__, "My 2D App")

          # 3D rendering with depth testing
          EAGL.Window.run(__MODULE__, "My 3D App", depth_testing: true)

          # Custom size and tutorial mode
          EAGL.Window.run(__MODULE__, "Tutorial",
            size: {1280, 720},
            enter_to_exit: true
          )
        end

        @impl true
        def setup do
          # Initialize shaders, load models, set up state
          {:ok, initial_state}
        end

        @impl true
        def render(width, height, state) do
          # Clear screen and render content
          :gl.clearColor(0.2, 0.3, 0.3, 1.0)
          :gl.clear(@gl_color_buffer_bit)
          # ... render content
          :ok
        end

        @impl true
        def cleanup(state) do
          # Clean up OpenGL resources
          :ok
        end

        # Optional: Handle mouse events for camera control
        @impl true
        def handle_event({:mouse_motion, x, y}, state) do
          # Handle mouse movement for camera look around
          {:ok, updated_state}
        end

        @impl true
        def handle_event({:mouse_wheel, x, y, wheel_rotation, wheel_delta}, state) do
          # Handle scroll wheel for camera zoom
          {:ok, updated_state}
        end
      end
  """

  use EAGL.Const
  use WX.Const
  import Bitwise

  @default_window_size {1024, 768}
  # 60 FPS
  @tick_interval trunc(1000 / 60)

  # Private helper to get the physical framebuffer size for OpenGL viewport
  # On retina displays, logical size ≠ physical size, and OpenGL viewport needs physical size
  defp get_framebuffer_size(canvas) do
    {logical_width, logical_height} = :wxWindow.getSize(canvas)

    # Get content scale factor (1.0 on non-retina, 2.0 on retina, etc.)
    scale_factor =
      try do
        :wxWindow.getContentScaleFactor(canvas)
      rescue
        # Fallback for older wxWidgets versions that don't have getContentScaleFactor
        _ -> 1.0
      end

    # Calculate physical framebuffer size
    physical_width = round(logical_width * scale_factor)
    physical_height = round(logical_height * scale_factor)

    {physical_width, physical_height}
  end

  # OpenGL context attributes for wxGLCanvas.
  # Based on Wings3D's wings_gl.erl attributes/0 function.
  # Ensures proper OpenGL context with optional depth buffer, double buffering, and RGBA mode.
  defp gl_attributes(depth_testing) do
    base_attributes = [
      # Use RGBA mode
      @wx_gl_rgba,
      # Minimum 8 bits for red channel
      @wx_gl_min_red,
      8,
      # Minimum 8 bits for green channel
      @wx_gl_min_green,
      8,
      # Minimum 8 bits for blue channel
      @wx_gl_min_blue,
      8,
      # Double buffering for smooth animation
      @wx_gl_doublebuffer
    ]

    # Add depth buffer only if depth testing is requested
    depth_attributes =
      if depth_testing do
        # 24-bit depth buffer (for 3D rendering)
        [@wx_gl_depth_size, 24]
      else
        []
      end

    # Add macOS-specific forward compatibility and OpenGL 3.3 Core Profile
    # This is required for OpenGL 3.0+ contexts on macOS and matches the behaviour of:
    # #ifdef __APPLE__
    #     glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    #     glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    #     glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    #     glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    # #endif
    macos_attributes =
      case :os.type() do
        {:unix, :darwin} ->
          IO.puts(
            "Detected macOS: Adding forward compatibility and requesting OpenGL 3.3 Core Profile"
          )

          [
            @wx_gl_forward_compat,
            @wx_gl_major_version,
            3,
            @wx_gl_minor_version,
            3,
            @wx_gl_core_profile
          ]

        _ ->
          []
      end

    # Combine base attributes with depth and platform-specific ones and terminate
    [
      # 0 terminates attribute list
      attribList: base_attributes ++ depth_attributes ++ macos_attributes ++ [0]
    ]
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour EAGL.WindowBehaviour
    end
  end

  @doc """
  Creates and runs an OpenGL window using the given callback module.
  The callback module must implement the GLWindowBehaviour.

  Options:
  - size: {width, height} tuple, defaults to {1024, 768}. Sets the initial window size.
  - depth_testing: boolean, defaults to false. When true, enables depth testing and requests a depth buffer.
  - enter_to_exit: boolean, defaults to false. When true, pressing ENTER will automatically close the window.
  - timeout: integer, optional. If set, automatically exits after this many milliseconds for automated testing.
  """

  @spec run(module(), String.t()) :: :ok | {:error, term()}
  def run(callback_module, title) do
    run(callback_module, title, [])
  end

  @spec run(module(), String.t(), keyword()) :: :ok | {:error, term()}
  def run(callback_module, title, opts) when is_list(opts) do
    size = Keyword.get(opts, :size, @default_window_size)
    depth_testing = Keyword.get(opts, :depth_testing, false)
    enter_to_exit = Keyword.get(opts, :enter_to_exit, false)
    timeout = Keyword.get(opts, :timeout)

    try do
      # Initialize wx

      :application.start(:wx)

      wx = :wx.new()

      frame = :wxFrame.new(wx, -1, title, size: size)

      IO.puts("Creating OpenGL canvas")
      depth_msg = if depth_testing, do: "24-bit depth buffer, ", else: ""
      attrs = gl_attributes(depth_testing)
      IO.puts("Requested: RGBA mode, 8-bit RGB channels, #{depth_msg}double buffering")
      gl_canvas = :wxGLCanvas.new(frame, attrs)
      IO.puts("OpenGL canvas created successfully with requested attributes")

      # Set background style following wings_gl pattern
      :wxGLCanvas.setBackgroundStyle(gl_canvas, @wx_bg_style_paint)

      # Set up event handlers
      :wxFrame.connect(frame, :size)
      :wxFrame.connect(frame, :close_window)
      :wxGLCanvas.connect(gl_canvas, :paint)
      :wxFrame.connect(frame, :char_hook)

      # Mouse event handlers for camera control
      :wxFrame.connect(frame, :motion)
      :wxFrame.connect(frame, :mousewheel)
      # Also try connecting to canvas
      :wxGLCanvas.connect(gl_canvas, :motion)
      :wxGLCanvas.connect(gl_canvas, :mousewheel)

      # Create a sizer and add the canvas to it
      sizer = :wxBoxSizer.new(@wx_vertical)
      :wxSizer.add(sizer, gl_canvas, proportion: 1, flag: @wx_expand)
      :wxFrame.setSizer(frame, sizer)

      # Set minimum size for the canvas
      :wxWindow.setMinSize(gl_canvas, {100, 100})

      # Force initial layout
      :wxWindow.layout(frame)
      :wxWindow.update(frame)

      # Connect to show event and show frame (following wings_gl pattern)

      :wxWindow.connect(frame, :show)
      :wxFrame.show(frame)

      # Wait for show event with shorter timeout (Wings3D approach)
      # The show event may come before the window is actually displayed

      receive do
        {:wx, _, _, _, {:wxShow, :show}} ->
          :ok
      after
        1000 ->
          # If no show event after 1 second, continue anyway
          # This is more reliable than waiting indefinitely

          :ok
      end

      # Critical timing from wings_gl: let wxWidgets realize the window
      # "otherwise the setCurrent fails" - especially important on GTK
      # Always sleep regardless of whether we got the show event
      :timer.sleep(200)

      # Create OpenGL context AFTER window is shown and realized
      # This follows Wings3D pattern more closely

      gl_context = :wxGLContext.new(gl_canvas)

      # Set focus after window is shown and ensure keyboard events
      :wxWindow.setFocus(frame)
      :wxFrame.raise(frame)

      # Enable keyboard events
      :wxEvtHandler.connect(frame, :char_hook, [])

      # Make context current after proper timing and context creation
      # Add error handling for setCurrent following Wings3D pattern
      context_result =
        try do
          :wxGLCanvas.setCurrent(gl_canvas, gl_context)
          :ok
        rescue
          e ->
            {:error, {:context_error, e}}
        end

      case context_result do
        :ok ->
          # Verify OpenGL NIF is loaded by testing a basic GL call
          nif_test_result =
            try do
              # Test if GL NIFs are available with a basic call
              :gl.getError()
              :ok
            rescue
              e in [ErlangError] ->
                case e.original do
                  {:nif_not_loaded, _, _, _, _} ->
                    {:error,
                     {:nif_not_loaded,
                      "OpenGL NIFs are not loaded. This may be due to missing OpenGL drivers or incompatible wxWidgets/OTP versions."}}

                  _ ->
                    {:error, {:gl_error, e}}
                end

              e ->
                {:error, {:unexpected_error, e}}
            end

          case nif_test_result do
            :ok ->
              # Continue with initialization
              # Get physical framebuffer size for retina display support
              {width, height} = get_framebuffer_size(gl_canvas)
              safe_width = max(width, 1)
              safe_height = max(height, 1)

              # Initialize OpenGL with proper setup using physical framebuffer size
              :gl.viewport(0, 0, safe_width, safe_height)

              # Conditionally enable depth testing based on configuration
              if depth_testing do
                # Enable depth testing - Wings3D approach: trust the attributes we requested
                # Since we requested 24-bit depth buffer in canvas attributes, it should be available
                :gl.enable(@gl_depth_test)
                :gl.depthFunc(@gl_less)
                :gl.clearDepth(1.0)
              end

              # Initial clear to ensure clean state - examples will handle their own clearing
              :gl.clearColor(0.0, 0.0, 0.0, 1.0)

              clear_bits =
                if depth_testing do
                  @gl_color_buffer_bit ||| @gl_depth_buffer_bit
                else
                  @gl_color_buffer_bit
                end

              :gl.clear(clear_bits)

              # Check for OpenGL errors
              case :gl.getError() do
                # GL_NO_ERROR
                0 ->
                  :ok

                error ->
                  IO.puts("Warning: OpenGL error during initialization: #{error}")
              end

              # Set up shaders using callback module
              case callback_module.setup() do
                {:ok, state} ->
                  # Initial refresh to trigger paint
                  :wxWindow.refresh(gl_canvas)
                  :wxWindow.update(gl_canvas)

                  # Set up tick timer
                  :timer.send_interval(@tick_interval, self(), :tick)

                  # Main loop
                  try do
                    main_loop(
                      frame,
                      gl_canvas,
                      gl_context,
                      callback_module,
                      state,
                      enter_to_exit,
                      timeout,
                      :erlang.monotonic_time(:millisecond) / 1000.0
                    )
                  catch
                    :exit_main_loop -> :ok
                  end

                  # Cleanup - try to ensure context is current before cleanup
                  try do
                    :wxGLCanvas.setCurrent(gl_canvas, gl_context)
                    # Only try to unbind shader program if context is still valid
                    try do
                      # Unbind shader program
                      :gl.useProgram(0)
                    rescue
                      e in [ErlangError] ->
                        case e.original do
                          {:error, :no_gl_context, _} ->
                            # OpenGL context is already destroyed, that's OK during shutdown
                            :ok

                          _ ->
                            # Re-raise other errors
                            reraise e, __STACKTRACE__
                        end
                    end
                  rescue
                    _e ->
                      # wxGLCanvas context might already be destroyed during shutdown, that's OK
                      :ok
                  end

                  try do
                    callback_module.cleanup(state)
                  rescue
                    e in [ErlangError] ->
                      case e.original do
                        {:error, :no_gl_context, _} ->
                          # OpenGL context is already destroyed, that's OK during shutdown
                          # This happens when cleanup functions try to delete OpenGL resources
                          :ok

                        _ ->
                          IO.puts("Warning: Error during cleanup: #{inspect(e)}")
                      end

                    e ->
                      IO.puts("Warning: Error during cleanup: #{inspect(e)}")
                  end

                  :wxGLContext.destroy(gl_context)
                  :wxFrame.destroy(frame)
                  :application.stop(:wx)
                  :ok

                {:error, reason} ->
                  # Cleanup on setup failure
                  :wxGLContext.destroy(gl_context)
                  :wxFrame.destroy(frame)
                  :application.stop(:wx)
                  {:error, reason}
              end

            {:error, error_details} ->
              # Cleanup and return error for NIF loading failure
              :wxGLContext.destroy(gl_context)
              :wxFrame.destroy(frame)
              :application.stop(:wx)
              {:error, error_details}
          end

        {:error, {:context_error, e}} ->
          IO.puts("Error setting OpenGL context current: #{inspect(e)}")
          # Cleanup and exit gracefully
          :wxGLContext.destroy(gl_context)
          :wxFrame.destroy(frame)
          :application.stop(:wx)
          {:error, {:context_error, e}}
      end
    rescue
      e ->
        IO.puts("Error in window setup: #{inspect(e)}")
        # Ensure wx is stopped even on error
        try do
          :application.stop(:wx)
        rescue
          _ -> :ok
        end

        {:error, e}
    end
  end

  # Private helper to handle window cleanup consistently
  @spec cleanup_and_exit(
          :wxFrame.wxFrame(),
          :wxGLCanvas.wxGLCanvas(),
          :wxGLContext.wxGLContext(),
          module(),
          any()
        ) :: no_return()
  defp cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state) do
    # Try to ensure OpenGL context is current before cleanup, but don't fail if it's already invalid
    try do
      :wxGLCanvas.setCurrent(gl_canvas, gl_context)
      # Only try to unbind shader program if context is still valid
      try do
        # Unbind shader program
        :gl.useProgram(0)
      rescue
        e in [ErlangError] ->
          case e.original do
            {:error, :no_gl_context, _} ->
              # OpenGL context is already destroyed, that's OK during shutdown
              :ok

            _ ->
              # Re-raise other errors
              reraise e, __STACKTRACE__
          end
      end
    rescue
      _e ->
        # wxGLCanvas context might already be destroyed during shutdown, that's OK
        :ok
    end

    try do
      callback_module.cleanup(state)
    rescue
      e in [ErlangError] ->
        case e.original do
          {:error, :no_gl_context, _} ->
            # OpenGL context is already destroyed, that's OK during shutdown
            # This happens when cleanup functions try to delete OpenGL resources
            :ok

          _ ->
            IO.puts("Warning: Error during cleanup: #{inspect(e)}")
        end

      e ->
        IO.puts("Warning: Error during cleanup: #{inspect(e)}")
    end

    :wxGLContext.destroy(gl_context)
    :wxFrame.destroy(frame)
    throw(:exit_main_loop)
  end

  # Private helper to handle window cleanup for close event (returns :ok)
  @spec cleanup_and_close(
          :wxFrame.wxFrame(),
          :wxGLCanvas.wxGLCanvas(),
          :wxGLContext.wxGLContext(),
          module(),
          any()
        ) :: :ok
  defp cleanup_and_close(frame, gl_canvas, gl_context, callback_module, state) do
    # Try to ensure OpenGL context is current before cleanup, but don't fail if it's already invalid
    try do
      :wxGLCanvas.setCurrent(gl_canvas, gl_context)
      # Only try to unbind shader program if context is still valid
      try do
        # Unbind shader program
        :gl.useProgram(0)
      rescue
        e in [ErlangError] ->
          case e.original do
            {:error, :no_gl_context, _} ->
              # OpenGL context is already destroyed, that's OK during shutdown
              :ok

            _ ->
              # Re-raise other errors
              reraise e, __STACKTRACE__
          end
      end
    rescue
      _e ->
        # wxGLCanvas context might already be destroyed during shutdown, that's OK
        :ok
    end

    try do
      callback_module.cleanup(state)
    rescue
      e in [ErlangError] ->
        case e.original do
          {:error, :no_gl_context, _} ->
            # OpenGL context is already destroyed, that's OK during shutdown
            # This happens when cleanup functions try to delete OpenGL resources
            :ok

          _ ->
            IO.puts("Warning: Error during cleanup: #{inspect(e)}")
        end

      e ->
        IO.puts("Warning: Error during cleanup: #{inspect(e)}")
    end

    :wxGLContext.destroy(gl_context)
    :wxFrame.destroy(frame)
    :ok
  end

  @spec main_loop(
          :wxFrame.wxFrame(),
          :wxGLCanvas.wxGLCanvas(),
          :wxGLContext.wxGLContext(),
          module(),
          any(),
          boolean(),
          integer() | nil,
          float() | nil
        ) :: :ok
  defp main_loop(
         frame,
         gl_canvas,
         gl_context,
         callback_module,
         state,
         enter_to_exit,
         timeout,
         last_tick_time
       ) do
    receive do
      # Handle timeout for automated testing
      {:timeout_expired, timeout_ms} ->
        IO.puts("EAGL_TIMEOUT: Window timed out after #{timeout_ms}ms for automated testing")
        cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state)

      # Handle both frame and canvas size events
      {:wx, _, obj, _, {:wxSize, :size, {_width, _height}, _}} ->
        if obj == frame or obj == gl_canvas do
          # IO.puts("Resizing window #{width} x #{height}")
          :wxGLCanvas.setCurrent(gl_canvas, gl_context)

          # Get the actual canvas size after layout
          # Re-layout the frame to update sizer
          :wxWindow.layout(frame)
          # Force update after layout
          :wxWindow.update(frame)

          # Get both frame and canvas sizes for debugging
          {frame_width, frame_height} = :wxWindow.getSize(frame)
          {canvas_width, canvas_height} = :wxWindow.getSize(gl_canvas)

          # Ensure canvas fills the frame (only if sizes are valid)
          if canvas_width > 0 and canvas_height > 0 and frame_width > 0 and frame_height > 0 do
            if canvas_width != frame_width or canvas_height != frame_height do
              :wxWindow.setSize(gl_canvas, {frame_width, frame_height})
            end
          end

          # Get physical framebuffer size for retina display support
          {physical_width, physical_height} = get_framebuffer_size(gl_canvas)
          safe_width = max(physical_width, 1)
          safe_height = max(physical_height, 1)

          :gl.viewport(0, 0, safe_width, safe_height)
          # Pass physical framebuffer size to render function (for OpenGL operations)
          callback_module.render(physical_width * 1.0, physical_height * 1.0, state)
          :wxGLCanvas.swapBuffers(gl_canvas)
        end

        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          state,
          enter_to_exit,
          timeout,
          last_tick_time
        )

      {:wx, _, _, _, {:wxKey, :char_hook, _, _, key_code, _, _, _, _, _, _, _}} ->
        # Handle ENTER key if enter_to_exit is enabled
        # Check for both main ENTER (13/WXK_RETURN) and numeric keypad ENTER (370/WXK_NUMPAD_ENTER)
        if enter_to_exit and (key_code == 13 or key_code == 370) do
          cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state)
        end

        # Handle keyboard events
        new_state =
          if function_exported?(callback_module, :handle_event, 2) do
            try do
              case callback_module.handle_event({:key, key_code}, state) do
                {:ok, updated_state} -> updated_state
                _ -> state
              end
            rescue
              # Handle FunctionClauseError when key handler is not defined
              _e in [FunctionClauseError] ->
                state
            catch
              :close_window ->
                cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state)
            end
          else
            state
          end

        # Trigger a repaint after handling the event
        :wxWindow.refresh(gl_canvas)

        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          new_state,
          enter_to_exit,
          timeout,
          last_tick_time
        )

      # Handle mouse motion events for camera look around
      {:wx, _, _, _, {:wxMouse, :motion, x, y, _, _, _, _, _, _, _, _, _, _}} ->
        new_state =
          if function_exported?(callback_module, :handle_event, 2) do
            try do
              case callback_module.handle_event({:mouse_motion, x, y}, state) do
                {:ok, updated_state} -> updated_state
                _ -> state
              end
            rescue
              # Handle FunctionClauseError when mouse motion handler is not defined
              _e in [FunctionClauseError] ->
                state
            catch
              :close_window ->
                cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state)
            end
          else
            state
          end

        # Trigger a repaint after handling the event
        :wxWindow.refresh(gl_canvas)

        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          new_state,
          enter_to_exit,
          timeout,
          last_tick_time
        )

      # Handle scroll wheel events for camera zoom
      {:wx, _, _, _,
       {:wxMouse, :mousewheel, x, y, _, _, _, _, _, _, _, wheel_rotation, wheel_delta, _}} ->
        new_state =
          if function_exported?(callback_module, :handle_event, 2) do
            try do
              case callback_module.handle_event(
                     {:mouse_wheel, x, y, wheel_rotation, wheel_delta},
                     state
                   ) do
                {:ok, updated_state} -> updated_state
                _ -> state
              end
            rescue
              # Handle FunctionClauseError when mouse wheel handler is not defined
              _e in [FunctionClauseError] ->
                state
            catch
              :close_window ->
                cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state)
            end
          else
            state
          end

        # Trigger a repaint after handling the event
        :wxWindow.refresh(gl_canvas)

        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          new_state,
          enter_to_exit,
          timeout,
          last_tick_time
        )

      {:wx, _, _, _, {:wxClose, :close_window}} ->
        cleanup_and_close(frame, gl_canvas, gl_context, callback_module, state)

      {:wx, _, _, _, {:wxPaint, :paint}} ->
        # Start timeout timer on first render if timeout is set
        if timeout != nil do
          :timer.send_after(timeout, {:timeout_expired, timeout})
        end

        :wxGLCanvas.setCurrent(gl_canvas, gl_context)
        # Get physical framebuffer size for OpenGL viewport and render callback (retina support)
        {physical_width, physical_height} = get_framebuffer_size(gl_canvas)

        # Ensure dimensions are positive
        safe_physical_width = max(physical_width, 1)
        safe_physical_height = max(physical_height, 1)

        # Set OpenGL viewport to physical framebuffer size
        :gl.viewport(0, 0, safe_physical_width, safe_physical_height)
        # Pass physical framebuffer size to render function for all OpenGL operations
        callback_module.render(safe_physical_width * 1.0, safe_physical_height * 1.0, state)
        :wxGLCanvas.swapBuffers(gl_canvas)
        # Set timeout to nil after first render to prevent multiple timers
        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          state,
          enter_to_exit,
          nil,
          last_tick_time
        )

      :tick ->
        tick_time = :erlang.monotonic_time(:millisecond) / 1000.0
        time_delta = if last_tick_time != nil, do: tick_time - last_tick_time, else: 0.0

        new_state =
          if function_exported?(callback_module, :handle_event, 2) do
            try do
              case callback_module.handle_event({:tick, time_delta}, state) do
                {:ok, updated_state} ->
                  self() |> send({:wx, :ignore, :ignore, :ignore, {:wxPaint, :paint}})
                  updated_state

                _ ->
                  state
              end
            rescue
              # Handle FunctionClauseError when :tick handler is not defined
              _e in [FunctionClauseError] ->
                self() |> send({:wx, :ignore, :ignore, :ignore, {:wxPaint, :paint}})
                state
            catch
              :close_window ->
                cleanup_and_exit(frame, gl_canvas, gl_context, callback_module, state)
            end
          else
            self() |> send({:wx, :ignore, :ignore, :ignore, {:wxPaint, :paint}})
            state
          end

        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          new_state,
          enter_to_exit,
          timeout,
          tick_time
        )

      other ->
        # Only debug non-tick, non-show, and non-mouse events to avoid spam
        case other do
          :tick -> :ok
          {:wx, _, _, _, {:wxShow, :show, _}} -> :ok
          {:wx, _, _, _, {:wxMouse, _, _, _, _, _, _, _, _, _, _, _, _, _}} -> :ok
          _ -> IO.puts("DEBUG: Unhandled event: #{inspect(other)}")
        end

        main_loop(
          frame,
          gl_canvas,
          gl_context,
          callback_module,
          state,
          enter_to_exit,
          timeout,
          last_tick_time
        )
    end
  end
end
