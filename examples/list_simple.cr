require "../src/bubbletea"
require "../lib/bubbles/src/bubbles"
require "lipgloss"

LIST_HEIGHT   = 14
DEFAULT_WIDTH = 20

struct ListSimpleStyles
  property title : Lipgloss::Style
  property item : Lipgloss::Style
  property selected_item : Lipgloss::Style
  property pagination : Lipgloss::Style
  property help : Lipgloss::Style
  property quit_text : Lipgloss::Style

  def initialize(
    @title : Lipgloss::Style,
    @item : Lipgloss::Style,
    @selected_item : Lipgloss::Style,
    @pagination : Lipgloss::Style,
    @help : Lipgloss::Style,
    @quit_text : Lipgloss::Style,
  )
  end
end

private def new_list_simple_styles(dark_bg : Bool) : ListSimpleStyles
  defaults = Bubbles::List.default_styles(dark_bg)
  ListSimpleStyles.new(
    Lipgloss::Style.new.margin_left(2),
    Lipgloss::Style.new.padding_left(4),
    Lipgloss::Style.new.padding_left(2).foreground("170"),
    defaults.pagination_style.padding_left(4),
    defaults.help_style.padding_left(4).padding_bottom(1),
    Lipgloss::Style.new.margin(1, 0, 2, 4),
  )
end

struct ListSimpleItem
  include Bubbles::List::Item

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

class ListSimpleItemDelegate
  include Bubbles::List::ItemDelegate

  property styles : ListSimpleStyles

  def initialize(@styles : ListSimpleStyles)
  end

  def height : Int32
    1
  end

  def spacing : Int32
    0
  end

  def update(msg : Tea::Msg, m : Bubbles::List::Model) : Tea::Cmd?
    _ = msg
    _ = m
    nil
  end

  def render(w : IO, m : Bubbles::List::Model, index : Int32, item : Bubbles::List::Item)
    i = item.as(ListSimpleItem)
    str = "#{index + 1}. #{i.value}"

    if index == m.index
      w << @styles.selected_item.render("> #{str}")
    else
      w << @styles.item.render(str)
    end
  end
end

class ListSimpleModel
  include Bubbletea::Model

  def initialize(@list : Bubbles::List::Model, @styles : ListSimpleStyles, @choice = "", @quitting = false)
  end

  def self.initial_model : self
    items = [
      ListSimpleItem.new("Ramen"),
      ListSimpleItem.new("Tomato Soup"),
      ListSimpleItem.new("Hamburgers"),
      ListSimpleItem.new("Cheeseburgers"),
      ListSimpleItem.new("Currywurst"),
      ListSimpleItem.new("Okonomiyaki"),
      ListSimpleItem.new("Pasta"),
      ListSimpleItem.new("Fillet Mignon"),
      ListSimpleItem.new("Caviar"),
      ListSimpleItem.new("Just Wine"),
    ] of Bubbles::List::Item

    styles = new_list_simple_styles(true)
    delegate = ListSimpleItemDelegate.new(styles)

    list = Bubbles::List.new(items, delegate, DEFAULT_WIDTH, LIST_HEIGHT)
    list.title = "What do you want for dinner?"
    list.set_show_status_bar(false)
    list.set_filtering_enabled(false)

    model = new(list, styles)
    model.update_styles(true)
    model
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::WindowSizeMsg
      @list.set_width(msg.width)
      return {self, nil}
    when Tea::KeyPressMsg
      case msg.string
      when "q", "ctrl+c"
        @quitting = true
        return {self, Tea.quit}
      when "enter"
        if selected = @list.selected_item
          @choice = selected.as(ListSimpleItem).value
        end
        return {self, Tea.quit}
      end
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : Tea::View
    if !@choice.empty?
      return Tea.new_view(@styles.quit_text.render("#{@choice}? Sounds good to me."))
    end

    if @quitting
      return Tea.new_view(@styles.quit_text.render("Not hungry? That’s cool."))
    end

    Tea.new_view("\n" + @list.view)
  end

  def update_styles(is_dark : Bool)
    @styles = new_list_simple_styles(is_dark)
    @list.styles.title = @styles.title
    @list.styles.pagination_style = @styles.pagination
    @list.styles.help_style = @styles.help
    @list.set_delegate(ListSimpleItemDelegate.new(@styles))
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Tea::Program.new(ListSimpleModel.initial_model)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
