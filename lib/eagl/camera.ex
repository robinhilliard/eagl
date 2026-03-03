defmodule EAGL.Camera do
  @moduledoc """
  Geometric camera for view and projection matrices.

  EAGL.Camera provides a glTF-style geometric camera: position, target, up vector,
  and projection parameters (perspective or orthographic). It produces view and
  projection matrices for rendering—no movement or input handling.

  Use `EAGL.OrbitCamera` for interactive orbit/zoom/pan controls built on this camera.

  ## Usage

      # Create a perspective camera
      camera = EAGL.Camera.new(
        position: vec3(0, 0, 5),
        target: vec3(0, 0, 0),
        type: :perspective,
        yfov: :math.pi() / 4,
        znear: 0.1,
        zfar: 100.0
      )

      view = EAGL.Camera.get_view_matrix(camera)
      proj = EAGL.Camera.get_projection_matrix(camera, 16.0 / 9.0)

  ## glTF Reference

  The camera model follows glTF 2.0: perspective (yfov, aspectRatio, znear, zfar)
  and orthographic (xmag, ymag, znear, zfar). glTF cameras are parsed and
  converted to EAGL.Camera via `GLTF.EAGL.gltf_camera_to_eagl/2`.
  """

  import EAGL.Math

  @default_up vec3(0.0, 1.0, 0.0)
  @infinite_zfar 1.0e6

  defstruct position: [{0.0, 0.0, 0.0}],
            target: [{0.0, 0.0, 0.0}],
            up: @default_up,
            type: :perspective,
            # Perspective
            yfov: :math.pi() / 4,
            aspect_ratio: nil,
            znear: 0.1,
            zfar: 1000.0,
            # Orthographic
            xmag: 1.0,
            ymag: 1.0

  @type t :: %__MODULE__{
          position: EAGL.Math.vec3(),
          target: EAGL.Math.vec3(),
          up: EAGL.Math.vec3(),
          type: :perspective | :orthographic,
          yfov: float(),
          aspect_ratio: float() | nil,
          znear: float(),
          zfar: float() | nil,
          xmag: float(),
          ymag: float()
        }

  @doc """
  Create a new camera from keyword options.

  ## Options

  - `:position` - eye position (vec3, default: origin)
  - `:target` - look-at point (vec3, default: origin)
  - `:up` - world up vector (vec3, default: {0, 1, 0})
  - `:type` - `:perspective` or `:orthographic` (default: :perspective)
  - `:yfov` - vertical field of view in radians (perspective, default: π/4)
  - `:aspect_ratio` - aspect ratio (nil = use at render time)
  - `:znear` - near clip plane (default: 0.1)
  - `:zfar` - far clip plane (nil = infinite, uses 1e6 for mat4_perspective)
  - `:xmag` - horizontal magnification (orthographic, default: 1.0)
  - `:ymag` - vertical magnification (orthographic, default: 1.0)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    zfar = Keyword.get(opts, :zfar, 1000.0)
    zfar = if zfar == nil, do: @infinite_zfar, else: zfar

    %__MODULE__{
      position: Keyword.get(opts, :position, vec3(0.0, 0.0, 0.0)),
      target: Keyword.get(opts, :target, vec3(0.0, 0.0, 0.0)),
      up: Keyword.get(opts, :up, @default_up),
      type: Keyword.get(opts, :type, :perspective),
      yfov: Keyword.get(opts, :yfov, :math.pi() / 4),
      aspect_ratio: Keyword.get(opts, :aspect_ratio),
      znear: Keyword.get(opts, :znear, 0.1),
      zfar: zfar,
      xmag: Keyword.get(opts, :xmag, 1.0),
      ymag: Keyword.get(opts, :ymag, 1.0)
    }
  end

  @doc """
  Get the view matrix for this camera.
  """
  @spec get_view_matrix(t()) :: EAGL.Math.mat4()
  def get_view_matrix(%__MODULE__{position: eye, target: center, up: up}) do
    mat4_look_at(eye, center, up)
  end

  @doc """
  Get the projection matrix for this camera.

  For perspective cameras, pass `aspect_ratio` (width/height). If the camera
  has `aspect_ratio` set, it overrides the parameter; otherwise the parameter
  is used.

  For orthographic cameras, uses xmag and ymag for the projection extent.
  """
  @spec get_projection_matrix(t(), float()) :: EAGL.Math.mat4()
  def get_projection_matrix(%__MODULE__{type: :perspective} = cam, aspect_ratio) do
    aspect = cam.aspect_ratio || aspect_ratio
    aspect = if aspect > 0, do: aspect, else: 1.0
    mat4_perspective(cam.yfov, aspect, cam.znear, cam.zfar)
  end

  def get_projection_matrix(%__MODULE__{type: :orthographic} = cam, _aspect_ratio) do
    left = -cam.xmag
    right = cam.xmag
    bottom = -cam.ymag
    top = cam.ymag
    mat4_ortho(left, right, bottom, top, cam.znear, cam.zfar)
  end

  @doc """
  Set the camera position.
  """
  @spec set_position(t(), EAGL.Math.vec3()) :: t()
  def set_position(%__MODULE__{} = cam, position), do: %{cam | position: position}

  @doc """
  Set the camera target (look-at point).
  """
  @spec set_target(t(), EAGL.Math.vec3()) :: t()
  def set_target(%__MODULE__{} = cam, target), do: %{cam | target: target}

  @doc """
  Unproject screen coordinates to a world-space ray.

  Converts (screen_x, screen_y) to a ray from the camera through that screen point.
  Screen coordinates are in pixels; origin is bottom-left (OpenGL convention).
  Viewport is `{x, y, width, height}` in pixels.

  Returns `{origin, direction}` as a ray (both vec3). Direction is normalized.
  """
  @spec unproject(
          float(),
          float(),
          EAGL.Math.mat4(),
          EAGL.Math.mat4(),
          {float(), float(), float(), float()}
        ) :: {EAGL.Math.vec3(), EAGL.Math.vec3()}
  def unproject(screen_x, screen_y, view_matrix, proj_matrix, {vp_x, vp_y, vp_w, vp_h}) do
    # NDC: x,y in [-1,1], screen origin bottom-left
    x_ndc = (screen_x - vp_x) / max(vp_w, 1) * 2.0 - 1.0
    y_ndc = (screen_y - vp_y) / max(vp_h, 1) * 2.0 - 1.0

    # Near and far clip plane points in NDC
    near_ndc = vec3(x_ndc, y_ndc, -1.0)
    far_ndc = vec3(x_ndc, y_ndc, 1.0)

    inv_vp = mat4_inverse(mat4_mul(proj_matrix, view_matrix))

    near_world = mat4_transform_point(inv_vp, near_ndc)
    far_world = mat4_transform_point(inv_vp, far_ndc)

    direction = normalize(vec_sub(far_world, near_world))
    {near_world, direction}
  end
end
