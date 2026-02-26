require "../src/bubbletea"

class SuspendModel
  include Bubbletea::Model

  def initialize
    @quitting = false
    @suspending = false
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::ResumeMsg
      @suspending = false
      {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "q", "esc"
        @quitting = true
        {self, Bubbletea.quit}
      when "ctrl+c"
        @quitting = true
        {self, Bubbletea.interrupt}
      when "ctrl+z"
        @suspending = true
        {self, Bubbletea.suspend}
      else
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("") if @suspending || @quitting
    Bubbletea::View.new("\nPress ctrl-z to suspend, ctrl+c to interrupt, q, or esc to exit\n")
  end
end

program = Bubbletea::Program.new(SuspendModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
