require "../lib/bubbles/src/bubbles"
require "lipgloss"

class PagerModel
  include Tea::Model

  TITLE_BORDER = begin
    b = Lipgloss::Border.rounded
    b.right = "├"
    b
  end

  TITLE_STYLE = Lipgloss::Style.new.border_style(TITLE_BORDER).padding(0, 1)

  INFO_STYLE = begin
    b = Lipgloss::Border.rounded
    b.left = "┤"
    Lipgloss::Style.new.border_style(b).padding(0, 1)
  end

  @content : String
  @ready : Bool
  @viewport : Bubbles::Viewport::Model

  def initialize(@content : String = default_content)
    @ready = false
    @viewport = Bubbles::Viewport.new(
      Bubbles::Viewport.with_width(0),
      Bubbles::Viewport.with_height(0)
    )
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    cmds = [] of Tea::Cmd?

    case msg
    when Tea::KeyPressMsg
      key = msg.string
      if key == "ctrl+c" || key == "q" || key == "esc"
        return {self, Tea.quit}
      end
    when Tea::WindowSizeMsg
      header_height = Lipgloss.height(header_view)
      footer_height = Lipgloss.height(footer_view)
      vertical_margin_height = header_height + footer_height

      if !@ready
        @viewport = Bubbles::Viewport.new(
          Bubbles::Viewport.with_width(msg.width),
          Bubbles::Viewport.with_height(msg.height - vertical_margin_height)
        )
        @viewport.y_position = header_height
        @viewport.left_gutter_func = ->(info : Bubbles::Viewport::GutterContext) do
          if info.soft
            "     │ "
          elsif info.index >= info.total_lines
            "   ~ │ "
          else
            "%4d │ " % {info.index + 1}
          end
        end
        @viewport.highlight_style = Lipgloss::Style.new.foreground(Lipgloss.color("238")).background(Lipgloss.color("34"))
        @viewport.selected_highlight_style = Lipgloss::Style.new.foreground(Lipgloss.color("238")).background(Lipgloss.color("47"))
        @viewport.set_content(@content)
        @viewport.set_highlights(find_all_string_index(@content, /artichoke/))
        @viewport.highlight_next
        @ready = true
      else
        @viewport.set_width(msg.width)
        @viewport.set_height(msg.height - vertical_margin_height)
      end
    end

    @viewport, cmd = @viewport.update(msg)
    cmds << cmd

    {self, Tea.batch(cmds)}
  end

  def view : Tea::View
    v = Tea.new_view("")
    v.alt_screen = true
    v.mouse_mode = Tea::MouseMode::CellMotion

    if !@ready
      v.content = "\n  Initializing..."
    else
      v.content = "#{header_view}\n#{@viewport.view}\n#{footer_view}"
    end

    v
  end

  private def header_view : String
    title = TITLE_STYLE.render("Mr. Pager")
    line = "─" * ({@viewport.width - Lipgloss.width(title), 0}.max)
    Lipgloss.join_horizontal(Lipgloss::Position::Center, title, line)
  end

  private def footer_view : String
    info = INFO_STYLE.render(sprintf("%3.0f%%:%3.0f%%", @viewport.scroll_percent * 100.0, @viewport.horizontal_scroll_percent * 100.0))
    line = "─" * ({@viewport.width - Lipgloss.width(info), 0}.max)
    Lipgloss.join_horizontal(Lipgloss::Position::Center, line, info)
  end

  private def default_content : String
    path = File.join(__DIR__, "artichoke.md")
    return File.read(path) if File.exists?(path)
    raise "could not load file: #{path}"
  end

  private def find_all_string_index(content : String, regex : Regex) : Array(Array(Int32))
    matches = [] of Array(Int32)
    offset = 0

    while match = regex.match(content, offset)
      start = match.byte_begin(0)
      finish = match.byte_end(0)
      matches << [start.to_i32, finish.to_i32]
      next_offset = match.end(0)
      break if next_offset <= offset
      offset = next_offset
    end

    matches
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end

  program = Tea::Program.new(PagerModel.new)
  _model, err = program.run
  if err
    STDERR.puts "could not run program: #{err.message}"
    exit 1
  end
end
