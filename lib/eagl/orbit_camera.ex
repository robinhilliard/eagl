defmodule EAGL.OrbitCamera do
  @moduledoc """
  Orbit camera for inspecting 3D scenes.

  Unlike the first-person LearnOpenGL Camera (in `examples/learnopengl/camera.ex`),
  OrbitCamera provides a conventional turntable-style view:

  - **Left-drag**: orbit around the target point
  - **Scroll**: zoom in/out (moves closer/further from target)
  - **Middle-drag**: pan the target point

  The camera position is computed from spherical coordinates relative to the
  target, making it natural for inspecting models from all angles.

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
    spherical_to_vec3(cam.distance, cam.azimuth, cam.elevation, cam.target)
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
  """
  @spec orbit(t(), float(), float()) :: t()
  def orbit(%__MODULE__{} = cam, dx, dy) do
    new_azimuth = cam.azimuth - dx * cam.sensitivity
    new_elevation = cam.elevation + dy * cam.sensitivity

    max_elev = :math.pi() / 2.0 - 0.01
    new_elevation = max(-max_elev, min(max_elev, new_elevation))

    %{cam | azimuth: new_azimuth, elevation: new_elevation}
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
    [{tx, ty, tz}] = cam.target

    right_x = :math.cos(cam.azimuth)
    right_z = -:math.sin(cam.azimuth)

    up_x = -:math.sin(cam.elevation) * :math.sin(cam.azimuth)
    up_y = :math.cos(cam.elevation)
    up_z = -:math.sin(cam.elevation) * :math.cos(cam.azimuth)

    scale = cam.pan_speed * cam.distance

    new_tx = tx - dx * right_x * scale + dy * up_x * scale
    new_ty = ty + dy * up_y * scale
    new_tz = tz - dx * right_z * scale + dy * up_z * scale

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
end
