require "../src/bubbletea"

class SpinnersModel
  include Bubbletea::Model

  SPINNERS = [
    ["-", "\\", "|", "/"],
    [".", "o", "O", "o"],
    ["◐", "◓", "◑", "◒"],
    ["▁", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃"],
  ]

  def initialize
    @spinner_index = 0
    @frame_index = 0
  end

  def init : Bubbletea::Cmd?
    tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q", "esc"
        return {self, Bubbletea.quit}
      when "h", "left"
        @spinner_index -= 1
        @spinner_index = SPINNERS.size - 1 if @spinner_index < 0
        @frame_index = 0
        return {self, tick}
      when "l", "right"
        @spinner_index += 1
        @spinner_index = 0 if @spinner_index >= SPINNERS.size
        @frame_index = 0
        return {self, tick}
      else
        return {self, nil}
      end
    when Bubbletea::Value
      if msg.value == "tick"
        frames = SPINNERS[@spinner_index]
        @frame_index = (@frame_index + 1) % frames.size
        return {self, tick}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    frame = SPINNERS[@spinner_index][@frame_index]
    s = "\n #{frame} Spinning...\n\n"
    s += "h/l, ←/→: change spinner • q: exit\n"
    Bubbletea::View.new(s)
  end

  private def tick : Bubbletea::Cmd
    Bubbletea.tick(100.milliseconds, ->(_t : Time) { Bubbletea["tick"].as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(SpinnersModel.new)
_model, err = program.run
if err
  STDERR.puts "could not run program: #{err.message}"
  exit 1
end
