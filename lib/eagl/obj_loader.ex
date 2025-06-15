defmodule EAGL.ObjLoader do
  @moduledoc """
  Simple Wavefront OBJ file loader.
  Currently supports vertices, texture coordinates, normals, and faces.
  """

  @doc """
  Loads an OBJ file and returns vertex data ready for OpenGL.
  Returns {:ok, data} where data is a map containing:
    - :vertices - List of floats in x,y,z order
    - :tex_coords - List of floats in u,v order
    - :normals - List of floats in x,y,z order
    - :indices - List of integers for indexed drawing

  Options:
    - :flip_normal_direction - boolean, set to true to flip normal direction for all models (default: false)
                               This works consistently for both models with existing normals and models that need generated normals.
                               For models with existing normals: negates all normal components
                               For models without normals: generates normals with flipped direction
    - :smooth_normals - boolean, set to true to generate smooth normals by averaging across adjacent faces (default: false)
                        This gives a smoother appearance by eliminating the faceted look.
                        When true, existing normals are ignored and smooth normals are generated.
  """
  @spec load_obj(String.t(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def load_obj(file_path, opts \\ []) do
    try do
      # Initial accumulator for parsing
      initial_state = %{
        # Raw vertex positions
        vertices: [],
        # Raw texture coordinates
        tex_coords: [],
        # Raw normals
        normals: [],
        # Face definitions
        faces: [],
        indexed_data: %{
          vertices: [],
          tex_coords: [],
          normals: [],
          indices: []
        }
      }

      # Read and parse the file
      parsed_data =
        File.stream!(file_path)
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(String.length(&1) == 0 || String.starts_with?(&1, "#")))
        |> Enum.reduce(initial_state, &parse_line/2)

      # Process faces to create indexed data
      flip_normal_direction = Keyword.get(opts, :flip_normal_direction, false)
      smooth_normals = Keyword.get(opts, :smooth_normals, false)
      final_data = process_faces(parsed_data, flip_normal_direction, smooth_normals)

      {:ok, final_data}
    rescue
      e -> {:error, "Failed to load OBJ file: #{Exception.message(e)}"}
    end
  end

  # Parse different types of lines in the OBJ file
  defp parse_line(<<"v ", rest::binary>>, state) do
    # Vertex position
    [x, y, z] = String.split(rest) |> Enum.map(&String.to_float/1)
    %{state | vertices: state.vertices ++ [x, y, z]}
  end

  defp parse_line(<<"vt ", rest::binary>>, state) do
    # Texture coordinate
    coords = String.split(rest) |> Enum.map(&String.to_float/1)
    # OBJ can have 1D, 2D, or 3D texture coords. We only use 2D
    # Default to 0.0 if missing
    [u, v | _] = coords ++ [0.0, 0.0]
    %{state | tex_coords: state.tex_coords ++ [u, v]}
  end

  defp parse_line(<<"vn ", rest::binary>>, state) do
    # Normal
    [x, y, z] = String.split(rest) |> Enum.map(&String.to_float/1)
    %{state | normals: state.normals ++ [x, y, z]}
  end

  defp parse_line(<<"f ", rest::binary>>, state) do
    # Face definition
    faces =
      String.split(rest)
      |> Enum.map(fn vertex_str ->
        # Split on / and convert to integers, handling empty strings
        String.split(vertex_str, "/")
        |> Enum.map(fn index_str ->
          case index_str do
            "" -> nil
            str -> String.to_integer(str)
          end
        end)
        |> pad_vertex_data()
      end)

    %{state | faces: state.faces ++ [faces]}
  end

  defp parse_line(_, state), do: state

  # Ensure vertex data always has 3 components [v, vt, vn]
  defp pad_vertex_data(vertex_data) do
    case vertex_data do
      # Only vertex
      [v] -> [v, nil, nil]
      # Vertex and texture
      [v, vt] -> [v, vt, nil]
      # Complete data
      [v, vt, vn] -> [v, vt, vn]
      # Vertex and normal
      [v, nil, vn] -> [v, nil, vn]
      # Invalid data
      _ -> [nil, nil, nil]
    end
  end

  # Process faces to create indexed vertex data
  defp process_faces(data, flip_normal_direction, smooth_normals) do
    # Handle smooth normals first (they override existing normals)
    data_with_normals =
      cond do
        smooth_normals ->
          generate_smooth_normals(data, flip_normal_direction)

        length(data.normals) == 0 ->
          generate_face_normals(data, flip_normal_direction)

        flip_normal_direction ->
          flipped_normals = flip_existing_normals(data.normals)
          %{data | normals: flipped_normals}

        true ->
          data
      end

    # Create a map to store unique vertex combinations
    {indexed_data, _} =
      Enum.reduce(
        data_with_normals.faces,
        {%{vertices: [], tex_coords: [], normals: [], indices: []}, %{}},
        fn face, {acc, vertex_map} ->
          # Convert face (usually a triangle or quad) to triangles
          process_face(face, data_with_normals, acc, vertex_map)
        end
      )

    indexed_data
  end

  defp process_face(face_vertices, data, acc, vertex_map) do
    # Triangulate if necessary (assuming convex polygons)
    triangles = triangulate_face(face_vertices)

    # Process each triangle
    Enum.reduce(triangles, {acc, vertex_map}, fn triangle, {current_acc, current_map} ->
      process_triangle(triangle, data, current_acc, current_map)
    end)
  end

  defp triangulate_face(face_vertices) do
    case length(face_vertices) do
      3 ->
        [face_vertices]

      n when n > 3 ->
        # Fan triangulation - works for convex polygons
        v1 = Enum.at(face_vertices, 0)

        Enum.chunk_every(Enum.slice(face_vertices, 1, n - 1), 2, 1, :discard)
        |> Enum.map(fn [v2, v3] -> [v1, v2, v3] end)

      # Handle invalid faces
      _ ->
        []
    end
  end

  defp process_triangle(triangle, data, acc, vertex_map) do
    Enum.reduce(triangle, {acc, vertex_map}, fn [v_idx, t_idx, n_idx],
                                                {current_acc, current_map} ->
      # Create a unique key for this vertex combination
      vertex_key = {v_idx, t_idx, n_idx}

      case Map.get(current_map, vertex_key) do
        nil ->
          # New unique vertex
          new_index = map_size(current_map)

          # Get the actual vertex data (adjust indices because OBJ is 1-based)
          vertices =
            if v_idx do
              v_offset = (v_idx - 1) * 3
              Enum.slice(data.vertices, v_offset, 3)
            else
              [0.0, 0.0, 0.0]
            end

          # Get texture coordinates if they exist
          tex_coords =
            if t_idx do
              t_offset = (t_idx - 1) * 2
              Enum.slice(data.tex_coords, t_offset, 2)
            else
              [0.0, 0.0]
            end

          # Get normals if they exist
          normals =
            if n_idx do
              n_offset = (n_idx - 1) * 3
              Enum.slice(data.normals, n_offset, 3)
            else
              # Default normal pointing up
              [0.0, 1.0, 0.0]
            end

          {
            %{
              vertices: current_acc.vertices ++ vertices,
              tex_coords: current_acc.tex_coords ++ tex_coords,
              normals: current_acc.normals ++ normals,
              indices: current_acc.indices ++ [new_index]
            },
            Map.put(current_map, vertex_key, new_index)
          }

        existing_index ->
          # Reuse existing vertex
          {
            %{current_acc | indices: current_acc.indices ++ [existing_index]},
            current_map
          }
      end
    end)
  end

  # Generate face normals when none exist in the OBJ file
  defp generate_face_normals(data, flip_normal_direction) do
    # Calculate normals for each face
    face_normals =
      Enum.map(data.faces, fn face ->
        # Get the first triangle of the face (if it has more than 3 vertices, we use the first triangle)
        triangle = Enum.take(face, 3)
        calculate_face_normal(triangle, data.vertices, flip_normal_direction)
      end)

    # Create a normal for each vertex in each face
    # This creates flat shading where all vertices of a face share the same normal
    {normals, updated_faces} =
      data.faces
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {face, face_idx}, {acc_normals, acc_faces} ->
        face_normal = Enum.at(face_normals, face_idx)

        # Create normal entries for each vertex in this face
        face_vertex_count = length(face)

        face_normal_indices =
          Enum.map(1..face_vertex_count, fn i ->
            # 1-based indexing for OBJ
            length(acc_normals) + i
          end)

        # Add the face normal for each vertex
        new_normals = acc_normals ++ List.duplicate(face_normal, face_vertex_count)

        # Update face to reference the new normals
        updated_face =
          face
          |> Enum.with_index()
          |> Enum.map(fn {[v_idx, t_idx, _n_idx], vertex_idx} ->
            normal_idx = Enum.at(face_normal_indices, vertex_idx)
            [v_idx, t_idx, normal_idx]
          end)

        {new_normals, acc_faces ++ [updated_face]}
      end)

    # Flatten the normals list
    flat_normals = Enum.flat_map(normals, fn [x, y, z] -> [x, y, z] end)

    %{data | normals: flat_normals, faces: updated_faces}
  end

  # Generate smooth normals by averaging normals across adjacent faces
  defp generate_smooth_normals(data, flip_normal_direction) do
    vertex_count = div(length(data.vertices), 3)

    # Initialize accumulator for each vertex normal
    vertex_normals = for _ <- 1..vertex_count, do: [0.0, 0.0, 0.0]
    vertex_face_counts = for _ <- 1..vertex_count, do: 0

    # For each face, calculate its normal and add it to each vertex
    {accumulated_normals, face_counts} =
      Enum.reduce(data.faces, {vertex_normals, vertex_face_counts}, fn face,
                                                                       {acc_normals, acc_counts} ->
        # Get the first triangle of the face for normal calculation
        triangle = Enum.take(face, 3)
        face_normal = calculate_face_normal(triangle, data.vertices, flip_normal_direction)

        # Add this face normal to each vertex in the face
        {updated_normals, updated_counts} =
          Enum.reduce(face, {acc_normals, acc_counts}, fn [v_idx, _t_idx, _n_idx],
                                                          {curr_normals, curr_counts} ->
            # Convert to 0-based indexing
            list_idx = v_idx - 1

            # Add face normal to vertex normal
            current_normal = Enum.at(curr_normals, list_idx)
            new_normal = add_vectors(current_normal, face_normal)
            new_normals = List.replace_at(curr_normals, list_idx, new_normal)

            # Increment face count for this vertex
            current_count = Enum.at(curr_counts, list_idx)
            new_counts = List.replace_at(curr_counts, list_idx, current_count + 1)

            {new_normals, new_counts}
          end)

        {updated_normals, updated_counts}
      end)

    # Average the normals and normalize them
    averaged_normals =
      accumulated_normals
      |> Enum.with_index()
      |> Enum.map(fn {normal, idx} ->
        count = Enum.at(face_counts, idx)

        if count > 0 do
          averaged = divide_vector(normal, count)
          normalize_vector(averaged)
        else
          # Default up normal
          [0.0, 1.0, 0.0]
        end
      end)

    # Create normal entries for each vertex in each face
    {normals, updated_faces} =
      data.faces
      |> Enum.reduce({[], []}, fn face, {acc_normals, acc_faces} ->
        # For each vertex in the face, add its smooth normal
        face_normal_indices =
          Enum.map(face, fn [v_idx, _t_idx, _n_idx] ->
            vertex_normal = Enum.at(averaged_normals, v_idx - 1)

            # Add this normal to our list and get its index
            # 1-based indexing for OBJ
            new_normal_idx = length(acc_normals) + 1
            {vertex_normal, new_normal_idx}
          end)

        # Extract normals and indices
        {face_normals, normal_indices} = Enum.unzip(face_normal_indices)
        new_normals = acc_normals ++ face_normals

        # Update face to reference the new normals
        updated_face =
          face
          |> Enum.with_index()
          |> Enum.map(fn {[v_idx, t_idx, _n_idx], vertex_idx} ->
            normal_idx = Enum.at(normal_indices, vertex_idx)
            [v_idx, t_idx, normal_idx]
          end)

        {new_normals, acc_faces ++ [updated_face]}
      end)

    # Flatten the normals list
    flat_normals = Enum.flat_map(normals, fn [x, y, z] -> [x, y, z] end)

    %{data | normals: flat_normals, faces: updated_faces}
  end

  # Calculate normal for a face given three vertex indices
  defp calculate_face_normal(triangle, vertices, flip_normal_direction) do
    # Get the first three vertices of the face
    [[v1_idx, _, _], [v2_idx, _, _], [v3_idx, _, _]] = Enum.take(triangle, 3)

    # Get vertex positions (convert from 1-based to 0-based indexing)
    v1_pos = get_vertex_position(v1_idx, vertices)
    v2_pos = get_vertex_position(v2_idx, vertices)
    v3_pos = get_vertex_position(v3_idx, vertices)

    # Calculate two edges of the triangle
    edge1 = subtract_vectors(v2_pos, v1_pos)
    edge2 = subtract_vectors(v3_pos, v1_pos)

    # Calculate cross product to get normal
    # Default (false) uses edge1 × edge2 which works correctly for CCW-wound faces
    normal =
      if flip_normal_direction do
        # Flipped: edge2 × edge1
        cross_product(edge2, edge1)
      else
        # Standard: edge1 × edge2 for CCW faces
        cross_product(edge1, edge2)
      end

    normalize_vector(normal)
  end

  # Helper functions for vector math
  defp get_vertex_position(vertex_idx, vertices) do
    offset = (vertex_idx - 1) * 3

    [
      Enum.at(vertices, offset) || 0.0,
      Enum.at(vertices, offset + 1) || 0.0,
      Enum.at(vertices, offset + 2) || 0.0
    ]
  end

  defp subtract_vectors([x1, y1, z1], [x2, y2, z2]) do
    [x1 - x2, y1 - y2, z1 - z2]
  end

  defp add_vectors([x1, y1, z1], [x2, y2, z2]) do
    [x1 + x2, y1 + y2, z1 + z2]
  end

  defp divide_vector([x, y, z], scalar) do
    [x / scalar, y / scalar, z / scalar]
  end

  defp cross_product([x1, y1, z1], [x2, y2, z2]) do
    [
      y1 * z2 - z1 * y2,
      z1 * x2 - x1 * z2,
      x1 * y2 - y1 * x2
    ]
  end

  defp normalize_vector([x, y, z]) do
    length = :math.sqrt(x * x + y * y + z * z)
    # Avoid division by zero
    if length > 0.0001 do
      [x / length, y / length, z / length]
    else
      # Default up normal if zero length
      [0.0, 1.0, 0.0]
    end
  end

  # Flip existing normals by negating each component
  defp flip_existing_normals(normals) do
    Enum.map(normals, fn component -> -component end)
  end
end
