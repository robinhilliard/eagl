defmodule WX.Const do
  @moduledoc """
  wxWidgets constants for GUI and OpenGL canvas management.
  Use this module to inject wxWidgets constants as module attributes.

  ## Usage

      defmodule MyModule do
        use WX.Const

        # Now you can use @wx_vertical, @wx_gl_rgba, @wx_expand, etc.
      end

  ## Categories

  This module provides constants for:
  - OpenGL canvas attributes (WX_GL_*)
  - Layout directions and sizer flags
  - Window styles and background styles
  - Event types and window management
  """

  defmacro __using__(_opts) do
    quote do
      # ============================================================================
      # OPENGL CANVAS ATTRIBUTES (WX_GL_*)
      # ============================================================================

      @wx_gl_rgba 1  # WX_GL_RGBA
      @wx_gl_buffer_size 2  # WX_GL_BUFFER_SIZE
      @wx_gl_level 3  # WX_GL_LEVEL
      @wx_gl_doublebuffer 4  # WX_GL_DOUBLEBUFFER
      @wx_gl_stereo 5  # WX_GL_STEREO
      @wx_gl_aux_buffers 6  # WX_GL_AUX_BUFFERS
      @wx_gl_min_red 7  # WX_GL_MIN_RED
      @wx_gl_min_green 8  # WX_GL_MIN_GREEN
      @wx_gl_min_blue 9  # WX_GL_MIN_BLUE
      @wx_gl_min_alpha 10  # WX_GL_MIN_ALPHA
      @wx_gl_depth_size 11  # WX_GL_DEPTH_SIZE
      @wx_gl_stencil_size 12  # WX_GL_STENCIL_SIZE
      @wx_gl_min_accum_red 13  # WX_GL_MIN_ACCUM_RED
      @wx_gl_min_accum_green 14  # WX_GL_MIN_ACCUM_GREEN
      @wx_gl_min_accum_blue 15  # WX_GL_MIN_ACCUM_BLUE
      @wx_gl_min_accum_alpha 16  # WX_GL_MIN_ACCUM_ALPHA
      @wx_gl_sample_buffers 17  # WX_GL_SAMPLE_BUFFERS
      @wx_gl_samples 18  # WX_GL_SAMPLES
      @wx_gl_framebuffer_srgb 19  # WX_GL_FRAMEBUFFER_SRGB
      @wx_gl_forward_compat 24  # WX_GL_FORWARD_COMPAT
      @wx_gl_debug 26  # WX_GL_DEBUG
      @wx_gl_robust_access 27  # WX_GL_ROBUST_ACCESS
      @wx_gl_no_reset_notify 28  # WX_GL_NO_RESET_NOTIFY
      @wx_gl_lose_on_reset 29  # WX_GL_LOSE_ON_RESET
      @wx_gl_reset_isolation 30  # WX_GL_RESET_ISOLATION
      @wx_gl_release_flush 31  # WX_GL_RELEASE_FLUSH
      @wx_gl_release_none 32  # WX_GL_RELEASE_NONE

      # ============================================================================
      # LAYOUT DIRECTIONS
      # ============================================================================

      @wx_horizontal 4  # wxHORIZONTAL
      @wx_vertical 8  # wxVERTICAL
      @wx_both 12  # wxBOTH (wxHORIZONTAL | wxVERTICAL)

      # ============================================================================
      # SIZER FLAGS
      # ============================================================================

      @wx_expand 8192  # wxEXPAND
      @wx_shaped 16384  # wxSHAPED
      @wx_fixed_minsize 32768  # wxFIXED_MINSIZE
      @wx_reserve_space_even_if_hidden 2  # wxRESERVE_SPACE_EVEN_IF_HIDDEN

      # Alignment flags
      @wx_align_center 512  # wxALIGN_CENTER
      @wx_align_centre 512  # wxALIGN_CENTRE (same as CENTER)
      @wx_align_left 0  # wxALIGN_LEFT
      @wx_align_right 256  # wxALIGN_RIGHT
      @wx_align_top 0  # wxALIGN_TOP
      @wx_align_bottom 1024  # wxALIGN_BOTTOM
      @wx_align_center_horizontal 256  # wxALIGN_CENTER_HORIZONTAL
      @wx_align_centre_horizontal 256  # wxALIGN_CENTRE_HORIZONTAL
      @wx_align_center_vertical 512  # wxALIGN_CENTER_VERTICAL
      @wx_align_centre_vertical 512  # wxALIGN_CENTRE_VERTICAL

      # Border flags
      @wx_all 61440  # wxALL
      @wx_top 4096  # wxTOP
      @wx_bottom 8192  # wxBOTTOM
      @wx_left 16384  # wxLEFT
      @wx_right 32768  # wxRIGHT
      @wx_north 4096  # wxNORTH (same as TOP)
      @wx_south 8192  # wxSOUTH (same as BOTTOM)
      @wx_east 32768  # wxEAST (same as RIGHT)
      @wx_west 16384  # wxWEST (same as LEFT)

      # ============================================================================
      # WINDOW STYLES
      # ============================================================================

      @wx_simple_border 33554432  # wxSIMPLE_BORDER
      @wx_double_border 67108864  # wxDOUBLE_BORDER
      @wx_sunken_border 134217728  # wxSUNKEN_BORDER
      @wx_raised_border 268435456  # wxRAISED_BORDER
      @wx_static_border 16777216  # wxSTATIC_BORDER
      @wx_theme_border 268435456  # wxTHEME_BORDER
      @wx_no_border 2097152  # wxNO_BORDER
      @wx_transparent_window 1048576  # wxTRANSPARENT_WINDOW
      @wx_tab_traversal 524288  # wxTAB_TRAVERSAL
      @wx_wants_chars 262144  # wxWANTS_CHARS
      @wx_popup_window 131072  # wxPOPUP_WINDOW
      @wx_center_on_screen 65536  # wxCENTER_ON_SCREEN
      @wx_centre_on_screen 65536  # wxCENTRE_ON_SCREEN
      @wx_full_repaint_on_resize 65536  # wxFULL_REPAINT_ON_RESIZE
      @wx_clip_children 4194304  # wxCLIP_CHILDREN
      @wx_clip_siblings 8388608  # wxCLIP_SIBLINGS

      # ============================================================================
      # BACKGROUND STYLES
      # ============================================================================

      @wx_bg_style_system 0  # wxBG_STYLE_SYSTEM
      @wx_bg_style_colour 1  # wxBG_STYLE_COLOUR
      @wx_bg_style_custom 2  # wxBG_STYLE_CUSTOM
      @wx_bg_style_transparent 3  # wxBG_STYLE_TRANSPARENT
      @wx_bg_style_paint 2  # wxBG_STYLE_PAINT (same as CUSTOM)

      # ============================================================================
      # STANDARD IDS
      # ============================================================================

      @wx_id_any -1  # wxID_ANY
      @wx_id_none -3  # wxID_NONE
      @wx_id_separator -2  # wxID_SEPARATOR
      @wx_id_lowest 4999  # wxID_LOWEST
      @wx_id_open 5000  # wxID_OPEN
      @wx_id_close 5001  # wxID_CLOSE
      @wx_id_new 5002  # wxID_NEW
      @wx_id_save 5003  # wxID_SAVE
      @wx_id_saveas 5004  # wxID_SAVEAS
      @wx_id_revert 5005  # wxID_REVERT
      @wx_id_exit 5006  # wxID_EXIT
      @wx_id_undo 5007  # wxID_UNDO
      @wx_id_redo 5008  # wxID_REDO
      @wx_id_help 5009  # wxID_HELP
      @wx_id_print 5010  # wxID_PRINT
      @wx_id_print_setup 5011  # wxID_PRINT_SETUP
      @wx_id_preview 5012  # wxID_PREVIEW
      @wx_id_about 5013  # wxID_ABOUT
      @wx_id_help_contents 5014  # wxID_HELP_CONTENTS
      @wx_id_help_commands 5015  # wxID_HELP_COMMANDS
      @wx_id_help_procedures 5016  # wxID_HELP_PROCEDURES
      @wx_id_help_context 5017  # wxID_HELP_CONTEXT
      @wx_id_close_all 5018  # wxID_CLOSE_ALL
      @wx_id_preferences 5019  # wxID_PREFERENCES
      @wx_id_cut 5030  # wxID_CUT
      @wx_id_copy 5031  # wxID_COPY
      @wx_id_paste 5032  # wxID_PASTE
      @wx_id_clear 5033  # wxID_CLEAR
      @wx_id_find 5034  # wxID_FIND
      @wx_id_duplicate 5035  # wxID_DUPLICATE
      @wx_id_selectall 5036  # wxID_SELECTALL
      @wx_id_delete 5037  # wxID_DELETE
      @wx_id_replace 5038  # wxID_REPLACE
      @wx_id_replace_all 5039  # wxID_REPLACE_ALL
      @wx_id_properties 5040  # wxID_PROPERTIES
      @wx_id_view_details 5041  # wxID_VIEW_DETAILS
      @wx_id_view_largeicons 5042  # wxID_VIEW_LARGEICONS
      @wx_id_view_smallicons 5043  # wxID_VIEW_SMALLICONS
      @wx_id_view_list 5044  # wxID_VIEW_LIST
      @wx_id_view_sortdate 5045  # wxID_VIEW_SORTDATE
      @wx_id_view_sortname 5046  # wxID_VIEW_SORTNAME
      @wx_id_view_sortsize 5047  # wxID_VIEW_SORTSIZE
      @wx_id_view_sorttype 5048  # wxID_VIEW_SORTTYPE
      @wx_id_file1 5050  # wxID_FILE1
      @wx_id_file2 5051  # wxID_FILE2
      @wx_id_file3 5052  # wxID_FILE3
      @wx_id_file4 5053  # wxID_FILE4
      @wx_id_file5 5054  # wxID_FILE5
      @wx_id_file6 5055  # wxID_FILE6
      @wx_id_file7 5056  # wxID_FILE7
      @wx_id_file8 5057  # wxID_FILE8
      @wx_id_file9 5058  # wxID_FILE9
      @wx_id_ok 5100  # wxID_OK
      @wx_id_cancel 5101  # wxID_CANCEL
      @wx_id_apply 5102  # wxID_APPLY
      @wx_id_yes 5103  # wxID_YES
      @wx_id_no 5104  # wxID_NO
      @wx_id_static 5105  # wxID_STATIC
      @wx_id_forward 5106  # wxID_FORWARD
      @wx_id_backward 5107  # wxID_BACKWARD
      @wx_id_default 5108  # wxID_DEFAULT
      @wx_id_more 5109  # wxID_MORE
      @wx_id_setup 5110  # wxID_SETUP
      @wx_id_reset 5111  # wxID_RESET
      @wx_id_context_help 5112  # wxID_CONTEXT_HELP
      @wx_id_yestoall 5113  # wxID_YESTOALL
      @wx_id_notoall 5114  # wxID_NOTOALL
      @wx_id_abort 5115  # wxID_ABORT
      @wx_id_retry 5116  # wxID_RETRY
      @wx_id_ignore 5117  # wxID_IGNORE
      @wx_id_add 5118  # wxID_ADD
      @wx_id_remove 5119  # wxID_REMOVE
      @wx_id_up 5120  # wxID_UP
      @wx_id_down 5121  # wxID_DOWN
      @wx_id_home 5122  # wxID_HOME
      @wx_id_refresh 5123  # wxID_REFRESH
      @wx_id_stop 5124  # wxID_STOP
      @wx_id_index 5125  # wxID_INDEX
      @wx_id_bold 5126  # wxID_BOLD
      @wx_id_italic 5127  # wxID_ITALIC
      @wx_id_justify_center 5128  # wxID_JUSTIFY_CENTER
      @wx_id_justify_fill 5129  # wxID_JUSTIFY_FILL
      @wx_id_justify_right 5130  # wxID_JUSTIFY_RIGHT
      @wx_id_justify_left 5131  # wxID_JUSTIFY_LEFT
      @wx_id_underline 5132  # wxID_UNDERLINE
      @wx_id_indent 5133  # wxID_INDENT
      @wx_id_unindent 5134  # wxID_UNINDENT
      @wx_id_zoom_100 5135  # wxID_ZOOM_100
      @wx_id_zoom_fit 5136  # wxID_ZOOM_FIT
      @wx_id_zoom_in 5137  # wxID_ZOOM_IN
      @wx_id_zoom_out 5138  # wxID_ZOOM_OUT
      @wx_id_undelete 5139  # wxID_UNDELETE
      @wx_id_revert_to_saved 5140  # wxID_REVERT_TO_SAVED
      @wx_id_highest 5999  # wxID_HIGHEST

      # ============================================================================
      # FRAME STYLES
      # ============================================================================

      @wx_default_frame_style 2080374784  # wxDEFAULT_FRAME_STYLE
      @wx_iconize 16384  # wxICONIZE
      @wx_caption 536870912  # wxCAPTION
      @wx_minimize 16384  # wxMINIMIZE
      @wx_minimize_box 1024  # wxMINIMIZE_BOX
      @wx_maximize 8192  # wxMAXIMIZE
      @wx_maximize_box 512  # wxMAXIMIZE_BOX
      @wx_close_box 4096  # wxCLOSE_BOX
      @wx_stay_on_top 32768  # wxSTAY_ON_TOP
      @wx_system_menu 2048  # wxSYSTEM_MENU
      @wx_resize_border 64  # wxRESIZE_BORDER
      @wx_frame_tool_window 4  # wxFRAME_TOOL_WINDOW
      @wx_frame_no_taskbar 2  # wxFRAME_NO_TASKBAR
      @wx_frame_float_on_parent 8  # wxFRAME_FLOAT_ON_PARENT
      @wx_frame_shaped 16  # wxFRAME_SHAPED

      # ============================================================================
      # DIALOG STYLES
      # ============================================================================

      @wx_default_dialog_style 1073750016  # wxDEFAULT_DIALOG_STYLE
      @wx_dialog_no_parent 1  # wxDIALOG_NO_PARENT
      @wx_dialog_ex_contexthelp 128  # wxDIALOG_EX_CONTEXTHELP
      @wx_dialog_ex_metal 256  # wxDIALOG_EX_METAL

      # ============================================================================
      # COMMON CONSTANTS
      # ============================================================================

      @wx_not_found -1  # wxNOT_FOUND
      @wx_default_coord -1  # wxDefaultCoord
      @wx_default_size -1  # wxDefaultSize (used for width/height)
      @wx_default_position -1  # wxDefaultPosition (used for x/y)
    end
  end
end
