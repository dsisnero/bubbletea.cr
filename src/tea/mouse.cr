# Mouse handling for Tea v2-exp
# In Go: MouseButton = uv.MouseButton

module Tea
  # MouseButton is an alias for UVMouseButton (from ultraviolet)
  alias MouseButton = UVMouseButton

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
  MouseNone       = UVMouseButton::None
  MouseLeft       = UVMouseButton::Left
  MouseMiddle     = UVMouseButton::Middle
  MouseRight      = UVMouseButton::Right
  MouseWheelUp    = UVMouseButton::WheelUp
  MouseWheelDown  = UVMouseButton::WheelDown
  MouseWheelLeft  = UVMouseButton::WheelLeft
  MouseWheelRight = UVMouseButton::WheelRight
  MouseBackward   = UVMouseButton::Backward
  MouseForward    = UVMouseButton::Forward
  MouseButton10   = UVMouseButton::Button10
  MouseButton11   = UVMouseButton::Button11

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
      @button : MouseButton = UVMouseButton::None,
      @modifiers : KeyMod = UVKeyMod::None,
    )
    end

    def position
      {@x, @y}
    end

    def shift?
      @modifiers.shift?
    end

    def alt?
      @modifiers.alt?
    end

    def ctrl?
      @modifiers.ctrl?
    end

    def meta?
      @modifiers.meta?
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

    def wheel_up?
      @mouse.button == UVMouseButton::WheelUp
    end

    def wheel_down?
      @mouse.button == UVMouseButton::WheelDown
    end

    def wheel_left?
      @mouse.button == UVMouseButton::WheelLeft
    end

    def wheel_right?
      @mouse.button == UVMouseButton::WheelRight
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
      if @mouse.button != UVMouseButton::None
        io << "+motion"
      else
        io << "motion"
      end
      io << ")"
    end
  end

  # Helper to create a mouse message
  def self.mouse_click(x : Int32, y : Int32, button : MouseButton = UVMouseButton::Left) : MouseClickMsg
    MouseClickMsg.new(Mouse.new(x, y, button))
  end

  def self.mouse_release(x : Int32, y : Int32, button : MouseButton = UVMouseButton::Left) : MouseReleaseMsg
    MouseReleaseMsg.new(Mouse.new(x, y, button))
  end

  def self.mouse_wheel(x : Int32, y : Int32, direction : MouseButton) : MouseWheelMsg
    MouseWheelMsg.new(Mouse.new(x, y, direction))
  end

  def self.mouse_motion(x : Int32, y : Int32) : MouseMotionMsg
    MouseMotionMsg.new(Mouse.new(x, y, UVMouseButton::None))
  end
end
