require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/http"

private class HttpParityModel < HttpModel
  def init : Bubbletea::Cmd?
    nil
  end
end

describe "examples/http parity" do
  it "matches the saved Go golden output exactly" do
    output = IO::Memory.new
    program = Bubbletea.new_program(
      HttpParityModel.new,
      Tea.with_input(IO::Memory.new("")),
      Tea.with_output(output),
      Tea.without_signals,
      Tea.with_window_size(80, 24),
    )

    spawn do
      sleep 40.milliseconds
      program.send(StatusMsg.new(200))
    end

    _model, err = program.run
    raise err.not_nil! if err

    actual = output.to_slice
    expected = File.read("#{__DIR__}/golden/http.go.golden").to_slice
    actual.should eq(expected)
  end
end
