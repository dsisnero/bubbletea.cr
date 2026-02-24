# Renderer interface for Tea v2-exp
# Ported from Go renderer.go

module Tea
  # Default and max framerate constants
  DEFAULT_FPS =  60
  MAX_FPS     = 120

  # Renderer is the interface for Bubble Tea renderers
  # Implementations: StandardRenderer (cursed_renderer.go), NilRenderer (nil_renderer.go)
  module Renderer
    # Start the renderer
    abstract def start

    # Close the renderer and flush any remaining data
    abstract def close : Exception?

    # Render a frame to the output
    abstract def render(view : View)

    # Flush the renderer's buffer to the output
    abstract def flush(closing : Bool) : Exception?

    # Reset the renderer's state to its initial state
    abstract def reset

    # Insert unmanaged lines above the renderer
    abstract def insert_above(content : String) : Exception?

    # Set whether to use synchronized updates
    abstract def syncd_updates=(enabled : Bool)

    # Notify the renderer of a terminal resize
    abstract def resize(width : Int32, height : Int32)

    # Clear the screen
    abstract def clear_screen

    # Write a string to the renderer's output
    abstract def write_string(content : String) : Tuple(Int32, Exception?)

    # Handle a mouse event
    abstract def on_mouse(msg : MouseMsg) : Cmd?
  end

  # Note: Println and Printf are defined in exec.cr

  # EncodeCursorStyle returns the ANSI escape sequence value for the given cursor style and blink state
  # Maps CursorShape to ANSI values:
  #   Block = 1, BlockBlinking = 2
  #   Underline = 3, UnderlineBlinking = 4
  #   Bar = 5, BarBlinking = 6
  def self.encode_cursor_style(style : CursorStyle, blink : Bool) : Int32
    # Calculate base value: (style * 2) + 1
    # This gives: Block=1, Underline=3, Bar=5
    base = (style.value * 2) + 1

    # If not blinking (steady), increment by 1
    # This gives: Block=2, Underline=4, Bar=6
    blink ? base : base + 1
  end

  # FPS constants for reference
  def self.default_fps : Int32
    DEFAULT_FPS
  end

  def self.max_fps : Int32
    MAX_FPS
  end
end
