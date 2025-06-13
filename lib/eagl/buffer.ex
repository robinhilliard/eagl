defmodule EAGL.Buffer do
  @moduledoc """
  Helper functions for OpenGL buffer and vertex array object management.
  Provides convenient wrappers for common VAO/VBO operations.
  """

  use EAGL.Const

  @doc """
  Creates a VAO with a single VBO containing vertex data.
  Returns {vao, vbo} tuple.

  ## Parameters
  - vertices: List of floats representing vertex data
  - attribute_configs: List of attribute configurations
    Each config is {location, size, type, normalized, stride, offset}

  ## Example
      vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
      {vao, vbo} = create_vertex_array(vertices, [{0, 3, @gl_float, @gl_false, 0, 0}])
  """
  @spec create_vertex_array(list(float()), list(tuple())) :: {integer(), integer()}
  def create_vertex_array(vertices, attribute_configs) do
    # Generate VAO and VBO
    [vao] = :gl.genVertexArrays(1)
    [vbo] = :gl.genBuffers(1)

    # Bind VAO
    :gl.bindVertexArray(vao)

    # Bind and fill VBO
    :gl.bindBuffer(@gl_array_buffer, vbo)
    vertex_data = for v <- vertices, into: <<>>, do: <<v::float-32-native>>
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, @gl_static_draw)

    # Configure vertex attributes
    Enum.each(attribute_configs, fn {location, size, type, normalized, stride, offset} ->
      :gl.vertexAttribPointer(location, size, type, normalized, stride, offset)
      :gl.enableVertexAttribArray(location)
    end)

    # Unbind (good practice)
    :gl.bindBuffer(@gl_array_buffer, 0)
    :gl.bindVertexArray(0)

    {vao, vbo}
  end

  @doc """
  Creates a simple VAO with position-only vertices (3 floats per vertex).
  Convenience wrapper for the most common case.

  ## Example
      vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
      {vao, vbo} = create_position_array(vertices)
  """
  @spec create_position_array(list(float())) :: {integer(), integer()}
  def create_position_array(vertices) do
    create_vertex_array(vertices, [{0, 3, @gl_float, @gl_false, 0, 0}])
  end

  @doc """
  Deletes a VAO and its associated VBOs.
  """
  @spec delete_vertex_array(integer(), list(integer())) :: :ok
  def delete_vertex_array(vao, vbos) when is_list(vbos) do
    :gl.deleteVertexArrays([vao])
    :gl.deleteBuffers(vbos)
    :ok
  end

  @spec delete_vertex_array(integer(), integer()) :: :ok
  def delete_vertex_array(vao, vbo) when is_integer(vbo) do
    delete_vertex_array(vao, [vbo])
  end


end
