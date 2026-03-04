require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/colorprofile"

private def capture_colorprofile_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    ColorProfileModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
    Tea.with_color_profile(Ultraviolet::ColorProfile::TrueColor),
  )

  spawn do
    sleep 40.milliseconds
    program.send(Tea::QuitMsg.new)
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

private def normalize_capability_query_order(bytes : Bytes) : String
  String
    .new(bytes)
    .gsub("\eP+q524742\e\\\eP+q5463\e\\", "\eP+q5463\e\\\eP+q524742\e\\")
end

describe "examples/colorprofile parity" do
  golden = "#{__DIR__}/golden/colorprofile.go.golden"

  if File.exists?(golden)
    it "matches the saved Go golden output exactly" do
      actual = normalize_capability_query_order(capture_colorprofile_output)
      expected = normalize_capability_query_order(File.read(golden).to_slice)
      actual.should eq(expected)
    end
  else
    pending "matches the saved Go golden output exactly (missing fixture: #{golden})" do
    end
  end
end
