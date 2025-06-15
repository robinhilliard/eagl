defmodule EAGL.Buffer do
  @moduledoc """
  OpenGL buffer and vertex array object management.

  Provides Wings3D-inspired helper functions for common VAO/VBO/EBO operations
  with meaningful abstractions for vertex attribute setup.

  The module includes type-safe helpers for common vertex attributes like
  position, color, texture coordinates, and normals.

  ## Original Source

  Buffer management patterns and helper functions are inspired by Wings3D's
  `wings_gl.erl` module:
  <https://github.com/dgud/wings/blob/master/src/wings_gl.erl>

  ## Usage

      import EAGL.Buffer

      # Simple position-only vertices
      vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
      {vao, vbo} = create_position_array(vertices)

      # Custom vertex attributes with type-safe configuration
      attributes = [
        vertex_attribute(location: 0, size: 3, type: :float, stride: 24, offset: 0),   # position
        vertex_attribute(location: 1, size: 3, type: :float, stride: 24, offset: 12)  # color
      ]
      {vao, vbo} = create_vertex_array(vertices, attributes)

      # Or use standard attribute helpers
      attributes = [
        position_attribute(stride: 24, offset: 0),
        color_attribute(stride: 24, offset: 12)
      ]
      {vao, vbo} = create_vertex_array(vertices, attributes)

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

  # ============================================================================
  # TYPE DEFINITIONS
  # ============================================================================

  @type buffer_id :: non_neg_integer()
  @type vao_id :: non_neg_integer()

  @type vertex_attribute_type :: :byte | :unsigned_byte | :short | :unsigned_short |
                                 :int | :unsigned_int | :fixed | :float | :half_float | :double

  @type buffer_usage :: :stream_draw | :stream_read | :stream_copy |
                        :static_draw | :static_read | :static_copy |
                        :dynamic_draw | :dynamic_read | :dynamic_copy

  @type vertex_attribute :: %{
    location: non_neg_integer(),
    size: 1..4,
    type: vertex_attribute_type(),
    normalized: boolean(),
    stride: non_neg_integer(),
    offset: non_neg_integer()
  }

  @type vertex_attribute_name :: :position | :color | :texture_coordinate | :normal

  # ============================================================================
  # TYPE-SAFE ATTRIBUTE HELPERS
  # ============================================================================

  @doc """
  Creates a vertex attribute configuration with type safety and sensible defaults.

  ## Options

  - `location`: Attribute location in shader (required)
  - `size`: Number of components (1-4, required)
  - `type`: Data type (default: :float)
  - `normalized`: Whether to normalize fixed-point data (default: false)
  - `stride`: Byte offset between consecutive attributes (default: 0 for tightly packed)
  - `offset`: Byte offset of first component in buffer (default: 0)

  ## Examples

      # Position attribute (vec3)
      pos_attr = vertex_attribute(location: 0, size: 3)

      # Color attribute with custom stride and offset
      color_attr = vertex_attribute(location: 1, size: 3, type: :float, stride: 24, offset: 12)

      # Normalized integer attribute
      normal_attr = vertex_attribute(location: 2, size: 3, type: :byte, normalized: true)
  """
  @spec vertex_attribute(keyword()) :: vertex_attribute()
  def vertex_attribute(opts) do
    location = Keyword.fetch!(opts, :location)
    size = Keyword.fetch!(opts, :size)

    unless location >= 0, do: raise(ArgumentError, "location must be non-negative")
    unless size in 1..4, do: raise(ArgumentError, "size must be 1-4")

    %{
      location: location,
      size: size,
      type: Keyword.get(opts, :type, :float),
      normalized: Keyword.get(opts, :normalized, false),
      stride: Keyword.get(opts, :stride, 0),
      offset: Keyword.get(opts, :offset, 0)
    }
  end

  @doc """
  Creates a standard position attribute configuration (location 0, vec3, float).
  """
  @spec position_attribute(keyword()) :: vertex_attribute()
  def position_attribute(opts \\ []) do
    opts
    |> Keyword.put_new(:location, 0)
    |> Keyword.put_new(:size, 3)
    |> Keyword.put_new(:type, :float)
    |> vertex_attribute()
  end

  @doc """
  Creates a standard color attribute configuration (location 1, vec3, float).
  """
  @spec color_attribute(keyword()) :: vertex_attribute()
  def color_attribute(opts \\ []) do
    opts
    |> Keyword.put_new(:location, 1)
    |> Keyword.put_new(:size, 3)
    |> Keyword.put_new(:type, :float)
    |> vertex_attribute()
  end

  @doc """
  Creates a standard texture coordinate attribute configuration (location 2, vec2, float).
  """
  @spec texture_coordinate_attribute(keyword()) :: vertex_attribute()
  def texture_coordinate_attribute(opts \\ []) do
    opts
    |> Keyword.put_new(:location, 2)
    |> Keyword.put_new(:size, 2)
    |> Keyword.put_new(:type, :float)
    |> vertex_attribute()
  end

  @doc """
  Creates a standard normal attribute configuration (location 3, vec3, float).
  """
  @spec normal_attribute(keyword()) :: vertex_attribute()
  def normal_attribute(opts \\ []) do
    opts
    |> Keyword.put_new(:location, 3)
    |> Keyword.put_new(:size, 3)
    |> Keyword.put_new(:type, :float)
    |> vertex_attribute()
  end

  # ============================================================================
  # MAIN BUFFER CREATION FUNCTIONS
  # ============================================================================

  @doc """
  Creates a VAO with a single VBO containing vertex data.
  Returns {vao, vbo} tuple.

  ## Parameters
  - vertices: List of floats representing vertex data
  - attributes: List of vertex_attribute structs
  - opts: Options for buffer creation

  ## Options
  - `usage`: Buffer usage pattern (default: :static_draw)

  ## Example
      vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]

      # Type-safe approach
      attributes = [
        position_attribute(),
        color_attribute(stride: 24, offset: 12)
      ]
      {vao, vbo} = create_vertex_array(vertices, attributes)
  """
  @spec create_vertex_array(list(float()), list(vertex_attribute()), keyword()) :: {vao_id(), buffer_id()}
  def create_vertex_array(vertices, attributes, opts \\ []) do
    # Generate VAO and VBO
    [vao] = :gl.genVertexArrays(1)
    [vbo] = :gl.genBuffers(1)

    # Bind VAO
    :gl.bindVertexArray(vao)

    # Bind and fill VBO
    :gl.bindBuffer(@gl_array_buffer, vbo)
    vertex_data = vertices_to_binary(vertices)
    usage = buffer_usage_to_gl(Keyword.get(opts, :usage, :static_draw))
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, usage)

    # Configure vertex attributes
    Enum.each(attributes, &configure_vertex_attribute/1)

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
  - attributes: List of vertex_attribute structs
  - opts: Options for buffer creation

  ## Options
  - `usage`: Buffer usage pattern (default: :static_draw)

  ## Example
      vertices = [0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0]
      indices = [0, 1, 3, 1, 2, 3]

      attributes = [position_attribute()]
      {vao, vbo, ebo} = create_indexed_array(vertices, indices, attributes)
  """
  @spec create_indexed_array(list(float()), list(integer()), list(vertex_attribute()), keyword()) :: {vao_id(), buffer_id(), buffer_id()}
  def create_indexed_array(vertices, indices, attributes, opts \\ []) do
    # Generate VAO, VBO, and EBO
    [vao] = :gl.genVertexArrays(1)
    [vbo] = :gl.genBuffers(1)
    [ebo] = :gl.genBuffers(1)

    # Bind VAO first
    :gl.bindVertexArray(vao)

    # Bind and fill VBO with vertex data
    :gl.bindBuffer(@gl_array_buffer, vbo)
    vertex_data = vertices_to_binary(vertices)
    usage = buffer_usage_to_gl(Keyword.get(opts, :usage, :static_draw))
    :gl.bufferData(@gl_array_buffer, byte_size(vertex_data), vertex_data, usage)

    # Bind and fill EBO with index data
    :gl.bindBuffer(@gl_element_array_buffer, ebo)
    index_data = indices_to_binary(indices)
    :gl.bufferData(@gl_element_array_buffer, byte_size(index_data), index_data, usage)

    # Configure vertex attributes
    Enum.each(attributes, &configure_vertex_attribute/1)

    # Unbind (good practice)
    :gl.bindBuffer(@gl_array_buffer, 0)
    # Note: Don't unbind EBO while VAO is active - VAO stores the EBO binding
    :gl.bindVertexArray(0)

    {vao, vbo, ebo}
  end

  @doc """
  Creates a list of vertex attributes with automatic stride and offset calculation.
  This is a higher-level helper that eliminates the redundancy of manually
  specifying stride and offset for common interleaved vertex layouts.

  ## Usage
      # List syntax
      attributes = vertex_attributes([:position, :color])

      # Multiple arguments syntax
      attributes = vertex_attributes(:position, :color, :texture_coordinate)

  ## Supported Attribute Types

  See `t:vertex_attribute_name/0` for the complete type definition.

  - `:position` - 3 floats (x, y, z) at location 0
  - `:color` - 3 floats (r, g, b) at location 1
  - `:texture_coordinate` - 2 floats (s, t) at location 2
  - `:normal` - 3 floats (nx, ny, nz) at location 3

  ## Examples
      # Position and color (stride=24, offsets: 0, 12)
      {vao, vbo} = create_vertex_array(vertices, vertex_attributes([:position, :color]))

      # Position, color, texture (stride=32, offsets: 0, 12, 24)
      attributes = vertex_attributes(:position, :color, :texture_coordinate)
      {vao, vbo} = create_vertex_array(vertices, attributes)

  The function automatically calculates:
  - Stride: Total size of one vertex (sum of all attribute sizes)
  - Offsets: Cumulative byte offset for each attribute
  - Locations: Sequential starting from 0
  """
  @spec vertex_attributes(list(vertex_attribute_name())) :: list(vertex_attribute())
  def vertex_attributes(attr_types) when is_list(attr_types) and length(attr_types) > 0 do
    calculate_attributes(attr_types)
  end

  # Support multiple argument syntax: vertex_attributes(:position, :color)
  @spec vertex_attributes(vertex_attribute_name(), vertex_attribute_name()) :: list(vertex_attribute())
  def vertex_attributes(first_type, second_type) when is_atom(first_type) and is_atom(second_type) do
    calculate_attributes([first_type, second_type])
  end

  @spec vertex_attributes(vertex_attribute_name(), vertex_attribute_name(), vertex_attribute_name()) :: list(vertex_attribute())
  def vertex_attributes(first_type, second_type, third_type) when is_atom(first_type) and is_atom(second_type) and is_atom(third_type) do
    calculate_attributes([first_type, second_type, third_type])
  end

  @spec vertex_attributes(vertex_attribute_name(), vertex_attribute_name(), vertex_attribute_name(), vertex_attribute_name()) :: list(vertex_attribute())
  def vertex_attributes(first_type, second_type, third_type, fourth_type) when is_atom(first_type) and is_atom(second_type) and is_atom(third_type) and is_atom(fourth_type) do
    calculate_attributes([first_type, second_type, third_type, fourth_type])
  end

  # Helper function to calculate attributes with automatic stride/offset
  @spec calculate_attributes(list(vertex_attribute_name())) :: list(vertex_attribute())
  defp calculate_attributes(attr_types) do
    # Calculate total stride (sum of all attribute sizes in bytes)
    total_stride = Enum.reduce(attr_types, 0, fn type, acc ->
      acc + attribute_size_bytes(type)
    end)

    # Generate attributes with calculated offsets
    {attributes, _final_offset} = Enum.reduce(attr_types, {[], 0}, fn type, {attrs, offset} ->
      location = length(attrs)  # Sequential locations: 0, 1, 2, 3...
      size = attribute_size_floats(type)
      attr = vertex_attribute(
        location: location,
        size: size,
        type: :float,
        stride: total_stride,
        offset: offset
      )
      next_offset = offset + attribute_size_bytes(type)
      {attrs ++ [attr], next_offset}
    end)

    attributes
  end

  # Size of each attribute type in floats
  @spec attribute_size_floats(vertex_attribute_name()) :: 1..4
  defp attribute_size_floats(:position), do: 3
  defp attribute_size_floats(:color), do: 3
  defp attribute_size_floats(:texture_coordinate), do: 2
  defp attribute_size_floats(:normal), do: 3

  # Size of each attribute type in bytes (float = 4 bytes)
  @spec attribute_size_bytes(vertex_attribute_name()) :: 4..16
  defp attribute_size_bytes(type), do: attribute_size_floats(type) * 4

  @doc """
  Creates a simple VAO with position-only vertices (3 floats per vertex).
  Convenience wrapper for the most common case.

  ## Example
      vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
      {vao, vbo} = create_position_array(vertices)
  """
  @spec create_position_array(list(float())) :: {vao_id(), buffer_id()}
  def create_position_array(vertices) do
    create_vertex_array(vertices, [position_attribute()])
  end

  @doc """
  Creates a simple indexed VAO with position-only vertices (3 floats per vertex).
  Convenience wrapper for indexed geometry with positions only.

  ## Example
      vertices = [0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0]
      indices = [0, 1, 3, 1, 2, 3]  # Two triangles forming a rectangle
      {vao, vbo, ebo} = create_indexed_position_array(vertices, indices)
  """
  @spec create_indexed_position_array(list(float()), list(integer())) :: {vao_id(), buffer_id(), buffer_id()}
  def create_indexed_position_array(vertices, indices) do
    create_indexed_array(vertices, indices, [position_attribute()])
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

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  # Configure a vertex attribute from vertex_attribute struct
  defp configure_vertex_attribute(%{location: location, size: size, type: type, normalized: normalized, stride: stride, offset: offset}) do
    gl_type = vertex_attribute_type_to_gl(type)
    gl_normalized = if normalized, do: @gl_true, else: @gl_false
    :gl.vertexAttribPointer(location, size, gl_type, gl_normalized, stride, offset)
    :gl.enableVertexAttribArray(location)
  end

  # Convert vertex attribute type atoms to OpenGL constants
  defp vertex_attribute_type_to_gl(:byte), do: @gl_byte
  defp vertex_attribute_type_to_gl(:unsigned_byte), do: @gl_unsigned_byte
  defp vertex_attribute_type_to_gl(:short), do: @gl_short
  defp vertex_attribute_type_to_gl(:unsigned_short), do: @gl_unsigned_short
  defp vertex_attribute_type_to_gl(:int), do: @gl_int
  defp vertex_attribute_type_to_gl(:unsigned_int), do: @gl_unsigned_int
  defp vertex_attribute_type_to_gl(:fixed), do: @gl_fixed
  defp vertex_attribute_type_to_gl(:float), do: @gl_float
  defp vertex_attribute_type_to_gl(:half_float), do: @gl_half_float
  defp vertex_attribute_type_to_gl(:double), do: @gl_double

  # Convert buffer usage atoms to OpenGL constants
  defp buffer_usage_to_gl(:stream_draw), do: @gl_stream_draw
  defp buffer_usage_to_gl(:stream_read), do: @gl_stream_read
  defp buffer_usage_to_gl(:stream_copy), do: @gl_stream_copy
  defp buffer_usage_to_gl(:static_draw), do: @gl_static_draw
  defp buffer_usage_to_gl(:static_read), do: @gl_static_read
  defp buffer_usage_to_gl(:static_copy), do: @gl_static_copy
  defp buffer_usage_to_gl(:dynamic_draw), do: @gl_dynamic_draw
  defp buffer_usage_to_gl(:dynamic_read), do: @gl_dynamic_read
  defp buffer_usage_to_gl(:dynamic_copy), do: @gl_dynamic_copy
end
