defmodule EAGL.Window do
  @moduledoc """
  Utility module for OpenGL window management.
  Handles window creation, OpenGL context setup, and event loop management.
  """

  use EAGL.Const
  use WX.Const
  import Bitwise

  @default_window_size {1024, 768}
  @tick_interval trunc(1000 / 60) # 60 FPS

  # OpenGL context attributes for wxGLCanvas.
  # Based on Wings3D's wings_gl.erl attributes/0 function.
  # Ensures proper OpenGL context with depth buffer, double buffering, and RGBA mode.
  defp gl_attributes do
    # Wings3D format: return a proplist with attribList key
    [
      attribList: [
        @wx_gl_rgba,                    # Use RGBA mode
        @wx_gl_min_red, 8,             # Minimum 8 bits for red channel
        @wx_gl_min_green, 8,           # Minimum 8 bits for green channel
        @wx_gl_min_blue, 8,            # Minimum 8 bits for blue channel
        @wx_gl_depth_size, 24,         # 24-bit depth buffer (critical for 3D)
        @wx_gl_doublebuffer,           # Double buffering for smooth animation
        0                              # Terminate attribute list
      ]
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
  """

  @spec run(module(), String.t()) :: :ok | {:error, term()}
  def run(callback_module, title) do
    run(callback_module, title, @default_window_size)
  end

  @spec run(module(), String.t(), {integer(), integer()}) :: :ok | {:error, term()}
  def run(callback_module, title, size) do
    try do
      # Initialize wx
      :application.start(:wx)
      wx = :wx.new()
      frame = :wxFrame.new(wx, -1, title, size: size)

      IO.puts("Creating OpenGL canvas")
      IO.puts("Requested: RGBA mode, 8-bit RGB channels, 24-bit depth buffer, double buffering")
      gl_canvas = :wxGLCanvas.new(frame, gl_attributes())
      IO.puts("✓ OpenGL canvas created successfully with requested attributes")

      # Set background style following wings_gl pattern
      :wxGLCanvas.setBackgroundStyle(gl_canvas, 2)  # wxBG_STYLE_PAINT

      # Set up event handlers
      :wxFrame.connect(frame, :size)
      :wxFrame.connect(frame, :close_window)
      :wxGLCanvas.connect(gl_canvas, :paint)
      :wxFrame.connect(frame, :char_hook)

      # Create a sizer and add the canvas to it
      sizer = :wxBoxSizer.new(@wx_vertical)
      :wxSizer.add(sizer, gl_canvas, proportion: 1, flag: @wx_expand)
      :wxFrame.setSizer(frame, sizer)

      # Set minimum size for the canvas
      :wxWindow.setMinSize(gl_canvas, {100, 100})

      # Force initial layout
      :wxWindow.layout(frame)
      :wxWindow.update(frame)

      # Create OpenGL context
      gl_context = :wxGLContext.new(gl_canvas)

      # Connect to show event and show frame (following wings_gl pattern)
      :wxWindow.connect(frame, :show)
      :wxFrame.show(frame)

      # Wait for show event (critical for proper initialization)
      receive do
        {:wx, _, _, _, {:wxShow, :show}} -> :ok
      after
        5000 ->
          IO.puts("Warning: Show event timeout")
          :ok
      end

      # Critical timing from wings_gl: let wxWidgets realize the window
      # "otherwise the setCurrent fails" - especially important on GTK
      :timer.sleep(200)

      # Set focus after window is shown and ensure keyboard events
      :wxWindow.setFocus(frame)
      :wxFrame.raise(frame)

      # Enable keyboard events
      :wxEvtHandler.connect(frame, :char_hook, [])

      # Make context current after proper timing
      :wxGLCanvas.setCurrent(gl_canvas, gl_context)

      # Get initial size and validate
      {width, height} = :wxWindow.getSize(gl_canvas)
      safe_width = max(width, 1)
      safe_height = max(height, 1)

      # Initialize OpenGL with proper setup
      :gl.viewport(0, 0, safe_width, safe_height)
      :gl.clearColor(0.0, 0.0, 0.0, 1.0)

      # Check depth buffer availability - should now have 24-bit depth buffer
      depth_bits = try do
        case :gl.getIntegerv(@gl_depth_bits) do
          [bits] when bits > 0 ->
            IO.puts("✓ OpenGL initialized with #{bits}-bit depth buffer (requested 24-bit)")
            if bits >= 24 do
              IO.puts("✓ Depth buffer meets or exceeds requirements")
            else
              IO.puts("⚠ Depth buffer is smaller than requested, but should still work")
            end
            bits
          _ ->
            IO.puts("✗ Warning: No depth buffer available despite requesting 24-bit")
            0
        end
      rescue
        e ->
          IO.puts("✗ Warning: Could not query depth buffer: #{Exception.message(e)}")
          0
      end

      # Enable depth testing if available
      if depth_bits > 0 do
        :gl.enable(@gl_depth_test)
        :gl.depthFunc(@gl_less)
        :gl.clearDepth(1.0)
        :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
      else
        :gl.clear(@gl_color_buffer_bit)
      end

      # Check for OpenGL errors
      case :gl.getError() do
        0 -> :ok  # GL_NO_ERROR
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
            main_loop(frame, gl_canvas, gl_context, callback_module, state)
          catch
            :exit_main_loop -> :ok
          end

          # Cleanup
          try do
            callback_module.cleanup(state)
          rescue
            _ -> :ok
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

  @spec main_loop(:wxFrame.wxFrame(), :wxGLCanvas.wxGLCanvas(), :wxGLContext.wxGLContext(), module(), any()) :: :ok
  defp main_loop(frame, gl_canvas, gl_context, callback_module, state) do
    receive do
      # Handle both frame and canvas size events
      {:wx, _, obj, _, {:wxSize, :size, {_width, _height}, _}} ->
        if obj == frame or obj == gl_canvas do
          #IO.puts("Resizing window #{width} x #{height}")
          :wxGLCanvas.setCurrent(gl_canvas, gl_context)

          # Get the actual canvas size after layout
          :wxWindow.layout(frame)  # Re-layout the frame to update sizer
          :wxWindow.update(frame)  # Force update after layout

          # Get both frame and canvas sizes for debugging
          {frame_width, frame_height} = :wxWindow.getSize(frame)
          {canvas_width, canvas_height} = :wxWindow.getSize(gl_canvas)

          # Ensure canvas fills the frame (only if sizes are valid)
          {final_width, final_height} = if canvas_width > 0 and canvas_height > 0 and frame_width > 0 and frame_height > 0 do
            if canvas_width != frame_width or canvas_height != frame_height do
              :wxWindow.setSize(gl_canvas, {frame_width, frame_height})
              # Use the frame size for rendering after resize
              {frame_width, frame_height}
            else
              {canvas_width, canvas_height}
            end
          else
            # Fallback to reasonable defaults if dimensions are invalid
            {max(canvas_width, 1), max(canvas_height, 1)}
          end

          # Ensure viewport dimensions are positive
          safe_width = max(final_width, 1)
          safe_height = max(final_height, 1)

          :gl.viewport(0, 0, safe_width, safe_height)
          :gl.clearColor(0.0, 0.0, 0.0, 1.0)
          :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
          callback_module.render(safe_width * 1.0, safe_height * 1.0, state)
          :wxGLCanvas.swapBuffers(gl_canvas)
        end
        main_loop(frame, gl_canvas, gl_context, callback_module, state)

      {:wx, _, _, _, {:wxKey, :char_hook, _, _, key_code, _, _, _, _, _, _, _}} ->
        # Handle keyboard events
        IO.puts("Key pressed: #{key_code}")
        new_state = if function_exported?(callback_module, :handle_event, 2) do
          try do
            case callback_module.handle_event({:key, key_code}, state) do
              {:ok, updated_state} -> updated_state
              _ -> state
            end
          catch
            :close_window ->
              # Clean up and exit
              :gl.useProgram(0)
              callback_module.cleanup(state)
              :wxGLContext.destroy(gl_context)
              :wxFrame.destroy(frame)
              throw(:exit_main_loop)
          end
        else
          state
        end

        # Trigger a repaint after handling the event
        :wxWindow.refresh(gl_canvas)
        main_loop(frame, gl_canvas, gl_context, callback_module, new_state)

      {:wx, _, _, _, {:wxClose, :close_window}} ->
        # Clean up OpenGL resources before destroying context
        :gl.useProgram(0)  # Unbind shader program
        callback_module.cleanup(state)
        :wxGLContext.destroy(gl_context)
        :wxFrame.destroy(frame)
        :ok

      {:wx, _, _, _, {:wxPaint, :paint}} ->
        :wxGLCanvas.setCurrent(gl_canvas, gl_context)
        {width, height} = :wxWindow.getSize(gl_canvas)

        # Ensure dimensions are positive
        safe_width = max(width, 1)
        safe_height = max(height, 1)

        :gl.viewport(0, 0, safe_width, safe_height)
        :gl.clearColor(0.0, 0.0, 0.0, 1.0)
        :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
        callback_module.render(safe_width * 1.0, safe_height * 1.0, state)
        :wxGLCanvas.swapBuffers(gl_canvas)
        main_loop(frame, gl_canvas, gl_context, callback_module, state)

      :tick ->
        new_state = if function_exported?(callback_module, :handle_event, 2) do
          try do
            case callback_module.handle_event(:tick, state) do
              {:ok, updated_state} ->
                self() |> send({:wx, :ignore, :ignore, :ignore, {:wxPaint, :paint}})
                updated_state
              _ -> state
            end
          catch
            :close_window ->
              # Clean up and exit
              :gl.useProgram(0)
              callback_module.cleanup(state)
              :wxGLContext.destroy(gl_context)
              :wxFrame.destroy(frame)
              throw(:exit_main_loop)
          end
        else
          state
        end
        main_loop(frame, gl_canvas, gl_context, callback_module, new_state)

      _ ->
        main_loop(frame, gl_canvas, gl_context, callback_module, state)
    end
  end
end
