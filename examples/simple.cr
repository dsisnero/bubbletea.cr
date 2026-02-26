require "../src/bubbletea"

struct SimpleTickMsg
  include Tea::Msg
end

private def simple_tick : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { SimpleTickMsg.new.as(Tea::Msg?) })
end

class SimpleModel
  include Bubbletea::Model

  getter remaining : Int32

  def initialize(@remaining : Int32)
  end

  def init : Bubbletea::Cmd?
    simple_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q"
        return {self, Bubbletea.quit}
      when "ctrl+z"
        return {self, Bubbletea.suspend}
      end
    when SimpleTickMsg
      @remaining -= 1
      return {self, Bubbletea.quit} if @remaining <= 0
      return {self, simple_tick}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    Bubbletea::View.new("Hi. This program will exit in #{@remaining} seconds.\n\nTo quit sooner press ctrl-c, or press ctrl-z to suspend...\n")
  end
end

if PROGRAM_NAME == __FILE__
  program = Bubbletea::Program.new(SimpleModel.new(5))
  _model, err = program.run
  if err
    STDERR.puts "Error: #{err.message}"
    exit 1
  end
end
