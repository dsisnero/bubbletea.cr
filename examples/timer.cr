require "../src/bubbletea"

struct TimerTickMsg
  include Tea::Msg
end

class TimerModel
  include Bubbletea::Model

  TIMEOUT_MS = 5000

  def initialize
    @remaining_ms = TIMEOUT_MS
    @running = true
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    timer_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when TimerTickMsg
      if @running
        @remaining_ms -= 1
        if @remaining_ms <= 0
          @quitting = true
          return {self, Bubbletea.quit}
        end
        return {self, timer_tick}
      end
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c"
        @quitting = true
        return {self, Bubbletea.quit}
      when "r"
        @remaining_ms = TIMEOUT_MS
      when "s"
        @running = !@running
        return {self, @running ? timer_tick : nil}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    if @remaining_ms <= 0
      return Bubbletea::View.new("All done!\n")
    end

    sec = @remaining_ms / 1000.0
    status = @running ? "running" : "stopped"
    text_output = "Exiting in %.3fs (#{status})\n" % sec
    unless @quitting
      text_output += "\n"
      text_output += "s: start/stop • r: reset • q: quit\n"
    end
    Bubbletea::View.new(text_output)
  end

  private def timer_tick : Bubbletea::Cmd
    Bubbletea.tick(1.millisecond, ->(_t : Time) { TimerTickMsg.new.as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(TimerModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
