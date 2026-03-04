require "../spec_helper"
require "../../lib/teatest/src/teatest"
require "file_utils"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/file_picker"

describe "examples/file_picker teatest" do
  it "selects a file and keeps selected path in the final model" do
    dir = File.join(Dir.current, "temp", "teatest", "file_picker")
    FileUtils.mkdir_p(dir)
    picked_path = File.join(dir, "picked.txt")
    File.write(picked_path, "picked\n")

    model = FilePickerModel.new
    model.filepicker.current_directory = dir
    model.filepicker.allowed_types = [".txt"]
    model.filepicker.height = 5

    tm = Teatest.new_test_model(
      model,
      [Teatest.with_initial_term_size(80, 24)]
    )

    entry = Bubbles::Filepicker::Entry.new("picked.txt", File.info(picked_path))
    tm.send(Bubbles::Filepicker::ReadDirMsg.new(model.filepicker.id, [entry]))
    sleep 100.milliseconds

    tm.send(Tea.key(Tea::KeyEnter))
    sleep 100.milliseconds
    tm.send(Tea.key('q'))

    final = tm.final_model([Teatest.with_final_timeout(3.seconds)])
    final.should be_a(FilePickerModel)
    final.not_nil!.as(FilePickerModel).selected_file.should eq(picked_path)
  end
end
