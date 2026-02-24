# Screen handling for Tea v2-exp

module Tea
  # Screen provides screen manipulation functions
  module Screen
    # Clear the screen
    def self.clear
      print "\e[2J\e[H"
    end

    # Clear from cursor to end of line
    def self.clear_line
      print "\e[K"
    end

    # Clear from cursor to beginning of line
    def self.clear_line_start
      print "\e[1K"
    end

    # Clear entire line
    def self.clear_line_all
      print "\e[2K"
    end

    # Move cursor to position (1-indexed)
    def self.move_cursor(x : Int32, y : Int32)
      print "\e[#{y};#{x}H"
    end

    # Hide cursor
    def self.hide_cursor
      print "\e[?25l"
    end

    # Show cursor
    def self.show_cursor
      print "\e[?25h"
    end

    # Enable alternate screen buffer
    def self.enter_alt_screen
      print "\e[?1049h"
    end

    # Disable alternate screen buffer
    def self.exit_alt_screen
      print "\e[?1049l"
    end

    # Request cursor position (response will be a CursorPositionMsg)
    def self.request_cursor_position
      print "\e[6n"
    end

    # Request terminal size (response will be a WindowSizeMsg)
    def self.request_size
      print "\e[18t"
    end

    # Save cursor position
    def self.save_cursor
      print "\e7"
    end

    # Restore cursor position
    def self.restore_cursor
      print "\e8"
    end

    # Enable mouse tracking
    def self.enable_mouse
      print "\e[?1000h\e[?1002h\e[?1003h\e[?1006h"
    end

    # Disable mouse tracking
    def self.disable_mouse
      print "\e[?1006l\e[?1003l\e[?1002l\e[?1000l"
    end

    # Enable bracketed paste
    def self.enable_bracketed_paste
      print "\e[?2004h"
    end

    # Disable bracketed paste
    def self.disable_bracketed_paste
      print "\e[?2004l"
    end

    # Enable focus reporting
    def self.enable_focus_reporting
      print "\e[?1004h"
    end

    # Disable focus reporting
    def self.disable_focus_reporting
      print "\e[?1004l"
    end

    # Set window title
    # ameba:disable Naming/AccessorMethodName
    def self.set_window_title(title : String)
      print "\e]0;#{title}\e\\"
    end

    # Request window title
    def self.request_window_title
      print "\e]21;t\e\\"
    end

    # Reset terminal to default state
    def self.reset
      print "\ec"
    end

    # Get terminal size
    def self.size : Tuple(Int32, Int32)
      # Try to get actual size from terminal
      # This is a simplified version - real implementation would use TIOCGWINSZ
      {80, 24}
    end
  end

  # AlternativeScreen enables alternate screen buffer
  def self.alt_screen : Cmd
    -> : Msg? {
      Screen.enter_alt_screen
      nil
    }
  end

  # ExitAltScreen disables alternate screen buffer
  def self.exit_alt_screen : Cmd
    -> : Msg? {
      Screen.exit_alt_screen
      nil
    }
  end

  # EnableMouse enables mouse tracking
  def self.enable_mouse : Cmd
    -> : Msg? {
      Screen.enable_mouse
      nil
    }
  end

  # DisableMouse disables mouse tracking
  def self.disable_mouse : Cmd
    -> : Msg? {
      Screen.disable_mouse
      nil
    }
  end

  # ClearScreen clears the screen
  def self.clear_screen : Cmd
    -> : Msg? {
      Screen.clear
      nil
    }
  end

  # HideCursor hides the cursor
  def self.hide_cursor : Cmd
    -> : Msg? {
      Screen.hide_cursor
      nil
    }
  end

  # ShowCursor shows the cursor
  def self.show_cursor : Cmd
    -> : Msg? {
      Screen.show_cursor
      nil
    }
  end
end
