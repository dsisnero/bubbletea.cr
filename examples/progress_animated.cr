require "../src/bubbletea"

PADDING   =  2
MAX_WIDTH = 80

struct ProgressTickMsg
  include Tea::Msg
end

private def progress_tick_cmd : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { ProgressTickMsg.new.as(Tea::Msg?) })
end

class ProgressAnimatedModel
  include Bubbletea::Model

  def initialize
    @percent = 0.0
    @width = 40
  end

  def init : Bubbletea::Cmd?
    progress_tick_cmd
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      @width = msg.width - PADDING * 2 - 4
      @width = MAX_WIDTH if @width > MAX_WIDTH
      @width = 10 if @width < 10
      {self, nil}
    when ProgressTickMsg
      return {self, Bubbletea.quit} if @percent >= 1.0
      @percent = {@percent + 0.25, 1.0}.min
      {self, progress_tick_cmd}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    filled = (@width * @percent).to_i
    bar = "[" + "=" * filled + " " * (@width - filled) + "]"
    pad = " " * PADDING
    Bubbletea::View.new("\n" + pad + bar + "\n\n" + pad + "Press any key to quit")
  end
end

program = Bubbletea::Program.new(ProgressAnimatedModel.new)
_model, err = program.run
if err
  STDERR.puts "Oh no! #{err.message}"
  exit 1
end
