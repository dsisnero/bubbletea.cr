require "../lib/bubbles/src/bubbles"
require "lipgloss"

class TextinputModel
  include Bubbletea::Model

  property text_input : Bubbles::TextInput::Model
  property err : Exception?
  property? quitting : Bool

  def initialize
    ti = Bubbles::TextInput.new
    ti.placeholder = "Pikachu"
    ti.set_virtual_cursor(false)
    ti.focus
    ti.char_limit = 156
    ti.set_width(20)

    @text_input = ti
    @err = nil
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    -> { Bubbles::TextInput.blink.as(Tea::Msg?) }
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string
      when "enter", "ctrl+c", "esc"
        @quitting = true
        return {self, Bubbletea.quit}
      end
    end

    @text_input, cmd = @text_input.update(msg)
    {self, cmd}
  end

  def view : Bubbletea::View
    c = nil
    unless @text_input.virtual_cursor?
      c = @text_input.cursor
      if c
        c = c.dup
        c.y += Lipgloss.height(header_view)
      end
    end

    str = Lipgloss.join_vertical(Lipgloss::Position::Top, header_view, @text_input.view, footer_view)
    str += "\n" if @quitting

    v = Bubbletea::View.new(str)
    v.cursor = c
    v
  end

  private def header_view : String
    "What’s your favorite Pokémon?\n"
  end

  private def footer_view : String
    "\n(esc to quit)"
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(TextinputModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
