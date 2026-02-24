# Mouse handling for Tea v2-exp
# In Go: MouseButton = uv.MouseButton

module Tea
  # MouseButton is an alias for UVMouseButton (from ultraviolet)
  alias MouseButton = UVMouseButton

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
  end

  # MouseReleaseMsg is sent when a mouse button is released
  struct MouseReleaseMsg
    include MouseMsg
    include Msg

    property mouse : Mouse

    def initialize(@mouse : Mouse)
    end
  end

  # MouseWheelMsg is sent for mouse wheel events
  struct MouseWheelMsg
    include MouseMsg
    include Msg

    property mouse : Mouse

    def initialize(@mouse : Mouse)
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
