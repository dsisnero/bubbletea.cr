# Nil renderer for Tea v2-exp
# Ported from Go nil_renderer.go
# This is a no-op renderer that implements the Renderer interface
# but doesn't render anything to the terminal.

module Tea
  # NilRenderer is a no-op renderer. It implements the Renderer interface but
  # doesn't render anything to the terminal.
  class NilRenderer
    include Renderer

    # Start the renderer - no-op
    # Implements renderer interface
    def start
      # No operation
    end

    # Close the renderer and flush any remaining data - no-op
    # Implements renderer interface
    def close : Exception?
      nil
    end

    # Render a frame to the output - no-op
    # Implements renderer interface
    def render(view : View)
      # No operation
    end

    # Flush the renderer's buffer to the output - no-op
    # Implements renderer interface
    def flush(closing : Bool) : Exception?
      nil
    end

    # Reset the renderer's state to its initial state - no-op
    # Implements renderer interface
    def reset
      # No operation
    end

    # Insert unmanaged lines above the renderer - no-op
    # Implements renderer interface
    def insert_above(content : String) : Exception?
      nil
    end

    # Set whether to use synchronized updates - no-op
    # Implements renderer interface
    def syncd_updates=(enabled : Bool)
      # No operation
    end

    # Set the method for calculating the width of the terminal - no-op
    def set_width_method(method : ANSI::Method)
      # No operation
    end

    # Notify the renderer of a terminal resize - no-op
    # Implements renderer interface
    def resize(width : Int32, height : Int32)
      # No operation
    end

    # Set the color profile - no-op
    # Implements renderer interface
    def set_color_profile(profile : ColorProfile::Profile)
      # No operation
    end

    # Clear the screen - no-op
    # Implements renderer interface
    def clear_screen
      # No operation
    end

    # Write a string to the renderer's output - no-op
    # Implements renderer interface
    def write_string(content : String) : Tuple(Int32, Exception?)
      {0, nil}
    end

    # Handle a mouse event - returns nil
    # Implements renderer interface
    def on_mouse(msg : MouseMsg) : Cmd?
      nil
    end
  end
end
