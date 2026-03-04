require "../lib/bubbles/src/bubbles"
require "lipgloss"

struct ListFancyStyles
  getter app : Lipgloss::Style
  getter title : Lipgloss::Style
  getter status_message : Lipgloss::Style

  def initialize(@app : Lipgloss::Style, @title : Lipgloss::Style, @status_message : Lipgloss::Style)
  end

  def self.new_styles(dark_bg : Bool) : self
    _ = dark_bg
    new(
      Lipgloss::Style.new.padding(1, 2),
      Lipgloss::Style.new
        .foreground("#FFFDF5")
        .background("#25A065")
        .padding(0, 1),
      Lipgloss::Style.new.foreground("#04B575")
    )
  end
end

struct ListFancyItem
  include Bubbles::List::DefaultItem

  getter title : String
  getter description : String

  def initialize(@title : String, @description : String)
  end

  def filter_value : String
    @title
  end
end

class ListFancyKeyMap
  getter toggle_spinner : Bubbles::Key::Binding
  getter toggle_title_bar : Bubbles::Key::Binding
  getter toggle_status_bar : Bubbles::Key::Binding
  getter toggle_pagination : Bubbles::Key::Binding
  getter toggle_help_menu : Bubbles::Key::Binding
  getter insert_item : Bubbles::Key::Binding

  def initialize
    @insert_item = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("a"),
      Bubbles::Key.with_help("a", "add item")
    )
    @toggle_spinner = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("s"),
      Bubbles::Key.with_help("s", "toggle spinner")
    )
    @toggle_title_bar = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("T"),
      Bubbles::Key.with_help("T", "toggle title")
    )
    @toggle_status_bar = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("S"),
      Bubbles::Key.with_help("S", "toggle status")
    )
    @toggle_pagination = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("P"),
      Bubbles::Key.with_help("P", "toggle pagination")
    )
    @toggle_help_menu = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("H"),
      Bubbles::Key.with_help("H", "toggle help")
    )
  end
end

class ListFancyDelegateKeyMap
  getter choose : Bubbles::Key::Binding
  getter remove : Bubbles::Key::Binding

  def initialize
    @choose = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("enter"),
      Bubbles::Key.with_help("enter", "choose")
    )
    @remove = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("x", "backspace"),
      Bubbles::Key.with_help("x", "delete")
    )
  end
end

class RandomFancyItemGenerator
  TITLES = [
    "Artichoke", "Baking Flour", "Bananas", "Barley", "Bean Sprouts", "Bitter Melon", "Black Cod", "Blood Orange", "Brown Sugar", "Cashew Apple", "Cashews", "Cat Food", "Coconut Milk", "Cucumber", "Curry Paste", "Currywurst", "Dill", "Dragonfruit", "Dried Shrimp", "Eggs", "Fish Cake", "Furikake", "Garlic", "Gherkin", "Ginger", "Granulated Sugar", "Grapefruit", "Green Onion", "Hazelnuts", "Heavy whipping cream", "Honey Dew", "Horseradish", "Jicama", "Kohlrabi", "Leeks", "Lentils", "Licorice Root", "Meyer Lemons", "Milk", "Molasses", "Muesli", "Nectarine", "Niagamo Root", "Nopal", "Nutella", "Oat Milk", "Oatmeal", "Olives", "Papaya", "Party Gherkin", "Peppers", "Persian Lemons", "Pickle", "Pineapple", "Plantains", "Pocky", "Powdered Sugar", "Quince", "Radish", "Ramps", "Star Anise", "Sweet Potato", "Tamarind", "Unsalted Butter", "Watermelon", "Weißwurst", "Yams", "Yeast", "Yuzu", "Snow Peas",
  ]

  DESCS = [
    "A little weird", "Bold flavor", "Can’t get enough", "Delectable", "Expensive", "Expired", "Exquisite", "Fresh", "Gimme", "In season", "Kind of spicy", "Looks fresh", "Looks good to me", "Maybe not", "My favorite", "Oh my", "On sale", "Organic", "Questionable", "Really fresh", "Refreshing", "Salty", "Scrumptious", "Delectable", "Slightly sweet", "Smells great", "Tasty", "Too ripe", "At last", "What?", "Wow", "Yum", "Maybe", "Sure, why not?",
  ]

  @titles : Array(String)?
  @descs : Array(String)?
  @title_index : Int32
  @desc_index : Int32
  @mtx : Mutex?
  @@rng = Random.new

  def initialize
    @titles = nil
    @descs = nil
    @title_index = 0
    @desc_index = 0
    @mtx = nil
  end

  def self.seed(seed : Int64)
    @@rng = Random.new(seed)
  end

  private def reset
    @mtx = Mutex.new
    @titles = TITLES.dup
    @descs = DESCS.dup

    # Match Go logic: shuffling draws from a shared mutable RNG state.
    @titles.not_nil!.shuffle!(@@rng)
    @descs.not_nil!.shuffle!(@@rng)
  end

  def next : ListFancyItem
    reset if @mtx.nil?

    @mtx.not_nil!.synchronize do
      titles = @titles.not_nil!
      descs = @descs.not_nil!

      item = ListFancyItem.new(titles[@title_index], descs[@desc_index])

      @title_index += 1
      @title_index = 0 if @title_index >= titles.size

      @desc_index += 1
      @desc_index = 0 if @desc_index >= descs.size

      item
    end
  end
