require "../src/bubbletea"

struct DelegateKeyMap
  getter choose = {"enter"}
  getter remove = {"x", "backspace"}

  def short_help : Array(String)
    ["enter: choose", "x: delete"]
  end

  def full_help : Array(Array(String))
    [short_help]
  end
end

struct ListFancyItem
  getter title : String
  getter description_text : String

  def initialize(@title : String, @description_text : String)
  end

  def description : String
    @description_text
  end

  def filter_value : String
    @title
  end
end

class ListFancyModel
  include Bubbletea::Model

  def initialize
    @items = [
      ListFancyItem.new("Milk", "Whole milk"),
      ListFancyItem.new("Eggs", "Free-range"),
      ListFancyItem.new("Bread", "Sourdough"),
    ]
    @idx = 0
    @keys = DelegateKeyMap.new
    @status = ""
    @show_help = true
  end

  def init : Bubbletea::Cmd?
    Tea.request_background_color
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::BackgroundColorMsg
      {self, nil}
    when Bubbletea::WindowSizeMsg
      {self, nil}
    when Bubbletea::KeyPressMsg
      key = msg.string_with_mods
      case key
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      when "up", "k"
        @idx -= 1
        @idx = 0 if @idx < 0
      when "down", "j"
        @idx += 1
        @idx = @items.size - 1 if @idx >= @items.size
      when "H"
        @show_help = !@show_help
      when "a"
        new_item = ListFancyItem.new("Item #{@items.size + 1}", "Generated item")
        @items.unshift(new_item)
        @idx = 0
        @status = "Added #{new_item.title}"
      when "enter"
        if current = @items[@idx]?
          @status = "You chose #{current.title}"
        end
      when "x", "backspace"
        if current = @items[@idx]?
          removed = current.title
          @items.delete_at(@idx)
          @idx = {@idx, @items.size - 1}.min
          @idx = 0 if @idx < 0
          @status = "Deleted #{removed}"
        end
      end
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    body = String.build do |io|
      io << "Groceries\n\n"
      @items.each_with_index do |item, i|
        prefix = i == @idx ? "> " : "  "
        io << prefix << item.title << "\n"
        io << "    " << item.description << "\n"
      end

      io << "\n#{@status}\n" unless @status.empty?

      if @show_help
        io << "\n"
        @keys.full_help.each do |row|
          io << row.join(" • ") << "\n"
        end
        io << "a: add • H: toggle help • q: quit\n"
      end
    end

    v = Bubbletea::View.new(body)
    v.alt_screen = true
    v
  end
end

program = Bubbletea::Program.new(ListFancyModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
