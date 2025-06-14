defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindowClear do
  @moduledoc """
  LearnOpenGL 1.2 - Hello Window Clear

  This example demonstrates setting a custom clear color for the OpenGL framebuffer.
  It builds upon the 1.1 Hello Window example by showing how to control the background color.

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example introduces the concept of:
  - `glClearColor()` - setting the clear color state
  - `glClear(GL_COLOR_BUFFER_BIT)` - actually clearing the buffer

  EAGL's Window framework automatically handles clearing for clean state, but this example
  demonstrates the pedagogical concepts by:
  - Explicitly calling `glClearColor()` to set a custom color
  - Showing the difference between state-setting and state-using functions
  - Explaining the OpenGL state machine concept

  ## Original Tutorial Concepts Demonstrated

  1. **OpenGL State Machine**: `glClearColor` sets state, `glClear` uses that state
  2. **Color Buffer Clearing**: Essential for preventing visual artifacts
  3. **RGBA Color Values**: Understanding the 0.0-1.0 range for color components
  4. **Render Loop Integration**: Where clearing fits in the rendering pipeline

  ## Key Learning Points

  - Understanding OpenGL's state-setting vs state-using functions
  - The importance of clearing buffers each frame
  - How color values work in OpenGL (0.0-1.0 range)
  - The difference between this and 1.1 (black vs colored background)

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindowClear.run_example()

  Press ESC to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise

  def run_example do
    EAGL.Window.run(__MODULE__, "LearnOpenGL 1.2 - Hello Window Clear")
  end

  @impl true
  def setup do
    # This example builds on 1.1 Hello Window by demonstrating how to set
    # a custom clear color. The key learning point is understanding the
    # difference between state-setting and state-using OpenGL functions.

    IO.puts("=== LearnOpenGL 1.2 - Hello Window Clear ===")
    IO.puts("This example demonstrates setting a custom clear color.")
    IO.puts("You should see a dark green-blue window!")
    IO.puts("")
    IO.puts("Key Concepts:")
    IO.puts("- glClearColor() is a STATE-SETTING function")
    IO.puts("- glClear() is a STATE-USING function")
    IO.puts("- This demonstrates OpenGL's state machine design")
    IO.puts("")
    IO.puts("Difference from 1.1:")
    IO.puts("- 1.1 Hello Window: Black background (0.0, 0.0, 0.0)")
    IO.puts("- 1.2 Hello Window Clear: Custom color (0.2, 0.3, 0.3)")
    IO.puts("")
    IO.puts("Press ESC to exit.")

    {:ok, %{}}
  end

  @impl true
  def render(_width, _height, state) do
    # This is the core of the 1.2 tutorial: demonstrating glClearColor
    #
    # In the original C++ tutorial, this example shows:
    # 1. glClearColor(0.2f, 0.3f, 0.3f, 1.0f) - sets the clear color STATE
    # 2. glClear(GL_COLOR_BUFFER_BIT) - USES that state to clear the buffer
    #
    # This demonstrates OpenGL's state machine design:
    # - State-setting functions configure how operations will work
    # - State-using functions perform operations using current state
    #
    # The color (0.2, 0.3, 0.3, 1.0) creates a dark green-blue background
    # - Red: 0.2 (20% intensity)
    # - Green: 0.3 (30% intensity)
    # - Blue: 0.3 (30% intensity)
    # - Alpha: 1.0 (fully opaque)

    # STATE-SETTING: Configure what color to use when clearing
    :gl.clearColor(0.2, 0.3, 0.3, 1.0)

    # STATE-USING: Actually clear the buffer using the color we just set
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # Educational note: In a real application, you'd typically set the clear
    # color once during setup and only call glClear in the render loop.
    # We call both here to demonstrate the concept clearly.

    state
  end

  @impl true
  def cleanup(_state) do
    IO.puts("Hello Window Clear example finished.")
    IO.puts("")
    IO.puts("Next: Try the triangle examples to see actual geometry rendering!")
    :ok
  end

  @impl true
  def handle_event({:key, key_code}, state) do
    case key_code do
      # ESC key - exit the example
      27 -> throw(:close_window)
      _ -> {:ok, state}
    end
  end
end
