defmodule EAGL.CameraTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.Camera

  describe "new/1" do
    test "creates perspective camera with defaults" do
      cam = Camera.new()
      assert cam.type == :perspective
      assert cam.yfov == :math.pi() / 4
      assert cam.znear == 0.1
      assert cam.zfar == 1000.0
      assert cam.aspect_ratio == nil
    end

    test "creates camera with custom options" do
      cam =
        Camera.new(
          position: vec3(1.0, 2.0, 3.0),
          target: vec3(0.0, 0.0, 0.0),
          type: :perspective,
          yfov: :math.pi() / 6,
          znear: 0.01,
          zfar: 500.0
        )

      assert cam.position == vec3(1.0, 2.0, 3.0)
      assert cam.target == vec3(0.0, 0.0, 0.0)
      assert cam.yfov == :math.pi() / 6
      assert cam.znear == 0.01
      assert cam.zfar == 500.0
    end

    test "creates orthographic camera" do
      cam =
        Camera.new(
          type: :orthographic,
          xmag: 2.0,
          ymag: 1.5,
          znear: 0.1,
          zfar: 100.0
        )

      assert cam.type == :orthographic
      assert cam.xmag == 2.0
      assert cam.ymag == 1.5
    end

    test "nil zfar uses large value for mat4_perspective" do
      cam = Camera.new(zfar: nil)
      assert cam.zfar > 1.0e5
    end
  end

  describe "get_view_matrix/1" do
    test "returns valid mat4" do
      cam = Camera.new(position: vec3(0, 0, 5), target: vec3(0, 0, 0))
      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] = Camera.get_view_matrix(cam)
      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end

    test "look-at from +Z toward origin" do
      cam = Camera.new(position: vec3(0, 0, 5), target: vec3(0, 0, 0))
      view = Camera.get_view_matrix(cam)
      # View matrix transforms world to view space; camera at +Z looks at -Z
      # A point at origin in world should be at -Z in view space
      origin_view = mat4_transform_point(view, vec3(0, 0, 0))
      [{_x, _y, z}] = origin_view
      assert z < 0
    end
  end

  describe "get_projection_matrix/2" do
    test "perspective returns valid mat4" do
      cam = Camera.new(type: :perspective)

      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] =
        Camera.get_projection_matrix(cam, 16.0 / 9.0)

      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end

    test "orthographic returns valid mat4" do
      cam = Camera.new(type: :orthographic, xmag: 1.0, ymag: 1.0)

      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] =
        Camera.get_projection_matrix(cam, 16.0 / 9.0)

      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end

    test "uses aspect_ratio param when camera.aspect_ratio is nil" do
      cam = Camera.new(aspect_ratio: nil)
      proj_wide = Camera.get_projection_matrix(cam, 2.0)
      proj_tall = Camera.get_projection_matrix(cam, 0.5)
      assert proj_wide != proj_tall
    end

    test "uses camera.aspect_ratio when set" do
      cam = Camera.new(aspect_ratio: 1.0)
      proj1 = Camera.get_projection_matrix(cam, 2.0)
      proj2 = Camera.get_projection_matrix(cam, 0.5)
      assert proj1 == proj2
    end
  end

  describe "set_position/2 and set_target/2" do
    test "set_position updates position" do
      cam = Camera.new()
      cam2 = Camera.set_position(cam, vec3(10, 20, 30))
      assert cam2.position == vec3(10, 20, 30)
      assert cam.position == vec3(0, 0, 0)
    end

    test "set_target updates target" do
      cam = Camera.new()
      cam2 = Camera.set_target(cam, vec3(1, 1, 1))
      assert cam2.target == vec3(1, 1, 1)
    end
  end
end
