require "../src/bubbletea"

struct KeyMap
  getter up = {"up", "k"}
  getter down = {"down", "j"}
  getter left = {"left", "h"}
  getter right = {"right", "l"}
  getter help = {"?"}
  getter quit = {"q", "esc", "ctrl+c"}

  def short_help : Array(String)
    ["?: toggle help", "q: quit"]
  end

  def full_help : Array(Array(String))
    [
      ["↑/k move up", "↓/j move down", "←/h move left", "→/l move right"],
      short_help,
    ]
  end
end

class HelpModel
  include Bubbletea::Model

  def initialize
    @keys = KeyMap.new
    @show_all = false
    @last_key = ""
    @quitting = false
    @width = 80
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
    when Bubbletea::KeyPressMsg
      key = msg.string_with_mods
      case
      when @keys.up.includes?(key)
        @last_key = "↑"
      when @keys.down.includes?(key)
        @last_key = "↓"
      when @keys.left.includes?(key)
        @last_key = "←"
      when @keys.right.includes?(key)
        @last_key = "→"
      when @keys.help.includes?(key)
        @show_all = !@show_all
      when @keys.quit.includes?(key)
        @quitting = true
        return {self, Bubbletea.quit}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("Bye!\n") if @quitting

    status = @last_key.empty? ? "Waiting for input..." : "You chose: #{@last_key}"
    help_view = if @show_all
                  @keys.full_help.map(&.join(" • ")).join("\n")
                else
                  @keys.short_help.join(" • ")
                end

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
