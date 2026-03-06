defmodule EAGL.OrthoCamera do
  @moduledoc """
  Fixed-axis orthographic camera for editor views.

  Provides pan and zoom but no rotation, suitable for Top/Front/Right
  views in a quad-viewport editor layout.

  - **Left-drag** or **Middle-drag**: pan
  - **Scroll**: zoom in/out

  ## Quick Start

      # Preset axis views
      top   = EAGL.OrthoCamera.new(axis: :top)
      front = EAGL.OrthoCamera.new(axis: :front)
      right = EAGL.OrthoCamera.new(axis: :right)

      # Fit to a scene
      top = EAGL.OrthoCamera.fit_to_scene(scene, :top)

  ## Automatic Event Handling

  Add `use EAGL.OrthoCamera` to inject default `handle_event` clauses.
  Your state map must include an `:ortho` key:

      defmodule MyOrthoView do
        use EAGL.Window
        use EAGL.Const
        use EAGL.OrthoCamera

        def setup do
          ortho = EAGL.OrthoCamera.new(axis: :top)
          {:ok, %{ortho: ortho}}
        end

        def render(w, h, %{ortho: ortho} = state) do
          view = EAGL.OrthoCamera.get_view_matrix(ortho)
          proj = EAGL.OrthoCamera.get_projection_matrix(ortho, w / h)
          # ...
        end
      end
  """

  import EAGL.Math
  alias EAGL.Camera

  @default_half_width 10.0
  @default_zoom_speed 0.1
  @default_pan_speed 0.002

  defstruct axis: :top,
            camera: nil,
            half_width: @default_half_width,
            zoom_speed: @default_zoom_speed,
            pan_speed: @default_pan_speed,
            last_mouse: nil,
            mouse_down: false,
            middle_down: false

  @type t :: %__MODULE__{
          axis: :top | :front | :right | :custom,
          camera: Camera.t(),
          half_width: float(),
          zoom_speed: float(),
          pan_speed: float(),
          last_mouse: {number(), number()} | nil,
          mouse_down: boolean(),
          middle_down: boolean()
        }

  @axis_presets %{
    top: %{
      position: [{0.0, 100.0, 0.0}],
      target: [{0.0, 0.0, 0.0}],
      up: [{0.0, 0.0, -1.0}]
    },
    front: %{
      position: [{0.0, 0.0, 100.0}],
      target: [{0.0, 0.0, 0.0}],
      up: [{0.0, 1.0, 0.0}]
    },
    right: %{
      position: [{100.0, 0.0, 0.0}],
      target: [{0.0, 0.0, 0.0}],
      up: [{0.0, 1.0, 0.0}]
    }
  }

  @doc """
  Create a new orthographic camera.

  ## Options

  - `:axis` - preset axis (`:top`, `:front`, `:right`), default `:top`
  - `:position` - eye position (overrides axis preset)
  - `:target` - look-at point (overrides axis preset)
  - `:up` - up vector (overrides axis preset)
  - `:half_width` - half the vertical extent in world units (default: 10.0)
  - `:znear` - near clip plane (default: 0.01)
  - `:zfar` - far clip plane (default: 1000.0)
  - `:zoom_speed` - scroll zoom speed (default: 0.1)
  - `:pan_speed` - drag pan speed (default: 0.002)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    axis = Keyword.get(opts, :axis, :top)
    preset = Map.get(@axis_presets, axis, @axis_presets.top)

    position = Keyword.get(opts, :position, preset.position)
    target = Keyword.get(opts, :target, preset.target)
    up = Keyword.get(opts, :up, preset.up)
    half_width = Keyword.get(opts, :half_width, @default_half_width)

    camera =
      Camera.new(
        type: :orthographic,
        position: position,
        target: target,
        up: up,
        xmag: half_width,
        ymag: half_width,
        znear: Keyword.get(opts, :znear, 0.01),
        zfar: Keyword.get(opts, :zfar, 1000.0)
      )

    %__MODULE__{
      axis: axis,
      camera: camera,
      half_width: half_width,
      zoom_speed: Keyword.get(opts, :zoom_speed, @default_zoom_speed),
      pan_speed: Keyword.get(opts, :pan_speed, @default_pan_speed)
    }
  end

  @doc """
  Create an orthographic camera sized to fit a bounding box.

  The `axis` determines the viewing direction (`:top`, `:front`, `:right`).
  """
  @spec fit_to_bounds(
          {number(), number(), number()} | list(),
          {number(), number(), number()} | list(),
          atom()
        ) :: t()
  def fit_to_bounds(min_point, max_point, axis \\ :top) do
    {min_x, min_y, min_z} = to_tuple3(min_point)
    {max_x, max_y, max_z} = to_tuple3(max_point)

    cx = (min_x + max_x) / 2.0
    cy = (min_y + max_y) / 2.0
    cz = (min_z + max_z) / 2.0

    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z
    diagonal = :math.sqrt(dx * dx + dy * dy + dz * dz)

    {half_width, offset_dist} = extent_for_axis(axis, dx, dy, dz, diagonal)

    preset = Map.get(@axis_presets, axis, @axis_presets.top)
    dir = normalize(vec_sub(preset.target, preset.position))
    [{dirx, diry, dirz}] = dir

    position = vec3(cx - dirx * offset_dist, cy - diry * offset_dist, cz - dirz * offset_dist)
    target = vec3(cx, cy, cz)

    near = max(0.01, offset_dist * 0.01)
    far = offset_dist * 2.0 + diagonal

    new(
      axis: axis,
      position: position,
      target: target,
      up: preset.up,
      half_width: half_width * 1.1,
      znear: near,
      zfar: far
    )
  end

  @doc """
  Create an orthographic camera sized to fit a scene.
  """
  @spec fit_to_scene(EAGL.Scene.t(), atom()) :: t()
  def fit_to_scene(%EAGL.Scene{} = scene, axis \\ :top) do
    case EAGL.Scene.bounds(scene) do
      {:ok, min_point, max_point} -> fit_to_bounds(min_point, max_point, axis)
      :no_bounds -> new(axis: axis)
    end
  end

  @doc """
  Get the camera's eye position in world space.
  """
  @spec get_position(t()) :: EAGL.Math.vec3()
  def get_position(%__MODULE__{camera: cam}), do: cam.position

  @doc """
  Get the view matrix.
  """
  @spec get_view_matrix(t()) :: EAGL.Math.mat4()
  def get_view_matrix(%__MODULE__{camera: cam}) do
    Camera.get_view_matrix(cam)
  end

  @doc """
  Get the projection matrix. Aspect ratio adjusts the horizontal extent.
  """
  @spec get_projection_matrix(t(), float()) :: EAGL.Math.mat4()
  def get_projection_matrix(%__MODULE__{half_width: hw, camera: cam}, aspect_ratio) do
    aspect = if aspect_ratio > 0, do: aspect_ratio, else: 1.0
    cam = %{cam | xmag: hw * aspect, ymag: hw}
    Camera.get_projection_matrix(cam, aspect)
  end

  @doc """
  Pan the camera by a screen-space delta.
  """
  @spec pan(t(), float(), float()) :: t()
  def pan(%__MODULE__{camera: cam} = ortho, dx, dy) do
    [{px, py, pz}] = cam.position
    [{tx, ty, tz}] = cam.target

    forward = normalize(vec_sub(cam.target, cam.position))
    right = normalize(cross(forward, cam.up))
    [{rx, ry, rz}] = right
    [{ux, uy, uz}] = cam.up

    scale = ortho.pan_speed * ortho.half_width

    new_px = px - dx * rx * scale + dy * ux * scale
    new_py = py - dx * ry * scale + dy * uy * scale
    new_pz = pz - dx * rz * scale + dy * uz * scale

    new_tx = tx - dx * rx * scale + dy * ux * scale
    new_ty = ty - dx * ry * scale + dy * uy * scale
    new_tz = tz - dx * rz * scale + dy * uz * scale

    new_cam = %{
      cam
      | position: vec3(new_px, new_py, new_pz),
        target: vec3(new_tx, new_ty, new_tz)
    }

    %{ortho | camera: new_cam}
  end

  @doc """
  Zoom by scaling the orthographic extent.
  """
  @spec zoom(t(), float()) :: t()
  def zoom(%__MODULE__{} = ortho, scroll_delta) do
    factor = 1.0 - scroll_delta * ortho.zoom_speed
    new_hw = max(0.01, ortho.half_width * factor)
    %{ortho | half_width: new_hw}
  end

  @doc """
  Handle mouse motion. Both left-drag and middle-drag pan.
  """
  @spec handle_mouse_motion(t(), number(), number()) :: t()
  def handle_mouse_motion(%__MODULE__{mouse_down: true, last_mouse: {lx, ly}} = cam, x, y) do
    cam |> pan(x - lx, y - ly) |> Map.put(:last_mouse, {x, y})
  end

  def handle_mouse_motion(%__MODULE__{middle_down: true, last_mouse: {lx, ly}} = cam, x, y) do
    cam |> pan(x - lx, y - ly) |> Map.put(:last_mouse, {x, y})
  end

  def handle_mouse_motion(%__MODULE__{} = cam, x, y) do
    %{cam | last_mouse: {x, y}}
  end

  @spec handle_mouse_down(t()) :: t()
  def handle_mouse_down(%__MODULE__{} = cam), do: %{cam | mouse_down: true}

  @spec handle_mouse_up(t()) :: t()
  def handle_mouse_up(%__MODULE__{} = cam), do: %{cam | mouse_down: false, last_mouse: nil}

  @spec handle_middle_down(t()) :: t()
  def handle_middle_down(%__MODULE__{} = cam), do: %{cam | middle_down: true}

  @spec handle_middle_up(t()) :: t()
  def handle_middle_up(%__MODULE__{} = cam), do: %{cam | middle_down: false, last_mouse: nil}

  @spec handle_scroll(t(), float()) :: t()
  def handle_scroll(%__MODULE__{} = cam, wheel_delta), do: zoom(cam, wheel_delta)

  # --- use macro ---

  @doc false
  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_event({:mouse_motion, x, y}, %{ortho: ortho} = state) do
        {:ok, %{state | ortho: EAGL.OrthoCamera.handle_mouse_motion(ortho, x, y)}}
      end

      def handle_event({:mouse_down, _, _}, %{ortho: ortho} = state) do
        {:ok, %{state | ortho: EAGL.OrthoCamera.handle_mouse_down(ortho)}}
      end

      def handle_event({:mouse_up, _, _}, %{ortho: ortho} = state) do
        {:ok, %{state | ortho: EAGL.OrthoCamera.handle_mouse_up(ortho)}}
      end

      def handle_event({:middle_down, _, _}, %{ortho: ortho} = state) do
        {:ok, %{state | ortho: EAGL.OrthoCamera.handle_middle_down(ortho)}}
      end

      def handle_event({:middle_up, _, _}, %{ortho: ortho} = state) do
        {:ok, %{state | ortho: EAGL.OrthoCamera.handle_middle_up(ortho)}}
      end

      def handle_event({:mouse_wheel, _, _, wheel_rotation, _wd}, %{ortho: ortho} = state) do
        scroll_delta = wheel_rotation / 120.0
        {:ok, %{state | ortho: EAGL.OrthoCamera.handle_scroll(ortho, scroll_delta)}}
      end

      def handle_event(_event, state), do: {:ok, state}

      defoverridable handle_event: 2
    end
  end

  # --- Private helpers ---

  defp to_tuple3([{x, y, z}]), do: {x, y, z}
  defp to_tuple3({x, y, z}), do: {x, y, z}
  defp to_tuple3([x, y, z]), do: {x, y, z}

  # Returns {half_width, offset_distance} for the given axis and scene extents
  defp extent_for_axis(:top, dx, _dy, dz, diagonal) do
    {max(dx, dz) / 2.0, diagonal}
  end

  defp extent_for_axis(:front, dx, dy, _dz, diagonal) do
    {max(dx, dy) / 2.0, diagonal}
  end

  defp extent_for_axis(:right, _dx, dy, dz, diagonal) do
    {max(dy, dz) / 2.0, diagonal}
  end

  defp extent_for_axis(_, dx, dy, dz, diagonal) do
    {max(dx, max(dy, dz)) / 2.0, diagonal}
  end
end
