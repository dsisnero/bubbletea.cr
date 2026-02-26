require "../src/bubbletea"

class VanishModel
  include Bubbletea::Model

  def initialize
    @done = false
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    if msg.is_a?(Bubbletea::KeyPressMsg)
      @done = true
      return {self, Bubbletea.quit}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    if @done
      Bubbletea::View.new("")
    else
      Bubbletea::View.new("Press any key to quit.\n(When this program quits, it will vanish without a trace.)")
    end
  end
end

program = Bubbletea::Program.new(VanishModel.new)
_model, err = program.run
if err
  STDERR.puts "Oh no: #{err.message}"
  exit 1
end
