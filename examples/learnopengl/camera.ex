defmodule EAGL.Examples.LearnOpenGL.Camera do
  @moduledoc """
  First-person camera for LearnOpenGL tutorial examples.

  This module is part of the LearnOpenGL examples, not the main EAGL library.
  For general 3D model viewing, use `EAGL.OrbitCamera` instead.

  Provides a camera implementation equivalent to the LearnOpenGL C++ camera class,
  offering first-person style controls with mouse look, keyboard movement, and
  scroll zoom. Used by LearnOpenGL examples 7.4-7.6 and the lighting chapter.

  ## Original C++ Source

  Based on: <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/includes/learnopengl/camera.h>

  ## Framework Adaptation Notes

  **Mouse Sensitivity**: EAGL's windowing reports pixel-level mouse movements,
  requiring a smaller sensitivity (0.2) than GLFW's 0.1 for natural feel.

  ## Usage (in LearnOpenGL examples)

      alias EAGL.Examples.LearnOpenGL.Camera, as: Camera

      camera = Camera.new(position: vec3(0.0, 0.0, 5.0))
      camera = Camera.process_keyboard_input(camera, delta_time)
      camera = Camera.process_mouse_movement(camera, x_offset, y_offset)
      camera = Camera.process_mouse_scroll(camera, y_offset)
      view = Camera.get_view_matrix(camera)
  """

  import EAGL.Math

  @type vec3 :: EAGL.Math.vec3()
  @type mat4 :: EAGL.Math.mat4()

  @default_yaw -90.0
  @default_pitch 0.0
  @default_movement_speed 2.5
  @default_mouse_sensitivity 0.2
  @default_zoom 45.0

  @type movement_direction :: :forward | :backward | :left | :right

  @type t :: %__MODULE__{
          position: vec3(),
          front: vec3(),
          up: vec3(),
          right: vec3(),
          world_up: vec3(),
          yaw: float(),
          pitch: float(),
          movement_speed: float(),
          mouse_sensitivity: float(),
          zoom: float()
        }

  defstruct position: [{0.0, 0.0, 0.0}],
            front: [{0.0, 0.0, -1.0}],
            up: [{0.0, 1.0, 0.0}],
            right: [{1.0, 0.0, 0.0}],
            world_up: [{0.0, 1.0, 0.0}],
            yaw: @default_yaw,
            pitch: @default_pitch,
            movement_speed: @default_movement_speed,
            mouse_sensitivity: @default_mouse_sensitivity,
            zoom: @default_zoom

  @doc """
  Create a new camera with default or custom parameters.

  ## Options

  - `:position` - Camera position (default: {0.0, 0.0, 0.0})
  - `:world_up` - World up vector (default: {0.0, 1.0, 0.0})
  - `:yaw` - Initial yaw angle in degrees (default: -90.0)
  - `:pitch` - Initial pitch angle in degrees (default: 0.0)
  - `:movement_speed` - Movement speed in units/second (default: 2.5)
  - `:mouse_sensitivity` - Mouse sensitivity multiplier (default: 0.2)
  - `:zoom` - Field of view in degrees (default: 45.0)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    camera = %__MODULE__{
      position: Keyword.get(opts, :position, [{0.0, 0.0, 0.0}]),
      world_up: Keyword.get(opts, :world_up, [{0.0, 1.0, 0.0}]),
      yaw: Keyword.get(opts, :yaw, @default_yaw),
      pitch: Keyword.get(opts, :pitch, @default_pitch),
      movement_speed: Keyword.get(opts, :movement_speed, @default_movement_speed),
      mouse_sensitivity: Keyword.get(opts, :mouse_sensitivity, @default_mouse_sensitivity),
      zoom: Keyword.get(opts, :zoom, @default_zoom)
    }

    update_camera_vectors(camera)
  end

  @doc """
  Get the view matrix for this camera.
  """
  @spec get_view_matrix(t()) :: mat4()
  def get_view_matrix(camera) do
    target = vec_add(camera.position, camera.front)
    mat4_look_at(camera.position, target, camera.up)
  end

  @doc """
  Process keyboard input for camera movement.

  - `direction` - `:forward`, `:backward`, `:left`, or `:right`
  - `delta_time` - Time since last frame in seconds
  """
  def process_keyboard(camera, direction, delta_time) do
    velocity = camera.movement_speed * delta_time

    new_position =
      case direction do
        :forward ->
          vec_add(camera.position, vec_scale(camera.front, velocity))

        :backward ->
          vec_sub(camera.position, vec_scale(camera.front, velocity))

        :left ->
          vec_sub(camera.position, vec_scale(camera.right, velocity))

        :right ->
          vec_add(camera.position, vec_scale(camera.right, velocity))
      end

    %{camera | position: new_position}
  end

  @doc """
  Process mouse movement for camera look around.
  """
  def process_mouse_movement(camera, x_offset, y_offset, constrain_pitch \\ true) do
    x_offset = x_offset * camera.mouse_sensitivity
    y_offset = y_offset * camera.mouse_sensitivity

    new_yaw = camera.yaw + x_offset
    new_pitch = camera.pitch + y_offset

    new_pitch =
      if constrain_pitch do
        cond do
          new_pitch > 89.0 -> 89.0
          new_pitch < -89.0 -> -89.0
          true -> new_pitch
        end
      else
        new_pitch
      end

    %{camera | yaw: new_yaw, pitch: new_pitch}
    |> update_camera_vectors()
  end

  @doc """
  Process mouse scroll wheel for zoom control.
  """
  def process_mouse_scroll(camera, y_offset) do
    new_zoom = camera.zoom - y_offset

    new_zoom =
      cond do
        new_zoom < 1.0 -> 1.0
        new_zoom > 45.0 -> 45.0
        true -> new_zoom
      end

    %{camera | zoom: new_zoom}
  end

  @doc """
  Process all WASD keyboard input using direct key state checking.
  """
  def process_keyboard_input(camera, delta_time) do
    velocity = camera.movement_speed * delta_time

    camera.position
    |> vec_add(
      if :wx_misc.getKeyState(?w),
        do: vec_scale(camera.front, velocity),
        else: vec3_zero()
    )
    |> vec_add(
      if :wx_misc.getKeyState(?s),
        do: vec_scale(camera.front, -velocity),
        else: vec3_zero()
    )
    |> vec_add(
      if :wx_misc.getKeyState(?a),
        do: vec_scale(camera.right, -velocity),
        else: vec3_zero()
    )
    |> vec_add(
      if :wx_misc.getKeyState(?d),
        do: vec_scale(camera.right, velocity),
        else: vec3_zero()
    )
    |> then(&%{camera | position: &1})
  end

  @doc """
  Process FPS keyboard input with Y-locked ground movement.
  """
  def process_fps_keyboard_input(camera, delta_time, ground_level) do
    velocity = camera.movement_speed * delta_time

    front = camera.front
    right = camera.right

    [{front_x, _front_y, front_z}] = front
    [{right_x, _right_y, right_z}] = right

    horizontal_front = normalize(vec3(front_x, 0.0, front_z))
    horizontal_right = normalize(vec3(right_x, 0.0, right_z))

    new_position =
      camera.position
      |> vec_add(
        if :wx_misc.getKeyState(119),
          do: vec_scale(horizontal_front, velocity),
          else: vec3_zero()
      )
      |> vec_add(
        if :wx_misc.getKeyState(115),
          do: vec_scale(horizontal_front, -velocity),
          else: vec3_zero()
      )
      |> vec_add(
        if :wx_misc.getKeyState(97),
          do: vec_scale(horizontal_right, -velocity),
          else: vec3_zero()
      )
      |> vec_add(
        if :wx_misc.getKeyState(100),
          do: vec_scale(horizontal_right, velocity),
          else: vec3_zero()
      )

    [{new_x, _new_y, new_z}] = new_position
    constrained_position = vec3(new_x, ground_level, new_z)

    %{camera | position: constrained_position}
  end

  defp update_camera_vectors(camera) do
    yaw_rad = radians(camera.yaw)
    pitch_rad = radians(camera.pitch)

    front_x = :math.cos(yaw_rad) * :math.cos(pitch_rad)
    front_y = :math.sin(pitch_rad)
    front_z = :math.sin(yaw_rad) * :math.cos(pitch_rad)

    new_front = normalize(vec3(front_x, front_y, front_z))
    new_right = normalize(cross(new_front, camera.world_up))
    new_up = normalize(cross(new_right, new_front))

    %{camera | front: new_front, right: new_right, up: new_up}
  end
end
