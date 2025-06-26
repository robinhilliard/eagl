defmodule GLTF.Extras do
  @moduledoc """
  Application-specific data support for glTF.

  The 'extras' property can be used to store application-specific data.
  This data is preserved during import/export but is not used by the glTF specification itself.
  """

  @type t :: any()

  @doc """
  Check if extras data is valid JSON-serializable data.
  """
  def valid?(data) do
    try do
      # Attempt to encode as JSON to validate structure
      # Try Jason first, fall back to Poison if available
      cond do
        Code.ensure_loaded?(Jason) ->
          Jason.encode!(data)
          true

        Code.ensure_loaded?(Poison) ->
          Poison.encode!(data)
          true

        true ->
          # No JSON library available, assume valid for basic data types
          is_json_serializable?(data)
      end
    rescue
      _ -> false
    end
  end

  # Helper to check if data is JSON-serializable without encoding
  defp is_json_serializable?(data)
       when is_nil(data) or is_boolean(data) or is_number(data) or is_binary(data),
       do: true

  defp is_json_serializable?(data) when is_list(data),
    do: Enum.all?(data, &is_json_serializable?/1)

  defp is_json_serializable?(data) when is_map(data) do
    Enum.all?(data, fn {k, v} -> is_binary(k) and is_json_serializable?(v) end)
  end

  defp is_json_serializable?(_), do: false

  @doc """
  Get a value from extras data using a path.
  """
  def get_in(extras, path) when is_map(extras) and is_list(path) do
    Kernel.get_in(extras, path)
  end

  def get_in(_, _), do: nil

  @doc """
  Put a value into extras data using a path.
  """
  def set_in(extras, path, value) when is_map(extras) and is_list(path) do
    Kernel.put_in(extras, path, value)
  end

  def set_in(extras, path, value) when is_nil(extras) and is_list(path) do
    set_in(%{}, path, value)
  end

  @doc """
  Merge two extras maps.
  """
  def merge(extras1, extras2) when is_map(extras1) and is_map(extras2) do
    Map.merge(extras1, extras2)
  end

  def merge(nil, extras2) when is_map(extras2), do: extras2
  def merge(extras1, nil) when is_map(extras1), do: extras1
  def merge(nil, nil), do: nil

  @doc """
  Common extras keys used by various tools.
  """
  def common_keys do
    %{
      # Blender
      "targetNames" => "Array of morph target names (Blender export)",

      # Various tools
      "author" => "Content author information",
      "license" => "License information",
      "source" => "Source application information",
      "title" => "Asset title",
      "description" => "Asset description",

      # Custom application data
      "userData" => "Custom user data",
      "metadata" => "Additional metadata"
    }
  end
end
