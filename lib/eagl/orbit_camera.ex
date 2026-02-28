defmodule EAGL.OrbitCamera do
  @moduledoc """
  Orbit camera for inspecting 3D scenes.

  Unlike the first-person `EAGL.Camera` (designed for LearnOpenGL tutorials),
  OrbitCamera provides a conventional turntable-style view:

  - **Left-drag**: orbit around the target point
  - **Scroll**: zoom in/out (moves closer/further from target)
  - **Middle-drag**: pan the target point

  The camera position is computed from spherical coordinates relative to the
  target, making it natural for inspecting models from all angles.

  ## Quick Start

  Use `fit_to_bounds/2` to automatically position the camera for a model:

      orbit = EAGL.OrbitCamera.fit_to_bounds({-1, -1, -1}, {1, 1, 1})

  Or from a GLTF document:

      orbit = EAGL.OrbitCamera.fit_to_gltf(gltf)

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
            fov: @default_fov,
            near: 0.1,
            far: 1000.0,
            sensitivity: @default_sensitivity,
            zoom_speed: @default_zoom_speed,
            pan_speed: @default_pan_speed,
            last_mouse: nil,
            mouse_down: false

  @type t :: %__MODULE__{
          target: EAGL.Math.vec3(),
          distance: float(),
          azimuth: float(),
          elevation: float(),
          fov: float(),
          near: float(),
          far: float(),
          sensitivity: float(),
          zoom_speed: float(),
          pan_speed: float(),
          last_mouse: {number(), number()} | nil,
          mouse_down: boolean()
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
    %__MODULE__{
      target: Keyword.get(opts, :target, [{0.0, 0.0, 0.0}]),
      distance: Keyword.get(opts, :distance, 5.0),
      azimuth: Keyword.get(opts, :azimuth, @default_azimuth),
      elevation: Keyword.get(opts, :elevation, @default_elevation),
      fov: Keyword.get(opts, :fov, @default_fov),
      near: Keyword.get(opts, :near, 0.1),
      far: Keyword.get(opts, :far, 1000.0),
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
  @spec fit_to_bounds({number(), number(), number()} | list(), {number(), number(), number()} | list()) :: t()
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
  Create an orbit camera automatically sized to fit a GLTF document.

  Scans all POSITION accessors to find the overall bounding box.

      orbit = OrbitCamera.fit_to_gltf(gltf)
  """
  @spec fit_to_gltf(GLTF.t()) :: t()
  def fit_to_gltf(%GLTF{} = gltf) do
    case compute_gltf_bounds(gltf) do
      {:ok, min_point, max_point} -> fit_to_bounds(min_point, max_point)
      :no_bounds -> new()
    end
  end

  @doc """
  Get the camera's eye position in world space.
  """
  @spec get_position(t()) :: EAGL.Math.vec3()
  def get_position(%__MODULE__{} = cam) do
    [{tx, ty, tz}] = cam.target

    x = tx + cam.distance * :math.cos(cam.elevation) * :math.sin(cam.azimuth)
    y = ty + cam.distance * :math.sin(cam.elevation)
    z = tz + cam.distance * :math.cos(cam.elevation) * :math.cos(cam.azimuth)

    vec3(x, y, z)
  end

  @doc """
  Get the view matrix for this camera.
  """
  @spec get_view_matrix(t()) :: EAGL.Math.mat4()
  def get_view_matrix(%__MODULE__{} = cam) do
    eye = get_position(cam)
    mat4_look_at(eye, cam.target, vec3(0.0, 1.0, 0.0))
  end

  @doc """
  Get the projection matrix for this camera.
  """
  @spec get_projection_matrix(t(), float()) :: EAGL.Math.mat4()
  def get_projection_matrix(%__MODULE__{} = cam, aspect_ratio) do
    aspect = if aspect_ratio > 0, do: aspect_ratio, else: 1.0
    mat4_perspective(radians(cam.fov), aspect, cam.near, cam.far)
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
    new_distance = max(cam.near * 2, cam.distance * factor)
    %{cam | distance: new_distance}
  end

  @doc """
  Process a mouse drag event to handle orbit/zoom interaction.

  Returns updated camera with new mouse tracking state.
  """
  @spec handle_mouse_motion(t(), number(), number()) :: t()
  def handle_mouse_motion(%__MODULE__{mouse_down: true, last_mouse: {lx, ly}} = cam, x, y) do
    cam
    |> orbit(x - lx, y - ly)
    |> Map.put(:last_mouse, {x, y})
  end

  def handle_mouse_motion(%__MODULE__{} = cam, x, y) do
    %{cam | last_mouse: {x, y}}
  end

  @doc """
  Process a mouse button press.
  """
  @spec handle_mouse_down(t()) :: t()
  def handle_mouse_down(%__MODULE__{} = cam) do
    %{cam | mouse_down: true}
  end

  @doc """
  Process a mouse button release.
  """
  @spec handle_mouse_up(t()) :: t()
  def handle_mouse_up(%__MODULE__{} = cam) do
    %{cam | mouse_down: false, last_mouse: nil}
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
      @impl true
      def handle_event({:tick, _dt}, state), do: {:ok, state}

      def handle_event({:mouse_motion, x, y}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_mouse_motion(orbit, x, y)}}
      end

      def handle_event({:mouse_down, _, _}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_mouse_down(orbit)}}
      end

      def handle_event({:mouse_up, _, _}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_mouse_up(orbit)}}
      end

      def handle_event({:mouse_wheel, _, _, _, wd}, %{orbit: orbit} = state) do
        {:ok, %{state | orbit: EAGL.OrbitCamera.handle_scroll(orbit, wd)}}
      end

      def handle_event(_event, state), do: {:ok, state}

      defoverridable handle_event: 2
    end
  end

  # --- Private helpers ---

  defp to_tuple3([{x, y, z}]), do: {x, y, z}
  defp to_tuple3({x, y, z}), do: {x, y, z}
  defp to_tuple3([x, y, z]), do: {x, y, z}

  defp compute_gltf_bounds(%GLTF{meshes: nil}), do: :no_bounds
  defp compute_gltf_bounds(%GLTF{meshes: []}), do: :no_bounds

  defp compute_gltf_bounds(%GLTF{meshes: meshes, accessors: accessors}) do
    position_accessor_indices =
      meshes
      |> Enum.flat_map(fn mesh ->
        Enum.map(mesh.primitives, fn prim -> prim.attributes["POSITION"] end)
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    bounds =
      position_accessor_indices
      |> Enum.reduce(nil, fn idx, acc ->
        accessor = Enum.at(accessors || [], idx)

        if accessor && accessor.min && accessor.max do
          [min_x, min_y, min_z] = accessor.min
          [max_x, max_y, max_z] = accessor.max

          case acc do
            nil ->
              {{min_x, min_y, min_z}, {max_x, max_y, max_z}}

            {{ax, ay, az}, {bx, by, bz}} ->
              {{min(ax, min_x), min(ay, min_y), min(az, min_z)},
               {max(bx, max_x), max(by, max_y), max(bz, max_z)}}
          end
        else
          acc
        end
      end)

    case bounds do
      nil -> :no_bounds
      {min_point, max_point} -> {:ok, min_point, max_point}
    end
  end
end
