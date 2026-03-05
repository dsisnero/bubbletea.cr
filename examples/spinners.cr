require "../lib/bubbles/src/bubbles"
require "lipgloss"

SPINNERS_LIST = [
  Bubbles::Spinner::Line,
  Bubbles::Spinner::Dot,
  Bubbles::Spinner::MiniDot,
  Bubbles::Spinner::Jump,
  Bubbles::Spinner::Pulse,
  Bubbles::Spinner::Points,
  Bubbles::Spinner::Globe,
  Bubbles::Spinner::Moon,
  Bubbles::Spinner::Monkey,
]

SPINNERS_TEXT_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("252"))
SPINNERS_SPINNER_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("69"))
SPINNERS_HELP_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("241"))

class SpinnersModel
  include Bubbletea::Model

  def initialize
    @index = 0
    @spinner = Bubbles::Spinner.new
    reset_spinner
  end

  def init : Bubbletea::Cmd?
    -> { @spinner.tick.as(Tea::Msg?) }
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      when "h", "left"
        @index -= 1
        @index = SPINNERS_LIST.size - 1 if @index < 0
        reset_spinner
        return {self, -> { @spinner.tick.as(Tea::Msg?) }}
      when "l", "right"
        @index += 1
        @index = 0 if @index >= SPINNERS_LIST.size
        reset_spinner
        return {self, -> { @spinner.tick.as(Tea::Msg?) }}
      else
        return {self, nil}
      end
    when Bubbles::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    else
      return {self, nil}
    end
  end

  def view : Bubbletea::View
    gap = @index == 1 ? "" : " "
    s = "\n #{@spinner.view}#{gap}#{SPINNERS_TEXT_STYLE.render("Spinning...")}\n\n"
    s += SPINNERS_HELP_STYLE.render("h/l, ←/→: change spinner • q: exit\n")
    Bubbletea::View.new(s)
  end

  def parity_tick_msg : Tea::Msg
    @spinner.tick
  end

  private def reset_spinner
    @spinner = Bubbles::Spinner.new
    @spinner.style = SPINNERS_SPINNER_STYLE
    @spinner.spinner = SPINNERS_LIST[@index]
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(SpinnersModel.new)
  _model, err = program.run
  if err
    STDERR.puts "could not run program: #{err.message}"
    exit 1
  end
end
