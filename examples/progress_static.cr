require "../src/bubbletea"

PADDING_STATIC = 2
MAX_WIDTH_STATIC = 80

struct ProgressStaticTickMsg
  include Tea::Msg
end

private def static_tick_cmd : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { ProgressStaticTickMsg.new.as(Tea::Msg?) })
end

class ProgressStaticModel
  include Bubbletea::Model

  def initialize
    @percent = 0.0
    @width = 40
  end

  def init : Bubbletea::Cmd?
    static_tick_cmd
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      @width = msg.width - PADDING_STATIC * 2 - 4
      @width = MAX_WIDTH_STATIC if @width > MAX_WIDTH_STATIC
      @width = 10 if @width < 10
      return {self, nil}
    when ProgressStaticTickMsg
      @percent += 0.25
      if @percent > 1.0
        @percent = 1.0
        return {self, Bubbletea.quit}
      end
      return {self, static_tick_cmd}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    filled = (@width * @percent).to_i
    bar = "[" + "=" * filled + " " * (@width - filled) + "]"
    Bubbletea::View.new("\n  #{bar}\n\n  Press any key to quit")
  end
end

program = Bubbletea::Program.new(ProgressStaticModel.new)
_model, err = program.run
if err
  STDERR.puts "Oh no! #{err.message}"
  exit 1
end
