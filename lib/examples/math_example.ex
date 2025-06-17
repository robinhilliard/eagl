defmodule EAGL.Examples.Math do
  @moduledoc """
  Comprehensive example demonstrating all EAGL.Math functionality.
  This showcases vector and quaternion constructor macros, vector operations,
  quaternions, matrices, utility functions, and real-world OpenGL usage patterns.
  """

  import EAGL.Math

  @doc """
  Example showing various vector and quaternion constructors.
  """
  def constructor_examples do
    IO.puts("=== EAGL Math Constructor Examples ===\n")

    # Vector constructors
    IO.puts("Vector Constructors:")
    pos_2d = vec2(10.0, 20.0)
    IO.puts("2D position: #{inspect(pos_2d)}")

    pos_3d = vec3(1.0, 2.0, 3.0)
    IO.puts("3D position: #{inspect(pos_3d)}")

    # RGBA color
    color = vec4(1.0, 0.5, 0.2, 1.0)
    IO.puts("RGBA color: #{inspect(color)}")

    # Zero vectors
    IO.puts("\nZero Vectors:")
    origin_2d = vec2_zero()
    origin_3d = vec3_zero()
    origin_4d = vec4_zero()
    IO.puts("2D origin: #{inspect(origin_2d)}")
    IO.puts("3D origin: #{inspect(origin_3d)}")
    IO.puts("4D origin: #{inspect(origin_4d)}")

    # Unit vectors
    IO.puts("\nUnit Vectors:")
    x_axis = vec3_unit_x()
    y_axis = vec3_unit_y()
    z_axis = vec3_unit_z()
    IO.puts("X axis: #{inspect(x_axis)}")
    IO.puts("Y axis: #{inspect(y_axis)}")
    IO.puts("Z axis: #{inspect(z_axis)}")

    # Quaternion constructors
    IO.puts("\nQuaternion Constructors:")
    # 90° rotation around Z
    rot_quat = quat(0.0, 0.0, 0.707, 0.707)
    IO.puts("90° Z rotation: #{inspect(rot_quat)}")

    identity_quat = quat_identity()
    IO.puts("Identity quaternion: #{inspect(identity_quat)}")

    # Matrix constructors
    IO.puts("\nMatrix Constructors:")
    identity_mat4 = mat4_identity()
    IO.puts("4x4 Identity: #{inspect(identity_mat4)}")

    identity_mat3 = mat3_identity()
    IO.puts("3x3 Identity: #{inspect(identity_mat3)}")

    # Custom matrices
    transform = ~m"""
    1.0  0.0  0.0  10.0  # Translation of 10 in X
    0.0  1.0  0.0  20.0  # Translation of 20 in Y
    0.0  0.0  1.0  30.0  # Translation of 30 in Z
    0.0  0.0  0.0   1.0
    """

    IO.puts("Transform matrix: #{inspect(transform)}")

    IO.puts("\n=== End Constructor Examples ===\n")
  end

  @doc """
  Demonstrate vector operations.
  """
  def vector_operations_demo do
    IO.puts("=== Vector Operations Demo ===\n")

    # Create some vectors
    v1 = vec3(1.0, 2.0, 3.0)
    v2 = vec3(4.0, 5.0, 6.0)
    # Unit X vector
    v3 = vec3(1.0, 0.0, 0.0)

    IO.puts("Vector 1: #{inspect(v1)}")
    IO.puts("Vector 2: #{inspect(v2)}")
    IO.puts("Vector 3 (unit X): #{inspect(v3)}")

    # Basic operations
    IO.puts("\nBasic Operations:")
    IO.puts("v1 + v2 = #{inspect(vec_add(v1, v2))}")
    IO.puts("v1 - v2 = #{inspect(vec_sub(v1, v2))}")
    IO.puts("v1 * 2.0 = #{inspect(vec_scale(v1, 2.0))}")
    IO.puts("-v1 = #{inspect(vec_negate(v1))}")

    # Dot and cross products
    IO.puts("\nProducts:")
    IO.puts("dot(v1, v2) = #{dot(v1, v2)}")
    IO.puts("cross(v1, v2) = #{inspect(cross(v1, v2))}")

    # Length operations
    IO.puts("\nLength Operations:")
    IO.puts("vec_length(v1) = #{vec_length(v1)}")
    IO.puts("length_squared(v1) = #{length_squared(v1)}")
    IO.puts("normalize(v1) = #{inspect(normalize(v1))}")

    # Distance
    IO.puts("\nDistance:")
    IO.puts("distance(v1, v2) = #{distance(v1, v2)}")
    IO.puts("distance_squared(v1, v2) = #{distance_squared(v1, v2)}")

    # Interpolation
    IO.puts("\nInterpolation:")
    IO.puts("lerp(v1, v2, 0.5) = #{inspect(vec_lerp(v1, v2, 0.5))}")

    # Geometric operations
    # Up normal
    normal = vec3(0.0, 1.0, 0.0)
    incident = vec3(1.0, -1.0, 0.0)
    IO.puts("\nGeometric Operations:")

    IO.puts(
      "reflect(#{inspect(incident)}, #{inspect(normal)}) = #{inspect(reflect(incident, normal))}"
    )

    # Angle between vectors
    IO.puts("angle_between(v1, v2) = #{degrees(angle_between(v1, v2))} degrees")
    IO.puts("parallel?(v3, vec3_unit_x()) = #{parallel?(v3, vec3_unit_x())}")

    IO.puts(
      "perpendicular?(vec3_unit_x(), vec3_unit_y()) = #{perpendicular?(vec3_unit_x(), vec3_unit_y())}"
    )

    IO.puts("\n=== End Vector Operations Demo ===\n")
  end

  @doc """
  Demonstrate quaternion operations.
  """
  def quaternion_operations_demo do
    IO.puts("=== Quaternion Operations Demo ===\n")

    # Create quaternions
    q1 = quat_identity()
    # 90° rotation around Z
    q2 = quat_from_axis_angle(vec3_unit_z(), radians(90.0))
    q3 = quat_from_euler(radians(30.0), radians(45.0), radians(60.0))

    IO.puts("Identity quaternion: #{inspect(q1)}")
    IO.puts("90° Z rotation: #{inspect(q2)}")
    IO.puts("Euler (30°, 45°, 60°): #{inspect(q3)}")

    # Quaternion operations
    IO.puts("\nQuaternion Operations:")
    IO.puts("normalize(q2) = #{inspect(quat_normalize(q2))}")
    IO.puts("conjugate(q2) = #{inspect(quat_conjugate(q2))}")
    IO.puts("q1 * q2 = #{inspect(quat_mul(q1, q2))}")

    # SLERP
    IO.puts("\nSpherical Linear Interpolation:")
    IO.puts("slerp(q1, q2, 0.5) = #{inspect(quat_slerp(q1, q2, 0.5))}")

    # Convert to matrices
    IO.puts("\nConvert to Matrices:")
    mat3_rot = quat_to_mat3(q2)
    mat4_rot = quat_to_mat4(q2)
    IO.puts("quat_to_mat3(q2) = #{inspect(mat3_rot)}")
    IO.puts("quat_to_mat4(q2) = #{inspect(mat4_rot)}")

    # Rotate vectors
    test_vec = vec3(1.0, 0.0, 0.0)
    rotated = quat_rotate_vec3(q2, test_vec)
    IO.puts("\nVector Rotation:")
    IO.puts("rotate #{inspect(test_vec)} by q2 = #{inspect(rotated)}")

    IO.puts("\n=== End Quaternion Operations Demo ===\n")
  end

  @doc """
  Demonstrate matrix operations.
  """
  def matrix_operations_demo do
    IO.puts("=== Matrix Operations Demo ===\n")

    # Create matrices
    identity = mat4_identity()
    translation = mat4_translate(vec3(10.0, 20.0, 30.0))
    scale = mat4_scale(vec3(2.0, 3.0, 4.0))
    rotation_x = mat4_rotate_x(radians(45.0))

    IO.puts("Identity matrix: #{inspect(identity)}")
    IO.puts("Translation(10, 20, 30): #{inspect(translation)}")
    IO.puts("Scale(2, 3, 4): #{inspect(scale)}")
    IO.puts("Rotate X 45°: #{inspect(rotation_x)}")

    # Matrix multiplication
    IO.puts("\nMatrix Operations:")
    combined = mat4_mul(translation, scale)
    IO.puts("translation * scale = #{inspect(combined)}")

    # Transpose
    IO.puts("transpose(rotation_x) = #{inspect(mat4_transpose(rotation_x))}")

    # Matrix inversion
    IO.puts("\nMatrix Inversion:")
    translation_inverse = mat4_inverse(translation)
    scale_inverse = mat4_inverse(scale)
    rotation_inverse = mat4_inverse(rotation_x)

    # Verify M * M^-1 = I
    translation_check = mat4_mul(translation, translation_inverse)
    scale_check = mat4_mul(scale, scale_inverse)
    rotation_check = mat4_mul(rotation_x, rotation_inverse)

    IO.puts("translation * translation^-1 = identity? #{is_identity_matrix?(translation_check)}")
    IO.puts("scale * scale^-1 = identity? #{is_identity_matrix?(scale_check)}")
    IO.puts("rotation * rotation^-1 = identity? #{is_identity_matrix?(rotation_check)}")

    # Combined transformation inversion
    combined_transform = translation |> mat4_mul(rotation_x) |> mat4_mul(scale)
    combined_inverse = mat4_inverse(combined_transform)
    combined_check = mat4_mul(combined_transform, combined_inverse)

    IO.puts(
      "complex_transform * complex_transform^-1 = identity? #{is_identity_matrix?(combined_check)}"
    )

    # Projection matrices
    IO.puts("\nProjection Matrices:")
    perspective = mat4_perspective(radians(45.0), 16.0 / 9.0, 0.1, 100.0)
    orthographic = mat4_ortho(-10.0, 10.0, -10.0, 10.0, 0.1, 100.0)

    IO.puts("Perspective (45° FOV, 16:9): #{inspect(perspective)}")
    IO.puts("Orthographic (-10 to 10): #{inspect(orthographic)}")

    # View matrix and its inverse
    eye = vec3(0.0, 0.0, 5.0)
    center = vec3_zero()
    up = vec3_unit_y()
    view = mat4_look_at(eye, center, up)
    view_inverse = mat4_inverse(view)
    view_check = mat4_mul(view, view_inverse)

    IO.puts("Look-at matrix: #{inspect(view)}")
    IO.puts("look_at * look_at^-1 = identity? #{is_identity_matrix?(view_check)}")

    IO.puts("\n=== End Matrix Operations Demo ===\n")
  end

  @doc """
  Demonstrate utility and trigonometric functions.
  """
  def utility_functions_demo do
    IO.puts("=== Utility Functions Demo ===\n")

    # Angle conversion
    IO.puts("Angle Conversion:")
    IO.puts("radians(180) = #{radians(180.0)}")
    IO.puts("degrees(π) = #{degrees(:math.pi())}")

    # Interpolation and step functions
    IO.puts("\nInterpolation:")
    IO.puts("lerp(0, 10, 0.5) = #{lerp(0.0, 10.0, 0.5)}")
    IO.puts("mix(5, 15, 0.3) = #{mix(5.0, 15.0, 0.3)}")
    IO.puts("smooth_step(0, 1, 0.5) = #{smooth_step(0.0, 1.0, 0.5)}")
    IO.puts("step(5, 7) = #{step(5.0, 7.0)}")

    # Clamping and math functions
    IO.puts("\nMath Functions:")
    IO.puts("clamp(15, 0, 10) = #{clamp(15.0, 0.0, 10.0)}")
    IO.puts("sign(-3.5) = #{sign(-3.5)}")
    IO.puts("abs_val(-7.2) = #{abs_val(-7.2)}")
    IO.puts("fract(3.14159) = #{fract(3.14159)}")
    IO.puts("mod(7.5, 3.0) = #{mod(7.5, 3.0)}")

    # Advanced functions
    IO.puts("\nAdvanced Functions:")
    IO.puts("inverse_sqrt(16) = #{inverse_sqrt(16.0)}")

    IO.puts("\n=== End Utility Functions Demo ===\n")
  end

  @doc """
  Demonstrate typical OpenGL transformation pipeline.
  """
  def transformation_pipeline_demo do
    IO.puts("=== Transformation Pipeline Demo ===\n")

    # Object transformation
    object_position = vec3(5.0, 0.0, 0.0)
    object_rotation = quat_from_axis_angle(vec3_unit_y(), radians(45.0))
    object_scale = vec3(2.0, 1.0, 1.0)

    # Create transformation matrices
    translate_mat = mat4_translate(object_position)
    rotate_mat = quat_to_mat4(object_rotation)
    scale_mat = mat4_scale(object_scale)

    # Combine transformations: T * R * S
    model_matrix =
      translate_mat
      |> mat4_mul(rotate_mat)
      |> mat4_mul(scale_mat)

    IO.puts("Model Matrix (T*R*S): #{inspect(model_matrix)}")

    # Camera/View matrix
    camera_pos = vec3(0.0, 5.0, 10.0)
    look_at_pos = vec3_zero()
    up_vector = vec3_unit_y()
    view_matrix = mat4_look_at(camera_pos, look_at_pos, up_vector)

    IO.puts("View Matrix: #{inspect(view_matrix)}")

    # Projection matrix
    fov = radians(60.0)
    aspect_ratio = 16.0 / 9.0
    near_plane = 0.1
    far_plane = 100.0
    projection_matrix = mat4_perspective(fov, aspect_ratio, near_plane, far_plane)

    IO.puts("Projection Matrix: #{inspect(projection_matrix)}")

    # Final MVP matrix
    mvp_matrix =
      projection_matrix
      |> mat4_mul(view_matrix)
      |> mat4_mul(model_matrix)

    IO.puts("MVP Matrix: #{inspect(mvp_matrix)}")

    # Transform a test vertex
    test_vertex = vec3(1.0, 0.0, 0.0)
    IO.puts("\nTransforming vertex #{inspect(test_vertex)}:")

    # Apply model transformation (simplified - would normally use homogeneous coordinates)
    rotated_vertex = quat_rotate_vec3(object_rotation, test_vertex)
    # Simplified scaling
    scaled_vertex = vec_add(vec_scale(rotated_vertex, 2.0), vec_scale(vec3_zero(), 0.0))
    transformed_vertex = vec_add(scaled_vertex, object_position)

    IO.puts("After model transform: #{inspect(transformed_vertex)}")

    IO.puts("\n=== End Transformation Pipeline Demo ===\n")
  end

  @doc """
  Demonstrate lighting calculations using vectors.
  """
  def lighting_demo do
    IO.puts("=== Lighting Demo ===\n")

    # Scene setup
    light_direction = normalize(vec3(-1.0, -1.0, -1.0))
    # Flat surface pointing up
    surface_normal = vec3_unit_y()
    view_direction = normalize(vec3(0.0, 0.0, 1.0))

    IO.puts("Light direction: #{inspect(light_direction)}")
    IO.puts("Surface normal: #{inspect(surface_normal)}")
    IO.puts("View direction: #{inspect(view_direction)}")

    # Diffuse lighting (Lambert)
    diffuse_intensity = max(0.0, dot(surface_normal, vec_negate(light_direction)))
    IO.puts("\nDiffuse intensity: #{diffuse_intensity}")

    # Specular reflection (Blinn-Phong)
    half_vector = normalize(vec_add(vec_negate(light_direction), view_direction))
    specular_intensity = :math.pow(max(0.0, dot(surface_normal, half_vector)), 32.0)
    IO.puts("Specular intensity: #{specular_intensity}")

    # Reflection vector
    reflection_vector = reflect(light_direction, surface_normal)
    IO.puts("Reflection vector: #{inspect(reflection_vector)}")

    # Calculate lighting colors
    # White light (unused in this simple example)
    _light_color = vec3(1.0, 1.0, 1.0)
    # Red material
    material_diffuse = vec3(0.8, 0.2, 0.2)
    # White specular
    material_specular = vec3(1.0, 1.0, 1.0)
    # Dark ambient
    ambient_color = vec3(0.1, 0.1, 0.1)

    final_diffuse = vec_scale(material_diffuse, diffuse_intensity)
    final_specular = vec_scale(material_specular, specular_intensity)
    final_color = vec_add(vec_add(ambient_color, final_diffuse), final_specular)

    IO.puts("\nFinal lighting calculation:")
    IO.puts("Ambient: #{inspect(ambient_color)}")
    IO.puts("Diffuse: #{inspect(final_diffuse)}")
    IO.puts("Specular: #{inspect(final_specular)}")
    IO.puts("Final color: #{inspect(final_color)}")

    IO.puts("\n=== End Lighting Demo ===\n")
  end

  @doc """
  Example showing how to use these in an OpenGL context.
  """
  def opengl_usage_examples do
    IO.puts("=== OpenGL Usage Examples ===\n")

    # Typical usage in vertex data
    vertices = [
      # Bottom left
      vec3(-1.0, -1.0, 0.0),
      # Bottom right
      vec3(1.0, -1.0, 0.0),
      # Top center
      vec3(0.0, 1.0, 0.0)
    ]

    IO.puts("Triangle vertices: #{inspect(vertices)}")

    # Colors for each vertex
    colors = [
      # Red
      vec3(1.0, 0.0, 0.0),
      # Green
      vec3(0.0, 1.0, 0.0),
      # Blue
      vec3(0.0, 0.0, 1.0)
    ]

    IO.puts("Vertex colors: #{inspect(colors)}")

    # Model transformation matrices
    model_matrix = mat4_identity()
    view_matrix = mat4_identity()
    projection_matrix = mat4_identity()

    IO.puts("Model matrix: #{inspect(model_matrix)}")
    IO.puts("View matrix: #{inspect(view_matrix)}")
    IO.puts("Projection matrix: #{inspect(projection_matrix)}")

    # Lighting vectors
    light_direction = vec3(-1.0, -1.0, -1.0)
    light_color = vec3(1.0, 1.0, 1.0)
    ambient_color = vec3(0.2, 0.2, 0.2)

    IO.puts("Light direction: #{inspect(light_direction)}")
    IO.puts("Light color: #{inspect(light_color)}")
    IO.puts("Ambient color: #{inspect(ambient_color)}")

    IO.puts("\n=== End OpenGL Usage Examples ===\n")
  end

  @doc """
  Run the math example - consistent interface with other examples.
  """
  def run_example(opts \\ []) do
    # Math example doesn't need timeout since it's non-interactive
    _merged_opts = Keyword.merge([], opts)
    IO.puts("EAGL Math Library Comprehensive Demo")
    IO.puts("====================================")
    IO.puts("This example demonstrates all EAGL.Math functionality without OpenGL.")

    constructor_examples()
    vector_operations_demo()
    quaternion_operations_demo()
    matrix_operations_demo()
    utility_functions_demo()
    transformation_pipeline_demo()
    lighting_demo()
    opengl_usage_examples()

    IO.puts("\n====================================")
    IO.puts("Math demo completed successfully!")
    IO.puts("Check out the other examples for OpenGL rendering demos.")
  end

  # Helper function to check if a matrix is approximately identity
  defp is_identity_matrix?(
         [{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p}],
         tolerance \\ 1.0e-6
       ) do
    abs(a - 1.0) < tolerance and abs(b) < tolerance and abs(c) < tolerance and abs(d) < tolerance and
      abs(e) < tolerance and abs(f - 1.0) < tolerance and abs(g) < tolerance and
      abs(h) < tolerance and
      abs(i) < tolerance and abs(j) < tolerance and abs(k - 1.0) < tolerance and
      abs(l) < tolerance and
      abs(m) < tolerance and abs(n) < tolerance and abs(o) < tolerance and
      abs(p - 1.0) < tolerance
  end
end
