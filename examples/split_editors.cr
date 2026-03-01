require "../src/bubbletea"

INITIAL_INPUTS = 2
MAX_INPUTS     = 6
MIN_INPUTS     = 1

class SplitEditorsModel
  include Bubbletea::Model

  @inputs : Array(String)

  def initialize
    @width = 80
    @height = 24
    @inputs = Array.new(INITIAL_INPUTS) { "" }
    @focus = 0
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      key = msg.keystroke
      case key
      when "esc", "ctrl+c"
        return {self, Bubbletea.quit}
      when "tab"
        @focus = (@focus + 1) % @inputs.size
      when "shift+tab"
        @focus -= 1
        @focus = @inputs.size - 1 if @focus < 0
      when "ctrl+n"
        @inputs << "" if @inputs.size < MAX_INPUTS
      when "ctrl+w"
        if @inputs.size > MIN_INPUTS
          @inputs.delete_at(@inputs.size - 1)
          @focus = @inputs.size - 1 if @focus >= @inputs.size
        end
      when "backspace"
        current = @inputs[@focus]
        @inputs[@focus] = current[0...-1] unless current.empty?
      when "space"
        @inputs[@focus] += " "
      else
        if rune = msg.rune
          @inputs[@focus] += rune.to_s
        end
      end
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
    end

    {self, nil}
  end

  def view : Bubbletea::View
    cols = @inputs.map_with_index do |text, i|
      prefix = i == @focus ? ">" : " "
      "#{prefix}#{text}"
    end

    help = "tab: next • shift+tab: prev • ctrl+n: add • ctrl+w: remove • esc: quit"
    v = Bubbletea::View.new(cols.join(" | ") + "\n\n" + help)
    v.alt_screen = true
    v
  end
end

program = Bubbletea::Program.new(SplitEditorsModel.new)
_model, err = program.run
if err
  STDERR.puts "Error while running program: #{err.message}"
  exit 1
end
