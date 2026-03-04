require "../lib/bubbles/src/bubbles"
require "lipgloss"

class CapabilityModel
  include Bubbletea::Model

  property input : Bubbles::TextInput::Model
  property width : Int32

  def initialize
    @input = Bubbles::TextInput.new
    @input.placeholder = "Enter capability name to request"
    @width = 0
  end

  def init : Bubbletea::Cmd?
    @input.focus
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
    when Bubbletea::CapabilityMsg
      return {self, Bubbletea.printf("Got capability: %s", msg)}
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "esc"
        return {self, Bubbletea.quit}
      when "enter"
        input_value = @input.value
        @input.reset
        return {self, Tea.request_capability(input_value)}
      end
    end

    @input, cmd = @input.update(msg)
    {self, cmd}
  end

  def view : Bubbletea::View
    instructions = Lipgloss::Style.new
      .width({@width, 60}.min)
      .render("Query for terminal capabilities. You can enter things like 'TN', 'RGB', 'cols', and so on. This will not work in all terminals and multiplexers.")

    Bubbletea::View.new("\n" + instructions + "\n\n" + @input.view + "\n\nPress enter to request capability, or ctrl+c to quit.")
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end

  program = Bubbletea::Program.new(CapabilityModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Uh oh: #{err.message}"
    exit 1
  end
end
