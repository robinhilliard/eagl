defmodule EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindow do
  @moduledoc """
  LearnOpenGL 1.1 - Hello Window

  This example demonstrates basic window creation and OpenGL context setup.
  It corresponds to the first rendering example in the LearnOpenGL tutorial series.

  ## Original C++ Source

  This example is based on the original LearnOpenGL C++ tutorial:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/src/1.getting_started/1.1.hello_window>

  ## Framework Adaptation Notes

  In the original LearnOpenGL C++ tutorial, this example shows a completely black window
  because no clearing is performed in the render loop. However, EAGL's Window framework
  automatically handles basic OpenGL setup including an initial clear for clean state.

  To maintain the pedagogical value while working within EAGL's design:
  - We set the clear color to black (0.0, 0.0, 0.0) to match the original example
  - The framework handles the actual clearing, but we demonstrate the concept
  - Comments explain what would happen without framework assistance

  ## Original Tutorial Concepts Demonstrated

  1. **Window Creation**: EAGL.Window handles GLFW setup and OpenGL context creation
  2. **Render Loop**: The framework manages the main loop and buffer swapping
  3. **Basic Rendering**: Shows the foundation for all subsequent examples
  4. **Input Handling**: ESC key to exit (handled by framework)

  ## Key Learning Points

  - Understanding the render loop concept
  - OpenGL context and window management
  - The importance of clearing buffers
  - Foundation for more complex rendering

  ## Usage

      EAGL.Examples.LearnOpenGL.GettingStarted.HelloWindow.run_example()

  Press ESC to exit the example.
  """

  use EAGL.Window
  use EAGL.Const

  import Bitwise

  def run_example do
    EAGL.Window.run(__MODULE__, "LearnOpenGL 1.1 - Hello Window", esc_to_exit: true)
  end

  @impl true
  def setup do
    # In the original LearnOpenGL tutorial, this example doesn't perform any
    # OpenGL rendering setup - it just creates a window and shows a black screen.
    #
    # The EAGL framework handles:
    # - OpenGL context creation
    # - Viewport setup
    # - Basic state initialization
    # - Depth testing setup
    #
    # This matches what GLFW + GLAD would do in the C++ version, but with
    # sensible defaults for a graphics framework.

    IO.puts("""
    === LearnOpenGL 1.1 - Hello Window ===
    This example demonstrates basic window creation.
    You should see a black window - this is correct!

    Framework Notes:
    - EAGL automatically handles OpenGL context setup
    - The black background comes from clearing with (0,0,0,1)
    - In raw OpenGL, you'd see undefined buffer contents without clearing

    Press ESC to exit.
    """)

    {:ok, %{}}
  end

  @impl true
  def render(_width, _height, state) do
    # In the original C++ tutorial, the render function for 1.1 Hello Window
    # contains NO rendering commands - just the render loop with glfwSwapBuffers
    # and glfwPollEvents. This results in a black window.
    #
    # EAGL's framework automatically:
    # 1. Clears the screen to ensure clean state (good practice)
    # 2. Sets clear color to black (0.0, 0.0, 0.0, 1.0) to match original
    # 3. Handles buffer swapping and event polling
    #
    # The pedagogical point is understanding that:
    # - Without clearing, you'd see random/undefined pixels
    # - The render loop is the foundation of real-time graphics
    # - This black window is the starting point for all OpenGL applications

    # Set clear color to black to match the original tutorial
    # (Framework will handle the actual clearing)
    :gl.clearColor(0.0, 0.0, 0.0, 1.0)
    :gl.clear(@gl_color_buffer_bit ||| @gl_depth_buffer_bit)

    # No other rendering - this example just shows a black window
    # Next tutorial (1.2) will demonstrate setting a custom clear color

    state
  end

  @impl true
  def cleanup(_state) do
    IO.puts("Hello Window example finished.")
    :ok
  end
end
