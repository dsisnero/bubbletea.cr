require "../src/bubbletea"

class MouseModel
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      if msg.keystroke.in?({"ctrl+c", "q", "esc"})
        return {self, Bubbletea.quit}
      end
    when Bubbletea::MouseClickMsg, Bubbletea::MouseReleaseMsg, Bubbletea::MouseWheelMsg, Bubbletea::MouseMotionMsg
      mouse = msg.mouse
      return {self, Bubbletea.printf("(X: %d, Y: %d) %s", mouse.x, mouse.y, msg.to_s)}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("Do mouse stuff. When you're done press q to quit.\n")
    v.mouse_mode = Bubbletea::MouseMode::AllMotion
    v
  end
end

program = Bubbletea::Program.new(MouseModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
