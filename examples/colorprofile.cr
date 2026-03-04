require "../src/bubbletea"
require "lipgloss"

class ColorProfileModel
  include Bubbletea::Model

  @fancy_style : Lipgloss::Style

  def initialize
    @fancy_style = Lipgloss::Style.new.foreground("#6b50ff")
  end

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
      @fancy_style.render("Howdy!") + "\n\n" +
      "Press any key to exit."
    )
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea.new_program(
    ColorProfileModel.new,
    Tea.with_color_profile(Ultraviolet::ColorProfile::TrueColor)
  )
  _model, err = program.run
  if err
    STDERR.puts "Oof: #{err.message}"
    exit 1
  end
end
