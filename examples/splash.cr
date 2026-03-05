require "../src/bubbletea"
require "lipgloss"

struct SplashTickMsg
  include Tea::Msg
end

class SplashModel
  include Bubbletea::Model

  COLORS = [
    {0x88, 0x11, 0x77},
    {0xaa, 0x33, 0x55},
    {0xcc, 0x66, 0x66},
    {0xee, 0x99, 0x44},
    {0xee, 0xdd, 0x00},
    {0x99, 0xdd, 0x55},
    {0x44, 0xdd, 0x88},
    {0x22, 0xcc, 0xbb},
    {0x00, 0xbb, 0xcc},
    {0x00, 0x99, 0xcc},
    {0x33, 0x66, 0xbb},
    {0x66, 0x33, 0x99},
  ]

  property rate : Int64

  def initialize(@rate : Int64 = 90_i64)
    @width = 0
    @height = 0
  end

  def init : Bubbletea::Cmd?
    tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
    when SplashTickMsg
      return {self, tick}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new
    v.alt_screen = true
    if @width == 0
      v.set_content("Initializing...")
      return v
    end

    v.set_content(gradient)
    v
  end

  private def tick : Bubbletea::Cmd
    -> { SplashTickMsg.new.as(Tea::Msg?) }
  end

  private def gradient : String
    t = (current_time_ns.to_f * @rate.to_f) / 1_000_000_000_f64
    angle_radians = -t * Math::PI / 180.0
    sin_angle = Math.sin(angle_radians)
    cos_angle = Math.cos(angle_radians)

    center_x = @width.to_f / 2.0
    center_y = @height.to_f

    String.build do |output|
      (0...@height).each do |line_y|
        point_y = line_y.to_f * 2.0 - center_y
        point_x = -center_x

        x1 = (center_x + (point_x * cos_angle - point_y * sin_angle)) / @width.to_f
        x2 = (center_x + (point_x * cos_angle - (point_y + 1.0) * sin_angle)) / @width.to_f

        point_x = @width.to_f - center_x
        end_x1 = (center_x + (point_x * cos_angle - point_y * sin_angle)) / @width.to_f
        delta_x = (end_x1 - x1) / @width.to_f

        if delta_x.abs < 0.0001
          color1 = get_gradient_color(x1)
          color2 = get_gradient_color(x2)
          style = Lipgloss::Style.new.foreground(color1).background(color2)
          output << style.render("▀" * @width)
        else
          (0...@width).each do |x|
            pos1 = x1 + x.to_f * delta_x
            pos2 = x2 + x.to_f * delta_x
            color1 = get_gradient_color(pos1)
            color2 = get_gradient_color(pos2)
            style = Lipgloss::Style.new.foreground(color1).background(color2)
            output << style.render("▀")
          end
        end

        output << '\n' if line_y < @height - 1
      end
    end
  end

  private def get_gradient_color(position : Float64) : String
    position = 0.0 if position <= 0.0
    position = 1.0 if position >= 1.0

    idx = position * (COLORS.size - 1).to_f
    i1 = idx.floor.to_i
    i2 = idx.ceil.to_i

    i1 = i1 % COLORS.size
    i2 = i2 % COLORS.size
    i1 += COLORS.size if i1 < 0
    i2 += COLORS.size if i2 < 0

    t = idx - i1.to_f
    rgb_to_hex(interpolate_colors(COLORS[i1], COLORS[i2], t))
  end

  private def interpolate_colors(
    c1 : Tuple(Int32, Int32, Int32),
    c2 : Tuple(Int32, Int32, Int32),
    t : Float64
  ) : Tuple(Int32, Int32, Int32)
    r = (c1[0].to_f * (1.0 - t) + c2[0].to_f * t).to_i
    g = (c1[1].to_f * (1.0 - t) + c2[1].to_f * t).to_i
    b = (c1[2].to_f * (1.0 - t) + c2[2].to_f * t).to_i
    {r, g, b}
  end

  private def rgb_to_hex(rgb : Tuple(Int32, Int32, Int32)) : String
    "#%02X%02X%02X" % {rgb[0], rgb[1], rgb[2]}
  end

  protected def current_time_ns : Int64
    Time.utc.to_unix_ns.to_i64
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(SplashModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
