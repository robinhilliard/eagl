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
end
