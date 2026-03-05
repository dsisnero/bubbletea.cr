require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/textarea"

private class TextareaParityModel < TextareaModel
  def initialize
    super
    @textarea.set_virtual_cursor(true)
  end
end

private def capture_textarea_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    TextareaParityModel.new,
    Tea.with_input(nil),
    Tea.with_output(output),
    Tea.with_environment(Ultraviolet::Environ.new(["TERM=xterm-256color"])),
    Tea.without_signals,
    Tea.with_window_size(60, 12),
  )

  spawn do
    sleep 80.milliseconds
    lines = [
      "Once upon a time,",
      "there were three bears.",
      "Papa Bear made porridge.",
      "Baby Bear took a walk.",
    ]

    lines.each_with_index do |line, idx|
      line.each_char { |ch| program.send(Tea.key(ch)) }
      program.send(Tea.key(Tea::KeyEnter)) unless idx == lines.size - 1
    end

    sleep 40.milliseconds
    program.send(Tea::QuitMsg.new)
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/textarea parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_textarea_output
    expected = File.read("#{__DIR__}/golden/textarea.go.golden").to_slice
    actual.should eq(expected)
  end
end
