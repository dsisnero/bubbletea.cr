require "../src/bubbletea"

PALETTE = [' ', '.', ':', '-', '=', '+', '*', '#', '%', '@']

struct FireTickMsg
  include Tea::Msg
end

private def fire_tick : Bubbletea::Cmd
  Bubbletea.tick(50.milliseconds, ->(_time : Time) { FireTickMsg.new.as(Tea::Msg?) })
end

class DoomFireModel
  include Bubbletea::Model

  def initialize
    @screen_buf = [] of Int32
    @width = 0
    @height = 0
    @start_time = Time.utc
  end

  def init : Bubbletea::Cmd?
    fire_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      if msg.keystroke.in?({"q", "ctrl+c"})
        return {self, Bubbletea.quit}
      end
    when FireTickMsg
      spread_fire
      return {self, fire_tick}
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height * 2
      @screen_buf = Array.new(@width * @height, 0)

      bottom_row = @height - 1
      (0...@width).each do |x|
        @screen_buf[bottom_row * @width + x] = PALETTE.size - 1
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("Initializing...") if @width == 0 || @height == 0

    s = String.build do |io|
      y = 0
      while y < @height - 1
        x = 0
        while x < @width
          pixel_hi = @screen_buf[y * @width + x]
          pixel_lo = @screen_buf[(y + 1) * @width + x]
          char = if pixel_hi >= pixel_lo
                   PALETTE[pixel_hi]
                 else
                   PALETTE[pixel_lo]
                 end
          io << char
          x += 1
        end
        io << '\n' if y < @height - 2
        y += 2
      end

      elapsed = Time.utc - @start_time
      io << "Press q or ctrl+c to quit. Elapsed: #{elapsed.total_seconds.to_i}s"
    end

    v = Bubbletea::View.new(s)
    v.alt_screen = true
    v
  end

  private def spread_fire
    return if @width <= 0 || @height <= 0 || @screen_buf.empty?

    (0...@width).each do |x|
      (0...@height).each do |y|
        spread_pixel(y * @width + x)
      end
    end
  end

  private def spread_pixel(idx : Int32)
    return if idx < @width

    pixel = @screen_buf[idx]
    if pixel == 0
      @screen_buf[idx - @width] = 0
      return
    end

    rnd = Random.rand(3)
    dst = idx - rnd + 1
    target = dst - @width
    return if target < 0 || target >= @screen_buf.size

    decay = rnd & 1
    new_value = {pixel - decay, 0}.max
    @screen_buf[target] = new_value
  end
end

program = Bubbletea::Program.new(DoomFireModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