end

class ListFancyModel
  include Tea::Model

  getter list : Bubbles::List::Model

  @styles : ListFancyStyles
  @dark_bg : Bool
  @width : Int32
  @height : Int32
  @list : Bubbles::List::Model
  @item_generator : RandomFancyItemGenerator
  @keys : ListFancyKeyMap
  @delegate_keys : ListFancyDelegateKeyMap

  def initialize
    @styles = ListFancyStyles.new_styles(false)
    @dark_bg = false
    @width = 0
    @height = 0

    @delegate_keys = ListFancyDelegateKeyMap.new
    @keys = ListFancyKeyMap.new

    @item_generator = RandomFancyItemGenerator.new

    items = [] of Bubbles::List::Item
    24.times do
      items << @item_generator.next
    end

    delegate = Bubbles::List::DefaultDelegate.new
    delegate.update_func = ->(msg : Tea::Msg, m : Bubbles::List::Model) do
      if selected = m.selected_item
        if item = selected.as?(ListFancyItem)
          title = item.title
          case key_msg = msg
          when Tea::KeyPressMsg
            if Bubbles::Key.matches?(key_msg, @delegate_keys.choose)
              m.new_status_message(@styles.status_message.render("You chose #{title}"))
            elsif Bubbles::Key.matches?(key_msg, @delegate_keys.remove)
              index = m.index
              m.remove_item(index)
              @delegate_keys.remove.set_enabled(false) if m.items.empty?
              m.new_status_message(@styles.status_message.render("Deleted #{title}"))
            else
              nil
            end
          else
            nil
          end
        else
          nil
        end
      else
        nil
      end
    end

    help = [@delegate_keys.choose, @delegate_keys.remove]
    delegate.short_help_func = -> { help }
    delegate.full_help_func = -> { [help] }

    grocery_list = Bubbles::List.new(items, delegate, 0, 0)
    grocery_list.title = "Groceries"
    grocery_list.styles.title = @styles.title
    grocery_list.additional_full_help_keys = -> {
      [
        @keys.toggle_spinner,
        @keys.insert_item,
        @keys.toggle_title_bar,
        @keys.toggle_status_bar,
        @keys.toggle_pagination,
        @keys.toggle_help_menu,
      ]
    }

    @list = grocery_list
  end

  def init : Tea::Cmd?
    Tea.request_background_color
  end

  private def update_list_properties
    h, v = @styles.app.get_frame_size
    @list.set_size(@width - h, @height - v)

    @styles = ListFancyStyles.new_styles(@dark_bg)
    @list.styles.title = @styles.title
  end

  def update(msg : Tea::Msg) : {Tea::Model, Tea::Cmd?}
    case bg = msg
    when Tea::BackgroundColorMsg
      @dark_bg = bg.is_dark?
      update_list_properties
      return {self, nil}
    when Tea::WindowSizeMsg
      @width = bg.width
      @height = bg.height
      update_list_properties
      return {self, nil}
    end

    if key_msg = msg.as?(Tea::KeyPressMsg)
      if @list.filter_state == Bubbles::List::FilterState::Filtering
        # Match Go behavior: do not handle extra key bindings while filtering.
      else
        if Bubbles::Key.matches?(key_msg, @keys.toggle_spinner)
          return {self, @list.toggle_spinner}
        end

        if Bubbles::Key.matches?(key_msg, @keys.toggle_title_bar)
          visible = !@list.show_title
          @list.set_show_title(visible)
          @list.set_show_filter(visible)
          @list.set_filtering_enabled(visible)
          return {self, nil}
        end

        if Bubbles::Key.matches?(key_msg, @keys.toggle_status_bar)
          @list.set_show_status_bar(!@list.show_status_bar)
          return {self, nil}
        end

        if Bubbles::Key.matches?(key_msg, @keys.toggle_pagination)
          @list.set_show_pagination(!@list.show_pagination)
          return {self, nil}
        end

        if Bubbles::Key.matches?(key_msg, @keys.toggle_help_menu)
          @list.set_show_help(!@list.show_help)
          return {self, nil}
        end

        if Bubbles::Key.matches?(key_msg, @keys.insert_item)
          @delegate_keys.remove.set_enabled(true)
          new_item = @item_generator.next
          ins_cmd = @list.insert_item(0, new_item)
          status_cmd = @list.new_status_message(@styles.status_message.render("Added #{new_item.title}"))
          return {self, Tea.batch(ins_cmd, status_cmd)}
        end
      end
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : Tea::View
    v = Tea.new_view(@styles.app.render(@list.view))
    v.alt_screen = true
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end

  program = Tea::Program.new(ListFancyModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
