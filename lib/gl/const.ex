defmodule GL.Const do
  @moduledoc """
  Constants for OpenGL.
  """

  @doc """
  OpenGL constants
  """
  def gl_vertex_shader, do: 35633  # GL_VERTEX_SHADER
  def gl_fragment_shader, do: 35632  # GL_FRAGMENT_SHADER
  def gl_compile_status, do: 35713  # GL_COMPILE_STATUS
  def gl_link_status, do: 35714  # GL_LINK_STATUS
  def gl_info_log_length, do: 35716  # GL_INFO_LOG_LENGTH
  def gl_color_buffer_bit, do: 16384  # GL_COLOR_BUFFER_BIT
  def gl_depth_buffer_bit, do: 256  # GL_DEPTH_BUFFER_BIT
  def gl_depth_test, do: 2929  # GL_DEPTH_TEST
  def gl_cull_face, do: 2884  # GL_CULL_FACE
  def gl_front_and_back, do: 1032  # GL_FRONT_AND_BACK
  def gl_fill, do: 6914  # GL_FILL
  def gl_triangles, do: 4  # GL_TRIANGLES
  def gl_points, do: 0  # GL_POINTS
  def gl_version, do: 7938  # GL_VERSION
  def gl_program, do: 33505  # GL_PROGRAM
  def gl_program_iv, do: 33506  # GL_PROGRAM_IV
  def gl_point_smooth, do: 2832  # GL_POINT_SMOOTH
  def gl_point_size, do: 2833  # GL_POINT_SIZE
  def gl_point_size_min, do: 33062  # GL_POINT_SIZE_MIN
  def gl_point_size_max, do: 33063  # GL_POINT_SIZE_MAX
  def gl_point_fade_threshold_size, do: 33064  # GL_POINT_FADE_THRESHOLD_SIZE
  def gl_active_program, do: 33369  # GL_ACTIVE_PROGRAM
  def gl_current_program, do: 35725  # GL_CURRENT_PROGRAM
  def gl_active_attributes, do: 35721  # GL_ACTIVE_ATTRIBUTES
  def gl_active_uniforms, do: 35718  # GL_ACTIVE_UNIFORMS
  def gl_attached_shaders, do: 35717  # GL_ATTACHED_SHADERS
  def gl_delete_status, do: 35712  # GL_DELETE_STATUS

  # Buffer types
  def gl_array_buffer, do: 34962  # GL_ARRAY_BUFFER
  def gl_element_array_buffer, do: 34963  # GL_ELEMENT_ARRAY_BUFFER
  def gl_element_array_buffer_binding, do: 34965  # GL_ELEMENT_ARRAY_BUFFER_BINDING

  # Data types
  def gl_float, do: 5126  # GL_FLOAT
  def gl_false, do: 0  # GL_FALSE
  def gl_unsigned_int, do: 5125  # GL_UNSIGNED_INT
  def gl_static_draw, do: 35044  # GL_STATIC_DRAW

  # Vertex attributes
  def gl_vertex_attrib_array_buffer_binding, do: 34975  # GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING
  def gl_vertex_attrib_binding, do: 33492  # GL_VERTEX_ATTRIB_BINDING
  def gl_vertex_attrib_array_enabled, do: 34338  # GL_VERTEX_ATTRIB_ARRAY_ENABLED
  def gl_vertex_attrib_array_size, do: 34339  # GL_VERTEX_ATTRIB_ARRAY_SIZE
  def gl_vertex_attrib_array_stride, do: 34340  # GL_VERTEX_ATTRIB_ARRAY_STRIDE
  def gl_vertex_array_binding, do: 34229  # GL_VERTEX_ARRAY_BINDING
  def gl_viewport, do: 2978  # GL_VIEWPORT
end
