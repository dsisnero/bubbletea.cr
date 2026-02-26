# Clipboard handling for Tea v2-exp
# Implements OSC52 clipboard operations

module Tea
  # ClipboardMsg is emitted when the terminal receives an OSC52 clipboard read
  struct ClipboardMsg
    include Msg
    property content : String
    property selection : UInt8

    def initialize(@content : String, @selection : UInt8 = 'c'.ord.to_u8)
    end

    # Returns the clipboard selection type:
    # - 'c': System clipboard
    # - 'p': Primary clipboard (X11/Wayland only)
    def clipboard : UInt8
      @selection
    end

    def to_s : String
      @content
    end

    # Go parity helper for ClipboardMsg.String().
    def string : String
      to_s
    end
  end

  # SetClipboard produces a command that sets the system clipboard using OSC52
  # Note: OSC52 is not supported in all terminals
  # ameba:disable Naming/AccessorMethodName
  def self.set_clipboard(content : String) : Cmd
    -> : Msg? { SetClipboardMsg.new(content) }
  end

  # SetClipboardMsg is an internal message for setting clipboard
  struct SetClipboardMsg
    include Msg
    property content : String

    def initialize(@content : String)
    end
  end

  # ReadClipboard produces a command that reads the system clipboard using OSC52
  def self.read_clipboard : Cmd
    -> : Msg? { ReadClipboardMsg.new }
  end

  # ReadClipboardMsg is an internal message for reading clipboard
  struct ReadClipboardMsg
    include Msg
  end

  # SetPrimaryClipboard produces a command that sets the primary clipboard (X11/Wayland)
  # ameba:disable Naming/AccessorMethodName
  def self.set_primary_clipboard(content : String) : Cmd
    -> : Msg? { SetPrimaryClipboardMsg.new(content) }
  end

  # SetPrimaryClipboardMsg is an internal message for setting primary clipboard
  struct SetPrimaryClipboardMsg
    include Msg
    property content : String

    def initialize(@content : String)
    end
  end

  # ReadPrimaryClipboard produces a command that reads the primary clipboard (X11/Wayland)
  def self.read_primary_clipboard : Cmd
    -> : Msg? { ReadPrimaryClipboardMsg.new }
  end

  # ReadPrimaryClipboardMsg is an internal message for reading primary clipboard
  struct ReadPrimaryClipboardMsg
    include Msg
  end
end
