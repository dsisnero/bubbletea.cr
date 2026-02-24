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
    property profile : String

    def initialize(@profile : String)
    end
  end

  # KeyboardEnhancementsMsg reports which keyboard enhancements are supported
  struct KeyboardEnhancementsMsg
    include Msg
    property enhancements : KeyboardEnhancements

    def initialize(@enhancements : KeyboardEnhancements)
    end
  end

  # CursorPositionMsg reports the cursor position
  struct CursorPositionMsg
    include Msg
    property x : Int32
    property y : Int32

    def initialize(@x : Int32, @y : Int32)
    end
  end

  # RawMsg for raw input events
  struct RawMsg
    include Msg
    property data : Bytes

    def initialize(@data : Bytes)
    end
  end

  # CapabilityMsg reports terminal capabilities
  struct CapabilityMsg
    include Msg
    property capability : String
    property value : String

    def initialize(@capability : String, @value : String)
    end
  end

  # TerminalVersionMsg reports the terminal version
  struct TerminalVersionMsg
    include Msg
    property version : String

    def initialize(@version : String)
    end
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

    def initialize(@key : String, @value : String)
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

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      # Calculate luminance - if < 0.5, it's dark
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end
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

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      # Calculate luminance - if < 0.5, it's dark
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end
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

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      # Calculate luminance - if < 0.5, it's dark
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end
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

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end
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

    # Returns whether the color is dark
    # ameba:disable Naming/PredicateName
    def is_dark? : Bool
      r, g, b = color.r, color.g, color.b
      luminance = 0.299 * r + 0.587 * g + 0.114 * b
      luminance < 0.5
    end
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
end
