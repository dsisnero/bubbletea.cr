require "../src/bubbletea"

class ProgressBarModel
  include Bubbletea::Model

  def initialize
    @value = 50
    @width = 80
    @state = Tea::ProgressBarState::Indeterminate
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c"
        return {self, Bubbletea.quit}
      when "up", "k"
        @value += 10 if @value < 100
      when "down", "j"
        @value -= 10 if @value > 0
      when "left", "h"
        @state = Tea::ProgressBarState.from_value?(@state.value - 1) || @state
      when "right", "l"
        @state = Tea::ProgressBarState.from_value?(@state.value + 1) || @state
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    text = "This demo requires terminal progress bar support. Press up/down to change value, left/right to change state, q to quit."
    v = Bubbletea::View.new(text)
    v.progress_bar = Tea::ProgressBar.new(@state, @value.to_f, 100.0)
    v
  end
end

program = Bubbletea::Program.new(ProgressBarModel.new)
_model, err = program.run
if err
  STDERR.puts "Error: #{err.message}"
  exit 1
end
