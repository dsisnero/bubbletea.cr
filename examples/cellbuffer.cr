require "../src/bubbletea"

FPS       =   60
FREQUENCY =  7.5
DAMPING   = 0.15
ASTERISK  = "*"

private def draw_ellipse(cb : CellBuffer, xc : Float64, yc : Float64, rx : Float64, ry : Float64)
  dx = 0.0
  dy = 0.0
  d1 = 0.0
  d2 = 0.0
  x = 0.0
  y = ry

  d1 = ry * ry - rx * rx * ry + 0.25 * rx * rx
  dx = 2 * ry * ry * x
  dy = 2 * rx * rx * y

  while dx < dy
    cb.set((x + xc).to_i, (y + yc).to_i)
    cb.set((-x + xc).to_i, (y + yc).to_i)
    cb.set((x + xc).to_i, (-y + yc).to_i)
    cb.set((-x + xc).to_i, (-y + yc).to_i)

    if d1 < 0
      x += 1
      dx += 2 * ry * ry
      d1 += dx + ry * ry
    else
      x += 1
      y -= 1
      dx += 2 * ry * ry
      dy -= 2 * rx * rx
      d1 += dx - dy + ry * ry
    end
  end

  d2 = ((ry * ry) * ((x + 0.5) * (x + 0.5))) + ((rx * rx) * ((y - 1) * (y - 1))) - (rx * rx * ry * ry)

  while y >= 0
    cb.set((x + xc).to_i, (y + yc).to_i)
    cb.set((-x + xc).to_i, (y + yc).to_i)
    cb.set((x + xc).to_i, (-y + yc).to_i)
    cb.set((-x + xc).to_i, (-y + yc).to_i)

    if d2 > 0
      y -= 1
      dy -= 2 * rx * rx
      d2 += rx * rx - dy
    else
      y -= 1
      x += 1
      dx += 2 * ry * ry
      dy -= 2 * rx * rx
      d2 += dx - dy + rx * rx
    end
  end
end

class CellBuffer
  @cells : Array(String) = [] of String
  @stride : Int32 = 0

  def init(width : Int32, height : Int32)
    return if width == 0
    @stride = width
    @cells = Array.new(width * height, " ")
  end

  def set(x : Int32, y : Int32)
    i = y * @stride + x
    return if i > @cells.size - 1 || x < 0 || y < 0 || x >= self.width || y >= self.height
    @cells[i] = ASTERISK
  end

  def wipe
    @cells.map! { " " }
  end

  def width : Int32
    @stride
  end

  def height : Int32
    return 0 if @stride <= 0
    h = @cells.size // @stride
    h += 1 if @cells.size % @stride != 0
    h
  end

  def ready? : Bool
    !@cells.empty?
  end

  def to_s(io : IO)
    @cells.each_with_index do |cell, i|
      if i > 0 && i % @stride == 0 && i < @cells.size - 1
        io << '\n'
      end
      io << cell
    end
  end
end

struct FrameMsg
  include Tea::Msg
end

private def animate : Bubbletea::Cmd
  Bubbletea.tick((1.0 / FPS).seconds, ->(_time : Time) { FrameMsg.new.as(Tea::Msg?) })
end

class CellBufferModel
  include Bubbletea::Model
  @spring_fps : Float64
  @spring_frequency : Float64
  @spring_damping : Float64

  def initialize
    @cells = CellBuffer.new
    @target_x = 0.0
    @target_y = 0.0
    @x = 0.0
    @y = 0.0
    @x_velocity = 0.0
    @y_velocity = 0.0
    @spring_fps = FPS.to_f
    @spring_frequency = FREQUENCY.to_f
    @spring_damping = DAMPING.to_f
  end

  def init : Bubbletea::Cmd?
    animate
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      unless @cells.ready?
        @target_x = msg.width.to_f / 2.0
        @target_y = msg.height.to_f / 2.0
      end
      @cells.init(msg.width, msg.height)
      {self, nil}
    when Bubbletea::MouseClickMsg, Bubbletea::MouseMotionMsg
      return {self, nil} unless @cells.ready?
      mouse = msg.mouse
      @target_x = mouse.x.to_f
      @target_y = mouse.y.to_f
      {self, nil}
    when FrameMsg
      return {self, nil} unless @cells.ready?

      @cells.wipe
      @x, @x_velocity = update_spring(@x, @x_velocity, @target_x)
      @y, @y_velocity = update_spring(@y, @y_velocity, @target_y)
      draw_ellipse(@cells, @x, @y, 16.0, 8.0)
      {self, animate}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new(@cells.to_s)
    v.alt_screen = true
    v.mouse_mode = Bubbletea::MouseMode::CellMotion
    v
  end

  private def update_spring(position : Float64, velocity : Float64, target : Float64) : {Float64, Float64}
    dt = 1.0 / @spring_fps
    omega = 2.0 * Math::PI * @spring_frequency
    zeta = @spring_damping
    f = 1.0 + 2.0 * dt * zeta * omega
    oo = omega * omega
    hoo = dt * oo
    hhoo = dt * hoo
    det_inv = 1.0 / (f + hhoo)
    det_x = f * position + dt * velocity + hhoo * target
    det_v = velocity + hoo * (target - position)
    new_pos = det_x * det_inv
    new_vel = det_v * det_inv
    {new_pos, new_vel}
  end
end

if PROGRAM_NAME == __FILE__
  program = Bubbletea::Program.new(CellBufferModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Uh oh: #{err.message}"
    exit 1
  end
end
