require "../spec_helper"

private struct DebounceExitMsg
  include Tea::Msg
  getter tag : Int32

  def initialize(@tag : Int32)
  end
end

private class DebounceParityModel
  include Bubbletea::Model

  DEBOUNCE_DURATION = 1.second

  def initialize
    @tag = 0
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      @tag += 1
      current_tag = @tag
      cmd = Tea.tick(DEBOUNCE_DURATION) { |_time| DebounceExitMsg.new(current_tag) }
      {self, cmd}
    when DebounceExitMsg
      if msg.tag == @tag
        {self, Tea.quit}
      else
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : Tea::View
    Tea::View.new("Key presses: #{@tag}\nTo exit press any key, then wait for one second without pressing anything.")
  end
end

private def capture_debounce_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    DebounceParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea.key('a'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/debounce parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_debounce_output
    expected = File.read("#{__DIR__}/golden/debounce.go.golden").to_slice
    actual.should eq(expected)
  end
end
