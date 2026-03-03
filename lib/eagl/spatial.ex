defmodule EAGL.Spatial do
  @moduledoc """
  Spatial index for ray-based queries (physics, AI line-of-sight, gameplay).

  Builds a BVH (Bounding Volume Hierarchy) from scene bounds and mesh positions.
  Use when GPU picking (Phase 1b) is insufficient—e.g. raycast from arbitrary
  points, physics raycast, AI visibility.

  ## Usage

      # Build from scene (lazy: rebuild on scene change)
      spatial = EAGL.Spatial.new(scene)

      # Raycast
      ray = EAGL.Math.ray_new(origin, direction)
      hits = EAGL.Spatial.raycast(spatial, ray)
      # => [{node, distance}, ...] sorted by distance

  ## Morton codes

  Morton encoding (bit-interleaving) is available in `EAGL.Math.morton_encode/3`
  and `morton_decode/1` for spatial hashing and optional LBVH construction.
  """

  alias EAGL.Node
  alias EAGL.Scene
  alias EAGL.Math

  @type aabb :: {{float(), float(), float()}, {float(), float(), float()}}
  @type ray :: {Math.vec3(), Math.vec3()}
  @type entry :: {Node.t(), aabb()}

  # BVH node: {:leaf, aabb, node} | {:inner, aabb, left, right}
  @type bvh_node :: {:leaf, aabb(), Node.t()} | {:inner, aabb(), bvh_node(), bvh_node()}

  defstruct [:root, :entries]

  @type t :: %__MODULE__{
          root: bvh_node() | nil,
          entries: [entry()]
        }

  @doc """
  Build a spatial index from a scene.

  Extracts nodes with mesh bounds, builds a BVH. Rebuild when the scene changes.
  Returns an empty index if no nodes have bounds.
  """
  @spec new(Scene.t()) :: t()
  def new(%Scene{} = scene) do
    entries = Scene.get_nodes_with_bounds(scene)
    new_from_entries(entries)
  end

  @doc """
  Build a spatial index from a list of `{node, aabb}` entries.

  AABB format: `{{min_x, min_y, min_z}, {max_x, max_y, max_z}}`.
  """
  @spec new_from_entries([entry()]) :: t()
  def new_from_entries(entries) when is_list(entries) do
    root =
      case entries do
        [] -> nil
        [single] -> build_leaf(single)
        _ -> build_bvh(entries)
      end

    %__MODULE__{root: root, entries: entries}
  end

  @doc """
  Cast a ray against the spatial index.

  Returns hits as `[{node, distance}, ...]` sorted by distance (closest first).
  Distance is along the ray from origin. Direction should be normalized.
  """
  @spec raycast(t(), ray()) :: [{Node.t(), float()}]
  def raycast(%__MODULE__{root: nil}, _ray), do: []

  def raycast(%__MODULE__{root: root}, ray) do
    raycast_node(root, ray, [])
    |> Enum.sort_by(fn {_node, t} -> t end)
  end

  defp raycast_node({:leaf, aabb, node}, ray, acc) do
    case Math.ray_intersects_aabb?(ray, aabb) do
      {:hit, t} -> [{node, t} | acc]
      :miss -> acc
    end
  end

  defp raycast_node({:inner, aabb, left, right}, ray, acc) do
    case Math.ray_intersects_aabb?(ray, aabb) do
      :miss ->
        acc

      {:hit, _t} ->
        acc = raycast_node(left, ray, acc)
        raycast_node(right, ray, acc)
    end
  end

  defp build_leaf({node, aabb}), do: {:leaf, aabb, node}

  defp build_bvh(entries) do
    aabb = merge_all_aabbs(Enum.map(entries, fn {_n, b} -> b end))

    case entries do
      [] -> raise "empty entries"
      [single] -> build_leaf(single)
      _ -> split_and_build(entries, aabb)
    end
  end

  defp split_and_build(entries, aabb) do
    axis = longest_axis(aabb)
    sorted = Enum.sort_by(entries, fn {_node, b} -> centroid(b) |> elem(axis) end)
    n = length(sorted)
    mid = div(n, 2)
    {left_entries, right_entries} = Enum.split(sorted, mid)

    left =
      case left_entries do
        [] -> raise "empty left"
        [single] -> build_leaf(single)
        _ -> build_bvh(left_entries)
      end

    right =
      case right_entries do
        [] -> raise "empty right"
        [single] -> build_leaf(single)
        _ -> build_bvh(right_entries)
      end

    {:inner, aabb, left, right}
  end

  defp centroid({{min_x, min_y, min_z}, {max_x, max_y, max_z}}) do
    {(min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2}
  end

  defp longest_axis({{min_x, min_y, min_z}, {max_x, max_y, max_z}}) do
    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z

    cond do
      dx >= dy and dx >= dz -> 0
      dy >= dx and dy >= dz -> 1
      true -> 2
    end
  end

  defp merge_all_aabbs([]), do: raise("empty aabbs")

  defp merge_all_aabbs([first | rest]) do
    Enum.reduce(rest, first, &merge_aabb/2)
  end

  defp merge_aabb(
         {{a_min_x, a_min_y, a_min_z}, {a_max_x, a_max_y, a_max_z}},
         {{b_min_x, b_min_y, b_min_z}, {b_max_x, b_max_y, b_max_z}}
       ) do
    {{min(a_min_x, b_min_x), min(a_min_y, b_min_y), min(a_min_z, b_min_z)},
     {max(a_max_x, b_max_x), max(a_max_y, b_max_y), max(a_max_z, b_max_z)}}
  end
end
