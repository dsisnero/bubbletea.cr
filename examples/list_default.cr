require "../lib/bubbles/src/bubbles"
require "lipgloss"

struct ListItem
  include Bubbles::List::DefaultItem

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
  include Tea::Model

  DOC_STYLE = Lipgloss::Style.new.margin(1, 2)

  property list : Bubbles::List::Model

  def initialize
    items = [] of Bubbles::List::Item
    items << ListItem.new("Raspberry Pi’s", "I have ’em all over my house")
    items << ListItem.new("Nutella", "It's good on toast")
    items << ListItem.new("Bitter melon", "It cools you down")
    items << ListItem.new("Nice socks", "And by that I mean socks without holes")
    items << ListItem.new("Eight hours of sleep", "I had this once")
    items << ListItem.new("Cats", "Usually")
    items << ListItem.new("Plantasia, the album", "My plants love it too")
    items << ListItem.new("Pour over coffee", "It takes forever to make though")
    items << ListItem.new("VR", "Virtual reality...what is there to say?")
    items << ListItem.new("Noguchi Lamps", "Such pleasing organic forms")
    items << ListItem.new("Linux", "Pretty much the best OS")
    items << ListItem.new("Business school", "Just kidding")
    items << ListItem.new("Pottery", "Wet clay is a great feeling")
    items << ListItem.new("Shampoo", "Nothing like clean hair")
    items << ListItem.new("Table tennis", "It’s surprisingly exhausting")
    items << ListItem.new("Milk crates", "Great for packing in your extra stuff")
    items << ListItem.new("Afternoon tea", "Especially the tea sandwich part")
    items << ListItem.new("Stickers", "The thicker the vinyl the better")
    items << ListItem.new("20° Weather", "Celsius, not Fahrenheit")
    items << ListItem.new("Warm light", "Like around 2700 Kelvin")
    items << ListItem.new("The vernal equinox", "The autumnal equinox is pretty good too")
    items << ListItem.new("Gaffer’s tape", "Basically sticky fabric")
    items << ListItem.new("Terrycloth", "In other words, towel fabric")
    
    @list = Bubbles::List.new(items, Bubbles::List::DefaultDelegate.new, 0, 0)
    @list.title = "My Fave Things"
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      if msg.string == "ctrl+c"
        return {self, Tea.quit}
      end
    when Tea::WindowSizeMsg
      h, v = DOC_STYLE.get_frame_size
      @list.set_size(msg.width - h, msg.height - v)
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : Tea::View
    v = Tea.new_view(DOC_STYLE.render(@list.view))
    v.alt_screen = true
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end
  program = Tea::Program.new(ListDefaultModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
