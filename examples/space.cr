require "../src/bubbletea"
require "lipgloss"

struct SpaceTickMsg
  include Tea::Msg
end

private def space_tick_cmd : Bubbletea::Cmd
  Bubbletea.tick((1.0 / 60).seconds, ->(_t : Time) { SpaceTickMsg.new.as(Tea::Msg?) })
end

class SpaceModel
  include Bubbletea::Model

  property width : Int32
  property height : Int32
  property frame_count : Int32

  def initialize(@rng : Random = Random.new)
    @colors = [] of Array(String)
    @last_width = 0
    @last_height = 0
    @frame_count = 0
    @width = 0
    @height = 0
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(space_tick_cmd)
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit} if msg.keystroke.in?({"q", "ctrl+c"})
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      if @width != @last_width || @height != @last_height
        setup_colors
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
    title = Lipgloss::Style.new.bold(true).render("Space")

    io = String::Builder.new
    visible_height = @height - 1
    visible_height = 0 if visible_height < 0

    (0...visible_height).each do |y|
      (0...@width).each do |x|
        xi = (x + @frame_count) % @width
        fg = @colors[y * 2][xi]
        bg = @colors[y * 2 + 1][xi]
        io << Lipgloss::Style.new.foreground(fg).background(bg).render("▀")
      end
      io << '\n' if y < visible_height - 1
    end

    Bubbletea::View.new([title, io.to_s].join("\n")).tap { |v| v.alt_screen = true }
  end

  private def setup_colors
    h = @height * 2
    @colors = Array.new(h) { Array.new(@width, "#000000") }

    (0...h).each do |y|
      randomness_factor = h > 0 ? (h - y).to_f / h.to_f : 0.0
      (0...@width).each do |x|
        base_value = randomness_factor * (h > 0 ? (h - y).to_f / h.to_f : 0.0)
        random_offset = (@rng.rand * 0.2) - 0.1
        value = clamp(base_value + random_offset, 0.0, 1.0)
        gray = (value * 255.0).to_i
        @colors[y][x] = "#%02x%02x%02x" % {gray, gray, gray}
      end
    end
  end

  private def clamp(value : Float64, min : Float64, max : Float64) : Float64
    return min if value < min
    return max if value > max
    value
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea.new_program(SpaceModel.new, Bubbletea.with_fps(120))
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
