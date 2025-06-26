defmodule EAGL.PBR do
  @moduledoc """
  Physically Based Rendering (PBR) support for EAGL.

  This module provides helper functions for working with PBR materials and shaders
  using the industry-standard metallic-roughness workflow as defined in the glTF specification.

  ## PBR Material Model

  The metallic-roughness material model uses three core parameters:
  - **Base Color**: The albedo color (diffuse for non-metals, F0 for metals)
  - **Metallic Factor**: Blend between dielectric (0.0) and conductor (1.0) behavior
  - **Roughness Factor**: Surface roughness from smooth (0.0) to rough (1.0)

  Additional parameters include:
  - **Emissive Factor**: HDR emissive color for glowing materials
  - **Normal Maps**: Surface detail through normal perturbation
  - **Occlusion Maps**: Ambient occlusion for enhanced realism

  ## Usage

      # Create PBR shader program
      {:ok, program} = EAGL.PBR.create_pbr_program()

      # Set material properties
      EAGL.PBR.set_material(program, %{
        base_color_factor: [0.8, 0.2, 0.1, 1.0],  # Reddish metal
        metallic_factor: 1.0,                      # Fully metallic
        roughness_factor: 0.2                      # Somewhat shiny
      })

      # Set lighting
      EAGL.PBR.set_lighting(program, %{
        light_position: vec3(10.0, 10.0, 5.0),
        light_color: vec3(1.0, 1.0, 1.0),
        camera_pos: camera_position
      })

  ## Integration with glTF

  This module works seamlessly with glTF materials:

      material_uniforms = GLTF.EAGL.material_to_uniforms(gltf_material)
      EAGL.Shader.set_uniforms(pbr_program, material_uniforms)
  """

  import EAGL.{Shader, Math}
  use EAGL.Const

  @doc """
  Create a PBR shader program using the standard EAGL PBR shaders.

  Returns a shader program configured for metallic-roughness PBR rendering.
  """
  @spec create_pbr_program() :: {:ok, integer()} | {:error, String.t()}
  def create_pbr_program do
    with {:ok, vertex_shader} <- create_shader(@gl_vertex_shader, "pbr_vertex_shader.glsl"),
         {:ok, fragment_shader} <- create_shader(@gl_fragment_shader, "pbr_fragment_shader.glsl"),
         {:ok, program} <- create_attach_link([vertex_shader, fragment_shader]) do
      {:ok, program}
    end
  end

  @doc """
  Set PBR material properties on a shader program.

  ## Parameters

  - `program`: OpenGL shader program ID
  - `material`: Map containing material properties

  ## Material Properties

  - `:base_color_factor` - Base color as `[r, g, b, a]` (default: `[1.0, 1.0, 1.0, 1.0]`)
  - `:metallic_factor` - Metalness from 0.0 to 1.0 (default: `1.0`)
  - `:roughness_factor` - Roughness from 0.0 to 1.0 (default: `1.0`)
  - `:emissive_factor` - Emissive color as `[r, g, b]` (default: `[0.0, 0.0, 0.0]`)

  ## Examples

      # Shiny red metal
      EAGL.PBR.set_material(program, %{
        base_color_factor: [0.8, 0.1, 0.1, 1.0],
        metallic_factor: 1.0,
        roughness_factor: 0.1
      })

      # Rough plastic
      EAGL.PBR.set_material(program, %{
        base_color_factor: [0.2, 0.7, 0.3, 1.0],
        metallic_factor: 0.0,
        roughness_factor: 0.8
      })
  """
  @spec set_material(integer(), map()) :: :ok
  def set_material(program, material) do
    uniforms = [
      baseColorFactor: list_to_vec4(Map.get(material, :base_color_factor, [1.0, 1.0, 1.0, 1.0])),
      metallicFactor: Map.get(material, :metallic_factor, 1.0),
      roughnessFactor: Map.get(material, :roughness_factor, 1.0),
      emissiveFactor: list_to_vec3(Map.get(material, :emissive_factor, [0.0, 0.0, 0.0]))
    ]

    set_uniforms(program, uniforms)
  end

  @doc """
  Set lighting parameters for PBR rendering.

  ## Parameters

  - `program`: OpenGL shader program ID
  - `lighting`: Map containing lighting properties

  ## Lighting Properties

  - `:light_position` - World space position as `vec3(x, y, z)`
  - `:light_color` - Light color as `vec3(r, g, b)`
  - `:camera_pos` - Camera position as `vec3(x, y, z)`

  ## Example

      lighting = %{
        light_position: vec3(5.0, 10.0, 5.0),
        light_color: vec3(1.0, 0.9, 0.8),      # Warm white
        camera_pos: Camera.get_position(camera)
      }
      EAGL.PBR.set_lighting(program, lighting)
  """
  @spec set_lighting(integer(), map()) :: :ok
  def set_lighting(program, lighting) do
    uniforms = [
      lightPosition: Map.get(lighting, :light_position, vec3(0.0, 10.0, 0.0)),
      lightColor: Map.get(lighting, :light_color, vec3(1.0, 1.0, 1.0)),
      cameraPos: Map.get(lighting, :camera_pos, vec3(0.0, 0.0, 5.0))
    ]

    set_uniforms(program, uniforms)
  end

  @doc """
  Set texture presence flags for conditional texture sampling.

  This tells the shader which textures are actually bound and should be sampled.

  ## Parameters

  - `program`: OpenGL shader program ID
  - `flags`: Map of texture presence flags

  ## Texture Flags

  - `:has_base_color_texture` - Boolean
  - `:has_metallic_roughness_texture` - Boolean
  - `:has_normal_texture` - Boolean
  - `:has_occlusion_texture` - Boolean
  - `:has_emissive_texture` - Boolean

  ## Example

      EAGL.PBR.set_texture_flags(program, %{
        has_base_color_texture: true,
        has_metallic_roughness_texture: true,
        has_normal_texture: false,
        has_occlusion_texture: false,
        has_emissive_texture: false
      })
  """
  @spec set_texture_flags(integer(), map()) :: :ok
  def set_texture_flags(program, flags) do
    uniforms = [
      hasBaseColorTexture: if(Map.get(flags, :has_base_color_texture, false), do: 1.0, else: 0.0),
      hasMetallicRoughnessTexture:
        if(Map.get(flags, :has_metallic_roughness_texture, false), do: 1.0, else: 0.0),
      hasNormalTexture: if(Map.get(flags, :has_normal_texture, false), do: 1.0, else: 0.0),
      hasOcclusionTexture: if(Map.get(flags, :has_occlusion_texture, false), do: 1.0, else: 0.0),
      hasEmissiveTexture: if(Map.get(flags, :has_emissive_texture, false), do: 1.0, else: 0.0)
    ]

    set_uniforms(program, uniforms)
  end

  @doc """
  Create a simple PBR material with common presets.

  ## Material Presets

  - `:gold` - Shiny gold metal
  - `:silver` - Shiny silver metal
  - `:iron` - Slightly rough iron
  - `:plastic_red` - Red plastic (dielectric)
  - `:plastic_blue` - Blue plastic (dielectric)
  - `:rubber_black` - Rough black rubber

  ## Example

      gold_material = EAGL.PBR.create_material(:gold)
      EAGL.PBR.set_material(program, gold_material)
  """
  @spec create_material(atom()) :: map()
  def create_material(:gold) do
    %{
      # Gold color from glTF spec
      base_color_factor: [1.0, 0.766, 0.336, 1.0],
      metallic_factor: 1.0,
      roughness_factor: 0.1
    }
  end

  def create_material(:silver) do
    %{
      base_color_factor: [0.972, 0.960, 0.915, 1.0],
      metallic_factor: 1.0,
      roughness_factor: 0.05
    }
  end

  def create_material(:iron) do
    %{
      base_color_factor: [0.560, 0.570, 0.580, 1.0],
      metallic_factor: 1.0,
      roughness_factor: 0.3
    }
  end

  def create_material(:plastic_red) do
    %{
      base_color_factor: [0.8, 0.1, 0.1, 1.0],
      metallic_factor: 0.0,
      roughness_factor: 0.4
    }
  end

  def create_material(:plastic_blue) do
    %{
      base_color_factor: [0.1, 0.3, 0.8, 1.0],
      metallic_factor: 0.0,
      roughness_factor: 0.4
    }
  end

  def create_material(:rubber_black) do
    %{
      base_color_factor: [0.05, 0.05, 0.05, 1.0],
      metallic_factor: 0.0,
      roughness_factor: 0.9
    }
  end

  # Helper functions for data conversion

  defp list_to_vec3([x, y, z]), do: vec3(x, y, z)
  defp list_to_vec3(_), do: vec3(0.0, 0.0, 0.0)

  defp list_to_vec4([x, y, z, w]), do: vec4(x, y, z, w)
  defp list_to_vec4([x, y, z]), do: vec4(x, y, z, 1.0)
  defp list_to_vec4(_), do: vec4(1.0, 1.0, 1.0, 1.0)
end
