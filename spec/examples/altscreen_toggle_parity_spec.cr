require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/altscreen_toggle"

private def capture_altscreen_toggle_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(AltScreenToggleModel.new, Tea.with_input(IO::Memory.new("")), Tea.with_output(output), Tea.without_signals, Tea.with_window_size(80, 24))
  spawn { sleep 60.milliseconds; program.send(Tea::QuitMsg.new) }
  _model, err = program.run; raise err.not_nil! if err; output.to_slice
end

describe "examples/altscreen_toggle parity" do
  it "matches the saved Go golden output exactly" do
    capture_altscreen_toggle_output.should eq(File.read("#{__DIR__}/golden/altscreen_toggle.go.golden").to_slice)
  end
end
