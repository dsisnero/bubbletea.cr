require "../src/bubbletea"

struct CountdownTickMsg
  include Tea::Msg
end

private def fullscreen_tick : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { CountdownTickMsg.new.as(Tea::Msg?) })
end

class FullscreenModel
  include Bubbletea::Model

  def initialize(@remaining = 5)
  end

  def init : Bubbletea::Cmd?
    fullscreen_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit} if msg.keystroke.in?({"q", "esc", "ctrl+c"})
    when CountdownTickMsg
      @remaining -= 1
      return {self, Bubbletea.quit} if @remaining <= 0
      return {self, fullscreen_tick}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("\n\n     Hi. This program will exit in #{@remaining} seconds...")
    v.alt_screen = true
    v
  end
end

program = Bubbletea::Program.new(FullscreenModel.new(5))
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
