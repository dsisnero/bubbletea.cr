require "../src/bubbletea"

struct LayerHitMsg
  include Tea::Msg
  getter id : String
  getter mouse : Bubbletea::MouseMsg

  def initialize(@id : String, @mouse : Bubbletea::MouseMsg)
  end
end

MAX_DIALOGS = 999

class Dialog
  property id : String = ""
  property button_id : String = ""
  property x : Int32 = 0
  property y : Int32 = 0
  property text : String = ""
  property hovering : Bool = false
  property hovering_button : Bool = false

  WINDOW_WIDTH  = 36
  WINDOW_HEIGHT =  8

  def button_label : String
    "Run Away"
  end

  def button_x : Int32
    WINDOW_WIDTH - button_label.size - 5
  end

  def button_y : Int32
    WINDOW_HEIGHT - 2
  end

  def contains?(x : Int32, y : Int32) : Bool
    x >= @x && x < @x + WINDOW_WIDTH && y >= @y && y < @y + WINDOW_HEIGHT
  end

  def button_contains?(x : Int32, y : Int32) : Bool
    bx = @x + button_x
    by = @y + button_y
    x >= bx && x < bx + button_label.size + 2 && y == by
  end

  def render_lines : Array(String)
    top = "+" + "-" * (WINDOW_WIDTH - 2) + "+"
    middle = Array.new(WINDOW_HEIGHT - 2, "|" + " " * (WINDOW_WIDTH - 2) + "|")
    bottom = "+" + "-" * (WINDOW_WIDTH - 2) + "+"

    lines = [top] + middle + [bottom]

    body = "#{@text} draws near. Command?"
    body = body[0, WINDOW_WIDTH - 4]? || body
    lines[2] = "| " + body.ljust(WINDOW_WIDTH - 4) + " |"

    btn = @hovering_button ? "[#{button_label}]" : " #{button_label} "
    left = button_x
    right = WINDOW_WIDTH - 2 - left - btn.size
    lines[button_y] = "|" + " " * left + btn + " " * right + "|"
    lines
  end
end

