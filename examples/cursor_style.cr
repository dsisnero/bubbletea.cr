require "../src/bubbletea"

class CursorStyleModel
  include Bubbletea::Model

  def initialize
    @cursor = Bubbletea::Cursor.new
    @blink = true
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "q"
        return {self, Bubbletea.quit}
      when "h", "left"
        @cursor.style = previous_style(@cursor.style)
      when "l", "right"
        @cursor.style = next_style(@cursor.style)
      end
    end

    @blink = !@blink
    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new(
      "Press left/right to change the cursor style, q or ctrl+c to quit." +
      "\n\n" +
      "  <- This is the cursor (a #{describe_cursor})"
    )

    cursor = Bubbletea::Cursor.new(0, 2, true, @blink ? blinking_variant(@cursor.style) : steady_variant(@cursor.style))
    v.cursor = cursor
    v
  end

  private def describe_cursor : String
    adjective = @blink ? "blinking" : "steady"
    noun = case steady_variant(@cursor.style)
           when Tea::CursorBlock
             "block"
           when Tea::CursorUnderline
             "underline"
           else
             "bar"
           end
    "#{adjective} #{noun}"
  end

  private def previous_style(style : Bubbletea::CursorStyle) : Bubbletea::CursorStyle
    case steady_variant(style)
    when Tea::CursorBlock
      Tea::CursorBar
    when Tea::CursorUnderline
      Tea::CursorBlock
    else
      Tea::CursorUnderline
    end
  end

  private def next_style(style : Bubbletea::CursorStyle) : Bubbletea::CursorStyle
    case steady_variant(style)
    when Tea::CursorBlock
      Tea::CursorUnderline
    when Tea::CursorUnderline
      Tea::CursorBar
    else
      Tea::CursorBlock
    end
  end

  private def steady_variant(style : Bubbletea::CursorStyle) : Bubbletea::CursorStyle
    case style
    when Bubbletea::CursorStyle::BlockBlinking
      Bubbletea::CursorStyle::Block
    when Bubbletea::CursorStyle::UnderlineBlinking
      Bubbletea::CursorStyle::Underline
    when Bubbletea::CursorStyle::BarBlinking
      Bubbletea::CursorStyle::Bar
    else
      style
    end
  end

  private def blinking_variant(style : Bubbletea::CursorStyle) : Bubbletea::CursorStyle
    case steady_variant(style)
    when Bubbletea::CursorStyle::Block
      Bubbletea::CursorStyle::BlockBlinking
    when Bubbletea::CursorStyle::Underline
      Bubbletea::CursorStyle::UnderlineBlinking
    else
      Bubbletea::CursorStyle::BarBlinking
    end
  end
end

program = Bubbletea::Program.new(CursorStyleModel.new)
_model, err = program.run
if err
  STDERR.puts "Error: #{err.message}"
  exit 1
end
