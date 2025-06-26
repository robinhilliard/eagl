defmodule GLTF.Scene do
  @moduledoc """
  The root nodes of a scene.
  """

  defstruct [
    :nodes,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          nodes: [non_neg_integer()] | nil,
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new scene.
  """
  def new(opts \\ []) do
    %__MODULE__{
      nodes: Keyword.get(opts, :nodes),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a scene with root nodes.
  """
  def with_nodes(node_indices, opts \\ []) when is_list(node_indices) do
    %__MODULE__{
      nodes: node_indices,
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if this scene has any nodes.
  """
  def has_nodes?(%__MODULE__{nodes: nil}), do: false
  def has_nodes?(%__MODULE__{nodes: []}), do: false
  def has_nodes?(%__MODULE__{nodes: _}), do: true

  @doc """
  Get root node count.
  """
  def node_count(%__MODULE__{nodes: nil}), do: 0
  def node_count(%__MODULE__{nodes: nodes}), do: length(nodes)

  @doc """
  Load a Scene struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    scene = %__MODULE__{
      nodes: json_data["nodes"],
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    {:ok, scene}
  end
end
