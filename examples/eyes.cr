require "../src/bubbletea"

EYE_WIDTH    = 15
EYE_HEIGHT   = 12
EYE_SPACING  = 40
BLINK_FRAMES = 20
OPEN_TIME_MIN_MS = 1000
OPEN_TIME_MAX_MS = 4000

struct EyesTickMsg
  include Tea::Msg
end

private def eyes_tick : Bubbletea::Cmd
  Bubbletea.tick(50.milliseconds, ->(_t : Time) { EyesTickMsg.new.as(Tea::Msg?) })
end

class EyesModel
  include Bubbletea::Model

  def initialize
    @width = 80
    @height = 24
    @eye_positions = {0, 0}
    @eye_y = 0
    @is_blinking = false
    @blink_state = 0
    @last_blink = Time.utc
    @open_time = random_open_time
    update_eye_positions
  end

  def init : Bubbletea::Cmd?
    eyes_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      if msg.string_with_mods.in?({"ctrl+c", "esc"})
        return {self, Bubbletea.quit}
      end
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      update_eye_positions
    when EyesTickMsg
      current_time = Time.utc

      if !@is_blinking && (current_time - @last_blink) >= @open_time
        @is_blinking = true
        @blink_state = 0
      end

      if @is_blinking
        @blink_state += 1

        if @blink_state >= BLINK_FRAMES
          @is_blinking = false
          @last_blink = current_time
          @open_time = random_open_time
          @open_time = 300.milliseconds if Random.rand(10) == 0
        end
      end
    end

    {self, eyes_tick}
  end

  def view : Bubbletea::View
    canvas = Array.new(@height) { Array.new(@width, ' ') }

    current_height = EYE_HEIGHT
    if @is_blinking
      if @blink_state < BLINK_FRAMES // 2
        progress = @blink_state.to_f / (BLINK_FRAMES // 2).to_f
        progress = 1.0 - (progress * progress)
        current_height = {1, (EYE_HEIGHT.to_f * progress).to_i}.max
      else
        progress = (@blink_state - BLINK_FRAMES // 2).to_f / (BLINK_FRAMES // 2).to_f
        progress = progress * (2.0 - progress)
        current_height = {1, (EYE_HEIGHT.to_f * progress).to_i}.max
      end
    end

    draw_ellipse(canvas, @eye_positions[0], @eye_y, EYE_WIDTH, current_height)
    draw_ellipse(canvas, @eye_positions[1], @eye_y, EYE_WIDTH, current_height)

    content = canvas.map { |row| String.build { |io| row.each { |c| io << c } } }.join("\n")

    v = Bubbletea::View.new(content)
    v.alt_screen = true
    v
  end

  private def random_open_time : Time::Span
    (Random.rand(OPEN_TIME_MAX_MS - OPEN_TIME_MIN_MS) + OPEN_TIME_MIN_MS).milliseconds
  end

  private def update_eye_positions
    start_x = (@width - EYE_SPACING) // 2
    @eye_y = @height // 2
    @eye_positions = {start_x, start_x + EYE_SPACING}
  end

  private def draw_ellipse(canvas : Array(Array(Char)), x0 : Int32, y0 : Int32, rx : Int32, ry : Int32)
    return if ry <= 0

    (-ry..ry).each do |y|
      ratio = y.to_f / ry.to_f
      width = (rx.to_f * Math.sqrt(1.0 - ratio * ratio)).to_i

      (-width..width).each do |x|
        cx = x0 + x
        cy = y0 + y
        next if cy < 0 || cy >= canvas.size
        next if cx < 0 || cx >= canvas[cy].size
        canvas[cy][cx] = '●'
      end
    end
  end
end

program = Bubbletea::Program.new(EyesModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
