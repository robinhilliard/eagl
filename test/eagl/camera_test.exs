defmodule EAGL.CameraTest do
  use ExUnit.Case, async: true
  import EAGL.Math
  alias EAGL.Camera

  # Helper function for floating point comparison
  defp assert_float_equal(a, b, tolerance \\ 1.0e-6) do
    assert abs(a - b) < tolerance, "Expected #{a} to be approximately equal to #{b}"
  end

  defp assert_vec3_equal([{x1, y1, z1}], [{x2, y2, z2}], tolerance \\ 1.0e-6) do
    assert_float_equal(x1, x2, tolerance)
    assert_float_equal(y1, y2, tolerance)
    assert_float_equal(z1, z2, tolerance)
  end

  # Helper function to assert matrix equality with tolerance
  defp assert_mat4_equal(mat1, mat2, tolerance \\ 1.0e-6) do
    [{a1, b1, c1, d1, e1, f1, g1, h1, i1, j1, k1, l1, m1, n1, o1, p1}] = mat1
    [{a2, b2, c2, d2, e2, f2, g2, h2, i2, j2, k2, l2, m2, n2, o2, p2}] = mat2

    assert_float_equal(a1, a2, tolerance)
    assert_float_equal(b1, b2, tolerance)
    assert_float_equal(c1, c2, tolerance)
    assert_float_equal(d1, d2, tolerance)
    assert_float_equal(e1, e2, tolerance)
    assert_float_equal(f1, f2, tolerance)
    assert_float_equal(g1, g2, tolerance)
    assert_float_equal(h1, h2, tolerance)
    assert_float_equal(i1, i2, tolerance)
    assert_float_equal(j1, j2, tolerance)
    assert_float_equal(k1, k2, tolerance)
    assert_float_equal(l1, l2, tolerance)
    assert_float_equal(m1, m2, tolerance)
    assert_float_equal(n1, n2, tolerance)
    assert_float_equal(o1, o2, tolerance)
    assert_float_equal(p1, p2, tolerance)
  end

  describe "new/1" do
    test "creates camera with default parameters" do
      camera = Camera.new()

      # Default position
      assert camera.position == [{0.0, 0.0, 0.0}]

      # Default angles
      assert_float_equal(camera.yaw, -90.0)
      assert_float_equal(camera.pitch, 0.0)

      # Default settings
      assert_float_equal(camera.movement_speed, 2.5)
      assert_float_equal(camera.mouse_sensitivity, 0.1)  # Default mouse sensitivity
      assert_float_equal(camera.zoom, 45.0)

      # Default world up
      assert camera.world_up == [{0.0, 1.0, 0.0}]

      # Computed vectors should be initialized
      assert_vec3_equal(camera.front, [{0.0, 0.0, -1.0}])
      assert_vec3_equal(camera.up, [{0.0, 1.0, 0.0}])
      assert_vec3_equal(camera.right, [{1.0, 0.0, 0.0}])
    end

    test "creates camera with custom position" do
      position = vec3(5.0, 2.0, 10.0)
      camera = Camera.new(position: position)

      assert camera.position == position
      # Other parameters should be defaults
      assert_float_equal(camera.yaw, -90.0)
      assert_float_equal(camera.pitch, 0.0)
    end

    test "creates camera with custom angles" do
      camera = Camera.new(yaw: 0.0, pitch: 30.0)

      assert_float_equal(camera.yaw, 0.0)
      assert_float_equal(camera.pitch, 30.0)

      # Front vector should be recalculated
      # For yaw=0, pitch=30: front should point roughly in +X direction with upward tilt
      [{fx, fy, _fz}] = camera.front
      assert fx > 0.8  # Should be mostly in +X direction for yaw=0
      assert fy > 0.4  # Should have upward component for pitch=30
    end

    test "creates camera with all custom parameters" do
      opts = [
        position: vec3(1.0, 2.0, 3.0),
        world_up: vec3(0.0, 0.0, 1.0),
        yaw: 45.0,
        pitch: -15.0,
        movement_speed: 5.0,
        mouse_sensitivity: 0.2,
        zoom: 60.0
      ]

      camera = Camera.new(opts)

      assert camera.position == vec3(1.0, 2.0, 3.0)
      assert camera.world_up == vec3(0.0, 0.0, 1.0)
      assert_float_equal(camera.yaw, 45.0)
      assert_float_equal(camera.pitch, -15.0)
      assert_float_equal(camera.movement_speed, 5.0)
      assert_float_equal(camera.mouse_sensitivity, 0.2)
      assert_float_equal(camera.zoom, 60.0)
    end

    test "properly calculates camera vectors" do
      # Test with known angles
      camera = Camera.new(yaw: 0.0, pitch: 0.0)

      # For yaw=0, pitch=0, front should be (1, 0, 0)
      assert_vec3_equal(camera.front, [{1.0, 0.0, 0.0}])

      # Right should be cross(front, world_up) = cross((1,0,0), (0,1,0)) = (0,0,1)
      assert_vec3_equal(camera.right, [{0.0, 0.0, 1.0}])

      # Up should be cross(right, front) = cross((0,0,1), (1,0,0)) = (0,1,0)
      assert_vec3_equal(camera.up, [{0.0, 1.0, 0.0}])
    end
  end

  describe "get_view_matrix/1" do
    test "creates view matrix for default camera" do
      camera = Camera.new()
      view_matrix = Camera.get_view_matrix(camera)

      # Should be a valid 4x4 matrix
      assert [{_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _}] = view_matrix

      # For a camera at origin looking down -Z axis, this should match mat4_look_at result
      target = vec_add(camera.position, camera.front)
      expected = mat4_look_at(camera.position, target, camera.up)

      assert_mat4_equal(view_matrix, expected)
    end

    test "creates view matrix for moved camera" do
      position = vec3(0.0, 0.0, 5.0)
      camera = Camera.new(position: position)
      view_matrix = Camera.get_view_matrix(camera)

      # Camera moved back 5 units, should create appropriate view matrix
      target = vec_add(position, camera.front)
      expected = mat4_look_at(position, target, camera.up)

      assert_mat4_equal(view_matrix, expected)
    end

    test "creates view matrix for rotated camera" do
      camera = Camera.new(yaw: 90.0, pitch: 45.0)
      view_matrix = Camera.get_view_matrix(camera)

      target = vec_add(camera.position, camera.front)
      expected = mat4_look_at(camera.position, target, camera.up)

      assert_mat4_equal(view_matrix, expected)
    end
  end

  describe "process_keyboard/3" do
    test "moves camera forward" do
      camera = Camera.new()
      delta_time = 1.0

      moved_camera = Camera.process_keyboard(camera, :forward, delta_time)

      # Should move in front direction by movement_speed * delta_time
      expected_displacement = vec_scale(camera.front, camera.movement_speed * delta_time)
      expected_position = vec_add(camera.position, expected_displacement)

      assert_vec3_equal(moved_camera.position, expected_position)
    end

    test "moves camera backward" do
      camera = Camera.new()
      delta_time = 0.5

      moved_camera = Camera.process_keyboard(camera, :backward, delta_time)

      # Should move opposite to front direction
      expected_displacement = vec_scale(camera.front, camera.movement_speed * delta_time)
      expected_position = vec_sub(camera.position, expected_displacement)

      assert_vec3_equal(moved_camera.position, expected_position)
    end

    test "moves camera left (strafe)" do
      camera = Camera.new()
      delta_time = 1.0

      moved_camera = Camera.process_keyboard(camera, :left, delta_time)

      # Should move opposite to right direction
      expected_displacement = vec_scale(camera.right, camera.movement_speed * delta_time)
      expected_position = vec_sub(camera.position, expected_displacement)

      assert_vec3_equal(moved_camera.position, expected_position)
    end

    test "moves camera right (strafe)" do
      camera = Camera.new()
      delta_time = 2.0

      moved_camera = Camera.process_keyboard(camera, :right, delta_time)

      # Should move in right direction
      expected_displacement = vec_scale(camera.right, camera.movement_speed * delta_time)
      expected_position = vec_add(camera.position, expected_displacement)

      assert_vec3_equal(moved_camera.position, expected_position)
    end

    test "respects custom movement speed" do
      speed = 10.0
      camera = Camera.new(movement_speed: speed)
      delta_time = 0.1

      moved_camera = Camera.process_keyboard(camera, :forward, delta_time)

      expected_displacement = vec_scale(camera.front, speed * delta_time)
      expected_position = vec_add(camera.position, expected_displacement)

      assert_vec3_equal(moved_camera.position, expected_position)
    end

        test "movement scales with delta time" do
      camera = Camera.new()

      # Movement with different delta times should scale proportionally
      moved_1s = Camera.process_keyboard(camera, :forward, 1.0)
      moved_2s = Camera.process_keyboard(camera, :forward, 2.0)

      # Position difference should be twice as much for 2x delta time
      diff_1s = vec_sub(moved_1s.position, camera.position)
      diff_2s = vec_sub(moved_2s.position, camera.position)

      # diff_2s should be 2x diff_1s
      expected_2x = vec_scale(diff_1s, 2.0)
      assert_vec3_equal(diff_2s, expected_2x)
    end
  end

  describe "process_mouse_movement/4" do
    test "updates yaw with horizontal mouse movement" do
      camera = Camera.new()
      x_offset = 10.0
      y_offset = 0.0

      moved_camera = Camera.process_mouse_movement(camera, x_offset, y_offset)

      # Yaw should increase by x_offset * sensitivity
      expected_yaw = camera.yaw + (x_offset * camera.mouse_sensitivity)
      assert_float_equal(moved_camera.yaw, expected_yaw)

      # Pitch should remain unchanged
      assert_float_equal(moved_camera.pitch, camera.pitch)
    end

    test "updates pitch with vertical mouse movement" do
      camera = Camera.new()
      x_offset = 0.0
      y_offset = 5.0

      moved_camera = Camera.process_mouse_movement(camera, x_offset, y_offset)

      # Pitch should increase by y_offset * sensitivity
      expected_pitch = camera.pitch + (y_offset * camera.mouse_sensitivity)
      assert_float_equal(moved_camera.pitch, expected_pitch)

      # Yaw should remain unchanged
      assert_float_equal(moved_camera.yaw, camera.yaw)
    end

    test "constrains pitch to prevent camera flipping" do
      camera = Camera.new()

      # Large upward movement that would exceed 89° (with sensitivity 0.005, need 18000+ to exceed 89°)
      moved_camera = Camera.process_mouse_movement(camera, 0.0, 20000.0)
      assert_float_equal(moved_camera.pitch, 89.0)

      # Large downward movement that would exceed -89°
      moved_camera = Camera.process_mouse_movement(camera, 0.0, -20000.0)
      assert_float_equal(moved_camera.pitch, -89.0)
    end

    test "allows unconstrained pitch when requested" do
      camera = Camera.new()
      constrain_pitch = false

      # Large movement without constraint (with sensitivity 0.005, need 20000+ to exceed 89°)
      moved_camera = Camera.process_mouse_movement(camera, 0.0, 20000.0, constrain_pitch)

      # Pitch should exceed normal constraints
      expected_pitch = camera.pitch + (20000.0 * camera.mouse_sensitivity)
      assert_float_equal(moved_camera.pitch, expected_pitch)
      assert moved_camera.pitch > 89.0
    end

    test "respects custom mouse sensitivity" do
      sensitivity = 0.05
      camera = Camera.new(mouse_sensitivity: sensitivity)
      x_offset = 20.0
      y_offset = 10.0

      moved_camera = Camera.process_mouse_movement(camera, x_offset, y_offset)

      expected_yaw = camera.yaw + (x_offset * sensitivity)
      expected_pitch = camera.pitch + (y_offset * sensitivity)

      assert_float_equal(moved_camera.yaw, expected_yaw)
      assert_float_equal(moved_camera.pitch, expected_pitch)
    end

    test "updates camera vectors after rotation" do
      camera = Camera.new()

      # Rotate camera 90 degrees to the right (with sensitivity 0.005, need 18000 for 90°)
      moved_camera = Camera.process_mouse_movement(camera, 18000.0, 0.0)

      # Front vector should have changed
      refute moved_camera.front == camera.front

      # Vectors should still be normalized
      front_length = vec_length(moved_camera.front)
      right_length = vec_length(moved_camera.right)
      up_length = vec_length(moved_camera.up)

      assert_float_equal(front_length, 1.0)
      assert_float_equal(right_length, 1.0)
      assert_float_equal(up_length, 1.0)

      # Vectors should be orthogonal
      front_dot_right = dot(moved_camera.front, moved_camera.right)
      front_dot_up = dot(moved_camera.front, moved_camera.up)
      right_dot_up = dot(moved_camera.right, moved_camera.up)

      assert_float_equal(front_dot_right, 0.0, 1.0e-5)
      assert_float_equal(front_dot_up, 0.0, 1.0e-5)
      assert_float_equal(right_dot_up, 0.0, 1.0e-5)
    end
  end

  describe "process_mouse_scroll/2" do
    test "decreases zoom with positive scroll" do
      camera = Camera.new()
      y_offset = 5.0

      scrolled_camera = Camera.process_mouse_scroll(camera, y_offset)

      # Zoom should decrease (narrower field of view)
      expected_zoom = camera.zoom - y_offset
      assert_float_equal(scrolled_camera.zoom, expected_zoom)
    end

        test "increases zoom with negative scroll" do
      camera = Camera.new(zoom: 30.0)  # Start with zoom that can increase
      y_offset = -3.0

      scrolled_camera = Camera.process_mouse_scroll(camera, y_offset)

      # Zoom should increase (wider field of view)
      expected_zoom = camera.zoom - y_offset  # 30.0 - (-3.0) = 33.0
      assert_float_equal(scrolled_camera.zoom, expected_zoom)
    end

    test "constrains zoom to minimum value" do
      camera = Camera.new()

      # Large positive scroll that would make zoom negative
      scrolled_camera = Camera.process_mouse_scroll(camera, 100.0)

      # Zoom should be clamped to 1.0
      assert_float_equal(scrolled_camera.zoom, 1.0)
    end

    test "constrains zoom to maximum value" do
      camera = Camera.new()

      # Large negative scroll that would make zoom very large
      scrolled_camera = Camera.process_mouse_scroll(camera, -100.0)

      # Zoom should be clamped to 45.0
      assert_float_equal(scrolled_camera.zoom, 45.0)
    end

    test "allows zoom within valid range" do
      camera = Camera.new(zoom: 30.0)

      # Small adjustments should work normally
      scrolled_in = Camera.process_mouse_scroll(camera, 5.0)
      assert_float_equal(scrolled_in.zoom, 25.0)

      scrolled_out = Camera.process_mouse_scroll(camera, -5.0)
      assert_float_equal(scrolled_out.zoom, 35.0)
    end
  end

  describe "direct field access" do
    test "camera fields are directly accessible" do
      zoom_value = 60.0
      position = vec3(1.0, 2.0, 3.0)
      yaw_value = 45.0
      pitch_value = 30.0

      camera = Camera.new(
        zoom: zoom_value,
        position: position,
        yaw: yaw_value,
        pitch: pitch_value
      )

      # Test direct field access (idiomatic Elixir)
      assert_float_equal(camera.zoom, zoom_value)
      assert camera.position == position
      assert_float_equal(camera.yaw, yaw_value)
      assert_float_equal(camera.pitch, pitch_value)

      # Test computed vectors are accessible
      assert_float_equal(vec_length(camera.front), 1.0)
      assert_float_equal(vec_length(camera.right), 1.0)
      assert_float_equal(vec_length(camera.up), 1.0)
    end
  end

  describe "edge cases and validation" do
    test "extreme yaw values work correctly" do
      # Test wraparound behavior
      camera = Camera.new(yaw: 370.0)
      assert_float_equal(camera.yaw, 370.0)

      # Camera should still function normally
      moved_camera = Camera.process_mouse_movement(camera, 10.0, 0.0)
      assert moved_camera.front != camera.front
    end

    test "camera vectors remain orthonormal after operations" do
      camera = Camera.new()

      # Apply various transformations
      camera = Camera.process_mouse_movement(camera, 45.0, 30.0)
      camera = Camera.process_keyboard(camera, :forward, 1.0)
      camera = Camera.process_mouse_scroll(camera, 5.0)

      # Vectors should still be normalized
      assert_float_equal(vec_length(camera.front), 1.0, 1.0e-5)
      assert_float_equal(vec_length(camera.right), 1.0, 1.0e-5)
      assert_float_equal(vec_length(camera.up), 1.0, 1.0e-5)

      # Vectors should be orthogonal
      assert_float_equal(dot(camera.front, camera.right), 0.0, 1.0e-5)
      assert_float_equal(dot(camera.front, camera.up), 0.0, 1.0e-5)
      assert_float_equal(dot(camera.right, camera.up), 0.0, 1.0e-5)
    end

        test "camera maintains correct handedness" do
      camera = Camera.new()

      # Right-handed coordinate system: front × up should equal right
      # This is because: right = cross(front, world_up), up = cross(right, front)
      # So: front × up = front × cross(right, front) = -cross(front, right) = -(-right) = right
      cross_result = cross(camera.front, camera.up)

      assert_vec3_equal(cross_result, camera.right, 1.0e-5)
    end

    test "zero delta time movement" do
      camera = Camera.new()

      # Zero delta time should not move camera
      moved_camera = Camera.process_keyboard(camera, :forward, 0.0)

      assert_vec3_equal(moved_camera.position, camera.position)
    end

    test "zero mouse movement" do
      camera = Camera.new()

      # Zero mouse movement should not change camera orientation
      moved_camera = Camera.process_mouse_movement(camera, 0.0, 0.0)

      assert_float_equal(moved_camera.yaw, camera.yaw)
      assert_float_equal(moved_camera.pitch, camera.pitch)
      assert_vec3_equal(moved_camera.front, camera.front)
    end

    test "zero scroll input" do
      camera = Camera.new()

      # Zero scroll should not change zoom
      scrolled_camera = Camera.process_mouse_scroll(camera, 0.0)

      assert_float_equal(scrolled_camera.zoom, camera.zoom)
    end
  end
end
