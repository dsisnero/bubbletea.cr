require "../src/bubbletea"

LIST_HEIGHT = 14

struct SimpleItem
  getter value : String

  def initialize(@value : String)
  end

  def filter_value : String
    ""
  end

  def to_s(io : IO)
    io << @value
  end
end

struct ItemDelegate
  def spacing : Int32
    0
  end

  def update(_msg : Tea::Msg) : Bubbletea::Cmd?
    nil
  end
end

class ListSimpleModel
  include Bubbletea::Model

  def initialize
    @items = [
      SimpleItem.new("Ramen"),
      SimpleItem.new("Tomato Soup"),
      SimpleItem.new("Hamburgers"),
      SimpleItem.new("Cheeseburgers"),
      SimpleItem.new("Okonomiyaki"),
    ]
    @index = 0
    @choice = ""
    @quitting = false
    @width = 20
    @delegate = ItemDelegate.new
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c"
        @quitting = true
        return {self, Bubbletea.quit}
      when "up", "k"
        @index -= 1
        @index = 0 if @index < 0
      when "down", "j"
        @index += 1
        @index = @items.size - 1 if @index >= @items.size
      when "enter"
        if item = @items[@index]?
          @choice = item.value
        end
        return {self, Bubbletea.quit}
      end
    end

    {self, @delegate.update(msg)}
  end

  def view : Bubbletea::View
    if !@choice.empty?
      return Bubbletea::View.new("#{@choice}? Sounds good to me.")
    end

    if @quitting
      return Bubbletea::View.new("Not hungry? That's cool.")
    end

    s = String.build do |io|
      io << "\nWhat do you want for dinner?\n"
      @items.each_with_index do |item, i|
        prefix = i == @index ? "> " : "  "
        io << prefix << (i + 1) << ". " << item.value << "\n"
      end
    end
    Bubbletea::View.new(s)
  end
end

program = Bubbletea::Program.new(ListSimpleModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
