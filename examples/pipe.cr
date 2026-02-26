require "../src/bubbletea"

class PipeModel
  include Bubbletea::Model

  def initialize(initial_value : String)
    @user_input = initial_value
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    if msg.is_a?(Bubbletea::KeyPressMsg)
      case msg.string_with_mods
      when "ctrl+c", "esc", "enter"
        return {self, Bubbletea.quit}
      when "backspace"
        @user_input = @user_input[0...-1] unless @user_input.empty?
      when "space"
        @user_input += " "
      else
        if rune = msg.rune
          @user_input += rune.to_s
        end
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new("\nYou piped in: #{@user_input}\n\nPress ^C to exit")
  end
end

input = STDIN.gets_to_end.strip
if input.empty?
  puts "Try piping in some text."
  exit 1
end

program = Bubbletea::Program.new(PipeModel.new(input))
_model, err = program.run
if err
  STDERR.puts "Couldn't start program: #{err.message}"
  exit 1
end
