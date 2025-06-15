defmodule EAGL.BufferTest do
  use ExUnit.Case
  import EAGL.Buffer
  doctest EAGL.Buffer

  describe "create_position_array/1" do
    setup do
      # Skip tests that require OpenGL context if not available
      try do
        :application.start(:wx)
        wx = :wx.new()
        frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
        gl_canvas = :wxGLCanvas.new(frame, [])
        :wxFrame.show(frame)
        :timer.sleep(50)
        gl_context = :wxGLContext.new(gl_canvas)
        :wxGLCanvas.setCurrent(gl_canvas, gl_context)

        on_exit(fn ->
          try do
            :wxGLContext.destroy(gl_context)
          rescue
            _ -> :ok
          end

          try do
            :wxFrame.destroy(frame)
          rescue
            _ -> :ok
          end

          try do
            :application.stop(:wx)
          rescue
            _ -> :ok
          end
        end)

        {:ok, %{gl_available: true}}
      rescue
        _ -> {:ok, %{gl_available: false}}
      end
    end

    test "creates VAO and VBO for triangle vertices", %{gl_available: gl_available} do
      if gl_available do
        vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
        {vao, vbo} = EAGL.Buffer.create_position_array(vertices)

        assert is_integer(vao)
        assert is_integer(vbo)
        assert vao > 0
        assert vbo > 0

        # Clean up
        EAGL.Buffer.delete_vertex_array(vao, vbo)
      else
        # Skip test if OpenGL not available
        assert true
      end
    end
  end

  describe "buffer creation" do
    setup do
      # Skip tests that require OpenGL context if not available
      try do
        :application.start(:wx)
        wx = :wx.new()
        frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
        gl_canvas = :wxGLCanvas.new(frame, [])
        :wxFrame.show(frame)
        :timer.sleep(50)
        gl_context = :wxGLContext.new(gl_canvas)
        :wxGLCanvas.setCurrent(gl_canvas, gl_context)

        on_exit(fn ->
          try do
            :wxGLContext.destroy(gl_context)
          rescue
            _ -> :ok
          end

          try do
            :wxFrame.destroy(frame)
          rescue
            _ -> :ok
          end

          try do
            :application.stop(:wx)
          rescue
            _ -> :ok
          end
        end)

        {:ok, %{gl_available: true}}
      rescue
        _ -> {:ok, %{gl_available: false}}
      end
    end

    test "creates vertex array with position data", %{gl_available: gl_available} do
      if gl_available do
        vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
        {vao, vbo} = create_position_array(vertices)

        assert is_integer(vao)
        assert is_integer(vbo)

        # Clean up
        delete_vertex_array(vao, vbo)
      else
        assert true
      end
    end

    test "creates indexed vertex array", %{gl_available: gl_available} do
      if gl_available do
        vertices = [0.5, 0.5, 0.0, 0.5, -0.5, 0.0, -0.5, -0.5, 0.0, -0.5, 0.5, 0.0]
        indices = [0, 1, 3, 1, 2, 3]
        {vao, vbo, ebo} = create_indexed_position_array(vertices, indices)

        assert is_integer(vao)
        assert is_integer(vbo)
        assert is_integer(ebo)

        # Clean up
        delete_indexed_array(vao, vbo, ebo)
      else
        assert true
      end
    end
  end

  describe "type-safe vertex attributes" do
    test "creates vertex attribute struct with required fields" do
      attr = vertex_attribute(location: 0, size: 3)

      assert attr.location == 0
      assert attr.size == 3
      # default
      assert attr.type == :float
      # default
      assert attr.normalized == false
      # default
      assert attr.stride == 0
      # default
      assert attr.offset == 0
    end

    test "creates vertex attribute struct with custom options" do
      attr =
        vertex_attribute(
          location: 1,
          size: 2,
          type: :unsigned_byte,
          normalized: true,
          stride: 20,
          offset: 12
        )

      assert attr.location == 1
      assert attr.size == 2
      assert attr.type == :unsigned_byte
      assert attr.normalized == true
      assert attr.stride == 20
      assert attr.offset == 12
    end

    test "validates location is non-negative" do
      assert_raise ArgumentError, "location must be non-negative", fn ->
        vertex_attribute(location: -1, size: 3)
      end
    end

    test "validates size is between 1 and 4" do
      assert_raise ArgumentError, "size must be 1-4", fn ->
        vertex_attribute(location: 0, size: 5)
      end

      assert_raise ArgumentError, "size must be 1-4", fn ->
        vertex_attribute(location: 0, size: 0)
      end
    end

    test "position_attribute creates standard position attribute" do
      attr = position_attribute()

      assert attr.location == 0
      assert attr.size == 3
      assert attr.type == :float
    end

    test "position_attribute allows overrides" do
      attr = position_attribute(stride: 24, offset: 0)

      assert attr.location == 0
      assert attr.size == 3
      assert attr.type == :float
      assert attr.stride == 24
      assert attr.offset == 0
    end

    test "color_attribute creates standard color attribute" do
      attr = color_attribute()

      assert attr.location == 1
      assert attr.size == 3
      assert attr.type == :float
    end

    test "texture_coordinate_attribute creates standard texture coordinate attribute" do
      attr = texture_coordinate_attribute()

      assert attr.location == 2
      assert attr.size == 2
      assert attr.type == :float
    end

    test "normal_attribute creates standard normal attribute" do
      attr = normal_attribute()

      assert attr.location == 3
      assert attr.size == 3
      assert attr.type == :float
    end

    @tag :skip
    test "can create complex vertex layouts" do
      vertices = [
        -0.5,
        -0.5,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.5,
        -0.5,
        0.0,
        0.0,
        1.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.5,
        0.0,
        0.0,
        0.0,
        1.0,
        0.5,
        1.0
      ]

      # Complex vertex format: position (3) + color (3) + texcoord (2) = 8 floats per vertex
      attributes = [
        position_attribute(stride: 32, offset: 0),
        color_attribute(stride: 32, offset: 12),
        texture_coordinate_attribute(stride: 32, offset: 24)
      ]

      {vao, vbo} = create_vertex_array(vertices, attributes)

      assert is_integer(vao)
      assert is_integer(vbo)
    end
  end

  describe "automatic vertex attributes" do
    test "creates position-only attributes with list syntax" do
      attrs = vertex_attributes([:position])

      assert length(attrs) == 1

      attr = List.first(attrs)
      assert attr.location == 0
      assert attr.size == 3
      assert attr.type == :float
      # 3 floats * 4 bytes
      assert attr.stride == 12
      assert attr.offset == 0
    end

    test "creates position and color attributes with list syntax" do
      attrs = vertex_attributes([:position, :color])

      assert length(attrs) == 2

      [pos_attr, color_attr] = attrs

      # Position attribute
      assert pos_attr.location == 0
      assert pos_attr.size == 3
      # 6 floats * 4 bytes total
      assert pos_attr.stride == 24
      assert pos_attr.offset == 0

      # Color attribute
      assert color_attr.location == 1
      assert color_attr.size == 3
      # Same stride for all
      assert color_attr.stride == 24
      # 3 floats * 4 bytes offset
      assert color_attr.offset == 12
    end

    test "creates complex attributes with multiple argument syntax" do
      attrs = vertex_attributes(:position, :color, :texture_coordinate)

      assert length(attrs) == 3

      [pos_attr, color_attr, tex_attr] = attrs

      # All should have same stride (total vertex size)
      # 8 floats * 4 bytes = 32 bytes
      total_stride = 32
      assert pos_attr.stride == total_stride
      assert color_attr.stride == total_stride
      assert tex_attr.stride == total_stride

      # Position: location 0, size 3, offset 0
      assert pos_attr.location == 0
      assert pos_attr.size == 3
      assert pos_attr.offset == 0

      # Color: location 1, size 3, offset 12
      assert color_attr.location == 1
      assert color_attr.size == 3
      assert color_attr.offset == 12

      # Texture coordinate: location 2, size 2, offset 24
      assert tex_attr.location == 2
      assert tex_attr.size == 2
      assert tex_attr.offset == 24
    end

    test "creates attributes with normal support" do
      attrs = vertex_attributes([:position, :normal])

      assert length(attrs) == 2

      [pos_attr, normal_attr] = attrs

      # Both 3-float attributes
      assert pos_attr.size == 3
      assert normal_attr.size == 3
      assert normal_attr.location == 1
      # After position
      assert normal_attr.offset == 12
    end

    test "supports two-argument syntax" do
      attrs = vertex_attributes(:position, :color)

      assert length(attrs) == 2
      assert List.first(attrs).location == 0
      assert List.last(attrs).location == 1
    end

    test "all attributes use float type by default" do
      attrs = vertex_attributes([:position, :color, :texture_coordinate, :normal])

      Enum.each(attrs, fn attr ->
        assert attr.type == :float
        assert attr.normalized == false
      end)
    end
  end

  describe "edge cases and error handling" do
    test "vertex_attributes with empty list" do
      assert_raise FunctionClauseError, fn ->
        vertex_attributes([])
      end
    end

    test "vertex_attributes with invalid atom" do
      assert_raise FunctionClauseError, fn ->
        vertex_attributes([:invalid_attribute_type])
      end
    end

    test "vertex_attributes with maximum supported attributes" do
      attrs = vertex_attributes([:position, :color, :texture_coordinate, :normal])

      assert length(attrs) == 4

      # Check that locations are sequential
      locations = Enum.map(attrs, & &1.location)
      assert locations == [0, 1, 2, 3]

      # Check total stride calculation (3+3+2+3 = 11 floats = 44 bytes)
      expected_stride = 44

      Enum.each(attrs, fn attr ->
        assert attr.stride == expected_stride
      end)

      # Check offset calculations
      [pos, color, tex, normal] = attrs
      assert pos.offset == 0
      # 3 floats * 4 bytes
      assert color.offset == 12
      # 6 floats * 4 bytes
      assert tex.offset == 24
      # 8 floats * 4 bytes
      assert normal.offset == 32
    end

    test "vertex_attribute with all supported types" do
      types = [
        :byte,
        :unsigned_byte,
        :short,
        :unsigned_short,
        :int,
        :unsigned_int,
        :fixed,
        :float,
        :half_float,
        :double
      ]

      Enum.each(types, fn type ->
        attr = vertex_attribute(location: 0, size: 3, type: type)
        assert attr.type == type
      end)
    end

    test "vertex_attribute with all supported sizes" do
      Enum.each(1..4, fn size ->
        attr = vertex_attribute(location: 0, size: size)
        assert attr.size == size
      end)
    end

    test "vertex_attribute with large stride and offset values" do
      attr =
        vertex_attribute(
          location: 0,
          size: 4,
          stride: 1024,
          offset: 512
        )

      assert attr.stride == 1024
      assert attr.offset == 512
    end

    test "vertex_attributes with single attribute via multiple argument syntax" do
      # This should work even though it's not the typical use case
      attrs = vertex_attributes(:position, :position)

      assert length(attrs) == 2
      assert List.first(attrs).location == 0
      assert List.last(attrs).location == 1
    end
  end

  describe "performance and large data" do
    test "vertices_to_binary with large vertex array" do
      # Create a large vertex array (1000 vertices * 3 floats = 3000 floats)
      large_vertices = Enum.to_list(1..3000) |> Enum.map(&(&1 * 1.0))

      binary = vertices_to_binary(large_vertices)

      assert is_binary(binary)
      # 3000 floats * 4 bytes each
      assert byte_size(binary) == 3000 * 4
    end

    test "indices_to_binary with large index array" do
      # Create a large index array
      large_indices = Enum.to_list(0..2999)

      binary = indices_to_binary(large_indices)

      assert is_binary(binary)
      # 3000 ints * 4 bytes each
      assert byte_size(binary) == 3000 * 4
    end

    test "vertex_attributes calculation performance" do
      # Test that calculations are fast even with complex layouts
      start_time = :erlang.monotonic_time(:microsecond)

      # Repeat calculation many times
      Enum.each(1..1000, fn _ ->
        vertex_attributes([:position, :color, :texture_coordinate, :normal])
      end)

      end_time = :erlang.monotonic_time(:microsecond)
      duration = end_time - start_time

      # Should complete in reasonable time (less than 100ms = 100,000 microseconds)
      assert duration < 100_000
    end
  end

  describe "resource cleanup and management" do
    setup do
      # Skip tests that require OpenGL context if not available
      try do
        :application.start(:wx)
        wx = :wx.new()
        frame = :wxFrame.new(wx, -1, "Test", size: {100, 100})
        gl_canvas = :wxGLCanvas.new(frame, [])
        :wxFrame.show(frame)
        :timer.sleep(50)
        gl_context = :wxGLContext.new(gl_canvas)
        :wxGLCanvas.setCurrent(gl_canvas, gl_context)

        on_exit(fn ->
          try do
            :wxGLContext.destroy(gl_context)
          rescue
            _ -> :ok
          end

          try do
            :wxFrame.destroy(frame)
          rescue
            _ -> :ok
          end

          try do
            :application.stop(:wx)
          rescue
            _ -> :ok
          end
        end)

        {:ok, %{gl_available: true}}
      rescue
        _ -> {:ok, %{gl_available: false}}
      end
    end

    test "delete_vertex_array with multiple VBOs", %{gl_available: gl_available} do
      if gl_available do
        vertices = [-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0]
        {vao, vbo} = create_position_array(vertices)

        # Test cleanup - should not raise errors
        assert :ok = delete_vertex_array(vao, [vbo])
        # Test single VBO variant
        assert :ok = delete_vertex_array(vao, vbo)
      else
        assert true
      end
    end
  end

  describe "utility functions" do
    test "converts vertices to binary" do
      vertices = [1.0, 2.0, 3.0]
      binary = vertices_to_binary(vertices)

      assert is_binary(binary)
      # 3 floats * 4 bytes each
      assert byte_size(binary) == 12
    end

    test "converts indices to binary" do
      indices = [0, 1, 2]
      binary = indices_to_binary(indices)

      assert is_binary(binary)
      # 3 ints * 4 bytes each
      assert byte_size(binary) == 12
    end
  end
end
