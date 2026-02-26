require "../src/bubbletea"

enum SessionState
  TimerView
  SpinnerView
end

DEFAULT_SECONDS = 60

struct TimerTickMsg
  include Tea::Msg
end

struct SpinnerTickMsg
  include Tea::Msg
end

private def timer_tick : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { TimerTickMsg.new.as(Tea::Msg?) })
end

private def spinner_tick : Bubbletea::Cmd
  Bubbletea.tick(100.milliseconds, ->(_t : Time) { SpinnerTickMsg.new.as(Tea::Msg?) })
end

class MainModel
  include Bubbletea::Model

  SPINNERS = ["-", "\\", "|", "/"]

  def initialize
    @state = SessionState::TimerView
    @seconds_left = DEFAULT_SECONDS
    @spinner_index = 0
    @spinner_style_index = 0
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(timer_tick, spinner_tick)
  end

  def update(msg : Tea::Msg)
    cmd = nil.as(Bubbletea::Cmd?)

    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q"
        return {self, Bubbletea.quit}
      when "tab"
        @state = @state.timer_view? ? SessionState::SpinnerView : SessionState::TimerView
      when "n"
        if @state.timer_view?
          @seconds_left = DEFAULT_SECONDS
          cmd = timer_tick
        else
          next_spinner
          @spinner_index = 0
          cmd = spinner_tick
        end
      end
    when TimerTickMsg
      @seconds_left -= 1 if @seconds_left > 0
      cmd = timer_tick
    when SpinnerTickMsg
      @spinner_index = (@spinner_index + 1) % SPINNERS.size
      cmd = spinner_tick
    end

    {self, cmd}
  end

  def view : Bubbletea::View
    timer_label = format_time(@seconds_left)
    spinner_label = SPINNERS[@spinner_index]

    timer_box = box(timer_label, @state.timer_view?)
    spinner_box = box(spinner_label, @state.spinner_view?)

    focused = @state.timer_view? ? "timer" : "spinner"
    help = "tab: focus next • n: new #{focused} • q: exit"

    Bubbletea::View.new("#{timer_box}    #{spinner_box}\n#{help}")
  end

  def next_spinner
    @spinner_style_index = (@spinner_style_index + 1) % 9
  end

  private def format_time(seconds : Int32) : String
    m = seconds // 60
    s = seconds % 60
    "%02d:%02d" % {m, s}
  end

  private def box(content : String, focused : Bool) : String
    border = focused ? "#" : "-"
    top = border * 11
    mid = "#{border} #{content.center(7)} #{border}"
    [top, mid, top].join("\n")
  end
end

program = Bubbletea::Program.new(MainModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
