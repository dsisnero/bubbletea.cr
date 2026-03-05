require "../spec_helper"

private struct FullscreenTickMsg
  include Tea::Msg
end

private def fullscreen_parity_tick : Tea::Cmd
  Tea.tick(1.second) { |_t| FullscreenTickMsg.new }
end

private class FullscreenParityModel
  include Tea::Model
  @count : Int32

  def initialize(@count : Int32 = 5)
  end

  def init : Tea::Cmd?
    fullscreen_parity_tick
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      if msg.string.in?({"q", "esc", "ctrl+c"})
        return {self, Tea.quit}
      end
    when FullscreenTickMsg
      @count -= 1
      if @count <= 0
        return {self, Tea.quit}
      end
      return {self, fullscreen_parity_tick}
    end
    {self, nil}
  end

  def view : Tea::View
    v = Tea::View.new("\n\n     Hi. This program will exit in #{@count} seconds...")
    v.alt_screen = true
    v
  end
end

private def capture_fullscreen_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    FullscreenParityModel.new(5),
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/fullscreen parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_fullscreen_output
    expected = File.read("#{__DIR__}/golden/fullscreen.go.golden").to_slice
    actual.should eq(expected)
  end
end
