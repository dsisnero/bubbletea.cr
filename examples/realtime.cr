require "../src/bubbletea"

struct ResponseMsg
  include Tea::Msg
end

class RealtimeModel
  include Bubbletea::Model

  def initialize
    @responses = 0
    @quitting = false
    @spinner = ["-", "\\", "|", "/"]
    @spin_index = 0
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(spinner_tick, wait_for_activity)
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @quitting = true
      {self, Bubbletea.quit}
    when ResponseMsg
      @responses += 1
      {self, wait_for_activity}
    when Bubbletea::Value
      if msg.value == "spin"
        @spin_index = (@spin_index + 1) % @spinner.size
        return {self, spinner_tick}
      end
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    s = "\n #{@spinner[@spin_index]} Events received: #{@responses}\n\n Press any key to exit\n"
    s += "\n" if @quitting
    Bubbletea::View.new(s)
  end

  private def wait_for_activity : Bubbletea::Cmd
    Bubbletea.tick((Random.rand(900) + 100).milliseconds, ->(_t : Time) { ResponseMsg.new.as(Tea::Msg?) })
  end

  private def spinner_tick : Bubbletea::Cmd
    Bubbletea.tick(100.milliseconds, ->(_t : Time) { Bubbletea["spin"].as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(RealtimeModel.new)
_model, err = program.run
if err
  STDERR.puts "could not start program: #{err.message}"
  exit 1
end
