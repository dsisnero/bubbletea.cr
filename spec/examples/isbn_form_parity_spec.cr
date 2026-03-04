require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/isbn_form"

private def capture_isbn_form_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    IsbnFormModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 80.milliseconds
    program.send(Tea::QuitMsg.new)
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/isbn_form parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_isbn_form_output
    expected = File.read("#{__DIR__}/golden/isbn_form.go.golden").to_slice
    actual.should eq(expected)
  end
end
