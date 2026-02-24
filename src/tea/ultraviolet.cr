# Ultraviolet compatibility layer for Tea v2-exp
# This provides the core types and interfaces from Go's ultraviolet library
# adapted for Crystal.

module Tea
  # Event is the base type for all messages in v2-exp
  # In Go: type Event interface { ... }
  # In Crystal: Event is just an alias for Msg, defined in tea.cr
  # This is declared here for documentation purposes
  # alias Event = Msg  # Defined in tea.cr after Msg is defined

  # KeyMod represents modifier keys
  @[Flags]
  enum UVKeyMod
    None       =   0
    Shift      =   1
    Alt        =   2
    Ctrl       =   4
    Meta       =   8
    Hyper      =  16
    Super      =  32
    CapsLock   =  64
    NumLock    = 128
    ScrollLock = 256
  end

  # MouseButton represents mouse buttons
  enum UVMouseButton
    None       =  0
    Left       =  1
    Middle     =  2
    Right      =  3
    WheelUp    =  4
    WheelDown  =  5
    WheelLeft  =  6
    WheelRight =  7
    Backward   =  8
    Forward    =  9
    Button10   = 10
    Button11   = 11
  end

  # Key constants for special keys
  module UVKeys
    # Extended keys
    KeyExtended = 0x10000

    # Navigation keys
    KeyUp     = KeyExtended + 1
    KeyDown   = KeyExtended + 2
    KeyRight  = KeyExtended + 3
    KeyLeft   = KeyExtended + 4
    KeyBegin  = KeyExtended + 5
    KeyFind   = KeyExtended + 6
    KeyInsert = KeyExtended + 7
    KeyDelete = KeyExtended + 8
    KeySelect = KeyExtended + 9
    KeyPgUp   = KeyExtended + 10
    KeyPgDown = KeyExtended + 11
    KeyHome   = KeyExtended + 12
    KeyEnd    = KeyExtended + 13

    # Keypad keys
    KeyKpEnter    = KeyExtended + 14
    KeyKpEqual    = KeyExtended + 15
    KeyKpMultiply = KeyExtended + 16
    KeyKpPlus     = KeyExtended + 17
    KeyKpComma    = KeyExtended + 18
    KeyKpMinus    = KeyExtended + 19
    KeyKpDecimal  = KeyExtended + 20
    KeyKpDivide   = KeyExtended + 21
    KeyKp0        = KeyExtended + 22
    KeyKp1        = KeyExtended + 23
    KeyKp2        = KeyExtended + 24
    KeyKp3        = KeyExtended + 25
    KeyKp4        = KeyExtended + 26
    KeyKp5        = KeyExtended + 27
    KeyKp6        = KeyExtended + 28
    KeyKp7        = KeyExtended + 29
    KeyKp8        = KeyExtended + 30
    KeyKp9        = KeyExtended + 31
    KeyKpSep      = KeyExtended + 32
    KeyKpUp       = KeyExtended + 33
    KeyKpDown     = KeyExtended + 34
    KeyKpLeft     = KeyExtended + 35
    KeyKpRight    = KeyExtended + 36
    KeyKpPgUp     = KeyExtended + 37
    KeyKpPgDown   = KeyExtended + 38
    KeyKpHome     = KeyExtended + 39
    KeyKpEnd      = KeyExtended + 40
    KeyKpInsert   = KeyExtended + 41
    KeyKpDelete   = KeyExtended + 42
    KeyKpBegin    = KeyExtended + 43

    # Function keys
    KeyF1  = KeyExtended + 44
    KeyF2  = KeyExtended + 45
    KeyF3  = KeyExtended + 46
    KeyF4  = KeyExtended + 47
    KeyF5  = KeyExtended + 48
    KeyF6  = KeyExtended + 49
    KeyF7  = KeyExtended + 50
    KeyF8  = KeyExtended + 51
    KeyF9  = KeyExtended + 52
    KeyF10 = KeyExtended + 53
    KeyF11 = KeyExtended + 54
    KeyF12 = KeyExtended + 55
    KeyF13 = KeyExtended + 56
    KeyF14 = KeyExtended + 57
    KeyF15 = KeyExtended + 58
    KeyF16 = KeyExtended + 59
    KeyF17 = KeyExtended + 60
    KeyF18 = KeyExtended + 61
    KeyF19 = KeyExtended + 62
    KeyF20 = KeyExtended + 63
    KeyF21 = KeyExtended + 64
    KeyF22 = KeyExtended + 65
    KeyF23 = KeyExtended + 66
    KeyF24 = KeyExtended + 67
    KeyF25 = KeyExtended + 68
    KeyF26 = KeyExtended + 69
    KeyF27 = KeyExtended + 70
    KeyF28 = KeyExtended + 71
    KeyF29 = KeyExtended + 72
    KeyF30 = KeyExtended + 73
    KeyF31 = KeyExtended + 74
    KeyF32 = KeyExtended + 75
    KeyF33 = KeyExtended + 76
    KeyF34 = KeyExtended + 77
    KeyF35 = KeyExtended + 78
  end

  # Environ represents environment variables
  struct UVEnviron
    property vars : Hash(String, String)

    def initialize(@vars = {} of String => String)
    end

    def [](key : String)
      @vars[key]?
    end

    def []=(key : String, value : String)
      @vars[key] = value
    end

    def get(key : String, default = "")
      @vars[key]? || default
    end
  end

  # Logger interface for debugging
  module UVLogger
    abstract def debug(msg : String)
    abstract def info(msg : String)
    abstract def warn(msg : String)
    abstract def error(msg : String)
  end

  # ConsoleLogger is a simple logger implementation
  class ConsoleLogger
    include UVLogger

    def debug(msg : String)
      STDERR.puts "[DEBUG] #{msg}"
    end

    def info(msg : String)
      STDERR.puts "[INFO] #{msg}"
    end

    def warn(msg : String)
      STDERR.puts "[WARN] #{msg}"
    end

    def error(msg : String)
      STDERR.puts "[ERROR] #{msg}"
    end
  end

  # TerminalReader reads input from a terminal
  class TerminalReader
    @input : IO
    @buffer = Bytes.new(4096)
    @closed = false

    def initialize(@input : IO)
    end

    def read
      return if @closed

      begin
        bytes_read = @input.read(@buffer)
        return if bytes_read == 0

        @buffer[0, bytes_read]
      rescue IO::Error
        nil
      end
    end

    def close
      @closed = true
    end
  end

  # CancelReader wraps a reader with cancellation support
  class CancelReader
    @input : IO
    @cancelled = false
    @mutex = Mutex.new

    def initialize(@input : IO)
    end

    def self.new(input : IO) : CancelReader
      instance = allocate
      instance.initialize(input)
      instance
    end

    def read
      @mutex.synchronize do
        return if @cancelled
      end

      buffer = Bytes.new(4096)
      begin
        bytes_read = @input.read(buffer)
        return if bytes_read == 0
        buffer[0, bytes_read]
      rescue IO::Error
        nil
      end
    end

    def cancel
      @mutex.synchronize do
        @cancelled = true
      end
    end
  end

  # TTY operations
  module TTY
    # OpenTTY opens the TTY for input/output
    def self.open
      {STDIN, STDOUT}
    end
  end
end
