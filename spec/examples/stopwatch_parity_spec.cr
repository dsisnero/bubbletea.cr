require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/stopwatch"

private class StopwatchParityModel < StopwatchModel
  def init : Bubbletea::Cmd?
    nil
  end
end

describe "examples/stopwatch parity" do
  it "matches the saved Go golden output exactly" do
    output = IO::Memory.new
    program = Bubbletea.new_program(
      StopwatchParityModel.new,
      Tea.with_input(IO::Memory.new("")),
      Tea.with_output(output),
      Tea.without_signals,
      Tea.with_window_size(80, 24),
    )

    spawn do
      sleep 40.milliseconds
      program.send(Tea.key('q'))
    end

    _model, err = program.run
    raise err.not_nil! if err

    actual = output.to_slice
    expected = File.read("#{__DIR__}/golden/stopwatch.go.golden").to_slice
    actual.should eq(expected)
  end
end
