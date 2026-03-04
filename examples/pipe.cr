require "../lib/bubbles/src/bubbles"
require "lipgloss"

class PipeModel
  include Tea::Model

  @user_input : Bubbles::TextInput::Model

  def initialize(@user_input : Bubbles::TextInput::Model)
  end

  def self.new_model(initial_value : String) : self
    i = Bubbles::TextInput.new
    i.prompt = ""

    styles = i.styles
    styles.cursor.color = Lipgloss.color("63")
    i.set_styles(styles)

    i.set_width(48)
    i.set_value(initial_value)
    i.cursor_end
    i.focus

    new(i)
  end

  def init : Tea::Cmd?
    -> { Bubbles::TextInput.blink.as(Tea::Msg?) }
  end

  def update(msg : Tea::Msg)
    if key = msg.as?(Tea::KeyPressMsg)
      case key.string
      when "ctrl+c", "esc", "enter"
        return {self, Tea.quit}
      end
    end

    @user_input, cmd = @user_input.update(msg)
    {self, cmd}
  end

  def view : Tea::View
    Tea.new_view("\nYou piped in: #{@user_input.view}\n\nPress ^C to exit")
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  stdin_info = STDIN.info
  if stdin_info.type != File::Type::Pipe && stdin_info.size == 0
    puts "Try piping in some text."
    exit 1
  end

  input = STDIN.gets_to_end
  model = PipeModel.new_model(input.strip)

  _model, err = Tea::Program.new(model).run
  if err
    STDERR.puts "Couldn't start program: #{err.message}"
    exit 1
  end
end
