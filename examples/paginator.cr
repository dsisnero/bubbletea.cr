require "../src/bubbletea"

class PaginatorModel
  include Bubbletea::Model
  @items : Array(String)

  PER_PAGE = 10

  def initialize
    @items = (1..100).map { |i| "Item #{i}" }
    @page = 0
  end

  def init : Bubbletea::Cmd?
    Tea.request_background_color
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::BackgroundColorMsg
      {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "q", "esc", "ctrl+c"
        return {self, Bubbletea.quit}
      when "right", "l"
        @page += 1
        @page = total_pages - 1 if @page >= total_pages
      when "left", "h"
        @page -= 1
        @page = 0 if @page < 0
      end
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    start_idx = @page * PER_PAGE
    end_idx = {start_idx + PER_PAGE, @items.size}.min

    b = String.build do |io|
      io << "\n  Paginator Example\n\n"
      @items[start_idx...end_idx].each do |item|
        io << "  • #{item}\n\n"
      end
      io << "  " << dots << "\n\n"
      io << "  h/l ←/→ page • q: quit\n"
    end

    Bubbletea::View.new(b)
  end

  private def total_pages : Int32
    ((@items.size + PER_PAGE - 1) // PER_PAGE).to_i
  end

  private def dots : String
    (0...total_pages).map { |i| i == @page ? "•" : "·" }.join(" ")
  end
end

program = Bubbletea::Program.new(PaginatorModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
