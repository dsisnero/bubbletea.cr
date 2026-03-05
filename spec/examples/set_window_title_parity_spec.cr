require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/set_window_title"

private def capture_set_window_title_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(SetWindowTitleModel.new, Tea.with_input(IO::Memory.new("")), Tea.with_output(output), Tea.without_signals, Tea.with_window_size(80, 24))
  spawn { sleep 60.milliseconds; program.send(Tea::QuitMsg.new) }
  _model, err = program.run; raise err.not_nil! if err; output.to_slice
end

describe "examples/set_window_title parity" do
  it "matches the saved Go golden output exactly" do
    capture_set_window_title_output.should eq(File.read("#{__DIR__}/golden/set_window_title.go.golden").to_slice)
  end
end
