defmodule GLTF.Camera do
  @moduledoc """
  A camera's projection. A node can reference a camera to apply a transform to place the camera in the scene.
  """

  defstruct [
    :orthographic,
    :perspective,
    :type,
    :name,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    orthographic: GLTF.Camera.Orthographic.t() | nil,
    perspective: GLTF.Camera.Perspective.t() | nil,
    type: camera_type(),
    name: String.t() | nil,
    extensions: map() | nil,
    extras: any() | nil
  }

  @type camera_type :: :perspective | :orthographic

  def camera_types do
    [:perspective, :orthographic]
  end

  @doc """
  Create a new perspective camera.
  """
  def perspective(yfov, znear, opts \\ []) do
    perspective_props = GLTF.Camera.Perspective.new(yfov, znear, opts)

    %__MODULE__{
      type: :perspective,
      perspective: perspective_props,
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Create a new orthographic camera.
  """
  def orthographic(xmag, ymag, zfar, znear, opts \\ []) do
    orthographic_props = GLTF.Camera.Orthographic.new(xmag, ymag, zfar, znear, opts)

    %__MODULE__{
      type: :orthographic,
      orthographic: orthographic_props,
      name: Keyword.get(opts, :name),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end
end

defmodule GLTF.Camera.Perspective do
  @moduledoc """
  A perspective camera containing properties to create a perspective projection matrix.
  """

  defstruct [
    :aspect_ratio,
    :yfov,
    :zfar,
    :znear,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    aspect_ratio: float() | nil,
    yfov: float(),
    zfar: float() | nil,
    znear: float(),
    extensions: map() | nil,
    extras: any() | nil
  }

  @doc """
  Create a new perspective camera configuration.
  """
  def new(yfov, znear, opts \\ []) when is_number(yfov) and is_number(znear) and znear > 0 do
    %__MODULE__{
      yfov: yfov,
      znear: znear,
      aspect_ratio: Keyword.get(opts, :aspect_ratio),
      zfar: Keyword.get(opts, :zfar),
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end

  @doc """
  Check if this camera uses infinite projection (no zfar defined).
  """
  def infinite?(%__MODULE__{zfar: nil}), do: true
  def infinite?(%__MODULE__{}), do: false
end

defmodule GLTF.Camera.Orthographic do
  @moduledoc """
  An orthographic camera containing properties to create an orthographic projection matrix.
  """

  defstruct [
    :xmag,
    :ymag,
    :zfar,
    :znear,
    :extensions,
    :extras
  ]

  @type t :: %__MODULE__{
    xmag: float(),
    ymag: float(),
    zfar: float(),
    znear: float(),
    extensions: map() | nil,
    extras: any() | nil
  }

  @doc """
  Create a new orthographic camera configuration.
  """
  def new(xmag, ymag, zfar, znear, opts \\ [])
      when is_number(xmag) and is_number(ymag) and is_number(zfar) and is_number(znear) and znear >= 0 do
    %__MODULE__{
      xmag: xmag,
      ymag: ymag,
      zfar: zfar,
      znear: znear,
      extensions: Keyword.get(opts, :extensions),
      extras: Keyword.get(opts, :extras)
    }
  end
end
