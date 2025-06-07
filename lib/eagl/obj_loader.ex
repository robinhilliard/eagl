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
  """
  @spec load_obj(String.t()) :: {:ok, map()} | {:error, String.t()}
  def load_obj(file_path) do
    try do
      # Initial accumulator for parsing
      initial_state = %{
        vertices: [],    # Raw vertex positions
        tex_coords: [],  # Raw texture coordinates
        normals: [],     # Raw normals
        faces: [],       # Face definitions
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
      final_data = process_faces(parsed_data)

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
    [u, v | _] = coords ++ [0.0, 0.0]  # Default to 0.0 if missing
    %{state | tex_coords: state.tex_coords ++ [u, v]}
  end

  defp parse_line(<<"vn ", rest::binary>>, state) do
    # Normal
    [x, y, z] = String.split(rest) |> Enum.map(&String.to_float/1)
    %{state | normals: state.normals ++ [x, y, z]}
  end

  defp parse_line(<<"f ", rest::binary>>, state) do
    # Face definition
    faces = String.split(rest)
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
      [v] -> [v, nil, nil]                    # Only vertex
      [v, vt] -> [v, vt, nil]                 # Vertex and texture
      [v, vt, vn] -> [v, vt, vn]             # Complete data
      [v, nil, vn] -> [v, nil, vn]           # Vertex and normal
      _ -> [nil, nil, nil]                    # Invalid data
    end
  end

  # Process faces to create indexed vertex data
  defp process_faces(data) do
    # Create a map to store unique vertex combinations
    {indexed_data, _} = Enum.reduce(data.faces, {%{vertices: [], tex_coords: [], normals: [], indices: []}, %{}}, fn face, {acc, vertex_map} ->
      # Convert face (usually a triangle or quad) to triangles
      process_face(face, data, acc, vertex_map)
    end)

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
      3 -> [face_vertices]
      n when n > 3 ->
        # Fan triangulation - works for convex polygons
        v1 = Enum.at(face_vertices, 0)
        Enum.chunk_every(Enum.slice(face_vertices, 1, n-1), 2, 1, :discard)
        |> Enum.map(fn [v2, v3] -> [v1, v2, v3] end)
      _ -> []  # Handle invalid faces
    end
  end

  defp process_triangle(triangle, data, acc, vertex_map) do
    Enum.reduce(triangle, {acc, vertex_map}, fn [v_idx, t_idx, n_idx], {current_acc, current_map} ->
      # Create a unique key for this vertex combination
      vertex_key = {v_idx, t_idx, n_idx}

      case Map.get(current_map, vertex_key) do
        nil ->
          # New unique vertex
          new_index = map_size(current_map)

          # Get the actual vertex data (adjust indices because OBJ is 1-based)
          vertices = if v_idx do
            v_offset = (v_idx - 1) * 3
            Enum.slice(data.vertices, v_offset, 3)
          else
            [0.0, 0.0, 0.0]
          end

          # Get texture coordinates if they exist
          tex_coords = if t_idx do
            t_offset = (t_idx - 1) * 2
            Enum.slice(data.tex_coords, t_offset, 2)
          else
            [0.0, 0.0]
          end

          # Get normals if they exist
          normals = if n_idx do
            n_offset = (n_idx - 1) * 3
            Enum.slice(data.normals, n_offset, 3)
          else
            [0.0, 1.0, 0.0]  # Default normal pointing up
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
end
