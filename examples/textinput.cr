require "../src/bubbletea"

class TextinputModel
  include Bubbletea::Model

  def initialize
    @input = ""
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "enter", "ctrl+c", "esc"
        @quitting = true
        return {self, Bubbletea.quit}
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
      else
        if rune = msg.rune
          @input += rune.to_s
        end
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    str = "What's your favorite Pokemon?\n\n#{@input.empty? ? "Pikachu" : @input}\n\n(esc to quit)"
    str += "\n" if @quitting
    Bubbletea::View.new(str)
  end
end

program = Bubbletea::Program.new(TextinputModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
