require "../src/bubbletea"

class SpinnerModel
  include Bubbletea::Model

  def initialize
    @frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    @index = 0
    @quitting = false
    @err = nil.as(String?)
  end

  def init : Bubbletea::Cmd?
    tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "esc", "ctrl+c"
        @quitting = true
        return {self, Bubbletea.quit}
      else
        return {self, nil}
      end
    when Bubbletea::Value
      if msg.value == "tick"
        @index = (@index + 1) % @frames.size
        return {self, tick}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    return Bubbletea::View.new(@err.not_nil!) if @err

    str = "\n\n   #{@frames[@index]} Loading forever...press q to quit\n\n"
    str += "\n" if @quitting
    Bubbletea::View.new(str)
  end

  private def tick : Bubbletea::Cmd
    Bubbletea.tick(100.milliseconds, ->(_t : Time) { Bubbletea["tick"].as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(SpinnerModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
