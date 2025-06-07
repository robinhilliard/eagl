defmodule WX.Const do
  @moduledoc """
  Constants for wxWidgets.
  Use this module to inject wxWidgets constants as module attributes.

  ## Usage

      defmodule MyModule do
        use WX.Const

        # Now you can use @wx_gl_rgba, @wx_vertical, etc.
      end
  """

  defmacro __using__(_opts) do
    quote do
      # OpenGL context attributes
      @wx_gl_rgba 1  # WX_GL_RGBA
      @wx_gl_doublebuffer 2  # WX_GL_DOUBLEBUFFER

      # Layout directions
      @wx_vertical 8  # wxVERTICAL
      @wx_horizontal 4  # wxHORIZONTAL

      # Sizer flags
      @wx_expand 2  # wxEXPAND
    end
  end
end
