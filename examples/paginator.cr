require "../src/bubbletea"
require "bubbles"
require "lipgloss"

class PaginatorModel
  include Bubbletea::Model

  @items : Array(String)
  @paginator : Bubbles::Paginator::Model

  def initialize
    @items = (1..100).map { |i| "Item #{i}" }
    @paginator = Bubbles::Paginator.new(
      Bubbles::Paginator.with_total_pages(@items.size),
      Bubbles::Paginator.with_per_page(10)
    )
    @paginator.type = Bubbles::Paginator::Type::Dots
    update_styles(true) # default to dark
  end

  private def update_styles(is_dark : Bool)
    light_dark = Lipgloss.light_dark(is_dark)
    active_color = light_dark.call(Lipgloss.color("235"), Lipgloss.color("252"))
    inactive_color = light_dark.call(Lipgloss.color("250"), Lipgloss.color("238"))

    active_style = Lipgloss::Style.new.foreground(active_color)
    inactive_style = Lipgloss::Style.new.foreground(inactive_color)

    @paginator.active_dot = active_style.apply("•")
    @paginator.inactive_dot = inactive_style.apply("•")
  end

  def init : Bubbletea::Cmd?
    Tea.request_background_color
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::BackgroundColorMsg
      update_styles(msg.is_dark?)
      {self, nil}
    when Tea::KeyPressMsg
      case msg.keystroke
      when "q", "esc", "ctrl+c"
        return {self, Bubbletea.quit}
      end
    end

    # Delegate to paginator
    updated_paginator, cmd = @paginator.update(msg)
    @paginator = updated_paginator
    {self, cmd}
  end

  def view : Bubbletea::View
    start_idx, end_idx = @paginator.get_slice_bounds(@items.size)

    b = String.build do |io|
      io << "\n  Paginator Example\n\n"
      @items[start_idx...end_idx].each do |item|
        io << "  • #{item}\n\n"
      end
      io << "  " << @paginator.view << "\n\n"
      io << "  h/l ←/→ page • q: quit\n"
    end

    Bubbletea::View.new(b)
  end
end

program = Bubbletea::Program.new(PaginatorModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
