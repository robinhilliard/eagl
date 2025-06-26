defmodule GLTF.Skin do
  @moduledoc """
  Joints and matrices defining a skin.
  """

  defstruct [
    :inverse_bind_matrices,
    :skeleton,
    :joints,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
          inverse_bind_matrices: non_neg_integer() | nil,
          skeleton: non_neg_integer() | nil,
          joints: [non_neg_integer()],
          name: String.t() | nil,
          extensions: map() | nil,
          extras: any() | nil
        }

  @doc """
  Create a new skin with required joints.
  """
  def new(joints, opts \\ []) when is_list(joints) and length(joints) > 0 do
    %__MODULE__{
      joints: joints,
      inverse_bind_matrices: Keyword.get(opts, :inverse_bind_matrices),
      skeleton: Keyword.get(opts, :skeleton),
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Get the number of joints in this skin.
  """
  def joint_count(%__MODULE__{joints: joints}) when is_list(joints), do: length(joints)
  def joint_count(%__MODULE__{}), do: 0

  @doc """
  Check if skin has inverse bind matrices.
  """
  def has_inverse_bind_matrices?(%__MODULE__{inverse_bind_matrices: nil}), do: false
  def has_inverse_bind_matrices?(%__MODULE__{inverse_bind_matrices: _}), do: true

  @doc """
  Check if skin has a skeleton root specified.
  """
  def has_skeleton?(%__MODULE__{skeleton: nil}), do: false
  def has_skeleton?(%__MODULE__{skeleton: _}), do: true

  @doc """
  Load a Skin struct from JSON data.
  """
  def load(json_data) when is_map(json_data) do
    skin = %__MODULE__{
      inverse_bind_matrices: json_data["inverseBindMatrices"],
      skeleton: json_data["skeleton"],
      joints: json_data["joints"],
      name: json_data["name"],
      extensions: json_data["extensions"],
      extras: json_data["extras"]
    }

    # Validate that joints array is present and not empty
    case skin.joints do
      nil -> {:error, :missing_joints}
      [] -> {:error, :empty_joints_array}
      joints when is_list(joints) -> {:ok, skin}
      _ -> {:error, :invalid_joints}
    end
  end
end
