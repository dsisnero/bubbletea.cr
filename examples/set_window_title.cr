require "../src/bubbletea"
require "lipgloss"

WINDOW_TITLE = "Hello, Bubble Tea"

class SetWindowTitleModel
  include Bubbletea::Model

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    if msg.is_a?(Bubbletea::KeyPressMsg)
      return {self, Bubbletea.quit}
    end
    {self, nil}
  end

  def view : Bubbletea::View
    wrap = Lipgloss::Style.new.width(78)
    text = wrap.render("The window title has been set to '#{WINDOW_TITLE}'. It will be cleared on exit.") +
           "\n\nPress any key to quit."
    v = Bubbletea::View.new(text)
    v.window_title = WINDOW_TITLE
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(SetWindowTitleModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Uh oh: #{err.message}"
    exit 1
  end
end
