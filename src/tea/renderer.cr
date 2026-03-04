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

    # Set terminal width computation strategy
    # ameba:disable Naming/AccessorMethodName
    abstract def set_width_method(method : Ultraviolet::WidthMethod)
    # ameba:enable Naming/AccessorMethodName

    # Notify the renderer of a terminal resize
    abstract def resize(width : Int32, height : Int32)

    # Set the terminal color profile
    # ameba:disable Naming/AccessorMethodName
    abstract def set_color_profile(profile : Ultraviolet::ColorProfile)
    # ameba:enable Naming/AccessorMethodName

    # Clear the screen
    abstract def clear_screen

    # Write a string to the renderer's output
    abstract def write_string(content : String) : Tuple(Int32, Exception?)

    # Handle a mouse event
    abstract def on_mouse(msg : MouseMsg) : Cmd?
  end

  # Note: Println and Printf are defined in exec.cr

  # Encode cursor style into DECSCUSR numeric value.
  # 1: blinking block, 2: steady block, 3: blinking underline,
  # 4: steady underline, 5: blinking bar, 6: steady bar.
  def self.encode_cursor_style(style : CursorStyle, blink : Bool) : Int32
    case style
    when CursorStyle::BlockBlinking
      1
    when CursorStyle::Block
      2
    when CursorStyle::UnderlineBlinking
      3
    when CursorStyle::Underline
      4
    when CursorStyle::BarBlinking
      5
    when CursorStyle::Bar
      6
    else
      # Fallback for future enum values that may still use blink flag semantics.
      base = 1
      blink ? base : base + 1
    end
  end

  # FPS constants for reference
  def self.default_fps : Int32
    DEFAULT_FPS
  end

  def self.max_fps : Int32
    MAX_FPS
  end
end
