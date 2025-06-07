defmodule EAGL.Window do
  @moduledoc """
  Utility module for OpenGL window management.
  Handles window creation, OpenGL context setup, and event loop management.
  """

  use EAGL.Const
  use WX.Const
  import Bitwise

  @default_window_size {1024, 768}

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

      # Create OpenGL context attributes
      attrib = [
        {:attribList, [@wx_gl_rgba, @wx_gl_doublebuffer, 0]}
      ]

      # Create OpenGL canvas
      gl_canvas = :wxGLCanvas.new(frame, attrib)

      # Set up event handlers
      :wxFrame.connect(frame, :size)
      :wxFrame.connect(frame, :close_window)
      :wxGLCanvas.connect(gl_canvas, :paint)

      # Create a sizer and add the canvas to it
      sizer = :wxBoxSizer.new(@wx_vertical)
      :wxSizer.add(sizer, gl_canvas, proportion: 1, flag: @wx_expand)
      :wxFrame.setSizer(frame, sizer)

      # Set minimum size for the canvas
      :wxWindow.setMinSize(gl_canvas, {100, 100})

      # Force initial layout
      :wxWindow.layout(frame)
      :wxWindow.update(frame)

      # Show frame and ensure it's ready
      :wxFrame.show(frame)
      :timer.sleep(10)  # Give the window system time to create the window

      # Create OpenGL context
      gl_context = :wxGLContext.new(gl_canvas)
      :wxGLCanvas.setCurrent(gl_canvas, gl_context)

      # Get initial size
      {width, height} = :wxWindow.getSize(gl_canvas)

      # Initialize OpenGL
      :gl.viewport(0, 0, width, height)
      :gl.clearColor(0.0, 0.0, 0.0, 1.0)
      :gl.clear(@gl_color_buffer_bit)

      # Set up shaders using callback module
      case callback_module.setup() do
        {:ok, state} ->
          # Initial refresh to trigger paint
          :wxWindow.refresh(gl_canvas)
          :wxWindow.update(gl_canvas)

          # Main loop
          main_loop(frame, gl_canvas, gl_context, callback_module, state)

          # Stop wx application
          :application.stop(:wx)
          :ok

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        IO.puts("Error: #{inspect(e)}")
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

          # Ensure canvas fills the frame
          if canvas_width != frame_width or canvas_height != frame_height do
            :wxWindow.setSize(gl_canvas, {frame_width, frame_height})
            :wxWindow.getSize(gl_canvas)
          end

          :gl.viewport(0, 0, canvas_width, canvas_height)
          :gl.clearColor(0.0, 0.0, 0.0, 1.0)
          :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)
          :wxGLCanvas.swapBuffers(gl_canvas)  # Force a buffer swap after clear
          callback_module.render(canvas_width * 1.0, canvas_height * 1.0, state)
          :wxGLCanvas.swapBuffers(gl_canvas)
        end
        main_loop(frame, gl_canvas, gl_context, callback_module, state)

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
        :gl.viewport(0, 0, width, height)
        :gl.clearColor(0.0, 0.0, 0.0, 1.0)
        :gl.clear(@gl_color_buffer_bit)
        :wxGLCanvas.swapBuffers(gl_canvas)  # Force a buffer swap after clear
        callback_module.render(width * 1.0, height * 1.0, state)
        :wxGLCanvas.swapBuffers(gl_canvas)
        main_loop(frame, gl_canvas, gl_context, callback_module, state)

      _ ->
        main_loop(frame, gl_canvas, gl_context, callback_module, state)
    end
  end
end
