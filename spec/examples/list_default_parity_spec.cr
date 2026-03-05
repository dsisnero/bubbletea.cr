require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/list_default"

private def capture_list_default_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    ListDefaultModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 180.milliseconds
    program.send(Tea.key('/'))
    "linux".each_char do |ch|
      sleep 40.milliseconds
      program.send(Tea.key(ch))
    end
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
    sleep 100.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/list_default parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_list_default_output
    expected = File.read("#{__DIR__}/golden/list_default.go.golden").to_slice
    actual.should eq(expected)
  end
end
