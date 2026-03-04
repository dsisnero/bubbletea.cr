require "../src/bubbletea"
require "lipgloss"

# Pokemon types.
NONE     = ""
BUG      = "Bug"
ELECTRIC = "Electric"
FIRE     = "Fire"
FLYING   = "Flying"
GRASS    = "Grass"
GROUND   = "Ground"
NORMAL   = "Normal"
POISON   = "Poison"
WATER    = "Water"

class TableResizeModel
  include Bubbletea::Model

  @rows : Array(Array(String))
  @table : Lipgloss::StyleTable::Table

  def initialize
    base_style = Lipgloss::Style.new.padding(0, 1)
    header_style = base_style.foreground("252").bold(true)
    selected_style = base_style.foreground("#01BE85").background("#00432F")
    type_colors = {
      BUG      => "#D7FF87",
      ELECTRIC => "#FDFF90",
      FIRE     => "#FF7698",
      FLYING   => "#FF87D7",
      GRASS    => "#75FBAB",
      GROUND   => "#FF875F",
      NORMAL   => "#929292",
      POISON   => "#7D5AFC",
      WATER    => "#00E2C7",
    }
    dim_type_colors = {
      BUG      => "#97AD64",
      ELECTRIC => "#FCFF5F",
      FIRE     => "#BA5F75",
      FLYING   => "#C97AB2",
      GRASS    => "#59B980",
      GROUND   => "#C77252",
      NORMAL   => "#727272",
      POISON   => "#634BD0",
      WATER    => "#439F8E",
    }
    @rows = [
      ["1", "Bulbasaur", GRASS, POISON, "フシギダネ", "Bulbasaur"],
      ["2", "Ivysaur", GRASS, POISON, "フシギソウ", "Ivysaur"],
      ["3", "Venusaur", GRASS, POISON, "フシギバナ", "Venusaur"],
      ["4", "Charmander", FIRE, NONE, "ヒトカゲ", "Hitokage"],
      ["5", "Charmeleon", FIRE, NONE, "リザード", "Lizardo"],
      ["6", "Charizard", FIRE, FLYING, "リザードン", "Lizardon"],
      ["7", "Squirtle", WATER, NONE, "ゼニガメ", "Zenigame"],
      ["8", "Wartortle", WATER, NONE, "カメール", "Kameil"],
      ["9", "Blastoise", WATER, NONE, "カメックス", "Kamex"],
      ["10", "Caterpie", BUG, NONE, "キャタピー", "Caterpie"],
      ["11", "Metapod", BUG, NONE, "トランセル", "Trancell"],
      ["12", "Butterfree", BUG, FLYING, "バタフリー", "Butterfree"],
      ["13", "Weedle", BUG, POISON, "ビードル", "Beedle"],
      ["14", "Kakuna", BUG, POISON, "コクーン", "Cocoon"],
      ["15", "Beedrill", BUG, POISON, "スピアー", "Spear"],
      ["16", "Pidgey", NORMAL, FLYING, "ポッポ", "Poppo"],
      ["17", "Pidgeotto", NORMAL, FLYING, "ピジョン", "Pigeon"],
      ["18", "Pidgeot", NORMAL, FLYING, "ピジョット", "Pigeot"],
      ["19", "Rattata", NORMAL, NONE, "コラッタ", "Koratta"],
      ["20", "Raticate", NORMAL, NONE, "ラッタ", "Ratta"],
      ["21", "Spearow", NORMAL, FLYING, "オニスズメ", "Onisuzume"],
      ["22", "Fearow", NORMAL, FLYING, "オニドリル", "Onidrill"],
      ["23", "Ekans", POISON, NONE, "アーボ", "Arbo"],
      ["24", "Arbok", POISON, NONE, "アーボック", "Arbok"],
      ["25", "Pikachu", ELECTRIC, NONE, "ピカチュウ", "Pikachu"],
      ["26", "Raichu", ELECTRIC, NONE, "ライチュウ", "Raichu"],
      ["27", "Sandshrew", GROUND, NONE, "サンド", "Sand"],
      ["28", "Sandslash", GROUND, NONE, "サンドパン", "Sandpan"],
    ]

    @table = Lipgloss::StyleTable::Table.new
      .headers("#", "NAME", "TYPE 1", "TYPE 2", "JAPANESE", "OFFICIAL ROM.")
      .rows(@rows)
      .border(Lipgloss::Border.normal)
      .border(Lipgloss::Border.thick)
      .border_style(Lipgloss::Style.new.foreground("238"))
      .style_func(->(row : Int32, col : Int32) do
        if row == Lipgloss::StyleTable::HEADER_ROW
          header_style
        elsif @rows[row][1] == "Pikachu"
          selected_style
        else
          even = (row + 1).even?
          case col
          when 2, 3
            colors = even ? dim_type_colors : type_colors
            color = colors[@rows[row][col]]?
            color ? base_style.foreground(color) : base_style
          else
            even ? base_style.foreground("245") : base_style.foreground("252")
          end
        end
      end)
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
    v = Bubbletea::View.new("\n" + @table.string + "\n")
    v.alt_screen = true
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end
  program = Bubbletea::Program.new(TableResizeModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
