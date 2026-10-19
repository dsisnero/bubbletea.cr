require "spec"
require "../src/bubbletea"

# Captures the initial WindowSizeMsg and quits.
class WindowSizeProbeModel
  include Tea::Model

  getter size : Tuple(Int32, Int32)? = nil

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    if msg.is_a?(Tea::WindowSizeMsg)
      @size = {msg.width, msg.height}
      return {self, Tea.quit}
    end

    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("")
  end
end

private def with_columns_lines(columns : String?, lines : String?, &)
  old_columns = ENV["COLUMNS"]?
  old_lines = ENV["LINES"]?

  if columns
    ENV["COLUMNS"] = columns
  else
    ENV.delete("COLUMNS")
  end
  if lines
    ENV["LINES"] = lines
  else
    ENV.delete("LINES")
  end

  yield
ensure
  if old_columns
    ENV["COLUMNS"] = old_columns
  else
    ENV.delete("COLUMNS")
  end
  if old_lines
    ENV["LINES"] = old_lines
  else
    ENV.delete("LINES")
  end
end

private def window_size_for(model : Tea::Model, options : Array(Tea::ProgramOption) = [] of Tea::ProgramOption) : Tuple(Int32, Int32)?
  program = Tea.new_program(
    model,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(IO::Memory.new),
    Tea.without_signals,
  )
  options.each(&.call(program))

  _model, err = program.run
  raise err if err

  model.as(WindowSizeProbeModel).size
end

describe "fallback dimensions" do
  # Port of Go test TestFallbackDimensions.
  it "falls back to 80x24 for non-positive sizes" do
    with_columns_lines(nil, nil) do
      program = Tea::Program.new

      program.fallback_dimensions(0, 0).should eq({80, 24})
      program.fallback_dimensions(-10, -5).should eq({80, 24})
    end
  end

  it "preserves positive dimensions" do
    Tea::Program.new.fallback_dimensions(120, 40).should eq({120, 40})
  end

  it "fills only the non-positive dimension" do
    with_columns_lines(nil, nil) do
      program = Tea::Program.new

      program.fallback_dimensions(0, 50).should eq({80, 50})
      program.fallback_dimensions(100, 0).should eq({100, 24})
    end
  end

  it "uses COLUMNS and LINES from the process environment" do
    with_columns_lines("132", "43") do
      Tea::Program.new.fallback_dimensions(0, 0).should eq({132, 43})
    end
  end

  it "prefers the program environment" do
    with_columns_lines("200", "100") do
      program = Tea::Program.new
      program.env = Ultraviolet::Environ.new(["COLUMNS=150", "LINES=60"])

      program.fallback_dimensions(0, 0).should eq({150, 60})
    end
  end

  it "does not read the process environment when a program environment exists" do
    with_columns_lines("200", "100") do
      program = Tea::Program.new
      program.env = Ultraviolet::Environ.new(["OTHER_VAR=1"])

      program.fallback_dimensions(0, 0).should eq({80, 24})
    end
  end

  it "ignores invalid or non-positive values" do
    with_columns_lines("invalid", "-10") do
      Tea::Program.new.fallback_dimensions(0, 0).should eq({80, 24})
    end

    with_columns_lines("0", "0") do
      Tea::Program.new.fallback_dimensions(0, 0).should eq({80, 24})
    end
  end
end

describe "non-tty dimensions" do
  # Port of Go test TestProgramNonTTYDimensions.
  it "does not invent fallback dimensions for non-tty output" do
    with_columns_lines("110", "35") do
      model = WindowSizeProbeModel.new
      window_size_for(model).should eq({0, 0})
    end
  end

  it "ignores the program environment for non-tty output" do
    model = WindowSizeProbeModel.new
    window_size_for(
      model,
      [Tea.with_environment(Ultraviolet::Environ.new(["COLUMNS=150", "LINES=60"]))]
    ).should eq({0, 0})
  end

  it "preserves with_window_size for non-tty output" do
    model = WindowSizeProbeModel.new
    window_size_for(model, [Tea.with_window_size(120, 50)]).should eq({120, 50})
  end
end
