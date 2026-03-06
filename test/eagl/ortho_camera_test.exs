defmodule EAGL.OrthoCameraTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.{OrthoCamera, Scene, Node}

  describe "new/1" do
    test "creates top camera by default" do
      cam = OrthoCamera.new()
      assert cam.axis == :top
      assert cam.half_width == 10.0
      assert cam.camera.type == :orthographic
      [{_, py, _}] = cam.camera.position
      assert py > 0
    end

    test "creates front camera" do
      cam = OrthoCamera.new(axis: :front)
      assert cam.axis == :front
      [{_, _, pz}] = cam.camera.position
      assert pz > 0
    end

    test "creates right camera" do
      cam = OrthoCamera.new(axis: :right)
      assert cam.axis == :right
      [{px, _, _}] = cam.camera.position
      assert px > 0
    end

    test "accepts custom half_width" do
      cam = OrthoCamera.new(half_width: 25.0)
      assert cam.half_width == 25.0
    end

    test "accepts custom position/target/up" do
      cam =
        OrthoCamera.new(
          position: vec3(0.0, 0.0, 50.0),
          target: vec3(0.0, 0.0, 0.0),
          up: vec3(0.0, 1.0, 0.0)
        )

      assert cam.camera.position == vec3(0.0, 0.0, 50.0)
      assert cam.camera.target == vec3(0.0, 0.0, 0.0)
    end
  end

  describe "axis presets" do
    test "top looks down Y axis" do
      cam = OrthoCamera.new(axis: :top)
      [{_, py, _}] = cam.camera.position
      [{_, ty, _}] = cam.camera.target
      assert py > ty
    end

    test "front looks along negative Z" do
      cam = OrthoCamera.new(axis: :front)
      [{_, _, pz}] = cam.camera.position
      [{_, _, tz}] = cam.camera.target
      assert pz > tz
    end

    test "right looks along negative X" do
      cam = OrthoCamera.new(axis: :right)
      [{px, _, _}] = cam.camera.position
      [{tx, _, _}] = cam.camera.target
      assert px > tx
    end
  end

  describe "fit_to_bounds/3" do
    test "centres on bounding box midpoint" do
      cam = OrthoCamera.fit_to_bounds({-2.0, -3.0, -4.0}, {2.0, 3.0, 4.0}, :top)
      [{tx, ty, tz}] = cam.camera.target
      assert_in_delta tx, 0.0, 0.001
      assert_in_delta ty, 0.0, 0.001
      assert_in_delta tz, 0.0, 0.001
    end

    test "half_width covers the scene extent" do
      cam = OrthoCamera.fit_to_bounds({0.0, 0.0, 0.0}, {10.0, 5.0, 8.0}, :top)
      assert cam.half_width > 4.0
    end

    test "front view fits X/Y extent" do
      cam = OrthoCamera.fit_to_bounds({-5.0, -3.0, -1.0}, {5.0, 3.0, 1.0}, :front)
      assert cam.half_width >= 5.0 * 1.1 - 0.01
    end

    test "right view fits Y/Z extent" do
      cam = OrthoCamera.fit_to_bounds({-1.0, -4.0, -6.0}, {1.0, 4.0, 6.0}, :right)
      assert cam.half_width >= 6.0 * 1.1 - 0.01
    end

    test "accepts EAGL vec3 format" do
      cam = OrthoCamera.fit_to_bounds(vec3(-1.0, -1.0, -1.0), vec3(1.0, 1.0, 1.0), :top)
      [{tx, _, _}] = cam.camera.target
      assert_in_delta tx, 0.0, 0.001
    end
  end

  describe "fit_to_scene/2" do
    test "returns default camera for empty scene" do
      cam = OrthoCamera.fit_to_scene(Scene.new(), :front)
      assert cam.half_width == 10.0
    end

    test "fits to scene with mesh bounds" do
      mesh = %{bounds: {{-10.0, 0.0, -10.0}, {10.0, 20.0, 10.0}}}
      node = Node.new(mesh: mesh)
      scene = Scene.add_root_node(Scene.new(), node)

      cam = OrthoCamera.fit_to_scene(scene, :top)
      assert cam.half_width > 5.0
    end
  end

  describe "get_view_matrix/1" do
    test "returns a valid mat4" do
      cam = OrthoCamera.new()
      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] = OrthoCamera.get_view_matrix(cam)
      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end
  end

  describe "get_projection_matrix/2" do
    test "returns a valid mat4" do
      cam = OrthoCamera.new()

      [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}] =
        OrthoCamera.get_projection_matrix(cam, 16.0 / 9.0)

      values = [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      assert Enum.all?(values, &is_float/1)
    end

    test "aspect ratio affects horizontal extent" do
      cam = OrthoCamera.new(half_width: 10.0)

      [{a1, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}] =
        OrthoCamera.get_projection_matrix(cam, 1.0)

      [{a2, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}] =
        OrthoCamera.get_projection_matrix(cam, 2.0)

      assert a1 != a2
    end
  end

  describe "zoom/2" do
    test "positive scroll zooms in" do
      cam = OrthoCamera.new(half_width: 10.0)
      cam2 = OrthoCamera.zoom(cam, 1.0)
      assert cam2.half_width < cam.half_width
    end

    test "negative scroll zooms out" do
      cam = OrthoCamera.new(half_width: 10.0)
      cam2 = OrthoCamera.zoom(cam, -1.0)
      assert cam2.half_width > cam.half_width
    end

    test "half_width has a minimum" do
      cam = OrthoCamera.new(half_width: 0.1)
      cam2 = OrthoCamera.zoom(cam, 100.0)
      assert cam2.half_width > 0
    end
  end

  describe "pan/3" do
    test "panning shifts both position and target" do
      cam = OrthoCamera.new(axis: :front)
      [{px, _, _}] = cam.camera.position
      [{tx, _, _}] = cam.camera.target

      cam2 = OrthoCamera.pan(cam, 100.0, 0.0)
      [{px2, _, _}] = cam2.camera.position
      [{tx2, _, _}] = cam2.camera.target

      assert px2 != px
      assert tx2 != tx
      # Position and target shift by the same amount
      assert_in_delta px2 - px, tx2 - tx, 0.0001
    end
  end

  describe "mouse interaction" do
    test "left drag pans" do
      cam = OrthoCamera.new(axis: :front)
      cam = OrthoCamera.handle_mouse_down(cam)
      cam = OrthoCamera.handle_mouse_motion(cam, 100, 100)
      [{tx1, _, _}] = cam.camera.target
      cam = OrthoCamera.handle_mouse_motion(cam, 200, 100)
      [{tx2, _, _}] = cam.camera.target

      assert tx2 != tx1
    end

    test "mouse up clears state" do
      cam = OrthoCamera.new()
      cam = OrthoCamera.handle_mouse_down(cam)
      cam = OrthoCamera.handle_mouse_motion(cam, 100, 100)
      cam = OrthoCamera.handle_mouse_up(cam)
      assert cam.mouse_down == false
      assert cam.last_mouse == nil
    end

    test "no drag when not pressed" do
      cam = OrthoCamera.new(axis: :front)
      [{tx1, _, _}] = cam.camera.target
      cam = OrthoCamera.handle_mouse_motion(cam, 100, 100)
      cam = OrthoCamera.handle_mouse_motion(cam, 200, 200)
      [{tx2, _, _}] = cam.camera.target
      assert tx1 == tx2
    end
  end
end
