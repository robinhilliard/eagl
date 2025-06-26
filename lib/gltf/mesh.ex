defmodule GLTF.Mesh do
  @moduledoc """
  A set of primitives to be rendered. A client implementation must render all primitives in the same mode.
  """

  defstruct [
    :primitives,
    :weights,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          primitives: [GLTF.Mesh.Primitive.t()],
          weights: [float()] | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new mesh with primitives.
  """
  def new(primitives, opts \\ []) when is_list(primitives) do
    %__MODULE__{
      primitives: primitives,
      weights: Keyword.get(opts, :weights),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if this mesh has morph targets (shape keys).
  """
  def has_morph_targets?(%__MODULE__{weights: nil}), do: false
  def has_morph_targets?(%__MODULE__{weights: []}), do: false
  def has_morph_targets?(%__MODULE__{weights: _}), do: true

  @doc """
  Load a Mesh struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    # Load primitives with validation
    case json_data["primitives"] do
      nil ->
        {:error, :missing_primitives}

      [] ->
        {:error, :missing_primitives}

      primitives_data when is_list(primitives_data) ->
        case load_primitives(primitives_data) do
          {:ok, primitives} ->
            mesh = %__MODULE__{
              primitives: primitives,
              weights: json_data["weights"],
              name: json_data["name"],
              extensions: json_data["extensions"],
              extras: json_data["extras"]
            }

            {:ok, mesh}

          {:error, reason} ->
            {:error, reason}
        end

      _ ->
        {:error, :missing_primitives}
    end
  end

  # Load and validate all primitives
  defp load_primitives(primitives_data) do
    primitives_data
    |> Enum.reduce_while({:ok, []}, fn primitive_data, {:ok, acc} ->
      case load_primitive(primitive_data) do
        {:ok, primitive} -> {:cont, {:ok, [primitive | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, primitives} -> {:ok, Enum.reverse(primitives)}
      error -> error
    end
  end

  defp load_primitive(primitive_data) when is_map(primitive_data) do
    with {:ok, attributes} <- validate_attributes(primitive_data["attributes"]),
         {:ok, mode} <- parse_mode(primitive_data["mode"]),
         {:ok, targets} <- load_targets(primitive_data["targets"]),
         {:ok, indices} <- validate_indices(primitive_data["indices"]),
         {:ok, material} <- validate_material(primitive_data["material"]) do
      primitive = %{
        __struct__: GLTF.Mesh.Primitive,
        attributes: attributes,
        indices: indices,
        material: material,
        mode: mode,
        targets: targets,
        extensions: primitive_data["extensions"],
        extras: primitive_data["extras"]
      }

      {:ok, primitive}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_primitive(_), do: {:error, :invalid_primitive_format}

  # Validate attributes map and ensure POSITION is present
  defp validate_attributes(nil), do: {:error, :missing_position_attribute}

  defp validate_attributes(attributes) when is_map(attributes) do
    cond do
      not Map.has_key?(attributes, "POSITION") ->
        {:error, :missing_position_attribute}

      not Enum.all?(attributes, fn {k, v} -> is_binary(k) and is_integer(v) end) ->
        {:error, :invalid_primitive_format}

      true ->
        {:ok, attributes}
    end
  end

  defp validate_attributes(_), do: {:error, :invalid_primitive_format}

  # Parse and validate primitive mode
  # Default mode
  defp parse_mode(nil), do: {:ok, :triangles}

  defp parse_mode(mode_int) when is_integer(mode_int) do
    case GLTF.Mesh.Primitive.primitive_modes()[mode_int] do
      nil -> {:error, {:invalid_primitive_mode, mode_int}}
      mode_atom -> {:ok, mode_atom}
    end
  end

  defp parse_mode(_), do: {:error, :invalid_primitive_format}

  # Load morph targets
  defp load_targets(nil), do: {:ok, nil}
  defp load_targets([]), do: {:ok, nil}

  defp load_targets(targets) when is_list(targets) do
    # Keep as-is, they are maps of attribute indices
    {:ok, targets}
  end

  defp load_targets(_), do: {:error, :invalid_primitive_format}

  # Validate indices accessor index
  defp validate_indices(nil), do: {:ok, nil}
  defp validate_indices(indices) when is_integer(indices) and indices >= 0, do: {:ok, indices}
  defp validate_indices(_), do: {:error, :invalid_primitive_format}

  # Validate material index
  defp validate_material(nil), do: {:ok, nil}

  defp validate_material(material) when is_integer(material) and material >= 0,
    do: {:ok, material}

  defp validate_material(_), do: {:error, :invalid_primitive_format}
end

defmodule GLTF.Mesh.Primitive do
  @moduledoc """
  Geometry to be rendered with the given material.
  """

  defstruct [
    :attributes,
    :indices,
    :material,
    :mode,
    :targets,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          attributes: %{String.t() => non_neg_integer()},
          indices: non_neg_integer() | nil,
          material: non_neg_integer() | nil,
          mode: primitive_mode(),
          targets: [%{String.t() => non_neg_integer()}] | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @type primitive_mode ::
          :points
          | :lines
          | :line_loop
          | :line_strip
          | :triangles
          | :triangle_strip
          | :triangle_fan

  # WebGL primitive modes
  @points 0
  @lines 1
  @line_loop 2
  @line_strip 3
  @triangles 4
  @triangle_strip 5
  @triangle_fan 6

  def primitive_modes do
    %{
      @points => :points,
      @lines => :lines,
      @line_loop => :line_loop,
      @line_strip => :line_strip,
      @triangles => :triangles,
      @triangle_strip => :triangle_strip,
      @triangle_fan => :triangle_fan
    }
  end

  @doc """
  Create a new primitive.
  """
  def new(attributes, opts \\ []) when is_map(attributes) do
    %__MODULE__{
      attributes: attributes,
      indices: Keyword.get(opts, :indices),
      material: Keyword.get(opts, :material),
      mode: Keyword.get(opts, :mode, :triangles),
      targets: Keyword.get(opts, :targets),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Standard vertex attribute names.
  """
  def standard_attributes do
    [
      "POSITION",
      "NORMAL",
      "TANGENT",
      "TEXCOORD_0",
      "TEXCOORD_1",
      "COLOR_0",
      "JOINTS_0",
      "WEIGHTS_0"
    ]
  end

  @doc """
  Check if attribute name is application-specific (starts with underscore).
  """
  def application_specific?("_" <> _), do: true
  def application_specific?(_), do: false
end
