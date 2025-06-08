defmodule EAGL.Math do
  @moduledoc """
  Port of the OpenGL GLM header files to Elixir macros.
  """
  defmacro __using__(_opts) do
    quote do
      @type vec2 :: [{float(), float()}]
      @type vec3 :: [{float(), float(), float()}]
      @type vec4 :: [{float(), float(), float(), float()}]
      @type quat :: [{float(), float(), float(), float()}]

      @type mat2 :: [
        {float(), float(),
         float(), float()}
      ]

      @type mat3 :: [
        {float(), float(), float(),
         float(), float(), float(),
         float(), float(), float()}]

      @type mat4 :: [
        {float(), float(), float(), float(),
        float(), float(), float(), float(),
        float(), float(), float(), float(),
        float(), float(), float(), float()}
      ]


      @doc """
      Create a 2x2 matrix.
      """
      defmacro mat2(a, b, c, d) do
        quote do: [{unquote(a), unquote(b),
                    unquote(c), unquote(d)}]
      end

      @doc """
      Create a 3x3 matrix.
      """
      defmacro mat3(a, b, c, d, e, f, g, h, i) do
        quote do: [{unquote(a), unquote(b), unquote(c),
                    unquote(d), unquote(e), unquote(f),
                    unquote(g), unquote(h), unquote(i)}]
      end

      @doc """
      Create a 4x4 matrix.
      """
      defmacro mat4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) do
        quote do: [{unquote(a), unquote(b), unquote(c), unquote(d),
                    unquote(e), unquote(f), unquote(g), unquote(h),
                    unquote(i), unquote(j), unquote(k), unquote(l),
                    unquote(m), unquote(n), unquote(o), unquote(p)}]
      end

      @doc """
      Create a 2D vector.
      """
      defmacro vec2(x, y) do
        quote do: [{unquote(x), unquote(y)}]
      end

      @doc """
      Create a 3D vector.
      """
      defmacro vec3(x, y, z) do
        quote do: [{unquote(x), unquote(y), unquote(z)}]
      end

      @doc """
      Create a 4D vector.
      """
      defmacro vec4(x, y, z, w) do
        quote do: [{unquote(x), unquote(y), unquote(z), unquote(w)}]
      end

      @doc """
      Create a quaternion.
      Quaternions are represented as {x, y, z, w} where w is the scalar component.
      This follows the (x, y, z, w) convention commonly used in graphics programming.
      """
      defmacro quat(x, y, z, w) do
        quote do: [{unquote(x), unquote(y), unquote(z), unquote(w)}]
      end

      @doc """
      Create an identity quaternion (no rotation).
      """
      defmacro quat_identity() do
        quote do: [{0.0, 0.0, 0.0, 1.0}]
      end

      # Common vector constructors

      @doc """
      Create a zero vector (2D).
      """
      defmacro vec2_zero() do
        quote do: [{0.0, 0.0}]
      end

      @doc """
      Create a zero vector (3D).
      """
      defmacro vec3_zero() do
        quote do: [{0.0, 0.0, 0.0}]
      end

      @doc """
      Create a zero vector (4D).
      """
      defmacro vec4_zero() do
        quote do: [{0.0, 0.0, 0.0, 0.0}]
      end

      @doc """
      Create a 3D vector with all components set to 1.
      """
      defmacro vec3_one() do
        quote do: [{1.0, 1.0, 1.0}]
      end

      @doc """
      Create the X unit vector (1, 0, 0).
      """
      defmacro vec3_unit_x() do
        quote do: [{1.0, 0.0, 0.0}]
      end

      @doc """
      Create the Y unit vector (0, 1, 0).
      """
      defmacro vec3_unit_y() do
        quote do: [{0.0, 1.0, 0.0}]
      end

      @doc """
      Create the Z unit vector (0, 0, 1).
      """
      defmacro vec3_unit_z() do
        quote do: [{0.0, 0.0, 1.0}]
      end

      # Common matrix constructors

      @doc """
      Create a 4x4 identity matrix.
      """
      defmacro mat4_identity() do
        quote do: [{1.0, 0.0, 0.0, 0.0,
                    0.0, 1.0, 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0,
                    0.0, 0.0, 0.0, 1.0}]
      end

      @doc """
      Create a 3x3 identity matrix.
      """
      defmacro mat3_identity() do
        quote do: [{1.0, 0.0, 0.0,
                    0.0, 1.0, 0.0,
                    0.0, 0.0, 1.0}]
      end

      @doc """
      Create a 2x2 identity matrix.
      """
      defmacro mat2_identity() do
        quote do: [{1.0, 0.0,
                    0.0, 1.0}]
      end

      # ============================================================================
      # VECTOR OPERATIONS
      # ============================================================================

      @doc """
      Compute the dot product of two 2D vectors.
      """
      @spec dot(vec2(), vec2()) :: float()
      def dot([{x1, y1}], [{x2, y2}]) do
        x1 * x2 + y1 * y2
      end

      @doc """
      Compute the dot product of two 3D vectors.
      """
      @spec dot(vec3(), vec3()) :: float()
      def dot([{x1, y1, z1}], [{x2, y2, z2}]) do
        x1 * x2 + y1 * y2 + z1 * z2
      end

      @doc """
      Compute the dot product of two 4D vectors.
      """
      @spec dot(vec4(), vec4()) :: float()
      def dot([{x1, y1, z1, w1}], [{x2, y2, z2, w2}]) do
        x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
      end

      @doc """
      Compute the cross product of two 3D vectors.
      """
      @spec cross(vec3(), vec3()) :: vec3()
      def cross([{x1, y1, z1}], [{x2, y2, z2}]) do
        [{y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2}]
      end

      @doc """
      Compute the length (magnitude) of a 2D vector.
      """
      @spec vec_length(vec2()) :: float()
      def vec_length([{x, y}]) do
        :math.sqrt(x * x + y * y)
      end

      @doc """
      Compute the length (magnitude) of a 3D vector.
      """
      @spec vec_length(vec3()) :: float()
      def vec_length([{x, y, z}]) do
        :math.sqrt(x * x + y * y + z * z)
      end

      @doc """
      Compute the length (magnitude) of a 4D vector.
      """
      @spec vec_length(vec4()) :: float()
      def vec_length([{x, y, z, w}]) do
        :math.sqrt(x * x + y * y + z * z + w * w)
      end

      @doc """
      Compute the squared length of a vector (avoids sqrt for performance).
      """
      @spec length_squared(vec2()) :: float()
      def length_squared([{x, y}]) do
        x * x + y * y
      end

      @spec length_squared(vec3()) :: float()
      def length_squared([{x, y, z}]) do
        x * x + y * y + z * z
      end

      @spec length_squared(vec4()) :: float()
      def length_squared([{x, y, z, w}]) do
        x * x + y * y + z * z + w * w
      end

      @doc """
      Normalize a 2D vector to unit length.
      """
      @spec normalize(vec2()) :: vec2()
      def normalize([{x, y}]) do
        len = :math.sqrt(x * x + y * y)
        if len == 0.0, do: [{0.0, 0.0}], else: [{x / len, y / len}]
      end

      @doc """
      Normalize a 3D vector to unit length.
      """
      @spec normalize(vec3()) :: vec3()
      def normalize([{x, y, z}]) do
        len = :math.sqrt(x * x + y * y + z * z)
        if len == 0.0, do: [{0.0, 0.0, 0.0}], else: [{x / len, y / len, z / len}]
      end

      @doc """
      Normalize a 4D vector to unit length.
      """
      @spec normalize(vec4()) :: vec4()
      def normalize([{x, y, z, w}]) do
        len = :math.sqrt(x * x + y * y + z * z + w * w)
        if len == 0.0, do: [{0.0, 0.0, 0.0, 0.0}], else: [{x / len, y / len, z / len, w / len}]
      end

      @doc """
      Add two vectors component-wise.
      """
      @spec vec_add(vec2(), vec2()) :: vec2()
      def vec_add([{x1, y1}], [{x2, y2}]) do
        [{x1 + x2, y1 + y2}]
      end

      @spec vec_add(vec3(), vec3()) :: vec3()
      def vec_add([{x1, y1, z1}], [{x2, y2, z2}]) do
        [{x1 + x2, y1 + y2, z1 + z2}]
      end

      @spec vec_add(vec4(), vec4()) :: vec4()
      def vec_add([{x1, y1, z1, w1}], [{x2, y2, z2, w2}]) do
        [{x1 + x2, y1 + y2, z1 + z2, w1 + w2}]
      end

      @doc """
      Subtract two vectors component-wise.
      """
      @spec vec_sub(vec2(), vec2()) :: vec2()
      def vec_sub([{x1, y1}], [{x2, y2}]) do
        [{x1 - x2, y1 - y2}]
      end

      @spec vec_sub(vec3(), vec3()) :: vec3()
      def vec_sub([{x1, y1, z1}], [{x2, y2, z2}]) do
        [{x1 - x2, y1 - y2, z1 - z2}]
      end

      @spec vec_sub(vec4(), vec4()) :: vec4()
      def vec_sub([{x1, y1, z1, w1}], [{x2, y2, z2, w2}]) do
        [{x1 - x2, y1 - y2, z1 - z2, w1 - w2}]
      end

      @doc """
      Multiply a vector by a scalar.
      """
      @spec vec_scale(vec2(), float()) :: vec2()
      def vec_scale([{x, y}], s) do
        [{x * s, y * s}]
      end

      @spec vec_scale(vec3(), float()) :: vec3()
      def vec_scale([{x, y, z}], s) do
        [{x * s, y * s, z * s}]
      end

      @spec vec_scale(vec4(), float()) :: vec4()
      def vec_scale([{x, y, z, w}], s) do
        [{x * s, y * s, z * s, w * s}]
      end

      @doc """
      Negate a vector (multiply by -1).
      """
      @spec vec_negate(vec2()) :: vec2()
      def vec_negate([{x, y}]) do
        [{-x, -y}]
      end

      @spec vec_negate(vec3()) :: vec3()
      def vec_negate([{x, y, z}]) do
        [{-x, -y, -z}]
      end

      @spec vec_negate(vec4()) :: vec4()
      def vec_negate([{x, y, z, w}]) do
        [{-x, -y, -z, -w}]
      end

      @doc """
      Calculate the distance between two points (vectors).
      """
      @spec distance(vec2(), vec2()) :: float()
      @spec distance(vec3(), vec3()) :: float()
      @spec distance(vec4(), vec4()) :: float()
      def distance(v1, v2) do
        v1 |> vec_sub(v2) |> vec_length()
      end

      @doc """
      Calculate the squared distance between two points (avoids sqrt).
      """
      @spec distance_squared(vec2(), vec2()) :: float()
      @spec distance_squared(vec3(), vec3()) :: float()
      @spec distance_squared(vec4(), vec4()) :: float()
      def distance_squared(v1, v2) do
        v1 |> vec_sub(v2) |> length_squared()
      end

      @doc """
      Linear interpolation between two vectors.
      """
      @spec vec_lerp(vec2(), vec2(), float()) :: vec2()
      def vec_lerp([{x1, y1}], [{x2, y2}], t) do
        [{x1 + t * (x2 - x1), y1 + t * (y2 - y1)}]
      end

      @spec vec_lerp(vec3(), vec3(), float()) :: vec3()
      def vec_lerp([{x1, y1, z1}], [{x2, y2, z2}], t) do
        [{x1 + t * (x2 - x1), y1 + t * (y2 - y1), z1 + t * (z2 - z1)}]
      end

      @spec vec_lerp(vec4(), vec4(), float()) :: vec4()
      def vec_lerp([{x1, y1, z1, w1}], [{x2, y2, z2, w2}], t) do
        [{x1 + t * (x2 - x1), y1 + t * (y2 - y1), z1 + t * (z2 - z1), w1 + t * (w2 - w1)}]
      end

      @doc """
      Reflect a vector around a normal.
      """
      @spec reflect(vec3(), vec3()) :: vec3()
      def reflect(incident, normal) do
        d = dot(incident, normal)
        scaled_normal = vec_scale(normal, 2.0 * d)
        vec_sub(incident, scaled_normal)
      end

      @doc """
      Refract a vector around a normal with given refractive index ratio.
      """
      @spec refract(vec3(), vec3(), float()) :: vec3()
      def refract(incident, normal, eta) do
        n_dot_i = dot(normal, incident)
        k = 1.0 - eta * eta * (1.0 - n_dot_i * n_dot_i)

        if k < 0.0 do
          vec3_zero()  # Total internal reflection
        else
          scaled_incident = vec_scale(incident, eta)
          scaled_normal = vec_scale(normal, eta * n_dot_i + :math.sqrt(k))
          vec_sub(scaled_incident, scaled_normal)
        end
      end

      # ============================================================================
      # QUATERNION OPERATIONS
      # ============================================================================

      @doc """
      Multiply two quaternions.
      """
      @spec quat_mul(quat(), quat()) :: quat()
      def quat_mul([{x1, y1, z1, w1}], [{x2, y2, z2, w2}]) do
        [{
          w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
          w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2,
          w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2,
          w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
        }]
      end

      @doc """
      Conjugate a quaternion (negate x, y, z components).
      """
      @spec quat_conjugate(quat()) :: quat()
      def quat_conjugate([{x, y, z, w}]) do
        [{-x, -y, -z, w}]
      end

      @doc """
      Normalize a quaternion.
      """
      @spec quat_normalize(quat()) :: quat()
      def quat_normalize(q) do
        normalize(q)
      end

      @doc """
      Convert quaternion to rotation matrix (3x3).
      """
      @spec quat_to_mat3(quat()) :: mat3()
      def quat_to_mat3([{x, y, z, w}]) do
        x2 = x + x; y2 = y + y; z2 = z + z
        xx = x * x2; xy = x * y2; xz = x * z2
        yy = y * y2; yz = y * z2; zz = z * z2
        wx = w * x2; wy = w * y2; wz = w * z2

        [{
          1.0 - (yy + zz), xy - wz, xz + wy,
          xy + wz, 1.0 - (xx + zz), yz - wx,
          xz - wy, yz + wx, 1.0 - (xx + yy)
        }]
      end

      @doc """
      Convert quaternion to rotation matrix (4x4).
      """
      @spec quat_to_mat4(quat()) :: mat4()
      def quat_to_mat4(q) do
        [{m00, m01, m02, m10, m11, m12, m20, m21, m22}] = quat_to_mat3(q)

        [{
          m00, m01, m02, 0.0,
          m10, m11, m12, 0.0,
          m20, m21, m22, 0.0,
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Spherical linear interpolation between two quaternions.
      """
      @spec quat_slerp(quat(), quat(), float()) :: quat()
      def quat_slerp(q1, q2, t) do
        [{x1, y1, z1, w1}] = quat_normalize(q1)
        [{x2, y2, z2, w2}] = quat_normalize(q2)

        # Compute the cosine of the angle between them
        cos_theta = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2

        # If cos_theta < 0, the interpolation will take the long way around the sphere
        # To fix this, one quat must be negated
        {x2, y2, z2, w2, cos_theta} =
          if cos_theta < 0.0 do
            {-x2, -y2, -z2, -w2, -cos_theta}
          else
            {x2, y2, z2, w2, cos_theta}
          end

        # Perform linear interpolation for very close quaternions
        if cos_theta > 0.9995 do
          # Linear interpolation
          x = x1 + t * (x2 - x1)
          y = y1 + t * (y2 - y1)
          z = z1 + t * (z2 - z1)
          w = w1 + t * (w2 - w1)
          quat_normalize([{x, y, z, w}])
        else
          # Spherical interpolation
          theta = :math.acos(cos_theta)
          sin_theta = :math.sin(theta)

          a = :math.sin((1.0 - t) * theta) / sin_theta
          b = :math.sin(t * theta) / sin_theta

          [{
            a * x1 + b * x2,
            a * y1 + b * y2,
            a * z1 + b * z2,
            a * w1 + b * w2
          }]
        end
      end

      @doc """
      Create a quaternion from axis-angle representation.
      """
      @spec quat_from_axis_angle(vec3(), float()) :: quat()
      def quat_from_axis_angle(axis, angle) do
        [{x, y, z}] = normalize(axis)
        half_angle = angle * 0.5
        s = :math.sin(half_angle)
        c = :math.cos(half_angle)

        [{x * s, y * s, z * s, c}]
      end

      @doc """
      Create a quaternion from Euler angles (pitch, yaw, roll in radians).
      """
      @spec quat_from_euler(float(), float(), float()) :: quat()
      def quat_from_euler(pitch, yaw, roll) do
        half_pitch = pitch * 0.5
        half_yaw = yaw * 0.5
        half_roll = roll * 0.5

        cos_pitch = :math.cos(half_pitch)
        sin_pitch = :math.sin(half_pitch)
        cos_yaw = :math.cos(half_yaw)
        sin_yaw = :math.sin(half_yaw)
        cos_roll = :math.cos(half_roll)
        sin_roll = :math.sin(half_roll)

        [{
          sin_pitch * cos_yaw * cos_roll - cos_pitch * sin_yaw * sin_roll,
          cos_pitch * sin_yaw * cos_roll + sin_pitch * cos_yaw * sin_roll,
          cos_pitch * cos_yaw * sin_roll - sin_pitch * sin_yaw * cos_roll,
          cos_pitch * cos_yaw * cos_roll + sin_pitch * sin_yaw * sin_roll
        }]
      end

      @doc """
      Rotate a 3D vector by a quaternion.
      """
      @spec quat_rotate_vec3(quat(), vec3()) :: vec3()
      def quat_rotate_vec3(q, v) do
        # Convert vector to quaternion
        [{x, y, z}] = v
        vec_quat = [{x, y, z, 0.0}]

        # q * vec_quat * q_conjugate
        q_conj = quat_conjugate(q)
        temp = quat_mul(q, vec_quat)
        [{rx, ry, rz, _}] = quat_mul(temp, q_conj)

        [{rx, ry, rz}]
      end

      # ============================================================================
      # MATRIX OPERATIONS
      # ============================================================================

      @doc """
      Multiply two 4x4 matrices.
      """
      @spec mat4_mul(mat4(), mat4()) :: mat4()
      def mat4_mul(
        [{a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, a30, a31, a32, a33}],
        [{b00, b01, b02, b03, b10, b11, b12, b13, b20, b21, b22, b23, b30, b31, b32, b33}]
      ) do
        [{
          a00*b00 + a01*b10 + a02*b20 + a03*b30,
          a00*b01 + a01*b11 + a02*b21 + a03*b31,
          a00*b02 + a01*b12 + a02*b22 + a03*b32,
          a00*b03 + a01*b13 + a02*b23 + a03*b33,

          a10*b00 + a11*b10 + a12*b20 + a13*b30,
          a10*b01 + a11*b11 + a12*b21 + a13*b31,
          a10*b02 + a11*b12 + a12*b22 + a13*b32,
          a10*b03 + a11*b13 + a12*b23 + a13*b33,

          a20*b00 + a21*b10 + a22*b20 + a23*b30,
          a20*b01 + a21*b11 + a22*b21 + a23*b31,
          a20*b02 + a21*b12 + a22*b22 + a23*b32,
          a20*b03 + a21*b13 + a22*b23 + a23*b33,

          a30*b00 + a31*b10 + a32*b20 + a33*b30,
          a30*b01 + a31*b11 + a32*b21 + a33*b31,
          a30*b02 + a31*b12 + a32*b22 + a33*b32,
          a30*b03 + a31*b13 + a32*b23 + a33*b33
        }]
      end

      @doc """
      Multiply two 3x3 matrices.
      """
      @spec mat3_mul(mat3(), mat3()) :: mat3()
      def mat3_mul(
        [{a00, a01, a02, a10, a11, a12, a20, a21, a22}],
        [{b00, b01, b02, b10, b11, b12, b20, b21, b22}]
      ) do
        [{
          a00*b00 + a01*b10 + a02*b20,
          a00*b01 + a01*b11 + a02*b21,
          a00*b02 + a01*b12 + a02*b22,

          a10*b00 + a11*b10 + a12*b20,
          a10*b01 + a11*b11 + a12*b21,
          a10*b02 + a11*b12 + a12*b22,

          a20*b00 + a21*b10 + a22*b20,
          a20*b01 + a21*b11 + a22*b21,
          a20*b02 + a21*b12 + a22*b22
        }]
      end

      @doc """
      Transpose a 4x4 matrix.
      """
      @spec mat4_transpose(mat4()) :: mat4()
      def mat4_transpose([{m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}]) do
        [{m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33}]
      end

      @doc """
      Transpose a 3x3 matrix.
      """
      @spec mat3_transpose(mat3()) :: mat3()
      def mat3_transpose([{m00, m01, m02, m10, m11, m12, m20, m21, m22}]) do
        [{m00, m10, m20, m01, m11, m21, m02, m12, m22}]
      end

      @doc """
      Create a translation matrix.
      """
      @spec mat4_translate(vec3()) :: mat4()
      def mat4_translate(v) do
        [{x, y, z}] = v
        [{
          1.0, 0.0, 0.0, x,
          0.0, 1.0, 0.0, y,
          0.0, 0.0, 1.0, z,
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Create a scale matrix.
      """
      @spec mat4_scale(vec3()) :: mat4()
      def mat4_scale(v) do
        [{x, y, z}] = v
        [{
          x,   0.0, 0.0, 0.0,
          0.0, y,   0.0, 0.0,
          0.0, 0.0, z,   0.0,
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Create a rotation matrix around the X axis.
      """
      @spec mat4_rotate_x(float()) :: mat4()
      def mat4_rotate_x(angle) do
        c = :math.cos(angle)
        s = :math.sin(angle)

        [{
          1.0, 0.0, 0.0, 0.0,
          0.0, c,  -s,   0.0,
          0.0, s,   c,   0.0,
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Create a rotation matrix around the Y axis.
      """
      @spec mat4_rotate_y(float()) :: mat4()
      def mat4_rotate_y(angle) do
        c = :math.cos(angle)
        s = :math.sin(angle)

        [{
          c,   0.0, s,   0.0,
          0.0, 1.0, 0.0, 0.0,
         -s,   0.0, c,   0.0,
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Create a rotation matrix around the Z axis.
      """
      @spec mat4_rotate_z(float()) :: mat4()
      def mat4_rotate_z(angle) do
        c = :math.cos(angle)
        s = :math.sin(angle)

        [{
          c,  -s,   0.0, 0.0,
          s,   c,   0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Create a rotation matrix from axis and angle.
      """
      @spec mat4_rotate(vec3(), float()) :: mat4()
      def mat4_rotate(axis, angle) do
        quat_from_axis_angle(axis, angle) |> quat_to_mat4()
      end

      # ============================================================================
      # PROJECTION AND VIEW TRANSFORMATIONS
      # ============================================================================

      @doc """
      Create a perspective projection matrix.
      """
      @spec mat4_perspective(float(), float(), float(), float()) :: mat4()
      def mat4_perspective(fov_y, aspect_ratio, z_near, z_far) do
        tan_half_fov = :math.tan(fov_y * 0.5)

        [{
          1.0 / (aspect_ratio * tan_half_fov), 0.0, 0.0, 0.0,
          0.0, 1.0 / tan_half_fov, 0.0, 0.0,
          0.0, 0.0, -(z_far + z_near) / (z_far - z_near), -(2.0 * z_far * z_near) / (z_far - z_near),
          0.0, 0.0, -1.0, 0.0
        }]
      end

      @doc """
      Create an orthographic projection matrix.
      """
      @spec mat4_ortho(float(), float(), float(), float(), float(), float()) :: mat4()
      def mat4_ortho(left, right, bottom, top, z_near, z_far) do
        [{
          2.0 / (right - left), 0.0, 0.0, -(right + left) / (right - left),
          0.0, 2.0 / (top - bottom), 0.0, -(top + bottom) / (top - bottom),
          0.0, 0.0, -2.0 / (z_far - z_near), -(z_far + z_near) / (z_far - z_near),
          0.0, 0.0, 0.0, 1.0
        }]
      end

      @doc """
      Create a look-at view matrix.
      """
      @spec mat4_look_at(vec3(), vec3(), vec3()) :: mat4()
      def mat4_look_at(eye, center, up) do
        f = normalize(vec_sub(center, eye))
        s = normalize(cross(f, up))
        u = cross(s, f)

        [{fx, fy, fz}] = f
        [{sx, sy, sz}] = s
        [{ux, uy, uz}] = u
        [{ex, ey, ez}] = eye

        [{
          sx, ux, -fx, -dot(s, eye),
          sy, uy, -fy, -dot(u, eye),
          sz, uz, -fz,  dot(f, eye),
          0.0, 0.0, 0.0, 1.0
        }]
      end

      # ============================================================================
      # TRIGONOMETRIC AND UTILITY FUNCTIONS
      # ============================================================================

      @doc """
      Convert degrees to radians.
      """
      @spec radians(float()) :: float()
      def radians(degrees) do
        degrees * :math.pi() / 180.0
      end

      @doc """
      Convert radians to degrees.
      """
      @spec degrees(float()) :: float()
      def degrees(radians) do
        radians * 180.0 / :math.pi()
      end

      @doc """
      Clamp value between min and max.
      """
      @spec clamp(float(), float(), float()) :: float()
      def clamp(value, min_val, max_val) do
        max(min_val, min(max_val, value))
      end

      @doc """
      Linear interpolation between two values.
      """
      @spec lerp(float(), float(), float()) :: float()
      def lerp(a, b, t) do
        a + t * (b - a)
      end

      @doc """
      Smooth step function (Hermite interpolation).
      """
      @spec smooth_step(float(), float(), float()) :: float()
      def smooth_step(edge0, edge1, x) do
        t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
        t * t * (3.0 - 2.0 * t)
      end

      @doc """
      Step function (returns 0.0 if x < edge, 1.0 otherwise).
      """
      @spec step(float(), float()) :: float()
      def step(edge, x) do
        if x < edge, do: 0.0, else: 1.0
      end

      @doc """
      Fast inverse square root approximation.
      """
      @spec inverse_sqrt(float()) :: float()
      def inverse_sqrt(x) when x > 0.0 do
        1.0 / :math.sqrt(x)
      end

      def inverse_sqrt(_), do: 0.0

      @doc """
      Mix (linear interpolation) between two values.
      """
      @spec mix(float(), float(), float()) :: float()
      def mix(x, y, a) do
        x * (1.0 - a) + y * a
      end

      @doc """
      Fractional part of x (x - floor(x)).
      """
      @spec fract(float()) :: float()
      def fract(x) do
        x - Float.floor(x)
      end

      @doc """
      Modulo operation that works with floats.
      """
      @spec mod(float(), float()) :: float()
      def mod(x, y) do
        x - y * Float.floor(x / y)
      end

      @doc """
      Sign function (-1, 0, or 1).
      """
      @spec sign(float()) :: float()
      def sign(x) do
        cond do
          x > 0.0 -> 1.0
          x < 0.0 -> -1.0
          true -> 0.0
        end
      end

      @doc """
      Absolute value.
      """
      @spec abs_val(float()) :: float()
      def abs_val(x) do
        abs(x)
      end

      # ============================================================================
      # GEOMETRIC FUNCTIONS
      # ============================================================================

      @doc """
      Calculate face normal from three vertices (assumes counter-clockwise winding).
      """
      @spec face_normal(vec3(), vec3(), vec3()) :: vec3()
      def face_normal(v0, v1, v2) do
        edge1 = vec_sub(v1, v0)
        edge2 = vec_sub(v2, v0)
        cross(edge1, edge2) |> normalize()
      end

      @doc """
      Project vector a onto vector b.
      """
      @spec project(vec3(), vec3()) :: vec3()
      def project(a, b) do
        dot_product = dot(a, b)
        b_length_sq = length_squared(b)

        if b_length_sq == 0.0 do
          vec3_zero()
        else
          vec_scale(b, dot_product / b_length_sq)
        end
      end

      @doc """
      Reject vector a from vector b (perpendicular component).
      """
      @spec reject(vec3(), vec3()) :: vec3()
      def reject(a, b) do
        vec_sub(a, project(a, b))
      end

      @doc """
      Calculate angle between two vectors in radians.
      """
      @spec angle_between(vec3(), vec3()) :: float()
      def angle_between(a, b) do
        a_norm = normalize(a)
        b_norm = normalize(b)
        dot_product = clamp(dot(a_norm, b_norm), -1.0, 1.0)
        :math.acos(dot_product)
      end

      @doc """
      Check if two vectors are parallel (dot product close to ±1).
      """
      @spec parallel?(vec3(), vec3(), float()) :: boolean()
      def parallel?(a, b, tolerance \\ 0.001) do
        dot_product = abs(dot(normalize(a), normalize(b)))
        abs(dot_product - 1.0) < tolerance
      end

      @doc """
      Check if two vectors are perpendicular (dot product close to 0).
      """
      @spec perpendicular?(vec3(), vec3(), float()) :: boolean()
      def perpendicular?(a, b, tolerance \\ 0.001) do
        abs(dot(normalize(a), normalize(b))) < tolerance
      end
    end
  end



end
