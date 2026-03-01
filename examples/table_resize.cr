require "../src/bubbletea"
require "lipgloss"

# Pokemon types.
NONE_TYPE = ""
BUG       = "Bug"
ELECTRIC  = "Electric"
FIRE      = "Fire"
FLYING    = "Flying"
GRASS     = "Grass"
GROUND    = "Ground"
NORMAL    = "Normal"
POISON    = "Poison"
WATER     = "Water"

class TableResizeModel
  include Bubbletea::Model

  def initialize
    @table = Lipgloss::StyleTable::Table.new
      .headers("#", "NAME", "TYPE 1", "TYPE 2")
      .rows([
        ["1", "Bulbasaur", GRASS, POISON],
        ["4", "Charmander", FIRE, NONE_TYPE],
        ["7", "Squirtle", WATER, NONE_TYPE],
        ["10", "Caterpie", BUG, NONE_TYPE],
        ["25", "Pikachu", ELECTRIC, NONE_TYPE],
        ["27", "Sandshrew", GROUND, NONE_TYPE],
        ["16", "Pidgey", NORMAL, FLYING],
      ])
      .border(Lipgloss::Border.thick)
      .border_style(Lipgloss::Style.new.foreground("238"))
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @table = @table.width(msg.width).height(msg.height)
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c"
        return {self, Bubbletea.quit}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("\n" + @table.render + "\n")
    v.alt_screen = true
    v
  end
end

program = Bubbletea::Program.new(TableResizeModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
