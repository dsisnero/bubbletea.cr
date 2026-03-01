require "bubbles"
require "lipgloss"

struct ListItem
  include Bubbles::List::Item

  getter title : String
  getter desc : String

  def initialize(@title : String, @desc : String)
  end

  def title : String
    @title
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

  DOC_STYLE = Lipgloss::Style.new.margin(1, 2)

  property list : Bubbles::List::Model

  def initialize
    items = [
      ListItem.new("Raspberry Pi's", "I have 'em all over my house"),
      ListItem.new("Nutella", "It's good on toast"),
      ListItem.new("Bitter melon", "It cools you down"),
      ListItem.new("Nice socks", "And by that I mean socks without holes"),
      ListItem.new("Eight hours of sleep", "I had this once"),
      ListItem.new("Cats", "Usually"),
      ListItem.new("Plantasia, the album", "My plants love it too"),
      ListItem.new("Pour over coffee", "It takes forever to make though"),
      ListItem.new("VR", "Virtual reality...what is there to say?"),
      ListItem.new("Noguchi Lamps", "Such pleasing organic forms"),
      ListItem.new("Linux", "Pretty much the best OS"),
      ListItem.new("Business school", "Just kidding"),
      ListItem.new("Pottery", "Wet clay is a great feeling"),
      ListItem.new("Shampoo", "Nothing like clean hair"),
      ListItem.new("Table tennis", "It's surprisingly exhausting"),
      ListItem.new("Milk crates", "Great for packing in your extra stuff"),
      ListItem.new("Afternoon tea", "Especially the tea sandwich part"),
      ListItem.new("Stickers", "The thicker the vinyl the better"),
      ListItem.new("20° Weather", "Celsius, not Fahrenheit"),
      ListItem.new("Warm light", "Like around 2700 Kelvin"),
      ListItem.new("The vernal equinox", "The autumnal equinox is pretty good too"),
      ListItem.new("Gaffer's tape", "Basically sticky fabric"),
      ListItem.new("Terrycloth", "In other words, towel fabric"),
    ]

    @list = Bubbles::List.new(items, Bubbles::List::DefaultDelegate.new, 0, 0)
    @list.title = "My Fave Things"
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      if msg.string_with_mods == "ctrl+c"
        return {self, Bubbletea.quit}
      end
    when Bubbletea::WindowSizeMsg
      # margin(1, 2) means vertical margin 1, horizontal margin 2
      # So total horizontal frame size = 2 * 2 = 4, vertical frame size = 2 * 1 = 2
      h = 4 # 2 * horizontal margin
      v = 2 # 2 * vertical margin
      @list.set_size(msg.width - h, msg.height - v)
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : Bubbletea::View
    # Just add margins manually instead of using style.render
    content = String.build do |io|
      io << "\n" # top margin
      io << "  " # left margin
      io << @list.view
      io << "\n" # bottom margin
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
