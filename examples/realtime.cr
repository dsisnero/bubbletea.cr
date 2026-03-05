require "../lib/bubbles/src/bubbles"

struct ResponseMsg
  include Tea::Msg
end

class RealtimeModel
  include Bubbletea::Model

  def initialize
    @sub = Channel(Nil).new
    @responses = 0
    @quitting = false
    @spinner = Bubbles::Spinner.new
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(
      -> { @spinner.tick.as(Tea::Msg?) },
      listen_for_activity(@sub),
      wait_for_activity(@sub),
    )
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @quitting = true
      {self, Bubbletea.quit}
    when ResponseMsg
      @responses += 1
      {self, wait_for_activity(@sub)}
    when Bubbles::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      {self, cmd}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    s = "\n #{@spinner.view} Events received: #{@responses}\n\n Press any key to exit\n"
    s += "\n" if @quitting
    Bubbletea::View.new(s)
  end

  private def listen_for_activity(sub : Channel(Nil)) : Bubbletea::Cmd
    -> : Tea::Msg? do
      loop do
        sleep (Random.rand(900) + 100).milliseconds
        sub.send(nil)
      end
    end
  end

  private def wait_for_activity(sub : Channel(Nil)) : Bubbletea::Cmd
    -> : Tea::Msg? do
      sub.receive
      ResponseMsg.new
    end
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(RealtimeModel.new)
  _model, err = program.run
  if err
    STDERR.puts "could not start program: #{err.message}"
    exit 1
  end
end
