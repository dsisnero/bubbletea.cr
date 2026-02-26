require "../src/bubbletea"

class PagerModel
  include Bubbletea::Model
  @content : String

  def initialize(@content = default_content)
    @ready = false
    @offset = 0
    @width = 80
    @height = 24
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      when "down", "j"
        @offset += 1
      when "up", "k"
        @offset -= 1
        @offset = 0 if @offset < 0
      end
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      @ready = true
    end

    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("")
    v.alt_screen = true
    v.mouse_mode = Bubbletea::MouseMode::CellMotion

    unless @ready
      v.content = "\n  Initializing..."
      return v
    end

    lines = @content.split('\n')
    body_height = {@height - 2, 1}.max
    max_offset = {lines.size - body_height, 0}.max
    @offset = max_offset if @offset > max_offset
    visible = lines[@offset, body_height]? || [] of String

    title = "Mr. Pager"
    header = title + " " + "-" * {@width - title.size - 1, 0}.max
    footer = "-" * {@width - 12, 0}.max + " #{@offset}/#{max_offset}"

    v.content = [header, visible.join("\n"), footer].join("\n")
    v
  end

  private def default_content : String
    (1..200).map { |i| "%4d | artichoke line %d" % {i, i} }.join("\n")
  end
end

program = Bubbletea::Program.new(PagerModel.new)
_model, err = program.run
if err
  STDERR.puts "could not run program: #{err.message}"
  exit 1
end
