defmodule EAGL.MathTest do
  use ExUnit.Case, async: true
  import EAGL.Math

  # Helper function for floating point comparison
  defp assert_float_equal(a, b, tolerance \\ 1.0e-6) do
    assert abs(a - b) < tolerance, "Expected #{a} to be approximately equal to #{b}"
  end

  defp assert_vec3_equal([{x1, y1, z1}], [{x2, y2, z2}], tolerance \\ 1.0e-6) do
    assert_float_equal(x1, x2, tolerance)
    assert_float_equal(y1, y2, tolerance)
    assert_float_equal(z1, z2, tolerance)
  end

  defp assert_quat_equal([{x1, y1, z1, w1}], [{x2, y2, z2, w2}], tolerance \\ 1.0e-6) do
    assert_float_equal(x1, x2, tolerance)
    assert_float_equal(y1, y2, tolerance)
    assert_float_equal(z1, z2, tolerance)
    assert_float_equal(w1, w2, tolerance)
  end

  describe "Vector Constructors" do
    test "vec2 constructor" do
      v = vec2(1.0, 2.0)
      assert v == [{1.0, 2.0}]
    end

    test "vec3 constructor" do
      v = vec3(1.0, 2.0, 3.0)
      assert v == [{1.0, 2.0, 3.0}]
    end

    test "vec4 constructor" do
      v = vec4(1.0, 2.0, 3.0, 4.0)
      assert v == [{1.0, 2.0, 3.0, 4.0}]
    end

    test "zero vector constructors" do
      assert vec2_zero() == [{0.0, 0.0}]
      assert vec3_zero() == [{0.0, 0.0, 0.0}]
      assert vec4_zero() == [{0.0, 0.0, 0.0, 0.0}]
    end

    test "unit vector constructors" do
      assert vec3_unit_x() == [{1.0, 0.0, 0.0}]
      assert vec3_unit_y() == [{0.0, 1.0, 0.0}]
      assert vec3_unit_z() == [{0.0, 0.0, 1.0}]
      assert vec3_one() == [{1.0, 1.0, 1.0}]
    end
  end

  describe "Quaternion Constructors" do
    test "quat constructor" do
      q = quat(1.0, 2.0, 3.0, 4.0)
      assert q == [{1.0, 2.0, 3.0, 4.0}]
    end

    test "quat_identity" do
      q = quat_identity()
      assert q == [{0.0, 0.0, 0.0, 1.0}]
    end

    test "quat_from_axis_angle" do
      axis = vec3_unit_z()
      angle = radians(90.0)
      q = quat_from_axis_angle(axis, angle)

      # 90° rotation around Z should give approximately (0, 0, sin(45°), cos(45°))
      expected_z = :math.sin(angle / 2)
      expected_w = :math.cos(angle / 2)

      assert_quat_equal(q, [{0.0, 0.0, expected_z, expected_w}])
    end

    test "quat_from_euler" do
      # Test identity (no rotation)
      q = quat_from_euler(0.0, 0.0, 0.0)
      assert_quat_equal(q, quat_identity())
    end
  end

  describe "Matrix Constructors" do
    test "mat2_identity" do
      m = mat2_identity()
      expected = [{1.0, 0.0, 0.0, 1.0}]
      assert m == expected
    end

    test "mat3_identity" do
      m = mat3_identity()
      expected = [{1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0}]
      assert m == expected
    end

    test "mat4_identity" do
      m = mat4_identity()

      expected = [
        {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      ]

      assert m == expected
    end
  end

  describe "Vector Operations" do
    test "vec_add" do
      v1 = vec3(1.0, 2.0, 3.0)
      v2 = vec3(4.0, 5.0, 6.0)
      result = vec_add(v1, v2)
      assert result == [{5.0, 7.0, 9.0}]
    end

    test "vec_sub" do
      v1 = vec3(4.0, 5.0, 6.0)
      v2 = vec3(1.0, 2.0, 3.0)
      result = vec_sub(v1, v2)
      assert result == [{3.0, 3.0, 3.0}]
    end

    test "vec_scale" do
      v = vec3(1.0, 2.0, 3.0)
      result = vec_scale(v, 2.0)
      assert result == [{2.0, 4.0, 6.0}]
    end

    test "vec_negate" do
      v = vec3(1.0, -2.0, 3.0)
      result = vec_negate(v)
      assert result == [{-1.0, 2.0, -3.0}]
    end

    test "dot product 2D" do
      v1 = vec2(1.0, 2.0)
      v2 = vec2(3.0, 4.0)
      result = dot(v1, v2)
      # 1*3 + 2*4 = 11
      assert_float_equal(result, 11.0)
    end

    test "dot product 3D" do
      v1 = vec3(1.0, 2.0, 3.0)
      v2 = vec3(4.0, 5.0, 6.0)
      result = dot(v1, v2)
      # 1*4 + 2*5 + 3*6 = 32
      assert_float_equal(result, 32.0)
    end

    test "cross product" do
      # X axis
      v1 = vec3(1.0, 0.0, 0.0)
      # Y axis
      v2 = vec3(0.0, 1.0, 0.0)
      result = cross(v1, v2)
      # Should give Z axis
      assert_vec3_equal(result, [{0.0, 0.0, 1.0}])
    end

    test "vec_length" do
      # 3-4-5 triangle
      v = vec3(3.0, 4.0, 0.0)
      result = vec_length(v)
      assert_float_equal(result, 5.0)
    end

    test "length_squared" do
      v = vec3(3.0, 4.0, 0.0)
      result = length_squared(v)
      # 3² + 4² = 25
      assert_float_equal(result, 25.0)
    end

    test "normalize" do
      v = vec3(3.0, 4.0, 0.0)
      result = normalize(v)
      expected_length = vec_length(result)
      assert_float_equal(expected_length, 1.0)
      assert_vec3_equal(result, [{0.6, 0.8, 0.0}])
    end

    test "distance" do
      v1 = vec3(0.0, 0.0, 0.0)
      v2 = vec3(3.0, 4.0, 0.0)
      result = distance(v1, v2)
      assert_float_equal(result, 5.0)
    end

    test "distance_squared" do
      v1 = vec3(0.0, 0.0, 0.0)
      v2 = vec3(3.0, 4.0, 0.0)
      result = distance_squared(v1, v2)
      assert_float_equal(result, 25.0)
    end

    test "vec_lerp" do
      v1 = vec3(0.0, 0.0, 0.0)
      v2 = vec3(10.0, 20.0, 30.0)
      result = vec_lerp(v1, v2, 0.5)
      assert_vec3_equal(result, [{5.0, 10.0, 15.0}])
    end

    test "reflect" do
      # 45° downward
      incident = normalize(vec3(1.0, -1.0, 0.0))
      # Up normal
      normal = vec3(0.0, 1.0, 0.0)
      result = reflect(incident, normal)
      # Should reflect upward
      expected = normalize(vec3(1.0, 1.0, 0.0))
      assert_vec3_equal(result, expected)
    end

    test "angle_between" do
      # X axis
      v1 = vec3(1.0, 0.0, 0.0)
      # Y axis
      v2 = vec3(0.0, 1.0, 0.0)
      result = angle_between(v1, v2)
      # 90 degrees in radians
      expected = :math.pi() / 2
      assert_float_equal(result, expected)
    end

    test "parallel?" do
      v1 = vec3(1.0, 0.0, 0.0)
      # Same direction, different magnitude
      v2 = vec3(2.0, 0.0, 0.0)
      # Perpendicular
      v3 = vec3(0.0, 1.0, 0.0)

      assert parallel?(v1, v2) == true
      assert parallel?(v1, v3) == false
    end

    test "perpendicular?" do
      # X axis
      v1 = vec3(1.0, 0.0, 0.0)
      # Y axis (perpendicular)
      v2 = vec3(0.0, 1.0, 0.0)
      # Same direction
      v3 = vec3(1.0, 0.0, 0.0)

      assert perpendicular?(v1, v2) == true
      assert perpendicular?(v1, v3) == false
    end
  end

  describe "Quaternion Operations" do
    test "quat_normalize" do
      q = quat(1.0, 2.0, 3.0, 4.0)
      result = quat_normalize(q)

      # Check that the magnitude is 1
      [{x, y, z, w}] = result
      magnitude = :math.sqrt(x * x + y * y + z * z + w * w)
      assert_float_equal(magnitude, 1.0)
    end

    test "quat_conjugate" do
      q = quat(1.0, 2.0, 3.0, 4.0)
      result = quat_conjugate(q)
      assert result == [{-1.0, -2.0, -3.0, 4.0}]
    end

    test "quat_mul identity" do
      q = quat(1.0, 2.0, 3.0, 4.0)
      identity = quat_identity()
      result = quat_mul(q, identity)
      assert_quat_equal(result, q)
    end

    test "quat_slerp" do
      q1 = quat_identity()
      q2 = quat_from_axis_angle(vec3_unit_z(), radians(90.0))
      result = quat_slerp(q1, q2, 0.5)

      # Should be halfway between identity and 90° rotation
      expected_angle = radians(45.0)
      expected = quat_from_axis_angle(vec3_unit_z(), expected_angle)
      assert_quat_equal(result, expected)
    end

    test "quat_rotate_vec3" do
      # 90° rotation around Z axis
      q = quat_from_axis_angle(vec3_unit_z(), radians(90.0))
      # X axis
      v = vec3(1.0, 0.0, 0.0)
      result = quat_rotate_vec3(q, v)

      # Should rotate X axis to Y axis
      assert_vec3_equal(result, [{0.0, 1.0, 0.0}], 1.0e-5)
    end

    test "quat_to_mat3" do
      # Identity quaternion should give identity matrix
      q = quat_identity()
      result = quat_to_mat3(q)
      expected = mat3_identity()
      assert result == expected
    end

    test "quat_to_mat4" do
      # Identity quaternion should give identity matrix
      q = quat_identity()
      result = quat_to_mat4(q)
      expected = mat4_identity()
      assert result == expected
    end
  end

  describe "Matrix Operations" do
    test "mat4_mul with identity" do
      m =
        mat4(
          1.0,
          2.0,
          3.0,
          4.0,
          5.0,
          6.0,
          7.0,
          8.0,
          9.0,
          10.0,
          11.0,
          12.0,
          13.0,
          14.0,
          15.0,
          16.0
        )

      identity = mat4_identity()
      result = mat4_mul(m, identity)
      assert result == m
    end

    test "mat4_transpose" do
      m =
        mat4(
          1.0,
          2.0,
          3.0,
          4.0,
          5.0,
          6.0,
          7.0,
          8.0,
          9.0,
          10.0,
          11.0,
          12.0,
          13.0,
          14.0,
          15.0,
          16.0
        )

      result = mat4_transpose(m)

      expected =
        mat4(
          1.0,
          5.0,
          9.0,
          13.0,
          2.0,
          6.0,
          10.0,
          14.0,
          3.0,
          7.0,
          11.0,
          15.0,
          4.0,
          8.0,
          12.0,
          16.0
        )

      assert result == expected
    end

    test "mat4_translate" do
      translation = vec3(10.0, 20.0, 30.0)
      result = mat4_translate(translation)
      # Column-major format: translation is in the 4th column (last 4 elements)
      expected =
        mat4(
          1.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
          10.0,
          20.0,
          30.0,
          1.0
        )

      assert result == expected
    end

    test "mat4_scale" do
      scale_vec = vec3(2.0, 3.0, 4.0)
      result = mat4_scale(scale_vec)

      expected =
        mat4(
          2.0,
          0.0,
          0.0,
          0.0,
          0.0,
          3.0,
          0.0,
          0.0,
          0.0,
          0.0,
          4.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0
        )

      assert result == expected
    end

    test "mat4_rotate_x for 90 degrees" do
      angle = radians(90.0)
      result = mat4_rotate_x(angle)

      # Check key elements (cos(90°) = 0, sin(90°) = 1)
      # Matrix is stored in column-major order: [col0, col1, col2, col3]
      [{a, b, c, _d, _e, f, g, _h, _i, j, k, _l, _m, _n, _o, _p}] = result

      # [0,0] - should be 1
      assert_float_equal(a, 1.0)
      # [1,1] = cos(90°) ≈ 0
      assert_float_equal(f, 0.0, 1.0e-15)
      # [2,1] = sin(90°) = 1 (column-major)
      assert_float_equal(g, 1.0)
      # [1,0] = 0
      assert_float_equal(b, 0.0, 1.0e-15)
      # [2,0] = 0
      assert_float_equal(c, 0.0, 1.0e-15)
      # [1,2] = -sin(90°) = -1 (column-major)
      assert_float_equal(j, -1.0)
      # [2,2] = cos(90°) ≈ 0
      assert_float_equal(k, 0.0, 1.0e-15)
    end

    test "mat4_inverse of identity" do
      identity = mat4_identity()
      result = mat4_inverse(identity)
      assert result == identity
    end

    test "mat4_inverse of translation matrix" do
      translation = vec3(10.0, 20.0, 30.0)
      matrix = mat4_translate(translation)
      inverse = mat4_inverse(matrix)

      # M * M^-1 should equal identity
      product = mat4_mul(matrix, inverse)
      identity = mat4_identity()

      # Check if the product is approximately identity
      assert_matrices_equal(product, identity)
    end

    test "mat4_inverse of scale matrix" do
      scale_vec = vec3(2.0, 3.0, 4.0)
      matrix = mat4_scale(scale_vec)
      inverse = mat4_inverse(matrix)

      # M * M^-1 should equal identity
      product = mat4_mul(matrix, inverse)
      identity = mat4_identity()

      assert_matrices_equal(product, identity)
    end

    test "mat4_inverse of rotation matrix" do
      angle = radians(45.0)
      matrix = mat4_rotate_x(angle)
      inverse = mat4_inverse(matrix)

      # M * M^-1 should equal identity
      product = mat4_mul(matrix, inverse)
      identity = mat4_identity()

      assert_matrices_equal(product, identity)
    end

    test "mat4_inverse of combined transformations" do
      # Create a complex transformation matrix
      translation = mat4_translate(vec3(5.0, 10.0, 15.0))
      rotation = mat4_rotate_y(radians(30.0))
      scale = mat4_scale(vec3(2.0, 1.5, 0.8))

      # Combine transformations: T * R * S
      matrix = translation |> mat4_mul(rotation) |> mat4_mul(scale)
      inverse = mat4_inverse(matrix)

      # M * M^-1 should equal identity
      product = mat4_mul(matrix, inverse)
      identity = mat4_identity()

      assert_matrices_equal(product, identity)
    end

    test "mat4_inverse of singular matrix raises error" do
      # Create a matrix with zero determinant (all elements zero except last)
      singular =
        mat4(
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0
        )

      # Should raise ArithmeticError since the matrix is not invertible
      assert_raise ArithmeticError, "Matrix is not invertible", fn ->
        mat4_inverse(singular)
      end
    end

    test "mat4_inverse preserves orthogonal matrices" do
      # Rotation matrices are orthogonal, so inverse = transpose
      angle = radians(60.0)
      rotation = mat4_rotate_z(angle)
      inverse = mat4_inverse(rotation)
      transpose = mat4_transpose(rotation)

      # For rotation matrices, inverse should equal transpose
      assert_matrices_equal(inverse, transpose)
    end

    test "mat4_inverse of look_at matrix" do
      eye = vec3(10.0, 5.0, 15.0)
      center = vec3(0.0, 0.0, 0.0)
      up = vec3(0.0, 1.0, 0.0)

      view_matrix = mat4_look_at(eye, center, up)
      inverse = mat4_inverse(view_matrix)

      # M * M^-1 should equal identity
      product = mat4_mul(view_matrix, inverse)
      identity = mat4_identity()

      assert_matrices_equal(product, identity)
    end
  end

  # Helper function to compare matrices with floating point tolerance
  defp assert_matrices_equal(
         [{a1, b1, c1, d1, e1, f1, g1, h1, i1, j1, k1, l1, m1, n1, o1, p1}],
         [{a2, b2, c2, d2, e2, f2, g2, h2, i2, j2, k2, l2, m2, n2, o2, p2}],
         tolerance \\ 1.0e-6
       ) do
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

  describe "Utility Functions" do
    test "radians conversion" do
      result = radians(180.0)
      expected = :math.pi()
      assert_float_equal(result, expected)
    end

    test "degrees conversion" do
      result = degrees(:math.pi())
      expected = 180.0
      assert_float_equal(result, expected)
    end

    test "lerp scalar" do
      result = lerp(0.0, 10.0, 0.3)
      assert_float_equal(result, 3.0)
    end

    test "mix" do
      result = mix(5.0, 15.0, 0.5)
      assert_float_equal(result, 10.0)
    end

    test "clamp" do
      assert_float_equal(clamp(15.0, 0.0, 10.0), 10.0)
      assert_float_equal(clamp(-5.0, 0.0, 10.0), 0.0)
      assert_float_equal(clamp(5.0, 0.0, 10.0), 5.0)
    end

    test "sign" do
      assert_float_equal(sign(5.0), 1.0)
      assert_float_equal(sign(-3.0), -1.0)
      assert_float_equal(sign(0.0), 0.0)
    end

    test "abs_val" do
      assert_float_equal(abs_val(-7.5), 7.5)
      assert_float_equal(abs_val(7.5), 7.5)
      assert_float_equal(abs_val(0.0), 0.0)
    end

    test "fract" do
      result = fract(3.14159)
      assert_float_equal(result, 0.14159, 1.0e-5)
    end

    test "mod" do
      result = mod(7.5, 3.0)
      assert_float_equal(result, 1.5)
    end

    test "step" do
      # 7.0 >= 5.0
      assert_float_equal(step(5.0, 7.0), 1.0)
      # 3.0 < 5.0
      assert_float_equal(step(5.0, 3.0), 0.0)
    end

    test "smooth_step" do
      result = smooth_step(0.0, 1.0, 0.5)
      # Should be smooth interpolation
      expected = 0.5
      assert_float_equal(result, expected)

      # Test edge cases
      assert_float_equal(smooth_step(0.0, 1.0, 0.0), 0.0)
      assert_float_equal(smooth_step(0.0, 1.0, 1.0), 1.0)
    end

    test "inverse_sqrt" do
      result = inverse_sqrt(16.0)
      expected = 1.0 / 4.0
      assert_float_equal(result, expected)
    end
  end

  describe "Projection Matrices" do
    test "mat4_perspective" do
      fov = radians(45.0)
      aspect = 16.0 / 9.0
      near = 0.1
      far = 100.0

      result = mat4_perspective(fov, aspect, near, far)

      # Check that it's a valid perspective matrix (non-zero elements in expected positions)
      # Matrix is stored in column-major order: [col0, col1, col2, col3]
      [{a, _b, _c, _d, _e, f, _g, _h, _i, _j, k, l, _m, _n, o, _p}] = result

      # X scaling factor
      assert a > 0.0
      # Y scaling factor
      assert f > 0.0
      # Z scaling factor (should be negative)
      assert k < 0.0
      # Z translation (should be negative) - now in column 3
      assert o < 0.0
      # Perspective divide factor - now in position l
      assert_float_equal(l, -1.0)
    end

    test "mat4_ortho" do
      left = -10.0
      right = 10.0
      bottom = -5.0
      top = 5.0
      near = 0.1
      far = 100.0

      result = mat4_ortho(left, right, bottom, top, near, far)

      # Check key elements of orthographic matrix
      # Matrix is stored as single tuple: [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
      [{a, _b, _c, _d, _e, f, _g, _h, _i, _j, k, _l, _m, _n, _o, p}] = result

      # X scale
      assert_float_equal(a, 2.0 / (right - left))
      # Y scale
      assert_float_equal(f, 2.0 / (top - bottom))
      # Z scale
      assert_float_equal(k, -2.0 / (far - near))
      # Homogeneous coordinate
      assert_float_equal(p, 1.0)
    end

    test "mat4_look_at" do
      eye = vec3(0.0, 0.0, 5.0)
      center = vec3_zero()
      up = vec3_unit_y()

      result = mat4_look_at(eye, center, up)

      # Should be a valid view matrix (last row should be [0,0,0,1])
      # Matrix is stored in column-major order: [col0, col1, col2, col3]
      [{_a, _b, _c, d, _e, _f, _g, h, _i, _j, _k, l, _m, _n, _o, p}] = result

      # Bottom row in column-major: elements d, h, l, p
      assert_float_equal(d, 0.0)
      assert_float_equal(h, 0.0)
      assert_float_equal(l, 0.0)
      assert_float_equal(p, 1.0)
    end
  end

  describe "Edge Cases and Error Conditions" do
    test "normalize zero vector should handle gracefully" do
      zero_vec = vec3_zero()
      # Should not crash, though result may be undefined
      result = normalize(zero_vec)
      # Result should be a valid vec3 (even if NaN)
      assert is_list(result)
      assert length(result) == 1
      [{_, _, _}] = result
    end

    test "division by zero in inverse_sqrt" do
      # Should handle gracefully (may return infinity)
      result = inverse_sqrt(0.0)
      assert is_float(result)
    end

    test "slerp with identical quaternions" do
      q = quat_identity()
      result = quat_slerp(q, q, 0.5)
      assert_quat_equal(result, q)
    end

    test "cross product with parallel vectors" do
      v1 = vec3(1.0, 0.0, 0.0)
      # Parallel
      v2 = vec3(2.0, 0.0, 0.0)
      result = cross(v1, v2)
      assert_vec3_equal(result, vec3_zero())
    end
  end

  describe "Matrix Sigil (~m)" do
    test "creates 2x2 matrix from string" do
      matrix = ~m"""
      1.0 0.0
      0.0 1.0
      """

      expected = mat2_identity()
      assert matrix == expected
    end

    test "creates 2x2 matrix with comments" do
      matrix = ~m"""
      1.0 0.0  # row 1
      0.0 1.0  # row 2 - identity matrix
      """

      expected = mat2_identity()
      assert matrix == expected
    end

    test "creates 3x3 matrix from string" do
      matrix = ~m"""
      1.0 0.0 0.0
      0.0 1.0 0.0
      0.0 0.0 1.0
      """

      expected = mat3_identity()
      assert matrix == expected
    end

    test "creates 3x3 matrix with detailed comments" do
      matrix = ~m"""
      1.0 0.0 0.0  # X axis
      0.0 1.0 0.0  # Y axis
      0.0 0.0 1.0  # Z axis - 3D identity
      """

      expected = mat3_identity()
      assert matrix == expected
    end

    test "creates 4x4 matrix from string" do
      matrix = ~m"""
      1.0 0.0 0.0 0.0
      0.0 1.0 0.0 0.0
      0.0 0.0 1.0 0.0
      0.0 0.0 0.0 1.0
      """

      expected = mat4_identity()
      assert matrix == expected
    end

    test "creates 4x4 transformation matrix with comments" do
      matrix = ~m"""
      1.0 0.0 0.0 5.0  # X axis + translation
      0.0 1.0 0.0 2.0  # Y axis + translation
      0.0 0.0 1.0 1.0  # Z axis + translation
      0.0 0.0 0.0 1.0  # homogeneous coordinate
      """

      expected = [
        {1.0, 0.0, 0.0, 5.0, 0.0, 1.0, 0.0, 2.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0}
      ]

      assert matrix == expected
    end

    test "creates matrix from single line string" do
      matrix = ~m"1.0 0.0 0.0 1.0"
      expected = mat2_identity()
      assert matrix == expected
    end

    test "handles mixed whitespace and comments" do
      matrix = ~m"""

      1.0 0.0  # first row with leading whitespace
         0.0 1.0  # second row with extra spacing

      """

      expected = mat2_identity()
      assert matrix == expected
    end

    test "errors with invalid number of floats (3 floats)" do
      assert_raise ArgumentError, "Invalid matrix size: expected 4, 9, or 16 floats, got 3", fn ->
        ~m"""
        1.0 2.0 3.0
        """
      end
    end

    test "errors with invalid number of floats (5 floats)" do
      assert_raise ArgumentError, "Invalid matrix size: expected 4, 9, or 16 floats, got 5", fn ->
        ~m"""
        1.0 2.0 3.0 4.0 5.0
        """
      end
    end

    test "errors with invalid number of floats (10 floats)" do
      assert_raise ArgumentError,
                   "Invalid matrix size: expected 4, 9, or 16 floats, got 10",
                   fn ->
                     ~m"""
                     1.0 2.0 3.0 4.0 5.0
                     6.0 7.0 8.0 9.0 10.0
                     """
                   end
    end

    test "errors with invalid number of floats (17 floats)" do
      assert_raise ArgumentError,
                   "Invalid matrix size: expected 4, 9, or 16 floats, got 17",
                   fn ->
                     ~m"""
                     1.0 2.0 3.0 4.0
                     5.0 6.0 7.0 8.0
                     9.0 10.0 11.0 12.0
                     13.0 14.0 15.0 16.0 17.0
                     """
                   end
    end
  end

  describe "Vertex Sigil (~v)" do
    test "creates simple vertex data from string" do
      vertices = ~v"""
      0.0 0.5 0.0
      -0.5 -0.5 0.0
      0.5 -0.5 0.0
      """

      expected = [0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0]
      assert vertices == expected
    end

    test "creates vertex data with comments" do
      vertices = ~v"""
      0.0  0.5 0.0   # top vertex
      -0.5 -0.5 0.0  # bottom left
      0.5  -0.5 0.0  # bottom right - triangle complete
      """

      expected = [0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0]
      assert vertices == expected
    end

    test "creates quad vertices with texture coordinates and comments" do
      vertices = ~v"""
      # Position    # Texture coords
      -1.0  1.0 0.0  0.0 1.0  # top left
       1.0  1.0 0.0  1.0 1.0  # top right
       1.0 -1.0 0.0  1.0 0.0  # bottom right
      -1.0 -1.0 0.0  0.0 0.0  # bottom left
      """

      expected = [
        -1.0,
        1.0,
        0.0,
        0.0,
        1.0,
        1.0,
        1.0,
        0.0,
        1.0,
        1.0,
        1.0,
        -1.0,
        0.0,
        1.0,
        0.0,
        -1.0,
        -1.0,
        0.0,
        0.0,
        0.0
      ]

      assert vertices == expected
    end

    test "creates color data with comments" do
      colors = ~v"""
      1.0 0.0 0.0  # red
      0.0 1.0 0.0  # green
      0.0 0.0 1.0  # blue
      """

      expected = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]
      assert colors == expected
    end

    test "creates vertex data from single line" do
      vertices = ~v"0.0 0.5 0.0  -0.5 -0.5 0.0  0.5 -0.5 0.0"
      expected = [0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0]
      assert vertices == expected
    end

    test "handles mixed whitespace and comments" do
      vertices = ~v"""

      1.0 2.0 3.0  # first vertex with leading whitespace
         4.0 5.0 6.0  # second vertex with extra spacing

      """

      expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
      assert vertices == expected
    end

    test "handles empty lines and comment-only lines" do
      vertices = ~v"""
      1.0 2.0 3.0
      # This is a comment-only line

      4.0 5.0 6.0
      # Another comment
      """

      expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
      assert vertices == expected
    end

    test "creates empty list from empty string" do
      vertices = ~v""
      assert vertices == []
    end

    test "creates empty list from comments only" do
      vertices = ~v"""
      # Just comments here
      # No actual vertex data
      """

      assert vertices == []
    end
  end

  describe "Index Sigil (~i)" do
    test "creates simple triangle indices" do
      indices = ~i"""
      0 1 2
      """

      expected = [0, 1, 2]
      assert indices == expected
    end

    test "creates quad indices with comments" do
      indices = ~i"""
      0 1 2  # first triangle
      2 3 0  # second triangle
      """

      expected = [0, 1, 2, 2, 3, 0]
      assert indices == expected
    end

    test "creates cube indices with detailed comments" do
      indices = ~i"""
      # Front face
      0 1 2  2 3 0
      # Back face
      4 5 6  6 7 4
      # Left face
      7 3 0  0 4 7
      """

      expected = [0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 7, 3, 0, 0, 4, 7]
      assert indices == expected
    end

    test "creates triangle strip indices with comments" do
      indices = ~i"""
      0 1 2   # first triangle
      1 3 2   # second triangle (shares edge 1-2)
      2 3 4   # third triangle (shares edge 2-3)
      """

      expected = [0, 1, 2, 1, 3, 2, 2, 3, 4]
      assert indices == expected
    end

    test "creates indices from single line" do
      indices = ~i"0 1 2  2 3 0"
      expected = [0, 1, 2, 2, 3, 0]
      assert indices == expected
    end

    test "handles mixed whitespace and comments" do
      indices = ~i"""

      0 1 2  # first triangle with leading whitespace
         3 4 5  # second triangle with extra spacing

      """

      expected = [0, 1, 2, 3, 4, 5]
      assert indices == expected
    end

    test "handles empty lines and comment-only lines" do
      indices = ~i"""
      0 1 2
      # This is a comment-only line

      3 4 5
      # Another comment
      """

      expected = [0, 1, 2, 3, 4, 5]
      assert indices == expected
    end

    test "creates empty list from empty string" do
      indices = ~i""
      assert indices == []
    end

    test "creates empty list from comments only" do
      indices = ~i"""
      # Just comments here
      # No actual index data
      """

      assert indices == []
    end

    test "errors when floats are provided instead of integers" do
      assert_raise ArgumentError, fn ->
        ~i"""
        0.5 1.0 2.5
        """
      end
    end

    test "errors when mixed integers and floats are provided" do
      assert_raise ArgumentError, fn ->
        ~i"""
        0 1.5 2
        """
      end
    end

    test "errors when non-numeric data is provided" do
      assert_raise ArgumentError, fn ->
        ~i"""
        0 abc 2
        """
      end
    end
  end
end
