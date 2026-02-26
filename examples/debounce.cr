require "../src/bubbletea"

DEBOUNCE_DURATION = 1.second

struct ExitMsg
  include Tea::Msg
  getter tag : Int32

  def initialize(@tag : Int32)
  end
end

class DebounceModel
  include Bubbletea::Model

  def initialize
    @tag = 0
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @tag += 1
      current_tag = @tag
      cmd = Bubbletea.tick(DEBOUNCE_DURATION, ->(_time : Time) { ExitMsg.new(current_tag).as(Tea::Msg?) })
      {self, cmd}
    when ExitMsg
      return {self, Bubbletea.quit} if msg.tag == @tag
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    Bubbletea::View.new(
      "Key presses: #{@tag}\n" +
      "To exit press any key, then wait for one second without pressing anything."
    )
  end
end

program = Bubbletea::Program.new(DebounceModel.new)
_model, err = program.run
if err
  STDERR.puts "uh oh: #{err.message}"
  exit 1
end
