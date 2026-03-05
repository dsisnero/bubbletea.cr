require "../spec_helper"
require "lipgloss"

private struct TabsParityStyles
  getter doc : Lipgloss::Style
  getter inactive_tab : Lipgloss::Style
  getter active_tab : Lipgloss::Style
  getter window : Lipgloss::Style

  def initialize(
    @doc : Lipgloss::Style,
    @inactive_tab : Lipgloss::Style,
    @active_tab : Lipgloss::Style,
    @window : Lipgloss::Style,
  )
  end
end

private def tabs_parity_border_with_bottom(left : String, middle : String, right : String) : Lipgloss::Border
  border = Lipgloss::Border.rounded
  border.bottom_left = left
  border.bottom = middle
  border.bottom_right = right
  border
end

private def new_tabs_parity_styles(bg_is_dark : Bool) : TabsParityStyles
  highlight_color = bg_is_dark ? Lipgloss.color("#7D56F4") : Lipgloss.color("#874BFD")
  inactive_tab_border = tabs_parity_border_with_bottom("┴", "─", "┴")
  active_tab_border = tabs_parity_border_with_bottom("┘", " ", "└")

  doc = Lipgloss.new_style.padding(1, 2, 1, 2)
  inactive_tab = Lipgloss.new_style
    .border(inactive_tab_border, true)
    .border_foreground(highlight_color)
    .padding(0, 1)
  active_tab = Lipgloss.new_style
    .border(active_tab_border, true)
    .border_foreground(highlight_color)
    .padding(0, 1)
  window = Lipgloss.new_style
    .border_foreground(highlight_color)
    .padding(2, 0)
    .align(Lipgloss::Position::Center)
    .border(Lipgloss::Border.normal)
    .unset_border_top

  TabsParityStyles.new(doc, inactive_tab, active_tab, window)
end

private class TabsParityModel
  include Bubbletea::Model
  @tabs : Array(String)
  @tab_content : Array(String)
  @styles : TabsParityStyles
  @active_tab : Int32

  def initialize
    @tabs = ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"]
    @tab_content = ["Lip Gloss Tab", "Blush Tab", "Eye Shadow Tab", "Mascara Tab", "Foundation Tab"]
    @styles = new_tabs_parity_styles(true)
    @active_tab = 0
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      case msg.string
      when "ctrl+c", "q"
        return {self, Tea.quit}
      when "right", "l", "n", "tab"
        @active_tab = Math.min(@active_tab + 1, @tabs.size - 1)
      when "left", "h", "p", "shift+tab"
        @active_tab = Math.max(@active_tab - 1, 0)
      end
    end
    {self, nil}
  end

  def view : Bubbletea::View
    rendered_tabs = [] of String

    @tabs.each_with_index do |tab, i|
      is_first = i == 0
      is_last = i == @tabs.size - 1
      is_active = i == @active_tab
      style = (is_active ? @styles.active_tab : @styles.inactive_tab).copy

      border, top, right, bottom, left = style.get_border
      if is_first && is_active
        border.bottom_left = "│"
      elsif is_first && !is_active
        border.bottom_left = "├"
      elsif is_last && is_active
        border.bottom_right = "│"
      elsif is_last && !is_active
        border.bottom_right = "┤"
      end

      style = style.border(border, top, right, bottom, left)
      rendered_tabs << style.render(tab)
    end

    row = Lipgloss.join_horizontal(Lipgloss::Position::Top, rendered_tabs)
    doc = String.build do |io|
      io << row << "\n"
      io << @styles.window.copy.width(Lipgloss.width(row)).render(@tab_content[@active_tab])
    end
    Bubbletea::View.new(@styles.doc.copy.render(doc))
  end
end

private def capture_tabs_arrows_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    TabsParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea.key(Tea::KeyRight))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyLeft))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/tabs parity" do
  it "matches the saved Go golden output exactly for arrow movement" do
    actual = capture_tabs_arrows_output
    expected = File.read("#{__DIR__}/golden/tabs_arrows.go.golden").to_slice
    actual.should eq(expected)
  end
end
