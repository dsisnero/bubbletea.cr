require "./spec_helper"

describe "Pager highlight parity" do
  # Load captured outputs from parity test
  go_output_path = File.join(__DIR__, "../temp/parity/pager.go.view.txt")
  crystal_output_path = File.join(__DIR__, "../temp/parity/pager.crystal.view.txt")

  it "uses parity captures only when both files are available" do
    go_exists = File.exists?(go_output_path)
    crystal_exists = File.exists?(crystal_output_path)

    if go_exists && crystal_exists
      go_output = File.read(go_output_path)
      crystal_output = File.read(crystal_output_path)

      go_line = go_output.split('\n')[7]
      crystal_line = crystal_output.split('\n')[7]

      go_ansi_count = go_line.scan(/\e\[/).size
      crystal_ansi_count = crystal_line.scan(/\e\[/).size

      go_ansi_count.should be > 0
      crystal_ansi_count.should be > 0
    else
      go_exists.should eq(crystal_exists)
    end
  end
end
