require "../src/bubbletea"
require "bubbles"
require "lipgloss"

class SpinnerErrMsg
  include Tea::Msg

  getter err : String

  def initialize(@err : String)
  end
end

class SpinnerModel
  include Bubbletea::Model

  def initialize
    @spinner = Bubbles::Spinner.new
    @spinner.spinner = Bubbles::Spinner::Dot
    @spinner.style = Lipgloss.new_style.foreground(Lipgloss.color("205"))
    @quitting = false
    @err = nil.as(String?)
  end

  def init : Bubbletea::Cmd?
    -> { @spinner.tick.as(Tea::Msg?) }
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
    when SpinnerErrMsg
      @err = msg.err
      return {self, nil}
    else
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    end
  end

  def view : Bubbletea::View
    return Bubbletea::View.new(@err.not_nil!) if @err

    str = "\n\n   #{@spinner.view} Loading forever...press q to quit\n\n"
    if @quitting
      Bubbletea::View.new("#{str}\n")
    else
      Bubbletea::View.new(str)
    end
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(SpinnerModel.new)
  _model, err = program.run
  if err
    STDERR.puts err.message
    exit 1
  end
end
