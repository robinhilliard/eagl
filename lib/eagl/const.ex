defmodule EAGL.Const do
  @moduledoc """
  Curated set of 300 OpenGL constants for 3D graphics programming. Additional constants
  can be added as needed from the 4,925 constants in the wx/include/gl.hrl file.

  Use this module to inject OpenGL constants as module attributes.

  ## Usage

      defmodule MyModule do
        use EAGL.Const

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

      # GL_VERTEX_SHADER
      @gl_vertex_shader 35633
      # GL_FRAGMENT_SHADER
      @gl_fragment_shader 35632
      # GL_GEOMETRY_SHADER
      @gl_geometry_shader 36313
      # GL_TESS_CONTROL_SHADER
      @gl_tess_control_shader 36488
      # GL_TESS_EVALUATION_SHADER
      @gl_tess_evaluation_shader 36487
      # GL_COMPUTE_SHADER
      @gl_compute_shader 37305

      # ============================================================================
      # SHADER COMPILATION/LINKING
      # ============================================================================

      # GL_COMPILE_STATUS
      @gl_compile_status 35713
      # GL_LINK_STATUS
      @gl_link_status 35714
      # GL_VALIDATE_STATUS
      @gl_validate_status 35715
      # GL_INFO_LOG_LENGTH
      @gl_info_log_length 35716
      # GL_SHADER_SOURCE_LENGTH
      @gl_shader_source_length 35720
      # GL_DELETE_STATUS
      @gl_delete_status 35712

      # ============================================================================
      # PROGRAM ATTRIBUTES
      # ============================================================================

      # GL_ACTIVE_PROGRAM
      @gl_active_program 33369
      # GL_CURRENT_PROGRAM
      @gl_current_program 35725
      # GL_ACTIVE_ATTRIBUTES
      @gl_active_attributes 35721
      # GL_ACTIVE_UNIFORMS
      @gl_active_uniforms 35718
      # GL_ATTACHED_SHADERS
      @gl_attached_shaders 35717
      # GL_ACTIVE_UNIFORM_BLOCKS
      @gl_active_uniform_blocks 35382
      # GL_ACTIVE_UNIFORM_MAX_LENGTH
      @gl_active_uniform_max_length 35719
      # GL_ACTIVE_ATTRIBUTE_MAX_LENGTH
      @gl_active_attribute_max_length 35722

      # ============================================================================
      # BUFFER TYPES
      # ============================================================================

      # GL_ARRAY_BUFFER
      @gl_array_buffer 34962
      # GL_ELEMENT_ARRAY_BUFFER
      @gl_element_array_buffer 34963
      # GL_UNIFORM_BUFFER
      @gl_uniform_buffer 35345
      # GL_TEXTURE_BUFFER
      @gl_texture_buffer 35882
      # GL_TRANSFORM_FEEDBACK_BUFFER
      @gl_transform_feedback_buffer 35982
      # GL_COPY_READ_BUFFER
      @gl_copy_read_buffer 36662
      # GL_COPY_WRITE_BUFFER
      @gl_copy_write_buffer 36663
      # GL_PIXEL_PACK_BUFFER
      @gl_pixel_pack_buffer 35051
      # GL_PIXEL_UNPACK_BUFFER
      @gl_pixel_unpack_buffer 35052
      # GL_QUERY_BUFFER
      @gl_query_buffer 37266
      # GL_SHADER_STORAGE_BUFFER
      @gl_shader_storage_buffer 37074
      # GL_ATOMIC_COUNTER_BUFFER
      @gl_atomic_counter_buffer 37568
      # GL_DRAW_INDIRECT_BUFFER
      @gl_draw_indirect_buffer 36671
      # GL_DISPATCH_INDIRECT_BUFFER
      @gl_dispatch_indirect_buffer 37102

      # ============================================================================
      # BUFFER USAGE PATTERNS
      # ============================================================================

      # GL_STATIC_DRAW
      @gl_static_draw 35044
      # GL_DYNAMIC_DRAW
      @gl_dynamic_draw 35048
      # GL_STREAM_DRAW
      @gl_stream_draw 35040
      # GL_STATIC_READ
      @gl_static_read 35045
      # GL_DYNAMIC_READ
      @gl_dynamic_read 35049
      # GL_STREAM_READ
      @gl_stream_read 35041
      # GL_STATIC_COPY
      @gl_static_copy 35046
      # GL_DYNAMIC_COPY
      @gl_dynamic_copy 35050
      # GL_STREAM_COPY
      @gl_stream_copy 35042

      # ============================================================================
      # BUFFER BINDINGS
      # ============================================================================

      # GL_ARRAY_BUFFER_BINDING
      @gl_array_buffer_binding 34964
      # GL_ELEMENT_ARRAY_BUFFER_BINDING
      @gl_element_array_buffer_binding 34965
      # GL_UNIFORM_BUFFER_BINDING
      @gl_uniform_buffer_binding 35368
      # GL_VERTEX_ARRAY_BINDING
      @gl_vertex_array_binding 34229

      # ============================================================================
      # DRAWING PRIMITIVES
      # ============================================================================

      # GL_POINTS
      @gl_points 0
      # GL_LINES
      @gl_lines 1
      # GL_LINE_LOOP
      @gl_line_loop 2
      # GL_LINE_STRIP
      @gl_line_strip 3
      # GL_TRIANGLES
      @gl_triangles 4
      # GL_TRIANGLE_STRIP
      @gl_triangle_strip 5
      # GL_TRIANGLE_FAN
      @gl_triangle_fan 6
      # GL_QUADS
      @gl_quads 7
      # GL_QUAD_STRIP
      @gl_quad_strip 8
      # GL_POLYGON
      @gl_polygon 9
      # GL_LINES_ADJACENCY
      @gl_lines_adjacency 10
      # GL_LINE_STRIP_ADJACENCY
      @gl_line_strip_adjacency 11
      # GL_TRIANGLES_ADJACENCY
      @gl_triangles_adjacency 12
      # GL_TRIANGLE_STRIP_ADJACENCY
      @gl_triangle_strip_adjacency 13
      # GL_PATCHES
      @gl_patches 14

      # ============================================================================
      # POLYGON MODES
      # ============================================================================

      # GL_POINT
      @gl_point 6912
      # GL_LINE
      @gl_line 6913
      # GL_FILL
      @gl_fill 6914

      # ============================================================================
      # FACE CULLING
      # ============================================================================

      # GL_FRONT
      @gl_front 1028
      # GL_BACK
      @gl_back 1029
      # GL_FRONT_AND_BACK
      @gl_front_and_back 1032
      # GL_CW (clockwise)
      @gl_cw 2304
      # GL_CCW (counter-clockwise)
      @gl_ccw 2305

      # ============================================================================
      # DATA TYPES
      # ============================================================================

      # GL_BYTE
      @gl_byte 5120
      # GL_UNSIGNED_BYTE
      @gl_unsigned_byte 5121
      # GL_SHORT
      @gl_short 5122
      # GL_UNSIGNED_SHORT
      @gl_unsigned_short 5123
      # GL_INT
      @gl_int 5124
      # GL_UNSIGNED_INT
      @gl_unsigned_int 5125
      # GL_FLOAT
      @gl_float 5126
      # GL_DOUBLE
      @gl_double 5130
      # GL_HALF_FLOAT
      @gl_half_float 5131
      # GL_FIXED
      @gl_fixed 5132
      # GL_INT_2_10_10_10_REV
      @gl_int_2_10_10_10_rev 36255
      # GL_UNSIGNED_INT_2_10_10_10_REV
      @gl_unsigned_int_2_10_10_10_rev 33640
      # GL_UNSIGNED_INT_10F_11F_11F_REV
      @gl_unsigned_int_10f_11f_11f_rev 35899

      # ============================================================================
      # VERTEX ATTRIBUTES
      # ============================================================================

      # GL_VERTEX_ATTRIB_ARRAY_ENABLED
      @gl_vertex_attrib_array_enabled 34338
      # GL_VERTEX_ATTRIB_ARRAY_SIZE
      @gl_vertex_attrib_array_size 34339
      # GL_VERTEX_ATTRIB_ARRAY_STRIDE
      @gl_vertex_attrib_array_stride 34340
      # GL_VERTEX_ATTRIB_ARRAY_TYPE
      @gl_vertex_attrib_array_type 34341
      # GL_VERTEX_ATTRIB_ARRAY_NORMALIZED
      @gl_vertex_attrib_array_normalized 34922
      # GL_VERTEX_ATTRIB_ARRAY_POINTER
      @gl_vertex_attrib_array_pointer 34373
      # GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING
      @gl_vertex_attrib_array_buffer_binding 34975
      # GL_VERTEX_ATTRIB_BINDING
      @gl_vertex_attrib_binding 33492
      # GL_VERTEX_ATTRIB_ARRAY_INTEGER
      @gl_vertex_attrib_array_integer 35069
      # GL_VERTEX_ATTRIB_ARRAY_DIVISOR
      @gl_vertex_attrib_array_divisor 35070

      # ============================================================================
      # PIXEL STORE PARAMETERS
      # ============================================================================

      # GL_UNPACK_ALIGNMENT
      @gl_unpack_alignment 3317
      # GL_PACK_ALIGNMENT
      @gl_pack_alignment 3333

      # ============================================================================
      # TEXTURES
      # ============================================================================

      # GL_TEXTURE_1D
      @gl_texture_1d 3552
      # GL_TEXTURE_2D
      @gl_texture_2d 3553
      # GL_TEXTURE_3D
      @gl_texture_3d 32879
      # GL_TEXTURE_CUBE_MAP
      @gl_texture_cube_map 34067
      # GL_TEXTURE_1D_ARRAY
      @gl_texture_1d_array 35864
      # GL_TEXTURE_2D_ARRAY
      @gl_texture_2d_array 35866
      # GL_TEXTURE_CUBE_MAP_ARRAY
      @gl_texture_cube_map_array 36873
      # GL_TEXTURE_RECTANGLE
      @gl_texture_rectangle 34037
      # GL_TEXTURE_2D_MULTISAMPLE
      @gl_texture_2d_multisample 37120
      # GL_TEXTURE_2D_MULTISAMPLE_ARRAY
      @gl_texture_2d_multisample_array 37122
      # GL_TEXTURE_BUFFER
      @gl_texture_buffer 35882

      # Cube map faces
      # GL_TEXTURE_CUBE_MAP_POSITIVE_X
      @gl_texture_cube_map_positive_x 34069
      # GL_TEXTURE_CUBE_MAP_NEGATIVE_X
      @gl_texture_cube_map_negative_x 34070
      # GL_TEXTURE_CUBE_MAP_POSITIVE_Y
      @gl_texture_cube_map_positive_y 34071
      # GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
      @gl_texture_cube_map_negative_y 34072
      # GL_TEXTURE_CUBE_MAP_POSITIVE_Z
      @gl_texture_cube_map_positive_z 34073
      # GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
      @gl_texture_cube_map_negative_z 34074

      # ============================================================================
      # TEXTURE PARAMETERS
      # ============================================================================

      # GL_TEXTURE_MIN_FILTER
      @gl_texture_min_filter 10241
      # GL_TEXTURE_MAG_FILTER
      @gl_texture_mag_filter 10240
      # GL_TEXTURE_WRAP_S
      @gl_texture_wrap_s 10242
      # GL_TEXTURE_WRAP_T
      @gl_texture_wrap_t 10243
      # GL_TEXTURE_WRAP_R
      @gl_texture_wrap_r 32882
      # GL_TEXTURE_BASE_LEVEL
      @gl_texture_base_level 33084
      # GL_TEXTURE_MAX_LEVEL
      @gl_texture_max_level 33085
      # GL_TEXTURE_LOD_BIAS
      @gl_texture_lod_bias 34049
      # GL_TEXTURE_COMPARE_MODE
      @gl_texture_compare_mode 34892
      # GL_TEXTURE_COMPARE_FUNC
      @gl_texture_compare_func 34893

      # ============================================================================
      # TEXTURE UNITS
      # ============================================================================

      # GL_TEXTURE0
      @gl_texture0 33984
      # GL_TEXTURE1
      @gl_texture1 33985
      # GL_TEXTURE2
      @gl_texture2 33986
      # GL_TEXTURE3
      @gl_texture3 33987
      # GL_TEXTURE4
      @gl_texture4 33988
      # GL_TEXTURE5
      @gl_texture5 33989
      # GL_TEXTURE6
      @gl_texture6 33990
      # GL_TEXTURE7
      @gl_texture7 33991
      # GL_TEXTURE8
      @gl_texture8 33992
      # GL_TEXTURE9
      @gl_texture9 33993
      # GL_TEXTURE10
      @gl_texture10 33994
      # GL_TEXTURE11
      @gl_texture11 33995
      # GL_TEXTURE12
      @gl_texture12 33996
      # GL_TEXTURE13
      @gl_texture13 33997
      # GL_TEXTURE14
      @gl_texture14 33998
      # GL_TEXTURE15
      @gl_texture15 33999

      # ============================================================================
      # TEXTURE FILTERING
      # ============================================================================

      # GL_NEAREST
      @gl_nearest 9728
      # GL_LINEAR
      @gl_linear 9729
      # GL_NEAREST_MIPMAP_NEAREST
      @gl_nearest_mipmap_nearest 9984
      # GL_LINEAR_MIPMAP_NEAREST
      @gl_linear_mipmap_nearest 9985
      # GL_NEAREST_MIPMAP_LINEAR
      @gl_nearest_mipmap_linear 9986
      # GL_LINEAR_MIPMAP_LINEAR
      @gl_linear_mipmap_linear 9987

      # ============================================================================
      # TEXTURE WRAPPING
      # ============================================================================

      # GL_CLAMP_TO_EDGE
      @gl_clamp_to_edge 33071
      # GL_CLAMP_TO_BORDER
      @gl_clamp_to_border 33069
      # GL_MIRRORED_REPEAT
      @gl_mirrored_repeat 33648
      # GL_REPEAT
      @gl_repeat 10497
      # GL_MIRROR_CLAMP_TO_EDGE
      @gl_mirror_clamp_to_edge 34627

      # ============================================================================
      # PIXEL FORMATS
      # ============================================================================

      # GL_RED
      @gl_red 6403
      # GL_RG
      @gl_rg 33319
      # GL_RGB
      @gl_rgb 6407
      # GL_RGBA
      @gl_rgba 6408
      # GL_BGR
      @gl_bgr 32992
      # GL_BGRA
      @gl_bgra 32993
      # GL_RED_INTEGER
      @gl_red_integer 36244
      # GL_RG_INTEGER
      @gl_rg_integer 33320
      # GL_RGB_INTEGER
      @gl_rgb_integer 36248
      # GL_RGBA_INTEGER
      @gl_rgba_integer 36249
      # GL_BGR_INTEGER
      @gl_bgr_integer 36250
      # GL_BGRA_INTEGER
      @gl_bgra_integer 36251

      # ============================================================================
      # INTERNAL FORMATS
      # ============================================================================

      # GL_R8
      @gl_r8 33321
      # GL_R8_SNORM
      @gl_r8_snorm 36756
      # GL_R16
      @gl_r16 33322
      # GL_R16_SNORM
      @gl_r16_snorm 36760
      # GL_RG8
      @gl_rg8 33323
      # GL_RG8_SNORM
      @gl_rg8_snorm 36757
      # GL_RG16
      @gl_rg16 33324
      # GL_RG16_SNORM
      @gl_rg16_snorm 36761
      # GL_R3_G3_B2
      @gl_r3_g3_b2 10768
      # GL_RGB4
      @gl_rgb4 32847
      # GL_RGB5
      @gl_rgb5 32848
      # GL_RGB8
      @gl_rgb8 32849
      # GL_RGB8_SNORM
      @gl_rgb8_snorm 36758
      # GL_RGB10
      @gl_rgb10 32850
      # GL_RGB12
      @gl_rgb12 32851
      # GL_RGB16
      @gl_rgb16 32852
      # GL_RGB16_SNORM
      @gl_rgb16_snorm 36762
      # GL_RGBA2
      @gl_rgba2 32853
      # GL_RGBA4
      @gl_rgba4 32854
      # GL_RGB5_A1
      @gl_rgb5_a1 32855
      # GL_RGBA8
      @gl_rgba8 32856
      # GL_RGBA8_SNORM
      @gl_rgba8_snorm 36759
      # GL_RGB10_A2
      @gl_rgb10_a2 32857
      # GL_RGB10_A2UI
      @gl_rgb10_a2ui 36975
      # GL_RGBA12
      @gl_rgba12 32858
      # GL_RGBA16
      @gl_rgba16 32859
      # GL_RGBA16_SNORM
      @gl_rgba16_snorm 36763

      # ============================================================================
      # FLOATING POINT FORMATS
      # ============================================================================

      # GL_R16F
      @gl_r16f 33325
      # GL_RG16F
      @gl_rg16f 33327
      # GL_RGB16F
      @gl_rgb16f 34843
      # GL_RGBA16F
      @gl_rgba16f 34842
      # GL_R32F
      @gl_r32f 33326
      # GL_RG32F
      @gl_rg32f 33328
      # GL_RGB32F
      @gl_rgb32f 34837
      # GL_RGBA32F
      @gl_rgba32f 34836
      # GL_R11F_G11F_B10F
      @gl_r11f_g11f_b10f 35898
      # GL_RGB9_E5
      @gl_rgb9_e5 35901

      # ============================================================================
      # INTEGER FORMATS
      # ============================================================================

      # GL_R8I
      @gl_r8i 33329
      # GL_R8UI
      @gl_r8ui 33330
      # GL_R16I
      @gl_r16i 33331
      # GL_R16UI
      @gl_r16ui 33332
      # GL_R32I
      @gl_r32i 33333
      # GL_R32UI
      @gl_r32ui 33334
      # GL_RG8I
      @gl_rg8i 33335
      # GL_RG8UI
      @gl_rg8ui 33336
      # GL_RG16I
      @gl_rg16i 33337
      # GL_RG16UI
      @gl_rg16ui 33338
      # GL_RG32I
      @gl_rg32i 33339
      # GL_RG32UI
      @gl_rg32ui 33340
      # GL_RGB8I
      @gl_rgb8i 36239
      # GL_RGB8UI
      @gl_rgb8ui 36221
      # GL_RGB16I
      @gl_rgb16i 36233
      # GL_RGB16UI
      @gl_rgb16ui 36215
      # GL_RGB32I
      @gl_rgb32i 36227
      # GL_RGB32UI
      @gl_rgb32ui 36209
      # GL_RGBA8I
      @gl_rgba8i 36238
      # GL_RGBA8UI
      @gl_rgba8ui 36220
      # GL_RGBA16I
      @gl_rgba16i 36232
      # GL_RGBA16UI
      @gl_rgba16ui 36214
      # GL_RGBA32I
      @gl_rgba32i 36226
      # GL_RGBA32UI
      @gl_rgba32ui 36208

      # ============================================================================
      # DEPTH AND STENCIL FORMATS
      # ============================================================================

      # GL_DEPTH_COMPONENT
      @gl_depth_component 6402
      # GL_DEPTH_STENCIL
      @gl_depth_stencil 34041
      # GL_DEPTH_COMPONENT16
      @gl_depth_component16 33189
      # GL_DEPTH_COMPONENT24
      @gl_depth_component24 33190
      # GL_DEPTH_COMPONENT32
      @gl_depth_component32 33191
      # GL_DEPTH_COMPONENT32F
      @gl_depth_component32f 36012
      # GL_DEPTH24_STENCIL8
      @gl_depth24_stencil8 35056
      # GL_DEPTH32F_STENCIL8
      @gl_depth32f_stencil8 36013
      # GL_STENCIL_INDEX
      @gl_stencil_index 6401
      # GL_STENCIL_INDEX1
      @gl_stencil_index1 36166
      # GL_STENCIL_INDEX4
      @gl_stencil_index4 36167
      # GL_STENCIL_INDEX8
      @gl_stencil_index8 36168
      # GL_STENCIL_INDEX16
      @gl_stencil_index16 36169

      # ============================================================================
      # COMPRESSED FORMATS
      # ============================================================================

      # GL_COMPRESSED_RED
      @gl_compressed_red 33317
      # GL_COMPRESSED_RG
      @gl_compressed_rg 33318
      # GL_COMPRESSED_RGB
      @gl_compressed_rgb 34029
      # GL_COMPRESSED_RGBA
      @gl_compressed_rgba 34030
      # GL_COMPRESSED_SRGB
      @gl_compressed_srgb 35912
      # GL_COMPRESSED_SRGB_ALPHA
      @gl_compressed_srgb_alpha 35913

      # ============================================================================
      # BLENDING
      # ============================================================================

      # GL_ZERO
      @gl_zero 0
      # GL_ONE
      @gl_one 1
      # GL_SRC_COLOR
      @gl_src_color 768
      # GL_ONE_MINUS_SRC_COLOR
      @gl_one_minus_src_color 769
      # GL_DST_COLOR
      @gl_dst_color 774
      # GL_ONE_MINUS_DST_COLOR
      @gl_one_minus_dst_color 775
      # GL_SRC_ALPHA
      @gl_src_alpha 770
      # GL_ONE_MINUS_SRC_ALPHA
      @gl_one_minus_src_alpha 771
      # GL_DST_ALPHA
      @gl_dst_alpha 772
      # GL_ONE_MINUS_DST_ALPHA
      @gl_one_minus_dst_alpha 773
      # GL_CONSTANT_COLOR
      @gl_constant_color 32769
      # GL_ONE_MINUS_CONSTANT_COLOR
      @gl_one_minus_constant_color 32770
      # GL_CONSTANT_ALPHA
      @gl_constant_alpha 32771
      # GL_ONE_MINUS_CONSTANT_ALPHA
      @gl_one_minus_constant_alpha 32772
      # GL_SRC_ALPHA_SATURATE
      @gl_src_alpha_saturate 776
      # GL_SRC1_COLOR
      @gl_src1_color 35065
      # GL_ONE_MINUS_SRC1_COLOR
      @gl_one_minus_src1_color 35066
      # GL_SRC1_ALPHA
      @gl_src1_alpha 34185
      # GL_ONE_MINUS_SRC1_ALPHA
      @gl_one_minus_src1_alpha 35067

      # Blend equations
      # GL_FUNC_ADD
      @gl_func_add 32774
      # GL_FUNC_SUBTRACT
      @gl_func_subtract 32778
      # GL_FUNC_REVERSE_SUBTRACT
      @gl_func_reverse_subtract 32779
      # GL_MIN
      @gl_min 32775
      # GL_MAX
      @gl_max 32776

      # ============================================================================
      # DEPTH TESTING
      # ============================================================================

      # GL_DEPTH_BITS
      @gl_depth_bits 3414
      # GL_NEVER
      @gl_never 512
      # GL_LESS
      @gl_less 513
      # GL_EQUAL
      @gl_equal 514
      # GL_LEQUAL
      @gl_lequal 515
      # GL_GREATER
      @gl_greater 516
      # GL_NOTEQUAL
      @gl_notequal 517
      # GL_GEQUAL
      @gl_gequal 518
      # GL_ALWAYS
      @gl_always 519

      # ============================================================================
      # STENCIL OPERATIONS
      # ============================================================================

      # GL_KEEP
      @gl_keep 7680
      # @gl_zero already defined above
      # GL_REPLACE
      @gl_replace 7681
      # GL_INCR
      @gl_incr 7682
      # GL_DECR
      @gl_decr 7683
      # GL_INVERT
      @gl_invert 5386
      # GL_INCR_WRAP
      @gl_incr_wrap 34055
      # GL_DECR_WRAP
      @gl_decr_wrap 34056

      # ============================================================================
      # CLEAR BUFFER BITS
      # ============================================================================

      # GL_COLOR_BUFFER_BIT
      @gl_color_buffer_bit 16384
      # GL_DEPTH_BUFFER_BIT
      @gl_depth_buffer_bit 256
      # GL_STENCIL_BUFFER_BIT
      @gl_stencil_buffer_bit 1024

      # ============================================================================
      # CAPABILITY NAMES
      # ============================================================================

      # GL_BLEND
      @gl_blend 3042
      # GL_CULL_FACE
      @gl_cull_face 2884
      # GL_DEPTH_TEST
      @gl_depth_test 2929
      # GL_DITHER
      @gl_dither 3024
      # GL_POLYGON_OFFSET_FILL
      @gl_polygon_offset_fill 32823
      # GL_SAMPLE_ALPHA_TO_COVERAGE
      @gl_sample_alpha_to_coverage 32926
      # GL_SAMPLE_COVERAGE
      @gl_sample_coverage 32928
      # GL_SCISSOR_TEST
      @gl_scissor_test 3089
      # GL_STENCIL_TEST
      @gl_stencil_test 2960

      # Smooth rendering
      # GL_POINT_SMOOTH
      @gl_point_smooth 2832
      # GL_LINE_SMOOTH
      @gl_line_smooth 2848
      # GL_POLYGON_SMOOTH
      @gl_polygon_smooth 2881

      # Point size
      # GL_PROGRAM_POINT_SIZE
      @gl_program_point_size 34370
      # GL_POINT_SIZE
      @gl_point_size 2833

      # ============================================================================
      # FRAMEBUFFER OBJECTS
      # ============================================================================

      # GL_FRAMEBUFFER
      @gl_framebuffer 36160
      # GL_READ_FRAMEBUFFER
      @gl_read_framebuffer 36008
      # GL_DRAW_FRAMEBUFFER
      @gl_draw_framebuffer 36009
      # GL_COLOR_ATTACHMENT0
      @gl_color_attachment0 36064
      # GL_DEPTH_ATTACHMENT
      @gl_depth_attachment 36096
      # GL_FRAMEBUFFER_COMPLETE
      @gl_framebuffer_complete 36053
      # GL_DEPTH_COMPONENT24
      @gl_depth_component24 33190

      # ============================================================================
      # MATRIX MODES
      # ============================================================================

      # GL_MODELVIEW
      @gl_modelview 5888
      # GL_PROJECTION
      @gl_projection 5889
      # GL_TEXTURE
      @gl_texture 5890

      # ============================================================================
      # ERRORS
      # ============================================================================

      # GL_NO_ERROR
      @gl_no_error 0
      # GL_INVALID_ENUM
      @gl_invalid_enum 1280
      # GL_INVALID_VALUE
      @gl_invalid_value 1281
      # GL_INVALID_OPERATION
      @gl_invalid_operation 1282
      # GL_STACK_OVERFLOW
      @gl_stack_overflow 1283
      # GL_STACK_UNDERFLOW
      @gl_stack_underflow 1284
      # GL_OUT_OF_MEMORY
      @gl_out_of_memory 1285
      # GL_INVALID_FRAMEBUFFER_OPERATION
      @gl_invalid_framebuffer_operation 1286
      # GL_CONTEXT_LOST
      @gl_context_lost 1287
    end
  end
end
