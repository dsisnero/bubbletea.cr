# Message types for Tea v2-exp

module Tea
  # QuitMsg signals that the program should quit
  struct QuitMsg
    include Msg
  end

  # SuspendMsg signals the program should suspend
  struct SuspendMsg
    include Msg
  end

  # ResumeMsg signals the program has resumed from suspend
  struct ResumeMsg
    include Msg
  end

  # InterruptMsg signals the program should interrupt (Ctrl+C)
  struct InterruptMsg
    include Msg
  end

  # WindowSizeMsg reports the terminal window size
  struct WindowSizeMsg
    include Msg
    property width : Int32
    property height : Int32

    def initialize(@width : Int32, @height : Int32)
    end
  end

  # ClearScreenMsg clears the screen
  struct ClearScreenMsg
    include Msg
  end

  # FocusMsg signals the terminal gained focus
  struct FocusMsg
    include Msg
  end

  # BlurMsg signals the terminal lost focus
  struct BlurMsg
    include Msg
  end

  # PasteMsg contains pasted content
  struct PasteMsg
    include Msg
    property content : String

    def initialize(@content : String)
    end

    # Go parity helper for PasteMsg.String().
    def string : String
      content
    end
  end

  # PasteStartMsg signals the start of a paste operation
  struct PasteStartMsg
    include Msg
  end

  # PasteEndMsg signals the end of a paste operation
  struct PasteEndMsg
    include Msg
  end

  # ColorProfileMsg reports the terminal color profile
  struct ColorProfileMsg
    include Msg
    property profile : Ultraviolet::ColorProfile

    def initialize(@profile : Ultraviolet::ColorProfile)
    end
  end

  # KeyboardEnhancementsMsg reports which keyboard enhancements are supported
  struct KeyboardEnhancementsMsg
    include Msg
    property enhancements : KeyboardEnhancements

    def initialize(@enhancements : KeyboardEnhancements)
    end

    # Returns whether the terminal supports key disambiguation
    # (e.g., distinguishing between different modifier keys)
    def supports_key_disambiguation? : Bool
      # Non-zero flags indicates basic key disambiguation support
      enhancements.report_alternate_keys? ||
        enhancements.report_event_types? ||
        enhancements.report_all_keys?
    end

    # Go parity helper for KeyboardEnhancementsMsg.SupportsKeyDisambiguation().
    # ameba:disable Naming/PredicateName
    def supports_key_disambiguation : Bool
      supports_key_disambiguation?
    end
    # ameba:enable Naming/PredicateName

    # Returns whether the terminal supports reporting different types
    # of key events (press, release, and repeat)
    def supports_event_types? : Bool
      enhancements.report_event_types?
    end

    # Go parity helper for KeyboardEnhancementsMsg.SupportsEventTypes().
    # ameba:disable Naming/PredicateName
    def supports_event_types : Bool
      supports_event_types?
    end
    # ameba:enable Naming/PredicateName
  end

  # CursorPositionMsg reports the cursor position
  struct CursorPositionMsg
    include Msg
    property x : Int32
    property y : Int32

    def initialize(@x : Int32, @y : Int32)
    end
  end

  # RawMsg is a message that contains a string to be printed to the terminal
  # without any intermediate processing.
  struct RawMsg
    include Msg
    property msg : String

    def initialize(@msg : String)
    end
  end

  # CapabilityMsg reports terminal capabilities
  struct CapabilityMsg
    include Msg
    property content : String

    def initialize(@content : String)
    end

    # Returns the capability content as a string
    def to_s : String
      @content
    end

    # Go parity helper for CapabilityMsg.String().
    def string : String
      to_s
    end
  end

  # RequestCapabilityMsg is an internal message that requests terminal capabilities
  struct RequestCapabilityMsg
    include Msg
    property capability : String

    def initialize(@capability : String)
    end
  end

  # RequestCapability is a command that requests the terminal to send its
  # Termcap/Terminfo response for the given capability.
  #
  # Bubble Tea recognizes the following capabilities:
  #   - "RGB" Xterm direct color
  #   - "Tc" True color support
  def self.request_capability(capability : String) : Cmd
    -> : Msg? { RequestCapabilityMsg.new(capability) }
  end

  # TerminalVersionMsg reports the terminal version
  struct TerminalVersionMsg
    include Msg
    property name : String

    def initialize(@name : String)
    end

    # Returns the terminal name as a string
    def to_s : String
      @name
    end

    # Go parity helper for TerminalVersionMsg.String().
    def string : String
      to_s
    end
  end

  # TerminalVersionRequestMsg is an internal message that queries the terminal version
  struct TerminalVersionRequestMsg
    include Msg
  end

  # RequestTerminalVersion is a command that queries the terminal for its
  # version using XTVERSION. Note that some terminals may not support this.
  def self.request_terminal_version : Cmd
    -> : Msg? { TerminalVersionRequestMsg.new }
  end

  # ModeReportMsg reports terminal mode status
  struct ModeReportMsg
    include Msg
    property mode : Int32
    property value : Int32

    def initialize(@mode : Int32, @value : Int32)
    end
  end

  # EnvMsg reports environment variable changes
  struct EnvMsg
    include Msg
    property key : String
    property value : String
    property environ : Ultraviolet::Environ

    def initialize(@key : String, @value : String)
      @environ = Ultraviolet::Environ.new(["#{@key}=#{@value}"])
    end

    def initialize(@environ : Ultraviolet::Environ)
      @key = ""
      @value = ""
    end

    # Getenv returns the value of the environment variable named by the key.
    def getenv(key : String) : String
      @environ.getenv(key)
    end

    # LookupEnv retrieves the value of the environment variable named by key.
    def lookup_env(key : String) : Tuple(String, Bool)
      @environ.lookup_env(key)
    end
  end

  # BackgroundColorMsg sets the background color
  struct BackgroundColorMsg
    include Msg

    getter color : Colorful::Color

    def initialize(@color : Colorful::Color)
    end

    # Returns hex representation of the color
    def to_s : String
      color.hex
    end

    # Go parity helper for BackgroundColorMsg.String().
    def string : String
      to_s
    end

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      # Calculate luminance - if < 0.5, it's dark
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end

    # Go parity helper for BackgroundColorMsg.IsDark().
    # ameba:disable Naming/PredicateName
    def is_dark : Bool
      is_dark?
    end
    # ameba:enable Naming/PredicateName
  end

  # ForegroundColorMsg sets the foreground color
  struct ForegroundColorMsg
    include Msg

    getter color : Colorful::Color

    def initialize(@color : Colorful::Color)
    end

    # Returns hex representation of the color
    def to_s : String
      color.hex
    end

    # Go parity helper for ForegroundColorMsg.String().
    def string : String
      to_s
    end

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      # Calculate luminance - if < 0.5, it's dark
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end

    # Go parity helper for ForegroundColorMsg.IsDark().
    # ameba:disable Naming/PredicateName
    def is_dark : Bool
      is_dark?
    end
    # ameba:enable Naming/PredicateName
  end

  # CursorColorMsg sets the cursor color
  struct CursorColorMsg
    include Msg

    getter color : Colorful::Color

    def initialize(@color : Colorful::Color)
    end

    # Returns hex representation of the color
    def to_s : String
      color.hex
    end

    # Go parity helper for CursorColorMsg.String().
    def string : String
      to_s
    end

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end

    # Go parity helper for CursorColorMsg.IsDark().
    # ameba:disable Naming/PredicateName
    def is_dark : Bool
      is_dark?
    end
    # ameba:enable Naming/PredicateName
  end

  # RequestBackgroundColor returns a command that requests the terminal background color
  def self.request_background_color : Cmd
    -> : Msg? { BackgroundColorMsg.new(Colorful::Color.new(0.0, 0.0, 0.0)) }
  end

  # RequestForegroundColor returns a command that requests the terminal foreground color
  def self.request_foreground_color : Cmd
    -> : Msg? { ForegroundColorMsg.new(Colorful::Color.new(1.0, 1.0, 1.0)) }
  end

  # RequestCursorColor returns a command that requests the terminal cursor color
  def self.request_cursor_color : Cmd
    -> : Msg? { CursorColorMsg.new(Colorful::Color.new(1.0, 1.0, 1.0)) }
  end

  # Raw prints the given string to the terminal without any formatting.
  # This is intended for advanced use cases where you need to query the terminal
  # or send escape sequences directly.
  def self.raw(msg : String) : Cmd
    -> : Msg? { RawMsg.new(msg) }
  end
end
