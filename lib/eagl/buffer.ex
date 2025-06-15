defmodule EAGL.Buffer do
  @moduledoc """
  OpenGL buffer and vertex array object management.

  Provides Wings3D-inspired helper functions for common VAO/VBO/EBO operations
  with meaningful abstractions for vertex attribute setup.

  ## Usage

      import EAGL.Buffer

      # Simple position-only vertices
      vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
      {vao, vbo} = create_position_array(vertices)

      # Custom vertex attributes
      {vao, vbo} = create_vertex_array(vertices, [
        {0, 3, @gl_float, @gl_false, 0, 0}  # position at location 0
      ])

      # Indexed geometry (rectangles, models)
      vertices = [0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0]
      indices = [0, 1, 3, 1, 2, 3]
      {vao, vbo, ebo} = create_indexed_position_array(vertices, indices)

      # Use OpenGL directly for rendering
      :gl.bindVertexArray(vao)
      :gl.drawElements(@gl_triangles, 6, @gl_unsigned_int, 0)

      # Clean up
      delete_vertex_array(vao, vbo)
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
    vertex_data = vertices_to_binary(vertices)
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
  Creates a VAO with VBO and EBO for indexed geometry.
  Returns {vao, vbo, ebo} tuple.

  ## Parameters
  - vertices: List of floats representing vertex data
  - indices: List of integers representing vertex indices
  - attribute_configs: List of attribute configurations
    Each config is {location, size, type, normalized, stride, offset}

  ## Example
      vertices = [0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0]
      indices = [0, 1, 3, 1, 2, 3]
      {vao, vbo, ebo} = create_indexed_array(vertices, indices, [{0, 3, @gl_float, @gl_false, 0, 0}])
  """
  @spec create_indexed_array(list(float()), list(integer()), list(tuple())) :: {integer(), integer(), integer()}
  def create_indexed_array(vertices, indices, attribute_configs) do
    # Generate VAO, VBO, and EBO
    [vao] = :gl.genVertexArrays(1)
    [vbo] = :gl.genBuffers(1)
    [ebo] = :gl.genBuffers(1)

    # Bind VAO first
    :gl.bindVertexArray(vao)

    # Bind and fill VBO with vertex data
    :gl.bindBuffer(@gl_array_buffer, vbo)
    vertex_data = vertices_to_binary(vertices)
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, @gl_static_draw)

    # Bind and fill EBO with index data
    :gl.bindBuffer(@gl_element_array_buffer, ebo)
    index_data = indices_to_binary(indices)
    :gl.bufferData(@gl_element_array_buffer, byte_size(index_data), index_data, @gl_static_draw)

    # Configure vertex attributes
    Enum.each(attribute_configs, fn {location, size, type, normalized, stride, offset} ->
      :gl.vertexAttribPointer(location, size, type, normalized, stride, offset)
      :gl.enableVertexAttribArray(location)
    end)

    # Unbind (good practice)
    :gl.bindBuffer(@gl_array_buffer, 0)
    # Note: Don't unbind EBO while VAO is active - VAO stores the EBO binding
    :gl.bindVertexArray(0)

    {vao, vbo, ebo}
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
  Creates a simple indexed VAO with position-only vertices (3 floats per vertex).
  Convenience wrapper for indexed geometry with positions only.

  ## Example
      vertices = [0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0]
      indices = [0, 1, 3, 1, 2, 3]  # Two triangles forming a rectangle
      {vao, vbo, ebo} = create_indexed_position_array(vertices, indices)
  """
  @spec create_indexed_position_array(list(float()), list(integer())) :: {integer(), integer(), integer()}
  def create_indexed_position_array(vertices, indices) do
    create_indexed_array(vertices, indices, [{0, 3, @gl_float, @gl_false, 0, 0}])
  end

  @doc """
  Converts a list of vertex floats to binary format for OpenGL.
  """
  @spec vertices_to_binary(list(float())) :: binary()
  def vertices_to_binary(vertices) do
    for v <- vertices, into: <<>>, do: <<v::float-32-native>>
  end

  @doc """
  Converts a list of indices to binary format for OpenGL.
  """
  @spec indices_to_binary(list(integer())) :: binary()
  def indices_to_binary(indices) do
    for i <- indices, into: <<>>, do: <<i::unsigned-32-native>>
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

  @doc """
  Deletes a VAO and its associated VBO and EBO.
  """
  @spec delete_indexed_array(integer(), integer(), integer()) :: :ok
  def delete_indexed_array(vao, vbo, ebo) do
    :gl.deleteVertexArrays([vao])
    :gl.deleteBuffers([vbo, ebo])
    :ok
  end
end
