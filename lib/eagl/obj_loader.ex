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
    - :async - boolean, set to true to enable parallel processing for normal generation (default: true)
               This can significantly speed up loading of complex models on multi-core systems.
               Set to false to disable parallel processing (useful for debugging or single-core systems).
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
      async = Keyword.get(opts, :async, true)
      final_data = process_faces(parsed_data, flip_normal_direction, smooth_normals, async)

      {:ok, final_data}
    rescue
      e -> {:error, "Failed to load OBJ file: #{Exception.message(e)}"}
    end
  end

  # Parse different types of lines in the OBJ file
  # PERFORMANCE: Use list prepending (O(1)) instead of appending (O(n))
  # Lists will be reversed at the end of parsing
  defp parse_line(<<"v ", rest::binary>>, state) do
    # Vertex position
    [x, y, z] = String.split(rest, " ", trim: true) |> Enum.map(&String.to_float/1)
    %{state | vertices: [z, y, x | state.vertices]}  # Prepend in reverse order
  end

  defp parse_line(<<"vt ", rest::binary>>, state) do
    # Texture coordinate
    coords = String.split(rest, " ", trim: true) |> Enum.map(&String.to_float/1)
    # OBJ can have 1D, 2D, or 3D texture coords. We only use 2D
    # Default to 0.0 if missing
    [u, v | _] = coords ++ [0.0, 0.0]
    %{state | tex_coords: [v, u | state.tex_coords]}  # Prepend in reverse order
  end

  defp parse_line(<<"vn ", rest::binary>>, state) do
    # Normal
    [x, y, z] = String.split(rest, " ", trim: true) |> Enum.map(&String.to_float/1)
    %{state | normals: [z, y, x | state.normals]}  # Prepend in reverse order
  end

  defp parse_line(<<"f ", rest::binary>>, state) do
    # Face definition
    faces =
      String.split(rest, " ", trim: true)
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

    %{state | faces: [faces | state.faces]}  # Prepend
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
  defp process_faces(data, flip_normal_direction, smooth_normals, async) do
    # PERFORMANCE: Reverse accumulated lists since we prepended during parsing
    corrected_data = %{
      vertices: Enum.reverse(data.vertices),
      tex_coords: Enum.reverse(data.tex_coords),
      normals: Enum.reverse(data.normals),
      faces: Enum.reverse(data.faces)
    }

    # Handle smooth normals first (they override existing normals)
    data_with_normals =
      cond do
        smooth_normals ->
          generate_smooth_normals(corrected_data, flip_normal_direction, async)

        length(corrected_data.normals) == 0 ->
          generate_face_normals(corrected_data, flip_normal_direction, async)

        flip_normal_direction ->
          flipped_normals = flip_existing_normals(corrected_data.normals)
          %{corrected_data | normals: flipped_normals}

        true ->
          corrected_data
      end

    # PERFORMANCE: Pre-chunk all data once at the beginning
    chunked_data = %{
      vertex_chunks: Enum.chunk_every(data_with_normals.vertices, 3),
      normal_chunks: Enum.chunk_every(data_with_normals.normals, 3),
      texcoord_chunks: Enum.chunk_every(data_with_normals.tex_coords, 2)
    }

    # Create a map to store unique vertex combinations
    {indexed_data, _} =
      Enum.reduce(
        data_with_normals.faces,
        {%{vertices: [], tex_coords: [], normals: [], indices: []}, %{}},
        fn face, {acc, vertex_map} ->
          # Convert face (usually a triangle or quad) to triangles
          process_face(face, chunked_data, acc, vertex_map)
        end
      )

    # PERFORMANCE: Reverse the accumulated lists since we prepended during processing
    %{
      vertices: Enum.reverse(indexed_data.vertices),
      tex_coords: Enum.reverse(indexed_data.tex_coords),
      normals: Enum.reverse(indexed_data.normals),
      indices: Enum.reverse(indexed_data.indices)
    }
  end

  defp process_face(face_vertices, chunked_data, acc, vertex_map) do
    # Triangulate if necessary (assuming convex polygons)
    triangles = triangulate_face(face_vertices)

    # Process each triangle
    Enum.reduce(triangles, {acc, vertex_map}, fn triangle, {current_acc, current_map} ->
      process_triangle(triangle, chunked_data, current_acc, current_map)
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

  defp process_triangle(triangle, chunked_data, acc, vertex_map) do
    Enum.reduce(triangle, {acc, vertex_map}, fn [v_idx, t_idx, n_idx],
                                                {current_acc, current_map} ->
      # Create a unique key for this vertex combination
      vertex_key = {v_idx, t_idx, n_idx}

      case Map.get(current_map, vertex_key) do
        nil ->
          # New unique vertex
          new_index = map_size(current_map)

          # Get the actual vertex data using pre-chunked data
          [x, y, z] =
            if v_idx do
              Enum.at(chunked_data.vertex_chunks, v_idx - 1) || [0.0, 0.0, 0.0]
            else
              [0.0, 0.0, 0.0]
            end

          # Get texture coordinates if they exist
          [u, v] =
            if t_idx do
              Enum.at(chunked_data.texcoord_chunks, t_idx - 1) || [0.0, 0.0]
            else
              [0.0, 0.0]
            end

          # Get normals if they exist
          [nx, ny, nz] =
            if n_idx do
              Enum.at(chunked_data.normal_chunks, n_idx - 1) || [0.0, 1.0, 0.0]
            else
              # Default normal pointing up
              [0.0, 1.0, 0.0]
            end

          # PERFORMANCE: Use prepending (O(1)) instead of concatenation (O(n))
          {
            %{
              vertices: [z, y, x | current_acc.vertices],
              tex_coords: [v, u | current_acc.tex_coords],
              normals: [nz, ny, nx | current_acc.normals],
              indices: [new_index | current_acc.indices]
            },
            Map.put(current_map, vertex_key, new_index)
          }

        existing_index ->
          # Reuse existing vertex - only add index
          {
            %{current_acc | indices: [existing_index | current_acc.indices]},
            current_map
          }
      end
    end)
  end

  # Generate face normals when none exist in the OBJ file
  defp generate_face_normals(data, flip_normal_direction, async) do
    # PERFORMANCE: Pre-chunk vertices for faster access
    vertex_chunks = Enum.chunk_every(data.vertices, 3)

            # ASYNC: Calculate normals for each face in parallel
    # Temporarily using simpler approach to debug the issue
    face_normals =
      if async and length(data.faces) > 10000 do
        # Higher threshold and simpler approach for debugging
        chunk_size = max(div(length(data.faces), System.schedulers_online()), 50)

                # Create data tuples to avoid closure issues
        face_chunks_with_data =
          data.faces
          |> Enum.chunk_every(chunk_size)
          |> Enum.map(fn chunk -> {chunk, vertex_chunks, flip_normal_direction} end)

        face_chunks_with_data
        |> Task.async_stream(
          fn {face_chunk, v_chunks, flip_dir} ->
            Enum.map(face_chunk, fn face ->
              triangle = Enum.take(face, 3)
              calculate_face_normal_optimized(triangle, v_chunks, flip_dir)
            end)
          end,
          max_concurrency: System.schedulers_online(),
          timeout: :infinity
        )
        |> Enum.map(fn {:ok, normals} -> normals end)
        |> List.flatten()
      else
        # Sequential processing for smaller models or when async is disabled
        Enum.map(data.faces, fn face ->
          triangle = Enum.take(face, 3)
          calculate_face_normal_optimized(triangle, vertex_chunks, flip_normal_direction)
        end)
      end

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
  defp generate_smooth_normals(data, flip_normal_direction, async) do
    vertex_count = div(length(data.vertices), 3)

    # PERFORMANCE: Pre-chunk vertices for faster access
    vertex_chunks = Enum.chunk_every(data.vertices, 3)

    # Initialize accumulator for each vertex normal
    vertex_normals = for _ <- 1..vertex_count, do: [0.0, 0.0, 0.0]
    vertex_face_counts = for _ <- 1..vertex_count, do: 0

    # ASYNC: Calculate face normals in parallel for the first phase
    # Use chunked processing to reduce task overhead
    face_normals_with_faces =
      if async and length(data.faces) > 10000 do
        # Parallel processing with chunked batches for better efficiency
        chunk_size = max(div(length(data.faces), System.schedulers_online() * 2), 10)

        face_chunks_with_data =
          data.faces
          |> Enum.chunk_every(chunk_size)
          |> Enum.map(fn chunk -> {chunk, vertex_chunks, flip_normal_direction} end)

        face_chunks_with_data
        |> Task.async_stream(
          fn {face_chunk, v_chunks, flip_dir} ->
            Enum.map(face_chunk, fn face ->
              triangle = Enum.take(face, 3)
              face_normal = calculate_face_normal_optimized(triangle, v_chunks, flip_dir)
              {face, face_normal}
            end)
          end,
          max_concurrency: System.schedulers_online(),
          timeout: :infinity
        )
        |> Enum.map(fn {:ok, results} -> results end)
        |> List.flatten()
      else
        # Sequential processing for smaller models or when async is disabled
        Enum.map(data.faces, fn face ->
          triangle = Enum.take(face, 3)
          face_normal = calculate_face_normal_optimized(triangle, vertex_chunks, flip_normal_direction)
          {face, face_normal}
        end)
      end

    # Accumulate normals per vertex (this part is harder to parallelize due to shared state)
    {accumulated_normals, face_counts} =
      Enum.reduce(face_normals_with_faces, {vertex_normals, vertex_face_counts},
        fn {face, face_normal}, {acc_normals, acc_counts} ->
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

    # ASYNC: Average and normalize normals in parallel
    # Use chunked processing to reduce task overhead
    averaged_normals =
      if async and length(accumulated_normals) > 20000 do
        # Parallel processing with chunked batches for better efficiency
        chunk_size = max(div(length(accumulated_normals), System.schedulers_online() * 2), 50)

        normal_chunks_with_data =
          accumulated_normals
          |> Enum.with_index()
          |> Enum.chunk_every(chunk_size)
          |> Enum.map(fn chunk -> {chunk, face_counts} end)

        normal_chunks_with_data
        |> Task.async_stream(
          fn {chunk, counts} ->
            Enum.map(chunk, fn {normal, idx} ->
              count = Enum.at(counts, idx)

              if count > 0 do
                averaged = divide_vector(normal, count)
                normalize_vector(averaged)
              else
                # Default up normal
                [0.0, 1.0, 0.0]
              end
            end)
          end,
          max_concurrency: System.schedulers_online(),
          timeout: :infinity
        )
        |> Enum.map(fn {:ok, normals} -> normals end)
        |> List.flatten()
      else
        # Sequential processing for smaller models or when async is disabled
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
      end

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

  # PERFORMANCE: Optimized version using pre-chunked vertices
  defp calculate_face_normal_optimized(triangle, vertex_chunks, flip_normal_direction) do
    # Get the first three vertices of the face
    [[v1_idx, _, _], [v2_idx, _, _], [v3_idx, _, _]] = Enum.take(triangle, 3)

    # Get vertex positions using direct chunk access (faster than Enum.slice)
    v1_pos = Enum.at(vertex_chunks, v1_idx - 1) || [0.0, 0.0, 0.0]
    v2_pos = Enum.at(vertex_chunks, v2_idx - 1) || [0.0, 0.0, 0.0]
    v3_pos = Enum.at(vertex_chunks, v3_idx - 1) || [0.0, 0.0, 0.0]

    # Calculate two edges of the triangle
    edge1 = subtract_vectors(v2_pos, v1_pos)
    edge2 = subtract_vectors(v3_pos, v1_pos)

    # Calculate cross product to get normal
    normal =
      if flip_normal_direction do
        cross_product(edge2, edge1)
      else
        cross_product(edge1, edge2)
      end

    normalize_vector(normal)
  end

  # Helper functions for vector math

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
