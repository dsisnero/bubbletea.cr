require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/list_simple"

private def capture_list_simple_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(ListSimpleModel.initial_model, Tea.with_input(IO::Memory.new("")), Tea.with_output(output), Tea.without_signals, Tea.with_window_size(80, 24))
  spawn { sleep 60.milliseconds; program.send(Tea::QuitMsg.new) }
  _model, err = program.run; raise err.not_nil! if err; output.to_slice
end

describe "examples/list_simple parity" do
  it "matches the saved Go golden output exactly" do
    capture_list_simple_output.should eq(File.read("#{__DIR__}/golden/list_simple.go.golden").to_slice)
  end
end
