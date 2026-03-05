require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/splash"

private class SplashParityModel < SplashModel
  def initialize
    super(0_i64)
  end

  def init : Bubbletea::Cmd?
    nil
  end
end

private def capture_splash_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    SplashParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(40, 10),
  )

  spawn do
    sleep 60.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/splash parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_splash_output
    expected = File.read("#{__DIR__}/golden/splash.go.golden").to_slice
    actual.should eq(expected)
  end
end
