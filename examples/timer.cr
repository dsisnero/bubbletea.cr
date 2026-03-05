require "../lib/bubbles/src/bubbles"

class TimerKeyMap
  property start : Bubbles::Key::Binding
  property stop : Bubbles::Key::Binding
  property reset : Bubbles::Key::Binding
  property quit : Bubbles::Key::Binding

  def initialize
    @start = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("s"),
      Bubbles::Key.with_help("s", "start"),
    )
    @stop = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("s"),
      Bubbles::Key.with_help("s", "stop"),
    )
    @reset = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("r"),
      Bubbles::Key.with_help("r", "reset"),
    )
    @quit = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("q", "ctrl+c"),
      Bubbles::Key.with_help("q", "quit"),
    )
  end
end

class TimerModel
  include Bubbletea::Model

  TIMEOUT = 5.seconds

  property timer : Bubbles::Timer::Model
  property keymap : TimerKeyMap
  property help : Bubbles::Help::Model
  property? quitting : Bool

  def initialize
    @timer = Bubbles::Timer.new(TIMEOUT, Bubbles::Timer.with_interval(1.millisecond))
    @keymap = TimerKeyMap.new
    @help = Bubbles::Help.new
    @quitting = false
    @keymap.start.set_enabled(false)
  end

  def init : Bubbletea::Cmd?
    @timer.init
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbles::Timer::TickMsg
      @timer, cmd = @timer.update(msg)
      return {self, cmd}
    when Bubbles::Timer::StartStopMsg
      @timer, cmd = @timer.update(msg)
      @keymap.stop.set_enabled(@timer.running?)
      @keymap.start.set_enabled(!@timer.running?)
      return {self, cmd}
    when Bubbles::Timer::TimeoutMsg
      @quitting = true
      return {self, Bubbletea.quit}
    when Bubbletea::KeyPressMsg
      case
      when Bubbles::Key.matches?(msg, @keymap.quit)
        @quitting = true
        return {self, Bubbletea.quit}
      when Bubbles::Key.matches?(msg, @keymap.reset)
        @timer.timeout = TIMEOUT
      when Bubbles::Key.matches?(msg, @keymap.start, @keymap.stop)
        return {self, @timer.toggle}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    s = @timer.view
    s = "All done!" if @timer.timedout?
    s += "\n"
    unless @quitting
      s = "Exiting in " + s
      s += help_view
    end
    Bubbletea::View.new(s)
  end

  private def help_view : String
    "\n" + @help.short_help_view([@keymap.start, @keymap.stop, @keymap.reset, @keymap.quit])
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(TimerModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Uh oh, we encountered an error: #{err.message}"
    exit 1
  end
end
