defmodule EAGL.Math do
  @moduledoc """
  GLM-compatible 3D math library for OpenGL applications.

  Provides comprehensive vector, matrix, and quaternion operations with
  OpenGL integration based on the GLM library. All functions work with Erlang's tuple-in-list
  format required by wx OpenGL bindings.

  ## Usage

      import EAGL.Math

      # Vector operations
      position = vec3(1.0, 2.0, 3.0)
      direction = vec3(0.0, 1.0, 0.0)
      result = vec_add(position, direction)
      length = vec_length(position)

      # Matrix transformations
      model = mat4_translate(vec3(5.0, 0.0, 0.0))
      view = mat4_look_at(
        vec3(0.0, 0.0, 5.0),  # eye
        vec3(0.0, 0.0, 0.0),  # target
        vec3(0.0, 1.0, 0.0)   # up
      )
      projection = mat4_perspective(radians(45.0), 16.0/9.0, 0.1, 100.0)

      # Quaternion rotations
      rotation = quat_from_axis_angle(vec3(0.0, 1.0, 0.0), radians(45.0))

      # All values work directly with EAGL.Shader uniform functions
      set_uniform(program, "model", model)
      set_uniform(program, "view", view)
      set_uniform(program, "projection", projection)
  """

  # ============================================================================
  # TYPE DEFINITIONS
  # ============================================================================

  @type vec2 :: [{float(), float()}]
  @type vec3 :: [{float(), float(), float()}]
  @type vec4 :: [{float(), float(), float(), float()}]
  @type quat :: [{float(), float(), float(), float()}]

  @type mat2 :: [
          {float(), float(), float(), float()}
        ]

  @type mat3 :: [
          {float(), float(), float(), float(), float(), float(), float(), float(), float()}
        ]

  @type mat4 :: [
          {float(), float(), float(), float(), float(), float(), float(), float(), float(),
           float(), float(), float(), float(), float(), float(), float()}
        ]

  # ============================================================================
  # MATRIX CONSTRUCTORS
  # ============================================================================

  @doc """
  Create a 2x2 matrix.
  """
  @spec mat2(float(), float(), float(), float()) :: mat2()
  def mat2(a, b, c, d) do
    [{a, b, c, d}]
  end

  @doc """
  Create a 3x3 matrix.
  """
  @spec mat3(float(), float(), float(), float(), float(), float(), float(), float(), float()) ::
          mat3()
  def mat3(a, b, c, d, e, f, g, h, i) do
    [{a, b, c, d, e, f, g, h, i}]
  end

  @doc """
  Create a 4x4 matrix.
  """
  @spec mat4(
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float(),
          float()
        ) :: mat4()
  def mat4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) do
    [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}]
  end

  @doc ~S"""
  A sigil to create a matrix from a string.

  Automatically determines matrix size based on the number of floats:
  - 4 floats: creates a 2x2 matrix
  - 9 floats: creates a 3x3 matrix
  - 16 floats: creates a 4x4 matrix

  Supports comments using '#' - everything after '#' on a line is ignored.
  Works with module attributes since sigils are evaluated at compile time.

  ## Examples

      # 2x2 matrix (single line)
      ~m"1.0 0.0 0.0 1.0"

      # 2x2 matrix with comments
      ~m'''
      1.0 0.0  # row 1
      0.0 1.0  # row 2
      '''

      # 3x3 identity matrix with detailed comments
      ~m'''
      1.0 0.0 0.0  # X axis
      0.0 1.0 0.0  # Y axis
      0.0 0.0 1.0  # Z axis
      '''

      # 4x4 transformation matrix
      ~m'''
      1.0 0.0 0.0 5.0  # X axis + translation
      0.0 1.0 0.0 0.0  # Y axis
      0.0 0.0 1.0 0.0  # Z axis
      0.0 0.0 0.0 1.0  # homogeneous coordinate
      '''

  ## Module Attributes

      # Define matrices as module attributes for reuse
      @identity_4x4 ~m'''
      1.0 0.0 0.0 0.0  # identity matrix
      0.0 1.0 0.0 0.0
      0.0 0.0 1.0 0.0
      0.0 0.0 0.0 1.0
      '''

      @projection_matrix ~m'''
      1.81 0.0  0.0   0.0   # perspective projection
      0.0  2.41 0.0   0.0   # 45° FOV, 16:9 aspect
      0.0  0.0 -1.002 -0.2  # near=0.1, far=100.0
      0.0  0.0 -1.0   0.0
      '''

      def get_identity, do: @identity_4x4
      def get_projection, do: @projection_matrix
  """
  def sigil_m(string, _opts) do
    floats =
      string
      |> String.split("\n")
      |> Enum.map(fn line ->
        # Remove comments (everything after #)
        line
        |> String.split("#")
        |> List.first()
      end)
      |> Enum.join(" ")
      |> String.split()
      |> Enum.map(&String.to_float/1)

    case length(floats) do
      4 -> apply(__MODULE__, :mat2, floats)
      9 -> apply(__MODULE__, :mat3, floats)
      16 -> apply(__MODULE__, :mat4, floats)
      n -> raise ArgumentError, "Invalid matrix size: expected 4, 9, or 16 floats, got #{n}"
    end
  end

  @doc ~S"""
  A sigil to create vertex data from a string.

  Returns a flat list of floats, perfect for vertex arrays, texture coordinates,
  normals, colors, or any other vertex attribute data.

  Supports comments using '#' - everything after '#' on a line is ignored.
  Works with module attributes since sigils are evaluated at compile time.

  ## Examples

      # Simple triangle vertices (x, y, z)
      ~v"0.0 0.5 0.0  -0.5 -0.5 0.0  0.5 -0.5 0.0"

      # Triangle with comments
      ~v'''
      0.0  0.5 0.0   # top vertex
      -0.5 -0.5 0.0  # bottom left
      0.5  -0.5 0.0  # bottom right
      '''

      # Quad vertices with texture coordinates
      ~v'''
      # Position    # Texture coords
      -1.0  1.0 0.0  0.0 1.0  # top left
       1.0  1.0 0.0  1.0 1.0  # top right
       1.0 -1.0 0.0  1.0 0.0  # bottom right
      -1.0 -1.0 0.0  0.0 0.0  # bottom left
      '''

      # Color data (RGB)
      ~v'''
      1.0 0.0 0.0  # red
      0.0 1.0 0.0  # green
      0.0 0.0 1.0  # blue
      '''

  ## Module Attributes

      # Define vertex data as module attributes
      @triangle_vertices ~v'''
      0.0  0.5 0.0   # top
      -0.5 -0.5 0.0  # bottom left
      0.5  -0.5 0.0  # bottom right
      '''

      @quad_indices ~v"0 1 2  2 3 0"  # triangle indices

      def get_triangle_vertices, do: @triangle_vertices
      def get_quad_indices, do: @quad_indices
  """
  def sigil_v(string, _opts) do
    string
    |> String.split("\n")
    |> Enum.map(fn line ->
      # Remove comments (everything after #)
      line
      |> String.split("#")
      |> List.first()
    end)
    |> Enum.join(" ")
    |> String.split()
    |> Enum.map(&String.to_float/1)
  end

  @doc ~S"""
  A sigil to create index data from a string.

  Returns a flat list of integers, perfect for element array buffer indices,
  face definitions, or any other integer-based data.

  Supports comments using '#' - everything after '#' on a line is ignored.
  Works with module attributes since sigils are evaluated at compile time.

  ## Examples

      # Simple triangle indices
      ~i"0 1 2"

      # Quad indices (two triangles)
      ~i"0 1 2  2 3 0"

      # Cube indices with comments
      ~i'''
      # Front face
      0 1 2  2 3 0
      # Back face
      4 5 6  6 7 4
      # Left face
      7 3 0  0 4 7
      # Right face
      1 5 6  6 2 1
      # Top face
      3 2 6  6 7 3
      # Bottom face
      0 1 5  5 4 0
      '''

      # Triangle strip indices
      ~i'''
      0 1 2   # first triangle
      1 3 2   # second triangle (shares edge 1-2)
      2 3 4   # third triangle (shares edge 2-3)
      '''

  ## Module Attributes

      # Define index data as module attributes
      @quad_indices ~i'''
      0 1 2  # first triangle
      2 3 0  # second triangle
      '''

      @cube_indices ~i'''
      # All 12 triangles for a cube
      0 1 2  2 3 0    # front
      4 5 6  6 7 4    # back
      7 3 0  0 4 7    # left
      1 5 6  6 2 1    # right
      3 2 6  6 7 3    # top
      0 1 5  5 4 0    # bottom
      '''

      def get_quad_indices, do: @quad_indices
      def get_cube_indices, do: @cube_indices
  """
  def sigil_i(string, _opts) do
    string
    |> String.split("\n")
    |> Enum.map(fn line ->
      # Remove comments (everything after #)
      line
      |> String.split("#")
      |> List.first()
    end)
    |> Enum.join(" ")
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  # ============================================================================
  # VECTOR CONSTRUCTORS
  # ============================================================================

  @doc """
  Create a 2D vector.
  """
  @spec vec2(float(), float()) :: vec2()
  def vec2(x, y) do
    [{x, y}]
  end

  @doc """
  Create a 3D vector.
  """
  @spec vec3(float(), float(), float()) :: vec3()
  def vec3(x, y, z) do
    [{x, y, z}]
  end

  @doc """
  Create a 4D vector.
  """
  @spec vec4(float(), float(), float(), float()) :: vec4()
  def vec4(x, y, z, w) do
    [{x, y, z, w}]
  end

  # ============================================================================
  # QUATERNION CONSTRUCTORS
  # ============================================================================

  @doc """
  Create a quaternion.
  Quaternions are represented as {x, y, z, w} where w is the scalar component.
  This follows the (x, y, z, w) convention commonly used in graphics programming.
  """
  @spec quat(float(), float(), float(), float()) :: quat()
  def quat(x, y, z, w) do
    [{x, y, z, w}]
  end

  @doc """
  Create an identity quaternion (no rotation).
  """
  @spec quat_identity() :: quat()
  def quat_identity() do
    [{0.0, 0.0, 0.0, 1.0}]
  end

  # ============================================================================
  # COMMON VECTOR CONSTRUCTORS
  # ============================================================================

  @doc """
  Create a zero vector (2D).
  """
  @spec vec2_zero() :: vec2()
  def vec2_zero() do
    [{0.0, 0.0}]
  end

  @doc """
  Create a zero vector (3D).
  """
  @spec vec3_zero() :: vec3()
  def vec3_zero() do
    [{0.0, 0.0, 0.0}]
  end

  @doc """
  Create a zero vector (4D).
  """
  @spec vec4_zero() :: vec4()
  def vec4_zero() do
    [{0.0, 0.0, 0.0, 0.0}]
  end

  @doc """
  Create a 3D vector with all components set to 1.
  """
  @spec vec3_one() :: vec3()
  def vec3_one() do
    [{1.0, 1.0, 1.0}]
  end

  @doc """
  Create the X unit vector (1, 0, 0).
  """
  @spec vec3_unit_x() :: vec3()
  def vec3_unit_x() do
    [{1.0, 0.0, 0.0}]
  end

  @doc """
  Create the Y unit vector (0, 1, 0).
  """
  @spec vec3_unit_y() :: vec3()
  def vec3_unit_y() do
    [{0.0, 1.0, 0.0}]
  end

  @doc """
  Create the Z unit vector (0, 0, 1).
  """
  @spec vec3_unit_z() :: vec3()
  def vec3_unit_z() do
    [{0.0, 0.0, 1.0}]
  end

  # ============================================================================
  # COMMON MATRIX CONSTRUCTORS
  # ============================================================================

  @doc """
  Create a 4x4 identity matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_identity() :: mat4()
  def mat4_identity do
    ~m"""
    1.0 0.0 0.0 0.0  # Column 0
    0.0 1.0 0.0 0.0  # Column 1
    0.0 0.0 1.0 0.0  # Column 2
    0.0 0.0 0.0 1.0  # Column 3
    """
  end

  @doc """
  Create a 3x3 identity matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat3_identity() :: mat3()
  def mat3_identity do
    ~m"""
    1.0 0.0 0.0  # Column 0
    0.0 1.0 0.0  # Column 1
    0.0 0.0 1.0  # Column 2
    """
  end

  @doc """
  Create a 2x2 identity matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat2_identity() :: mat2()
  def mat2_identity do
    ~m"""
    1.0 0.0  # Column 0
    0.0 1.0  # Column 1
    """
  end

  # ============================================================================
  # VECTOR OPERATIONS
  # ============================================================================

  @doc """
  Compute the dot product of two vectors (2D, 3D, or 4D).
  """
  @spec dot(vec2(), vec2()) :: float()
  @spec dot(vec3(), vec3()) :: float()
  @spec dot(vec4(), vec4()) :: float()
  def dot([{x1, y1}], [{x2, y2}]) do
    x1 * x2 + y1 * y2
  end

  def dot([{x1, y1, z1}], [{x2, y2, z2}]) do
    x1 * x2 + y1 * y2 + z1 * z2
  end

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
  Compute the length (magnitude) of a vector (2D, 3D, or 4D).
  """
  @spec vec_length(vec2()) :: float()
  @spec vec_length(vec3()) :: float()
  @spec vec_length(vec4()) :: float()
  def vec_length([{x, y}]) do
    :math.sqrt(x * x + y * y)
  end

  def vec_length([{x, y, z}]) do
    :math.sqrt(x * x + y * y + z * z)
  end

  def vec_length([{x, y, z, w}]) do
    :math.sqrt(x * x + y * y + z * z + w * w)
  end

  @doc """
  Compute the squared length of a vector (avoids sqrt).
  """
  @spec length_squared(vec2()) :: float()
  @spec length_squared(vec3()) :: float()
  @spec length_squared(vec4()) :: float()
  def length_squared([{x, y}]) do
    x * x + y * y
  end

  def length_squared([{x, y, z}]) do
    x * x + y * y + z * z
  end

  def length_squared([{x, y, z, w}]) do
    x * x + y * y + z * z + w * w
  end

  @doc """
  Normalize a vector to unit length (2D, 3D, or 4D).
  """
  @spec normalize(vec2()) :: vec2()
  @spec normalize(vec3()) :: vec3()
  @spec normalize(vec4()) :: vec4()
  def normalize([{x, y}]) do
    len = :math.sqrt(x * x + y * y)
    if len == 0.0, do: [{0.0, 0.0}], else: [{x / len, y / len}]
  end

  def normalize([{x, y, z}]) do
    len = :math.sqrt(x * x + y * y + z * z)
    if len == 0.0, do: [{0.0, 0.0, 0.0}], else: [{x / len, y / len, z / len}]
  end

  def normalize([{x, y, z, w}]) do
    len = :math.sqrt(x * x + y * y + z * z + w * w)
    if len == 0.0, do: [{0.0, 0.0, 0.0, 0.0}], else: [{x / len, y / len, z / len, w / len}]
  end

  @doc """
  Add two vectors component-wise.
  """
  @spec vec_add(vec2(), vec2()) :: vec2()
  @spec vec_add(vec3(), vec3()) :: vec3()
  @spec vec_add(vec4(), vec4()) :: vec4()
  def vec_add([{x1, y1}], [{x2, y2}]) do
    [{x1 + x2, y1 + y2}]
  end

  def vec_add([{x1, y1, z1}], [{x2, y2, z2}]) do
    [{x1 + x2, y1 + y2, z1 + z2}]
  end

  def vec_add([{x1, y1, z1, w1}], [{x2, y2, z2, w2}]) do
    [{x1 + x2, y1 + y2, z1 + z2, w1 + w2}]
  end

  @doc """
  Subtract two vectors component-wise.
  """
  @spec vec_sub(vec2(), vec2()) :: vec2()
  @spec vec_sub(vec3(), vec3()) :: vec3()
  @spec vec_sub(vec4(), vec4()) :: vec4()
  def vec_sub([{x1, y1}], [{x2, y2}]) do
    [{x1 - x2, y1 - y2}]
  end

  def vec_sub([{x1, y1, z1}], [{x2, y2, z2}]) do
    [{x1 - x2, y1 - y2, z1 - z2}]
  end

  def vec_sub([{x1, y1, z1, w1}], [{x2, y2, z2, w2}]) do
    [{x1 - x2, y1 - y2, z1 - z2, w1 - w2}]
  end

  @doc """
  Multiply a vector by a scalar.
  """
  @spec vec_scale(vec2(), float()) :: vec2()
  @spec vec_scale(vec3(), float()) :: vec3()
  @spec vec_scale(vec4(), float()) :: vec4()
  def vec_scale([{x, y}], s) do
    [{x * s, y * s}]
  end

  def vec_scale([{x, y, z}], s) do
    [{x * s, y * s, z * s}]
  end

  def vec_scale([{x, y, z, w}], s) do
    [{x * s, y * s, z * s, w * s}]
  end

  @doc """
  Negate a vector (multiply by -1).
  """
  @spec vec_negate(vec2()) :: vec2()
  @spec vec_negate(vec3()) :: vec3()
  @spec vec_negate(vec4()) :: vec4()
  def vec_negate([{x, y}]) do
    [{-x, -y}]
  end

  def vec_negate([{x, y, z}]) do
    [{-x, -y, -z}]
  end

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
  @spec vec_lerp(vec3(), vec3(), float()) :: vec3()
  @spec vec_lerp(vec4(), vec4(), float()) :: vec4()
  def vec_lerp([{x1, y1}], [{x2, y2}], t) do
    [{x1 + t * (x2 - x1), y1 + t * (y2 - y1)}]
  end

  def vec_lerp([{x1, y1, z1}], [{x2, y2, z2}], t) do
    [{x1 + t * (x2 - x1), y1 + t * (y2 - y1), z1 + t * (z2 - z1)}]
  end

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
      # Total internal reflection
      vec3_zero()
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
    [
      {
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
        w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2,
        w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2,
        w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
      }
    ]
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
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec quat_to_mat3(quat()) :: mat3()
  def quat_to_mat3([{x, y, z, w}]) do
    x2 = x + x
    y2 = y + y
    z2 = z + z
    xx = x * x2
    xy = x * y2
    xz = x * z2
    yy = y * y2
    yz = y * z2
    zz = z * z2
    wx = w * x2
    wy = w * y2
    wz = w * z2

    [
      {
        # Column 0
        1.0 - (yy + zz),
        xy + wz,
        xz - wy,
        # Column 1
        xy - wz,
        1.0 - (xx + zz),
        yz + wx,
        # Column 2
        xz + wy,
        yz - wx,
        1.0 - (xx + yy)
      }
    ]
  end

  @doc """
  Convert quaternion to rotation matrix (4x4).
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec quat_to_mat4(quat()) :: mat4()
  def quat_to_mat4(q) do
    [{m00, m01, m02, m10, m11, m12, m20, m21, m22}] = quat_to_mat3(q)

    # mix format: off
    [
      {
        m00, m01, m02, 0.0,  # Column 0
        m10, m11, m12, 0.0,  # Column 1
        m20, m21, m22, 0.0,  # Column 2
        0.0, 0.0, 0.0, 1.0   # Column 3
      }
    ]
    # mix format: on
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

      [
        {
          a * x1 + b * x2,
          a * y1 + b * y2,
          a * z1 + b * z2,
          a * w1 + b * w2
        }
      ]
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

    [
      {
        sin_pitch * cos_yaw * cos_roll - cos_pitch * sin_yaw * sin_roll,
        cos_pitch * sin_yaw * cos_roll + sin_pitch * cos_yaw * sin_roll,
        cos_pitch * cos_yaw * sin_roll - sin_pitch * sin_yaw * cos_roll,
        cos_pitch * cos_yaw * cos_roll + sin_pitch * sin_yaw * sin_roll
      }
    ]
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
  All matrices are in column-major order for OpenGL compatibility.
  """
  @spec mat4_mul(mat4(), mat4()) :: mat4()
  def mat4_mul(
        [{a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, a30, a31, a32, a33}],
        [{b00, b01, b02, b03, b10, b11, b12, b13, b20, b21, b22, b23, b30, b31, b32, b33}]
      ) do
    # mix format: off
    [
      {
        a00 * b00 + a01 * b10 + a02 * b20 + a03 * b30, a00 * b01 + a01 * b11 + a02 * b21 + a03 * b31, a00 * b02 + a01 * b12 + a02 * b22 + a03 * b32, a00 * b03 + a01 * b13 + a02 * b23 + a03 * b33,  # Column 0
        a10 * b00 + a11 * b10 + a12 * b20 + a13 * b30, a10 * b01 + a11 * b11 + a12 * b21 + a13 * b31, a10 * b02 + a11 * b12 + a12 * b22 + a13 * b32, a10 * b03 + a11 * b13 + a12 * b23 + a13 * b33,  # Column 1
        a20 * b00 + a21 * b10 + a22 * b20 + a23 * b30, a20 * b01 + a21 * b11 + a22 * b21 + a23 * b31, a20 * b02 + a21 * b12 + a22 * b22 + a23 * b32, a20 * b03 + a21 * b13 + a22 * b23 + a23 * b33,  # Column 2
        a30 * b00 + a31 * b10 + a32 * b20 + a33 * b30, a30 * b01 + a31 * b11 + a32 * b21 + a33 * b31, a30 * b02 + a31 * b12 + a32 * b22 + a33 * b32, a30 * b03 + a31 * b13 + a32 * b23 + a33 * b33   # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Multiply two 3x3 matrices.
  All matrices are in column-major order for OpenGL compatibility.
  """
  @spec mat3_mul(mat3(), mat3()) :: mat3()
  def mat3_mul(
        [{a00, a01, a02, a10, a11, a12, a20, a21, a22}],
        [{b00, b01, b02, b10, b11, b12, b20, b21, b22}]
      ) do
    [
      {
        a00 * b00 + a01 * b10 + a02 * b20,
        a00 * b01 + a01 * b11 + a02 * b21,
        a00 * b02 + a01 * b12 + a02 * b22,
        a10 * b00 + a11 * b10 + a12 * b20,
        a10 * b01 + a11 * b11 + a12 * b21,
        a10 * b02 + a11 * b12 + a12 * b22,
        a20 * b00 + a21 * b10 + a22 * b20,
        a20 * b01 + a21 * b11 + a22 * b21,
        a20 * b02 + a21 * b12 + a22 * b22
      }
    ]
  end

  @doc """
  Transpose a 4x4 matrix.
  Input and output matrices are in column-major order for OpenGL compatibility.
  """
  @spec mat4_transpose(mat4()) :: mat4()
  def mat4_transpose([
        {m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}
      ]) do
    [{m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33}]
  end

  @doc """
  Transpose a 3x3 matrix.
  Input and output matrices are in column-major order for OpenGL compatibility.
  """
  @spec mat3_transpose(mat3()) :: mat3()
  def mat3_transpose([{m00, m01, m02, m10, m11, m12, m20, m21, m22}]) do
    [{m00, m10, m20, m01, m11, m21, m02, m12, m22}]
  end

  @doc """
  Create a translation matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_translate(vec3()) :: mat4()
  def mat4_translate(v) do
    [{x, y, z}] = v

    # mix format: off
    [
      {
        1.0, 0.0, 0.0, 0.0,  # Column 0
        0.0, 1.0, 0.0, 0.0,  # Column 1
        0.0, 0.0, 1.0, 0.0,  # Column 2
        x,   y,   z,   1.0   # Column 3 (translation)
      }
    ]
    # mix format: on
  end

  @doc """
  Create a scale matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_scale(vec3()) :: mat4()
  def mat4_scale(v) do
    [{x, y, z}] = v

    # mix format: off
    [
      {
        x,   0.0, 0.0, 0.0,  # Column 0 (X scale)
        0.0, y,   0.0, 0.0,  # Column 1 (Y scale)
        0.0, 0.0, z,   0.0,  # Column 2 (Z scale)
        0.0, 0.0, 0.0, 1.0   # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Create a rotation matrix around the X axis.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_rotate_x(float()) :: mat4()
  def mat4_rotate_x(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)

    # mix format: off
    [
      {
        1.0, 0.0, 0.0, 0.0,  # Column 0
        0.0, c,   s,   0.0,  # Column 1 (swapped s and -s for column-major)
        0.0, -s,  c,   0.0,  # Column 2
        0.0, 0.0, 0.0, 1.0   # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Create a rotation matrix around the Y axis.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_rotate_y(float()) :: mat4()
  def mat4_rotate_y(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)

    # mix format: off
    [
      {
        c,   0.0, -s,  0.0,  # Column 0 (swapped s and -s for column-major)
        0.0, 1.0, 0.0, 0.0,  # Column 1
        s,   0.0, c,   0.0,  # Column 2
        0.0, 0.0, 0.0, 1.0   # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Create a rotation matrix around the Z axis.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_rotate_z(float()) :: mat4()
  def mat4_rotate_z(angle) do
    c = :math.cos(angle)
    s = :math.sin(angle)

    # mix format: off
    [
      {
        c,   s,   0.0, 0.0,  # Column 0 (swapped s and -s for column-major)
        -s,  c,   0.0, 0.0,  # Column 1
        0.0, 0.0, 1.0, 0.0,  # Column 2
        0.0, 0.0, 0.0, 1.0   # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Create a rotation matrix from axis and angle.
  """
  @spec mat4_rotate(vec3(), float()) :: mat4()
  def mat4_rotate(axis, angle) do
    quat_from_axis_angle(axis, angle) |> quat_to_mat4()
  end

  @doc """
  Create the inverse of a 4x4 matrix using the adjugate method.
  Returns the original matrix if it's not invertible (determinant is zero).
  Input and output matrices are in column-major order for OpenGL compatibility.
  Note this is the only function not from the original OpenGl GLM library.
  """
  @spec mat4_inverse(mat4()) :: mat4()
  def mat4_inverse([
        {m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}
      ]) do
    # Calculate the 2x2 determinants for the first two rows
    s0 = m00 * m11 - m10 * m01
    s1 = m00 * m12 - m10 * m02
    s2 = m00 * m13 - m10 * m03
    s3 = m01 * m12 - m11 * m02
    s4 = m01 * m13 - m11 * m03
    s5 = m02 * m13 - m12 * m03

    # Calculate the 2x2 determinants for the last two rows
    c5 = m22 * m33 - m32 * m23
    c4 = m21 * m33 - m31 * m23
    c3 = m21 * m32 - m31 * m22
    c2 = m20 * m33 - m30 * m23
    c1 = m20 * m32 - m30 * m22
    c0 = m20 * m31 - m30 * m21

    # Calculate the determinant
    det = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0

    # Check for non-invertible matrix
    if abs(det) < 1.0e-14 do
      # Return the original matrix if not invertible
      [{m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}]
    else
      invdet = 1.0 / det

      # Calculate the inverse matrix elements
      inv00 = (m11 * c5 - m12 * c4 + m13 * c3) * invdet
      inv01 = (-m01 * c5 + m02 * c4 - m03 * c3) * invdet
      inv02 = (m31 * s5 - m32 * s4 + m33 * s3) * invdet
      inv03 = (-m21 * s5 + m22 * s4 - m23 * s3) * invdet

      inv10 = (-m10 * c5 + m12 * c2 - m13 * c1) * invdet
      inv11 = (m00 * c5 - m02 * c2 + m03 * c1) * invdet
      inv12 = (-m30 * s5 + m32 * s2 - m33 * s1) * invdet
      inv13 = (m20 * s5 - m22 * s2 + m23 * s1) * invdet

      inv20 = (m10 * c4 - m11 * c2 + m13 * c0) * invdet
      inv21 = (-m00 * c4 + m01 * c2 - m03 * c0) * invdet
      inv22 = (m30 * s4 - m31 * s2 + m33 * s0) * invdet
      inv23 = (-m20 * s4 + m21 * s2 - m23 * s0) * invdet

      inv30 = (-m10 * c3 + m11 * c1 - m12 * c0) * invdet
      inv31 = (m00 * c3 - m01 * c1 + m02 * c0) * invdet
      inv32 = (-m30 * s3 + m31 * s1 - m32 * s0) * invdet
      inv33 = (m20 * s3 - m21 * s1 + m22 * s0) * invdet

      # mix format: off
      [
        {
          inv00, inv01, inv02, inv03,  # Column 0
          inv10, inv11, inv12, inv13,  # Column 1
          inv20, inv21, inv22, inv23,  # Column 2
          inv30, inv31, inv32, inv33   # Column 3
        }
      ]
      # mix format: on
    end
  end

  # ============================================================================
  # PROJECTION AND VIEW TRANSFORMATIONS
  # ============================================================================

  @doc """
  Create a perspective projection matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_perspective(float(), float(), float(), float()) :: mat4()
  def mat4_perspective(fov_y, aspect_ratio, z_near, z_far) do
    tan_half_fov = :math.tan(fov_y * 0.5)

    # mix format: off
    [
      {
        1.0 / (aspect_ratio * tan_half_fov), 0.0,                    0.0,                                     0.0,  # Column 0
        0.0,                                 1.0 / tan_half_fov,     0.0,                                     0.0,  # Column 1
        0.0,                                 0.0,                    -(z_far + z_near) / (z_far - z_near),    -1.0, # Column 2
        0.0,                                 0.0,                    -(2.0 * z_far * z_near) / (z_far - z_near), 0.0  # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Create an orthographic projection matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_ortho(float(), float(), float(), float(), float(), float()) :: mat4()
  def mat4_ortho(left, right, bottom, top, z_near, z_far) do
    # mix format: off
    [
      {
        2.0 / (right - left),                  0.0,                               0.0,                                    0.0,  # Column 0
        0.0,                                   2.0 / (top - bottom),              0.0,                                    0.0,  # Column 1
        0.0,                                   0.0,                               -2.0 / (z_far - z_near),               0.0,  # Column 2
        -(right + left) / (right - left),      -(top + bottom) / (top - bottom),  -(z_far + z_near) / (z_far - z_near),  1.0   # Column 3
      }
    ]
    # mix format: on
  end

  @doc """
  Create a look-at view matrix.
  Matrix is stored in column-major order for OpenGL compatibility.
  """
  @spec mat4_look_at(vec3(), vec3(), vec3()) :: mat4()
  def mat4_look_at(eye, center, up) do
    f = normalize(vec_sub(center, eye))
    s = normalize(cross(f, up))
    u = normalize(cross(s, f))

    [{fx, fy, fz}] = f
    [{sx, sy, sz}] = s
    [{ux, uy, uz}] = u

    # mix format: off
    [
      {
        sx,           sy,           sz,          0.0,  # Column 0 (right vector)
        ux,           uy,           uz,          0.0,  # Column 1 (up vector)
        -fx,          -fy,          -fz,         0.0,  # Column 2 (forward vector, negated)
        -dot(s, eye), -dot(u, eye), dot(f, eye), 1.0   # Column 3 (translation)
      }
    ]
    # mix format: on
  end

  # ============================================================================
  # MATRIX-VECTOR OPERATIONS
  # ============================================================================

  @doc """
  Multiply a 3D vector by a 4x4 matrix (treating vector as point with w=1).
  Returns a 3D vector with the w component divided out.
  """
  @spec mat4_transform_point(mat4(), vec3()) :: vec3()
  def mat4_transform_point(
        [{m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}],
        [{x, y, z}]
      ) do
    # Multiply as if the vector has w=1
    new_x = m00 * x + m10 * y + m20 * z + m30
    new_y = m01 * x + m11 * y + m21 * z + m31
    new_z = m02 * x + m12 * y + m22 * z + m32
    new_w = m03 * x + m13 * y + m23 * z + m33

    # Divide by w if not 1 (for perspective division)
    if new_w != 1.0 and new_w != 0.0 do
      [{new_x / new_w, new_y / new_w, new_z / new_w}]
    else
      [{new_x, new_y, new_z}]
    end
  end

  @doc """
  Multiply a 3D vector by a 4x4 matrix (treating vector as direction with w=0).
  Used for transforming direction vectors (normals, etc.) where translation should be ignored.
  """
  @spec mat4_transform_vector(mat4(), vec3()) :: vec3()
  def mat4_transform_vector(
        [{m00, m01, m02, _m03, m10, m11, m12, _m13, m20, m21, m22, _m23, _m30, _m31, _m32, _m33}],
        [{x, y, z}]
      ) do
    # Multiply as if the vector has w=0 (ignore translation)
    new_x = m00 * x + m10 * y + m20 * z
    new_y = m01 * x + m11 * y + m21 * z
    new_z = m02 * x + m12 * y + m22 * z
    [{new_x, new_y, new_z}]
  end

  @doc """
  Multiply a 4D vector by a 4x4 matrix.
  """
  @spec mat4_transform_vec4(mat4(), vec4()) :: vec4()
  def mat4_transform_vec4(
        [{m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}],
        [{x, y, z, w}]
      ) do
    new_x = m00 * x + m10 * y + m20 * z + m30 * w
    new_y = m01 * x + m11 * y + m21 * z + m31 * w
    new_z = m02 * x + m12 * y + m22 * z + m32 * w
    new_w = m03 * x + m13 * y + m23 * z + m33 * w
    [{new_x, new_y, new_z, new_w}]
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
