require "../src/bubbletea"

class ColorProfileModel
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    Bubbletea.batch(
      Tea.request_capability("RGB"),
      Tea.request_capability("Tc")
    )
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      {self, Bubbletea.quit}
    when Bubbletea::ColorProfileMsg
      {self, Bubbletea.println("Color profile manually set to", msg.profile.to_s)}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    Bubbletea::View.new(
      "This will produce the wrong colors on Apple Terminal :)\n\n" +
      "Howdy!\n\n" +
      "Press any key to exit."
    )
  end
end

program = Bubbletea::Program.new(ColorProfileModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
