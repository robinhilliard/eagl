defmodule EAGL.OrbitCameraTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.{OrbitCamera, Scene, Node}

  describe "new/1" do
    test "creates camera with defaults" do
      cam = OrbitCamera.new()
      assert cam.distance == 5.0
      assert_in_delta cam.camera.yfov, :math.pi() / 4, 0.001
      assert cam.target == [{0.0, 0.0, 0.0}]
      assert cam.mouse_down == false
      assert cam.last_mouse == nil
    end

    test "accepts custom options" do
      cam =
        OrbitCamera.new(
          target: vec3(1.0, 2.0, 3.0),
          distance: 10.0,
          azimuth: 0.0,
          elevation: 0.0
        )

      assert cam.distance == 10.0
      assert cam.target == vec3(1.0, 2.0, 3.0)
      assert cam.azimuth == 0.0
    end
  end

  describe "fit_to_bounds/2" do
    test "centres on bounding box midpoint" do
      cam = OrbitCamera.fit_to_bounds({-2.0, -3.0, -4.0}, {2.0, 3.0, 4.0})
      [{cx, cy, cz}] = cam.target
      assert_in_delta cx, 0.0, 0.001
      assert_in_delta cy, 0.0, 0.001
      assert_in_delta cz, 0.0, 0.001
    end

    test "distance is proportional to diagonal" do
      cam = OrbitCamera.fit_to_bounds({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0})
      diagonal = :math.sqrt(3.0)
      assert_in_delta cam.distance, diagonal * 1.5, 0.01
    end

    test "accepts EAGL vec3 format" do
      cam = OrbitCamera.fit_to_bounds(vec3(-1.0, -1.0, -1.0), vec3(1.0, 1.0, 1.0))
      [{cx, _, _}] = cam.target
      assert_in_delta cx, 0.0, 0.001
    end

    test "accepts flat list format" do
      cam = OrbitCamera.fit_to_bounds([-1.0, -1.0, -1.0], [1.0, 1.0, 1.0])
      [{cx, _, _}] = cam.target
      assert_in_delta cx, 0.0, 0.001
    end

    test "sets near/far based on distance" do
      cam = OrbitCamera.fit_to_bounds({0.0, 0.0, 0.0}, {10.0, 10.0, 10.0})
      assert cam.camera.znear > 0
      assert cam.camera.zfar > cam.distance
    end
  end

  describe "get_position/1" do
    test "position is at distance from target" do
      cam = OrbitCamera.new(target: vec3(0.0, 0.0, 0.0), distance: 10.0)
      [{x, y, z}] = OrbitCamera.get_position(cam)
      actual_distance = :math.sqrt(x * x + y * y + z * z)
      assert_in_delta actual_distance, 10.0, 0.001
    end

    test "position offset by target" do
      cam =
        OrbitCamera.new(
          target: vec3(5.0, 0.0, 0.0),
          distance: 10.0,
          azimuth: 0.0,
          elevation: 0.0
        )

      [{x, _y, z}] = OrbitCamera.get_position(cam)
      assert_in_delta x, 5.0, 0.001
      assert_in_delta z, 10.0, 0.001
    end

    test "elevation moves camera up" do
      cam_low = OrbitCamera.new(distance: 10.0, elevation: 0.0)
      cam_high = OrbitCamera.new(distance: 10.0, elevation: :math.pi() / 4.0)

      [{_, y_low, _}] = OrbitCamera.get_position(cam_low)
      [{_, y_high, _}] = OrbitCamera.get_position(cam_high)

      assert y_high > y_low
    end
  end

  describe "get_view_matrix/1" do
    test "returns a valid mat4" do
      cam = OrbitCamera.new()
      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] = OrbitCamera.get_view_matrix(cam)
      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end
  end

  describe "get_projection_matrix/2" do
    test "returns a valid mat4" do
      cam = OrbitCamera.new()

      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] =
        OrbitCamera.get_projection_matrix(cam, 16.0 / 9.0)

      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end
  end

  describe "orbit/3" do
    test "horizontal drag changes azimuth" do
      cam = OrbitCamera.new(azimuth: 0.0)
      cam2 = OrbitCamera.orbit(cam, 100.0, 0.0)
      assert cam2.azimuth != 0.0
    end

    test "vertical drag changes elevation" do
      cam = OrbitCamera.new(elevation: 0.0)
      cam2 = OrbitCamera.orbit(cam, 0.0, 100.0)
      assert cam2.elevation != 0.0
    end

    test "elevation is clamped to avoid poles" do
      cam = OrbitCamera.new(elevation: 0.0)
      cam_up = OrbitCamera.orbit(cam, 0.0, -100_000.0)
      cam_down = OrbitCamera.orbit(cam, 0.0, 100_000.0)

      max_elev = :math.pi() / 2.0 - 0.01
      assert cam_up.elevation >= -max_elev
      assert cam_down.elevation <= max_elev
    end
  end

  describe "zoom/2" do
    test "positive scroll zooms in" do
      cam = OrbitCamera.new(distance: 10.0)
      cam2 = OrbitCamera.zoom(cam, 1.0)
      assert cam2.distance < cam.distance
    end

    test "negative scroll zooms out" do
      cam = OrbitCamera.new(distance: 10.0)
      cam2 = OrbitCamera.zoom(cam, -1.0)
      assert cam2.distance > cam.distance
    end

    test "distance has a minimum" do
      cam = OrbitCamera.new(distance: 1.0)
      cam2 = OrbitCamera.zoom(cam, 1000.0)
      assert cam2.distance > 0
    end
  end

  describe "mouse interaction" do
    test "handle_mouse_down sets flag" do
      cam = OrbitCamera.new()
      assert cam.mouse_down == false
      cam2 = OrbitCamera.handle_mouse_down(cam)
      assert cam2.mouse_down == true
    end

    test "handle_mouse_up clears flag and last_mouse" do
      cam = %{OrbitCamera.new() | mouse_down: true, last_mouse: {100, 200}}
      cam2 = OrbitCamera.handle_mouse_up(cam)
      assert cam2.mouse_down == false
      assert cam2.last_mouse == nil
    end

    test "handle_mouse_motion orbits when dragging" do
      cam = OrbitCamera.new(azimuth: 0.0, elevation: 0.0)
      cam = OrbitCamera.handle_mouse_down(cam)
      cam = OrbitCamera.handle_mouse_motion(cam, 100, 100)
      cam = OrbitCamera.handle_mouse_motion(cam, 200, 100)

      assert cam.azimuth != 0.0
      assert cam.last_mouse == {200, 100}
    end

    test "handle_mouse_motion only tracks when not dragging" do
      cam = OrbitCamera.new(azimuth: 0.0)
      cam = OrbitCamera.handle_mouse_motion(cam, 100, 100)
      cam = OrbitCamera.handle_mouse_motion(cam, 200, 200)

      assert cam.azimuth == 0.0
      assert cam.last_mouse == {200, 200}
    end
  end

  describe "fit_to_scene/1" do
    test "returns default camera for empty scene" do
      scene = Scene.new()
      cam = OrbitCamera.fit_to_scene(scene)
      assert cam.distance == 5.0
    end

    test "fits to scene with mesh bounds" do
      mesh = %{bounds: {{-100.0, 0.0, -100.0}, {100.0, 200.0, 100.0}}}
      node = Node.new(mesh: mesh)
      scene = Scene.add_root_node(Scene.new(), node)

      cam = OrbitCamera.fit_to_scene(scene)
      [{cx, cy, _cz}] = cam.target
      assert_in_delta cx, 0.0, 0.001
      assert_in_delta cy, 100.0, 0.001
      assert cam.distance > 100.0
    end
  end
end
