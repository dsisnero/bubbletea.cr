# Mouse handling for Tea v2-exp
# In Go: MouseButton = uv.MouseButton

module Tea
  # MouseButton is an alias for Ultraviolet::MouseButton (from ultraviolet)
  alias MouseButton = Ultraviolet::MouseButton

  # Mouse button constants (aliases to UV constants)
  # Based on X11 mouse button codes:
  #   1 = left button
  #   2 = middle button (pressing the scroll wheel)
  #   3 = right button
  #   4 = turn scroll wheel up
  #   5 = turn scroll wheel down
  #   6 = push scroll wheel left
  #   7 = push scroll wheel right
  #   8 = 4th button (aka browser backward button)
  #   9 = 5th button (aka browser forward button)
  #   10, 11 = additional buttons
  MouseNone       = Ultraviolet::MouseButton::None
  MouseLeft       = Ultraviolet::MouseButton::Left
  MouseMiddle     = Ultraviolet::MouseButton::Middle
  MouseRight      = Ultraviolet::MouseButton::Right
  MouseWheelUp    = Ultraviolet::MouseButton::WheelUp
  MouseWheelDown  = Ultraviolet::MouseButton::WheelDown
  MouseWheelLeft  = Ultraviolet::MouseButton::WheelLeft
  MouseWheelRight = Ultraviolet::MouseButton::WheelRight
  MouseBackward   = Ultraviolet::MouseButton::Backward
  MouseForward    = Ultraviolet::MouseButton::Forward
  MouseButton10   = Ultraviolet::MouseButton::Button10
  MouseButton11   = Ultraviolet::MouseButton::Button11

  # Mouse represents mouse event data
  struct Mouse
    # X position (column)
    property x : Int32

    # Y position (row)
    property y : Int32

    # Button that triggered the event
    property button : MouseButton

    # Modifier keys pressed
    property modifiers : KeyMod

    def initialize(
      @x : Int32,
      @y : Int32,
      @button : MouseButton = Ultraviolet::MouseButton::None,
      @modifiers : KeyMod = 0,
    )
    end

    def position
      {@x, @y}
    end

    def shift?
      KeyModHelpers.shift?(@modifiers)
    end

    def alt?
      KeyModHelpers.alt?(@modifiers)
    end

    def ctrl?
      KeyModHelpers.ctrl?(@modifiers)
    end

    def meta?
      KeyModHelpers.meta?(@modifiers)
    end

    # Returns a string representation of the mouse event
    def to_s(io : IO)
      io << "Mouse(x=#{@x}, y=#{@y}, button=#{@button}"
      io << ", shift" if shift?
      io << ", alt" if alt?
      io << ", ctrl" if ctrl?
      io << ", meta" if meta?
      io << ")"
    end

    # Go parity helper for Mouse.String().
    def string : String
      String.build { |io| to_s(io) }
    end
  end

  # MouseMsg is the interface for all mouse messages
  module MouseMsg
    include Msg

    abstract def mouse : Mouse
  end

  # MouseClickMsg is sent when a mouse button is pressed
  struct MouseClickMsg
    include MouseMsg
    include Msg

    property mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    # Returns the underlying mouse event
    def mouse : Mouse
      @mouse
    end

    # Returns a string representation
    def to_s(io : IO)
      io << "MouseClick("
      @mouse.to_s(io)
      io << ")"
    end

    # Go parity helper for MouseClickMsg.String().
    def string : String
      mouse.string
    end
  end

  # MouseReleaseMsg is sent when a mouse button is released
  struct MouseReleaseMsg
    include MouseMsg
    include Msg

    property mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    # Returns the underlying mouse event
    def mouse : Mouse
      @mouse
    end

    # Returns a string representation
    def to_s(io : IO)
      io << "MouseRelease("
      @mouse.to_s(io)
      io << ")"
    end

    # Go parity helper for MouseReleaseMsg.String().
    def string : String
      mouse.string
    end
  end

  # MouseWheelMsg is sent for mouse wheel events
  struct MouseWheelMsg
    include MouseMsg
    include Msg

    property mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    # Returns the underlying mouse event
    def mouse : Mouse
      @mouse
    end

    # Returns a string representation
    def to_s(io : IO)
      io << "MouseWheel("
      @mouse.to_s(io)
      io << ")"
    end

    # Go parity helper for MouseWheelMsg.String().
    def string : String
      mouse.string
    end

    def wheel_up?
      @mouse.button == Ultraviolet::MouseButton::WheelUp
    end

    def wheel_down?
      @mouse.button == Ultraviolet::MouseButton::WheelDown
    end

    def wheel_left?
      @mouse.button == Ultraviolet::MouseButton::WheelLeft
    end

    def wheel_right?
      @mouse.button == Ultraviolet::MouseButton::WheelRight
    end
  end

  # MouseMotionMsg is sent when the mouse moves
  struct MouseMotionMsg
    include MouseMsg
    include Msg

    property mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    # Returns the underlying mouse event
    def mouse : Mouse
      @mouse
    end

    # Returns a string representation
    # In Go: if m.Button != 0 { return m.String() + "+motion" }
    #        return m.String() + "motion"
    def to_s(io : IO)
      io << "MouseMotion("
      @mouse.to_s(io)
      if @mouse.button != Ultraviolet::MouseButton::None
        io << "+motion"
      else
        io << "motion"
      end
      io << ")"
    end

    # Go parity helper for MouseMotionMsg.String().
    def string : String
      base = mouse.string
      mouse.button == Ultraviolet::MouseButton::None ? "#{base}motion" : "#{base}+motion"
    end
  end

  # Helper to create a mouse message
  def self.mouse_click(x : Int32, y : Int32, button : MouseButton = Ultraviolet::MouseButton::Left) : MouseClickMsg
    MouseClickMsg.new(Mouse.new(x, y, button))
  end

  def self.mouse_release(x : Int32, y : Int32, button : MouseButton = Ultraviolet::MouseButton::Left) : MouseReleaseMsg
    MouseReleaseMsg.new(Mouse.new(x, y, button))
  end

  def self.mouse_wheel(x : Int32, y : Int32, direction : MouseButton) : MouseWheelMsg
    MouseWheelMsg.new(Mouse.new(x, y, direction))
  end

  def self.mouse_motion(x : Int32, y : Int32) : MouseMotionMsg
    MouseMotionMsg.new(Mouse.new(x, y, Ultraviolet::MouseButton::None))
  end
end
