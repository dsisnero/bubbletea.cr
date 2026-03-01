require "../src/bubbletea"
require "http/client"

struct DownloadProgressMsg
  include Tea::Msg
  getter ratio : Float64

  def initialize(@ratio : Float64)
  end
end

struct DownloadErrMsg
  include Tea::Msg
  getter err : Exception

  def initialize(@err : Exception)
  end
end

class ProgressWriter
  property total : Int32
  property downloaded : Int32
  property on_progress : Proc(Float64, Nil)?

  def initialize(@total : Int32, @downloaded : Int32 = 0, @on_progress = nil)
  end

  # Go parity for progressWriter.Write
  def write(bytes : Bytes) : {Int32, Nil}
    @downloaded += bytes.size
    if @total > 0
      if cb = @on_progress
        cb.call(@downloaded.to_f / @total.to_f)
      end
    end
    {bytes.size, nil}
  end
end

class ProgressDownloadModel
  include Bubbletea::Model

  PADDING   =  2
  MAX_WIDTH = 80

  def initialize
    @percent = 0.0
    @width = 40
    @err = nil.as(Exception?)
    @writer = ProgressWriter.new(100)
  end

  def init : Bubbletea::Cmd?
    tick
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
    when DownloadErrMsg
      @err = msg.err
      {self, Bubbletea.quit}
    when DownloadProgressMsg
      @percent = msg.ratio
      if @percent >= 1.0
        {self, Bubbletea.sequence(final_pause, Bubbletea.quit)}
      else
        {self, tick}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("Error downloading: #{@err}\n") if @err

    filled = (@width * @percent).to_i
    bar = "[" + "=" * filled + " " * (@width - filled) + "]"
    Bubbletea::View.new("\n  #{bar}\n\n  Press any key to quit")
  end

  private def tick : Bubbletea::Cmd
    Bubbletea.tick(250.milliseconds, ->(_t : Time) {
      next_ratio = {@percent + 0.1, 1.0}.min
      DownloadProgressMsg.new(next_ratio).as(Tea::Msg?)
    })
  end

  private def final_pause : Bubbletea::Cmd
    Bubbletea.tick(750.milliseconds, ->(_t : Time) { nil })
  end
end

program = Bubbletea::Program.new(ProgressDownloadModel.new)
_model, err = program.run
if err
  STDERR.puts "error running program: #{err.message}"
  exit 1
end
