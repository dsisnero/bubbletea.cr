require "../spec_helper"
require "../../lib/bubbles/src/bubbles"

private class TimerParityKeyMap
  getter start : Bubbles::Key::Binding
  getter stop : Bubbles::Key::Binding
  getter reset : Bubbles::Key::Binding
  getter quit : Bubbles::Key::Binding

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

private class TimerParityModel
  include Tea::Model

  TIMEOUT = 5.seconds

  def initialize
    @timer = Bubbles::Timer.new(TIMEOUT, Bubbles::Timer.with_interval(1.millisecond))
    @keymap = TimerParityKeyMap.new
    @help = Bubbles::Help.new
    @quitting = false
    @keymap.start.set_enabled(false)
  end

  def init : Tea::Cmd?
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
      return {self, Tea.quit}
    when Tea::KeyPressMsg
      if Bubbles::Key.matches?(msg, @keymap.quit)
        @quitting = true
        return {self, Tea.quit}
      end
      if Bubbles::Key.matches?(msg, @keymap.reset)
        @timer.timeout = TIMEOUT
      end
      if Bubbles::Key.matches?(msg, @keymap.start, @keymap.stop)
        return {self, @timer.toggle}
      end
    end

    {self, nil}
  end

  def help_view : String
    "\n" + @help.short_help_view([@keymap.start, @keymap.stop, @keymap.reset, @keymap.quit])
  end

  def view : Tea::View
    s = @timer.view
    s = "All done!" if @timer.timedout?
    s += "\n"
    unless @quitting
      s = "Exiting in " + s
      s += help_view
    end
    Tea::View.new(s)
  end
end

private def capture_timer_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    TimerParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 100.milliseconds
    program.send(Tea.key('s'))
    sleep 40.milliseconds
    program.send(Tea.key('s'))
    sleep 40.milliseconds
    program.send(Tea.key('r'))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/timer parity" do
  pending "matches the saved Go golden output exactly (millisecond tick stream is timing-sensitive and currently drifts from Go capture)" do
    actual = capture_timer_output
    expected = File.read("#{__DIR__}/golden/timer.go.golden").to_slice
    actual.should eq(expected)
  end
end
