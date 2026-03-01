require "../src/bubbletea"

class TextinputsModel
  include Bubbletea::Model

  def initialize
    @focus_index = 0
    @inputs = ["", "", ""]
    @labels = ["Nickname", "Email", "Password"]
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      key = msg.keystroke
      case key
      when "ctrl+c", "esc"
        @quitting = true
        return {self, Bubbletea.quit}
      when "tab", "down", "enter"
        if @focus_index == @inputs.size
          return {self, Bubbletea.quit}
        end
        @focus_index = {@focus_index + 1, @inputs.size}.min
      when "shift+tab", "up"
        @focus_index = {@focus_index - 1, 0}.max
      when "backspace"
        if @focus_index < @inputs.size
          current = @inputs[@focus_index]
          @inputs[@focus_index] = current[0...-1] unless current.empty?
        end
      else
        if @focus_index < @inputs.size
          if rune = msg.rune
            @inputs[@focus_index] += rune.to_s
          end
        end
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    text_output = String.build do |io|
      @labels.each_with_index do |label, i|
        marker = i == @focus_index ? ">" : " "
        value = @inputs[i]
        value = "*" * value.size if i == 2
        io << marker << " " << label << ": " << value << "\n"
      end

      submit_marker = @focus_index == @inputs.size ? ">" : " "
      io << "\n" << submit_marker << " [ Submit ]\n\n"
      io << "tab/down: next • shift+tab/up: prev • enter: select"
      io << "\n" if @quitting
    end
    Bubbletea::View.new(text_output)
  end
end

program = Bubbletea::Program.new(TextinputsModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
