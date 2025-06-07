defmodule GL.Const do
  @moduledoc """
  Constants for OpenGL.
  Use this module to inject OpenGL constants as module attributes.

  ## Usage

      defmodule MyModule do
        use GL.Const

        # Now you can use @gl_vertex_shader, @gl_triangles, etc.
      end
  """

  defmacro __using__(_opts) do
    quote do
      # Shader types
      @gl_vertex_shader 35633  # GL_VERTEX_SHADER
      @gl_fragment_shader 35632  # GL_FRAGMENT_SHADER

      # Shader compilation/linking
      @gl_compile_status 35713  # GL_COMPILE_STATUS
      @gl_link_status 35714  # GL_LINK_STATUS
      @gl_info_log_length 35716  # GL_INFO_LOG_LENGTH

      # Buffer bits
      @gl_color_buffer_bit 16384  # GL_COLOR_BUFFER_BIT
      @gl_depth_buffer_bit 256  # GL_DEPTH_BUFFER_BIT

      # OpenGL capabilities
      @gl_depth_test 2929  # GL_DEPTH_TEST
      @gl_cull_face 2884  # GL_CULL_FACE
      @gl_front_and_back 1032  # GL_FRONT_AND_BACK
      @gl_fill 6914  # GL_FILL

      # Drawing primitives
      @gl_triangles 4  # GL_TRIANGLES
      @gl_points 0  # GL_POINTS

      # OpenGL info
      @gl_version 7938  # GL_VERSION
      @gl_program 33505  # GL_PROGRAM
      @gl_program_iv 33506  # GL_PROGRAM_IV

      # Point rendering
      @gl_point_smooth 2832  # GL_POINT_SMOOTH
      @gl_point_size 2833  # GL_POINT_SIZE
      @gl_point_size_min 33062  # GL_POINT_SIZE_MIN
      @gl_point_size_max 33063  # GL_POINT_SIZE_MAX
      @gl_point_fade_threshold_size 33064  # GL_POINT_FADE_THRESHOLD_SIZE

      # Program attributes
      @gl_active_program 33369  # GL_ACTIVE_PROGRAM
      @gl_current_program 35725  # GL_CURRENT_PROGRAM
      @gl_active_attributes 35721  # GL_ACTIVE_ATTRIBUTES
      @gl_active_uniforms 35718  # GL_ACTIVE_UNIFORMS
      @gl_attached_shaders 35717  # GL_ATTACHED_SHADERS
      @gl_delete_status 35712  # GL_DELETE_STATUS

      # Buffer types
      @gl_array_buffer 34962  # GL_ARRAY_BUFFER
      @gl_element_array_buffer 34963  # GL_ELEMENT_ARRAY_BUFFER
      @gl_element_array_buffer_binding 34965  # GL_ELEMENT_ARRAY_BUFFER_BINDING

      # Data types
      @gl_float 5126  # GL_FLOAT
      @gl_false 0  # GL_FALSE
      @gl_unsigned_int 5125  # GL_UNSIGNED_INT
      @gl_static_draw 35044  # GL_STATIC_DRAW

      # Vertex attributes
      @gl_vertex_attrib_array_buffer_binding 34975  # GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING
      @gl_vertex_attrib_binding 33492  # GL_VERTEX_ATTRIB_BINDING
      @gl_vertex_attrib_array_enabled 34338  # GL_VERTEX_ATTRIB_ARRAY_ENABLED
      @gl_vertex_attrib_array_size 34339  # GL_VERTEX_ATTRIB_ARRAY_SIZE
      @gl_vertex_attrib_array_stride 34340  # GL_VERTEX_ATTRIB_ARRAY_STRIDE
      @gl_vertex_array_binding 34229  # GL_VERTEX_ARRAY_BINDING
      @gl_viewport 2978  # GL_VIEWPORT
    end
  end
end