class ClickableModel
  include Bubbletea::Model

  @@id_counter = 0

  def initialize
    @width = 0
    @height = 0
    @dialogs = [] of Dialog
    @mouse_down = false
    @press_id = ""
    @drag_id = ""
    @drag_offset_x = 0
    @drag_offset_y = 0
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c", "esc"
        return {self, Bubbletea.quit}
      end
    when LayerHitMsg
      mouse = msg.mouse.mouse

      case msg.mouse
      when Bubbletea::MouseClickMsg
        return {self, nil} if mouse.button != Tea::MouseLeft

        unless @mouse_down
          @mouse_down = true
          @press_id = msg.id

          @dialogs.each_with_index do |dialog, idx|
            next unless dialog.id == msg.id

            @drag_id = msg.id
            @drag_offset_x = mouse.x - dialog.x
            @drag_offset_y = mouse.y - dialog.y

            if @dialogs.size >= 2
              dragged = @dialogs.delete_at(idx)
              @dialogs << dragged if dragged
            end
            break
          end
        end
      when Bubbletea::MouseMotionMsg
        if @mouse_down && !@drag_id.empty?
          @dialogs.each do |dialog|
            next unless dialog.id == @drag_id

            dialog.x = clamp(mouse.x - @drag_offset_x, 0, @width - Dialog::WINDOW_WIDTH)
            dialog.y = clamp(mouse.y - @drag_offset_y, 0, @height - Dialog::WINDOW_HEIGHT)
            break
          end
        end

        @dialogs.each do |dialog|
          dialog.hovering = false
          dialog.hovering_button = false

          if dialog.id == msg.id
            dialog.hovering = true
          elsif dialog.button_id == msg.id
            dialog.hovering = true
            dialog.hovering_button = true
          end
        end
      when Bubbletea::MouseReleaseMsg
        unless @press_id.empty?
          @dialogs.each_with_index do |dialog, idx|
            if msg.id == dialog.button_id && @press_id == dialog.button_id
              @dialogs.delete_at(idx)
              break
            end
          end

          if msg.id == "bg" && @press_id == "bg" && @dialogs.size < MAX_DIALOGS
            @dialogs << new_dialog(mouse.x, mouse.y)
          end
        end

        @mouse_down = false
        @drag_id = ""
        @press_id = ""
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    grid = Array.new(@height) { Array.new(@width, ' ') }

    header = header_text
    header.split('\n').each_with_index do |line, y|
      break if y >= @height
      line.each_char.with_index do |ch, x|
        break if x >= @width
        grid[y][x] = ch
      end
    end

    @dialogs.each do |dialog|
      lines = dialog.render_lines
      lines.each_with_index do |line, dy|
        gy = dialog.y + dy
        next if gy < 0 || gy >= @height

        line.each_char.with_index do |ch, dx|
          gx = dialog.x + dx
          next if gx < 0 || gx >= @width
          grid[gy][gx] = ch
        end
      end
    end

    content = grid.map do |row|
      String.build do |io|
        row.each { |ch| io << ch }
      end
    end.join("\n")

    v = Bubbletea::View.new(content)
    v.mouse_mode = Bubbletea::MouseMode::AllMotion
    v.alt_screen = true
    v.on_mouse = ->(message : Bubbletea::MouseMsg) : Tea::Cmd? {
      mouse = message.mouse
      id = hit_id(mouse.x, mouse.y)
      -> : Tea::Msg? { LayerHitMsg.new(id, message) }
    }
    v
  end

  private def hit_id(x : Int32, y : Int32) : String
    (@dialogs.size - 1).downto(0) do |i|
      dialog = @dialogs[i]
      return dialog.button_id if dialog.button_contains?(x, y)
      return dialog.id if dialog.contains?(x, y)
    end
    "bg"
  end

  private def header_text : String
    n = @dialogs.size
    body = String.build do |io|
      io << "Drag to move. " if n > 0

      if n == 0 && n < MAX_DIALOGS
        io << "Click to spawn."
      elsif n >= 1 && n < MAX_DIALOGS
        io << "Click to spawn up to #{MAX_DIALOGS - n} more."
      end

      io << "\n\nPress q to quit."
    end
    body
  end

  private def new_dialog(x : Int32, y : Int32) : Dialog
    dialog = Dialog.new
    dialog.x = clamp(x - (Dialog::WINDOW_WIDTH // 2), 0, @width - Dialog::WINDOW_WIDTH)
    dialog.y = clamp(y - (Dialog::WINDOW_HEIGHT // 2), 0, @height - Dialog::WINDOW_HEIGHT)
    dialog.text = next_random_word
    dialog.id = next_id
    dialog.button_id = next_id
    dialog
  end

  private def next_id : String
    @@id_counter += 1
    "dialog-#{@@id_counter}"
  end

  private def next_random_word : String
    adjectives = {
      "a hot", "a cute", "a fresh", "a nice", "a lovely", "an eager", "a soft", "an expensive", "a new", "an old",
      "a happy", "a messy", "a good", "a bad", "a cheesy", "a friendly", "a cold", "a gorgeous", "a wooden",
    }

    nouns = {
      "pear", "banana", "bowl of ramen", "currywurst", "quince", "pie", "cake", "burrito", "sushi", "burger", "computer",
    }

    adjective = adjectives.sample || "a mysterious"
    noun = nouns.sample || "artifact"
    "#{adjective} #{noun}".split.map_with_index { |word, idx| idx == 0 ? word.capitalize : word }.join(" ")
  end

  private def clamp(value : Int32, min : Int32, max : Int32) : Int32
    return min if value < min
    return max if value > max
    value
  end
end

program = Bubbletea::Program.new(ClickableModel.new)
_model, err = program.run
if err
  STDERR.puts "Error while running program: #{err.message}"
  exit 1
end
