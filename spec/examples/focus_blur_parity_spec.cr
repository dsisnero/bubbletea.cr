require "../spec_helper"

private class FocusBlurParityModel
  include Tea::Model

  def initialize(@focused = true, @reporting = true)
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::FocusMsg
      @focused = true
    when Tea::BlurMsg
      @focused = false
    when Tea::KeyPressMsg
      case msg.string
      when "t"
        @reporting = !@reporting
      when "ctrl+c", "q"
        return {self, Tea.quit}
      end
    end
    {self, nil}
  end

  def view : Tea::View
    s = "Hi. Focus report is currently "
    s += @reporting ? "enabled" : "disabled"
    s += ".\n\n"
    if @reporting
      s += @focused ? "This program is currently focused!" : "This program is currently blurred!"
    end

    view = Tea::View.new(s + "\n\nTo quit sooner press ctrl-c, or t to toggle focus reporting...\n")
    view.report_focus = @reporting
    view
  end
end

private def capture_focus_blur_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    FocusBlurParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_environment(Ultraviolet::Environ.new([] of String)),
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea::BlurMsg.new)
    sleep 40.milliseconds
    program.send(Tea.key('t'))
    sleep 40.milliseconds
    program.send(Tea.key('t'))
    sleep 40.milliseconds
    program.send(Tea::FocusMsg.new)
    sleep 40.milliseconds
    program.send(Tea.key('t'))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/focus_blur parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_focus_blur_output
    expected = File.read("#{__DIR__}/golden/focus_blur.go.golden").to_slice
    actual.should eq(expected)
  end
end
