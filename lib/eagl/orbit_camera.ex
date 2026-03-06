defmodule EAGL.OrbitCamera do
  @moduledoc """
  Orbit camera for inspecting 3D scenes.

  - **Left-drag**: orbit around the target point
  - **Scroll**: zoom in/out (moves closer/further from target)
  - **Middle-drag**: pan the target point

  Orientation is stored as a quaternion for numerical stability.
  Rotation axes are derived from the look_at construction so they
  match what the renderer displays on screen. Azimuth and elevation
  are kept in sync for backward compatibility.

  ## Quick Start

  Use `fit_to_bounds/2` to automatically position the camera for a model:

      orbit = EAGL.OrbitCamera.fit_to_bounds({-1, -1, -1}, {1, 1, 1})

  Or from an EAGL scene (e.g. loaded from glTF):

      orbit = EAGL.OrbitCamera.fit_to_scene(scene)

  ## Automatic Event Handling

  Add `use EAGL.OrbitCamera` to your module to inject default `handle_event`
  clauses. Your state map must include an `:orbit` key:

      defmodule MyViewer do
        use EAGL.Window
        use EAGL.Const
        use EAGL.OrbitCamera

        def setup do
          orbit = EAGL.OrbitCamera.fit_to_bounds(min, max)
          {:ok, %{orbit: orbit}}
        end

        def render(w, h, %{orbit: orbit} = state) do
          view = EAGL.OrbitCamera.get_view_matrix(orbit)
          proj = EAGL.OrbitCamera.get_projection_matrix(orbit, w / h)
          # ...
        end
      end
  """

  import EAGL.Math
  alias EAGL.Camera

  @default_azimuth :math.pi() / 6.0
  @default_elevation :math.pi() / 9.0
  @default_fov 45.0
  @default_sensitivity 0.005
  @default_zoom_speed 0.1
  @default_pan_speed 0.002

  defstruct target: [{0.0, 0.0, 0.0}],
            distance: 5.0,
            azimuth: @default_azimuth,
            elevation: @default_elevation,
            orientation: nil,
            camera: nil,
            sensitivity: @default_sensitivity,
            zoom_speed: @default_zoom_speed,
            pan_speed: @default_pan_speed,
            last_mouse: nil,
            mouse_down: false,
            middle_down: false

  @type t :: %__MODULE__{
          target: EAGL.Math.vec3(),
          distance: float(),
          azimuth: float(),
          elevation: float(),
          orientation: EAGL.Math.quat(),
          camera: Camera.t(),
          sensitivity: float(),
          zoom_speed: float(),
          pan_speed: float(),
          last_mouse: {number(), number()} | nil,
          mouse_down: boolean(),
          middle_down: boolean()
        }

  @doc """
  Create a new orbit camera with default or custom parameters.

  ## Options

  - `:target` - point to orbit around (default: origin)
  - `:distance` - distance from target (default: 5.0)
  - `:azimuth` - horizontal angle in radians (default: ~30 degrees)
  - `:elevation` - vertical angle in radians (default: ~20 degrees)
  - `:fov` - field of view in degrees (default: 45.0)
  - `:near` - near clip plane (default: 0.1)
  - `:far` - far clip plane (default: 1000.0)
  - `:sensitivity` - orbit drag sensitivity (default: 0.005)
  - `:zoom_speed` - scroll zoom speed (default: 0.1)
  - `:pan_speed` - middle-drag pan speed (default: 0.002)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    target = Keyword.get(opts, :target, [{0.0, 0.0, 0.0}])
    distance = Keyword.get(opts, :distance, 5.0)
    azimuth = Keyword.get(opts, :azimuth, @default_azimuth)
    elevation = Keyword.get(opts, :elevation, @default_elevation)
    near = Keyword.get(opts, :near, 0.1)
    far = Keyword.get(opts, :far, 1000.0)

    orientation = azimuth_elevation_to_quat(azimuth, elevation)

    camera =
      Camera.new(
        type: :perspective,
        yfov: radians(Keyword.get(opts, :fov, @default_fov)),
        znear: near,
        zfar: far,
        position: spherical_to_vec3(distance, azimuth, elevation, target),
        target: target
      )

    %__MODULE__{
      target: target,
      distance: distance,
      azimuth: azimuth,
      elevation: elevation,
      orientation: orientation,
      camera: camera,
      sensitivity: Keyword.get(opts, :sensitivity, @default_sensitivity),
      zoom_speed: Keyword.get(opts, :zoom_speed, @default_zoom_speed),
      pan_speed: Keyword.get(opts, :pan_speed, @default_pan_speed)
    }
  end

  @doc """
  Create an orbit camera automatically sized to fit a bounding box.

  Takes min and max corners as `{x, y, z}` tuples or EAGL vec3 format.
  Positions the camera so the entire model is visible with a pleasant default angle.

      orbit = OrbitCamera.fit_to_bounds({-1, -1, -1}, {1, 1, 1})
  """
  @spec fit_to_bounds(
          {number(), number(), number()} | list(),
          {number(), number(), number()} | list()
        ) :: t()
  def fit_to_bounds(min_point, max_point) do
    {min_x, min_y, min_z} = to_tuple3(min_point)
    {max_x, max_y, max_z} = to_tuple3(max_point)

    cx = (min_x + max_x) / 2.0
    cy = (min_y + max_y) / 2.0
    cz = (min_z + max_z) / 2.0

    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z
    diagonal = :math.sqrt(dx * dx + dy * dy + dz * dz)

    distance = diagonal * 1.5
    near = max(distance * 0.01, 0.01)
    far = distance * 10.0

    new(
      target: vec3(cx, cy, cz),
      distance: distance,
      near: near,
      far: far
    )
  end

  @doc """
  Create an orbit camera automatically sized to fit a scene.

  Delegates to `EAGL.Scene.bounds/1` for bounding box extraction. Falls back
  to default camera when bounds cannot be computed. Bounds reflect current
  animated state when the scene has been updated.

      orbit = OrbitCamera.fit_to_scene(scene)
  """
  @spec fit_to_scene(EAGL.Scene.t()) :: t()
  def fit_to_scene(%EAGL.Scene{} = scene) do
    case EAGL.Scene.bounds(scene) do
      {:ok, min_point, max_point} -> fit_to_bounds(min_point, max_point)
      :no_bounds -> new()
    end
  end

  @doc """
  Get the camera's eye position in world space.
  """
  @spec get_position(t()) :: EAGL.Math.vec3()
  def get_position(%__MODULE__{} = cam) do
    offset = quat_rotate_vec3(cam.orientation, vec3(0.0, 0.0, cam.distance))
    vec_add(cam.target, offset)
  end

  @doc """
  Get the view matrix for this camera.
  """
  @spec get_view_matrix(t()) :: EAGL.Math.mat4()
  def get_view_matrix(%__MODULE__{} = cam) do
    pos = get_position(cam)
    cam_with_pos = Camera.set_position(cam.camera, pos) |> Camera.set_target(cam.target)
    Camera.get_view_matrix(cam_with_pos)
  end

  @doc """
  Get the projection matrix for this camera.
  """
  @spec get_projection_matrix(t(), float()) :: EAGL.Math.mat4()
  def get_projection_matrix(%__MODULE__{} = cam, aspect_ratio) do
    Camera.get_projection_matrix(cam.camera, aspect_ratio)
  end

  @doc """
  Process a mouse drag to orbit the camera.

  Rotation axes are derived from the look_at construction (matching
  what the renderer displays), so horizontal drag always orbits
  around screen-up and vertical drag around screen-right.
  The quaternion provides a stable fallback near the poles where
  the look_at cross product degenerates.
  """
  @spec orbit(t(), float(), float()) :: t()
  def orbit(%__MODULE__{} = cam, dx, dy) do
    world_up = vec3(0.0, 1.0, 0.0)
    max_elev = :math.pi() / 2.0 - 0.01

    offset = quat_rotate_vec3(cam.orientation, vec3(0.0, 0.0, cam.distance))
    forward = normalize(vec_scale(offset, -1.0))

    right_cross = cross(forward, world_up)

    {right, view_up} =
      if vec_length(right_cross) < 0.001 do
        r = quat_rotate_vec3(cam.orientation, vec3(1.0, 0.0, 0.0))
        {r, normalize(cross(r, forward))}
      else
        r = normalize(right_cross)
        {r, normalize(cross(r, forward))}
      end

    h_q = quat_from_axis_angle(view_up, -dx * cam.sensitivity)
    v_q = quat_from_axis_angle(right, -dy * cam.sensitivity)

    new_orientation = quat_normalize(quat_mul(h_q, quat_mul(v_q, cam.orientation)))

    new_offset = quat_rotate_vec3(new_orientation, vec3(0.0, 0.0, cam.distance))
    {_r, _az, new_elev} = vec3_to_spherical(new_offset)

    new_orientation =
      if abs(new_elev) > max_elev do
        quat_normalize(quat_mul(h_q, cam.orientation))
      else
        new_orientation
      end

    sync_spherical(cam, new_orientation)
  end

  @doc """
  Process a scroll event to zoom the camera.
  """
  @spec zoom(t(), float()) :: t()
  def zoom(%__MODULE__{} = cam, scroll_delta) do
    factor = 1.0 - scroll_delta * cam.zoom_speed
    min_dist = cam.camera.znear * 2
    new_distance = max(min_dist, cam.distance * factor)
    %{cam | distance: new_distance}
  end

  @doc """
  Pan the camera target perpendicular to the view direction.

  Shifts the target point right/up relative to the camera's orientation,
  scaled by distance so pan speed feels consistent at any zoom level.
  """
  @spec pan(t(), float(), float()) :: t()
  def pan(%__MODULE__{} = cam, dx, dy) do
    [{rx, ry, rz}] = quat_rotate_vec3(cam.orientation, vec3(1.0, 0.0, 0.0))
    [{ux, uy, uz}] = quat_rotate_vec3(cam.orientation, vec3(0.0, 1.0, 0.0))
    [{tx, ty, tz}] = cam.target

    scale = cam.pan_speed * cam.distance

    new_tx = tx - dx * rx * scale + dy * ux * scale
    new_ty = ty - dx * ry * scale + dy * uy * scale
    new_tz = tz - dx * rz * scale + dy * uz * scale

    %{cam | target: vec3(new_tx, new_ty, new_tz)}
  end

  @doc """
  Process a mouse drag event. Orbits on left-drag, pans on middle-drag.
  """
  @spec handle_mouse_motion(t(), number(), number()) :: t()
  def handle_mouse_motion(%__MODULE__{mouse_down: true, last_mouse: {lx, ly}} = cam, x, y) do
    cam
    |> orbit(x - lx, y - ly)
    |> Map.put(:last_mouse, {x, y})
  end

  def handle_mouse_motion(%__MODULE__{middle_down: true, last_mouse: {lx, ly}} = cam, x, y) do
    cam
    |> pan(x - lx, y - ly)
    |> Map.put(:last_mouse, {x, y})
  end

  def handle_mouse_motion(%__MODULE__{} = cam, x, y) do
    %{cam | last_mouse: {x, y}}
  end

  @doc """
  Process a left mouse button press.
  """
  @spec handle_mouse_down(t()) :: t()
  def handle_mouse_down(%__MODULE__{} = cam) do
    %{cam | mouse_down: true}
  end

  @doc """
  Process a left mouse button release.
  """
  @spec handle_mouse_up(t()) :: t()
  def handle_mouse_up(%__MODULE__{} = cam) do
    %{cam | mouse_down: false, last_mouse: nil}
  end

  @doc """
  Process a middle mouse button press.
  """
  @spec handle_middle_down(t()) :: t()
  def handle_middle_down(%__MODULE__{} = cam) do
    %{cam | middle_down: true}
  end

  @doc """
  Process a middle mouse button release.
  """
  @spec handle_middle_up(t()) :: t()
  def handle_middle_up(%__MODULE__{} = cam) do
    %{cam | middle_down: false, last_mouse: nil}
  end

  @doc """
  Process a scroll wheel event.
  """
  @spec handle_scroll(t(), float()) :: t()
  def handle_scroll(%__MODULE__{} = cam, wheel_delta) do
    zoom(cam, wheel_delta)
  end

  # --- use macro ---

  @doc false
  defmacro __using__(_opts) do
    quote do
      @doc """
      Per-frame callback injected by `use EAGL.OrbitCamera`.

      Override this to add per-frame logic (e.g. animation updates) without
      losing the orbit camera's mouse/scroll event handlers. This callback
      is specific to the OrbitCamera macro - it is not part of the
      EAGL.Window behaviour.

      The default implementation is a no-op that returns `{:ok, state}`.

          def on_tick(_time_delta, %{animator: animator, scene: scene} = state) do
            :ok = Animator.update(animator, time_delta)
            {:ok, %{state | scene: Animator.apply_to_scene(animator, scene)}}
          end
      """
      @spec on_tick(float(), any()) :: {:ok, any()}
      def on_tick(_time_delta, state), do: {:ok, state}

      @impl true
      def handle_event({:tick, dt}, state) do
        on_tick(dt, state)
      end

      def handle_event({:mouse_motion, x, y}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_mouse_motion(orbit, x, y)}}
      end

      def handle_event({:mouse_down, _, _}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_mouse_down(orbit)}}
      end

      def handle_event({:mouse_up, _, _}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_mouse_up(orbit)}}
      end

      def handle_event({:middle_down, _, _}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_middle_down(orbit)}}
      end

      def handle_event({:middle_up, _, _}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_middle_up(orbit)}}
      end

      def handle_event({:mouse_wheel, _, _, wheel_rotation, _wd}, %{orbit: orbit} = state) do
        scroll_delta = wheel_rotation / 120.0
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_scroll(orbit, scroll_delta)}}
      end

      def handle_event(_event, state), do: {:ok, state}

      defoverridable handle_event: 2, on_tick: 2
    end
  end

  # --- Private helpers ---

  defp to_tuple3([{x, y, z}]), do: {x, y, z}
  defp to_tuple3({x, y, z}), do: {x, y, z}
  defp to_tuple3([x, y, z]), do: {x, y, z}

  defp azimuth_elevation_to_quat(azimuth, elevation) do
    q_elev = quat_from_axis_angle(vec3(1.0, 0.0, 0.0), -elevation)
    q_azim = quat_from_axis_angle(vec3(0.0, 1.0, 0.0), azimuth)
    quat_normalize(quat_mul(q_azim, q_elev))
  end

  defp sync_spherical(cam, orientation) do
    offset = quat_rotate_vec3(orientation, vec3(0.0, 0.0, cam.distance))
    {_r, azimuth, elevation} = vec3_to_spherical(offset)
    %{cam | orientation: orientation, azimuth: azimuth, elevation: elevation}
  end
end
