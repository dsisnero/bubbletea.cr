require "../src/bubbletea"

struct StopwatchTickMsg
  include Tea::Msg
end

private def stopwatch_tick : Bubbletea::Cmd
  Bubbletea.tick(1.millisecond, ->(_t : Time) { StopwatchTickMsg.new.as(Tea::Msg?) })
end

class StopwatchModel
  include Bubbletea::Model

  def initialize
    @elapsed_ms = 0
    @running = false
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    @running ? stopwatch_tick : nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      key = msg.keystroke
      case key
      when "ctrl+c", "q"
        @quitting = true
        return {self, Bubbletea.quit}
      when "r"
        @elapsed_ms = 0
        return {self, nil}
      when "s"
        @running = !@running
        return {self, @running ? stopwatch_tick : nil}
      end
    when StopwatchTickMsg
      if @running
        @elapsed_ms += 1
        return {self, stopwatch_tick}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    s = format_elapsed
    unless @quitting
      s = "Elapsed: #{s}\n\n" +
          "s: #{@running ? "stop" : "start"} • r: reset • q: quit"
    end
    Bubbletea::View.new(s)
  end

  private def format_elapsed : String
    total = @elapsed_ms
    minutes = total // 60000
    seconds = (total % 60000) // 1000
    millis = total % 1000
    "%02d:%02d.%03d" % {minutes, seconds, millis}
  end
end

program = Bubbletea::Program.new(StopwatchModel.new)
_model, err = program.run
if err
  STDERR.puts "Oh no, it didn't work: #{err.message}"
  exit 1
end
