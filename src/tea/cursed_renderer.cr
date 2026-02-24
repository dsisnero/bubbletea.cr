# Cursed renderer for Tea v2-exp
# Ported from Go cursed_renderer.go
# This is the main renderer implementation that handles terminal output

require "colorful"

module Tea
  # CursedRenderer is the main terminal renderer implementation
  # It handles screen buffer management, cursor control, and terminal output
  class CursedRenderer
    include Renderer

    # Output writer
    @w : IO

    # Buffer for accumulating output before flush
    @buf : IO::Memory

    # Terminal renderer from ultraviolet
    @scr : Ultraviolet::TerminalRenderer

    # Cell buffer for tracking screen state
    @cellbuf : Ultraviolet::ScreenBuffer

    # Last rendered view (for comparison)
    @last_view : View? = nil

    # Environment variables
    @env : Ultraviolet::Environ

    # Terminal type ($TERM)
    @term : String

    # Terminal dimensions
    @width : Int32
    @height : Int32

    # Mutex for thread safety
    @mutex : Mutex

    # Color profile
    @profile : Ultraviolet::ColorProfile

    # Logger for debugging
    @logger : Ultraviolet::Logger? = nil

    # Current view being rendered
    @view : View

    # Optimization flags
    @hard_tabs : Bool = false # Use hard tabs for cursor movement
    @backspace : Bool = false # Use backspace for cursor movement
    @mapnl : Bool = false     # Map newline

    # Synchronized updates mode
    @syncd_updates : Bool = false

    # Starting flag (for restoring state after stop/start)
    @starting : Bool = false

    def initialize(w : IO, env : Ultraviolet::Environ, width : Int32, height : Int32)
      @w = w
      @buf = IO::Memory.new
      @env = env
      @term = env.get("TERM", "")
      @width = width
      @height = height
      @mutex = Mutex.new
      @profile = Ultraviolet::ColorProfile::TrueColor
      @view = View.new

      # Initialize terminal renderer and cell buffer
      @scr = Ultraviolet::TerminalRenderer.new(@w, env.vars.to_a)
      @cellbuf = Ultraviolet::ScreenBuffer.new(@width, @height)

      reset
    end

    # set_logger sets the logger for the renderer
    def set_logger(logger : Ultraviolet::Logger)
      @mutex.synchronize do
        @logger = logger
      end
    end

    # set_optimizations sets the cursor movement optimizations
    def set_optimizations(hard_tabs : Bool, backspace : Bool, mapnl : Bool)
      @mutex.synchronize do
        @hard_tabs = hard_tabs
        @backspace = backspace
        @mapnl = mapnl
        @scr.tab_stops = @width
        @scr.backspace = @backspace
        @scr.map_newline = @mapnl
      end
    end

    # start starts the renderer
    # Implements renderer interface
    def start
      @mutex.synchronize do
        @starting = true

        return unless last = @last_view

        # Enable alt screen if requested
        if last.alt_screen?
          enable_alt_screen(true, true)
        end

        # Enable cursor if visible
        enable_text_cursor(last.cursor != nil)

        # Set cursor properties
        if cursor = last.cursor
          # Set cursor color
          if color = cursor.color
            hex = color.hex
            @scr.write_string(ANSI.set_cursor_color(hex))
          end

          # Set cursor style
          style = encode_cursor_style(cursor.style, cursor.style.to_s.includes?("Blinking"))
          if style != 0 && style != 1
            @scr.write_string(ANSI.set_cursor_style(style))
          end
        end

        # Set foreground color
        if fg = last.foreground_color
          hex = fg.hex
          @scr.write_string(ANSI.set_foreground_color(hex))
        end

        # Set background color
        if bg = last.background_color
          hex = bg.hex
          @scr.write_string(ANSI.set_background_color(hex))
        end

        # Enable bracketed paste unless disabled
        unless last.disable_bracketed_paste?
          @scr.write_string(ANSI.set_mode_bracketed_paste)
        end

        # Enable focus reporting
        if last.report_focus?
          @scr.write_string(ANSI.set_mode_focus_event)
        end

        # Set mouse mode
        case last.mouse_mode
        when MouseMode::None
          # No mouse
        when MouseMode::CellMotion
          @scr.write_string(ANSI.set_mode_mouse_button_event + ANSI.set_mode_mouse_ext_sgr)
        when MouseMode::AllMotion
          @scr.write_string(ANSI.set_mode_mouse_any_event + ANSI.set_mode_mouse_ext_sgr)
        end

        # Set window title
        if last.window_title != ""
          @scr.write_string(ANSI.set_window_title(last.window_title))
        end

        # Set progress bar
        if pb = last.progress_bar
          set_progress_bar(pb)
        end

        # Enable keyboard enhancements
        @scr.write_string(ANSI.set_modify_other_keys_2)

        # Kitty keyboard protocol
        kitty_flags = ANSI.kitty_disambiguate_escape_codes
        if last.keyboard_enhancements.report_event_types?
          kitty_flags |= ANSI.kitty_report_event_types
        end
        @scr.write_string(ANSI.kitty_keyboard(kitty_flags, 1))
      end
    end

    # close closes the renderer and flushes any remaining data
    # Implements renderer interface
    def close : Exception?
      @mutex.synchronize do
        if last = @last_view
          # Reset keyboard protocol
          @buf << ANSI.reset_modify_other_keys
          @buf << ANSI.kitty_keyboard(0, 1)

          # Go to bottom of screen
          # Get current position from terminal renderer
          x, y = 0, 0 # Simplified - should get from @scr
          down = @cellbuf.height - y - 1
          @buf << "\r"
          @buf << ANSI.cursor_down(down) if down > 0

          if last.alt_screen?
            enable_alt_screen(false, true)
          else
            # For non-altscreen, erase below
            @buf << ANSI.erase_screen_below
          end

          # Show cursor if it was hidden
          if last.cursor.nil?
            enable_text_cursor(true)
          end

          # Reset bracketed paste
          unless last.disable_bracketed_paste?
            @buf << ANSI.reset_mode_bracketed_paste
          end

          # Reset focus reporting
          if last.report_focus?
            @buf << ANSI.reset_mode_focus_event
          end

          # Reset mouse mode
          case last.mouse_mode
          when MouseMode::None
            # No mouse
          when MouseMode::CellMotion, MouseMode::AllMotion
            @buf << ANSI.reset_mode_mouse_button_event +
                    ANSI.reset_mode_mouse_any_event +
                    ANSI.reset_mode_mouse_ext_sgr
          end

          # Clear window title
          if last.window_title != ""
            @buf << ANSI.set_window_title("")
          end

          # Reset cursor
          if cursor = last.cursor
            style = encode_cursor_style(cursor.style, cursor.style.to_s.includes?("Blinking"))
            if style != 0 && style != 1
              @buf << ANSI.set_cursor_style(0)
            end

            if cursor.color
              @buf << ANSI.reset_cursor_color
            end
          end

          # Reset colors
          if last.background_color
            @buf << ANSI.reset_background_color
          end

          if last.foreground_color
            @buf << ANSI.reset_foreground_color
          end

          # Reset progress bar
          if pb = last.progress_bar
            if pb.state != ProgressBarState::None
              @buf << ANSI.reset_progress_bar
            end
          end
        end

        # Reset unicode mode
        if @cellbuf.method == Ultraviolet::WidthMethod::GraphemeWidth
          @buf << ANSI.reset_mode_unicode_core
        end

        # Write buffer to output
        if @buf.size > 0
          if logger = @logger
            logger.debug("output: #{@buf}")
          end

          @w.write(@buf.to_slice)
          @w.flush
          @buf.clear
        end

        # Save cursor position before reset
        x, y = 0, 0 # Simplified

        # Reset renderer state
        reset

        nil
      end
    rescue ex
      ex
    end

    # write_string writes a string to the renderer's output
    # Implements renderer interface
    def write_string(content : String) : Tuple(Int32, Exception?)
      @mutex.synchronize do
        # Write directly to buffer for now
        @buf << content
        {content.size, nil}
      end
    rescue ex
      {0, ex}
    end

    # flush flushes the renderer's buffer to the output
    # Implements renderer interface
    def flush(closing : Bool) : Exception?
      @mutex.synchronize do
        view = @view

        # Check if anything changed (simplified check)
        changed = @starting || closing || @last_view.nil? ||
                  !view_equals(@last_view, view)

        if changed
          @starting = false

          # Write buffer to output
          if @buf.size > 0
            if logger = @logger
              logger.debug("output: #{@buf}")
            end

            @w.write(@buf.to_slice)
            @w.flush
            @buf.clear
          end
        end

        @last_view = view
        nil
      end
    rescue ex
      ex
    end

    # render renders a frame to the output
    # Implements renderer interface
    def render(view : View)
      @mutex.synchronize do
        @view = view
      end
    end

    # reset resets the renderer's state to its initial state
    # Implements renderer interface
    def reset
      @mutex.synchronize do
        @cellbuf = Ultraviolet::ScreenBuffer.new(@width, @height)
        @last_view = nil
      end
    end

    # insert_above inserts unmanaged lines above the renderer
    # Implements renderer interface
    def insert_above(content : String) : Exception?
      @mutex.synchronize do
        return nil if content.empty?

        # Move to bottom of screen and write content
        @buf << "\r"
        @buf << ANSI.cursor_down(@cellbuf.height - 1)

        lines = content.split("\n")
        lines.each do |line|
          @buf << "\r\n#{line}"
        end

        # Write to output immediately
        @w.write(@buf.to_slice)
        @w.flush
        @buf.clear

        nil
      end
    rescue ex
      ex
    end

    # syncd_updates= sets whether to use synchronized updates
    # Implements renderer interface
    def syncd_updates=(enabled : Bool)
      @mutex.synchronize do
        @syncd_updates = enabled
      end
    end

    # resize notify the renderer of a terminal resize
    # Implements renderer interface
    def resize(width : Int32, height : Int32)
      @mutex.synchronize do
        @width = width
        @height = height
        @cellbuf = Ultraviolet::ScreenBuffer.new(width, height)
      end
    end

    # set_color_profile sets the color profile
    # Implements renderer interface
    def set_color_profile(profile : Ultraviolet::ColorProfile)
      @mutex.synchronize do
        @profile = profile
      end
    end

    # clear_screen clears the screen
    # Implements renderer interface
    def clear_screen
      @mutex.synchronize do
        @buf << ANSI.erase_display
        @cellbuf = Ultraviolet::ScreenBuffer.new(@width, @height)
      end
    end

    # on_mouse handles a mouse event
    # Implements renderer interface
    def on_mouse(msg : MouseMsg) : Cmd?
      if last = @last_view
        if on_mouse_handler = last.on_mouse
          return on_mouse_handler.call(msg)
        end
      end
      nil
    end

    private def enable_alt_screen(enable : Bool, clear : Bool)
      if enable
        @buf << ANSI.enable_alt_screen
        @buf << ANSI.erase_display if clear
      else
        @buf << ANSI.disable_alt_screen
      end
    end

    private def enable_text_cursor(enable : Bool)
      if enable
        @buf << ANSI.show_cursor
      else
        @buf << ANSI.hide_cursor
      end
    end

    private def set_progress_bar(pb : ProgressBar)
      return unless pb

      seq = case pb.state
            when ProgressBarState::None
              ANSI.reset_progress_bar
            when ProgressBarState::Default
              ANSI.set_progress_bar(pb.value.to_i)
            when ProgressBarState::Error
              ANSI.set_error_progress_bar(pb.value.to_i)
            when ProgressBarState::Indeterminate
              ANSI.set_indeterminate_progress_bar
            when ProgressBarState::Warning
              ANSI.set_warning_progress_bar(pb.value.to_i)
            else
              ""
            end

      @buf << seq unless seq.empty?
    end

    private def view_equals(a : View?, b : View) : Bool
      return false unless a

      return false if a.content != b.content
      return false if a.alt_screen? != b.alt_screen?
      return false if a.disable_bracketed_paste? != b.disable_bracketed_paste?
      return false if a.report_focus? != b.report_focus?
      return false if a.mouse_mode != b.mouse_mode
      return false if a.window_title != b.window_title
      return false if a.foreground_color != b.foreground_color
      return false if a.background_color != b.background_color
      return false if a.keyboard_enhancements != b.keyboard_enhancements

      # Compare cursors
      if (a.cursor.nil?) != (b.cursor.nil?)
        return false
      end

      if a_cursor = a.cursor
        if b_cursor = b.cursor
          return false if a_cursor.x != b_cursor.x
          return false if a_cursor.y != b_cursor.y
          return false if a_cursor.style != b_cursor.style
          return false if a_cursor.visible? != b_cursor.visible?
          return false if a_cursor.color != b_cursor.color
        end
      end

      # Compare progress bars
      if (a.progress_bar.nil?) != (b.progress_bar.nil?)
        return false
      end

      if a_pb = a.progress_bar
        if b_pb = b.progress_bar
          return false if a_pb != b_pb
        end
      end

      true
    end
  end

  # Factory method to create a new cursed renderer
  def self.new_cursed_renderer(w : IO, env : Ultraviolet::Environ, width : Int32, height : Int32) : CursedRenderer
    CursedRenderer.new(w, env, width, height)
  end
end
