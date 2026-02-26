require "../src/bubbletea"

struct ProcessFinishedMsg
  include Tea::Msg

  getter duration : Time::Span

  def initialize(@duration : Time::Span)
  end
end

class TuiDaemonComboModel
  include Bubbletea::Model

  def initialize
    @results = Array(String).new(5, "........................")
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    run_pretend_process
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @quitting = true
      return {self, Bubbletea.quit}
    when ProcessFinishedMsg
      @results.shift
      @results << "#{random_emoji} Job finished in #{msg.duration}"
      return {self, run_pretend_process}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    s = String.build do |io|
      io << "\nDoing some work...\n\n"
      @results.each { |r| io << r << "\n" }
      io << "\nPress any key to exit\n"
      io << "\n" if @quitting
    end
    Bubbletea::View.new(s)
  end

  private def run_pretend_process : Bubbletea::Cmd
    -> : Tea::Msg? do
      pause = rand(100..999).milliseconds
      sleep(pause)
      ProcessFinishedMsg.new(pause).as(Tea::Msg?)
    end
  end

  private def random_emoji : String
    emojis = ["🍦", "🧋", "🍡", "🤠", "👾", "😭", "🦊", "🐯", "🦆", "🥨"]
    emojis.sample
  end
end

program = Bubbletea::Program.new(TuiDaemonComboModel.new)
_model, err = program.run
if err
  STDERR.puts "Error starting Bubble Tea program: #{err.message}"
  exit 1
end
