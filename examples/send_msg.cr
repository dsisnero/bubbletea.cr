require "../src/bubbletea"

struct ResultMsg
  include Tea::Msg
  getter duration : Time::Span
  getter food : String

  def initialize(@duration : Time::Span, @food : String)
  end

  def to_s : String
    return "." * 30 if @duration.zero?
    "Ate #{@food} #{@duration}"
  end
end

class SendMsgModel
  include Bubbletea::Model
  @results : Array(ResultMsg)

  def initialize
    @spinner = ["-", "\\", "|", "/"]
    @spin_index = 0
    @results = Array.new(5) { ResultMsg.new(0.milliseconds, "") }
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    spinner_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @quitting = true
      {self, Bubbletea.quit}
    when ResultMsg
      @results.shift
      @results << msg
      {self, nil}
    when Bubbletea::Value
      if msg.value == "spin"
        @spin_index = (@spin_index + 1) % @spinner.size
        return {self, spinner_tick}
      end
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    b = String.build do |io|
      if @quitting
        io << "That's all for today!"
      else
        io << @spinner[@spin_index] << " Eating food..."
      end

      io << "\n\n"
      @results.each do |res|
        io << res.to_s << "\n"
      end
      io << "\nPress any key to exit" unless @quitting
      io << "\n" if @quitting
    end

    Bubbletea::View.new(b)
  end

  private def spinner_tick : Bubbletea::Cmd
    Bubbletea.tick(100.milliseconds, ->(_t : Time) { Bubbletea["spin"].as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(SendMsgModel.new)

spawn do
  foods = ["an apple", "a pear", "some ramen", "tacos", "a sandwich"]
  loop do
    pause = (Random.rand(899) + 100).milliseconds
    sleep pause
    program.send(ResultMsg.new(pause, foods.sample || "food"))
  end
end

_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
