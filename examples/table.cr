require "../src/bubbletea"
require "lipgloss"

BASE_STYLE = Lipgloss::Style.new
  .border(Lipgloss::Border.normal)
  .border_foreground(
    Lipgloss.color("240"),
    Lipgloss.color("240"),
    Lipgloss.color("240"),
    Lipgloss.color("240")
  )

class TableModel
  include Bubbletea::Model

  def initialize
    @focused = true
    @selected = 0
    @rows = [
      ["1", "Tokyo", "Japan", "37,274,000"],
      ["2", "Delhi", "India", "32,065,760"],
      ["3", "Shanghai", "China", "28,516,904"],
      ["4", "Dhaka", "Bangladesh", "22,478,116"],
      ["5", "Sao Paulo", "Brazil", "22,429,800"],
    ]
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "esc"
        @focused = !@focused
      when "up", "k"
        @selected = {@selected - 1, 0}.max if @focused
      when "down", "j"
        @selected = {@selected + 1, @rows.size - 1}.min if @focused
      when "q", "ctrl+c"
        return {self, Bubbletea.quit}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    table = Lipgloss::StyleTable::Table.new
      .headers("Rank", "City", "Country", "Population")
      .border(Lipgloss::Border.normal)
    @rows.each_with_index do |row, idx|
      rendered = if idx == @selected && @focused
                   [">#{row[0]}", row[1], row[2], row[3]]
                 else
                   row
                 end
      table = table.row(rendered)
    end

    content = BASE_STYLE.render(table.render) + "\n  esc: focus/blur • arrows: move • q: quit\n"
    Bubbletea::View.new(content)
  end
end

program = Bubbletea::Program.new(TableModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
