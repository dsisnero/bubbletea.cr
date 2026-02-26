# Cursed renderer for Tea v2-exp
# Ported from Go cursed_renderer.go
# This is the main renderer implementation that handles terminal output

require "colorful"

module Tea
  # Crystal idiom would use writer-style setters (`logger=`, `color_profile=`,
  # `width_method=`), but this file keeps Go-parity method names.
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
    @unicode_core_mode : Bool = false

    def initialize(w : IO, env : Ultraviolet::Environ, width : Int32, height : Int32)
      @w = w
      @buf = IO::Memory.new
      @env = env
      @term = env.getenv("TERM")
      @width = width
      @height = height
      @mutex = Mutex.new
      @profile = Ultraviolet::ColorProfile::TrueColor
      @view = View.new

      # Initialize with a valid renderer; reset will fully configure it.
      @scr = Ultraviolet::TerminalRenderer.new(@buf, env.items)
      @cellbuf = Ultraviolet::ScreenBuffer.new(@width, @height)

      reset
    end

    # set_logger sets the logger for the renderer
    # ameba:disable Naming/AccessorMethodName
    def set_logger(logger : Ultraviolet::Logger)
      @mutex.synchronize do
        @logger = logger
      end
    end

    # ameba:enable Naming/AccessorMethodName

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
            @scr.write_string(Ansi.set_cursor_color(hex))
          end

          # Set cursor style
          style = Tea.encode_cursor_style(cursor.style, cursor.style.to_s.includes?("Blinking"))
          if style != 0 && style != 1
            @scr.write_string(Ansi.set_cursor_style(style))
          end
        end

        # Set foreground color
        if fg = last.foreground_color
          hex = fg.hex
          @scr.write_string(Ansi.set_foreground_color(hex))
        end

        # Set background color
        if bg = last.background_color
          hex = bg.hex
          @scr.write_string(Ansi.set_background_color(hex))
        end

        # Enable bracketed paste unless disabled
        unless last.disable_bracketed_paste?
          @scr.write_string(Ansi::SetModeBracketedPaste)
        end

        # Enable focus reporting
        if last.report_focus?
          @scr.write_string(Ansi::SetModeFocusEvent)
        end

        # Set mouse mode
        case last.mouse_mode
        when MouseMode::None
          # No mouse
        when MouseMode::CellMotion
          @scr.write_string(Ansi::SetModeMouseButtonEvent + Ansi::SetModeMouseExtSgr)
        when MouseMode::AllMotion
          @scr.write_string(Ansi::SetModeMouseAnyEvent + Ansi::SetModeMouseExtSgr)
        end

        # Set window title
        if last.window_title != ""
          @scr.write_string(Ansi.set_window_title(last.window_title))
        end

        # Set progress bar
        if pb = last.progress_bar
          set_progress_bar(pb)
        end

        # Enable keyboard enhancements
        @scr.write_string(Ansi::SetModifyOtherKeys2)

        # Kitty keyboard protocol
        kitty_flags = Ansi::KittyDisambiguateEscapeCodes
        if last.keyboard_enhancements.report_event_types?
          kitty_flags |= Ansi::KittyReportEventTypes
        end
        @scr.write_string(Ansi.kitty_keyboard(kitty_flags, 1))
      end
    end

    # close closes the renderer and flushes any remaining data
    # Implements renderer interface
    def close : Exception?
      @mutex.synchronize do
        if last = @last_view
          # Reset keyboard protocol
          @buf << Ansi::ResetModifyOtherKeys
          @buf << Ansi.kitty_keyboard(0, 1)

          # Go to bottom of screen regardless of mode.
          @scr.move_to(0, @cellbuf.height - 1)
          @scr.flush

          if last.alt_screen?
            enable_alt_screen(false, true)
          else
            # For non-altscreen, erase below
            @scr.write_string(Ansi::EraseScreenBelow)
          end

          # Show cursor if it was hidden
          if last.cursor.nil?
            enable_text_cursor(true)
          end

          # Reset bracketed paste
          unless last.disable_bracketed_paste?
            @scr.write_string(Ansi::ResetModeBracketedPaste)
          end

          # Reset focus reporting
          if last.report_focus?
            @scr.write_string(Ansi::ResetModeFocusEvent)
          end

          # Reset mouse mode
          case last.mouse_mode
          when MouseMode::None
            # No mouse
          when MouseMode::CellMotion, MouseMode::AllMotion
            @scr.write_string(Ansi::ResetModeMouseButtonEvent +
                              Ansi::ResetModeMouseAnyEvent +
                              Ansi::ResetModeMouseExtSgr)
          end

          # Clear window title
          if last.window_title != ""
            @scr.write_string(Ansi.set_window_title(""))
          end

          # Reset cursor
          if cursor = last.cursor
            style = Tea.encode_cursor_style(cursor.style, cursor.style.to_s.includes?("Blinking"))
            if style != 0 && style != 1
              @scr.write_string(Ansi.set_cursor_style(0))
            end

            if cursor.color
              @scr.write_string(Ansi::ResetCursorColor)
            end
          end

          # Reset colors
          if last.background_color
            @scr.write_string(Ansi::ResetBackgroundColor)
          end

          if last.foreground_color
            @scr.write_string(Ansi::ResetForegroundColor)
          end

          # Reset progress bar
          if pb = last.progress_bar
            if pb.state != ProgressBarState::None
              @scr.write_string(Ansi::ResetProgressBar)
            end
          end
        end

        # Reset unicode mode
        if @unicode_core_mode
          @scr.write_string(Ansi::ResetModeUnicodeCore)
        end

        @scr.flush

        # Write buffer to output
        if @buf.size > 0
          if logger = @logger
            logger.printf("output: %s", @buf.to_s)
          end

          @w.write(@buf.to_slice)
          @w.flush
        end

        # Preserve cursor position across reset.
        x, y = @scr.position

        # Reset renderer state
        reset
        @scr.set_position(x, y)

        nil
      end
    rescue ex
      ex
    end

    # write_string writes a string to the renderer's output
    # Implements renderer interface
    def write_string(content : String) : Tuple(Int32, Exception?)
      @mutex.synchronize do
        {@scr.write_string(content), nil}
      end
    rescue ex
      {0, ex}
    end

    # flush flushes the renderer's buffer to the output
    # Implements renderer interface
    def flush(closing : Bool) : Exception?
      @mutex.synchronize do
        view = @view
        last_view = @last_view
        frame_width = @width
        frame_height = view.content.empty? ? 0 : @height
        content = Ultraviolet::StyledString.new(view.content)

        unless view.alt_screen?
          content_height = content.height
          frame_height = content_height if content_height != frame_height
        end

        frame_area = Ultraviolet.rect(0, 0, frame_width, frame_height)
        if !@starting && !closing && last_view && view_equals(last_view, view) && frame_area == @cellbuf.bounds
          return
        end

        @starting = false

        if frame_area != @cellbuf.bounds
          @scr.erase
          @cellbuf.touched = Array(Ultraviolet::LineData?).new(frame_height, nil)
          @cellbuf.resize(frame_width, frame_height)
        end

        @cellbuf.clear
        content.draw(@cellbuf, @cellbuf.bounds)

        if frame_height > @height
          (frame_height - @height).times { @cellbuf.lines.shift? }
        end

        should_update_alt_screen = if last_view
                                     last_view.alt_screen? != view.alt_screen?
                                   else
                                     view.alt_screen?
                                   end
        if should_update_alt_screen
          # Update internal renderer mode, but defer escape sequence emission
          # so it can be wrapped with cursor visibility/sync updates.
          enable_alt_screen(view.alt_screen?, false)
        end

        if last_view.nil? || view.disable_bracketed_paste? != last_view.disable_bracketed_paste?
          if !view.disable_bracketed_paste?
            @scr.write_string(Ansi::SetModeBracketedPaste)
          elsif last_view
            @scr.write_string(Ansi::ResetModeBracketedPaste)
          end
        end

        if last_view.nil? || last_view.report_focus? != view.report_focus?
          if view.report_focus?
            @scr.write_string(Ansi::SetModeFocusEvent)
          elsif last_view
            @scr.write_string(Ansi::ResetModeFocusEvent)
          end
        end

        if last_view.nil? || view.mouse_mode != last_view.mouse_mode
          case view.mouse_mode
          when MouseMode::None
            if last_view && last_view.mouse_mode != MouseMode::None
              @scr.write_string(Ansi::ResetModeMouseButtonEvent +
                                Ansi::ResetModeMouseAnyEvent +
                                Ansi::ResetModeMouseExtSgr)
            end
          when MouseMode::CellMotion
            if last_view && last_view.mouse_mode == MouseMode::AllMotion
              @scr.write_string(Ansi::ResetModeMouseAnyEvent)
            end
            @scr.write_string(Ansi::SetModeMouseButtonEvent + Ansi::SetModeMouseExtSgr)
          when MouseMode::AllMotion
            if last_view && last_view.mouse_mode == MouseMode::CellMotion
              @scr.write_string(Ansi::ResetModeMouseButtonEvent)
            end
            @scr.write_string(Ansi::SetModeMouseAnyEvent + Ansi::SetModeMouseExtSgr)
          end
        end

        if last_view.nil? || view.window_title != last_view.window_title
          if last_view || !view.window_title.empty?
            @scr.write_string(Ansi.set_window_title(view.window_title))
          end
        end

        if last_view.nil? ||
           view.keyboard_enhancements != last_view.keyboard_enhancements ||
           view.alt_screen? != last_view.alt_screen?
          @scr.write_string(Ansi::SetModifyOtherKeys2)

          kitty_flags = Ansi::KittyDisambiguateEscapeCodes
          if view.keyboard_enhancements.report_event_types?
            kitty_flags |= Ansi::KittyReportEventTypes
          end
          @scr.write_string(Ansi.kitty_keyboard(kitty_flags, 1))
          @scr.write_string(Ansi::RequestKittyKeyboard) unless closing
        end

        cc = view.cursor.try(&.color)
        lcc = last_view.try(&.cursor).try(&.color)
        lfg = last_view.try(&.foreground_color)
        lbg = last_view.try(&.background_color)

        [
          {cc, lcc, Ansi::ResetCursorColor, ->(hex : String) { Ansi.set_cursor_color(hex) }},
          {view.foreground_color, lfg, Ansi::ResetForegroundColor, ->(hex : String) { Ansi.set_foreground_color(hex) }},
          {view.background_color, lbg, Ansi::ResetBackgroundColor, ->(hex : String) { Ansi.set_background_color(hex) }},
        ].each do |entry|
          new_color, old_color, reset_seq, setter = entry
          next if new_color == old_color

          if new_color.nil?
            @scr.write_string(reset_seq)
          elsif color = new_color
            @scr.write_string(setter.call(color.hex))
          else
            # no-op
          end
        end

        cc_style = 0
        lc_style = 0
        if ccur = view.cursor
          cc_style = Tea.encode_cursor_style(ccur.style, ccur.style.to_s.includes?("Blinking"))
        end
        if lcur = last_view.try(&.cursor)
          lc_style = Tea.encode_cursor_style(lcur.style, lcur.style.to_s.includes?("Blinking"))
        end
        @scr.write_string(Ansi.set_cursor_style(cc_style)) if cc_style != lc_style

        progress_changed = if last_view.nil?
                             if progress = view.progress_bar
                               progress.state != ProgressBarState::None
                             else
                               false
                             end
                           elsif last_view.progress_bar.nil? != view.progress_bar.nil?
                             true
                           elsif (last_progress = last_view.progress_bar) && (progress = view.progress_bar)
                             last_progress != progress
                           else
                             false
                           end
        if progress_changed
          set_progress_bar(view.progress_bar)
        end

        @scr.render(@cellbuf)

        if cur = view.cursor
          @scr.move_to(cur.x, cur.y)
        elsif !view.alt_screen?
          x, y = @scr.position
          @scr.move_to(0, y) if x >= @width - 1
        end

        @scr.flush

        has_updates = @buf.size > 0
        did_show_cursor = !last_view.nil? && !last_view.cursor.nil?
        show_cursor = !view.cursor.nil?
        hide_cursor = !show_cursor
        should_update_cursor_vis = last_view.nil? || did_show_cursor != show_cursor || should_update_alt_screen

        output_buf = IO::Memory.new
        if should_update_alt_screen
          output_buf << Ansi::ResetModifyOtherKeys
          output_buf << Ansi.kitty_keyboard(0, 1)
          if view.alt_screen?
            output_buf << Ansi::SetModeAltScreenSaveCursor
          else
            output_buf << Ansi::ResetModeAltScreenSaveCursor
          end
        end

        if @syncd_updates
          output_buf << Ansi::SetModeSynchronizedOutput if has_updates
          output_buf << Ansi::ResetModeTextCursorEnable if should_update_cursor_vis && hide_cursor
        elsif (should_update_cursor_vis && hide_cursor) || (has_updates && show_cursor && did_show_cursor)
          output_buf << Ansi::ResetModeTextCursorEnable
        end

        output_buf.write(@buf.to_slice) if has_updates

        if @syncd_updates
          output_buf << Ansi::SetModeTextCursorEnable if should_update_cursor_vis && show_cursor
          output_buf << Ansi::ResetModeSynchronizedOutput if has_updates
        elsif (should_update_cursor_vis && show_cursor) || (has_updates && show_cursor && did_show_cursor)
          output_buf << Ansi::SetModeTextCursorEnable
        end

        @buf.clear

        if output_buf.size > 0
          if logger = @logger
            logger.printf("output: %s", String.new(output_buf.to_slice))
          end
          @w.write(output_buf.to_slice)
          @w.flush
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
        @buf.clear
        scr = Ultraviolet::TerminalRenderer.new(@buf, @env.items)
        scr.color_profile = @profile
        scr.relative_cursor = true
        scr.fullscreen = false
        scr.tab_stops = @width
        scr.backspace = @backspace
        scr.map_newline = @mapnl
        {% if flag?(:windows) %}
          scr.scroll_optim = false
        {% else %}
          scr.scroll_optim = true
        {% end %}
        @scr = scr
        @cellbuf = Ultraviolet::ScreenBuffer.new(@width, @height)
        @last_view = nil
      end
    end

    # insert_above inserts unmanaged lines above the renderer
    # Implements renderer interface
    def insert_above(content : String) : Exception?
      @mutex.synchronize do
        return if content.empty?

        # Move to bottom of screen and write content
        @buf << "\r"
        @buf << Ansi.cursor_down(@cellbuf.height - 1)

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
        @scr.erase
        @width = width
        @height = height
        @scr.resize(width, height)
        @cellbuf = Ultraviolet::ScreenBuffer.new(width, height)
      end
    end

    # set_color_profile sets the color profile
    # Implements renderer interface
    # ameba:disable Naming/AccessorMethodName
    def set_color_profile(profile : Ultraviolet::ColorProfile)
      @mutex.synchronize do
        @profile = profile
        @scr.color_profile = profile
      end
    end

    # ameba:enable Naming/AccessorMethodName

    # set_width_method sets terminal width calculation method
    # Implements renderer interface
    # ameba:disable Naming/AccessorMethodName
    def set_width_method(method : Ultraviolet::WidthMethod)
      @mutex.synchronize do
        if method != @cellbuf.method
          if method == Ultraviolet::DEFAULT_WIDTH_METHOD
            @scr.write_string(Ansi::ResetModeUnicodeCore)
            @unicode_core_mode = false
          else
            @scr.write_string(Ansi::SetModeUnicodeCore)
            @unicode_core_mode = true
          end
        end
        @cellbuf.method = method
      end
    end

    # ameba:enable Naming/AccessorMethodName

    # clear_screen clears the screen
    # Implements renderer interface
    def clear_screen
      @mutex.synchronize do
        @scr.move_to(0, 0)
        @scr.erase
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

    private def enable_alt_screen(enable : Bool, write : Bool)
      if enable
        @scr.save_cursor
        @buf << Ansi::SetModeAltScreenSaveCursor if write
        @scr.fullscreen = true
        @scr.relative_cursor = false
        @scr.erase
      else
        @scr.erase
        @scr.relative_cursor = true
        @scr.fullscreen = false
        @buf << Ansi::ResetModeAltScreenSaveCursor if write
        @scr.restore_cursor
      end
    end

    private def enable_text_cursor(enable : Bool)
      if enable
        @scr.write_string(Ansi::ShowCursor)
      else
        @scr.write_string(Ansi::HideCursor)
      end
    end

    private def set_progress_bar(pb : ProgressBar?)
      return unless pb

      seq = case pb.state
            when ProgressBarState::None
              Ansi::ResetProgressBar
            when ProgressBarState::Default
              Ansi.set_progress_bar(pb.value.to_i)
            when ProgressBarState::Error
              Ansi.set_error_progress_bar(pb.value.to_i)
            when ProgressBarState::Indeterminate
              Ansi::SetIndeterminateProgressBar
            when ProgressBarState::Warning
              Ansi.set_warning_progress_bar(pb.value.to_i)
            else
              ""
            end

      @scr.write_string(seq) unless seq.empty?
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
