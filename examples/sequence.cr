require "../src/bubbletea"

private def sleep_println(text : String, milliseconds : Int32) : Bubbletea::Cmd
  print_cmd = Bubbletea.println(text)
  -> : Tea::Msg? do
    sleep milliseconds.milliseconds
    print_cmd.call
  end
end

class SequenceModel
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    Bubbletea.sequence(
      Bubbletea.batch(
        Bubbletea.sequence(
          sleep_println("1-1-1", 1000),
          sleep_println("1-1-2", 1000)
        ),
        Bubbletea.batch(
          sleep_println("1-2-1", 1500),
          sleep_println("1-2-2", 1250)
        )
      ),
      Bubbletea.println("2"),
      Bubbletea.sequence(
        Bubbletea.batch(
          sleep_println("3-1-1", 500),
          sleep_println("3-1-2", 1000)
        ),
        Bubbletea.sequence(
          sleep_println("3-2-1", 750),
          sleep_println("3-2-2", 500)
        )
      ),
      Bubbletea.quit
    )
  end

  def update(msg : Tea::Msg)
    if msg.is_a?(Bubbletea::KeyPressMsg)
      return {self, Bubbletea.quit}
    end
    {self, nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new("")
  end
end

program = Bubbletea::Program.new(SequenceModel.new)
_model, err = program.run
if err
  STDERR.puts "Uh oh: #{err.message}"
  exit 1
end
