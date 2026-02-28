require "bubbles"
require "lipgloss"

struct KeyMap
  include Bubbles::Help::KeyMap

  property up : Bubbles::Key::Binding
  property down : Bubbles::Key::Binding
  property left : Bubbles::Key::Binding
  property right : Bubbles::Key::Binding
  property help : Bubbles::Key::Binding
  property quit : Bubbles::Key::Binding

  def initialize
    @up = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("up", "k"),
      Bubbles::Key.with_help("↑/k", "move up")
    )
    @down = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("down", "j"),
      Bubbles::Key.with_help("↓/j", "move down")
    )
    @left = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("left", "h"),
      Bubbles::Key.with_help("←/h", "move left")
    )
    @right = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("right", "l"),
      Bubbles::Key.with_help("→/l", "move right")
    )
    @help = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("?"),
      Bubbles::Key.with_help("?", "toggle help")
    )
    @quit = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("q", "esc", "ctrl+c"),
      Bubbles::Key.with_help("q", "quit")
    )
  end

  def short_help : Array(Bubbles::Key::Binding)
    [@help, @quit]
  end

  def full_help : Array(Array(Bubbles::Key::Binding))
    [
      [@up, @down, @left, @right], # first column
      [@help, @quit],              # second column
    ]
  end
end

class HelpModel
  include Bubbletea::Model

  property keys : KeyMap
  property help : Bubbles::Help::Model
  property input_style : Lipgloss::Style
  property last_key : String
  property? quitting : Bool

  def initialize
    @keys = KeyMap.new
    @help = Bubbles::Help::Model.new
    @input_style = Lipgloss::Style.new.foreground("#FF75B7")
    @last_key = ""
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      # If we set a width on the help menu it can gracefully truncate
      # its view as needed.
      @help.width = msg.width
    when Bubbletea::KeyPressMsg
      case
      when Bubbles::Key.matches?(msg, @keys.up)
        @last_key = "↑"
      when Bubbles::Key.matches?(msg, @keys.down)
        @last_key = "↓"
      when Bubbles::Key.matches?(msg, @keys.left)
        @last_key = "←"
      when Bubbles::Key.matches?(msg, @keys.right)
        @last_key = "→"
      when Bubbles::Key.matches?(msg, @keys.help)
        @help.show_all = !@help.show_all
      when Bubbles::Key.matches?(msg, @keys.quit)
        @quitting = true
        return {self, Bubbletea.quit}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("Bye!\n") if @quitting

    status = @last_key.empty? ? "Waiting for input..." : "You chose: #{@input_style.render(@last_key)}"
    help_view = @help.view(@keys)
    height = {8 - status.count('\n') - help_view.count('\n'), 1}.max

    Bubbletea::View.new(status + "\n" * height + help_view)
  end
end

program = Bubbletea::Program.new(HelpModel.new)
_model, err = program.run
if err
  STDERR.puts "Could not start program :( #{err.message}"
  exit 1
end
