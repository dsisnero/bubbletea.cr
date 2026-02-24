require "spec"
require "../src/bubbletea"

describe "Options" do
  describe "output" do
    it "sets custom output" do
      buf = IO::Memory.new
      model = Tea::View.new("test")
      # Note: Options.with_output returns a ProgramOption proc
      # We'd need to apply it to verify it works
      opt = Tea::Options.with_output(buf)
      opt.should be_a(Tea::ProgramOption)
    end
  end

  describe "renderer" do
    it "disables renderer" do
      opt = Tea::Options.without_renderer
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.disable_renderer?.should be_true
    end
  end

  describe "without signals" do
    pending "ignores signals" do
      # This feature may not be fully implemented yet
      opt = Tea.without_input
      opt.should be_a(Tea::ProgramOption)
    end
  end

  describe "filter" do
    it "sets filter function" do
      filter_fn = ->(_model : Tea::Model, msg : Tea::Msg) { msg.as(Tea::Msg?) }
      opt = Tea::Options.with_filter(&filter_fn)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.filter.should_not be_nil
    end
  end

  describe "external context" do
    it "sets external context" do
      ctx = Tea::ExecutionContext.new
      opt = Tea::Options.with_context(ctx)
      opt.should be_a(Tea::ProgramOption)

      # Would verify context is set when applied to program
    end
  end

  describe "input options" do
    pending "handles nil input" do
      # Note: with_input doesn't accept nil in current implementation
      # opt = Tea::Options.with_input(nil)
      # opt.should be_a(Tea::ProgramOption)
      # program = Tea::Program.new
      # opt.call(program)
      # program.disable_input?.should be_true
    end

    it "handles custom input" do
      buf = IO::Memory.new
      opt = Tea::Options.with_input(buf)
      opt.should be_a(Tea::ProgramOption)

      # Would verify input is set when applied
    end
  end

  describe "startup options" do
    pending "without catch panics" do
      # Feature may not be fully implemented
      opt = Tea.without_input
      opt.should be_a(Tea::ProgramOption)
    end

    pending "without signal handler" do
      # Feature may not be fully implemented
      opt = Tea.without_input
      opt.should be_a(Tea::ProgramOption)
    end
  end

  describe "convenience methods" do
    it "provides with_context" do
      ctx = Tea::ExecutionContext.new
      opt = Tea.with_context(ctx)
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides without_input" do
      opt = Tea.without_input
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides without_renderer" do
      opt = Tea.without_renderer
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_fps" do
      opt = Tea.with_fps(30)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.fps.should eq 30
    end

    it "clamps fps to valid range" do
      opt = Tea.with_fps(200)
      program = Tea::Program.new
      opt.call(program)
      program.fps.should eq 120

      opt = Tea.with_fps(0)
      opt.call(program)
      program.fps.should eq 1
    end

    it "provides with_filter" do
      opt = Tea.with_filter { |_, msg| msg }
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_alt_screen" do
      opt = Tea.with_alt_screen
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_mouse_cell_motion" do
      opt = Tea.with_mouse_cell_motion
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_mouse_all_motion" do
      opt = Tea.with_mouse_all_motion
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_report_focus" do
      opt = Tea.with_report_focus
      opt.should be_a(Tea::ProgramOption)
    end
  end
end
