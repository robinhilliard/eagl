defmodule EAGL.MeshTest do
  use ExUnit.Case, async: true
  use EAGL.Const

  alias EAGL.Mesh

  describe "from_map/1" do
    test "returns nil for nil" do
      assert Mesh.from_map(nil) == nil
    end

    test "returns structs unchanged" do
      mesh = Mesh.new(vao: 1, vertex_count: 3)
      assert Mesh.from_map(mesh) == mesh
    end

    test "converts maps including bounds-only meshes" do
      mesh = Mesh.from_map(%{bounds: {{-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}}})
      assert %Mesh{bounds: {{-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0}}, mode: :triangles} = mesh
    end
  end

  describe "indexed?/1" do
    test "true when index_count is positive" do
      assert Mesh.indexed?(Mesh.new(vao: 1, index_count: 6))
      refute Mesh.indexed?(Mesh.new(vao: 1, vertex_count: 3))
      refute Mesh.indexed?(Mesh.new(vao: 1, index_count: 0))
    end
  end

  describe "gl_mode/1" do
    test "maps atoms and passes integers through" do
      assert Mesh.gl_mode(Mesh.new(mode: :triangles)) == @gl_triangles
      assert Mesh.gl_mode(Mesh.new(mode: :triangle_strip)) == @gl_triangle_strip
      assert Mesh.gl_mode(Mesh.new(mode: :lines)) == @gl_lines
      assert Mesh.gl_mode(Mesh.new(mode: @gl_triangle_fan)) == @gl_triangle_fan
    end
  end

  describe "gl_index_type/1" do
    test "defaults to unsigned int" do
      assert Mesh.gl_index_type(Mesh.new()) == @gl_unsigned_int
      assert Mesh.gl_index_type(Mesh.new(index_type: :unsigned_short)) == @gl_unsigned_short
      assert Mesh.gl_index_type(Mesh.new(index_type: @gl_unsigned_byte)) == @gl_unsigned_byte
    end
  end

  describe "with_program/2" do
    test "sets program on maps and structs" do
      assert %Mesh{program: 9} = Mesh.with_program(%{vao: 1, vertex_count: 3}, 9)
      assert %Mesh{program: 9} = Mesh.with_program(Mesh.new(vao: 1), 9)
    end
  end
end
