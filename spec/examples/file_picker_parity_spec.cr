require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/file_picker"

private def capture_file_picker_output : Bytes
  temp_dir = File.join(Dir.current, "temp", "parity", "file_picker")
  Dir.mkdir_p(temp_dir)
  Dir.mkdir_p(File.join(temp_dir, "a_dir"))
  File.write(File.join(temp_dir, "a_dir", "inside.txt"), "inside\n")
  File.write(File.join(temp_dir, "b.txt"), "picked\n")
  File.write(File.join(temp_dir, "picked.txt"), "picked\n")

  model = FilePickerModel.new
  model.filepicker.allowed_types = [".mod", ".sum", ".go", ".txt", ".md"]
  model.filepicker.current_directory = temp_dir

  output = IO::Memory.new
  program = Bubbletea.new_program(
    model,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 120.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyUp))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyRight))
    sleep 80.milliseconds
    program.send(Tea.key(Tea::KeyLeft))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/file_picker parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_file_picker_output
    expected = File.read("#{__DIR__}/golden/file_picker.go.golden").to_slice
    actual.should eq(expected)
  end
end
