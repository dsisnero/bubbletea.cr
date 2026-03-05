require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/package_manager"

private class PackageManagerParityModel < PackageManagerModel
  def initialize
    super(Random.new(1_u64), ["alpha-1.0.0", "beta-2.0.0", "gamma-3.0.0"])
  end

  def init : Bubbletea::Cmd?
    nil
  end
end

private def capture_package_manager_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    PackageManagerParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_color_profile(Ultraviolet::ColorProfile::NoTTY),
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 40.milliseconds
    program.send(InstalledPkgMsg.new("alpha-1.0.0"))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/package_manager parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_package_manager_output
    expected = File.read("#{__DIR__}/golden/package_manager.go.golden").to_slice
    actual.should eq(expected)
  end
end
