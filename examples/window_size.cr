require "../src/bubbletea"

class WindowSizeModel
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      else
        return {self, Bubbletea.window_size}
      end
    when Bubbletea::WindowSizeMsg
      return {self, Bubbletea.printf("The window size is: %dx%d", msg.width, msg.height)}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new("\nWhen you're done press q to quit.\nPress any other key to query the window-size.\n")
  end
end

program = Bubbletea::Program.new(WindowSizeModel.new)
_model, err = program.run
if err
  STDERR.puts "Error: #{err.message}"
  exit 1
end
