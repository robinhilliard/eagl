defmodule EAGL.Math.Bounds do
  @moduledoc """
  Axis-aligned bounding box (AABB) utilities.

  AABB format: `{{min_x, min_y, min_z}, {max_x, max_y, max_z}}`.
  Compatible with `EAGL.Scene.bounds/1` which returns `{:ok, min_point, max_point}`.
  """

  @type aabb :: {{float(), float(), float()}, {float(), float(), float()}}

  @doc """
  Check if a point is inside an AABB (inclusive bounds).

  ## Examples

      iex> EAGL.Math.Bounds.contains_point?({{0, 0, 0}, {1, 1, 1}}, [{0.5, 0.5, 0.5}])
      true
      iex> EAGL.Math.Bounds.contains_point?({{0, 0, 0}, {1, 1, 1}}, [{1.5, 0.5, 0.5}])
      false
  """
  @spec contains_point?(aabb(), EAGL.Math.vec3()) :: boolean()
  def contains_point?({{min_x, min_y, min_z}, {max_x, max_y, max_z}}, [{x, y, z}]) do
    x >= min_x and x <= max_x and y >= min_y and y <= max_y and z >= min_z and z <= max_z
  end

  @doc """
  Check if two AABBs intersect.

  ## Examples

      iex> EAGL.Math.Bounds.intersects?({{0, 0, 0}, {1, 1, 1}}, {{0.5, 0.5, 0.5}, {2, 2, 2}})
      true
      iex> EAGL.Math.Bounds.intersects?({{0, 0, 0}, {1, 1, 1}}, {{2, 2, 2}, {3, 3, 3}})
      false
  """
  @spec intersects?(aabb(), aabb()) :: boolean()
  def intersects?(
        {{a_min_x, a_min_y, a_min_z}, {a_max_x, a_max_y, a_max_z}},
        {{b_min_x, b_min_y, b_min_z}, {b_max_x, b_max_y, b_max_z}}
      ) do
    a_min_x <= b_max_x and a_max_x >= b_min_x and
      a_min_y <= b_max_y and a_max_y >= b_min_y and
      a_min_z <= b_max_z and a_max_z >= b_min_z
  end

  @doc """
  Check if a ray intersects an AABB.

  Ray format: `{origin, direction}` where both are vec3 `[{x, y, z}]`.
  Direction should be normalized for correct distance semantics.
  """
  @spec intersects_ray?(aabb(), {EAGL.Math.vec3(), EAGL.Math.vec3()}) :: boolean()
  def intersects_ray?(aabb, ray) do
    case EAGL.Math.ray_intersects_aabb?(ray, aabb) do
      {:hit, _t} -> true
      :miss -> false
    end
  end
end
