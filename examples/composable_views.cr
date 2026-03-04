require "../lib/bubbles/src/bubbles"

enum SessionState
  TimerView
  SpinnerView
end

DEFAULT_TIME = 1.minute

SPINNERS = [
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

MODEL_STYLE = Lipgloss::Style.new
  .width(15)
  .height(5)
  .align(Lipgloss::Position::Center, Lipgloss::Position::Center)
  .border_style(Lipgloss::Border.hidden)

FOCUSED_MODEL_STYLE = Lipgloss::Style.new
  .width(15)
  .height(5)
  .align(Lipgloss::Position::Center, Lipgloss::Position::Center)
  .border_style(Lipgloss::Border.normal)
  .border_foreground(Lipgloss.color("69"))

SPINNER_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("69"))
HELP_STYLE    = Lipgloss::Style.new.foreground(Lipgloss.color("241"))

class MainModel
  include Bubbletea::Model

  @state : SessionState
  @timer : Bubbles::Timer::Model
  @spinner : Bubbles::Spinner::Model
  @index : Int32

  def initialize(timeout : Time::Span)
    @state = SessionState::TimerView
    @timer = Bubbles::Timer.new(timeout)
    @spinner = Bubbles::Spinner.new
    @index = 0
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(@timer.init, -> { @spinner.tick.as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    cmds = [] of Tea::Cmd?

    case msg
    when Tea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "q"
        return {self, Tea.quit}
      when "tab"
        @state = @state.timer_view? ? SessionState::SpinnerView : SessionState::TimerView
      when "n"
        if @state.timer_view?
          @timer = Bubbles::Timer.new(DEFAULT_TIME)
          cmds << @timer.init
        else
          next_spinner
          reset_spinner
          cmds << -> { @spinner.tick.as(Tea::Msg?) }
        end
      end

      case @state
      when .spinner_view?
        @spinner, cmd = @spinner.update(msg)
        cmds << cmd
      else
        @timer, cmd = @timer.update(msg)
        cmds << cmd
      end
    when Bubbles::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      cmds << cmd
    when Bubbles::Timer::TickMsg
      @timer, cmd = @timer.update(msg)
      cmds << cmd
    end

    {self, Tea.batch(cmds)}
  end

  def view : Bubbletea::View
    timer_view = "%4s" % @timer.view
    spinner_view = @spinner.view

    content = if @state.timer_view?
                Lipgloss.join_horizontal(
                  Lipgloss::Position::Top,
                  FOCUSED_MODEL_STYLE.render(timer_view),
                  MODEL_STYLE.render(spinner_view)
                )
              else
                Lipgloss.join_horizontal(
                  Lipgloss::Position::Top,
                  MODEL_STYLE.render(timer_view),
                  FOCUSED_MODEL_STYLE.render(spinner_view)
                )
              end

    help = HELP_STYLE.render("\ntab: focus next • n: new #{current_focused_model} • q: exit\n")
    Bubbletea::View.new(content + help)
  end

  def current_focused_model : String
    @state.timer_view? ? "timer" : "spinner"
  end

  def next_spinner
    if @index == SPINNERS.size - 1
      @index = 0
    else
      @index += 1
    end
  end

  def reset_spinner
    @spinner = Bubbles::Spinner.new
    @spinner.style = SPINNER_STYLE
    @spinner.spinner = SPINNERS[@index]
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end

  program = Bubbletea::Program.new(MainModel.new(DEFAULT_TIME))
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
