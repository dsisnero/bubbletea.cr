require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/table_resize"

private def capture_table_resize_output(width : Int32, height : Int32, resize_to : Tuple(Int32, Int32)? = nil) : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    TableResizeModel.new,
    Tea.with_input(nil),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(width, height),
  )

  spawn do
    if to = resize_to
      sleep 100.milliseconds
      program.send(Bubbletea::WindowSizeMsg.new(to[0], to[1]))
    end
    sleep 120.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/table_resize parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_table_resize_output(80, 24)
    expected = File.read("#{__DIR__}/golden/table_resize.go.golden").to_slice
    actual.should eq(expected)
  end

  it "renders differently at a larger initial window size" do
    small = capture_table_resize_output(80, 24)
    large = capture_table_resize_output(120, 40)
    small.should_not eq(large)
  end

  it "reacts to runtime WindowSizeMsg changes" do
    static_small = capture_table_resize_output(80, 24)
    resized = capture_table_resize_output(80, 24, {120, 40})
    static_small.should_not eq(resized)
  end
end
