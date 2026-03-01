require "../src/bubbletea"
require "../lib/lipgloss/src/lipgloss"

class PagerViewport
  alias GutterFunc = Proc(Bool, Int32, Int32, String)
  alias Row = NamedTuple(text: String, index: Int32, soft: Bool)
  GUTTER_WIDTH = 7

  property width : Int32
  property height : Int32
  property y_position : Int32 = 0
  property left_gutter_func : GutterFunc = ->(_soft : Bool, _index : Int32, _total : Int32) { "" }
  property highlight_style : Lipgloss::Style = Lipgloss::Style.new
  property selected_highlight_style : Lipgloss::Style = Lipgloss::Style.new

  @content : String = ""
  @lines : Array(String) = [] of String
  @y_offset : Int32 = 0
  @selected_highlight : Int32 = -1

  def initialize(@width : Int32, @height : Int32)
  end

  def set_content(content : String)
    @content = content
    @lines = content.split('\n')
    @y_offset = @y_offset.clamp(0, max_y_offset)
  end

  def set_width(width : Int32)
    @width = width
  end

  def set_height(height : Int32)
    @height = {height, 1}.max
    @y_offset = @y_offset.clamp(0, max_y_offset)
  end

  def highlight_next
    @selected_highlight = 0
  end

  def update(msg : Tea::Msg) : Bubbletea::Cmd?
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "down", "j"
        scroll_by(1)
      when "up", "k"
        scroll_by(-1)
      when "pgdown", " "
        scroll_by(@height)
      when "pgup"
        scroll_by(-@height)
      when "ctrl+d"
        scroll_by(@height // 2)
      when "ctrl+u"
        scroll_by(-(@height // 2))
      when "g"
        @y_offset = 0
      when "G"
        @y_offset = max_y_offset
      end
    when Bubbletea::MouseWheelMsg
      if msg.wheel_down?
        scroll_by(3)
      elsif msg.wheel_up?
        scroll_by(-3)
      end
    end
    nil
  end

  def view : String
    rows = rendered_rows
    total_lines = @lines.size
    visible = rows[@y_offset, @height]? || [] of Row
    out = [] of String

    visible.each do |row|
      gutter = @left_gutter_func.call(row[:soft], row[:index], total_lines)
      out << "#{gutter}#{pad_to_width(row[:text], content_width)}"
    end

    if visible.size < @height
      (visible.size...@height).each do |i|
        index = @y_offset + i
        gutter = @left_gutter_func.call(false, index, total_lines)
        out << "#{gutter}#{pad_to_width("", content_width)}"
      end
    end

    out.join("\n")
  end

  def scroll_percent : Float64
    max = max_y_offset
    return 0.0 if max <= 0
    @y_offset.to_f / max.to_f
  end

  def horizontal_scroll_percent : Float64
    1.0
  end

  private def scroll_by(delta : Int32)
    @y_offset = (@y_offset + delta).clamp(0, max_y_offset)
  end

  private def rendered_rows : Array(Row)
    rows = [] of Row
    content_width = self.content_width
    match_index = 0

    @lines.each_with_index do |line, line_idx|
      clipped = clip_to_width(line, content_width)
      highlighted, match_index = highlight_line(clipped, match_index)
      rows << {text: highlighted, index: line_idx, soft: false}
    end

    rows
  end

  private def highlight_line(line : String, start_index : Int32) : {String, Int32}
    regex = /artichoke/
    cursor = 0
    idx = start_index
    rendered = String.build do |io|
      while match = regex.match(line, cursor)
        io << line[cursor, match.begin(0) - cursor]
        token = match[0]
        style = idx == @selected_highlight ? @selected_highlight_style : @highlight_style
        io << style.render(token)
        cursor = match.end(0)
        idx += 1
      end
      io << line[cursor..] if cursor < line.size
    end
    {rendered, idx}
  end

  private def max_y_offset : Int32
    {rendered_rows.size - @height, 0}.max
  end

  private def content_width : Int32
    {@width - GUTTER_WIDTH, 1}.max
  end

  private def pad_to_width(text : String, width : Int32) : String
    w = Lipgloss::Text.width(text)
    return text if w >= width
    text + (" " * (width - w))
  end

  private def clip_to_width(line : String, width : Int32) : String
    return "" if width <= 0 || line.empty?
    current = 0
    String.build do |io|
      line.each_grapheme do |g|
        gs = g.to_s
        gw = Lipgloss::Text.width(gs)
        break if current + gw > width
        io << gs
        current += gw
      end
    end
  end
end

class PagerModel
  include Bubbletea::Model
  TITLE_BORDER = begin
    border = Lipgloss::Border.rounded
    border.right = "├"
    border
  end
  INFO_BORDER = begin
    border = Lipgloss::Border.rounded
    border.left = "┤"
    border
  end
  TITLE_STYLE = Lipgloss::Style.new.border(TITLE_BORDER).padding(0, 1)
  INFO_STYLE  = Lipgloss::Style.new.border(INFO_BORDER).padding(0, 1)
  @content : String
  @viewport : PagerViewport

  def initialize(@content = default_content)
    @ready = false
    @viewport = PagerViewport.new(0, 0)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      end
    when Bubbletea::WindowSizeMsg
      header_height = Lipgloss::Text.height(header_view)
      footer_height = Lipgloss::Text.height(footer_view)
      vertical_margin_height = header_height + footer_height

      if !@ready
        @viewport = PagerViewport.new(msg.width, {msg.height - vertical_margin_height, 1}.max)
        @viewport.y_position = header_height
        @viewport.left_gutter_func = ->(soft : Bool, index : Int32, total : Int32) do
          if soft
            "     │ "
          elsif index >= total
            "   ~ │ "
          else
            "%4d │ " % {index + 1}
          end
        end
        @viewport.highlight_style = Lipgloss::Style.new.foreground("238").background("34")
        @viewport.selected_highlight_style = Lipgloss::Style.new.foreground("238").background("47")
        @viewport.set_content(@content)
        @viewport.highlight_next
        @ready = true
      else
        @viewport.set_width(msg.width)
        @viewport.set_height({msg.height - vertical_margin_height, 1}.max)
      end
    end

    cmd = @viewport.update(msg)
    {self, cmd}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("")
    v.alt_screen = true
    v.mouse_mode = Bubbletea::MouseMode::CellMotion

    unless @ready
      v.content = "\n  Initializing..."
      return v
    end

    v.content = [header_view, @viewport.view, footer_view].join("\n")
    v
  end

  private def header_view : String
    title = TITLE_STYLE.render("Mr. Pager")
    line = "─" * {@viewport.width - Lipgloss::Text.width(title), 0}.max
    Lipgloss.join_horizontal(Lipgloss::Position::Center, title, line)
  end

  private def footer_view : String
    vertical_percent = @viewport.scroll_percent * 100.0
    horizontal_percent = @viewport.horizontal_scroll_percent * 100.0
    info = INFO_STYLE.render(sprintf("%3.0f%%:%3.0f%%", vertical_percent, horizontal_percent))
    line = "─" * {@viewport.width - Lipgloss::Text.width(info), 0}.max
    Lipgloss.join_horizontal(Lipgloss::Position::Center, line, info)
  end

  private def default_content : String
    path = File.join(__DIR__, "artichoke.md")
    return File.read(path) if File.exists?(path)
    (1..200).map { |i| "%4d | artichoke line %d" % {i, i} }.join("\n")
  end
end

if PROGRAM_NAME == __FILE__
  program = Bubbletea::Program.new(PagerModel.new)
  _model, err = program.run
  if err
    STDERR.puts "could not run program: #{err.message}"
    exit 1
  end
end
