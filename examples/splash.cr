require "../src/bubbletea"

struct SplashTickMsg
  include Tea::Msg
end

private def splash_tick : Bubbletea::Cmd
  Bubbletea.tick(16.milliseconds, ->(_t : Time) { SplashTickMsg.new.as(Tea::Msg?) })
end

class SplashModel
  include Bubbletea::Model

  def initialize
    @width = 0
    @height = 0
    @rate = 90
    @frame = 0
  end

  def init : Bubbletea::Cmd?
    splash_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
    when SplashTickMsg
      @frame += 1
      return {self, splash_tick}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    v = Bubbletea::View.new("")
    v.alt_screen = true

    if @width == 0
      v.content = "Initializing..."
      return v
    end

    chars = " .:-=+*#%@"
    lines = Array.new(@height) do |y|
      String.build do |io|
        (0...@width).each do |x|
          t = ((x + @frame) * 0.08) + (y * 0.06) + (@rate * 0.0005)
          level = (((Math.sin(t) + 1.0) / 2.0) * (chars.size - 1)).to_i
          io << chars[level.clamp(0, chars.size - 1)]
        end
      end
    end

    v.content = (["Splash"] + lines).join("\n")
    v
  end
end

program = Bubbletea::Program.new(SplashModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
