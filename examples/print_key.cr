require "../src/bubbletea"

class PrintKeyModel
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyboardEnhancementsMsg
      {self, Bubbletea.printf("Keyboard enhancements: EventTypes: %s\n", msg.supports_event_types?.to_s)}
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit} if msg.keystroke == "ctrl+c"

      format = "(%s) You pressed: %s"
      value = msg.rune ? msg.rune.to_s : msg.keystroke
      {self, Bubbletea.printf(format, msg.class.name, msg.keystroke + (msg.rune ? " (text: #{value})" : ""))}
    when Bubbletea::KeyReleaseMsg
      {self, Bubbletea.printf("(%s) You pressed: %s", msg.class.name, msg.to_s)}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("Press any key to see its details printed to the terminal. Press 'ctrl+c' to quit.")
    v.keyboard_enhancements.report_event_types = true
    v
  end
end

program = Bubbletea::Program.new(PrintKeyModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
end
