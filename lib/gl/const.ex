defmodule GL.Const do
  @moduledoc """
  Comprehensive OpenGL constants for 3D graphics programming.
  Use this module to inject OpenGL constants as module attributes.

  ## Usage

      defmodule MyModule do
        use GL.Const

        # Now you can use @gl_vertex_shader, @gl_triangles, @gl_texture_2d, etc.
      end

  ## Categories

  This module provides constants for:
  - Shader types and compilation
  - Buffer types and usage patterns
  - Drawing primitives and polygon modes
  - Data types and formats
  - Textures and sampling
  - Blending and transparency
  - Depth and stencil testing
  - Matrices and transformations
  - Vertex attributes and arrays
  - Framebuffers and attachments
  - And much more...
  """

  defmacro __using__(_opts) do
    quote do
      # ============================================================================
      # BASIC CONSTANTS
      # ============================================================================

      @gl_false 0
      @gl_true 1
      @gl_none 0

      # ============================================================================
      # SHADER TYPES
      # ============================================================================

      @gl_vertex_shader 35633  # GL_VERTEX_SHADER
      @gl_fragment_shader 35632  # GL_FRAGMENT_SHADER
      @gl_geometry_shader 36313  # GL_GEOMETRY_SHADER
      @gl_tess_control_shader 36488  # GL_TESS_CONTROL_SHADER
      @gl_tess_evaluation_shader 36487  # GL_TESS_EVALUATION_SHADER
      @gl_compute_shader 37305  # GL_COMPUTE_SHADER

      # ============================================================================
      # SHADER COMPILATION/LINKING
      # ============================================================================

      @gl_compile_status 35713  # GL_COMPILE_STATUS
      @gl_link_status 35714  # GL_LINK_STATUS
      @gl_validate_status 35715  # GL_VALIDATE_STATUS
      @gl_info_log_length 35716  # GL_INFO_LOG_LENGTH
      @gl_shader_source_length 35720  # GL_SHADER_SOURCE_LENGTH
      @gl_delete_status 35712  # GL_DELETE_STATUS

      # ============================================================================
      # PROGRAM ATTRIBUTES
      # ============================================================================

      @gl_active_program 33369  # GL_ACTIVE_PROGRAM
      @gl_current_program 35725  # GL_CURRENT_PROGRAM
      @gl_active_attributes 35721  # GL_ACTIVE_ATTRIBUTES
      @gl_active_uniforms 35718  # GL_ACTIVE_UNIFORMS
      @gl_attached_shaders 35717  # GL_ATTACHED_SHADERS
      @gl_active_uniform_blocks 35382  # GL_ACTIVE_UNIFORM_BLOCKS
      @gl_active_uniform_max_length 35719  # GL_ACTIVE_UNIFORM_MAX_LENGTH
      @gl_active_attribute_max_length 35722  # GL_ACTIVE_ATTRIBUTE_MAX_LENGTH

      # ============================================================================
      # BUFFER TYPES
      # ============================================================================

      @gl_array_buffer 34962  # GL_ARRAY_BUFFER
      @gl_element_array_buffer 34963  # GL_ELEMENT_ARRAY_BUFFER
      @gl_uniform_buffer 35345  # GL_UNIFORM_BUFFER
      @gl_texture_buffer 35882  # GL_TEXTURE_BUFFER
      @gl_transform_feedback_buffer 35982  # GL_TRANSFORM_FEEDBACK_BUFFER
      @gl_copy_read_buffer 36662  # GL_COPY_READ_BUFFER
      @gl_copy_write_buffer 36663  # GL_COPY_WRITE_BUFFER
      @gl_pixel_pack_buffer 35051  # GL_PIXEL_PACK_BUFFER
      @gl_pixel_unpack_buffer 35052  # GL_PIXEL_UNPACK_BUFFER
      @gl_query_buffer 37266  # GL_QUERY_BUFFER
      @gl_shader_storage_buffer 37074  # GL_SHADER_STORAGE_BUFFER
      @gl_atomic_counter_buffer 37568  # GL_ATOMIC_COUNTER_BUFFER
      @gl_draw_indirect_buffer 36671  # GL_DRAW_INDIRECT_BUFFER
      @gl_dispatch_indirect_buffer 37102  # GL_DISPATCH_INDIRECT_BUFFER

      # ============================================================================
      # BUFFER USAGE PATTERNS
      # ============================================================================

      @gl_static_draw 35044  # GL_STATIC_DRAW
      @gl_dynamic_draw 35048  # GL_DYNAMIC_DRAW
      @gl_stream_draw 35040  # GL_STREAM_DRAW
      @gl_static_read 35045  # GL_STATIC_READ
      @gl_dynamic_read 35049  # GL_DYNAMIC_READ
      @gl_stream_read 35041  # GL_STREAM_READ
      @gl_static_copy 35046  # GL_STATIC_COPY
      @gl_dynamic_copy 35050  # GL_DYNAMIC_COPY
      @gl_stream_copy 35042  # GL_STREAM_COPY

      # ============================================================================
      # BUFFER BINDINGS
      # ============================================================================

      @gl_array_buffer_binding 34964  # GL_ARRAY_BUFFER_BINDING
      @gl_element_array_buffer_binding 34965  # GL_ELEMENT_ARRAY_BUFFER_BINDING
      @gl_uniform_buffer_binding 35368  # GL_UNIFORM_BUFFER_BINDING
      @gl_vertex_array_binding 34229  # GL_VERTEX_ARRAY_BINDING

      # ============================================================================
      # DRAWING PRIMITIVES
      # ============================================================================

      @gl_points 0  # GL_POINTS
      @gl_lines 1  # GL_LINES
      @gl_line_loop 2  # GL_LINE_LOOP
      @gl_line_strip 3  # GL_LINE_STRIP
      @gl_triangles 4  # GL_TRIANGLES
      @gl_triangle_strip 5  # GL_TRIANGLE_STRIP
      @gl_triangle_fan 6  # GL_TRIANGLE_FAN
      @gl_quads 7  # GL_QUADS
      @gl_quad_strip 8  # GL_QUAD_STRIP
      @gl_polygon 9  # GL_POLYGON
      @gl_lines_adjacency 10  # GL_LINES_ADJACENCY
      @gl_line_strip_adjacency 11  # GL_LINE_STRIP_ADJACENCY
      @gl_triangles_adjacency 12  # GL_TRIANGLES_ADJACENCY
      @gl_triangle_strip_adjacency 13  # GL_TRIANGLE_STRIP_ADJACENCY
      @gl_patches 14  # GL_PATCHES

      # ============================================================================
      # POLYGON MODES
      # ============================================================================

      @gl_point 6912  # GL_POINT
      @gl_line 6913  # GL_LINE
      @gl_fill 6914  # GL_FILL

      # ============================================================================
      # FACE CULLING
      # ============================================================================

      @gl_front 1028  # GL_FRONT
      @gl_back 1029  # GL_BACK
      @gl_front_and_back 1032  # GL_FRONT_AND_BACK
      @gl_cw 2304  # GL_CW (clockwise)
      @gl_ccw 2305  # GL_CCW (counter-clockwise)

      # ============================================================================
      # DATA TYPES
      # ============================================================================

      @gl_byte 5120  # GL_BYTE
      @gl_unsigned_byte 5121  # GL_UNSIGNED_BYTE
      @gl_short 5122  # GL_SHORT
      @gl_unsigned_short 5123  # GL_UNSIGNED_SHORT
      @gl_int 5124  # GL_INT
      @gl_unsigned_int 5125  # GL_UNSIGNED_INT
      @gl_float 5126  # GL_FLOAT
      @gl_double 5130  # GL_DOUBLE
      @gl_half_float 5131  # GL_HALF_FLOAT
      @gl_fixed 5132  # GL_FIXED
      @gl_int_2_10_10_10_rev 33640  # GL_INT_2_10_10_10_REV
      @gl_unsigned_int_2_10_10_10_rev 33641  # GL_UNSIGNED_INT_2_10_10_10_REV
      @gl_unsigned_int_10f_11f_11f_rev 35899  # GL_UNSIGNED_INT_10F_11F_11F_REV

      # ============================================================================
      # VERTEX ATTRIBUTES
      # ============================================================================

      @gl_vertex_attrib_array_enabled 34338  # GL_VERTEX_ATTRIB_ARRAY_ENABLED
      @gl_vertex_attrib_array_size 34339  # GL_VERTEX_ATTRIB_ARRAY_SIZE
      @gl_vertex_attrib_array_stride 34340  # GL_VERTEX_ATTRIB_ARRAY_STRIDE
      @gl_vertex_attrib_array_type 34341  # GL_VERTEX_ATTRIB_ARRAY_TYPE
      @gl_vertex_attrib_array_normalized 34922  # GL_VERTEX_ATTRIB_ARRAY_NORMALIZED
      @gl_vertex_attrib_array_pointer 34373  # GL_VERTEX_ATTRIB_ARRAY_POINTER
      @gl_vertex_attrib_array_buffer_binding 34975  # GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING
      @gl_vertex_attrib_binding 33492  # GL_VERTEX_ATTRIB_BINDING
      @gl_vertex_attrib_array_integer 35069  # GL_VERTEX_ATTRIB_ARRAY_INTEGER
      @gl_vertex_attrib_array_divisor 35070  # GL_VERTEX_ATTRIB_ARRAY_DIVISOR

      # ============================================================================
      # TEXTURES
      # ============================================================================

      @gl_texture_1d 3552  # GL_TEXTURE_1D
      @gl_texture_2d 3553  # GL_TEXTURE_2D
      @gl_texture_3d 32879  # GL_TEXTURE_3D
      @gl_texture_cube_map 34067  # GL_TEXTURE_CUBE_MAP
      @gl_texture_1d_array 35864  # GL_TEXTURE_1D_ARRAY
      @gl_texture_2d_array 35866  # GL_TEXTURE_2D_ARRAY
      @gl_texture_cube_map_array 36873  # GL_TEXTURE_CUBE_MAP_ARRAY
      @gl_texture_rectangle 34037  # GL_TEXTURE_RECTANGLE
      @gl_texture_2d_multisample 37120  # GL_TEXTURE_2D_MULTISAMPLE
      @gl_texture_2d_multisample_array 37122  # GL_TEXTURE_2D_MULTISAMPLE_ARRAY

      # Cube map faces
      @gl_texture_cube_map_positive_x 34069  # GL_TEXTURE_CUBE_MAP_POSITIVE_X
      @gl_texture_cube_map_negative_x 34070  # GL_TEXTURE_CUBE_MAP_NEGATIVE_X
      @gl_texture_cube_map_positive_y 34071  # GL_TEXTURE_CUBE_MAP_POSITIVE_Y
      @gl_texture_cube_map_negative_y 34072  # GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
      @gl_texture_cube_map_positive_z 34073  # GL_TEXTURE_CUBE_MAP_POSITIVE_Z
      @gl_texture_cube_map_negative_z 34074  # GL_TEXTURE_CUBE_MAP_NEGATIVE_Z

      # ============================================================================
      # TEXTURE PARAMETERS
      # ============================================================================

      @gl_texture_min_filter 10241  # GL_TEXTURE_MIN_FILTER
      @gl_texture_mag_filter 10240  # GL_TEXTURE_MAG_FILTER
      @gl_texture_wrap_s 10242  # GL_TEXTURE_WRAP_S
      @gl_texture_wrap_t 10243  # GL_TEXTURE_WRAP_T
      @gl_texture_wrap_r 32882  # GL_TEXTURE_WRAP_R
      @gl_texture_border_color 4100  # GL_TEXTURE_BORDER_COLOR
      @gl_texture_compare_mode 34892  # GL_TEXTURE_COMPARE_MODE
      @gl_texture_compare_func 34893  # GL_TEXTURE_COMPARE_FUNC
      @gl_texture_base_level 33084  # GL_TEXTURE_BASE_LEVEL
      @gl_texture_max_level 33085  # GL_TEXTURE_MAX_LEVEL
      @gl_texture_lod_bias 34049  # GL_TEXTURE_LOD_BIAS

      # ============================================================================
      # TEXTURE FILTERING
      # ============================================================================

      @gl_nearest 9728  # GL_NEAREST
      @gl_linear 9729  # GL_LINEAR
      @gl_nearest_mipmap_nearest 9984  # GL_NEAREST_MIPMAP_NEAREST
      @gl_linear_mipmap_nearest 9985  # GL_LINEAR_MIPMAP_NEAREST
      @gl_nearest_mipmap_linear 9986  # GL_NEAREST_MIPMAP_LINEAR
      @gl_linear_mipmap_linear 9987  # GL_LINEAR_MIPMAP_LINEAR

      # ============================================================================
      # TEXTURE WRAPPING
      # ============================================================================

      @gl_repeat 10497  # GL_REPEAT
      @gl_clamp_to_edge 33071  # GL_CLAMP_TO_EDGE
      @gl_clamp_to_border 33069  # GL_CLAMP_TO_BORDER
      @gl_mirrored_repeat 33648  # GL_MIRRORED_REPEAT
      @gl_mirror_clamp_to_edge 34627  # GL_MIRROR_CLAMP_TO_EDGE

      # ============================================================================
      # PIXEL FORMATS
      # ============================================================================

      @gl_red 6403  # GL_RED
      @gl_green 6404  # GL_GREEN
      @gl_blue 6405  # GL_BLUE
      @gl_alpha 6406  # GL_ALPHA
      @gl_rgb 6407  # GL_RGB
      @gl_rgba 6408  # GL_RGBA
      @gl_luminance 6409  # GL_LUMINANCE
      @gl_luminance_alpha 6410  # GL_LUMINANCE_ALPHA
      @gl_rg 33319  # GL_RG
      @gl_bgr 32992  # GL_BGR
      @gl_bgra 32993  # GL_BGRA
      @gl_red_integer 36244  # GL_RED_INTEGER
      @gl_green_integer 36245  # GL_GREEN_INTEGER
      @gl_blue_integer 36246  # GL_BLUE_INTEGER
      @gl_alpha_integer 36247  # GL_ALPHA_INTEGER
      @gl_rgb_integer 36248  # GL_RGB_INTEGER
      @gl_rgba_integer 36249  # GL_RGBA_INTEGER
      @gl_bgr_integer 36250  # GL_BGR_INTEGER
      @gl_bgra_integer 36251  # GL_BGRA_INTEGER
      @gl_depth_component 6402  # GL_DEPTH_COMPONENT
      @gl_depth_stencil 34041  # GL_DEPTH_STENCIL

      # ============================================================================
      # INTERNAL FORMATS
      # ============================================================================

      @gl_r8 33321  # GL_R8
      @gl_r16 33322  # GL_R16
      @gl_rg8 33323  # GL_RG8
      @gl_rg16 33324  # GL_RG16
      @gl_r16f 33325  # GL_R16F
      @gl_r32f 33326  # GL_R32F
      @gl_rg16f 33327  # GL_RG16F
      @gl_rg32f 33328  # GL_RG32F
      @gl_rgba32f 34836  # GL_RGBA32F
      @gl_rgb32f 34837  # GL_RGB32F
      @gl_rgba16f 34842  # GL_RGBA16F
      @gl_rgb16f 34843  # GL_RGB16F
      @gl_rgba8 32856  # GL_RGBA8
      @gl_rgb8 32849  # GL_RGB8
      @gl_srgb8 35905  # GL_SRGB8
      @gl_srgb8_alpha8 35907  # GL_SRGB8_ALPHA8
      @gl_depth_component16 33189  # GL_DEPTH_COMPONENT16
      @gl_depth_component24 33190  # GL_DEPTH_COMPONENT24
      @gl_depth_component32 33191  # GL_DEPTH_COMPONENT32
      @gl_depth_component32f 36012  # GL_DEPTH_COMPONENT32F
      @gl_depth24_stencil8 35056  # GL_DEPTH24_STENCIL8
      @gl_depth32f_stencil8 36013  # GL_DEPTH32F_STENCIL8

      # ============================================================================
      # BLENDING
      # ============================================================================

      @gl_blend 3042  # GL_BLEND
      @gl_blend_src 3041  # GL_BLEND_SRC
      @gl_blend_dst 3040  # GL_BLEND_DST
      @gl_blend_equation 32777  # GL_BLEND_EQUATION
      @gl_blend_equation_rgb 32777  # GL_BLEND_EQUATION_RGB
      @gl_blend_equation_alpha 34877  # GL_BLEND_EQUATION_ALPHA
      @gl_blend_dst_rgb 32968  # GL_BLEND_DST_RGB
      @gl_blend_src_rgb 32969  # GL_BLEND_SRC_RGB
      @gl_blend_dst_alpha 32970  # GL_BLEND_DST_ALPHA
      @gl_blend_src_alpha 32971  # GL_BLEND_SRC_ALPHA
      @gl_blend_color 32773  # GL_BLEND_COLOR

      # Blend functions
      @gl_zero 0  # GL_ZERO
      @gl_one 1  # GL_ONE
      @gl_src_color 768  # GL_SRC_COLOR
      @gl_one_minus_src_color 769  # GL_ONE_MINUS_SRC_COLOR
      @gl_dst_color 774  # GL_DST_COLOR
      @gl_one_minus_dst_color 775  # GL_ONE_MINUS_DST_COLOR
      @gl_src_alpha 770  # GL_SRC_ALPHA
      @gl_one_minus_src_alpha 771  # GL_ONE_MINUS_SRC_ALPHA
      @gl_dst_alpha 772  # GL_DST_ALPHA
      @gl_one_minus_dst_alpha 773  # GL_ONE_MINUS_DST_ALPHA
      @gl_constant_color 32769  # GL_CONSTANT_COLOR
      @gl_one_minus_constant_color 32770  # GL_ONE_MINUS_CONSTANT_COLOR
      @gl_constant_alpha 32771  # GL_CONSTANT_ALPHA
      @gl_one_minus_constant_alpha 32772  # GL_ONE_MINUS_CONSTANT_ALPHA
      @gl_src_alpha_saturate 776  # GL_SRC_ALPHA_SATURATE

      # Blend equations
      @gl_func_add 32774  # GL_FUNC_ADD
      @gl_func_subtract 32778  # GL_FUNC_SUBTRACT
      @gl_func_reverse_subtract 32779  # GL_FUNC_REVERSE_SUBTRACT
      @gl_min 32775  # GL_MIN
      @gl_max 32776  # GL_MAX

      # ============================================================================
      # BUFFER BITS
      # ============================================================================

      @gl_color_buffer_bit 16384  # GL_COLOR_BUFFER_BIT
      @gl_depth_buffer_bit 256  # GL_DEPTH_BUFFER_BIT
      @gl_stencil_buffer_bit 1024  # GL_STENCIL_BUFFER_BIT

      # ============================================================================
      # OPENGL CAPABILITIES
      # ============================================================================

      @gl_depth_test 2929  # GL_DEPTH_TEST
      @gl_stencil_test 2960  # GL_STENCIL_TEST
      @gl_cull_face 2884  # GL_CULL_FACE
      @gl_scissor_test 3089  # GL_SCISSOR_TEST
      @gl_alpha_test 3008  # GL_ALPHA_TEST
      @gl_dither 3024  # GL_DITHER
      @gl_color_logic_op 3058  # GL_COLOR_LOGIC_OP
      @gl_polygon_offset_fill 32823  # GL_POLYGON_OFFSET_FILL
      @gl_polygon_offset_line 10754  # GL_POLYGON_OFFSET_LINE
      @gl_polygon_offset_point 10753  # GL_POLYGON_OFFSET_POINT
      @gl_multisample 32925  # GL_MULTISAMPLE
      @gl_sample_alpha_to_coverage 32926  # GL_SAMPLE_ALPHA_TO_COVERAGE
      @gl_sample_alpha_to_one 32927  # GL_SAMPLE_ALPHA_TO_ONE
      @gl_sample_coverage 32928  # GL_SAMPLE_COVERAGE

      # ============================================================================
      # DEPTH TESTING
      # ============================================================================

      @gl_never 512  # GL_NEVER
      @gl_less 513  # GL_LESS
      @gl_equal 514  # GL_EQUAL
      @gl_lequal 515  # GL_LEQUAL
      @gl_greater 516  # GL_GREATER
      @gl_notequal 517  # GL_NOTEQUAL
      @gl_gequal 518  # GL_GEQUAL
      @gl_always 519  # GL_ALWAYS

      # ============================================================================
      # STENCIL OPERATIONS
      # ============================================================================

      @gl_keep 7680  # GL_KEEP
      @gl_replace 7681  # GL_REPLACE
      @gl_incr 7682  # GL_INCR
      @gl_decr 7683  # GL_DECR
      @gl_invert 5386  # GL_INVERT
      @gl_incr_wrap 34055  # GL_INCR_WRAP
      @gl_decr_wrap 34056  # GL_DECR_WRAP

      # ============================================================================
      # FRAMEBUFFERS
      # ============================================================================

      @gl_framebuffer 36160  # GL_FRAMEBUFFER
      @gl_read_framebuffer 36008  # GL_READ_FRAMEBUFFER
      @gl_draw_framebuffer 36009  # GL_DRAW_FRAMEBUFFER
      @gl_renderbuffer 36161  # GL_RENDERBUFFER
      @gl_color_attachment0 36064  # GL_COLOR_ATTACHMENT0
      @gl_color_attachment1 36065  # GL_COLOR_ATTACHMENT1
      @gl_color_attachment2 36066  # GL_COLOR_ATTACHMENT2
      @gl_color_attachment3 36067  # GL_COLOR_ATTACHMENT3
      @gl_color_attachment4 36068  # GL_COLOR_ATTACHMENT4
      @gl_color_attachment5 36069  # GL_COLOR_ATTACHMENT5
      @gl_color_attachment6 36070  # GL_COLOR_ATTACHMENT6
      @gl_color_attachment7 36071  # GL_COLOR_ATTACHMENT7
      @gl_depth_attachment 36096  # GL_DEPTH_ATTACHMENT
      @gl_stencil_attachment 36128  # GL_STENCIL_ATTACHMENT
      @gl_depth_stencil_attachment 33306  # GL_DEPTH_STENCIL_ATTACHMENT

      # Framebuffer status
      @gl_framebuffer_complete 36053  # GL_FRAMEBUFFER_COMPLETE
      @gl_framebuffer_incomplete_attachment 36054  # GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT
      @gl_framebuffer_incomplete_missing_attachment 36055  # GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT
      @gl_framebuffer_incomplete_draw_buffer 36059  # GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER
      @gl_framebuffer_incomplete_read_buffer 36060  # GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER
      @gl_framebuffer_unsupported 36061  # GL_FRAMEBUFFER_UNSUPPORTED
      @gl_framebuffer_incomplete_multisample 36182  # GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE

      # ============================================================================
      # MATRIX MODES (Legacy)
      # ============================================================================

      @gl_modelview 5888  # GL_MODELVIEW
      @gl_projection 5889  # GL_PROJECTION
      @gl_texture 5890  # GL_TEXTURE

      # ============================================================================
      # POINT RENDERING
      # ============================================================================

      @gl_point_smooth 2832  # GL_POINT_SMOOTH
      @gl_point_size 2833  # GL_POINT_SIZE
      @gl_point_size_min 33062  # GL_POINT_SIZE_MIN
      @gl_point_size_max 33063  # GL_POINT_SIZE_MAX
      @gl_point_fade_threshold_size 33064  # GL_POINT_FADE_THRESHOLD_SIZE
      @gl_point_distance_attenuation 33065  # GL_POINT_DISTANCE_ATTENUATION

      # ============================================================================
      # LINE RENDERING
      # ============================================================================

      @gl_line_smooth 2848  # GL_LINE_SMOOTH
      @gl_line_width 2849  # GL_LINE_WIDTH
      @gl_line_stipple 2852  # GL_LINE_STIPPLE

      # ============================================================================
      # OPENGL INFO
      # ============================================================================

      @gl_vendor 7936  # GL_VENDOR
      @gl_renderer 7937  # GL_RENDERER
      @gl_version 7938  # GL_VERSION
      @gl_extensions 7939  # GL_EXTENSIONS
      @gl_shading_language_version 35724  # GL_SHADING_LANGUAGE_VERSION
      @gl_major_version 33307  # GL_MAJOR_VERSION
      @gl_minor_version 33308  # GL_MINOR_VERSION
      @gl_context_flags 33310  # GL_CONTEXT_FLAGS
      @gl_context_profile_mask 37158  # GL_CONTEXT_PROFILE_MASK

      # ============================================================================
      # TEXTURE UNITS
      # ============================================================================

      @gl_texture0 33984  # GL_TEXTURE0
      @gl_texture1 33985  # GL_TEXTURE1
      @gl_texture2 33986  # GL_TEXTURE2
      @gl_texture3 33987  # GL_TEXTURE3
      @gl_texture4 33988  # GL_TEXTURE4
      @gl_texture5 33989  # GL_TEXTURE5
      @gl_texture6 33990  # GL_TEXTURE6
      @gl_texture7 33991  # GL_TEXTURE7
      @gl_active_texture 34016  # GL_ACTIVE_TEXTURE
      @gl_max_texture_units 34018  # GL_MAX_TEXTURE_UNITS
      @gl_max_combined_texture_image_units 35661  # GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS

      # ============================================================================
      # QUERY OBJECTS
      # ============================================================================

      @gl_query_result 34918  # GL_QUERY_RESULT
      @gl_query_result_available 34919  # GL_QUERY_RESULT_AVAILABLE
      @gl_samples_passed 35092  # GL_SAMPLES_PASSED
      @gl_any_samples_passed 35887  # GL_ANY_SAMPLES_PASSED
      @gl_any_samples_passed_conservative 36202  # GL_ANY_SAMPLES_PASSED_CONSERVATIVE
      @gl_primitives_generated 35975  # GL_PRIMITIVES_GENERATED
      @gl_transform_feedback_primitives_written 35976  # GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN
      @gl_time_elapsed 35007  # GL_TIME_ELAPSED
      @gl_timestamp 36392  # GL_TIMESTAMP

      # ============================================================================
      # UNIFORM TYPES
      # ============================================================================

      @gl_float_vec2 35664  # GL_FLOAT_VEC2
      @gl_float_vec3 35665  # GL_FLOAT_VEC3
      @gl_float_vec4 35666  # GL_FLOAT_VEC4
      @gl_int_vec2 35667  # GL_INT_VEC2
      @gl_int_vec3 35668  # GL_INT_VEC3
      @gl_int_vec4 35669  # GL_INT_VEC4
      @gl_bool 35670  # GL_BOOL
      @gl_bool_vec2 35671  # GL_BOOL_VEC2
      @gl_bool_vec3 35672  # GL_BOOL_VEC3
      @gl_bool_vec4 35673  # GL_BOOL_VEC4
      @gl_float_mat2 35674  # GL_FLOAT_MAT2
      @gl_float_mat3 35675  # GL_FLOAT_MAT3
      @gl_float_mat4 35676  # GL_FLOAT_MAT4
      @gl_sampler_2d 35678  # GL_SAMPLER_2D
      @gl_sampler_cube 35680  # GL_SAMPLER_CUBE

      # ============================================================================
      # VIEWPORT
      # ============================================================================

      @gl_viewport 2978  # GL_VIEWPORT
      @gl_scissor_box 3088  # GL_SCISSOR_BOX
      @gl_depth_range 2928  # GL_DEPTH_RANGE

      # ============================================================================
      # ERROR CODES
      # ============================================================================

      @gl_no_error 0  # GL_NO_ERROR
      @gl_invalid_enum 1280  # GL_INVALID_ENUM
      @gl_invalid_value 1281  # GL_INVALID_VALUE
      @gl_invalid_operation 1282  # GL_INVALID_OPERATION
      @gl_stack_overflow 1283  # GL_STACK_OVERFLOW
      @gl_stack_underflow 1284  # GL_STACK_UNDERFLOW
      @gl_out_of_memory 1285  # GL_OUT_OF_MEMORY
      @gl_invalid_framebuffer_operation 1286  # GL_INVALID_FRAMEBUFFER_OPERATION
      @gl_context_lost 1287  # GL_CONTEXT_LOST

      # ============================================================================
      # LEGACY/COMPATIBILITY CONSTANTS
      # ============================================================================

      @gl_program 33505  # GL_PROGRAM
      @gl_program_iv 33506  # GL_PROGRAM_IV
    end
  end
end
