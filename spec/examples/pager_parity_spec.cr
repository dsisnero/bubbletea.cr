require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/pager"

private def capture_pager_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    PagerModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 120.milliseconds
    program.send(Tea.key('j'))
    sleep 20.milliseconds
    program.send(Tea::QuitMsg.new)
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/pager parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_pager_output
    expected = File.read("#{__DIR__}/golden/pager.go.golden").to_slice
    actual.should eq(expected)
  end
end
