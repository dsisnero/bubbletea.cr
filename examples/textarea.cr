require "../src/bubbletea"

class TextareaModel
  include Bubbletea::Model

  def initialize
    @text = ""
    @focused = true
    @is_dark = true
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(
      Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) }),
      Tea.request_background_color
    )
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::BackgroundColorMsg
      @is_dark = msg.is_dark?
    when Bubbletea::KeyPressMsg
      key = msg.string_with_mods
      case key
      when "esc"
        @focused = false
      when "ctrl+c"
        return {self, Bubbletea.quit}
      when "backspace"
        @text = @text[0...-1] unless @text.empty?
      else
        if !@focused
          @focused = true
        elsif rune = msg.rune
          @text += rune.to_s
        end
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    footer = "\n(ctrl+c to quit)\n"
    body = @text.empty? ? "Once upon a time..." : @text
    prefix = @is_dark ? "[dark]" : "[light]"
    Bubbletea::View.new("Tell me a story. #{prefix}\n\n#{body}\n#{footer}")
  end
end

program = Bubbletea::Program.new(TextareaModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
