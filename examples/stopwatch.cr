require "../lib/bubbles/src/bubbles"

struct StopwatchKeyMap
  include Bubbles::Help::KeyMap

  property start : Bubbles::Key::Binding
  property stop : Bubbles::Key::Binding
  property reset : Bubbles::Key::Binding
  property quit : Bubbles::Key::Binding

  def initialize
    @start = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("s"),
      Bubbles::Key.with_help("s", "start")
    )
    @stop = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("s"),
      Bubbles::Key.with_help("s", "stop")
    )
    @reset = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("r"),
      Bubbles::Key.with_help("r", "reset")
    )
    @quit = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("ctrl+c", "q"),
      Bubbles::Key.with_help("q", "quit")
    )
  end

  def short_help : Array(Bubbles::Key::Binding)
    [@start, @stop, @reset, @quit]
  end

  def full_help : Array(Array(Bubbles::Key::Binding))
    [] of Array(Bubbles::Key::Binding)
  end
end

class StopwatchModel
  include Bubbletea::Model

  property stopwatch : Bubbles::Stopwatch::Model
  property keymap : StopwatchKeyMap
  property help : Bubbles::Help::Model
  property? quitting : Bool

  def initialize
    @stopwatch = Bubbles::Stopwatch.new(Bubbles::Stopwatch.with_interval(1.millisecond))
    @keymap = StopwatchKeyMap.new
    @help = Bubbles::Help.new
    @quitting = false

    @keymap.start.set_enabled(false)
  end

  def init : Bubbletea::Cmd?
    @stopwatch.init
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case
      when Bubbles::Key.matches?(msg, @keymap.quit)
        @quitting = true
        return {self, Bubbletea.quit}
      when Bubbles::Key.matches?(msg, @keymap.reset)
        return {self, @stopwatch.reset}
      when Bubbles::Key.matches?(msg, @keymap.start, @keymap.stop)
        @keymap.stop.set_enabled(!@stopwatch.running)
        @keymap.start.set_enabled(@stopwatch.running)
        return {self, @stopwatch.toggle}
      end
    end

    stopwatch, cmd = @stopwatch.update(msg)
    @stopwatch = stopwatch
    {self, cmd}
  end

  def view : Bubbletea::View
    s = @stopwatch.view + "\n"
    unless @quitting
      s = "Elapsed: " + s
      s += help_view
    end
    Bubbletea::View.new(s)
  end

  private def help_view : String
    "\n" + @help.short_help_view([@keymap.start, @keymap.stop, @keymap.reset, @keymap.quit])
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(StopwatchModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Oh no, it didn't work: #{err.message}"
    exit 1
  end
end
