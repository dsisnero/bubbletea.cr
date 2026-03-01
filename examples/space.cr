require "../src/bubbletea"

struct SpaceTickMsg
  include Tea::Msg
end

private def space_tick_cmd : Bubbletea::Cmd
  Bubbletea.tick((1.0 / 60).seconds, ->(_t : Time) { SpaceTickMsg.new.as(Tea::Msg?) })
end

class SpaceModel
  include Bubbletea::Model

  def initialize
    @last_width = 0
    @last_height = 0
    @frame_count = 0
    @width = 0
    @height = 0
    @shade = [] of Array(Int32)
  end

  def init : Bubbletea::Cmd?
    space_tick_cmd
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit} if msg.keystroke.in?({"q", "ctrl+c"})
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      if @width != @last_width || @height != @last_height
        setup_shade
        @last_width = @width
        @last_height = @height
      end
    when SpaceTickMsg
      @frame_count += 1
      return {self, space_tick_cmd}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    title = "Space"
    rows = [] of String
    visible_h = {@height - 1, 0}.max

    (0...visible_h).each do |y|
      row = String.build do |io|
        (0...@width).each do |x|
          xi = @width > 0 ? (x + @frame_count) % @width : 0
          shade = @shade.dig?(y, xi) || 0
          io << shade_char(shade)
        end
      end
      rows << row
    end

    content = ([title] + rows).join("\n")
    v = Bubbletea::View.new(content)
    v.alt_screen = true
    v
  end

  private def setup_shade
    h = @height
    @shade = Array.new(h) do |y|
      Array.new(@width) do
        base = (h > 0 ? (h - y).to_f / h : 0.0)
        value = (base + (Random.rand * 0.2) - 0.1).clamp(0.0, 1.0)
        (value * 9).to_i
      end
    end
  end

  private def shade_char(level : Int32) : Char
    chars = " .:-=+*#%@"
    chars[level.clamp(0, chars.size - 1)]
  end
end

program = Bubbletea.new_program(SpaceModel.new, Bubbletea.with_fps(120))
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
