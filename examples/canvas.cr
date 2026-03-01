require "../src/bubbletea"

class CanvasModel
  include Bubbletea::Model

  CARD_BODY_WIDTH = 20
  CARD_HEIGHT     = 10
  CARD_X_OFFSET   = 10
  CARD_Y_OFFSET   =  2
  FOOTER_HEIGHT   = 13
  FOOTER_TEXT     = "Press any key to swap the cards, or q to quit."

  def initialize(@width = 0, @flip = false, @quitting = false)
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
      when "q", "ctrl+c", "esc"
        @quitting = true
        {self, Bubbletea.quit}
      else
        @flip = !@flip
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("") if @quitting

    z = @flip ? reverse_z([0, 1]) : [0, 1]
    card_a = {render_card("Hello"), 0, 0, z[0]}
    card_b = {render_card("Goodbye"), CARD_X_OFFSET, CARD_Y_OFFSET, z[1]}
    layers = [card_a, card_b]

    width = {FOOTER_TEXT.size, CARD_X_OFFSET + card_width}.max
    height = {FOOTER_HEIGHT, CARD_Y_OFFSET + CARD_HEIGHT}.max
    canvas = Array.new(height) { Array.new(width, ' ') }

    # The Go footer is styled with height=13 and bottom alignment.
    footer_y = FOOTER_HEIGHT - 1
    FOOTER_TEXT.each_char_with_index do |char, x|
      break if x >= width
      canvas[footer_y][x] = char
    end

    layers.sort_by! { |layer| layer[3] }
    layers.each do |lines, x_offset, y_offset, _z|
      lines.each_with_index do |line, y|
        yy = y_offset + y
        next if yy < 0 || yy >= height
        line.each_char_with_index do |char, x|
          xx = x_offset + x
          next if xx < 0 || xx >= width
          next if char == ' '
          canvas[yy][xx] = char
        end
      end
    end

    content = canvas.map do |line|
      String.build do |io|
        line.each { |char| io << char }
      end.rstrip
    end.join("\n")
    Bubbletea::View.new(content)
  end

  private def card_width : Int32
    CARD_BODY_WIDTH + 2
  end

  private def render_card(text : String) : Array(String)
    top = "╭" + ("─" * CARD_BODY_WIDTH) + "╮"
    bottom = "╰" + ("─" * CARD_BODY_WIDTH) + "╯"
    rows = Array.new(CARD_HEIGHT, " " * card_width)
    rows[0] = top
    rows[CARD_HEIGHT - 1] = bottom

    text_row = (CARD_HEIGHT - 2) // 2 + 1
    inner_rows = CARD_HEIGHT - 2
    (1...inner_rows + 1).each do |row|
      content =
        if row == text_row
          center_text(text, CARD_BODY_WIDTH)
        else
          " " * CARD_BODY_WIDTH
        end
      rows[row] = "│#{content}│"
    end

    rows
  end

  private def center_text(text : String, width : Int32) : String
    pad_left = (width - text.size) // 2
    pad_right = width - text.size - pad_left
    (" " * pad_left) + text + (" " * pad_right)
  end

  private def reverse_z(values : Array(Int32)) : Array(Int32)
    count = values.size
    Array.new(count) { |i| values[count - 1 - i] }
  end
end

if PROGRAM_NAME == __FILE__
  program = Bubbletea::Program.new(CanvasModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Urgh: #{err.message}"
    exit 1
  end
end
