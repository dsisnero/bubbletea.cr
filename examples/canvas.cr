require "../src/bubbletea"
require "lipgloss"

class CanvasModel
  include Bubbletea::Model

  def initialize
    @width = 0
    @flip = false
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      return {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c", "esc"
        @quitting = true
        return {self, Bubbletea.quit}
      else
        @flip = !@flip
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    view = Bubbletea::View.new
    return view if @quitting

    z = [0, 1]
    z = reverse(z) if @flip

    footer = Lipgloss::Style.new
      .height(13)
      .align(Lipgloss::Position::Left, Lipgloss::Position::Bottom)
      .render("Press any key to swap the cards, or q to quit.")

    card_a = new_card("Hello").z(z[0])
    card_b = new_card("Goodbye").z(z[1]).x(10).y(2)

    comp = Lipgloss.new_compositor(
      Lipgloss.new_layer(footer),
      card_a,
      card_b,
    )
    view.set_content(comp.render)
    view
  end

  private def new_card(str : String) : Lipgloss::Layer
    Lipgloss.new_layer(
      Lipgloss::Style.new
        .width(20)
        .height(10)
        .border(Lipgloss::Border.rounded)
        .align(Lipgloss::Position::Center, Lipgloss::Position::Center)
        .render(str)
    )
  end

  private def reverse(items : Array(Int32)) : Array(Int32)
    n = items.size
    Array(Int32).new(n) { |i| items[n - 1 - i] }
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(CanvasModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Urgh: #{err.message}"
    exit 1
  end
end
