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
      # OpenGL context attributes (verified values from wxWidgets docs)
      @wx_gl_rgba 1  # WX_GL_RGBA
      @wx_gl_buffer_size 2  # WX_GL_BUFFER_SIZE
      @wx_gl_level 3  # WX_GL_LEVEL
      @wx_gl_doublebuffer 4  # WX_GL_DOUBLEBUFFER
      @wx_gl_stereo 5  # WX_GL_STEREO
      @wx_gl_aux_buffers 6  # WX_GL_AUX_BUFFERS
      @wx_gl_min_red 7  # WX_GL_MIN_RED
      @wx_gl_min_green 8  # WX_GL_MIN_GREEN
      @wx_gl_min_blue 9  # WX_GL_MIN_BLUE
      @wx_gl_min_alpha 10  # WX_GL_MIN_ALPHA
      @wx_gl_depth_size 11  # WX_GL_DEPTH_SIZE
      @wx_gl_stencil_size 12  # WX_GL_STENCIL_SIZE
      @wx_gl_min_accum_red 13  # WX_GL_MIN_ACCUM_RED
      @wx_gl_min_accum_green 14  # WX_GL_MIN_ACCUM_GREEN
      @wx_gl_min_accum_blue 15  # WX_GL_MIN_ACCUM_BLUE
      @wx_gl_min_accum_alpha 16  # WX_GL_MIN_ACCUM_ALPHA
      @wx_gl_sample_buffers 17  # WX_GL_SAMPLE_BUFFERS
      @wx_gl_samples 18  # WX_GL_SAMPLES

      # Layout directions
      @wx_vertical 8  # wxVERTICAL
      @wx_horizontal 4  # wxHORIZONTAL

      # Sizer flags
      @wx_expand 2  # wxEXPAND
    end
  end
end
