require "bubbles"

class CapabilityModel
  include Bubbletea::Model

  property input : Bubbles::TextInput::Model
  property width : Int32
  property last : String

  def initialize
    @input = Bubbles::TextInput.new
    @input.placeholder = "Enter capability name to request"
    @width = 0
    @last = ""
  end

  def init : Bubbletea::Cmd?
    @input.focus
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      {self, nil}
    when Bubbletea::CapabilityMsg
      {self, Bubbletea.println("Got capability: #{msg}")}
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "esc"
        {self, Bubbletea.quit}
      when "enter"
        input_value = @input.value
        @input.reset
        {self, Tea.request_capability(input_value.empty? ? "RGB" : input_value)}
      end
    end

    @input, cmd = @input.update(msg)
    {self, cmd}
  end

  def view : Bubbletea::View
    _width = {@width, 60}.min
    _width = 60 if _width <= 0

    instructions = "Query for terminal capabilities. You can enter things like 'TN', 'RGB', 'cols', and so on. This will not work in all terminals and multiplexers."

    Bubbletea::View.new("\n" + instructions + "\n\n" + @input.view + "\n\nPress enter to request capability, or ctrl+c to quit.")
  end
end

program = Bubbletea::Program.new(CapabilityModel.new)
_model, err = program.run
if err
  STDERR.puts "Uh oh: #{err.message}"
  exit 1
end
