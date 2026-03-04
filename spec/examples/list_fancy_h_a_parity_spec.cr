require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/list_fancy"

private def capture_list_fancy_h_a_output : Bytes
  output = IO::Memory.new
  RandomFancyItemGenerator.seed(1_i64)
  program = Bubbletea.new_program(
    ListFancyModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 120.milliseconds
    program.send(Tea.key('H'))
    sleep 40.milliseconds
    program.send(Tea.key('a'))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/list_fancy H->a parity" do
  it "matches the saved Go golden output exactly" do
    unless File.exists?("#{__DIR__}/golden/list_fancy_h_a.go.golden")
      next
    end

    actual = capture_list_fancy_h_a_output
    expected = File.read("#{__DIR__}/golden/list_fancy_h_a.go.golden").to_slice
    actual.should eq(expected)
  end
end
