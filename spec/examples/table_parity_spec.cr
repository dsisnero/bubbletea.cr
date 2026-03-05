require "../spec_helper"
require "bubbles"
require "lipgloss"

TABLE_PARITY_BASE_STYLE = Lipgloss.new_style
  .border_style(Lipgloss::Border.normal)
  .border_foreground(Lipgloss.color("240"))

private class TableParityModel
  include Bubbletea::Model
  @table : Bubbles::Table::Model

  def initialize
    columns = [
      Bubbles::Table::Column.new("Rank", 4),
      Bubbles::Table::Column.new("City", 10),
      Bubbles::Table::Column.new("Country", 10),
      Bubbles::Table::Column.new("Population", 10),
    ]
    rows = [
      ["1", "Tokyo", "Japan", "37,274,000"],
      ["2", "Delhi", "India", "32,065,760"],
      ["3", "Shanghai", "China", "28,516,904"],
      ["4", "Dhaka", "Bangladesh", "22,478,116"],
      ["5", "Sao Paulo", "Brazil", "22,429,800"],
    ]

    @table = Bubbles::Table.new(
      Bubbles::Table.with_columns(columns),
      Bubbles::Table.with_rows(rows),
      Bubbles::Table.with_focused(true),
      Bubbles::Table.with_height(7),
    )
    styles = Bubbles::Table.default_styles
    @table.set_styles(styles)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      case msg.string
      when "esc"
        if @table.focused?
          @table.blur
        else
          @table.focus
        end
      when "q", "ctrl+c"
        return {self, Tea.quit}
      when "enter"
        if row = @table.selected_row
          return {self, Tea.printf("Let's go to %s!", row[1])}
        end
      end
    end
    @table, cmd = @table.update(msg)
    {self, cmd}
  end

  def view : Bubbletea::View
    Bubbletea::View.new(TABLE_PARITY_BASE_STYLE.render(@table.view) + "\n  " + @table.help_view + "\n")
  end
end

private def capture_table_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    TableParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea.key('j'))
    program.send(Tea.key('j'))
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

private def capture_table_arrows_esc_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    TableParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEsc))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEsc))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyUp))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/table parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_table_output
    expected = File.read("#{__DIR__}/golden/table.go.golden").to_slice
    actual.should eq(expected)
  end

  it "matches Go golden for arrow movement and esc focus toggle" do
    actual = capture_table_arrows_esc_output
    expected = File.read("#{__DIR__}/golden/table_arrows_esc.go.golden").to_slice
    actual.should eq(expected)
  end
end
