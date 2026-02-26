require "../src/bubbletea"

struct ListItem
  getter title : String
  getter desc : String

  def initialize(@title : String, @desc : String)
  end

  def description : String
    @desc
  end

  def filter_value : String
    @title
  end
end

class ListDefaultModel
  include Bubbletea::Model

  def initialize
    @items = [
      ListItem.new("Raspberry Pi's", "I have 'em all over my house"),
      ListItem.new("Nutella", "It's good on toast"),
      ListItem.new("Linux", "Pretty much the best OS"),
    ]
    @idx = 0
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      when "up", "k"
        @idx -= 1
        @idx = 0 if @idx < 0
      when "down", "j"
        @idx += 1
        @idx = @items.size - 1 if @idx >= @items.size
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    content = String.build do |io|
      io << "My Fave Things\n\n"
      @items.each_with_index do |item, i|
        prefix = i == @idx ? "> " : "  "
        io << prefix << item.title << "\n"
        io << "    " << item.description << "\n"
      end
      io << "\nq: quit"
    end

    v = Bubbletea::View.new(content)
    v.alt_screen = true
    v
  end
end

program = Bubbletea::Program.new(ListDefaultModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
