defmodule EAGL.Camera do
  @moduledoc """
  Camera system for 3D navigation and control.

  This module provides a comprehensive camera implementation equivalent to the
  LearnOpenGL camera class, offering first-person style camera controls with
  mouse look, keyboard movement, and scroll zoom functionality.

  ## Original C++ Source

  This camera implementation is based on the original LearnOpenGL C++ camera class:
  <https://github.com/JoeyDeVries/LearnOpenGL/tree/master/includes/learnopengl/camera.h>

  The design and functionality closely follow the C++ camera class tutorial from
  LearnOpenGL Chapter 7 - Camera, providing equivalent behaviour and API in Elixir.

  ## Framework Adaptation Notes

  **Mouse Sensitivity Adaptation**: The original LearnOpenGL tutorial uses a mouse
  sensitivity of 0.1f, which works well with GLFW's small mouse delta values.
  However, EAGL's windowing system reports pixel-level mouse movements, requiring
  a much smaller sensitivity (0.005) to achieve natural first-person camera feel.

  This adaptation addresses the "world rotation" feeling that students might
  experience when following camera tutorials - the camera should feel like natural
  first-person movement, not like rotating the entire world coordinate system.

  ## Features

  - **Euler Angle Camera**: Uses yaw and pitch for orientation
  - **WASD Movement**: Standard FPS-style keyboard controls
  - **Mouse Look**: Mouse movement for camera rotation with natural sensitivity
  - **Scroll Zoom**: Field of view adjustment via scroll wheel
  - **Pitch Constraints**: Prevents camera flipping at extreme angles
  - **Delta Time Support**: Frame-rate independent movement

  ## Usage

      # Create a camera at the origin looking down negative Z-axis
      camera = EAGL.Camera.new()

      # Create a camera at specific position
      camera = EAGL.Camera.new(position: vec3(0.0, 0.0, 5.0))

      # Process keyboard input (typically in handle_event/2)
      camera = EAGL.Camera.process_keyboard(camera, :forward, delta_time)

      # Process mouse movement (typically in handle_event/2)
      camera = EAGL.Camera.process_mouse_movement(camera, x_offset, y_offset)

      # Process scroll wheel (typically in handle_event/2)
      camera = EAGL.Camera.process_mouse_scroll(camera, y_offset)

      # Get view matrix for rendering
      view_matrix = EAGL.Camera.get_view_matrix(camera)

  ## Movement Directions

  - `:forward` - Move in the direction the camera is facing (-Z by default)
  - `:backward` - Move opposite to camera direction (+Z by default)
  - `:left` - Strafe left (perpendicular to front vector)
  - `:right` - Strafe right (perpendicular to front vector)

  ## Euler Angles

  - **Yaw**: Rotation around Y-axis (left/right look)
  - **Pitch**: Rotation around X-axis (up/down look)
  - **Roll**: Not used (always 0 for FPS-style camera)

  Default yaw of -90° makes the camera look down negative Z-axis initially.

  ## Educational Context

  This camera implementation serves as the foundation for LearnOpenGL camera
  examples 7.4-7.6, demonstrating the progression from manual camera implementation
  to well-designed camera abstractions. The mouse sensitivity adaptation ensures
  that students experience natural first-person camera controls throughout the
  tutorial series.
  """

  import EAGL.Math

  # Import types from EAGL.Math for function specs (following shader.ex pattern)
  @type vec3 :: EAGL.Math.vec3()
  @type mat4 :: EAGL.Math.mat4()

  # Default camera constants (matching LearnOpenGL camera.h with platform adaptations)
  @default_yaw -90.0
  @default_pitch 0.0
  @default_movement_speed 2.5
  # This seems to work well in our case
  @default_mouse_sensitivity 0.05
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
  - `:mouse_sensitivity` - Mouse sensitivity multiplier (default: 0.005, adapted from LearnOpenGL's 0.1 for natural feel)
  - `:zoom` - Field of view in degrees (default: 45.0)

  ## Examples

      # Default camera at origin
      camera = EAGL.Camera.new()

      # Camera at specific position
      camera = EAGL.Camera.new(position: vec3(5.0, 2.0, 5.0))

      # Custom camera configuration
      camera = EAGL.Camera.new(
        position: vec3(0.0, 5.0, 10.0),
        yaw: 180.0,
        pitch: -30.0,
        movement_speed: 5.0,
        mouse_sensitivity: 0.01
      )
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

  The view matrix transforms world coordinates to camera/view space,
  effectively moving the world to simulate camera movement.

  ## Examples

      camera = EAGL.Camera.new(position: vec3(0.0, 0.0, 3.0))
      view = EAGL.Camera.get_view_matrix(camera)

      # Use in shader
      set_uniform(program, "view", view)
  """
  @spec get_view_matrix(t()) :: mat4()
  def get_view_matrix(camera) do
    target = vec_add(camera.position, camera.front)
    mat4_look_at(camera.position, target, camera.up)
  end

  @doc """
  Process keyboard input for camera movement.

  Moves the camera based on the specified direction and delta time.
  Movement is frame-rate independent when delta time is provided.

  ## Parameters

  - `camera` - The camera struct
  - `direction` - Movement direction (`:forward`, `:backward`, `:left`, `:right`)
  - `delta_time` - Time since last frame in seconds

  ## Examples

      # Forward movement (W key)
      camera = EAGL.Camera.process_keyboard(camera, :forward, delta_time)

      # Backward movement (S key)
      camera = EAGL.Camera.process_keyboard(camera, :backward, delta_time)

      # Strafe left (A key)
      camera = EAGL.Camera.process_keyboard(camera, :left, delta_time)

      # Strafe right (D key)
      camera = EAGL.Camera.process_keyboard(camera, :right, delta_time)
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

  Updates camera orientation based on mouse movement offsets.
  Constrains pitch to prevent camera flipping.

  ## Parameters

  - `camera` - The camera struct
  - `x_offset` - Horizontal mouse movement offset
  - `y_offset` - Vertical mouse movement offset
  - `constrain_pitch` - Whether to constrain pitch (default: true)

  ## Examples

      # Typical mouse movement processing
      camera = EAGL.Camera.process_mouse_movement(camera, x_offset, y_offset)

      # Allow full pitch rotation (can cause gimbal lock)
      camera = EAGL.Camera.process_mouse_movement(camera, x_offset, y_offset, false)
  """
  def process_mouse_movement(camera, x_offset, y_offset, constrain_pitch \\ true) do
    # Apply mouse sensitivity
    x_offset = x_offset * camera.mouse_sensitivity
    y_offset = y_offset * camera.mouse_sensitivity

    # Update yaw and pitch
    new_yaw = camera.yaw + x_offset
    new_pitch = camera.pitch + y_offset

    # Constrain pitch to prevent camera flipping
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

    # Update camera with new angles and recalculate vectors
    %{camera | yaw: new_yaw, pitch: new_pitch}
    |> update_camera_vectors()
  end

  @doc """
  Process mouse scroll wheel input for zoom control.

  Adjusts field of view based on scroll wheel movement.
  Constrains zoom to reasonable range (1.0 to 45.0 degrees).

  ## Parameters

  - `camera` - The camera struct
  - `y_offset` - Scroll wheel offset (positive = zoom in, negative = zoom out)

  ## Examples

      # Zoom in (positive offset, smaller FOV)
      camera = EAGL.Camera.process_mouse_scroll(camera, 1.0)

      # Zoom out (negative offset, larger FOV)
      camera = EAGL.Camera.process_mouse_scroll(camera, -1.0)
  """
  def process_mouse_scroll(camera, y_offset) do
    new_zoom = camera.zoom - y_offset

    # Constrain zoom to valid range
    new_zoom =
      cond do
        new_zoom < 1.0 -> 1.0
        new_zoom > 45.0 -> 45.0
        true -> new_zoom
      end

    %{camera | zoom: new_zoom}
  end

  @doc """
  Process all keyboard input for camera movement using direct key state checking.

  This function checks the current state of WASD keys and applies movement
  accordingly. It uses `:wx_misc.getKeyState()` for reliable input detection,
  providing the same approach as examples 7.2 and 7.3.

  ## Parameters

  - `camera` - The camera struct
  - `delta_time` - Time since last frame in seconds

  ## Key Mappings

  - `W` (119) - Move forward
  - `A` (97) - Strafe left
  - `S` (115) - Move backward
  - `D` (100) - Strafe right

  ## Examples

      # Process all keyboard input at once
      camera = EAGL.Camera.process_keyboard_input(camera, delta_time)

  This approach is simpler and more reliable than individual key event handling,
  matching the proven pattern from examples 7.2 and 7.3.
  """
  def process_keyboard_input(camera, delta_time) do
    velocity = camera.movement_speed * delta_time

    camera.position
    # W - forward
    |> vec_add(
      if :wx_misc.getKeyState(?w),
        do: vec_scale(camera.front, velocity),
        else: vec3_zero()
    )
    # S - backward
    |> vec_add(
      if :wx_misc.getKeyState(?s),
        do: vec_scale(camera.front, -velocity),
        else: vec3_zero()
    )
    # A - strafe left
    |> vec_add(
      if :wx_misc.getKeyState(?a),
        do: vec_scale(camera.right, -velocity),
        else: vec3_zero()
    )
    # D - strafe right
    |> vec_add(
      if :wx_misc.getKeyState(?d),
        do: vec_scale(camera.right, velocity),
        else: vec3_zero()
    )
    |> then(&%{camera | position: &1})
  end

  @doc """
  Process all keyboard input for FPS camera movement using direct key state checking.

  This function provides the same simplified approach as `process_keyboard_input/2` but
  constrains movement to the XZ plane for realistic first-person shooter camera behavior.
  Movement vectors are projected horizontally to prevent "flying" when looking up/down.

  ## Parameters

  - `camera` - The camera struct
  - `delta_time` - Time since last frame in seconds
  - `ground_level` - Y-coordinate to constrain camera position to

  ## Key Mappings

  - `W` (119) - Move forward (horizontally)
  - `A` (97) - Strafe left (horizontally)
  - `S` (115) - Move backward (horizontally)
  - `D` (100) - Strafe right (horizontally)

  ## Examples

      # Process FPS keyboard input at ground level 1.5
      camera = EAGL.Camera.process_fps_keyboard_input(camera, delta_time, 1.5)

  This approach maintains the Y-coordinate at the specified ground level regardless
  of camera pitch, providing natural ground-based navigation.
  """
  def process_fps_keyboard_input(camera, delta_time, ground_level) do
    velocity = camera.movement_speed * delta_time

    # Get camera vectors and create horizontal-only movement vectors (Y = 0)
    front = camera.front
    right = camera.right

    [{front_x, _front_y, front_z}] = front
    [{right_x, _right_y, right_z}] = right

    horizontal_front = normalize(vec3(front_x, 0.0, front_z))
    horizontal_right = normalize(vec3(right_x, 0.0, right_z))

    new_position =
      camera.position
      # W - forward
      |> vec_add(
        if :wx_misc.getKeyState(119),
          do: vec_scale(horizontal_front, velocity),
          else: vec3_zero()
      )
      # S - backward
      |> vec_add(
        if :wx_misc.getKeyState(115),
          do: vec_scale(horizontal_front, -velocity),
          else: vec3_zero()
      )
      # A - strafe left
      |> vec_add(
        if :wx_misc.getKeyState(97),
          do: vec_scale(horizontal_right, -velocity),
          else: vec3_zero()
      )
      # D - strafe right
      |> vec_add(
        if :wx_misc.getKeyState(100),
          do: vec_scale(horizontal_right, velocity),
          else: vec3_zero()
      )

    # Force Y coordinate to ground level (FPS constraint)
    [{new_x, _new_y, new_z}] = new_position
    constrained_position = vec3(new_x, ground_level, new_z)

    %{camera | position: constrained_position}
  end

  # Private function to recalculate camera vectors from Euler angles
  defp update_camera_vectors(camera) do
    # Convert degrees to radians
    yaw_rad = radians(camera.yaw)
    pitch_rad = radians(camera.pitch)

    # Calculate new front vector from Euler angles
    front_x = :math.cos(yaw_rad) * :math.cos(pitch_rad)
    front_y = :math.sin(pitch_rad)
    front_z = :math.sin(yaw_rad) * :math.cos(pitch_rad)

    new_front = normalize(vec3(front_x, front_y, front_z))

    # Recalculate right and up vectors
    new_right = normalize(cross(new_front, camera.world_up))
    new_up = normalize(cross(new_right, new_front))

    %{camera | front: new_front, right: new_right, up: new_up}
  end
end
