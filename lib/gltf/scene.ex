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
  Check if scene has any root nodes.
  """
  def has_nodes?(%__MODULE__{nodes: nil}), do: false
  def has_nodes?(%__MODULE__{nodes: []}), do: false
  def has_nodes?(%__MODULE__{nodes: _}), do: true

  @doc """
  Get root node count.
  """
  def node_count(%__MODULE__{nodes: nil}), do: 0
  def node_count(%__MODULE__{nodes: nodes}), do: length(nodes)
end
