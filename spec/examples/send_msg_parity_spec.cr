require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/send_msg"

private def capture_send_msg_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    SendMsgModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 140.milliseconds
    program.send(SendMsgResult.new(120.milliseconds, "an apple"))
    sleep 80.milliseconds
    program.send(SendMsgResult.new(250.milliseconds, "tacos"))
    sleep 1.millisecond
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/send_msg parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_send_msg_output
    expected = File.read("#{__DIR__}/golden/send_msg.go.golden").to_slice
    actual.should eq(expected)
  end
end
